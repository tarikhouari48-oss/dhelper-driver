import 'dart:async';
import 'dart:math' show sqrt;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order_model.dart';
import '../models/driver_model.dart';

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

const _restLat = 41.3917;
const _restLng = 2.1649;

SupabaseClient get _db => Supabase.instance.client;

double _distFromRestaurant(OrderModel o) {
  if (o.deliveryLat == null || o.deliveryLng == null) return 99999;
  final dlat = o.deliveryLat! - _restLat;
  final dlng = o.deliveryLng! - _restLng;
  return sqrt(dlat * dlat + dlng * dlng) * 111000;
}

class DriverFirebaseService {
  // --- Auth (mock passwords, Supabase profiles) ---
  final _accounts = <String, Map<String, String>>{};

  DriverFirebaseService() {
    _accounts['demo@dhelper.com'] = {'password': '123456', 'driverId': 'driver-demo'};
    _accounts['ahmed@dhelper.com'] = {'password': 'ahmed123', 'driverId': 'drv-seed-1'};
    _accounts['juan@dhelper.com'] = {'password': 'juan123', 'driverId': 'drv-seed-2'};
    _accounts['maria@dhelper.com'] = {'password': 'maria123', 'driverId': 'drv-seed-3'};
    _driver = const DriverModel(
      id: 'driver-demo',
      name: 'Demo Rider',
      email: 'demo@dhelper.com',
      phone: '+34 600 000 000',
      vehicleType: VehicleType.motorcycle,
      isOnline: false,
    );
    _ensureDemoDriverInSupabase();
  }

  Future<void> _ensureDemoDriverInSupabase() async {
    try {
      await _db.from('drivers').upsert({
        'id':               'driver-demo',
        'name':             'Demo Rider',
        'email':            'demo@dhelper.com',
        'phone':            '+34 600 000 000',
        'vehicle_type':     'motorcycle',
        'is_online':        false,
        'today_deliveries': 0,
        'today_earnings':   0.0,
      });
    } catch (_) {}
  }

  DriverModel? login(String email, String password) {
    final acc = _accounts[email.toLowerCase()];
    if (acc == null || acc['password'] != password) return null;
    final driverId = acc['driverId']!;
    _driver = _driver.copyWith(isOnline: _driver.isOnline);
    _loadDriverFromSupabase(driverId);
    return _driver;
  }

  Future<void> _loadDriverFromSupabase(String driverId) async {
    try {
      final rows = await _db.from('drivers').select().eq('id', driverId);
      if ((rows as List).isNotEmpty) {
        final r = rows.first as Map<String, dynamic>;
        _driver = DriverModel(
          id: r['id']?.toString() ?? driverId,
          name: r['name']?.toString() ?? _driver.name,
          email: r['email']?.toString() ?? _driver.email,
          phone: r['phone']?.toString() ?? _driver.phone,
          vehicleType: r['vehicle_type'] == 'motorcycle'
              ? VehicleType.motorcycle
              : VehicleType.bike,
          isOnline: r['is_online'] as bool? ?? false,
          lat: (r['lat'] as num?)?.toDouble(),
          lng: (r['lng'] as num?)?.toDouble(),
        );
      }
    } catch (_) {}
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
    _driver = driver;
    _db.from('drivers').upsert({
      'id':               id,
      'name':             name,
      'email':            key,
      'phone':            phone,
      'vehicle_type':     vehicleType.name,
      'is_online':        false,
      'today_deliveries': 0,
      'today_earnings':   0.0,
    });
    return driver;
  }

  // --- Stats ---
  final _statsCtrl = StreamController<DailyStats>.broadcast();
  DailyStats _dailyStats = const DailyStats();
  DateTime _statsDate = DateTime.now();

  void _checkResetDay() {
    final now = DateTime.now();
    if (now.day != _statsDate.day || now.month != _statsDate.month) {
      _dailyStats = const DailyStats();
      _statsDate = now;
    }
  }

  // --- Driver ---
  late DriverModel _driver;

