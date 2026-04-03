import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:xeboki_ordering/core/types.dart';
import 'package:xeboki_ordering/l10n/app_localizations.dart';
import 'package:xeboki_ordering/providers/app_providers.dart';
import 'package:xeboki_ordering/providers/auth_providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  KeyValidationStatus? _validationResult;
  bool _retrying = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _fade = CurvedAnimation(
        parent: _ctrl, curve: const Interval(0, 0.6, curve: Curves.easeOut));
    _scale = Tween(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
          parent: _ctrl,
          curve: const Interval(0, 0.7, curve: Curves.easeOutBack)),
    );
    _ctrl.forward();
    _runValidation();
  }

  Future<void> _runValidation() async {
    setState(() {
      _validationResult = null;
      _retrying = false;
    });

    await ref.read(apiValidationProvider.notifier).validate();

    if (!mounted) return;

    final result = ref.read(apiValidationProvider);
    result.when(
      data: (status) {
        setState(() => _validationResult = status);
        if (status == KeyValidationStatus.valid) {
          _navigateNext();
        }
      },
      loading: () {},
      error: (_, __) {
        setState(() => _validationResult = KeyValidationStatus.networkError);
      },
    );
  }

  void _navigateNext() {
    final brand = ref.read(brandProvider);
    final isLoggedIn = ref.read(isLoggedInProvider);
    if (brand.features.customerAuth && !isLoggedIn) {
      context.go('/login');
    } else {
      context.go('/');
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brand = ref.watch(brandProvider);
    final splash = brand.splash;
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    if (_validationResult != null &&
        _validationResult != KeyValidationStatus.valid) {
      return _BlockedScreen(
        status: _validationResult!,
        primaryColor: primary,
        appName: brand.appName,
        onRetry: () async {
          setState(() => _retrying = true);
          await _runValidation();
          if (mounted) setState(() => _retrying = false);
        },
        retrying: _retrying,
      );
    }

    return Scaffold(
      backgroundColor: splash.backgroundColor,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  splash.logoAsset,
                  width: 120,
                  height: 120,
                  errorBuilder: (_, __, ___) => Text(
                    brand.appName,
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (splash.showTagline && brand.tagline.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    brand.tagline,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white70,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 40),
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Blocking error screen ─────────────────────────────────────────────────────

class _BlockedScreen extends StatelessWidget {
  final KeyValidationStatus status;
  final Color primaryColor;
  final String appName;
  final VoidCallback onRetry;
  final bool retrying;

  const _BlockedScreen({
    required this.status,
    required this.primaryColor,
    required this.appName,
    required this.onRetry,
    required this.retrying,
  });

  @override
  Widget build(BuildContext context) {
    final l10n  = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final info  = _info(l10n, status);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.07),
                      blurRadius: 40,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon with ring
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: info.iconColor.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: info.iconColor.withValues(alpha: 0.18),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(info.icon, size: 38, color: info.iconColor),
                    ),
                    const SizedBox(height: 24),

                    // Title
                    Text(
                      info.title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                        letterSpacing: -0.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),

                    // Message
                    Text(
                      info.message,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    // Tappable link (e.g. "Subscribe at xeboki.com/xe-pos →")
                    if (info.linkLabel != null) ...[
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () => launchUrl(
                          Uri.parse('https://xeboki.com/xe-pos'),
                          mode: LaunchMode.externalApplication,
                        ),
                        child: Text(
                          info.linkLabel!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: primaryColor,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                            decorationColor: primaryColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],

                    // Hint chip
                    if (info.hint.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          info.hint,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],

                    const SizedBox(height: 28),

                    // Retry button
                    if (info.canRetry)
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: retrying ? null : onRetry,
                          icon: retrying
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.refresh, size: 17),
                          label: Text(retrying
                              ? l10n.splashChecking
                              : l10n.commonRetry),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            textStyle: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 28),

                    Divider(
                      color: theme.colorScheme.outlineVariant
                          .withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),

                    // Powered-by footer — "Xeboki" links to xeboki.com/xe-pos
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.55),
                        ),
                        children: [
                          TextSpan(text: '${l10n.splashPoweredBy} '),
                          TextSpan(
                            text: 'Xeboki',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: primaryColor,
                              decoration: TextDecoration.underline,
                              decorationColor: primaryColor,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () => launchUrl(
                                    Uri.parse('https://xeboki.com/xe-pos'),
                                    mode: LaunchMode.externalApplication,
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  _BlockedInfo _info(AppLocalizations l10n, KeyValidationStatus s) {
    switch (s) {
      case KeyValidationStatus.invalidKey:
        return _BlockedInfo(
          icon: Icons.vpn_key_off_outlined,
          iconColor: const Color(0xFFE53E3E),
          title: l10n.splashInvalidKeyTitle,
          message: l10n.splashInvalidKeyMessage,
          hint: l10n.splashInvalidKeyHint,
          canRetry: false,
        );

      case KeyValidationStatus.noSubscription:
        return _BlockedInfo(
          icon: Icons.subscriptions_outlined,
          iconColor: const Color(0xFFED8936),
          title: l10n.splashNoSubscriptionTitle,
          message: l10n.splashNoSubscriptionMessage,
          linkLabel: l10n.splashNoSubscriptionLink,
          hint: l10n.splashNoSubscriptionHint,
          canRetry: true,
        );

      case KeyValidationStatus.freePlanBlocked:
        return _BlockedInfo(
          icon: Icons.lock_outline,
          iconColor: const Color(0xFFED8936),
          title: l10n.splashFreePlanTitle,
          message: l10n.splashFreePlanMessage,
          linkLabel: l10n.splashFreePlanLink,
          hint: l10n.splashFreePlanHint,
          canRetry: false,
        );

      case KeyValidationStatus.featureNotInPlan:
        return _BlockedInfo(
          icon: Icons.lock_outline,
          iconColor: const Color(0xFFED8936),
          title: l10n.splashFeatureNotInPlanTitle,
          message: l10n.splashFeatureNotInPlanMessage,
          linkLabel: l10n.splashFeatureNotInPlanLink,
          hint: l10n.splashFeatureNotInPlanHint,
          canRetry: false,
        );

      case KeyValidationStatus.networkError:
        return _BlockedInfo(
          icon: Icons.wifi_off_outlined,
          iconColor: const Color(0xFF718096),
          title: l10n.splashNetworkErrorTitle,
          message: l10n.splashNetworkErrorMessage,
          hint: l10n.splashNetworkErrorHint,
          canRetry: true,
        );

      case KeyValidationStatus.valid:
        return _BlockedInfo(
          icon: Icons.check_circle_outline,
          iconColor: const Color(0xFF38A169),
          title: '',
          message: '',
          hint: '',
          canRetry: false,
        );
    }
  }
}

class _BlockedInfo {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final String? linkLabel;
  final String hint;
  final bool canRetry;

  const _BlockedInfo({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    this.linkLabel,
    required this.hint,
    required this.canRetry,
  });
}
