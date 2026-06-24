import 'package:geolocator/geolocator.dart';
import 'package:injectable/injectable.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

import '../../../../../base/network/dio/index.dart';

@lazySingleton
class CheckingService extends DioBaseApiService {
  CheckingService(super.dio);

  Future<Position> getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception(
        'Location services are disabled. Vui lòng bật định vị (GPS) trên thiết bị.',
      );
    }

    final geolocatorPermission = await Geolocator.checkPermission();

    if (geolocatorPermission == LocationPermission.denied ||
        geolocatorPermission == LocationPermission.deniedForever) {
      final phStatus = await ph.Permission.locationWhenInUse.request();

      if (phStatus.isPermanentlyDenied) {
        throw Exception(
          'Location permissions are permanently denied. '
          'Vui lòng vào Settings → Apps → RTC Checking → Permissions → Location → Allow.',
        );
      }
      if (!phStatus.isGranted && !phStatus.isLimited) {
        throw Exception(
          'Location permissions are denied. Vui lòng cấp quyền vị trí cho ứng dụng.',
        );
      }
    }

    if (geolocatorPermission == LocationPermission.unableToDetermine) {
      final phStatus = await ph.Permission.locationWhenInUse.request();
      if (!phStatus.isGranted && !phStatus.isLimited) {
        throw Exception(
          'Location permissions are denied (unableToDetermine).',
        );
      }
    }

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }
}
