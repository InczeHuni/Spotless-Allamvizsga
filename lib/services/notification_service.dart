import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  /// Értesítési szerviz inicializálása
  Future<void> init() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();

    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(initSettings);

    // Értesítési csatorna létrehozása Android-on
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'spotless_channel',
      'Spotless Értesítések',
      description: 'Időpontfoglalási és mosási emlékeztető értesítések',
      importance: Importance.max,
    );

    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.createNotificationChannel(channel);
      await androidImplementation.requestNotificationsPermission();
    }

    _isInitialized = true;
  }

  /// Azonnali Push/Helyi értesítés megjelenítése
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await init();

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'spotless_channel',
      'Spotless Értesítések',
      channelDescription: 'Időpontfoglalási és mosási emlékeztető értesítések',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _notificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
    );
  }

  /// Emlékeztető értesítés időzítése a mosás időpontja elé (pl. 2 órával korábban)
  Future<void> scheduleBookingReminder({
    required int bookingIdHash,
    required String serviceName,
    required String carDetails,
    required DateTime startTime,
  }) async {
    await init();

    // Időzítés 2 órával a mosás előtt (vagy ha közelebb van, 15 perccel előtt)
    DateTime reminderTime = startTime.subtract(const Duration(hours: 2));
    if (reminderTime.isBefore(DateTime.now())) {
      reminderTime = startTime.subtract(const Duration(minutes: 15));
    }

    // Ha az emlékeztető még jövőbeli időpontra esik, beidőzítjük
    if (reminderTime.isAfter(DateTime.now())) {
      final tzTime = tz.TZDateTime.from(reminderTime, tz.local);

      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'spotless_channel',
        'Spotless Értesítések',
        channelDescription: 'Időpontfoglalási és mosási emlékeztető értesítések',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      final startStr = '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';

      try {
        await _notificationsPlugin.zonedSchedule(
          bookingIdHash,
          'Spotless Mosási Emlékeztető 🚗',
          'Hamarosan kezdődik a mosásod ($startStr)! Szolgáltatás: $serviceName ($carDetails).',
          tzTime,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        );
      } catch (_) {
        // Fallback Android 12+ inexact módra azon eszközökön, ahol a pontos ébresztő nincs engedélyezve
        await _notificationsPlugin.zonedSchedule(
          bookingIdHash,
          'Spotless Mosási Emlékeztető 🚗',
          'Hamarosan kezdődik a mosásod ($startStr)! Szolgáltatás: $serviceName ($carDetails).',
          tzTime,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    }
  }

  /// Időzített emlékeztető törlése (pl. ha az ügyfél lemondja a foglalást)
  Future<void> cancelReminder(int bookingIdHash) async {
    await _notificationsPlugin.cancel(bookingIdHash);
  }
}
