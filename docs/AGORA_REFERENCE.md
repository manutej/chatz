# Agora WebRTC Integration Reference

This document provides integration guidance for Agora RTC Engine in the Chatz application for voice and video calling.

## Overview

Agora provides real-time voice and video communication through a Software Defined Real-time Network (SD-RTN™).

## Installation

Add to `pubspec.yaml`:

```yaml
dependencies:
  agora_rtc_engine: ^6.3.0
  permission_handler: ^11.0.0
```

## Basic Setup

### 1. Initialize Agora Engine

```dart
import 'package:agora_rtc_engine/agora_rtc_engine.dart';

class CallService {
  late RtcEngine _engine;

  Future<void> initialize() async {
    // Request permissions
    await [Permission.microphone, Permission.camera].request();

    // Create engine
    _engine = createAgoraRtcEngine();

    // Initialize with App ID
    await _engine.initialize(const RtcEngineContext(
      appId: 'YOUR_AGORA_APP_ID',
      channelProfile: ChannelProfileType.channelProfileCommunication,
    ));

    // Register event handlers
    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: _onJoinChannelSuccess,
        onUserJoined: _onUserJoined,
        onUserOffline: _onUserOffline,
        onError: _onError,
        onTokenPrivilegeWillExpire: _onTokenPrivilegeWillExpire,
      ),
    );
  }

  void dispose() async {
    await _engine.leaveChannel();
    await _engine.release();
  }
}
```

### 2. Voice Call Implementation

```dart
class VoiceCallService {
  late RtcEngine _engine;

  Future<void> startVoiceCall(String channelName, String token) async {
    // Enable audio
    await _engine.enableAudio();

    // Join channel
    await _engine.joinChannel(
      token: token,
      channelId: channelName,
      uid: 0, // Let Agora assign UID
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ),
    );
  }

  Future<void> endCall() async {
    await _engine.leaveChannel();
  }

  Future<void> muteLocalAudio(bool muted) async {
    await _engine.muteLocalAudioStream(muted);
  }

  Future<void> muteRemoteAudio(int uid, bool muted) async {
    await _engine.muteRemoteAudioStream(uid: uid, mute: muted);
  }
}
```

### 3. Video Call Implementation

```dart
class VideoCallService {
  late RtcEngine _engine;

  Future<void> startVideoCall(String channelName, String token) async {
    // Enable video
    await _engine.enableVideo();
    await _engine.startPreview();

    // Configure video encoder
    await _engine.setVideoEncoderConfiguration(
      const VideoEncoderConfiguration(
        dimensions: VideoDimensions(width: 640, height: 480),
        frameRate: 15,
        bitrate: 0,
        orientationMode: OrientationMode.orientationModeAdaptive,
      ),
    );

    // Join channel
    await _engine.joinChannel(
      token: token,
      channelId: channelName,
      uid: 0,
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        channelProfile: ChannelProfileType.channelProfileCommunication,
        publishMicrophoneTrack: true,
        publishCameraTrack: true,
      ),
    );
  }

  Future<void> switchCamera() async {
    await _engine.switchCamera();
  }

  Future<void> toggleVideo(bool enabled) async {
    await _engine.enableLocalVideo(enabled);
  }
}
```

### 4. Video View Widgets

```dart
// Local video view
class LocalVideoView extends StatelessWidget {
  final RtcEngine engine;

  @override
  Widget build(BuildContext context) {
    return AgoraVideoView(
      controller: VideoViewController(
        rtcEngine: engine,
        canvas: const VideoCanvas(uid: 0),
      ),
    );
  }
}

// Remote video view
class RemoteVideoView extends StatelessWidget {
  final RtcEngine engine;
  final int remoteUid;
  final String channelId;

  @override
  Widget build(BuildContext context) {
    return AgoraVideoView(
      controller: VideoViewController.remote(
        rtcEngine: engine,
        canvas: VideoCanvas(uid: remoteUid),
        connection: RtcConnection(channelId: channelId),
      ),
    );
  }
}
```

### 5. Event Handlers

```dart
void _onJoinChannelSuccess(RtcConnection connection, int elapsed) {
  print('Local user ${connection.localUid} joined channel: ${connection.channelId}');
}

void _onUserJoined(RtcConnection connection, int remoteUid, int elapsed) {
  print('Remote user $remoteUid joined');
  // Update UI to show remote user
}

void _onUserOffline(RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
  print('Remote user $remoteUid left channel');
  // Update UI to remove remote user
}

void _onError(ErrorCodeType err, String msg) {
  print('Agora error: $err, message: $msg');
}

void _onTokenPrivilegeWillExpire(RtcConnection connection, String token) {
  print('Token will expire, renewing...');
  // Fetch new token from server and call renewToken
}
```

## Chatz-Specific Implementation

### Call with Payment Integration

