// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'D-helper Rider';

  @override
  String get login => 'Iniciar Sesión';

  @override
  String get register => 'Crear cuenta';

  @override
  String get email => 'Correo electrónico';

  @override
  String get password => 'Contraseña';

  @override
  String get name => 'Nombre completo';

  @override
  String get phoneNumber => 'Teléfono';

  @override
  String get vehicleType => 'Tipo de vehículo';

  @override
  String get bike => 'Bicicleta';

  @override
  String get motorcycle => 'Moto';

  @override
  String get car => 'Coche';

  @override
  String get logout => 'Cerrar Sesión';

  @override
  String get settings => 'Configuración';

  @override
  String get language => 'Idioma';

  @override
  String get profile => 'Perfil';

  @override
  String get online => 'En línea';

  @override
  String get offline => 'Fuera de línea';

  @override
  String get searchingForOrders => 'Buscando pedidos';

  @override
  String get goOffline => 'Desconectarse';

  @override
  String get earnings => 'Ganancias';

  @override
  String get todayEarnings => 'Ganancias de hoy';

  @override
  String get totalDeliveries => 'Entregas totales';

  @override
  String get orderHistory => 'Historial de pedidos';

  @override
  String get newOrderAvailable => '¡Nuevo pedido disponible!';

  @override
  String get restaurantLocation => 'Restaurante';

  @override
  String get customerName => 'Cliente';

  @override
  String get distance => 'Distancia';

  @override
  String get acceptOrder => 'Aceptar pedido';

  @override
  String get declineOrder => 'Rechazar';

  @override
  String get navigateToRestaurant => 'Navegar al restaurante';

  @override
  String get pickedUpOrder => 'Pedido recogido';

  @override
  String get navigateToCustomer => 'Navegar al cliente';

  @override
  String get orderDelivered => 'Pedido entregado';

  @override
  String get support => 'Soporte';

  @override
  String get callSupport => 'Llamar al soporte';

  @override
  String get deliveryAddress => 'Dirección de entrega';

  @override
  String get loading => 'Cargando...';

  @override
  String get error => 'Ocurrió un error';

  @override
  String get required => 'Requerido';

  @override
  String get noActiveOrder => 'Sin pedido activo';

  @override
  String get welcome => 'Bienvenido de nuevo';

  @override
  String get fillAllFields => 'Rellena todos los campos';

  @override
  String get wrongCredentials => 'Email o contraseña incorrectos';

  @override
  String get demoAccount => 'Cuenta demo';

  @override
  String get minPassword => 'Mínimo 6 caracteres';

  @override
  String get emailAlreadyExists => 'Este email ya está registrado';

  @override
  String km(String distance) {
    return '$distance km';
  }
}
