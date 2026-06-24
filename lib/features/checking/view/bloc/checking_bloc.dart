import 'dart:async';
import 'dart:math' as math;

import 'package:bloc/bloc.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:flutter/widgets.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:injectable/injectable.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../../../base/bloc/index.dart';
import '../../../../common/logger/index.dart';
import '../../../../common/notification/index.dart';
import '../../data/datasource/model/saved_location.dart';
import '../../data/repository/checking_repo.dart';

part 'checking_event.dart';
part 'checking_state.dart';
part 'checking_bloc.freezed.dart';
part 'checking_bloc.g.dart';

@injectable
class CheckingBloc extends BaseBloc<CheckingEvent, CheckingState> with WidgetsBindingObserver {
  final LogUtils _log;
  final CheckingRepo _repo;
  final NotificationService _notificationService;

  MapboxMap? mapboxMap;
  CircleAnnotationManager? circleAnnotationManager;
  PolygonAnnotationManager? polygonAnnotationManager;
  String? savedLocationId;
  
  StreamSubscription<geo.Position>? _locationSubscription;
  final Set<String> _inZoneLocationIds = {};

  CheckingBloc(
    this._log,
    this._repo,
    this._notificationService,
  ) : super(CheckingState.init()) {
    WidgetsBinding.instance.addObserver(this);
    
    on<CheckingEvent>((event, emit) async {
      await event.when(
        init: (mapboxMap) => _onInit(mapboxMap, emit),
        getCurrentLocation: () => _getCurrentLocation(emit),
        updateRadius: (radius) {
          _updateRadius(radius, emit);
        },
        inputLocation: (title, lat, lng) => _inputLocation(title, lat, lng, emit),
        saveLocation: () => _saveLocation(emit),
        selectLocation: (id, lat, lng) => _selectLocation(id, lat, lng, emit),
        deleteLocation: (id) => _deleteLocation(id, emit),
        updateLocation: (id, title, lat, lng, radius) =>
            _updateLocation(id, title, lat, lng, radius, emit),
        toggleNotification: (id) => _toggleLocationNotification(id, emit),
        checkLocationOnResume: () => _checkLocationOnResume(emit),
        dismissAlarm: () => _dismissAlarm(emit),
        locationUpdated: (lat, lng) => _onLocationUpdated(lat, lng, emit),
      );
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    if (lifecycleState == AppLifecycleState.resumed) {
      _startLocationTracking();
    } else if (lifecycleState == AppLifecycleState.paused) {
      _stopLocationTracking();
    }
  }

  void _startLocationTracking() {
    _locationSubscription?.cancel();
    _locationSubscription = geo.Geolocator.getPositionStream(
      locationSettings: const geo.LocationSettings(
        accuracy: geo.LocationAccuracy.high,
        distanceFilter: 1,
      ),
    ).listen((position) {
      add(CheckingEvent.locationUpdated(position.latitude, position.longitude));
    });
  }

  void _stopLocationTracking() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
  }

  Future<void> _onLocationUpdated(double lat, double lng, Emitter<CheckingState> emit) async {
    // Update current position
    emit(state.copyWith(lat: lat, lng: lng));
    
    // Check all locations with notification enabled
    for (final location in state.savedLocations) {
      if (!location.notificationEnabled) continue;
      
      final distance = geo.Geolocator.distanceBetween(
        lat, lng, location.lat, location.lng,
      );
      
      final isInZone = distance <= location.radius;
      final wasInZone = _inZoneLocationIds.contains(location.id);
      
      if (isInZone && !wasInZone) {
        // Just entered zone - trigger alarm
        _log.logI('Entered zone: ${location.title}');
        _inZoneLocationIds.add(location.id);
        
        await _notificationService.startAlarm(
          locationId: location.id,
          locationTitle: location.title,
        );
        
        // Update state if this is the selected location
        if (location.id == state.selectedLocationId) {
          emit(state.copyWith(
            distanceToZone: distance,
            isInZone: true,
            isAlarmPlaying: true,
            alarmDismissed: false,
          ));
        }
      } else if (!isInZone && wasInZone) {
        // Just exited zone - reset alarm
        _log.logI('Exited zone: ${location.title}');
        _inZoneLocationIds.remove(location.id);
        
        if (location.id == state.selectedLocationId) {
          await _notificationService.cancelInZoneNotification();
          emit(state.copyWith(
            distanceToZone: distance,
            isInZone: false,
            isAlarmPlaying: false,
            alarmDismissed: false,
          ));
        }
      } else if (location.id == state.selectedLocationId) {
        // Update distance for selected location
        emit(state.copyWith(distanceToZone: distance, isInZone: isInZone));
      }
    }
  }

  @override
  Future<void> close() {
    WidgetsBinding.instance.removeObserver(this);
    _locationSubscription?.cancel();
    return super.close();
  }

  Future<void> _checkLocationOnResume(Emitter<CheckingState> emit) async {
    // Restart location tracking on resume
    _startLocationTracking();
  }

  bool _isLocationDuplicate(double lat, double lng) {
    const tolerance = 0.000001;
    return state.savedLocations.any(
      (loc) =>
          (loc.lat - lat).abs() < tolerance &&
          (loc.lng - lng).abs() < tolerance,
    );
  }

  /// Simple distance calculation - trigger notification when entering zone
  Future<double> _calculateDistance(
    String? locationId,
    double targetLat,
    double targetLng,
    Emitter<CheckingState> emit,
  ) async {
    try {
      final currentPos = await geo.Geolocator.getCurrentPosition(
        locationSettings: const geo.LocationSettings(
          accuracy: geo.LocationAccuracy.high,
        ),
      );
      return await _checkZoneEntry(
        locationId,
        currentPos.latitude,
        currentPos.longitude,
        targetLat,
        targetLng,
        emit,
      );
    } catch (e) {
      _log.logE('Error calculating distance: $e');
      return 0.0;
    }
  }

  /// Check if user entered zone and trigger notification
  Future<double> _checkZoneEntry(
    String? locationId,
    double currentLat,
    double currentLng,
    double targetLat,
    double targetLng,
    Emitter<CheckingState> emit,
  ) async {
    final distanceInMeters = geo.Geolocator.distanceBetween(
      currentLat,
      currentLng,
      targetLat,
      targetLng,
    );

    final isInZone = distanceInMeters <= state.radius;

    emit(state.copyWith(
      distanceToZone: distanceInMeters,
      isInZone: isInZone,
    ));

    // Trigger notification if in zone AND alarm not playing AND notification enabled
    if (isInZone && !state.isAlarmPlaying && !state.alarmDismissed && locationId != null) {
      final location = state.savedLocations.where((loc) => loc.id == locationId).firstOrNull;
      if (location != null && location.notificationEnabled) {
        final locationTitle = _getLocationTitle(locationId);
        await _notificationService.startAlarm(
          locationId: locationId,
          locationTitle: locationTitle,
        );
        emit(state.copyWith(isAlarmPlaying: true));
      }
    }

    return distanceInMeters;
  }

  String _getLocationTitle(String locationId) {
    final location = state.savedLocations.where((loc) => loc.id == locationId).firstOrNull;
    return location?.title ?? state.title ?? 'Vị trí';
  }

  Future<void> _onInit(
    MapboxMap? incomingMap,
    Emitter<CheckingState> emit,
  ) async {
    mapboxMap = incomingMap;
    circleAnnotationManager = await incomingMap?.annotations
        .createCircleAnnotationManager();
    polygonAnnotationManager = await incomingMap?.annotations
        .createPolygonAnnotationManager();

    await incomingMap?.location.updateSettings(
      LocationComponentSettings(
        enabled: true,
        showAccuracyRing: true,
        pulsingEnabled: true,
      ),
    );

    try {
      final geo.Position position = await _repo.getCurrentLocation();
      final lng = position.longitude;
      final lat = position.latitude;

      await incomingMap?.setCamera(
        CameraOptions(center: Point(coordinates: Position(lng, lat)), zoom: 17),
      );

      emit(state.copyWith(
        status: BaseStateStatus.success,
        lat: lat,
        lng: lng,
        isInZone: false,
      ));

      // Load saved locations from Supabase
      await _loadSavedLocations(emit: emit, forceSelect: true);
      
      // Start continuous location tracking
      _startLocationTracking();
    } catch (e, st) {
      _log.logE('Location error, fallback to default: $e\n$st');
      emit(state.copyWith(
        status: BaseStateStatus.success,
        lat: 21.047450,
        lng: 105.735178,
        message: e.toString(),
      ));

      // Still try to load saved locations
      await _loadSavedLocations(emit: emit, forceSelect: true);
    }
  }

  void _updateRadius(double radius, Emitter<CheckingState> emit) =>
      emit(state.copyWith(radius: radius));

  Future<void> _inputLocation(
    String title,
    double lat,
    double lng,
    Emitter<CheckingState> emit,
  ) async {
    emit(state.copyWith(status: BaseStateStatus.loading));
    try {
      await mapboxMap?.setCamera(
        CameraOptions(center: Point(coordinates: Position(lng, lat)), zoom: 17),
      );

      await _calculateDistance(null, lat, lng, emit);
      emit(state.copyWith(
        status: BaseStateStatus.success,
        lat: lat,
        lng: lng,
        title: title.isEmpty ? null : title,
      ));
    } catch (e) {
      emit(state.copyWith(status: BaseStateStatus.failed, message: e.toString()));
    }
  }

  Future<void> _getCurrentLocation(Emitter<CheckingState> emit) async {
    emit(state.copyWith(status: BaseStateStatus.loading));
    try {
      final geo.Position position = await _repo.getCurrentLocation();
      await mapboxMap?.setCamera(
        CameraOptions(
          center: Point(
            coordinates: Position(position.longitude, position.latitude),
          ),
          zoom: 17,
        ),
      );

      await _calculateDistance(null, position.latitude, position.longitude, emit);
      emit(state.copyWith(
        status: BaseStateStatus.success,
        lat: position.latitude,
        lng: position.longitude,
      ));
    } catch (e) {
      emit(state.copyWith(status: BaseStateStatus.failed, message: e.toString()));
    }
  }

  Future<void> _saveLocation(Emitter<CheckingState> emit) async {
    if (state.lat == null || state.lng == null) {
      emit(state.copyWith(
        message: 'Vui lòng chọn vị trí trên bản đồ trước',
        status: BaseStateStatus.failed,
      ));
      return;
    }

    if (_isLocationDuplicate(state.lat!, state.lng!)) {
      emit(state.copyWith(
        message: 'Bạn đã lưu vị trí này rồi',
        status: BaseStateStatus.failed,
      ));
      return;
    }

    try {
      final title =
          (state.title == null || state.title!.isEmpty)
              ? 'Vị trí ${state.savedLocations.length + 1}'
              : state.title!;
      final newLocationId = DateTime.now().millisecondsSinceEpoch.toString();
      final createdAt = DateTime.now();
      final newLocation = SavedLocation(
        id: newLocationId,
        title: title,
        lat: state.lat!,
        lng: state.lng!,
        radius: state.radius,
        createdAt: createdAt,
        notificationEnabled: true,
      );

      await circleAnnotationManager?.deleteAll();
      savedLocationId = newLocationId;
      _notificationService.enableLocationNotification(newLocationId);

      // Calculate distance to update UI but DON'T trigger notification on save
      final distance = geo.Geolocator.distanceBetween(
        state.lat!,
        state.lng!,
        state.lat!,
        state.lng!,
      );
      final isInZone = distance <= state.radius;

      await _createCircle(state.lat!, state.lng!, state.radius);

      // Save to Supabase
      try {
        await _repo.saveLocationToSupabase(
          id: newLocationId,
          title: title,
          lat: state.lat!,
          lng: state.lng!,
          radius: state.radius,
          notificationEnabled: true,
          createdAt: createdAt,
        );
        _log.logI('Location saved to Supabase successfully');
      } catch (e) {
        _log.logE('Failed to save to Supabase: $e');
      }

      emit(state.copyWith(
        savedLocations: [...state.savedLocations, newLocation],
        selectedLocationId: newLocationId,
        isInZone: isInZone,
        status: BaseStateStatus.success,
        title: null,
        message: 'Đã lưu vị trí "$title"',
      ));
    } catch (e) {
      _log.logE('Error saving location: $e');
      emit(state.copyWith(status: BaseStateStatus.failed, message: e.toString()));
    }
  }

  Future<void> _loadSavedLocations({
    Emitter<CheckingState>? emit,
    bool forceSelect = false,
  }) async {
    if (emit == null) return;
    
    try {
      emit(state.copyWith(status: BaseStateStatus.loading));
      final locations = await _repo.getSavedLocations();

      // Enable notifications for loaded locations
      for (final location in locations) {
        if (location.notificationEnabled) {
          _notificationService.enableLocationNotification(location.id);
        }
      }

      emit(state.copyWith(
        savedLocations: locations,
        status: BaseStateStatus.success,
      ));

      // Auto-select first location only if forceSelect is true or no location selected
      if (forceSelect || state.selectedLocationId == null) {
        if (locations.isNotEmpty) {
          final enabledLocation = locations.firstWhere(
            (loc) => loc.notificationEnabled,
            orElse: () => locations.first,
          );

          await _selectLocation(
            enabledLocation.id,
            enabledLocation.lat,
            enabledLocation.lng,
            emit,
          );
        }
      }
    } catch (e) {
      _log.logE('Error loading saved locations: $e');
      emit(state.copyWith(
        status: BaseStateStatus.success,
        message: 'Không thể tải vị trí từ Supabase',
      ));
    }
  }

  Future<void> _selectLocation(
    String id,
    double lat,
    double lng,
    Emitter<CheckingState> emit,
  ) async {
    final location = state.savedLocations.firstWhere(
      (e) => e.id == id,
      orElse: () => SavedLocation(
        id: id,
        title: '',
        lat: lat,
        lng: lng,
        radius: state.radius,
        createdAt: DateTime.now(),
      ),
    );

    await circleAnnotationManager?.deleteAll();
    savedLocationId = id;

    // Reset alarm state when selecting new location
    emit(state.copyWith(
      isAlarmPlaying: false,
      alarmDismissed: false,
    ));

    await _createCircle(lat, lng, location.radius);
    await mapboxMap?.setCamera(
      CameraOptions(center: Point(coordinates: Position(lng, lat)), zoom: 17),
    );
    
    // Calculate distance and trigger notification if needed
    await _calculateDistance(id, lat, lng, emit);
    
    emit(state.copyWith(
      lat: lat,
      lng: lng,
      selectedLocationId: id,
      radius: location.radius,
    ));
  }

  Future<void> _createCircle(double lat, double lng, double radius) async {
    if (polygonAnnotationManager == null) return;

    await circleAnnotationManager?.deleteAll();
    await polygonAnnotationManager?.deleteAll();

    const int numPoints = 64;
    final List<Position> circlePoints = [];

    for (int i = 0; i < numPoints; i++) {
      final double angle = (2 * math.pi * i) / numPoints;
      final point = _offsetCoordinate(lat, lng, radius, angle);
      circlePoints.add(Position(point.longitude, point.latitude));
    }

    circlePoints.add(circlePoints.first);

    await polygonAnnotationManager!.create(
      PolygonAnnotationOptions(
        geometry: Polygon(coordinates: [circlePoints]),
        fillColor: 0x33E040FB,
        fillOutlineColor: 0xFFE040FB,
      ),
    );
  }

  GeoLatLng _offsetCoordinate(
    double lat,
    double lng,
    double radius,
    double bearing,
  ) {
    const double earthRadius = 6371000;
    final double latRad = lat * math.pi / 180;
    final double lngRad = lng * math.pi / 180;
    final double angularDistance = radius / earthRadius;

    final double newLatRad = math.asin(
      math.sin(latRad) * math.cos(angularDistance) +
          math.cos(latRad) * math.sin(angularDistance) * math.cos(bearing),
    );

    final double newLngRad = lngRad +
        math.atan2(
          math.sin(bearing) * math.sin(angularDistance) * math.cos(latRad),
          math.cos(angularDistance) - math.sin(latRad) * math.sin(newLatRad),
        );

    return GeoLatLng(
      latitude: newLatRad * 180 / math.pi,
      longitude: newLngRad * 180 / math.pi,
    );
  }

  Future<void> _deleteLocation(
      String id,
      Emitter<CheckingState> emit,
      ) async {
    final isSelected = state.selectedLocationId == id;

    await _repo.deleteLocationFromSupabase(id);
    _notificationService.disableLocationNotification(id);

    final updatedLocations = state.savedLocations
        .where((e) => e.id != id)
        .toList();

    await circleAnnotationManager?.deleteAll();
    await polygonAnnotationManager?.deleteAll();

    if (isSelected) {
      savedLocationId = null;
      await _notificationService.cancelInZoneNotification();
      // Reset alarm state
      emit(state.copyWith(
        isAlarmPlaying: false,
        alarmDismissed: false,
      ));
    }

    if (isSelected) {
      try {
        final position = await _repo.getCurrentLocation();
        await mapboxMap?.setCamera(
          CameraOptions(
            center: Point(
              coordinates: Position(position.longitude, position.latitude),
            ),
            zoom: 17,
          ),
        );
        emit(state.copyWith(
          savedLocations: updatedLocations,
          selectedLocationId: null,
          isInZone: false,
          distanceToZone: 0,
          lat: position.latitude,
          lng: position.longitude,
          title: null,
          status: BaseStateStatus.success,
          message: 'Đã xoá thành công',
        ));
      } catch (e) {
        emit(state.copyWith(
          savedLocations: updatedLocations,
          selectedLocationId: null,
          isInZone: false,
          distanceToZone: 0,
          lat: null,
          lng: null,
          title: null,
          status: BaseStateStatus.success,
          message: 'Đã xoá thành công',
        ));
      }
    } else {
      emit(state.copyWith(
        savedLocations: updatedLocations,
        selectedLocationId: state.selectedLocationId,
        isInZone: state.isInZone,
        distanceToZone: state.distanceToZone,
        lat: state.lat,
        lng: state.lng,
        title: state.title,
        status: BaseStateStatus.success,
        message: 'Đã xoá thành công',
      ));
    }
  }

  Future<void> _updateLocation(
    String id,
    String? title,
    double? lat,
    double? lng,
    double? radius,
    Emitter<CheckingState> emit,
  ) async {
    final locationIndex = state.savedLocations.indexWhere((loc) => loc.id == id);
    if (locationIndex == -1) return;

    final oldLocation = state.savedLocations[locationIndex];
    final updatedLocation = oldLocation.copyWith(
      title: title ?? oldLocation.title,
      lat: lat ?? oldLocation.lat,
      lng: lng ?? oldLocation.lng,
      radius: radius ?? oldLocation.radius,
    );

    try {
      await _repo.updateLocationInSupabase(
        id: id,
        title: title,
        lat: lat,
        lng: lng,
        radius: radius,
      );

      final updatedLocations = List<SavedLocation>.from(state.savedLocations);
      updatedLocations[locationIndex] = updatedLocation;

      emit(state.copyWith(
        savedLocations: updatedLocations,
        status: BaseStateStatus.success,
        message: 'Đã cập nhật vị trí "${updatedLocation.title}"',
      ));

      // Redraw circle and update map if this is the selected location
      final shouldRedraw = state.selectedLocationId == id;
      
      // Reload from Supabase to ensure data is synced
      await _loadSavedLocations(emit: emit, forceSelect: false);
      
      if (shouldRedraw) {
        await _createCircle(updatedLocation.lat, updatedLocation.lng, updatedLocation.radius);
        await mapboxMap?.setCamera(
          CameraOptions(
            center: Point(coordinates: Position(updatedLocation.lng, updatedLocation.lat)),
            zoom: 17,
          ),
        );
        await _calculateDistance(id, updatedLocation.lat, updatedLocation.lng, emit);
      }
    } catch (e) {
      _log.logE('Error updating location: $e');
      emit(state.copyWith(
        status: BaseStateStatus.failed,
        message: 'Không thể cập nhật vị trí',
      ));
    }
  }

  Future<void> _toggleLocationNotification(String id, Emitter<CheckingState> emit) async {
    final locationIndex = state.savedLocations.indexWhere((loc) => loc.id == id);
    if (locationIndex == -1) return;

    final location = state.savedLocations[locationIndex];
    final newEnabled = !location.notificationEnabled;
    final actionText = newEnabled ? 'bật' : 'tắt';

    // Update notification service
    if (newEnabled) {
      _notificationService.enableLocationNotification(id);
    } else {
      _notificationService.disableLocationNotification(id);
    }

    // Update local state
    final updatedLocations = List<SavedLocation>.from(state.savedLocations);
    updatedLocations[locationIndex] = location.copyWith(notificationEnabled: newEnabled);

    emit(state.copyWith(
      savedLocations: updatedLocations,
      status: BaseStateStatus.success,
      message: 'Đã $actionText thông báo cho "${location.title}"',
    ));

    // Update to Supabase
    try {
      await _repo.updateNotificationStatus(id, newEnabled);
    } catch (e) {
      _log.logE('Failed to update notification status to Supabase: $e');
    }
  }

  Future<void> _dismissAlarm(Emitter<CheckingState> emit) async {
    await _notificationService.stopAlarm();
    emit(state.copyWith(
      isAlarmPlaying: false,
      alarmDismissed: true,
    ));
    _log.logI('Alarm dismissed by user');
  }
}

class GeoLatLng {
  final double latitude;
  final double longitude;

  const GeoLatLng({
    required this.latitude,
    required this.longitude,
  });
}
