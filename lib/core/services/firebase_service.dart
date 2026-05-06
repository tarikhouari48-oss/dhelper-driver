import 'dart:async';
import 'dart:convert';
import 'dart:math' show sqrt;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../models/order_model.dart';
import '../models/driver_model.dart';

const _dbUrl = 'https://d-helper-f1331-default-rtdb.firebaseio.com';

final firebaseServiceProvider =
    Provider<DriverFirebaseService>((ref) => DriverFirebaseService());

final dailyStatsProvider = StreamProvider<DailyStats>((ref) {
  return ref.watch(firebaseServiceProvider).watchDailyStats();
});

class DailyStats {
  final int pedidos;
  final double earnings;
  const DailyStats({this.pedidos = 0, this.earnings = 0});
}

// Restaurant location — Carrer de Provença 78, Barcelona
const _restLat = 41.3917;
const _restLng = 2.1649;

double _distFromRestaurant(OrderModel o) {
  if (o.deliveryLat == null || o.deliveryLng == null) return 99999;
  final dlat = o.deliveryLat! - _restLat;
  final dlng = o.deliveryLng! - _restLng;
  return sqrt(dlat * dlat + dlng * dlng) * 111000;
}

class DriverFirebaseService {
  // --- HTTP client ---
  final _client = http.Client();

  // --- Auth ---
  final _accounts = <String, Map<String, String>>{}; // email → {password, driverId}
  final _driverAccounts = <String, DriverModel>{}; // driverId → DriverModel

  DriverFirebaseService() {
    const demo = DriverModel(
      id: 'driver-demo',
      name: 'Demo Rider',
      email: 'demo@dhelper.com',
      phone: '+34 600 000 000',
      vehicleType: VehicleType.motorcycle,
      isOnline: false,
    );
    _accounts['demo@dhelper.com'] = {'password': '123456', 'driverId': 'driver-demo'};
    _driverAccounts['driver-demo'] = demo;
    _driver = demo;
  }

  DriverModel? login(String email, String password) {
    final acc = _accounts[email.toLowerCase()];
    if (acc == null || acc['password'] != password) return null;
    final driver = _driverAccounts[acc['driverId']!]!;
    _driver = driver;
    return driver;
  }

  DriverModel? registerDriver({
    required String name,
    required String email,
    required String password,
    required String phone,
    required VehicleType vehicleType,
  }) {
    final key = email.toLowerCase();
    if (_accounts.containsKey(key)) return null;
    final id = 'driver-${DateTime.now().millisecondsSinceEpoch}';
    final driver = DriverModel(
      id: id,
      name: name,
      email: key,
      phone: phone,
      vehicleType: vehicleType,
      isOnline: false,
    );
    _accounts[key] = {'password': password, 'driverId': id};
    _driverAccounts[id] = driver;
    _driver = driver;
    return driver;
  }

  // --- Stats ---
  final _statsCtrl = StreamController<DailyStats>.broadcast();
  DailyStats _dailyStats = const DailyStats();
  DateTime _statsDate = DateTime.now();

  // --- Driver ---
  late DriverModel _driver;

  DriverModel get currentDriver => _driver;
  static const double restaurantLat = _restLat;
  static const double restaurantLng = _restLng;

  // --- Cached active orders for sync accessors ---
  List<OrderModel> _cachedActive = [];

  List<OrderModel> get sortedActiveOrders => List.from(_cachedActive)
    ..sort((a, b) => _distFromRestaurant(a).compareTo(_distFromRestaurant(b)));

  bool allPickedUp() =>
      _cachedActive.isNotEmpty &&
      _cachedActive.every((o) => o.status == OrderStatus.pickedUp);

  bool canDeliver(String orderId) {
    if (!allPickedUp()) return false;
    final sorted = sortedActiveOrders;
    return sorted.isNotEmpty && sorted.first.id == orderId;
  }

  bool get hasPendingRecogida => _cachedActive.any(
      (o) => o.status == OrderStatus.accepted || o.status == OrderStatus.ready);

  // --- Helpers ---
  void _checkResetDay() {
    final now = DateTime.now();
    if (now.day != _statsDate.day || now.month != _statsDate.month) {
      _dailyStats = const DailyStats();
      _statsDate = now;
    }
  }

  // --- Streams ---

