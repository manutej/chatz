import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chatz/features/chat/data/datasources/chat_remote_data_source.dart';
import 'package:chatz/features/chat/data/datasources/message_remote_data_source.dart';
import 'package:chatz/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:chatz/features/chat/data/repositories/message_repository_impl.dart';
import 'package:chatz/features/chat/domain/repositories/chat_repository.dart';
import 'package:chatz/features/chat/domain/repositories/message_repository.dart';
import 'package:chatz/features/chat/domain/usecases/get_user_chats.dart';
import 'package:chatz/features/chat/domain/usecases/get_chat_messages.dart';
import 'package:chatz/features/chat/domain/usecases/send_message.dart';
import 'package:chatz/features/chat/domain/usecases/create_chat.dart';
import 'package:chatz/features/chat/domain/usecases/mark_messages_as_read.dart';

// ============================================================================
// Firestore & Firebase Providers
// ============================================================================

/// Provider for Firestore instance
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

/// Provider for Firebase Storage instance
final storageProvider = Provider<FirebaseStorage>((ref) {
  return FirebaseStorage.instance;
});

// ============================================================================
// Data Source Providers
// ============================================================================

/// Provider for ChatRemoteDataSource
final chatRemoteDataSourceProvider = Provider<ChatRemoteDataSource>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return ChatRemoteDataSourceImpl(firestore);
});

/// Provider for MessageRemoteDataSource
final messageRemoteDataSourceProvider =
    Provider<MessageRemoteDataSource>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final storage = ref.watch(storageProvider);
  return MessageRemoteDataSourceImpl(firestore, storage);
});

// ============================================================================
// Repository Providers
// ============================================================================

/// Provider for ChatRepository
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final remoteDataSource = ref.watch(chatRemoteDataSourceProvider);
  return ChatRepositoryImpl(remoteDataSource);
});

/// Provider for MessageRepository
final messageRepositoryProvider = Provider<MessageRepository>((ref) {
  final remoteDataSource = ref.watch(messageRemoteDataSourceProvider);
  return MessageRepositoryImpl(remoteDataSource);
});

// ============================================================================
// Use Case Providers
// ============================================================================

/// Provider for GetUserChats use case
final getUserChatsProvider = Provider<GetUserChats>((ref) {
  final repository = ref.watch(chatRepositoryProvider);
  return GetUserChats(repository);
});

/// Provider for GetChatMessages use case
final getChatMessagesProvider = Provider<GetChatMessages>((ref) {
  final repository = ref.watch(messageRepositoryProvider);
  return GetChatMessages(repository);
});

/// Provider for SendMessage use case
final sendMessageProvider = Provider<SendMessage>((ref) {
  final repository = ref.watch(messageRepositoryProvider);
  return SendMessage(repository);
});

/// Provider for CreateChat use case
final createChatProvider = Provider<CreateChat>((ref) {
  final repository = ref.watch(chatRepositoryProvider);
  return CreateChat(repository);
});

/// Provider for MarkMessagesAsRead use case
final markMessagesAsReadProvider = Provider<MarkMessagesAsRead>((ref) {
  final repository = ref.watch(messageRepositoryProvider);
  return MarkMessagesAsRead(repository);
});

// ============================================================================
// Stream Providers for Real-time Data
// ============================================================================

/// Stream provider for user's chats with real-time updates
/// Usage: ref.watch(userChatsStreamProvider(userId))
final userChatsStreamProvider = StreamProvider.family((ref, String userId) {
  final getUserChats = ref.watch(getUserChatsProvider);
  return getUserChats(userId);
});

/// Stream provider for chat messages with real-time updates
/// Usage: ref.watch(chatMessagesStreamProvider(chatId))
final chatMessagesStreamProvider =
    StreamProvider.family((ref, String chatId) {
  final getChatMessages = ref.watch(getChatMessagesProvider);
  return getChatMessages(GetChatMessagesParams(chatId: chatId));
});
