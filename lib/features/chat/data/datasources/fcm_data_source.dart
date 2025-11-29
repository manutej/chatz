import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

/// Data source for managing FCM tokens in Firestore
///
/// Features:
/// - Save device tokens to Firestore
/// - Remove tokens on logout
/// - Query user tokens for sending notifications
/// - Track device info for each token
/// - Handle token refresh
class FCMDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final DeviceInfoPlugin _deviceInfo;

  FCMDataSource({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
    required DeviceInfoPlugin deviceInfo,
  })  : _firestore = firestore,
        _auth = auth,
        _deviceInfo = deviceInfo;

  /// Save device token to Firestore
  ///
  /// Structure:
  /// users/{userId}/deviceTokens/{token}
  /// - token: FCM token
  /// - deviceId: Unique device identifier
  /// - deviceName: Device name/model
  /// - platform: iOS or Android
  /// - createdAt: Timestamp when token was added
  /// - updatedAt: Timestamp when token was last updated
  Future<void> saveDeviceToken(String token) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        debugPrint('⚠️  Cannot save token: User not authenticated');
        return;
      }

      // Get device information
      final deviceData = await _getDeviceInfo();

      // Save token to Firestore
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('deviceTokens')
          .doc(token)
          .set({
        'token': token,
        'deviceId': deviceData['deviceId'],
        'deviceName': deviceData['deviceName'],
        'platform': deviceData['platform'],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('✅ Device token saved to Firestore');
    } catch (e) {
      debugPrint('❌ Error saving device token: $e');
      rethrow;
    }
  }

  /// Remove device token from Firestore
  ///
  /// Call this when:
  /// - User logs out
  /// - User disables notifications
  /// - Token is no longer valid
  Future<void> removeDeviceToken(String token) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        debugPrint('⚠️  Cannot remove token: User not authenticated');
        return;
      }

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('deviceTokens')
          .doc(token)
          .delete();

      debugPrint('✅ Device token removed from Firestore');
    } catch (e) {
      debugPrint('❌ Error removing device token: $e');
      rethrow;
    }
  }

  /// Remove all device tokens for current user
  ///
  /// Call this when user logs out from all devices
  Future<void> removeAllDeviceTokens() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        debugPrint('⚠️  Cannot remove tokens: User not authenticated');
        return;
      }

      final tokensSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('deviceTokens')
          .get();

      final batch = _firestore.batch();

      for (final doc in tokensSnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      debugPrint('✅ All device tokens removed');
    } catch (e) {
      debugPrint('❌ Error removing all tokens: $e');
      rethrow;
    }
  }

  /// Get all device tokens for a specific user
  ///
  /// Use this to send notifications to all user's devices
  /// This would typically be called from Cloud Functions
  Future<List<String>> getUserTokens(String userId) async {
    try {
      final tokensSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('deviceTokens')
          .get();

      return tokensSnapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      debugPrint('❌ Error getting user tokens: $e');
      return [];
    }
  }

  /// Get all device tokens for multiple users
  ///
  /// Use this for group notifications
  /// This would typically be called from Cloud Functions
  Future<List<String>> getMultipleUsersTokens(List<String> userIds) async {
    try {
      final allTokens = <String>[];

      for (final userId in userIds) {
        final tokens = await getUserTokens(userId);
        allTokens.addAll(tokens);
      }

      // Remove duplicates
      return allTokens.toSet().toList();
    } catch (e) {
      debugPrint('❌ Error getting multiple users tokens: $e');
      return [];
    }
  }

  /// Clean up old/invalid tokens
  ///
  /// Remove tokens that haven't been updated in specified days
  /// This should be called periodically (e.g., from Cloud Functions)
  Future<void> cleanupOldTokens({int daysOld = 30}) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        debugPrint('⚠️  Cannot cleanup tokens: User not authenticated');
        return;
      }

      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));

      final tokensSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('deviceTokens')
          .where('updatedAt', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();

      final batch = _firestore.batch();

      for (final doc in tokensSnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      debugPrint('✅ Cleaned up ${tokensSnapshot.docs.length} old tokens');
    } catch (e) {
      debugPrint('❌ Error cleaning up old tokens: $e');
      rethrow;
    }
  }

  /// Get device information
  Future<Map<String, String>> _getDeviceInfo() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return {
          'deviceId': androidInfo.id,
          'deviceName': '${androidInfo.manufacturer} ${androidInfo.model}',
          'platform': 'Android',
        };
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return {
          'deviceId': iosInfo.identifierForVendor ?? 'unknown',
          'deviceName': '${iosInfo.name} ${iosInfo.model}',
          'platform': 'iOS',
        };
      } else {
        return {
          'deviceId': 'unknown',
          'deviceName': 'Unknown Device',
          'platform': 'Unknown',
        };
      }
    } catch (e) {
      debugPrint('❌ Error getting device info: $e');
      return {
        'deviceId': 'unknown',
        'deviceName': 'Unknown Device',
        'platform': 'Unknown',
      };
    }
  }

  /// Update token timestamp (call periodically to mark token as active)
  Future<void> updateTokenTimestamp(String token) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        debugPrint('⚠️  Cannot update token: User not authenticated');
        return;
      }

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('deviceTokens')
          .doc(token)
          .update({
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Token timestamp updated');
    } catch (e) {
      debugPrint('❌ Error updating token timestamp: $e');
      rethrow;
    }
  }

  /// Check if token exists in Firestore
  Future<bool> tokenExists(String token) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        return false;
      }

      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('deviceTokens')
          .doc(token)
          .get();

      return doc.exists;
    } catch (e) {
      debugPrint('❌ Error checking token existence: $e');
      return false;
    }
  }

  /// Get token data
  Future<Map<String, dynamic>?> getTokenData(String token) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        return null;
      }

      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('deviceTokens')
          .doc(token)
          .get();

      return doc.data();
    } catch (e) {
      debugPrint('❌ Error getting token data: $e');
      return null;
    }
  }
}