  DriverModel get currentDriver => _driver;
  static const double restaurantLat = _restLat;
  static const double restaurantLng = _restLng;

  // --- Cached active orders ---
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

  // --- Streams ---

  Stream<List<OrderModel>> watchAvailableOrders() {
    return _db
        .from('orders')
        .stream(primaryKey: ['id'])
        .map((rows) => rows
            .map((r) => OrderModel.fromSupabase(r))
            .where((o) =>
                (o.status == OrderStatus.ready ||
                    o.status == OrderStatus.accepted) &&
                o.driverId == null)
            .toList());
  }

  Stream<List<OrderModel>> watchActiveOrdersList() {
    return _db
        .from('orders')
        .stream(primaryKey: ['id'])
        .map((rows) {
          final active = rows
              .map((r) => OrderModel.fromSupabase(r))
              .where((o) =>
                  o.driverId == _driver.id &&
                  o.status != OrderStatus.delivered &&
                  o.status != OrderStatus.rejected)
              .toList();
          active.sort(
              (a, b) => _distFromRestaurant(a).compareTo(_distFromRestaurant(b)));
          _cachedActive = active;
          return active;
        });
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

  Future<void> acceptOrder(String orderId) async {
    await _db.from('orders').update({
      'driver_id': _driver.id,
      'status':    OrderStatus.accepted.name,
    }).eq('id', orderId);
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    final body = <String, dynamic>{'status': status.name};
    if (status == OrderStatus.pickedUp) {
      body['picked_up_at'] = DateTime.now().millisecondsSinceEpoch;
    }
    if (status == OrderStatus.delivered) {
      body['delivered_at'] = DateTime.now().millisecondsSinceEpoch;
      _checkResetDay();
      final matching = _cachedActive.where((o) => o.id == orderId);
      if (matching.isNotEmpty) {
        final order = matching.first;
        _dailyStats = DailyStats(
          pedidos:  _dailyStats.pedidos + 1,
          earnings: _dailyStats.earnings + order.grandTotal,
        );
        _statsCtrl.add(_dailyStats);
      }
    }
    await _db.from('orders').update(body).eq('id', orderId);
  }

  Future<void> cancelOrder(String orderId) async {
    await _db.from('orders').update({
      'status': OrderStatus.rejected.name,
    }).eq('id', orderId);
  }

  Future<void> confirmAllRecogida() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final order in List<OrderModel>.from(_cachedActive)) {
      if (order.status == OrderStatus.accepted ||
          order.status == OrderStatus.ready ||
          order.status == OrderStatus.preparing) {
        await _db.from('orders').update({
          'status':     OrderStatus.pickedUp.name,
          'picked_up_at': now,
        }).eq('id', order.id);
      }
    }
  }

  Future<void> startDelivery(String orderId) async {}

  // --- Driver presence ---

  void updateDriverLocation(double lat, double lng) {
    _driver = _driver.copyWith(lat: lat, lng: lng);
    _db.from('drivers').update({
      'lat':       lat,
      'lng':       lng,
      'is_online': _driver.isOnline,
    }).eq('id', _driver.id);
  }

  Future<void> updateDriverOnlineStatus(bool isOnline) async {
    _driver = _driver.copyWith(isOnline: isOnline);
    await _db.from('drivers').update({
      'is_online': isOnline,
    }).eq('id', _driver.id);
  }

  Future<({double? lat, double? lng, String address})> getRestaurantCoords() async {
    try {
      final rows = await _db
          .from('restaurant_settings')
          .select()
          .eq('id', 'restaurant');
      if ((rows as List).isEmpty) return (lat: null, lng: null, address: '');
      final r = rows.first as Map<String, dynamic>;
      return (
        lat:     (r['lat'] as num?)?.toDouble(),
        lng:     (r['lng'] as num?)?.toDouble(),
        address: r['address']?.toString() ?? '',
      );
    } catch (_) {
      return (lat: null, lng: null, address: '');
    }
  }

  Future<void> initNotifications() async {}
}