```dart
class PaidCallService {
  final RtcEngine _engine;
  final double costPerMinute;
  Timer? _costTimer;
  double _accumulatedCost = 0.0;

  Future<bool> initiateCall({
    required String channelName,
    required String token,
    required double userBalance,
    required bool isVideo,
  }) async {
    final minBalance = 0.50; // Minimum required balance

    if (userBalance < minBalance) {
      throw InsufficientBalanceException('Insufficient balance to start call');
    }

    // Start call
    if (isVideo) {
      await _startVideoCall(channelName, token);
    } else {
      await _startVoiceCall(channelName, token);
    }

    // Start cost tracking
    _startCostTracking();

    return true;
  }

  void _startCostTracking() {
    // Deduct cost every 10 seconds
    _costTimer = Timer.periodic(Duration(seconds: 10), (timer) async {
      final cost = (costPerMinute / 60) * 10; // Cost for 10 seconds
      _accumulatedCost += cost;

      // Update Firestore with new balance
      await _deductBalance(cost);

      // Check if balance is low
      final currentBalance = await _getBalance();
      if (currentBalance < 0.10) {
        _showLowBalanceWarning();
      }

      if (currentBalance <= 0) {
        await endCall(reason: 'Insufficient balance');
      }
    });
  }

  Future<void> endCall({String? reason}) async {
    _costTimer?.cancel();
    await _engine.leaveChannel();

    // Record transaction
    await _recordTransaction(
      amount: _accumulatedCost,
      duration: _getCallDuration(),
      reason: reason,
    );

    _accumulatedCost = 0.0;
  }
}
```

### Call State Provider (Riverpod)

```dart
class CallNotifier extends StateNotifier<CallState> {
  final PaidCallService _callService;

  CallNotifier(this._callService) : super(CallState.idle());

  Future<void> startCall({
    required String contactId,
    required bool isVideo,
  }) async {
    try {
      state = CallState.initiating();

      // Get token from backend
      final token = await _getCallToken(contactId);
      final channelName = _generateChannelName(contactId);

      // Check balance
      final balance = await _getBalance();

      // Start call
      await _callService.initiateCall(
        channelName: channelName,
        token: token,
        userBalance: balance,
        isVideo: isVideo,
      );

      state = CallState.active(
        channelName: channelName,
        isVideo: isVideo,
        contactId: contactId,
      );
    } catch (e) {
      state = CallState.error(e.toString());
    }
  }

  Future<void> endCall() async {
    await _callService.endCall();
    state = CallState.idle();
  }
}
```

## Audio Effects

```dart
// Apply voice effects
await _engine.setAudioEffectPreset(AudioEffectPreset.voiceChangerEffectUncle);

// Adjust volume
await _engine.adjustPlaybackSignalVolume(50); // 0-100
```

## Network Quality Monitoring

```dart
_engine.registerEventHandler(
  RtcEngineEventHandler(
    onNetworkQuality: (connection, remoteUid, txQuality, rxQuality) {
      print('Network quality - TX: $txQuality, RX: $rxQuality');
      // Update UI to show network quality indicator
    },
  ),
);
```

## Token Generation (Backend)

```javascript
// Server-side token generation using Agora Token Builder
const { RtcTokenBuilder, RtcRole } = require('agora-access-token');

function generateToken(channelName, uid) {
  const appId = 'YOUR_APP_ID';
  const appCertificate = 'YOUR_APP_CERTIFICATE';
  const role = RtcRole.PUBLISHER;
  const expirationTimeInSeconds = 3600; // 1 hour

  const currentTimestamp = Math.floor(Date.now() / 1000);
  const privilegeExpiredTs = currentTimestamp + expirationTimeInSeconds;

  return RtcTokenBuilder.buildTokenWithUid(
    appId,
    appCertificate,
    channelName,
    uid,
    role,
    privilegeExpiredTs
  );
}
```

## Best Practices

1. **Always request permissions** before initializing
2. **Use tokens** for production (not App ID only)
3. **Renew tokens** before expiration
4. **Clean up resources** in dispose methods
5. **Handle network quality** changes gracefully
6. **Monitor call quality** and adjust settings
7. **Implement reconnection logic** for poor connections
8. **Test on real devices** (not just emulators)

## Platform-Specific Setup

### Android

Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS"/>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
```

### iOS

Add to `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>Chatz needs camera access for video calls</string>
<key>NSMicrophoneUsageDescription</key>
<string>Chatz needs microphone access for calls</string>
```

## Resources

- [Agora Flutter SDK Docs](https://docs.agora.io/en/video-calling/get-started/get-started-sdk)
- [Agora API Reference](https://api-ref.agora.io/en/video-sdk/flutter/6.x/API/rtc_api_overview.html)
- [Token Server Examples](https://github.com/AgoraIO/Tools/tree/master/DynamicKey/AgoraDynamicKey)
