import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:chatz/features/auth/domain/entities/user_entity.dart';

part 'auth_state.freezed.dart';

/// Authentication state using Freezed
/// Represents all possible authentication states in the app
@freezed
class AuthState with _$AuthState {
  const factory AuthState.initial() = _Initial;
  
  const factory AuthState.loading() = _Loading;
  
  const factory AuthState.authenticated(UserEntity user) = _Authenticated;
  
  const factory AuthState.unauthenticated() = _Unauthenticated;
  
  const factory AuthState.error(String message) = _Error;
  
  const factory AuthState.verificationCodeSent(String verificationId) = 
      _VerificationCodeSent;
  
  const factory AuthState.profileIncomplete(UserEntity user) = 
      _ProfileIncomplete;
}
