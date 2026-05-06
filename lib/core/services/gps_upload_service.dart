import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'firebase_service.dart';
import 'location_service.dart';

final gpsUploadServiceProvider = Provider<GpsUploadService>((ref) {
  final firebase = ref.watch(firebaseServiceProvider);
  final location = ref.watch(locationServiceProvider);
  return GpsUploadService(firebase: firebase, locationService: location);
});

/// Listens to the 5-second position stream and pushes the driver's
/// GPS coordinates to the backend.
///
/// Mock mode: stores in DriverFirebaseService.
/// Firebase mode (future): write to Firestore drivers/{id} → {lat, lng, updatedAt}.
class GpsUploadService {
  final DriverFirebaseService firebase;
  final LocationService locationService;

  StreamSubscription<Position>? _sub;
  DateTime? _lastUpload;

  GpsUploadService({required this.firebase, required this.locationService});

  void start() {
    _sub = locationService.watchPosition().listen((pos) {
      final now = DateTime.now();
      // Throttle to max 1 upload per 5 s
      if (_lastUpload != null && now.difference(_lastUpload!).inSeconds < 5) return;
      _lastUpload = now;
      firebase.updateDriverLocation(pos.latitude, pos.longitude);
    });
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
    _lastUpload = null;
  }
}
