import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:xeboki_ordering/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xeboki_ordering/core/config/app_config.dart';
import 'package:xeboki_ordering/core/config/app_theme.dart';
import 'package:xeboki_ordering/core/config/brand_config.dart';
import 'package:xeboki_ordering/core/services/fcm_service.dart';
import 'package:xeboki_ordering/core/services/firestore_service.dart';
import 'package:xeboki_ordering/core/services/stripe_service.dart';
import 'package:xeboki_ordering/core/types.dart';
import 'package:xeboki_ordering/providers/app_providers.dart';
import 'package:xeboki_ordering/providers/firebase_providers.dart';
import 'package:xeboki_ordering/router/app_router.dart';

/// True when running on Android or iOS.
bool get _isMobile =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

/// firebase_messaging is supported on mobile + web + macOS.
bool get _firebaseMessagingSupported =>
    kIsWeb ||
    defaultTargetPlatform == TargetPlatform.android ||
    defaultTargetPlatform == TargetPlatform.iOS ||
    defaultTargetPlatform == TargetPlatform.macOS;

/// flutter_stripe is supported on mobile + web.
bool get _stripeSupported =>
    kIsWeb ||
    defaultTargetPlatform == TargetPlatform.android ||
    defaultTargetPlatform == TargetPlatform.iOS;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Mobile-only: lock to portrait and configure system UI chrome.
  // These APIs are no-ops or unsupported on web/desktop.
  if (_isMobile) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    // Edge-to-edge on Android; transparent bars, content draws behind them
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
    ));
  }

  final brand = await BrandConfig.load();

  // Stripe SDK is not available on Windows/Linux.
  if (_stripeSupported) StripeService.init();

  // Pre-initialise Firebase Auth from the merchant's Pro Firebase config.
  // This is a background task — app boots normally while this completes.
  // The firebaseInitProvider watches it; auth falls back to REST until ready.
  // firebase_messaging has no Windows/Linux plugin — skip on those platforms.
  if (brand.features.firebaseAuth && _firebaseMessagingSupported) {
    final client = OrderingClient(apiKey: AppConfig.apiKey);
    client.getFirebaseConfig().then((config) async {
      await FirestoreService.instance.init(config);
      // FCM background handler requires a native isolate — mobile only.
      if (_isMobile) await FcmService.instance.init();
      client.close();
    }).catchError((_) {}); // non-fatal — REST auth still works
  }

  // Restore persisted locale
  final prefs = await SharedPreferences.getInstance();
  final savedLocale = prefs.getString('locale');
  final initialLocale = savedLocale != null ? Locale(savedLocale) : const Locale('en');

  runApp(
    ProviderScope(
      overrides: [
        localeProvider.overrideWith((_) => initialLocale),
      ],
      child: XebokiOrderingApp(brand: brand),
    ),
  );
}

class XebokiOrderingApp extends ConsumerWidget {
  final BrandConfig brand;
  const XebokiOrderingApp({super.key, required this.brand});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Activate FCM token registration whenever auth + Firebase are both ready.
    // Silently ignored if firebase_auth is off or user not logged in.
    ref.watch(fcmRegistrationProvider);

    final router = ref.watch(appRouterProvider);
    final isDark = ref.watch(isDarkModeProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: brand.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(
        colors: brand.colors,
        typo: brand.typography,
      ),
      darkTheme: brand.features.darkMode
          ? AppTheme.build(
              colors: brand.colors,
              typo: brand.typography,
              dark: true,
            )
          : null,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      routerConfig: router,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
