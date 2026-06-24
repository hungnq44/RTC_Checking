import 'dart:async';
import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';

import '../logger/index.dart';

@lazySingleton
class LocationServiceManager {
  static const _methodChannel = MethodChannel('com.example.rtc_checking/location_service');
  static const _eventChannel = EventChannel('com.example.rtc_checking/location_service/events');

  final LogUtils _log;

  StreamSubscription<dynamic>? _locationSubscription;
  StreamSubscription<dynamic>? _alarmSubscription;

  void Function(double lat, double lng, double distance, bool isInZone)? onLocationUpdate;
  void Function(String title)? onAlarmTriggered;
  void Function()? onAlarmDismissed;

  LocationServiceManager(this._log);

  Future<void> startService({
    required double targetLat,
    required double targetLng,
    required double radius,
    required String title,
    bool notificationEnabled = true,
  }) async {
    try {
      await _methodChannel.invokeMethod('startService', {
        'targetLat': targetLat,
        'targetLng': targetLng,
        'radius': radius,
        'title': title,
        'notificationEnabled': notificationEnabled,
      });
      _startListening();
      _log.logI('LocationService started: $title');
    } catch (e) {
      _log.logE('Failed to start LocationService: $e');
      rethrow;
    }
  }

  Future<void> stopService() async {
    try {
      await _methodChannel.invokeMethod('stopService');
      _stopListening();
      _log.logI('LocationService stopped');
    } catch (e) {
      _log.logE('Failed to stop LocationService: $e');
      rethrow;
    }
  }

  Future<void> updateTarget({
    required double targetLat,
    required double targetLng,
    required double radius,
    required String title,
  }) async {
    try {
      await _methodChannel.invokeMethod('updateTarget', {
        'targetLat': targetLat,
        'targetLng': targetLng,
        'radius': radius,
        'title': title,
      });
      _log.logI('LocationService target updated: $title');
    } catch (e) {
      _log.logE('Failed to update LocationService target: $e');
      rethrow;
    }
  }

  Future<void> dismissAlarm() async {
    try {
      await _methodChannel.invokeMethod('dismissAlarm');
      _log.logI('Alarm dismissed');
    } catch (e) {
      _log.logE('Failed to dismiss alarm: $e');
      rethrow;
    }
  }

  Future<void> enableAlarm() async {
    try {
      await _methodChannel.invokeMethod('enableAlarm');
      _log.logI('Alarm enabled');
    } catch (e) {
      _log.logE('Failed to enable alarm: $e');
      rethrow;
    }
  }

  Future<void> disableAlarm() async {
    try {
      await _methodChannel.invokeMethod('disableAlarm');
      _log.logI('Alarm disabled');
    } catch (e) {
      _log.logE('Failed to disable alarm: $e');
      rethrow;
    }
  }

  Future<bool> isAlarmActive() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('isAlarmActive');
      return result ?? false;
    } catch (e) {
      _log.logE('Failed to check alarm status: $e');
      return false;
    }
  }

  Future<bool> isServiceRunning() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('isServiceRunning');
      return result ?? false;
    } catch (e) {
      _log.logE('Failed to check service status: $e');
      return false;
    }
  }

  void _startListening() {
    _locationSubscription?.cancel();
    _alarmSubscription?.cancel();

    _locationSubscription = _eventChannel.receiveBroadcastStream().listen(
      (event) {
        if (event is Map) {
          final type = event['type'] as String?;
          switch (type) {
            case 'location':
              final lat = (event['lat'] as num?)?.toDouble() ?? 0.0;
              final lng = (event['lng'] as num?)?.toDouble() ?? 0.0;
              final distance = (event['distance'] as num?)?.toDouble() ?? 0.0;
              final isInZone = event['isInZone'] as bool? ?? false;
              onLocationUpdate?.call(lat, lng, distance, isInZone);
              break;
            case 'alarm':
              final title = event['title'] as String? ?? 'Vị trí';
              onAlarmTriggered?.call(title);
              break;
            case 'dismissed':
              onAlarmDismissed?.call();
              break;
          }
        }
      },
      onError: (error) {
        _log.logE('LocationService event error: $error');
      },
    );
  }

  void _stopListening() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
    _alarmSubscription?.cancel();
    _alarmSubscription = null;
  }

  void dispose() {
    _stopListening();
  }
}
