// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'D-helper Rider';

  @override
  String get login => 'تسجيل الدخول';

  @override
  String get register => 'إنشاء حساب';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get password => 'كلمة المرور';

  @override
  String get name => 'الاسم الكامل';

  @override
  String get phoneNumber => 'رقم الهاتف';

  @override
  String get vehicleType => 'نوع المركبة';

  @override
  String get bike => 'دراجة هوائية';

  @override
  String get motorcycle => 'دراجة نارية';

  @override
  String get car => 'سيارة';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get settings => 'الإعدادات';

  @override
  String get language => 'اللغة';

  @override
  String get profile => 'الملف الشخصي';

  @override
  String get online => 'متصل';

  @override
  String get offline => 'غير متصل';

  @override
  String get searchingForOrders => 'البحث عن طلبات';

  @override
  String get goOffline => 'قطع الاتصال';

  @override
  String get earnings => 'الأرباح';

  @override
  String get todayEarnings => 'أرباح اليوم';

  @override
  String get totalDeliveries => 'إجمالي التوصيلات';

  @override
  String get orderHistory => 'سجل الطلبات';

  @override
  String get newOrderAvailable => 'طلب جديد متاح!';

  @override
  String get restaurantLocation => 'المطعم';

  @override
  String get customerName => 'العميل';

  @override
  String get distance => 'المسافة';

  @override
  String get acceptOrder => 'قبول الطلب';

  @override
  String get declineOrder => 'رفض';

  @override
  String get navigateToRestaurant => 'التنقل إلى المطعم';

  @override
  String get pickedUpOrder => 'تم استلام الطلب';

  @override
  String get navigateToCustomer => 'التنقل إلى العميل';

  @override
  String get orderDelivered => 'تم توصيل الطلب';

  @override
  String get support => 'الدعم';

  @override
  String get callSupport => 'الاتصال بالدعم';

  @override
  String get deliveryAddress => 'عنوان التوصيل';

  @override
  String get loading => 'جار التحميل...';

  @override
  String get error => 'حدث خطأ';

  @override
  String get required => 'مطلوب';

  @override
  String get noActiveOrder => 'لا يوجد طلب نشط';

  @override
  String get welcome => 'مرحباً بعودتك';

  @override
  String get fillAllFields => 'أكمل جميع الحقول';

  @override
  String get wrongCredentials => 'البريد الإلكتروني أو كلمة المرور غير صحيحة';

  @override
  String get demoAccount => 'حساب تجريبي';

  @override
  String get minPassword => '6 أحرف على الأقل';

  @override
  String get emailAlreadyExists => 'البريد الإلكتروني مسجل مسبقاً';

  @override
  String km(String distance) {
    return '$distance كم';
  }
}
