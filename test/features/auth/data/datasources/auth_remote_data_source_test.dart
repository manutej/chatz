import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:chatz/core/errors/exceptions.dart';
import 'package:chatz/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:chatz/features/auth/data/models/user_model.dart';

// Mocks
class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockGoogleSignIn extends Mock implements GoogleSignIn {}
class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}
class MockLocalAuthentication extends Mock implements LocalAuthentication {}
class MockUserCredential extends Mock implements UserCredential {}
class MockUser extends Mock implements User {}
class MockCollectionReference extends Mock implements CollectionReference<Map<String, dynamic>> {}
class MockDocumentReference extends Mock implements DocumentReference<Map<String, dynamic>> {}
class MockDocumentSnapshot extends Mock implements DocumentSnapshot<Map<String, dynamic>> {}
class MockGoogleSignInAccount extends Mock implements GoogleSignInAccount {}
class MockGoogleSignInAuthentication extends Mock implements GoogleSignInAuthentication {}

void main() {
  late AuthRemoteDataSourceImpl dataSource;
  late MockFirebaseAuth mockFirebaseAuth;
  late MockFirebaseFirestore mockFirestore;
  late MockGoogleSignIn mockGoogleSignIn;
  late MockFlutterSecureStorage mockSecureStorage;
  late MockLocalAuthentication mockLocalAuth;

  setUp(() {
    mockFirebaseAuth = MockFirebaseAuth();
    mockFirestore = MockFirebaseFirestore();
    mockGoogleSignIn = MockGoogleSignIn();
    mockSecureStorage = MockFlutterSecureStorage();
    mockLocalAuth = MockLocalAuthentication();

    dataSource = AuthRemoteDataSourceImpl(
      firebaseAuth: mockFirebaseAuth,
      firestore: mockFirestore,
      googleSignIn: mockGoogleSignIn,
      secureStorage: mockSecureStorage,
      localAuth: mockLocalAuth,
    );
  });

  group('AuthRemoteDataSource', () {
    group('signInWithPhone', () {
      const tPhoneNumber = '+1234567890';

      test('should return verification ID when phone auth succeeds', () async {
        // arrange
        String? capturedVerificationId;

        when(() => mockFirebaseAuth.verifyPhoneNumber(
              phoneNumber: any(named: 'phoneNumber'),
              verificationCompleted: any(named: 'verificationCompleted'),
              verificationFailed: any(named: 'verificationFailed'),
              codeSent: any(named: 'codeSent'),
              timeout: any(named: 'timeout'),
              codeAutoRetrievalTimeout: any(named: 'codeAutoRetrievalTimeout'),
            )).thenAnswer((invocation) async {
          final codeSent = invocation.namedArguments[const Symbol('codeSent')]
              as void Function(String, int?);
          codeSent('verification_id_123', 12345);
        });

        // act
        final result = await dataSource.signInWithPhone(tPhoneNumber);

        // assert
        expect(result, isA<String>());
        verify(() => mockFirebaseAuth.verifyPhoneNumber(
              phoneNumber: tPhoneNumber,
              verificationCompleted: any(named: 'verificationCompleted'),
              verificationFailed: any(named: 'verificationFailed'),
              codeSent: any(named: 'codeSent'),
              timeout: any(named: 'timeout'),
              codeAutoRetrievalTimeout: any(named: 'codeAutoRetrievalTimeout'),
            )).called(1);
      });

      test('should throw AuthException when verification fails', () async {
        // arrange
        when(() => mockFirebaseAuth.verifyPhoneNumber(
              phoneNumber: any(named: 'phoneNumber'),
              verificationCompleted: any(named: 'verificationCompleted'),
              verificationFailed: any(named: 'verificationFailed'),
              codeSent: any(named: 'codeSent'),
              timeout: any(named: 'timeout'),
              codeAutoRetrievalTimeout: any(named: 'codeAutoRetrievalTimeout'),
            )).thenAnswer((invocation) async {
          final verificationFailed = invocation.namedArguments[const Symbol('verificationFailed')]
              as void Function(FirebaseAuthException);
          verificationFailed(FirebaseAuthException(code: 'invalid-phone-number'));
        });

        // assert
        expect(
          () => dataSource.signInWithPhone(tPhoneNumber),
          throwsA(isA<AuthException>()),
        );
      });
    });

    group('signInWithEmail', () {
      const tEmail = 'test@example.com';
      const tPassword = 'password123';

      test('should return UserModel when email sign in succeeds', () async {
        // arrange
        final mockUser = MockUser();
        final mockUserCredential = MockUserCredential();
        final mockDocRef = MockDocumentReference();
        final mockDocSnapshot = MockDocumentSnapshot();
        final mockCollection = MockCollectionReference();

        when(() => mockUser.uid).thenReturn('user_123');
        when(() => mockUser.email).thenReturn(tEmail);
        when(() => mockUser.phoneNumber).thenReturn(null);
        when(() => mockUser.displayName).thenReturn('Test User');
        when(() => mockUser.photoURL).thenReturn(null);
        when(() => mockUser.emailVerified).thenReturn(true);

        when(() => mockUserCredential.user).thenReturn(mockUser);

        when(() => mockFirebaseAuth.signInWithEmailAndPassword(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenAnswer((_) async => mockUserCredential);

        when(() => mockFirestore.collection('users')).thenReturn(mockCollection);
        when(() => mockCollection.doc(any())).thenReturn(mockDocRef);
        when(() => mockDocRef.get()).thenAnswer((_) async => mockDocSnapshot);
        when(() => mockDocSnapshot.exists).thenReturn(false);
        when(() => mockDocRef.set(any())).thenAnswer((_) async {});

        // act
        final result = await dataSource.signInWithEmail(
          email: tEmail,
          password: tPassword,
        );

        // assert
        expect(result, isA<UserModel>());
        expect(result.email, tEmail);
        verify(() => mockFirebaseAuth.signInWithEmailAndPassword(
              email: tEmail,
              password: tPassword,
            )).called(1);
      });

      test('should throw AuthException when credentials are invalid', () async {
        // arrange
        when(() => mockFirebaseAuth.signInWithEmailAndPassword(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenThrow(FirebaseAuthException(code: 'wrong-password'));

        // assert
        expect(
          () => dataSource.signInWithEmail(email: tEmail, password: tPassword),
          throwsA(isA<AuthException>()),
        );
      });
    });

    group('signInWithGoogle', () {
      test('should return UserModel when Google sign in succeeds', () async {
        // arrange
        final mockGoogleUser = MockGoogleSignInAccount();
        final mockGoogleAuth = MockGoogleSignInAuthentication();
        final mockUser = MockUser();
        final mockUserCredential = MockUserCredential();
        final mockDocRef = MockDocumentReference();
        final mockDocSnapshot = MockDocumentSnapshot();
        final mockCollection = MockCollectionReference();

        when(() => mockGoogleSignIn.signIn())
            .thenAnswer((_) async => mockGoogleUser);
        when(() => mockGoogleUser.authentication)
            .thenAnswer((_) async => mockGoogleAuth);
        when(() => mockGoogleAuth.accessToken).thenReturn('access_token');
        when(() => mockGoogleAuth.idToken).thenReturn('id_token');

        when(() => mockUser.uid).thenReturn('user_123');
        when(() => mockUser.email).thenReturn('test@gmail.com');
        when(() => mockUser.displayName).thenReturn('Test User');
        when(() => mockUser.photoURL).thenReturn('https://example.com/photo.jpg');
        when(() => mockUser.phoneNumber).thenReturn(null);
        when(() => mockUser.emailVerified).thenReturn(true);

        when(() => mockUserCredential.user).thenReturn(mockUser);
        when(() => mockFirebaseAuth.signInWithCredential(any()))
            .thenAnswer((_) async => mockUserCredential);

        when(() => mockFirestore.collection('users')).thenReturn(mockCollection);
        when(() => mockCollection.doc(any())).thenReturn(mockDocRef);
        when(() => mockDocRef.get()).thenAnswer((_) async => mockDocSnapshot);
        when(() => mockDocSnapshot.exists).thenReturn(false);
        when(() => mockDocRef.set(any())).thenAnswer((_) async {});

        // act
        final result = await dataSource.signInWithGoogle();

        // assert
        expect(result, isA<UserModel>());
        verify(() => mockGoogleSignIn.signIn()).called(1);
        verify(() => mockFirebaseAuth.signInWithCredential(any())).called(1);
      });

      test('should throw AuthException when user cancels', () async {
        // arrange
        when(() => mockGoogleSignIn.signIn()).thenAnswer((_) async => null);

        // assert
        expect(
          () => dataSource.signInWithGoogle(),
          throwsA(isA<AuthException>()),
        );
      });
    });

    group('signOut', () {
      test('should sign out successfully', () async {
        // arrange
        final mockUser = MockUser();
        final mockDocRef = MockDocumentReference();
        final mockCollection = MockCollectionReference();

        when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);
        when(() => mockUser.uid).thenReturn('user_123');
        when(() => mockFirestore.collection('users')).thenReturn(mockCollection);
        when(() => mockCollection.doc(any())).thenReturn(mockDocRef);
        when(() => mockDocRef.update(any())).thenAnswer((_) async {});
        when(() => mockFirebaseAuth.signOut()).thenAnswer((_) async {});
        when(() => mockGoogleSignIn.signOut()).thenAnswer((_) async => null);
        when(() => mockSecureStorage.delete(key: any(named: 'key')))
            .thenAnswer((_) async {});

        // act
        await dataSource.signOut();

        // assert
        verify(() => mockFirebaseAuth.signOut()).called(1);
        verify(() => mockGoogleSignIn.signOut()).called(1);
        verify(() => mockSecureStorage.delete(key: 'biometric_enabled')).called(1);
      });

      test('should throw AuthException when sign out fails', () async {
        // arrange
        when(() => mockFirebaseAuth.currentUser).thenReturn(null);
        when(() => mockFirebaseAuth.signOut())
            .thenThrow(Exception('Sign out failed'));

        // assert
        expect(
          () => dataSource.signOut(),
          throwsA(isA<AuthException>()),
        );
      });
    });

    group('getCurrentUser', () {
      test('should return UserModel when user is signed in', () async {
        // arrange
        final mockUser = MockUser();
        final mockDocRef = MockDocumentReference();
        final mockDocSnapshot = MockDocumentSnapshot();
        final mockCollection = MockCollectionReference();

        when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);
        when(() => mockUser.uid).thenReturn('user_123');

        when(() => mockFirestore.collection('users')).thenReturn(mockCollection);
        when(() => mockCollection.doc(any())).thenReturn(mockDocRef);
        when(() => mockDocRef.get()).thenAnswer((_) async => mockDocSnapshot);
        when(() => mockDocSnapshot.exists).thenReturn(true);
        when(() => mockDocSnapshot.id).thenReturn('user_123');
        when(() => mockDocSnapshot.data()).thenReturn({
          'email': 'test@example.com',
          'phoneNumber': null,
          'displayName': 'Test User',
          'photoUrl': null,
          'bio': null,
          'createdAt': 1704067200000,
          'lastSeen': null,
          'isOnline': false,
          'isEmailVerified': true,
          'isPhoneVerified': false,
          'deviceTokens': [],
          'metadata': null,
        });

        // act
        final result = await dataSource.getCurrentUser();

        // assert
        expect(result, isA<UserModel>());
        expect(result?.id, 'user_123');
        verify(() => mockFirebaseAuth.currentUser).called(1);
      });

      test('should return null when no user is signed in', () async {
        // arrange
        when(() => mockFirebaseAuth.currentUser).thenReturn(null);

        // act
        final result = await dataSource.getCurrentUser();

        // assert
        expect(result, null);
      });
    });

    group('isAuthenticated', () {
      test('should return true when user is signed in', () async {
        // arrange
        final mockUser = MockUser();
        when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);

        // act
        final result = await dataSource.isAuthenticated();

        // assert
        expect(result, true);
      });

      test('should return false when no user is signed in', () async {
        // arrange
        when(() => mockFirebaseAuth.currentUser).thenReturn(null);

        // act
        final result = await dataSource.isAuthenticated();

        // assert
        expect(result, false);
      });
    });
  });
}
