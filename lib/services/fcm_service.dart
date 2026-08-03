import 'package:flutter/widgets.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../routes/router.dart';

class FCMService {
  static String? pendingRedirectRoute;
  static Map<String, dynamic>? pendingRedirectExtra;

  static Future<void> initialize() async {
    try {
      // Request notifications permission (mainly for iOS & Android 13+)
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      print('🔔 Notification permission status: ${settings.authorizationStatus}');

      // Fetch registration token
      final token = await messaging.getToken();
      print('🔑 Device FCM Registration Token: $token');

      // Foreground message listener
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('🔔 Got a message while in the foreground!');
        print('Message data: ${message.data}');
      });

      // App opened from background message click
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _handleNotificationTap(message);
      });

      // Check if app was opened directly from a terminated state via notification click
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }

      // Background message handler registration wrapper
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    } catch (e) {
      print('Warning: Firebase Messaging is not fully configured for this platform: $e');
    }
  }

  static void _handleNotificationTap(RemoteMessage message) {
    print('🔔 Notification clicked! Data: ${message.data}');
    final data = message.data;
    if (data['type'] == 'chat_message' || data['chatRoomId'] != null) {
      final chatRoomId = data['chatRoomId']?.toString();
      final senderName = data['senderName']?.toString() ?? 'Match';
      final senderPhoto = data['senderPhoto']?.toString() ?? '';

      if (chatRoomId != null && chatRoomId.isNotEmpty) {
        final targetRoute = '/chat/$chatRoomId';
        final targetExtra = {
          'displayName': senderName,
          'photos': senderPhoto.isNotEmpty ? [senderPhoto] : <String>[],
        };

        pendingRedirectRoute = targetRoute;
        pendingRedirectExtra = targetExtra;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          try {
            appRouter.push(targetRoute, extra: targetExtra);
          } catch (e) {
            print('Router push notification navigation notice: $e');
          }
        });
      }
    }
  }

  // Background message handler
  @pragma('vm:entry-point')
  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    await Firebase.initializeApp();
    print("🔔 Handling a background message: ${message.messageId}");
  }
}
