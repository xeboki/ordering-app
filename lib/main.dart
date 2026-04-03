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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AppConfig.assertConfigured();

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

  final brand = await BrandConfig.load();

  // Initialise Stripe if configured for this white-label build
  StripeService.init();

  // Pre-initialise Firebase Auth from the merchant's Pro Firebase config.
  // This is a background task — app boots normally while this completes.
  // The firebaseInitProvider watches it; auth falls back to REST until ready.
  if (brand.features.firebaseAuth) {
    final client = OrderingClient(apiKey: AppConfig.apiKey);
    client.getFirebaseConfig().then((config) async {
      await FirestoreService.instance.init(config);
      // Init FCM after Firebase is ready — background handler must be
      // registered before any other FCM calls.
      await FcmService.instance.init();
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
