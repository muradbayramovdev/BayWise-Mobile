import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(android: android, iOS: ios);
    await _plugin.initialize(settings);
  }

  /// Android 13+ için bildirim izni iste
  Future<bool> requestPermission() async {
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        final granted = await android.requestNotificationsPermission();
        return granted ?? false;
      }
      return true;
    } catch (e) {
      debugPrint('Bildirim izni hatası: $e');
      return false;
    }
  }

  /// Anlık bildirim gönder (test / manuel tetikleme)
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'baywise_channel',
      'Baywise Bildirimleri',
      channelDescription: 'Tekrarlayan ödeme hatırlatıcıları',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    await _plugin.show(id, title, body, details);
  }

  /// Belirli tarih/saatte bildirim planla (gecikmeli tetikleyici)
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    if (scheduledDate.isBefore(DateTime.now())) return;

    final delay = scheduledDate.difference(DateTime.now());
    Future.delayed(delay, () async {
      await showNotification(id: id, title: title, body: body);
    });
  }

  /// Tüm planlanmış bildirimleri iptal et
  Future<void> cancelAll() => _plugin.cancelAll();

  /// Belirli bildirimi iptal et
  Future<void> cancel(int id) => _plugin.cancel(id);
}
