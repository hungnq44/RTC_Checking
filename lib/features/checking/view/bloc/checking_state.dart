part of 'checking_bloc.dart';

@CopyWith()
class CheckingState extends BaseBlocState {
  const CheckingState({
    required super.status,
    super.message,
    this.title,
    this.lat,
    this.lng,
    this.radius = 15.0,
    this.isInZone = false,
    this.savedLocations = const [],
    this.selectedLocationId,
    this.distanceToZone = 0.0,
    this.isAlarmPlaying = false,
    this.alarmDismissed = false,
  });

  final String? title;
  final double? lat;
  final double? lng;
  final double radius;
  final bool isInZone;
  final List<SavedLocation> savedLocations;
  final String? selectedLocationId;
  final double distanceToZone;
  final bool isAlarmPlaying;
  final bool alarmDismissed;

  factory CheckingState.init() => const CheckingState(
        status: BaseStateStatus.init,
      );

  @override
  List get props => [
        status,
        message,
        title,
        lat,
        lng,
        radius,
        isInZone,
        savedLocations,
        selectedLocationId,
        distanceToZone,
        isAlarmPlaying,
        alarmDismissed,
      ];
}