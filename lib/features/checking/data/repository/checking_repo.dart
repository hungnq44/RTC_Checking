import 'package:geolocator/geolocator.dart';
import '../datasource/model/saved_location.dart';

abstract class CheckingRepo {
  Future<Position> getCurrentLocation();

  Future<List<SavedLocation>> getSavedLocations();

  Future<SavedLocation?> saveLocationToSupabase({
    required String id,
    required String title,
    required double lat,
    required double lng,
    required double radius,
    required bool notificationEnabled,
    DateTime? createdAt,
  });

  Future<bool> updateNotificationStatus(String id, bool enabled);

  Future<bool> updateLocationInSupabase({
    required String id,
    String? title,
    double? lat,
    double? lng,
    double? radius,
  });

  Future<bool> deleteLocationFromSupabase(String id);
}