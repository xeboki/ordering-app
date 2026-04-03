// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get navShop => 'Shop';

  @override
  String get navOrders => 'Orders';

  @override
  String get navBookings => 'Bookings';

  @override
  String get navAccount => 'Account';

  @override
  String get navViewCart => 'View Cart';

  @override
  String get authSignIn => 'Sign In';

  @override
  String get authSignOut => 'Sign Out';

  @override
  String get authCreateAccount => 'Create Account';

  @override
  String get authWelcomeBack => 'Welcome back';

  @override
  String get authSignInToContinue => 'Sign in to continue';

  @override
  String get authDontHaveAccount => 'Don\'t have an account?';

  @override
  String get authAlreadyHaveAccount => 'Already have an account?';

  @override
  String get authContinueAsGuest => 'Continue as guest';

  @override
  String authJoinStore(String storeName) {
    return 'Join $storeName today';
  }

  @override
  String get authEmailLabel => 'Email';

  @override
  String get authPasswordLabel => 'Password';

  @override
  String get authFullNameLabel => 'Full name';

  @override
  String get authPhoneLabel => 'Phone (optional)';

  @override
  String get authEmailRequired => 'Email is required';

  @override
  String get authEmailInvalid => 'Enter a valid email';

  @override
  String get authPasswordRequired => 'Password is required';

  @override
  String get authPasswordTooShort => 'Password must be at least 6 characters';

  @override
  String get authIncorrectCredentials => 'Incorrect email or password.';

  @override
  String get authAccountNotFound => 'No account found with that email.';

  @override
  String get authEmailTaken => 'An account with this email already exists.';

  @override
  String get authLoginFailed => 'Login failed. Please try again.';

  @override
  String get authRegisterFailed => 'Registration failed. Please try again.';

  @override
  String catalogSearchHint(String storeName) {
    return 'Search $storeName…';
  }

  @override
  String get catalogAll => 'All';

  @override
  String get catalogNoProducts => 'No products found';

  @override
  String get catalogOutOfStock => 'Out of Stock';

  @override
  String get catalogFailedToLoad => 'Failed to load products';

  @override
  String get productSpecialInstructions => 'Special instructions';

  @override
  String get productInstructionsHint => 'E.g. no onions, extra sauce…';

  @override
  String get productRequired => 'Required';

  @override
  String productChooseUpTo(int max) {
    return 'Choose up to $max';
  }

  @override
  String productAddPrice(String price) {
    return 'Add $price';
  }

  @override
  String productAddedToCart(String name) {
    return '$name added to cart';
  }

  @override
  String get cartTitle => 'Your Cart';

  @override
  String get cartEmpty => 'Your cart is empty';

  @override
  String get cartEmptyHint => 'Add items from the menu to get started';

  @override
  String get cartBrowseMenu => 'Browse Menu';

  @override
  String get cartClearTitle => 'Clear cart?';

  @override
  String get cartClearMessage => 'All items will be removed.';

  @override
  String get cartClear => 'Clear';

  @override
  String get cartDiscountCode => 'Discount code';

  @override
  String get cartApply => 'Apply';

  @override
  String get cartSubtotal => 'Subtotal';

  @override
  String get cartDiscount => 'Discount';

  @override
  String get cartTotal => 'Total';

  @override
  String get cartProceedToCheckout => 'Proceed to Checkout';

  @override
  String get checkoutTitle => 'Checkout';

  @override
  String get checkoutOrderType => 'Order type';

  @override
  String get checkoutPaymentMethod => 'Payment method';

  @override
  String get checkoutNotes => 'Notes';

  @override
  String get checkoutNotesHint => 'Any special instructions?';

  @override
  String get checkoutOrderSummary => 'Order summary';

  @override
  String checkoutPlaceOrder(String total) {
    return 'Place Order — $total';
  }

  @override
  String get checkoutDeliveryAddress => 'Delivery address';

  @override
  String get checkoutStreetAddress => 'Street address';

  @override
  String get checkoutApartment => 'Apartment / Floor (optional)';

  @override
  String get checkoutCity => 'City';

  @override
  String get checkoutStreetRequired => 'Street address is required';

  @override
  String get checkoutCityRequired => 'City is required';

  @override
  String get checkoutSelectTable => 'Select your table';

  @override
  String checkoutTableLabel(String name) {
    return 'Table $name';
  }

  @override
  String get checkoutAvailable => 'Available';

  @override
  String get checkoutOccupied => 'Occupied';

  @override
  String get checkoutSchedule => 'Schedule for later';

  @override
  String get checkoutScheduleTime => 'Pickup time';

  @override
  String checkoutLoyaltyAvailable(int points, String value) {
    return '$points pts available (saves $value)';
  }

  @override
  String get checkoutApplyPoints => 'Apply';

  @override
  String get checkoutRemovePoints => 'Remove';

  @override
  String checkoutPointsApplied(int points) {
    return '$points pts applied';
  }

  @override
  String get checkoutOrderFailed => 'Failed to place order. Please try again.';

  @override
  String get checkoutNetworkError => 'Network error. Please try again.';

  @override
  String get checkoutItemUnavailable =>
      'One or more items are no longer available.';

  @override
  String get orderTypePickup => 'Pickup';

  @override
  String get orderTypeDelivery => 'Delivery';

  @override
  String get orderTypeDineIn => 'Dine In';

  @override
  String get orderTypeTakeaway => 'Takeaway';

  @override
  String get paymentCash => 'Cash';

  @override
  String get paymentCard => 'Card';

  @override
  String get paymentGiftCard => 'Gift Card';

  @override
  String get statusPending => 'Order Placed';

  @override
  String get statusConfirmed => 'Confirmed';

  @override
  String get statusProcessing => 'Preparing';

  @override
  String get statusReady => 'Ready';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get ordersTitle => 'My Orders';

  @override
  String get ordersEmpty => 'No orders yet';

  @override
  String get ordersEmptyHint => 'Your order history will appear here';

  @override
  String get ordersTrack => 'Track Order';

  @override
  String get ordersSignInRequired => 'Sign in to view your orders';

  @override
  String get ordersFailed => 'Failed to load orders';

  @override
  String get orderDetailTitle => 'Order Details';

  @override
  String get orderDetailItems => 'Items';

  @override
  String get orderDetailNotes => 'Notes';

  @override
  String get orderDetailCouldNotLoad => 'Could not load order';

  @override
  String get trackingTitle => 'Track Order';

  @override
  String get trackingYourOrder => 'Your order';

  @override
  String get trackingViewAll => 'View All Orders';

  @override
  String get trackingContinueShopping => 'Continue Shopping';

  @override
  String get trackingCancelled => 'This order was cancelled';

  @override
  String get accountTitle => 'Account';

  @override
  String get accountLoyaltyPoints => 'Loyalty Points';

  @override
  String get accountStoreCredit => 'Store Credit';

  @override
  String get accountMyOrders => 'My Orders';

  @override
  String get accountDarkMode => 'Dark Mode';

  @override
  String get accountLanguage => 'Language';

  @override
  String get accountPreferences => 'Preferences';

  @override
  String get accountSupport => 'Support';

  @override
  String get accountAbout => 'About';

  @override
  String get accountShopping => 'Shopping';

  @override
  String get accountSignInRequired => 'Sign in to view your account';

  @override
  String get accountSignInBenefit =>
      'Sign in to track orders, earn loyalty points and more';

  @override
  String get accountSignOutTitle => 'Sign out?';

  @override
  String get accountSignOutMessage =>
      'You will need to sign in again to place orders.';

  @override
  String get apptTitle => 'My Bookings';

  @override
  String get apptEmpty => 'No bookings yet';

  @override
  String get apptEmptyHint => 'Tap + to book an appointment';

  @override
  String get apptBook => 'Book';

  @override
  String get apptBookTitle => 'Book Appointment';

  @override
  String get apptConfirm => 'Confirm Booking';

  @override
  String get apptSignInRequired => 'Sign in to manage bookings';

  @override
  String get apptNotesHint => 'Any notes or requests…';

  @override
  String get apptBookingFailed => 'Booking failed. Please try again.';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonClose => 'Close';

  @override
  String get commonRetry => 'Try Again';

  @override
  String get commonRefresh => 'Refresh';

  @override
  String get commonSave => 'Save';

  @override
  String get commonDone => 'Done';

  @override
  String get commonError => 'Something went wrong';

  @override
  String get commonNetworkError => 'No internet connection';

  @override
  String get commonSignIn => 'Sign In';

  @override
  String get langEnglish => 'English';

  @override
  String get langArabic => 'العربية';

  @override
  String get langFrench => 'Français';

  @override
  String get langSpanish => 'Español';

  @override
  String get splashInvalidKeyTitle => 'Invalid API Key';

  @override
  String get splashInvalidKeyMessage =>
      'The API key configured for this app is invalid or has been revoked.';

  @override
  String get splashInvalidKeyHint =>
      'Contact the app owner to update the API key.';

  @override
  String get splashNoSubscriptionTitle => 'No Active Subscription';

  @override
  String get splashNoSubscriptionMessage =>
      'This account does not have an active POS subscription.';

  @override
  String get splashNoSubscriptionLink => 'Subscribe at xeboki.com/xe-pos →';

  @override
  String get splashNoSubscriptionHint =>
      'The app will become available once a subscription is activated.';

  @override
  String get splashFreePlanTitle => 'Plan Upgrade Required';

  @override
  String get splashFreePlanMessage =>
      'The Ordering App is not available on the free POS plan.';

  @override
  String get splashFreePlanLink => 'Upgrade at xeboki.com/xe-pos →';

  @override
  String get splashFreePlanHint =>
      'Free plan includes in-store POS only. Online ordering requires a paid plan.';

  @override
  String get splashFeatureNotInPlanTitle => 'Feature Not Included';

  @override
  String get splashFeatureNotInPlanMessage =>
      'Your current POS plan does not include the Ordering App.';

  @override
  String get splashFeatureNotInPlanLink => 'Upgrade at xeboki.com/xe-pos →';

  @override
  String get splashFeatureNotInPlanHint =>
      'Visit xeboki.com/xe-pos to upgrade your plan.';

  @override
  String get splashNetworkErrorTitle => 'No Connection';

  @override
  String get splashNetworkErrorMessage =>
      'Unable to verify your subscription. Please check your internet connection and try again.';

  @override
  String get splashNetworkErrorHint =>
      'The app requires a connection to start.';

  @override
  String get splashChecking => 'Checking…';

  @override
  String get splashPoweredBy => 'Powered by';
}
