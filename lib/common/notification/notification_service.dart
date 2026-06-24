import 'dart:typed_data';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:injectable/injectable.dart';

import '../logger/index.dart';

@lazySingleton
class NotificationService {
  static const int _inZoneNotificationId = 1001;
  static const String _dismissActionId = 'dismiss_action';
  static const String _alarmChannelId = 'alarm_channel';

  static NotificationService? _instance;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final LogUtils _log;

  VoidCallback? _onDismissNotification;
  Function(bool isPlaying)? _onAlarmStateChanged;

  NotificationService(this._log) {
    _instance = this;
  }

  void setOnDismissCallback(VoidCallback callback) {
    _onDismissNotification = callback;
  }

  void setOnAlarmStateChanged(Function(bool isPlaying) callback) {
    _onAlarmStateChanged = callback;
  }

  Future<void> init() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    final initSettings = InitializationSettings(android: androidInit);

    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidImpl?.requestNotificationsPermission();

    await _createNotificationChannels(androidImpl);

    _log.logI('NotificationService initialized');
  }

  Future<void> _createNotificationChannels(
    AndroidFlutterLocalNotificationsPlugin? androidImpl,
  ) async {
    if (androidImpl == null) return;

    final channel = AndroidNotificationChannel(
      _alarmChannelId,
      'Thông báo vị trí',
      description: 'Thông báo khi đến vị trí',
      importance: Importance.max,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 500, 250, 500]),
      playSound: true,
    );
    await androidImpl.createNotificationChannel(channel);

    _log.logI('Notification channels created');
  }

  void _onNotificationResponse(NotificationResponse response) {
    _log.logI(
      'Notification response: actionId=${response.actionId}, '
      'payload=${response.payload}',
    );
    if (response.actionId == _dismissActionId) {
      _instance?.stopAlarm();
      _onDismissNotification?.call();
    }
  }

  final Map<String, bool> _locationNotificationEnabled = {};

  bool isLocationNotificationEnabled(String locationId) {
    return _locationNotificationEnabled[locationId] ?? true;
  }

  void enableLocationNotification(String locationId) {
    _locationNotificationEnabled[locationId] = true;
    _log.logI('Notification enabled for location: $locationId');
  }

  void disableLocationNotification(String locationId) {
    _locationNotificationEnabled[locationId] = false;
    _log.logI('Notification disabled for location: $locationId');
  }

  Future<void> startAlarm({String? locationId, String? locationTitle}) async {
    // Check if notification is enabled for this location
    if (locationId != null && !isLocationNotificationEnabled(locationId)) {
      _log.logI('Notification disabled for location: $locationId');
      return;
    }

    final title = locationTitle ?? 'vị trí';

    final androidDetails = AndroidNotificationDetails(
      _alarmChannelId,
      'Thông báo vị trí',
      channelDescription: 'Thông báo khi đến vị trí',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 500, 250, 500]),
      category: AndroidNotificationCategory.alarm,
      ongoing: true,
      autoCancel: false,
      fullScreenIntent: true,
      actions: const <AndroidNotificationAction>[
        AndroidNotificationAction(
          _dismissActionId,
          'DỪNG',
          showsUserInterface: true,
        ),
      ],
    );

    final details = NotificationDetails(android: androidDetails);

    await _plugin.show(
      id: _inZoneNotificationId,
      title: 'Bạn đang ở $title',
      body: 'Nhấn DỪNG để tắt thông báo.',
      notificationDetails: details,
    );

    _onAlarmStateChanged?.call(true);
    _log.logI('Alarm started for: $title');
  }

  Future<void> stopAlarm() async {
    await _plugin.cancel(id: _inZoneNotificationId);
    _onAlarmStateChanged?.call(false);
    _log.logI('Alarm stopped');
  }

  Future<void> cancelInZoneNotification() async {
    await _plugin.cancel(id: _inZoneNotificationId);
    _onAlarmStateChanged?.call(false);
    _log.logI('In-zone notification cancelled');
  }
}

typedef VoidCallback = void Function();
