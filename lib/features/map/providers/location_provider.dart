import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/gps_upload_service.dart';

final positionStreamProvider = StreamProvider<Position>((ref) {
  return ref.watch(locationServiceProvider).watchPosition();
});

final isOnlineProvider = StateNotifierProvider<OnlineNotifier, bool>((ref) {
  final upload = ref.watch(gpsUploadServiceProvider);
  return OnlineNotifier(upload);
});

class OnlineNotifier extends StateNotifier<bool> {
  final GpsUploadService _upload;

  OnlineNotifier(this._upload) : super(false);

  void toggle() {
    state = !state;
    state ? _upload.start() : _upload.stop();
  }

  void setOnline()  { state = true;  _upload.start(); }
  void setOffline() { state = false; _upload.stop();  }
}
