import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/order_model.dart';
import '../../../core/services/firebase_service.dart';

final availableOrdersProvider = StreamProvider<List<OrderModel>>((ref) {
  return ref.watch(firebaseServiceProvider).watchAvailableOrders();
});

final activeOrderProvider = StreamProvider<OrderModel?>((ref) {
  return ref.watch(firebaseServiceProvider).watchActiveOrder();
});

final activeOrdersListProvider = StreamProvider<List<OrderModel>>((ref) {
  return ref.watch(firebaseServiceProvider).watchActiveOrdersList();
});
