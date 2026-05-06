import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

final locationServiceProvider = Provider<LocationService>((ref) => LocationService());

class LocationService {
  Future<Position> getCurrentPosition() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions permanently denied');
    }
    return Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  // Emits on real movement (≥5 m) AND every 5 s regardless of movement.
  // The 5-second tick is what drives GPS upload to the backend.
  Stream<Position> watchPosition() {
    Position? last;
    late StreamController<Position> ctrl;
    StreamSubscription<Position>? geoSub;
    Timer? uploadTimer;

    ctrl = StreamController<Position>(
      onListen: () {
        // Movement-based updates
        geoSub = Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 5,
          ),
        ).listen((pos) {
          last = pos;
          ctrl.add(pos);
        }, onError: (e) => ctrl.addError(e));

        // Time-based updates every 5 s (drives GPS upload)
        uploadTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
          if (ctrl.isClosed) return;
          if (last != null) {
            ctrl.add(last!);
          } else {
            try {
              final pos = await getCurrentPosition();
              last = pos;
              ctrl.add(pos);
            } catch (_) {}
          }
        });
      },
      onCancel: () {
        geoSub?.cancel();
        uploadTimer?.cancel();
      },
    );

    return ctrl.stream;
  }
}
