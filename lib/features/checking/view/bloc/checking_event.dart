part of 'checking_bloc.dart';

@freezed
class CheckingEvent with _$CheckingEvent {
  const factory CheckingEvent.init({MapboxMap? mapboxMap}) = _Init;
  const factory CheckingEvent.getCurrentLocation() = _GetCurrentLocation;
  const factory CheckingEvent.updateRadius(double radius) = _UpdateRadius;
  const factory CheckingEvent.inputLocation(String title, double lat, double lng) =
      _InputLocation;
  const factory CheckingEvent.saveLocation() = _SaveLocation;
  const factory CheckingEvent.selectLocation(String id, double lat, double lng) =
      _SelectLocation;
  const factory CheckingEvent.deleteLocation(String id) = _DeleteLocation;
  const factory CheckingEvent.updateLocation({
    required String id,
    String? title,
    double? lat,
    double? lng,
    double? radius,
  }) = _UpdateLocation;
  const factory CheckingEvent.toggleNotification(String id) = _ToggleNotification;
  const factory CheckingEvent.checkLocationOnResume() = _CheckLocationOnResume;
  const factory CheckingEvent.dismissAlarm() = _DismissAlarm;
  const factory CheckingEvent.locationUpdated(double lat, double lng) = _LocationUpdated;
}