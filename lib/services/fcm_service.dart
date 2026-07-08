import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class FCMService {
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

        if (message.notification != null) {
          print('Message also contained a notification: ${message.notification!.title}');
        }
      });

      // App opened from background message click
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('🔔 Notification clicked! Message data: ${message.data}');
      });

      // Background message handler registration wrapper
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    } catch (e) {
      print('Warning: Firebase Messaging is not fully configured for this platform: $e');
    }
  }

  // Background message handler
  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    // Make sure firebase is initialized in background isolate
    await Firebase.initializeApp();
    print("🔔 Handling a background message: ${message.messageId}");
  }
}
