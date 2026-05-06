// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'D-helper Rider';

  @override
  String get login => 'Login';

  @override
  String get register => 'Register';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get name => 'Full Name';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get vehicleType => 'Vehicle Type';

  @override
  String get bike => 'Bike';

  @override
  String get motorcycle => 'Motorcycle';

  @override
  String get car => 'Car';

  @override
  String get logout => 'Logout';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get profile => 'Profile';

  @override
  String get online => 'Online';

  @override
  String get offline => 'Offline';

  @override
  String get searchingForOrders => 'Searching for Orders';

  @override
  String get goOffline => 'Go Offline';

  @override
  String get earnings => 'Earnings';

  @override
  String get todayEarnings => 'Today\'s Earnings';

  @override
  String get totalDeliveries => 'Total Deliveries';

  @override
  String get orderHistory => 'Order History';

  @override
  String get newOrderAvailable => 'New Order Available!';

  @override
  String get restaurantLocation => 'Restaurant';

  @override
  String get customerName => 'Customer';

  @override
  String get distance => 'Distance';

  @override
  String get acceptOrder => 'Accept Order';

  @override
  String get declineOrder => 'Decline';

  @override
  String get navigateToRestaurant => 'Navigate to Restaurant';

  @override
  String get pickedUpOrder => 'Picked Up Order';

  @override
  String get navigateToCustomer => 'Navigate to Customer';

  @override
  String get orderDelivered => 'Order Delivered';

  @override
  String get support => 'Support';

  @override
  String get callSupport => 'Call Support';

  @override
  String get deliveryAddress => 'Delivery Address';

  @override
  String get loading => 'Loading...';

  @override
  String get error => 'An error occurred';

  @override
  String get required => 'Required';

  @override
  String get noActiveOrder => 'No active order';

  @override
  String get welcome => 'Welcome Back';

  @override
  String get fillAllFields => 'Fill in all fields';

  @override
  String get wrongCredentials => 'Incorrect email or password';

  @override
  String get demoAccount => 'Demo account';

  @override
  String get minPassword => 'Min. 6 characters';

  @override
  String get emailAlreadyExists => 'Email already registered';

  @override
  String km(String distance) {
    return '$distance km';
  }
}
