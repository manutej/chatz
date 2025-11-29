import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:chatz/core/errors/exceptions.dart';
import 'package:chatz/features/auth/data/models/user_model.dart';

/// Remote data source for authentication operations
/// Handles all Firebase Auth and Firestore operations
abstract class AuthRemoteDataSource {
  Future<String> signInWithPhone(String phoneNumber);
  Future<UserModel> verifyOtp({
    required String verificationId,
    required String smsCode,
  });
  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  });
  Future<UserModel> signInWithGoogle();
  Future<UserModel> signInWithApple();
  Future<UserModel> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
  });
  Future<void> signOut();
  Future<UserModel?> getCurrentUser();
  Future<UserModel> updateProfile({
    String? displayName,
    String? photoUrl,
    String? bio,
  });
  Future<void> sendPasswordResetEmail(String email);
  Future<bool> isAuthenticated();
  Future<void> enableBiometric();
  Future<UserModel> authenticateWithBiometric();
  Stream<UserModel?> get authStateChanges;
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth firebaseAuth;
  final FirebaseFirestore firestore;
  final GoogleSignIn googleSignIn;
  final FlutterSecureStorage secureStorage;
  final LocalAuthentication localAuth;

  AuthRemoteDataSourceImpl({
    required this.firebaseAuth,
    required this.firestore,
    required this.googleSignIn,
    required this.secureStorage,
    required this.localAuth,
  });

  @override
  Future<String> signInWithPhone(String phoneNumber) async {
    try {
      String? verificationId;
      
      await firebaseAuth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification (Android only)
          await firebaseAuth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          throw AuthException(e.message ?? 'Phone verification failed');
        },
        codeSent: (String verId, int? resendToken) {
          verificationId = verId;
        },
        timeout: const Duration(seconds: 60),
        codeAutoRetrievalTimeout: (String verId) {
          verificationId = verId;
        },
      );

      // Wait for verification ID to be set
      await Future.delayed(const Duration(seconds: 2));
      
      if (verificationId == null) {
        throw const AuthException('Failed to send verification code');
      }

      return verificationId!;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e));
    } catch (e) {
      throw AuthException('Failed to sign in with phone: $e');
    }
  }

  @override
  Future<UserModel> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      final userCredential = await firebaseAuth.signInWithCredential(credential);
      
      if (userCredential.user == null) {
        throw const AuthException('Failed to verify OTP');
      }

      return await _createOrUpdateUser(userCredential.user!);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e));
    } catch (e) {
      throw AuthException('Failed to verify OTP: $e');
    }
  }

  @override
  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw const AuthException('Failed to sign in');
      }

      return await _createOrUpdateUser(userCredential.user!);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e));
    } catch (e) {
      throw AuthException('Failed to sign in with email: $e');
    }
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    try {
      final googleUser = await googleSignIn.signIn();
      
      if (googleUser == null) {
        throw const AuthException('Google sign in cancelled');
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await firebaseAuth.signInWithCredential(credential);
      
      if (userCredential.user == null) {
        throw const AuthException('Failed to sign in with Google');
      }

      return await _createOrUpdateUser(userCredential.user!);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e));
    } catch (e) {
      throw AuthException('Failed to sign in with Google: $e');
    }
  }

  @override
  Future<UserModel> signInWithApple() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final userCredential = await firebaseAuth.signInWithCredential(
        oauthCredential,
      );

      if (userCredential.user == null) {
        throw const AuthException('Failed to sign in with Apple');
      }

      return await _createOrUpdateUser(userCredential.user!);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e));
    } catch (e) {
      throw AuthException('Failed to sign in with Apple: $e');
    }
  }

  @override
  Future<UserModel> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final userCredential = await firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw const AuthException('Failed to register');
      }

      // Update display name
      await userCredential.user!.updateDisplayName(displayName);

      return await _createOrUpdateUser(
        userCredential.user!,
        displayName: displayName,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e));
    } catch (e) {
      throw AuthException('Failed to register: $e');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      // Update online status before signing out
      final currentUser = firebaseAuth.currentUser;
      if (currentUser != null) {
        await firestore.collection('users').doc(currentUser.uid).update({
          'isOnline': false,
          'lastSeen': FieldValue.serverTimestamp(),
        });
      }

      await Future.wait([
        firebaseAuth.signOut(),
        googleSignIn.signOut(),
      ]);

      // Clear biometric credentials
      await secureStorage.delete(key: 'biometric_enabled');
    } catch (e) {
      throw AuthException('Failed to sign out: $e');
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final user = firebaseAuth.currentUser;
      if (user == null) return null;

      final doc = await firestore.collection('users').doc(user.uid).get();
      
      if (!doc.exists) {
        return await _createOrUpdateUser(user);
      }

      return UserModel.fromFirestore(doc.data()!, doc.id);
    } catch (e) {
      throw AuthException('Failed to get current user: $e');
    }
  }

  @override
  Future<UserModel> updateProfile({
    String? displayName,
    String? photoUrl,
    String? bio,
  }) async {
    try {
      final user = firebaseAuth.currentUser;
      if (user == null) {
        throw const AuthException('No user signed in');
      }

      final updates = <String, dynamic>{};
      
      if (displayName != null) {
        await user.updateDisplayName(displayName);
        updates['displayName'] = displayName;
      }
      
      if (photoUrl != null) {
        await user.updatePhotoURL(photoUrl);
        updates['photoUrl'] = photoUrl;
      }
      
      if (bio != null) {
        updates['bio'] = bio;
      }

      if (updates.isNotEmpty) {
        await firestore.collection('users').doc(user.uid).update(updates);
      }

      return await getCurrentUser() ?? 
          throw const AuthException('Failed to update profile');
    } catch (e) {
      throw AuthException('Failed to update profile: $e');
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e));
    } catch (e) {
      throw AuthException('Failed to send password reset email: $e');
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    return firebaseAuth.currentUser != null;
  }

  @override
  Future<void> enableBiometric() async {
    try {
      final user = firebaseAuth.currentUser;
      if (user == null) {
        throw const AuthException('No user signed in');
      }

      final canAuthenticate = await localAuth.canCheckBiometrics;
      if (!canAuthenticate) {
        throw const AuthException('Biometric authentication not available');
      }

      await secureStorage.write(
        key: 'biometric_enabled',
        value: user.uid,
      );
    } catch (e) {
      throw AuthException('Failed to enable biometric: $e');
    }
  }

  @override
  Future<UserModel> authenticateWithBiometric() async {
    try {
      final authenticated = await localAuth.authenticate(
        localizedReason: 'Authenticate to access your account',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (!authenticated) {
        throw const AuthException('Biometric authentication failed');
      }

      final userId = await secureStorage.read(key: 'biometric_enabled');
      if (userId == null) {
        throw const AuthException('Biometric not enabled');
      }

      final user = await getCurrentUser();
      if (user == null || user.id != userId) {
        throw const AuthException('User mismatch');
      }

      return user;
    } catch (e) {
      throw AuthException('Failed to authenticate with biometric: $e');
    }
  }

  @override
  Stream<UserModel?> get authStateChanges {
    return firebaseAuth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      return await getCurrentUser();
    });
  }

  /// Create or update user in Firestore
  Future<UserModel> _createOrUpdateUser(
    User user, {
    String? displayName,
  }) async {
    final userDoc = firestore.collection('users').doc(user.uid);
    final docSnapshot = await userDoc.get();

    final now = DateTime.now();
    
    if (docSnapshot.exists) {
      // Update existing user
      await userDoc.update({
        'lastSeen': FieldValue.serverTimestamp(),
        'isOnline': true,
      });
      
      return UserModel.fromFirestore(docSnapshot.data()!, docSnapshot.id);
    } else {
      // Create new user
      final userModel = UserModel(
        id: user.uid,
        email: user.email,
        phoneNumber: user.phoneNumber,
        displayName: displayName ?? user.displayName,
        photoUrl: user.photoURL,
        createdAt: now,
        lastSeen: now,
        isOnline: true,
        isEmailVerified: user.emailVerified,
        isPhoneVerified: user.phoneNumber != null,
      );

      await userDoc.set(userModel.toFirestore());
      
      return userModel;
    }
  }

  /// Map Firebase Auth errors to user-friendly messages
  String _mapFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Invalid password';
      case 'email-already-in-use':
        return 'Email is already registered';
      case 'invalid-email':
        return 'Invalid email address';
      case 'weak-password':
        return 'Password is too weak';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many requests. Please try again later';
      case 'operation-not-allowed':
        return 'Operation not allowed';
      case 'invalid-verification-code':
        return 'Invalid verification code';
      case 'invalid-verification-id':
        return 'Invalid verification ID';
      case 'session-expired':
        return 'Session expired. Please try again';
      default:
        return e.message ?? 'Authentication failed';
    }
  }
}
