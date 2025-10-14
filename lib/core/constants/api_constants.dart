/// API and Firebase constants
class ApiConstants {
  ApiConstants._();

  // Base URLs
  static const String baseUrl = 'https://api.chatz.com/v1';
  static const String socketUrl = 'wss://socket.chatz.com';

  // Endpoints
  static const String authEndpoint = '/auth';
  static const String loginEndpoint = '$authEndpoint/login';
  static const String registerEndpoint = '$authEndpoint/register';
  static const String verifyPhoneEndpoint = '$authEndpoint/verify-phone';
  static const String logoutEndpoint = '$authEndpoint/logout';

  static const String usersEndpoint = '/users';
  static const String profileEndpoint = '$usersEndpoint/profile';
  static const String updateProfileEndpoint = '$usersEndpoint/update';

  static const String chatsEndpoint = '/chats';
  static const String messagesEndpoint = '/messages';
  static const String sendMessageEndpoint = '$messagesEndpoint/send';

  static const String callsEndpoint = '/calls';
  static const String initiateCallEndpoint = '$callsEndpoint/initiate';
  static const String endCallEndpoint = '$callsEndpoint/end';
  static const String callHistoryEndpoint = '$callsEndpoint/history';

  static const String paymentsEndpoint = '/payments';
  static const String rechargeEndpoint = '$paymentsEndpoint/recharge';
  static const String transactionHistoryEndpoint = '$paymentsEndpoint/history';
  static const String walletBalanceEndpoint = '$paymentsEndpoint/balance';

  static const String contactsEndpoint = '/contacts';
  static const String syncContactsEndpoint = '$contactsEndpoint/sync';

  static const String statusEndpoint = '/status';
  static const String uploadStatusEndpoint = '$statusEndpoint/upload';
  static const String viewStatusEndpoint = '$statusEndpoint/view';

  static const String mediaEndpoint = '/media';
  static const String uploadMediaEndpoint = '$mediaEndpoint/upload';

  // Stripe
  static const String stripePublishableKey =
      'pk_test_YOUR_PUBLISHABLE_KEY'; // Replace with actual key
  static const String stripeMerchantId = 'merchant.com.chatz.app';

  // Agora (for WebRTC)
  static const String agoraAppId =
      'YOUR_AGORA_APP_ID'; // Replace with actual app ID

  // Firebase Collections
  static const String usersCollection = 'users';
  static const String chatsCollection = 'chats';
  static const String messagesCollection = 'messages';
  static const String callsCollection = 'calls';
  static const String statusCollection = 'status';
  static const String transactionsCollection = 'transactions';

  // Firebase Storage Paths
  static const String profileImagesPath = 'profile_images';
  static const String chatMediaPath = 'chat_media';
  static const String statusMediaPath = 'status_media';
  static const String voiceMessagesPath = 'voice_messages';

  // Socket Events
  static const String socketConnect = 'connect';
  static const String socketDisconnect = 'disconnect';
  static const String socketNewMessage = 'new_message';
  static const String socketTyping = 'typing';
  static const String socketStopTyping = 'stop_typing';
  static const String socketOnline = 'online';
  static const String socketOffline = 'offline';
  static const String socketMessageDelivered = 'message_delivered';
  static const String socketMessageRead = 'message_read';
  static const String socketIncomingCall = 'incoming_call';
  static const String socketCallAccepted = 'call_accepted';
  static const String socketCallRejected = 'call_rejected';
  static const String socketCallEnded = 'call_ended';

  // Headers
  static const String authHeader = 'Authorization';
  static const String contentTypeHeader = 'Content-Type';
  static const String acceptHeader = 'Accept';
  static const String applicationJson = 'application/json';
}
