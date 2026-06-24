import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../common/logger/index.dart';

@lazySingleton
class SupabaseService {
  final LogUtils _log;
  SupabaseService(this._log);

  static const String _tableName = 'locations';

  /// Get all saved locations from Supabase
  Future<List<Map<String, dynamic>>> getAllLocations() async {
    try {
      _log.logI('Supabase: Fetching locations...');
      final response = await Supabase.instance.client
          .from(_tableName)
          .select()
          .order('created_at', ascending: true);
      _log.logI('Supabase: Fetched ${(response as List).length} locations');
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      _log.logE('Error fetching locations from Supabase: $e');
      rethrow;
    }
  }

  /// Save a new location to Supabase
  Future<Map<String, dynamic>?> saveLocation({
    required String id,
    required String title,
    required double lat,
    required double lng,
    required double radius,
    required bool notificationEnabled,
    DateTime? createdAt,
  }) async {
    try {
      _log.logI('Supabase: Saving location - id: $id, title: $title, lat: $lat, lng: $lng');
      final data = {
        'id': id,
        'title': title,
        'lat': lat,
        'lng': lng,
        'radius': radius,
        'notification_enabled': notificationEnabled,
        'created_at': (createdAt ?? DateTime.now()).toIso8601String(),
      };

      _log.logI('Supabase: Insert data: $data');

      final response = await Supabase.instance.client
          .from(_tableName)
          .insert(data)
          .select()
          .single();
      _log.logI('Supabase: Save successful - $response');
      return Map<String, dynamic>.from(response);
    } catch (e) {
      _log.logE('Error saving location to Supabase: $e');
      rethrow;
    }
  }

  /// Update a location in Supabase
  Future<bool> updateLocation({
    required String id,
    String? title,
    double? lat,
    double? lng,
    double? radius,
    bool? notificationEnabled,
  }) async {
    try {
      final Map<String, dynamic> data = {};
      if (title != null) data['title'] = title;
      if (lat != null) data['lat'] = lat;
      if (lng != null) data['lng'] = lng;
      if (radius != null) data['radius'] = radius;
      if (notificationEnabled != null) {
        data['notification_enabled'] = notificationEnabled;
      }

      if (data.isEmpty) return true;

      final response = await Supabase.instance.client
          .from(_tableName)
          .update(data)
          .eq('id', id)
          .select()
          .single();
      return response != null;
    } catch (e) {
      _log.logE('Error updating location in Supabase: $e');
      rethrow;
    }
  }

  /// Delete a location from Supabase
  Future<bool> deleteLocation(String id) async {
    try {
      await Supabase.instance.client
          .from(_tableName)
          .delete()
          .eq('id', id);
      return true;
    } catch (e) {
      _log.logE('Error deleting location from Supabase: $e');
      rethrow;
    }
  }

  /// Toggle notification status for a location
  Future<bool> toggleNotification(String id, bool enabled) async {
    return updateLocation(
      id: id,
      notificationEnabled: enabled,
    );
  }
}
