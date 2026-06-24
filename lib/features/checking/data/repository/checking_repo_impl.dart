import 'package:geolocator/geolocator.dart';
import 'package:injectable/injectable.dart';

import '../datasource/model/saved_location.dart';
import '../datasource/service/checking_service.dart';
import '../datasource/service/supabase_service.dart';
import 'checking_repo.dart';

@LazySingleton(as: CheckingRepo)
class CheckingRepoImpl implements CheckingRepo {
  final CheckingService _checkingService;
  final SupabaseService _supabaseService;

  CheckingRepoImpl(this._checkingService, this._supabaseService);

  @override
  Future<Position> getCurrentLocation() {
    return _checkingService.getCurrentLocation();
  }

  /// Get all saved locations from Supabase
  Future<List<SavedLocation>> getSavedLocations() async {
    final data = await _supabaseService.getAllLocations();
    return data.map((json) => SavedLocation.fromJson(json)).toList();
  }

  /// Save a new location to Supabase
  Future<SavedLocation?> saveLocationToSupabase({
    required String id,
    required String title,
    required double lat,
    required double lng,
    required double radius,
    required bool notificationEnabled,
    DateTime? createdAt,
  }) async {
    final result = await _supabaseService.saveLocation(
      id: id,
      title: title,
      lat: lat,
      lng: lng,
      radius: radius,
      notificationEnabled: notificationEnabled,
      createdAt: createdAt,
    );
    if (result != null) {
      return SavedLocation.fromJson(result);
    }
    return null;
  }

  /// Update notification status in Supabase
  Future<bool> updateNotificationStatus(String id, bool enabled) async {
    return _supabaseService.toggleNotification(id, enabled);
  }

  /// Update a location in Supabase
  Future<bool> updateLocationInSupabase({
    required String id,
    String? title,
    double? lat,
    double? lng,
    double? radius,
  }) async {
    return _supabaseService.updateLocation(
      id: id,
      title: title,
      lat: lat,
      lng: lng,
      radius: radius,
    );
  }

  /// Delete a location from Supabase
  Future<bool> deleteLocationFromSupabase(String id) async {
    return _supabaseService.deleteLocation(id);
  }
}