  Future<List<OrderModel>> _fetchOrders() async {
    try {
      final res = await _client
          .get(Uri.parse('$_dbUrl/orders.json'))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200 && res.body != 'null') {
        final map = Map<String, dynamic>.from(jsonDecode(res.body) as Map);
        return map.entries.map((e) {
          final m = Map<String, dynamic>.from(e.value as Map);
          if (m['id'] == null || (m['id'] as String).isEmpty) m['id'] = e.key;
          return OrderModel.fromMap(m);
        }).toList();
      }
    } catch (_) {}
    return [];
  }

  Stream<List<OrderModel>> watchAvailableOrders() async* {
    while (true) {
      final all = await _fetchOrders();
      yield all.where((o) =>
          (o.status == OrderStatus.ready || o.status == OrderStatus.accepted) &&
          o.driverId == null).toList();
      await Future.delayed(const Duration(seconds: 3));
    }
  }

  Stream<List<OrderModel>> watchActiveOrdersList() async* {
    while (true) {
      final all = await _fetchOrders();
      final active = all.where((o) =>
          o.driverId == _driver.id &&
          o.status != OrderStatus.delivered &&
          o.status != OrderStatus.rejected).toList();
      active.sort((a, b) => _distFromRestaurant(a).compareTo(_distFromRestaurant(b)));
      _cachedActive = active;
      yield active;
      await Future.delayed(const Duration(seconds: 3));
    }
  }

  Stream<OrderModel?> watchActiveOrder() {
    return watchActiveOrdersList()
        .map((list) => list.isEmpty ? null : list.first);
  }

  Stream<DailyStats> watchDailyStats() {
    Future.microtask(() => _statsCtrl.add(_dailyStats));
    return _statsCtrl.stream;
  }

  // --- Order actions ---

  Future<void> _patch(String path, Map<String, dynamic> body) async {
    await _client.patch(
      Uri.parse('$_dbUrl/$path.json'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
  }

  Future<void> acceptOrder(String orderId) async {
    await _patch('orders/$orderId', {
      'driverId': _driver.id,
      'status': OrderStatus.accepted.name,
    });
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    final body = <String, dynamic>{'status': status.name};
    if (status == OrderStatus.pickedUp) {
      body['pickedUpAt'] = DateTime.now().millisecondsSinceEpoch;
    }
    await _patch('orders/$orderId', body);

    if (status == OrderStatus.delivered) {
      _checkResetDay();
      final res = await _client.get(Uri.parse('$_dbUrl/orders/$orderId.json'));
      if (res.statusCode == 200 && res.body != 'null') {
        final order = OrderModel.fromMap(
            Map<String, dynamic>.from(jsonDecode(res.body) as Map));
        _dailyStats = DailyStats(
          pedidos: _dailyStats.pedidos + 1,
          earnings: _dailyStats.earnings + order.grandTotal,
        );
        _statsCtrl.add(_dailyStats);
      }
    }
  }

  Future<void> cancelOrder(String orderId) async {
    await _patch('orders/$orderId', {
      'driverId': null,
      'status': OrderStatus.ready.name,
    });
  }

  Future<void> confirmAllRecogida() async {
    final orders = await _fetchOrders();
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final order in orders) {
      if (order.driverId == _driver.id &&
          (order.status == OrderStatus.accepted ||
              order.status == OrderStatus.ready ||
              order.status == OrderStatus.preparing)) {
        await _patch('orders/${order.id}', {
          'status': OrderStatus.pickedUp.name,
          'pickedUpAt': now,
        });
      }
    }
  }

  Future<void> startDelivery(String orderId) async {
    await _patch('orders/$orderId', {
      'deliveryStartedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  // --- Driver presence ---

  void updateDriverLocation(double lat, double lng) {
    _driver = _driver.copyWith(lat: lat, lng: lng);
    _patch('drivers/${_driver.id}', {
      'id': _driver.id,
      'name': _driver.name,
      'isOnline': _driver.isOnline,
      'lat': lat,
      'lng': lng,
      'vehicleType': _driver.vehicleType.name,
    });
  }

  Future<void> updateDriverOnlineStatus(bool isOnline) async {
    _driver = _driver.copyWith(isOnline: isOnline);
    await _patch('drivers/${_driver.id}', {
      'id': _driver.id,
      'name': _driver.name,
      'isOnline': isOnline,
      'vehicleType': _driver.vehicleType.name,
    });
  }

  Future<void> initNotifications() async {}
}
