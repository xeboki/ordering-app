import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('es'),
    Locale('fr')
  ];

  /// No description provided for @navShop.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get navShop;

  /// No description provided for @navOrders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get navOrders;

  /// No description provided for @navBookings.
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get navBookings;

  /// No description provided for @navAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get navAccount;

  /// No description provided for @navViewCart.
  ///
  /// In en, this message translates to:
  /// **'View Cart'**
  String get navViewCart;

  /// No description provided for @authSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get authSignIn;

  /// No description provided for @authSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get authSignOut;

  /// No description provided for @authCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get authCreateAccount;

  /// No description provided for @authWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get authWelcomeBack;

  /// No description provided for @authSignInToContinue.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue'**
  String get authSignInToContinue;

  /// No description provided for @authDontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get authDontHaveAccount;

  /// No description provided for @authAlreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get authAlreadyHaveAccount;

  /// No description provided for @authContinueAsGuest.
  ///
  /// In en, this message translates to:
  /// **'Continue as guest'**
  String get authContinueAsGuest;

  /// No description provided for @authJoinStore.
  ///
  /// In en, this message translates to:
  /// **'Join {storeName} today'**
  String authJoinStore(String storeName);

  /// No description provided for @authEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmailLabel;

  /// No description provided for @authPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPasswordLabel;

  /// No description provided for @authFullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get authFullNameLabel;

  /// No description provided for @authPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone (optional)'**
  String get authPhoneLabel;

  /// No description provided for @authEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get authEmailRequired;

  /// No description provided for @authEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get authEmailInvalid;

  /// No description provided for @authPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get authPasswordRequired;

  /// No description provided for @authPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get authPasswordTooShort;

  /// No description provided for @authIncorrectCredentials.
  ///
  /// In en, this message translates to:
  /// **'Incorrect email or password.'**
  String get authIncorrectCredentials;

  /// No description provided for @authAccountNotFound.
  ///
  /// In en, this message translates to:
  /// **'No account found with that email.'**
  String get authAccountNotFound;

  /// No description provided for @authEmailTaken.
  ///
  /// In en, this message translates to:
  /// **'An account with this email already exists.'**
  String get authEmailTaken;

  /// No description provided for @authLoginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed. Please try again.'**
  String get authLoginFailed;

  /// No description provided for @authRegisterFailed.
  ///
  /// In en, this message translates to:
  /// **'Registration failed. Please try again.'**
  String get authRegisterFailed;

  /// No description provided for @catalogSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search {storeName}…'**
  String catalogSearchHint(String storeName);

  /// No description provided for @catalogAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get catalogAll;

  /// No description provided for @catalogNoProducts.
  ///
  /// In en, this message translates to:
  /// **'No products found'**
  String get catalogNoProducts;

  /// No description provided for @catalogOutOfStock.
  ///
  /// In en, this message translates to:
  /// **'Out of Stock'**
  String get catalogOutOfStock;

  /// No description provided for @catalogFailedToLoad.
  ///
  /// In en, this message translates to:
  /// **'Failed to load products'**
  String get catalogFailedToLoad;

  /// No description provided for @productSpecialInstructions.
  ///
  /// In en, this message translates to:
  /// **'Special instructions'**
  String get productSpecialInstructions;

  /// No description provided for @productInstructionsHint.
  ///
  /// In en, this message translates to:
  /// **'E.g. no onions, extra sauce…'**
  String get productInstructionsHint;

  /// No description provided for @productRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get productRequired;

  /// No description provided for @productChooseUpTo.
  ///
  /// In en, this message translates to:
  /// **'Choose up to {max}'**
  String productChooseUpTo(int max);

  /// No description provided for @productAddPrice.
  ///
  /// In en, this message translates to:
  /// **'Add {price}'**
  String productAddPrice(String price);

  /// No description provided for @productAddedToCart.
  ///
  /// In en, this message translates to:
  /// **'{name} added to cart'**
  String productAddedToCart(String name);

  /// No description provided for @cartTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Cart'**
  String get cartTitle;

  /// No description provided for @cartEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your cart is empty'**
  String get cartEmpty;

  /// No description provided for @cartEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Add items from the menu to get started'**
  String get cartEmptyHint;

  /// No description provided for @cartBrowseMenu.
  ///
  /// In en, this message translates to:
  /// **'Browse Menu'**
  String get cartBrowseMenu;

  /// No description provided for @cartClearTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear cart?'**
  String get cartClearTitle;

  /// No description provided for @cartClearMessage.
  ///
  /// In en, this message translates to:
  /// **'All items will be removed.'**
  String get cartClearMessage;

  /// No description provided for @cartClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get cartClear;

  /// No description provided for @cartDiscountCode.
  ///
  /// In en, this message translates to:
  /// **'Discount code'**
  String get cartDiscountCode;

  /// No description provided for @cartApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get cartApply;

  /// No description provided for @cartSubtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get cartSubtotal;

  /// No description provided for @cartDiscount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get cartDiscount;

  /// No description provided for @cartTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get cartTotal;

  /// No description provided for @cartProceedToCheckout.
  ///
  /// In en, this message translates to:
  /// **'Proceed to Checkout'**
  String get cartProceedToCheckout;

  /// No description provided for @checkoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get checkoutTitle;

  /// No description provided for @checkoutOrderType.
  ///
  /// In en, this message translates to:
  /// **'Order type'**
  String get checkoutOrderType;

  /// No description provided for @checkoutPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment method'**
  String get checkoutPaymentMethod;

  /// No description provided for @checkoutNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get checkoutNotes;

  /// No description provided for @checkoutNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Any special instructions?'**
  String get checkoutNotesHint;

  /// No description provided for @checkoutOrderSummary.
  ///
  /// In en, this message translates to:
  /// **'Order summary'**
  String get checkoutOrderSummary;

  /// No description provided for @checkoutPlaceOrder.
  ///
  /// In en, this message translates to:
  /// **'Place Order — {total}'**
  String checkoutPlaceOrder(String total);

  /// No description provided for @checkoutDeliveryAddress.
  ///
  /// In en, this message translates to:
  /// **'Delivery address'**
  String get checkoutDeliveryAddress;

  /// No description provided for @checkoutStreetAddress.
  ///
  /// In en, this message translates to:
  /// **'Street address'**
  String get checkoutStreetAddress;

  /// No description provided for @checkoutApartment.
  ///
  /// In en, this message translates to:
  /// **'Apartment / Floor (optional)'**
  String get checkoutApartment;

  /// No description provided for @checkoutCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get checkoutCity;

  /// No description provided for @checkoutStreetRequired.
  ///
  /// In en, this message translates to:
  /// **'Street address is required'**
  String get checkoutStreetRequired;

  /// No description provided for @checkoutCityRequired.
  ///
  /// In en, this message translates to:
  /// **'City is required'**
  String get checkoutCityRequired;

  /// No description provided for @checkoutSelectTable.
  ///
  /// In en, this message translates to:
  /// **'Select your table'**
  String get checkoutSelectTable;

  /// No description provided for @checkoutTableLabel.
  ///
  /// In en, this message translates to:
  /// **'Table {name}'**
  String checkoutTableLabel(String name);

  /// No description provided for @checkoutAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get checkoutAvailable;

  /// No description provided for @checkoutOccupied.
  ///
  /// In en, this message translates to:
  /// **'Occupied'**
  String get checkoutOccupied;

  /// No description provided for @checkoutSchedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule for later'**
  String get checkoutSchedule;

  /// No description provided for @checkoutScheduleTime.
  ///
  /// In en, this message translates to:
  /// **'Pickup time'**
  String get checkoutScheduleTime;

  /// No description provided for @checkoutLoyaltyAvailable.
  ///
  /// In en, this message translates to:
  /// **'{points} pts available (saves {value})'**
  String checkoutLoyaltyAvailable(int points, String value);

  /// No description provided for @checkoutApplyPoints.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get checkoutApplyPoints;

  /// No description provided for @checkoutRemovePoints.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get checkoutRemovePoints;

  /// No description provided for @checkoutPointsApplied.
  ///
  /// In en, this message translates to:
  /// **'{points} pts applied'**
  String checkoutPointsApplied(int points);

  /// No description provided for @checkoutOrderFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to place order. Please try again.'**
  String get checkoutOrderFailed;

  /// No description provided for @checkoutNetworkError.
  ///
  /// In en, this message translates to:
  /// **'Network error. Please try again.'**
  String get checkoutNetworkError;

  /// No description provided for @checkoutItemUnavailable.
  ///
  /// In en, this message translates to:
  /// **'One or more items are no longer available.'**
  String get checkoutItemUnavailable;

  /// No description provided for @orderTypePickup.
  ///
  /// In en, this message translates to:
  /// **'Pickup'**
  String get orderTypePickup;

  /// No description provided for @orderTypeDelivery.
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get orderTypeDelivery;

  /// No description provided for @orderTypeDineIn.
  ///
  /// In en, this message translates to:
  /// **'Dine In'**
  String get orderTypeDineIn;

  /// No description provided for @orderTypeTakeaway.
  ///
  /// In en, this message translates to:
  /// **'Takeaway'**
  String get orderTypeTakeaway;

  /// No description provided for @paymentCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get paymentCash;

  /// No description provided for @paymentCard.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get paymentCard;

  /// No description provided for @paymentGiftCard.
  ///
  /// In en, this message translates to:
  /// **'Gift Card'**
  String get paymentGiftCard;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Order Placed'**
  String get statusPending;

  /// No description provided for @statusConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get statusConfirmed;

  /// No description provided for @statusProcessing.
  ///
  /// In en, this message translates to:
  /// **'Preparing'**
  String get statusProcessing;

  /// No description provided for @statusReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get statusReady;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// No description provided for @ordersTitle.
  ///
  /// In en, this message translates to:
  /// **'My Orders'**
  String get ordersTitle;

  /// No description provided for @ordersEmpty.
  ///
  /// In en, this message translates to:
  /// **'No orders yet'**
  String get ordersEmpty;

  /// No description provided for @ordersEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Your order history will appear here'**
  String get ordersEmptyHint;

  /// No description provided for @ordersTrack.
  ///
  /// In en, this message translates to:
  /// **'Track Order'**
  String get ordersTrack;

  /// No description provided for @ordersSignInRequired.
  ///
  /// In en, this message translates to:
  /// **'Sign in to view your orders'**
  String get ordersSignInRequired;

  /// No description provided for @ordersFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load orders'**
  String get ordersFailed;

  /// No description provided for @orderDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Order Details'**
  String get orderDetailTitle;

  /// No description provided for @orderDetailItems.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get orderDetailItems;

  /// No description provided for @orderDetailNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get orderDetailNotes;

  /// No description provided for @orderDetailCouldNotLoad.
  ///
  /// In en, this message translates to:
  /// **'Could not load order'**
  String get orderDetailCouldNotLoad;

  /// No description provided for @trackingTitle.
  ///
  /// In en, this message translates to:
  /// **'Track Order'**
  String get trackingTitle;

  /// No description provided for @trackingYourOrder.
  ///
  /// In en, this message translates to:
  /// **'Your order'**
  String get trackingYourOrder;

  /// No description provided for @trackingViewAll.
  ///
  /// In en, this message translates to:
  /// **'View All Orders'**
  String get trackingViewAll;

  /// No description provided for @trackingContinueShopping.
  ///
  /// In en, this message translates to:
  /// **'Continue Shopping'**
  String get trackingContinueShopping;

  /// No description provided for @trackingCancelled.
  ///
  /// In en, this message translates to:
  /// **'This order was cancelled'**
  String get trackingCancelled;

  /// No description provided for @accountTitle.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountTitle;

  /// No description provided for @accountLoyaltyPoints.
  ///
  /// In en, this message translates to:
  /// **'Loyalty Points'**
  String get accountLoyaltyPoints;

  /// No description provided for @accountStoreCredit.
  ///
  /// In en, this message translates to:
  /// **'Store Credit'**
  String get accountStoreCredit;

  /// No description provided for @accountMyOrders.
  ///
  /// In en, this message translates to:
  /// **'My Orders'**
  String get accountMyOrders;

  /// No description provided for @accountDarkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get accountDarkMode;

  /// No description provided for @accountLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get accountLanguage;

  /// No description provided for @accountPreferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get accountPreferences;

  /// No description provided for @accountSupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get accountSupport;

  /// No description provided for @accountAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get accountAbout;

  /// No description provided for @accountShopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get accountShopping;

  /// No description provided for @accountSignInRequired.
  ///
  /// In en, this message translates to:
  /// **'Sign in to view your account'**
  String get accountSignInRequired;

  /// No description provided for @accountSignInBenefit.
  ///
  /// In en, this message translates to:
  /// **'Sign in to track orders, earn loyalty points and more'**
  String get accountSignInBenefit;

  /// No description provided for @accountSignOutTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get accountSignOutTitle;

  /// No description provided for @accountSignOutMessage.
  ///
  /// In en, this message translates to:
  /// **'You will need to sign in again to place orders.'**
  String get accountSignOutMessage;

  /// No description provided for @apptTitle.
  ///
  /// In en, this message translates to:
  /// **'My Bookings'**
  String get apptTitle;

  /// No description provided for @apptEmpty.
  ///
  /// In en, this message translates to:
  /// **'No bookings yet'**
  String get apptEmpty;

  /// No description provided for @apptEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Tap + to book an appointment'**
  String get apptEmptyHint;

  /// No description provided for @apptBook.
  ///
  /// In en, this message translates to:
  /// **'Book'**
  String get apptBook;

  /// No description provided for @apptBookTitle.
  ///
  /// In en, this message translates to:
  /// **'Book Appointment'**
  String get apptBookTitle;

  /// No description provided for @apptConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm Booking'**
  String get apptConfirm;

  /// No description provided for @apptSignInRequired.
  ///
  /// In en, this message translates to:
  /// **'Sign in to manage bookings'**
  String get apptSignInRequired;

  /// No description provided for @apptNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Any notes or requests…'**
  String get apptNotesHint;

  /// No description provided for @apptBookingFailed.
  ///
  /// In en, this message translates to:
  /// **'Booking failed. Please try again.'**
  String get apptBookingFailed;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get commonRetry;

  /// No description provided for @commonRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get commonRefresh;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get commonDone;

  /// No description provided for @commonError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get commonError;

  /// No description provided for @commonNetworkError.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get commonNetworkError;

  /// No description provided for @commonSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get commonSignIn;

  /// No description provided for @langEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get langEnglish;

  /// No description provided for @langArabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get langArabic;

  /// No description provided for @langFrench.
  ///
  /// In en, this message translates to:
  /// **'Français'**
  String get langFrench;

  /// No description provided for @langSpanish.
  ///
  /// In en, this message translates to:
  /// **'Español'**
  String get langSpanish;

  /// No description provided for @splashInvalidKeyTitle.
  ///
  /// In en, this message translates to:
  /// **'Invalid API Key'**
  String get splashInvalidKeyTitle;

  /// No description provided for @splashInvalidKeyMessage.
  ///
  /// In en, this message translates to:
  /// **'The API key configured for this app is invalid or has been revoked.'**
  String get splashInvalidKeyMessage;

  /// No description provided for @splashInvalidKeyHint.
  ///
  /// In en, this message translates to:
  /// **'Contact the app owner to update the API key.'**
  String get splashInvalidKeyHint;

  /// No description provided for @splashNoSubscriptionTitle.
  ///
  /// In en, this message translates to:
  /// **'No Active Subscription'**
  String get splashNoSubscriptionTitle;

  /// No description provided for @splashNoSubscriptionMessage.
  ///
  /// In en, this message translates to:
  /// **'This account does not have an active POS subscription.'**
  String get splashNoSubscriptionMessage;

  /// No description provided for @splashNoSubscriptionLink.
  ///
  /// In en, this message translates to:
  /// **'Subscribe at xeboki.com/xe-pos →'**
  String get splashNoSubscriptionLink;

  /// No description provided for @splashNoSubscriptionHint.
  ///
  /// In en, this message translates to:
  /// **'The app will become available once a subscription is activated.'**
  String get splashNoSubscriptionHint;

  /// No description provided for @splashFreePlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Plan Upgrade Required'**
  String get splashFreePlanTitle;

  /// No description provided for @splashFreePlanMessage.
  ///
  /// In en, this message translates to:
  /// **'The Ordering App is not available on the free POS plan.'**
  String get splashFreePlanMessage;

  /// No description provided for @splashFreePlanLink.
  ///
  /// In en, this message translates to:
  /// **'Upgrade at xeboki.com/xe-pos →'**
  String get splashFreePlanLink;

  /// No description provided for @splashFreePlanHint.
  ///
  /// In en, this message translates to:
  /// **'Free plan includes in-store POS only. Online ordering requires a paid plan.'**
  String get splashFreePlanHint;

  /// No description provided for @splashFeatureNotInPlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Feature Not Included'**
  String get splashFeatureNotInPlanTitle;

  /// No description provided for @splashFeatureNotInPlanMessage.
  ///
  /// In en, this message translates to:
  /// **'Your current POS plan does not include the Ordering App.'**
  String get splashFeatureNotInPlanMessage;

  /// No description provided for @splashFeatureNotInPlanLink.
  ///
  /// In en, this message translates to:
  /// **'Upgrade at xeboki.com/xe-pos →'**
  String get splashFeatureNotInPlanLink;

  /// No description provided for @splashFeatureNotInPlanHint.
  ///
  /// In en, this message translates to:
  /// **'Visit xeboki.com/xe-pos to upgrade your plan.'**
  String get splashFeatureNotInPlanHint;

  /// No description provided for @splashNetworkErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'No Connection'**
  String get splashNetworkErrorTitle;

  /// No description provided for @splashNetworkErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Unable to verify your subscription. Please check your internet connection and try again.'**
  String get splashNetworkErrorMessage;

  /// No description provided for @splashNetworkErrorHint.
  ///
  /// In en, this message translates to:
  /// **'The app requires a connection to start.'**
  String get splashNetworkErrorHint;

  /// No description provided for @splashChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get splashChecking;

  /// No description provided for @splashPoweredBy.
  ///
  /// In en, this message translates to:
  /// **'Powered by'**
  String get splashPoweredBy;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'es', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
