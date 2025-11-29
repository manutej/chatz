# Chat UI - Quick Start Guide

## 🚀 Getting Started

### 1. Add to Your App

```dart
import 'package:chatz/features/chat/presentation/pages/chat_list_page.dart';

// In your main navigation or home screen
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => ChatListPage(
      userId: currentUserId, // Get from auth
    ),
  ),
);
```

### 2. Open Specific Chat

```dart
import 'package:chatz/features/chat/presentation/pages/chat_page.dart';

Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => ChatPage(
      chatId: chatId,
      currentUserId: currentUserId,
    ),
  ),
);
```

---

## 📱 Features Overview

### Chat List Page
- ✅ Real-time chat updates
- ✅ Search chats by name/message
- ✅ Swipe to archive/delete
- ✅ Unread badges
- ✅ Pin/mute indicators
- ✅ Pull to refresh

### Chat Page
- ✅ Real-time messages
- ✅ Text messages
- ✅ Image messages
- ✅ Video messages
- ✅ Audio/voice messages
- ✅ File attachments
- ✅ Reply to messages
- ✅ React with emojis
- ✅ Delete messages
- ✅ Copy message text

### Message Input
- ✅ Multi-line text input
- ✅ Emoji picker
- ✅ Camera capture
- ✅ Gallery picker
- ✅ Video picker
- ✅ Document picker
- ✅ Voice recording
- ✅ Reply mode

---

## 🔧 Required Setup

### 1. Dependencies

Already added to `pubspec.yaml`:
```yaml
cached_network_image: ^3.3.1
image_picker: ^1.0.7
video_player: ^2.8.3
record: ^5.0.4
emoji_picker_flutter: ^2.0.0  # ← Newly added
timeago: ^3.6.1
```

Run: `flutter pub get`

### 2. Permissions

**iOS (Info.plist):**
```xml
<key>NSCameraUsageDescription</key>
<string>Take photos to send in chat</string>
<key>NSMicrophoneUsageDescription</key>
<string>Record voice messages</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Select photos to send in chat</string>
```

**Android (AndroidManifest.xml):**
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

### 3. Firebase Configuration

Ensure Firestore and Storage are initialized:
```dart
await Firebase.initializeApp();
```

Collections required:
- `chats` - Chat documents
- `chats/{chatId}/messages` - Message subcollection

---

## 📂 File Structure

```
lib/features/chat/presentation/
├── pages/
│   ├── chat_list_page.dart       # Main chat list
│   └── chat_page.dart            # Individual chat
├── widgets/
│   ├── message_bubble.dart       # Message display
│   ├── chat_list_tile.dart       # Chat list item
│   ├── message_input_widget.dart # Input component
│   ├── media_viewer.dart         # Full-screen viewer
│   └── typing_indicator.dart     # Typing animation
└── providers/
    └── chat_providers.dart       # Riverpod providers
```

---

## 🎨 Customization

### Colors

Edit `/lib/core/themes/app_colors.dart`:
```dart
// Primary Colors
static const Color primary = Color(0xFF00A884); // Change this
static const Color primaryDark = Color(0xFF008069);

// Chat Bubble Colors
static const Color senderBubbleLight = Color(0xFFDCF8C6);
static const Color receiverBubbleLight = Color(0xFFFFFFFF);
```

### Text Styles

Edit `/lib/core/themes/app_text_styles.dart`:
```dart
static const TextStyle chatMessage = TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.w400,
  letterSpacing: 0.25,
  height: 1.4,
);
```

---

## 🔌 Integration Points

### With Authentication

```dart
// Get current user from auth provider
final authState = ref.watch(authStateProvider);
final currentUserId = authState.maybeWhen(
  authenticated: (user) => user.uid,
  orElse: () => null,
);

if (currentUserId != null) {
  ChatListPage(userId: currentUserId);
}
```

### With Contacts

```dart
// When creating new chat from contacts
final createChat = ref.read(createChatProvider);

final result = await createChat(
  CreateChatParams(
    participantIds: [currentUserId, contactUserId],
    type: ChatType.oneToOne,
  ),
);

result.fold(
  (failure) => showError(failure.message),
  (chat) => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ChatPage(
        chatId: chat.id,
        currentUserId: currentUserId,
      ),
    ),
  ),
);
```

### With Notifications

```dart
// When receiving FCM message notification
void onMessageNotification(RemoteMessage message) {
  final chatId = message.data['chatId'];
  final senderId = message.data['senderId'];

  // Navigate to chat
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ChatPage(
        chatId: chatId,
        currentUserId: currentUserId,
      ),
    ),
  );
}
```

---

## 🧪 Testing

### Quick Test Flow

1. **Start app** → See ChatListPage
2. **Tap chat** → Opens ChatPage
3. **Type message** → Tap send → Message appears
4. **Tap attachment** → Select image → Image uploads and appears
5. **Long-press message** → See actions (reply, react, delete)
6. **Tap reply** → Reply mode activates
7. **Send reply** → Reply appears with preview
8. **Swipe chat left** → Delete confirmation
9. **Search chats** → Filters in real-time

### Test with Firebase Emulator

```bash
firebase emulators:start --only firestore,storage
```

Update providers to use emulator:
```dart
final firestore = FirebaseFirestore.instance;
firestore.useFirestoreEmulator('localhost', 8080);

final storage = FirebaseStorage.instance;
storage.useStorageEmulator('localhost', 9199);
```

---

## ⚡ Performance Tips

1. **Pagination:** Load 50 messages at a time
2. **Image Optimization:** Compress before upload
3. **Caching:** Uses cached_network_image automatically
4. **Lazy Loading:** Messages load on-demand
5. **Const Widgets:** Reduces rebuilds

---

## 🐛 Common Issues

### Issue: "Permission denied" when picking images

**Solution:** Add permissions to Info.plist (iOS) and AndroidManifest.xml (Android)

### Issue: "No Firebase App" error

**Solution:** Ensure `Firebase.initializeApp()` is called before using chat

### Issue: Messages not appearing in real-time

**Solution:** Check Firestore rules allow read/write for authenticated users

### Issue: Voice recording not working

**Solution:** Request microphone permission with `permission_handler`

### Issue: Emoji picker not showing

**Solution:** Ensure `emoji_picker_flutter: ^2.0.0` is in pubspec.yaml

---

## 📚 Related Documentation

- Full implementation details: `CHAT_UI_IMPLEMENTATION.md`
- Domain entities: `/domain/entities/`
- Use cases: `/domain/usecases/`
- Data layer: `/data/`

---

## 🎯 Next Steps

1. ✅ UI is complete
2. 🔲 Test with real users
3. 🔲 Add typing indicators
4. 🔲 Add online presence
5. 🔲 Implement group chats
6. 🔲 Add voice/video calls
7. 🔲 Performance optimization

---

**Questions?** Check the full documentation in `CHAT_UI_IMPLEMENTATION.md`
