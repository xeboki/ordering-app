// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get navShop => 'Tienda';

  @override
  String get navOrders => 'Pedidos';

  @override
  String get navBookings => 'Reservas';

  @override
  String get navAccount => 'Cuenta';

  @override
  String get navViewCart => 'Ver carrito';

  @override
  String get authSignIn => 'Iniciar sesión';

  @override
  String get authSignOut => 'Cerrar sesión';

  @override
  String get authCreateAccount => 'Crear cuenta';

  @override
  String get authWelcomeBack => 'Bienvenido de nuevo';

  @override
  String get authSignInToContinue => 'Inicia sesión para continuar';

  @override
  String get authDontHaveAccount => '¿No tienes cuenta?';

  @override
  String get authAlreadyHaveAccount => '¿Ya tienes cuenta?';

  @override
  String get authContinueAsGuest => 'Continuar como invitado';

  @override
  String authJoinStore(String storeName) {
    return 'Únete a $storeName hoy';
  }

  @override
  String get authEmailLabel => 'Correo electrónico';

  @override
  String get authPasswordLabel => 'Contraseña';

  @override
  String get authFullNameLabel => 'Nombre completo';

  @override
  String get authPhoneLabel => 'Teléfono (opcional)';

  @override
  String get authEmailRequired => 'El correo electrónico es obligatorio';

  @override
  String get authEmailInvalid => 'Introduce un correo electrónico válido';

  @override
  String get authPasswordRequired => 'La contraseña es obligatoria';

  @override
  String get authPasswordTooShort =>
      'La contraseña debe tener al menos 6 caracteres';

  @override
  String get authIncorrectCredentials =>
      'Correo electrónico o contraseña incorrectos.';

  @override
  String get authAccountNotFound =>
      'No se encontró ninguna cuenta con ese correo.';

  @override
  String get authEmailTaken => 'Ya existe una cuenta con este correo.';

  @override
  String get authLoginFailed => 'Error al iniciar sesión. Inténtalo de nuevo.';

  @override
  String get authRegisterFailed => 'Error al registrarse. Inténtalo de nuevo.';

  @override
  String catalogSearchHint(String storeName) {
    return 'Buscar en $storeName…';
  }

  @override
  String get catalogAll => 'Todo';

  @override
  String get catalogNoProducts => 'No se encontraron productos';

  @override
  String get catalogOutOfStock => 'Agotado';

  @override
  String get catalogFailedToLoad => 'Error al cargar los productos';

  @override
  String get productSpecialInstructions => 'Instrucciones especiales';

  @override
  String get productInstructionsHint => 'Ej. sin cebolla, salsa extra…';

  @override
  String get productRequired => 'Obligatorio';

  @override
  String productChooseUpTo(int max) {
    return 'Elige hasta $max';
  }

  @override
  String productAddPrice(String price) {
    return 'Añadir $price';
  }

  @override
  String productAddedToCart(String name) {
    return '$name añadido al carrito';
  }

  @override
  String get cartTitle => 'Tu carrito';

  @override
  String get cartEmpty => 'Tu carrito está vacío';

  @override
  String get cartEmptyHint => 'Añade artículos del menú para empezar';

  @override
  String get cartBrowseMenu => 'Explorar menú';

  @override
  String get cartClearTitle => '¿Vaciar carrito?';

  @override
  String get cartClearMessage => 'Se eliminarán todos los artículos.';

  @override
  String get cartClear => 'Vaciar';

  @override
  String get cartDiscountCode => 'Código de descuento';

  @override
  String get cartApply => 'Aplicar';

  @override
  String get cartSubtotal => 'Subtotal';

  @override
  String get cartDiscount => 'Descuento';

  @override
  String get cartTotal => 'Total';

  @override
  String get cartProceedToCheckout => 'Proceder al pago';

  @override
  String get checkoutTitle => 'Pago';

  @override
  String get checkoutOrderType => 'Tipo de pedido';

  @override
  String get checkoutPaymentMethod => 'Método de pago';

  @override
  String get checkoutNotes => 'Notas';

  @override
  String get checkoutNotesHint => '¿Alguna instrucción especial?';

  @override
  String get checkoutOrderSummary => 'Resumen del pedido';

  @override
  String checkoutPlaceOrder(String total) {
    return 'Realizar pedido — $total';
  }

  @override
  String get checkoutDeliveryAddress => 'Dirección de entrega';

  @override
  String get checkoutStreetAddress => 'Dirección';

  @override
  String get checkoutApartment => 'Apartamento / Piso (opcional)';

  @override
  String get checkoutCity => 'Ciudad';

  @override
  String get checkoutStreetRequired => 'La dirección es obligatoria';

  @override
  String get checkoutCityRequired => 'La ciudad es obligatoria';

  @override
  String get checkoutSelectTable => 'Selecciona tu mesa';

  @override
  String checkoutTableLabel(String name) {
    return 'Mesa $name';
  }

  @override
  String get checkoutAvailable => 'Disponible';

  @override
  String get checkoutOccupied => 'Ocupada';

  @override
  String get checkoutSchedule => 'Programar para más tarde';

  @override
  String get checkoutScheduleTime => 'Hora de recogida';

  @override
  String checkoutLoyaltyAvailable(int points, String value) {
    return '$points pts disponibles (ahorra $value)';
  }

  @override
  String get checkoutApplyPoints => 'Aplicar';

  @override
  String get checkoutRemovePoints => 'Quitar';

  @override
  String checkoutPointsApplied(int points) {
    return '$points pts aplicados';
  }

  @override
  String get checkoutOrderFailed =>
      'Error al realizar el pedido. Inténtalo de nuevo.';

  @override
  String get checkoutNetworkError => 'Error de red. Inténtalo de nuevo.';

  @override
  String get checkoutItemUnavailable =>
      'Uno o más artículos ya no están disponibles.';

  @override
  String get orderTypePickup => 'Recogida';

  @override
  String get orderTypeDelivery => 'Entrega';

  @override
  String get orderTypeDineIn => 'En el local';

  @override
  String get orderTypeTakeaway => 'Para llevar';

  @override
  String get paymentCash => 'Efectivo';

  @override
  String get paymentCard => 'Tarjeta';

  @override
  String get paymentGiftCard => 'Tarjeta regalo';

  @override
  String get statusPending => 'Pedido realizado';

  @override
  String get statusConfirmed => 'Confirmado';

  @override
  String get statusProcessing => 'Preparando';

  @override
  String get statusReady => 'Listo';

  @override
  String get statusCompleted => 'Completado';

  @override
  String get statusCancelled => 'Cancelado';

  @override
  String get ordersTitle => 'Mis pedidos';

  @override
  String get ordersEmpty => 'Aún no hay pedidos';

  @override
  String get ordersEmptyHint => 'Tu historial de pedidos aparecerá aquí';

  @override
  String get ordersTrack => 'Seguir pedido';

  @override
  String get ordersSignInRequired => 'Inicia sesión para ver tus pedidos';

  @override
  String get ordersFailed => 'Error al cargar los pedidos';

  @override
  String get orderDetailTitle => 'Detalles del pedido';

  @override
  String get orderDetailItems => 'Artículos';

  @override
  String get orderDetailNotes => 'Notas';

  @override
  String get orderDetailCouldNotLoad => 'No se pudo cargar el pedido';

  @override
  String get trackingTitle => 'Seguimiento del pedido';

  @override
  String get trackingYourOrder => 'Tu pedido';

  @override
  String get trackingViewAll => 'Ver todos los pedidos';

  @override
  String get trackingContinueShopping => 'Seguir comprando';

  @override
  String get trackingCancelled => 'Este pedido fue cancelado';

  @override
  String get accountTitle => 'Cuenta';

  @override
  String get accountLoyaltyPoints => 'Puntos de fidelidad';

  @override
  String get accountStoreCredit => 'Crédito de tienda';

  @override
  String get accountMyOrders => 'Mis pedidos';

  @override
  String get accountDarkMode => 'Modo oscuro';

  @override
  String get accountLanguage => 'Idioma';

  @override
  String get accountPreferences => 'Preferencias';

  @override
  String get accountSupport => 'Soporte';

  @override
  String get accountAbout => 'Acerca de';

  @override
  String get accountShopping => 'Compras';

  @override
  String get accountSignInRequired => 'Inicia sesión para ver tu cuenta';

  @override
  String get accountSignInBenefit =>
      'Inicia sesión para seguir pedidos, ganar puntos de fidelidad y más';

  @override
  String get accountSignOutTitle => '¿Cerrar sesión?';

  @override
  String get accountSignOutMessage =>
      'Tendrás que iniciar sesión de nuevo para realizar pedidos.';

  @override
  String get apptTitle => 'Mis reservas';

  @override
  String get apptEmpty => 'Aún no hay reservas';

  @override
  String get apptEmptyHint => 'Pulsa + para reservar una cita';

  @override
  String get apptBook => 'Reservar';

  @override
  String get apptBookTitle => 'Reservar cita';

  @override
  String get apptConfirm => 'Confirmar reserva';

  @override
  String get apptSignInRequired => 'Inicia sesión para gestionar reservas';

  @override
  String get apptNotesHint => 'Notas o peticiones…';

  @override
  String get apptBookingFailed => 'Error al reservar. Inténtalo de nuevo.';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonClose => 'Cerrar';

  @override
  String get commonRetry => 'Reintentar';

  @override
  String get commonRefresh => 'Actualizar';

  @override
  String get commonSave => 'Guardar';

  @override
  String get commonDone => 'Listo';

  @override
  String get commonError => 'Algo salió mal';

  @override
  String get commonNetworkError => 'Sin conexión a Internet';

  @override
  String get commonSignIn => 'Iniciar sesión';

  @override
  String get langEnglish => 'English';

  @override
  String get langArabic => 'العربية';

  @override
  String get langFrench => 'Français';

  @override
  String get langSpanish => 'Español';

  @override
  String get splashInvalidKeyTitle => 'Clave API inválida';

  @override
  String get splashInvalidKeyMessage =>
      'La clave API configurada para esta aplicación es inválida o ha sido revocada.';

  @override
  String get splashInvalidKeyHint =>
      'Contacta al propietario de la app para actualizar la clave.';

  @override
  String get splashNoSubscriptionTitle => 'Sin suscripción activa';

  @override
  String get splashNoSubscriptionMessage =>
      'Esta cuenta no tiene una suscripción POS activa.';

  @override
  String get splashNoSubscriptionLink => 'Suscríbete en xeboki.com/xe-pos →';

  @override
  String get splashNoSubscriptionHint =>
      'La app estará disponible una vez activada la suscripción.';

  @override
  String get splashFreePlanTitle => 'Actualización requerida';

  @override
  String get splashFreePlanMessage =>
      'La App de Pedidos no está disponible en el plan POS gratuito.';

  @override
  String get splashFreePlanLink => 'Actualiza en xeboki.com/xe-pos →';

  @override
  String get splashFreePlanHint =>
      'El plan gratuito incluye solo POS en tienda. Los pedidos en línea requieren un plan de pago.';

  @override
  String get splashFeatureNotInPlanTitle => 'Función no incluida';

  @override
  String get splashFeatureNotInPlanMessage =>
      'Tu plan POS actual no incluye la App de Pedidos.';

  @override
  String get splashFeatureNotInPlanLink => 'Actualiza en xeboki.com/xe-pos →';

  @override
  String get splashFeatureNotInPlanHint =>
      'Visita xeboki.com/xe-pos para actualizar tu plan.';

  @override
  String get splashNetworkErrorTitle => 'Sin conexión';

  @override
  String get splashNetworkErrorMessage =>
      'No se puede verificar tu suscripción. Comprueba tu conexión a internet e inténtalo de nuevo.';

  @override
  String get splashNetworkErrorHint =>
      'La app requiere conexión para iniciarse.';

  @override
  String get splashChecking => 'Verificando…';

  @override
  String get splashPoweredBy => 'Desarrollado por';
}
