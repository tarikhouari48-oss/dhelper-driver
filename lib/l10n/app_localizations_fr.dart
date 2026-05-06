// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'D-helper Rider';

  @override
  String get login => 'Connexion';

  @override
  String get register => 'Créer un compte';

  @override
  String get email => 'E-mail';

  @override
  String get password => 'Mot de passe';

  @override
  String get name => 'Nom complet';

  @override
  String get phoneNumber => 'Téléphone';

  @override
  String get vehicleType => 'Type de véhicule';

  @override
  String get bike => 'Vélo';

  @override
  String get motorcycle => 'Moto';

  @override
  String get car => 'Voiture';

  @override
  String get logout => 'Déconnexion';

  @override
  String get settings => 'Paramètres';

  @override
  String get language => 'Langue';

  @override
  String get profile => 'Profil';

  @override
  String get online => 'En ligne';

  @override
  String get offline => 'Hors ligne';

  @override
  String get searchingForOrders => 'Recherche de commandes';

  @override
  String get goOffline => 'Se déconnecter';

  @override
  String get earnings => 'Gains';

  @override
  String get todayEarnings => 'Gains d\'aujourd\'hui';

  @override
  String get totalDeliveries => 'Livraisons totales';

  @override
  String get orderHistory => 'Historique des commandes';

  @override
  String get newOrderAvailable => 'Nouvelle commande disponible !';

  @override
  String get restaurantLocation => 'Restaurant';

  @override
  String get customerName => 'Client';

  @override
  String get distance => 'Distance';

  @override
  String get acceptOrder => 'Accepter la commande';

  @override
  String get declineOrder => 'Refuser';

  @override
  String get navigateToRestaurant => 'Aller au restaurant';

  @override
  String get pickedUpOrder => 'Commande récupérée';

  @override
  String get navigateToCustomer => 'Aller chez le client';

  @override
  String get orderDelivered => 'Commande livrée';

  @override
  String get support => 'Support';

  @override
  String get callSupport => 'Appeler le support';

  @override
  String get deliveryAddress => 'Adresse de livraison';

  @override
  String get loading => 'Chargement...';

  @override
  String get error => 'Une erreur s\'est produite';

  @override
  String get required => 'Requis';

  @override
  String get noActiveOrder => 'Aucune commande active';

  @override
  String get welcome => 'Bienvenue';

  @override
  String get fillAllFields => 'Remplissez tous les champs';

  @override
  String get wrongCredentials => 'Email ou mot de passe incorrect';

  @override
  String get demoAccount => 'Compte démo';

  @override
  String get minPassword => 'Min. 6 caractères';

  @override
  String get emailAlreadyExists => 'Email déjà enregistré';

  @override
  String km(String distance) {
    return '$distance km';
  }
}
