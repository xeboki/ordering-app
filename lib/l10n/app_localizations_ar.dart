// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get navShop => 'المتجر';

  @override
  String get navOrders => 'طلباتي';

  @override
  String get navBookings => 'الحجوزات';

  @override
  String get navAccount => 'حسابي';

  @override
  String get navViewCart => 'عرض السلة';

  @override
  String get authSignIn => 'تسجيل الدخول';

  @override
  String get authSignOut => 'تسجيل الخروج';

  @override
  String get authCreateAccount => 'إنشاء حساب';

  @override
  String get authWelcomeBack => 'مرحباً بعودتك';

  @override
  String get authSignInToContinue => 'سجّل الدخول للمتابعة';

  @override
  String get authDontHaveAccount => 'ليس لديك حساب؟';

  @override
  String get authAlreadyHaveAccount => 'لديك حساب بالفعل؟';

  @override
  String get authContinueAsGuest => 'المتابعة كضيف';

  @override
  String authJoinStore(String storeName) {
    return 'انضم إلى $storeName اليوم';
  }

  @override
  String get authEmailLabel => 'البريد الإلكتروني';

  @override
  String get authPasswordLabel => 'كلمة المرور';

  @override
  String get authFullNameLabel => 'الاسم الكامل';

  @override
  String get authPhoneLabel => 'رقم الهاتف (اختياري)';

  @override
  String get authEmailRequired => 'البريد الإلكتروني مطلوب';

  @override
  String get authEmailInvalid => 'أدخل بريداً إلكترونياً صحيحاً';

  @override
  String get authPasswordRequired => 'كلمة المرور مطلوبة';

  @override
  String get authPasswordTooShort => 'يجب أن تكون كلمة المرور 6 أحرف على الأقل';

  @override
  String get authIncorrectCredentials =>
      'البريد الإلكتروني أو كلمة المرور غير صحيحة.';

  @override
  String get authAccountNotFound => 'لا يوجد حساب بهذا البريد الإلكتروني.';

  @override
  String get authEmailTaken => 'يوجد حساب بهذا البريد الإلكتروني مسبقاً.';

  @override
  String get authLoginFailed => 'فشل تسجيل الدخول. حاول مجدداً.';

  @override
  String get authRegisterFailed => 'فشل إنشاء الحساب. حاول مجدداً.';

  @override
  String catalogSearchHint(String storeName) {
    return 'ابحث في $storeName…';
  }

  @override
  String get catalogAll => 'الكل';

  @override
  String get catalogNoProducts => 'لا توجد منتجات';

  @override
  String get catalogOutOfStock => 'غير متوفر';

  @override
  String get catalogFailedToLoad => 'فشل تحميل المنتجات';

  @override
  String get productSpecialInstructions => 'تعليمات خاصة';

  @override
  String get productInstructionsHint => 'مثال: بدون بصل، صوص إضافي…';

  @override
  String get productRequired => 'إلزامي';

  @override
  String productChooseUpTo(int max) {
    return 'اختر حتى $max';
  }

  @override
  String productAddPrice(String price) {
    return 'إضافة $price';
  }

  @override
  String productAddedToCart(String name) {
    return 'تمت إضافة $name إلى السلة';
  }

  @override
  String get cartTitle => 'سلة التسوق';

  @override
  String get cartEmpty => 'سلتك فارغة';

  @override
  String get cartEmptyHint => 'أضف عناصر من القائمة للبدء';

  @override
  String get cartBrowseMenu => 'تصفح القائمة';

  @override
  String get cartClearTitle => 'مسح السلة؟';

  @override
  String get cartClearMessage => 'سيتم حذف جميع العناصر.';

  @override
  String get cartClear => 'مسح';

  @override
  String get cartDiscountCode => 'رمز الخصم';

  @override
  String get cartApply => 'تطبيق';

  @override
  String get cartSubtotal => 'المجموع الفرعي';

  @override
  String get cartDiscount => 'الخصم';

  @override
  String get cartTotal => 'الإجمالي';

  @override
  String get cartProceedToCheckout => 'المتابعة للدفع';

  @override
  String get checkoutTitle => 'إتمام الطلب';

  @override
  String get checkoutOrderType => 'نوع الطلب';

  @override
  String get checkoutPaymentMethod => 'طريقة الدفع';

  @override
  String get checkoutNotes => 'ملاحظات';

  @override
  String get checkoutNotesHint => 'أي تعليمات خاصة؟';

  @override
  String get checkoutOrderSummary => 'ملخص الطلب';

  @override
  String checkoutPlaceOrder(String total) {
    return 'تأكيد الطلب — $total';
  }

  @override
  String get checkoutDeliveryAddress => 'عنوان التوصيل';

  @override
  String get checkoutStreetAddress => 'عنوان الشارع';

  @override
  String get checkoutApartment => 'الشقة / الطابق (اختياري)';

  @override
  String get checkoutCity => 'المدينة';

  @override
  String get checkoutStreetRequired => 'عنوان الشارع مطلوب';

  @override
  String get checkoutCityRequired => 'المدينة مطلوبة';

  @override
  String get checkoutSelectTable => 'اختر طاولتك';

  @override
  String checkoutTableLabel(String name) {
    return 'طاولة $name';
  }

  @override
  String get checkoutAvailable => 'متاحة';

  @override
  String get checkoutOccupied => 'مشغولة';

  @override
  String get checkoutSchedule => 'جدولة لوقت لاحق';

  @override
  String get checkoutScheduleTime => 'وقت الاستلام';

  @override
  String checkoutLoyaltyAvailable(int points, String value) {
    return '$points نقطة متاحة (توفير $value)';
  }

  @override
  String get checkoutApplyPoints => 'تطبيق';

  @override
  String get checkoutRemovePoints => 'إزالة';

  @override
  String checkoutPointsApplied(int points) {
    return 'تم تطبيق $points نقطة';
  }

  @override
  String get checkoutOrderFailed => 'فشل تقديم الطلب. حاول مجدداً.';

  @override
  String get checkoutNetworkError => 'خطأ في الشبكة. حاول مجدداً.';

  @override
  String get checkoutItemUnavailable => 'أحد المنتجات أو أكثر لم يعد متاحاً.';

  @override
  String get orderTypePickup => 'استلام';

  @override
  String get orderTypeDelivery => 'توصيل';

  @override
  String get orderTypeDineIn => 'تناول في المكان';

  @override
  String get orderTypeTakeaway => 'للمنزل';

  @override
  String get paymentCash => 'نقداً';

  @override
  String get paymentCard => 'بطاقة';

  @override
  String get paymentGiftCard => 'بطاقة هدية';

  @override
  String get statusPending => 'تم تقديم الطلب';

  @override
  String get statusConfirmed => 'تم التأكيد';

  @override
  String get statusProcessing => 'قيد التحضير';

  @override
  String get statusReady => 'جاهز';

  @override
  String get statusCompleted => 'مكتمل';

  @override
  String get statusCancelled => 'ملغي';

  @override
  String get ordersTitle => 'طلباتي';

  @override
  String get ordersEmpty => 'لا توجد طلبات بعد';

  @override
  String get ordersEmptyHint => 'سيظهر سجل طلباتك هنا';

  @override
  String get ordersTrack => 'تتبع الطلب';

  @override
  String get ordersSignInRequired => 'سجّل الدخول لعرض طلباتك';

  @override
  String get ordersFailed => 'فشل تحميل الطلبات';

  @override
  String get orderDetailTitle => 'تفاصيل الطلب';

  @override
  String get orderDetailItems => 'العناصر';

  @override
  String get orderDetailNotes => 'ملاحظات';

  @override
  String get orderDetailCouldNotLoad => 'تعذّر تحميل الطلب';

  @override
  String get trackingTitle => 'تتبع الطلب';

  @override
  String get trackingYourOrder => 'طلبك';

  @override
  String get trackingViewAll => 'عرض جميع الطلبات';

  @override
  String get trackingContinueShopping => 'مواصلة التسوق';

  @override
  String get trackingCancelled => 'تم إلغاء هذا الطلب';

  @override
  String get accountTitle => 'حسابي';

  @override
  String get accountLoyaltyPoints => 'نقاط الولاء';

  @override
  String get accountStoreCredit => 'رصيد المتجر';

  @override
  String get accountMyOrders => 'طلباتي';

  @override
  String get accountDarkMode => 'الوضع الداكن';

  @override
  String get accountLanguage => 'اللغة';

  @override
  String get accountPreferences => 'التفضيلات';

  @override
  String get accountSupport => 'الدعم';

  @override
  String get accountAbout => 'حول';

  @override
  String get accountShopping => 'التسوق';

  @override
  String get accountSignInRequired => 'سجّل الدخول لعرض حسابك';

  @override
  String get accountSignInBenefit =>
      'سجّل الدخول لتتبع الطلبات وكسب نقاط الولاء والمزيد';

  @override
  String get accountSignOutTitle => 'تسجيل الخروج؟';

  @override
  String get accountSignOutMessage =>
      'ستحتاج إلى تسجيل الدخول مجدداً لتقديم الطلبات.';

  @override
  String get apptTitle => 'حجوزاتي';

  @override
  String get apptEmpty => 'لا توجد حجوزات بعد';

  @override
  String get apptEmptyHint => 'اضغط + لحجز موعد';

  @override
  String get apptBook => 'حجز';

  @override
  String get apptBookTitle => 'حجز موعد';

  @override
  String get apptConfirm => 'تأكيد الحجز';

  @override
  String get apptSignInRequired => 'سجّل الدخول لإدارة الحجوزات';

  @override
  String get apptNotesHint => 'أي ملاحظات أو طلبات…';

  @override
  String get apptBookingFailed => 'فشل الحجز. حاول مجدداً.';

  @override
  String get commonCancel => 'إلغاء';

  @override
  String get commonClose => 'إغلاق';

  @override
  String get commonRetry => 'حاول مجدداً';

  @override
  String get commonRefresh => 'تحديث';

  @override
  String get commonSave => 'حفظ';

  @override
  String get commonDone => 'تم';

  @override
  String get commonError => 'حدث خطأ ما';

  @override
  String get commonNetworkError => 'لا يوجد اتصال بالإنترنت';

  @override
  String get commonSignIn => 'تسجيل الدخول';

  @override
  String get langEnglish => 'English';

  @override
  String get langArabic => 'العربية';

  @override
  String get langFrench => 'Français';

  @override
  String get langSpanish => 'Español';

  @override
  String get splashInvalidKeyTitle => 'مفتاح API غير صالح';

  @override
  String get splashInvalidKeyMessage =>
      'مفتاح API المُهيَّأ لهذا التطبيق غير صالح أو تم إلغاؤه.';

  @override
  String get splashInvalidKeyHint => 'تواصل مع مالك التطبيق لتحديث المفتاح.';

  @override
  String get splashNoSubscriptionTitle => 'لا يوجد اشتراك نشط';

  @override
  String get splashNoSubscriptionMessage =>
      'لا يملك هذا الحساب اشتراكاً نشطاً في نظام POS.';

  @override
  String get splashNoSubscriptionLink => '← اشترك على xeboki.com/xe-pos';

  @override
  String get splashNoSubscriptionHint =>
      'سيصبح التطبيق متاحاً بعد تفعيل الاشتراك.';

  @override
  String get splashFreePlanTitle => 'ترقية الخطة مطلوبة';

  @override
  String get splashFreePlanMessage =>
      'تطبيق الطلبات غير متاح في خطة POS المجانية.';

  @override
  String get splashFreePlanLink => '← قم بالترقية على xeboki.com/xe-pos';

  @override
  String get splashFreePlanHint =>
      'الخطة المجانية تشمل نقطة البيع داخل المتجر فقط. الطلبات عبر الإنترنت تتطلب خطة مدفوعة.';

  @override
  String get splashFeatureNotInPlanTitle => 'الميزة غير مشمولة';

  @override
  String get splashFeatureNotInPlanMessage =>
      'خطة POS الحالية لا تشمل تطبيق الطلبات.';

  @override
  String get splashFeatureNotInPlanLink =>
      '← قم بترقية خطتك على xeboki.com/xe-pos';

  @override
  String get splashFeatureNotInPlanHint =>
      'تفضل بزيارة xeboki.com/xe-pos لترقية خطتك.';

  @override
  String get splashNetworkErrorTitle => 'لا يوجد اتصال';

  @override
  String get splashNetworkErrorMessage =>
      'تعذّر التحقق من اشتراكك. يرجى التحقق من اتصالك بالإنترنت والمحاولة مرة أخرى.';

  @override
  String get splashNetworkErrorHint => 'يتطلب التطبيق اتصالاً بالإنترنت للبدء.';

  @override
  String get splashChecking => 'جارٍ التحقق…';

  @override
  String get splashPoweredBy => 'مدعوم من';
}
