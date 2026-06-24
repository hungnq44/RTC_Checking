import 'package:shared_preferences/shared_preferences.dart';

class LocationPreferenceService {
  static const String _selectedLocationKey = 'selected_location_id';

  final SharedPreferences _prefs;

  LocationPreferenceService(this._prefs);

  String? get selectedLocationId => _prefs.getString(_selectedLocationKey);

  Future<void> setSelectedLocationId(String? id) async {
    if (id == null) {
      await _prefs.remove(_selectedLocationKey);
    } else {
      await _prefs.setString(_selectedLocationKey, id);
    }
  }

  Future<void> clear() async {
    await _prefs.remove(_selectedLocationKey);
  }
}
