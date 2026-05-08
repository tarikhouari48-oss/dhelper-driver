enum OrderStatus { pending, accepted, preparing, ready, pickedUp, delivered, rejected }

enum PaymentType { cash, card, bizum }

class FoodItem {
  final String name;
  final int quantity;
  final double price;

  const FoodItem({required this.name, required this.quantity, required this.price});

  factory FoodItem.fromJson(Map<String, dynamic> json) => FoodItem(
        name: json['name']?.toString() ?? '',
        quantity: (json['quantity'] as num?)?.toInt() ?? 1,
        price: (json['price'] as num?)?.toDouble() ?? 0.0,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'quantity': quantity,
        'price': price,
      };
}

class OrderModel {
  final String id;
  final String customerName;
  final String phoneNumber;
  final String deliveryAddress;
  final List<FoodItem> items;
  final PaymentType paymentType;
  final OrderStatus status;
  final DateTime createdAt;
  final String operatorId;
  final String? driverId;
  final double tip;
  final double? deliveryLat;
  final double? deliveryLng;

  final DateTime? pickedUpAt;
  final DateTime? deliveryStartedAt;

  const OrderModel({
    required this.id,
    required this.customerName,
    required this.phoneNumber,
    required this.deliveryAddress,
    required this.items,
    required this.paymentType,
    required this.status,
    required this.createdAt,
    required this.operatorId,
    this.driverId,
    this.tip = 0,
    this.deliveryLat,
    this.deliveryLng,
    this.pickedUpAt,
    this.deliveryStartedAt,
  });

  double get itemsTotal => items.fold(0, (s, i) => s + i.price * i.quantity);
  double get grandTotal => itemsTotal + tip;

  OrderModel copyWith({
    OrderStatus? status,
    String? driverId,
    DateTime? pickedUpAt,
    DateTime? deliveryStartedAt,
  }) => OrderModel(
        id: id,
        customerName: customerName,
        phoneNumber: phoneNumber,
        deliveryAddress: deliveryAddress,
        items: items,
        paymentType: paymentType,
        status: status ?? this.status,
        createdAt: createdAt,
        operatorId: operatorId,
        driverId: driverId ?? this.driverId,
        tip: tip,
        deliveryLat: deliveryLat,
        deliveryLng: deliveryLng,
        pickedUpAt: pickedUpAt ?? this.pickedUpAt,
        deliveryStartedAt: deliveryStartedAt ?? this.deliveryStartedAt,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'customerName': customerName,
        'phoneNumber': phoneNumber,
        'deliveryAddress': deliveryAddress,
        'items': items.map((i) => i.toJson()).toList(),
        'status': status.name,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'paymentType': paymentType.name,
        'operatorId': operatorId,
        'driverId': driverId,
        'tip': tip,
        'deliveryLat': deliveryLat,
        'deliveryLng': deliveryLng,
        'pickedUpAt': pickedUpAt?.millisecondsSinceEpoch,
        'deliveryStartedAt': deliveryStartedAt?.millisecondsSinceEpoch,
      };

  factory OrderModel.fromSupabase(Map<String, dynamic> r) => OrderModel(
        id:              r['id']?.toString() ?? '',
        customerName:    r['customer_name']?.toString() ?? '',
        phoneNumber:     r['phone_number']?.toString() ?? '',
        deliveryAddress: r['delivery_address']?.toString() ?? '',
        items: (r['items'] as List<dynamic>? ?? [])
            .map((i) => FoodItem.fromJson(Map<String, dynamic>.from(i as Map)))
            .toList(),
        status: OrderStatus.values.firstWhere(
          (s) => s.name == r['status'],
          orElse: () => OrderStatus.pending,
        ),
        paymentType: PaymentType.values.firstWhere(
          (p) => p.name == r['payment_type'],
          orElse: () => PaymentType.cash,
        ),
        createdAt: DateTime.fromMillisecondsSinceEpoch(
            (r['created_at'] as num?)?.toInt() ?? 0),
        operatorId:  r['operator_id']?.toString() ?? 'local',
        driverId:    r['driver_id']?.toString(),
        deliveryLat: (r['delivery_lat'] as num?)?.toDouble(),
        deliveryLng: (r['delivery_lng'] as num?)?.toDouble(),
        pickedUpAt: r['picked_up_at'] != null
            ? DateTime.fromMillisecondsSinceEpoch((r['picked_up_at'] as num).toInt())
            : null,
      );

  factory OrderModel.fromMap(Map<String, dynamic> m) => OrderModel(
        id: m['id']?.toString() ?? '',
        customerName: m['customerName']?.toString() ?? '',
        phoneNumber: m['phoneNumber']?.toString() ?? '',
        deliveryAddress: m['deliveryAddress']?.toString() ?? '',
        items: (m['items'] as List<dynamic>?)
                ?.map((i) => FoodItem.fromJson(Map<String, dynamic>.from(i as Map)))
                .toList() ??
            [],
        status: OrderStatus.values.firstWhere(
          (s) => s.name == m['status'],
          orElse: () => OrderStatus.pending,
        ),
        paymentType: PaymentType.values.firstWhere(
          (p) => p.name == m['paymentType'],
          orElse: () => PaymentType.cash,
        ),
        createdAt: DateTime.fromMillisecondsSinceEpoch(
            (m['createdAt'] as num?)?.toInt() ?? 0),
        operatorId: m['operatorId']?.toString() ?? 'local',
        driverId: m['driverId']?.toString(),
        tip: (m['tip'] as num?)?.toDouble() ?? 0.0,
        deliveryLat: (m['deliveryLat'] as num?)?.toDouble(),
        deliveryLng: (m['deliveryLng'] as num?)?.toDouble(),
        pickedUpAt: m['pickedUpAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(
                (m['pickedUpAt'] as num).toInt())
            : null,
        deliveryStartedAt: m['deliveryStartedAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(
                (m['deliveryStartedAt'] as num).toInt())
            : null,
      );
}
