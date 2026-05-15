import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import '../../firebase_options.dart';
import '../../features/notifications/presentation/cubits/notification_badge_cubit.dart';
import '../../features/notifications/domain/usecases/notification_usecases.dart';
import '../di/service_locator.dart';
import '../routing/app_router.dart';

// Channel id MUST match the value declared in AndroidManifest.xml under
// `com.google.firebase.messaging.default_notification_channel_id` and the
// `ChannelId` set by the backend NotificationService when sending FCM messages.
const String _androidChannelId = 'high_importance_channel_v2';
const String _androidChannelName = 'Important Notifications';
const String _androidChannelDescription =
    'Appointments, messages, and account updates with sound and banner.';

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
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    await _initLocalNotifications();
    await _createAndroidChannel();

    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // iOS only: lets the system display banner + play sound while app is in
    // the foreground. Android ignores this and requires an explicit local
    // notification (see _showForegroundNotification below).
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

      _showForegroundNotification(message);

      final type = message.data['type'];
      if (type != 'new_message') {
        try {
          sl<NotificationBadgeCubit>().increment();
        } catch (_) {}
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);

    // Re-upload the FCM token whenever Firebase rotates it.
    // Without this, if the token changes (reinstall, app update, etc.)
    // the backend keeps the stale token and push delivery silently fails.
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      try {
        await sl<RegisterDeviceTokenUseCase>()(newToken);
      } catch (_) {}
    });

    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _handleMessageTap(initialMessage);
      });
    }
  }

  static Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/launcher_icon');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings =
        InitializationSettings(android: androidInit, iOS: iosInit);

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );
  }

  static Future<void> _createAndroidChannel() async {
    // Channels are immutable once created on the device. Sound, importance,
    // and vibration set here are locked in for the lifetime of the install.
    const channel = AndroidNotificationChannel(
      _androidChannelId,
      _androidChannelName,
      description: _androidChannelDescription,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Android 13+ runtime permission for notifications.
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      _androidChannelId,
      _androidChannelName,
      channelDescription: _androidChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/launcher_icon',
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      details,
      payload: jsonEncode(message.data),
    );
  }

  static void _onLocalNotificationTap(NotificationResponse response) {
    final raw = response.payload;
    if (raw == null || raw.isEmpty) return;

    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      _routeForData(data.map((k, v) => MapEntry(k, v?.toString() ?? '')));
    } catch (_) {
      // Malformed payload — fall back to notifications screen.
      AppRouter.navigatorKey.currentContext?.push('/notifications');
    }
  }

  static void _handleMessageTap(RemoteMessage message) {
    _routeForData(message.data.map((k, v) => MapEntry(k, v.toString())));
  }

  static void _routeForData(Map<String, String> data) {
    final referenceId = data['referenceId'];
    final type = data['type'];
    final context = AppRouter.navigatorKey.currentContext;
    if (context == null) return;

    switch (type) {
      case 'appointment_booked':
        context.push(referenceId != null && referenceId.isNotEmpty
            ? '/appointment/$referenceId?doctor=true'
            : '/notifications');

      case 'appointment_confirmed' ||
            'appointment_upcoming' ||
            'appointment_cancelled' ||
            'appointment_completed':
        context.push(referenceId != null && referenceId.isNotEmpty
            ? '/appointment/$referenceId'
            : '/notifications');

      case 'new_message':
        if (referenceId != null && referenceId.isNotEmpty) {
          context.push('/chat/$referenceId');
        }

      case 'doctor_approved' ||
            'doctor_rejected' ||
            'doctor_activated' ||
            'doctor_deactivated':
        context.push('/notifications');

      default:
        context.push('/notifications');
    }
  }
}
