enum VehicleType { bike, motorcycle }

class DriverModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final VehicleType vehicleType;
  final bool isOnline;
  final double earnings;
  final int totalDeliveries;
  final double? lat;
  final double? lng;

  const DriverModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.vehicleType,
    required this.isOnline,
    this.earnings = 0,
    this.totalDeliveries = 0,
    this.lat,
    this.lng,
  });

  DriverModel copyWith({bool? isOnline, double? lat, double? lng}) => DriverModel(
        id: id,
        name: name,
        email: email,
        phone: phone,
        vehicleType: vehicleType,
        isOnline: isOnline ?? this.isOnline,
        earnings: earnings,
        totalDeliveries: totalDeliveries,
        lat: lat ?? this.lat,
        lng: lng ?? this.lng,
      );
}
