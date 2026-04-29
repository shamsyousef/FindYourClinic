import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import '../../firebase_options.dart';
import '../../features/notifications/presentation/cubits/notification_badge_cubit.dart';
import '../di/service_locator.dart';
import '../routing/app_router.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  if (kDebugMode) {
    print("Handling a background message: ${message.messageId}");
  }
}

class PushNotificationService {
  static Future<void> init() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Foreground notifications
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('Got a message whilst in the foreground!');
        print('Message data: ${message.data}');
      }
      // Increment notification badge for non-chat messages
      final type = message.data['type'];
      if (type != 'new_message') {
        try {
          sl<NotificationBadgeCubit>().increment();
        } catch (_) {}
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleMessageTap(message);
    });

    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      // Need a slight delay to allow router to be ready
      Future.delayed(const Duration(milliseconds: 500), () {
        _handleMessageTap(initialMessage);
      });
    }
  }

  static void _handleMessageTap(RemoteMessage message) {
    final referenceId = message.data['referenceId'];
    final type = message.data['type'];
    
    if (type == 'new_message' && referenceId != null) {
      final context = AppRouter.navigatorKey.currentContext;
      if (context != null) {
        context.push('/chat/$referenceId');
      }
    }
  }
}
