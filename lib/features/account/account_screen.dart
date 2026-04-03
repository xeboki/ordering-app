import 'package:flutter/material.dart';
import 'package:xeboki_ordering/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xeboki_ordering/core/config/brand_config.dart';
import 'package:xeboki_ordering/features/loyalty/loyalty_stamp_card.dart';
import 'package:xeboki_ordering/providers/app_providers.dart';
import 'package:xeboki_ordering/providers/auth_providers.dart';
import 'package:intl/intl.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final authed = ref.watch(authProvider);
    final brand = ref.watch(brandProvider);
    final theme = Theme.of(context);

    if (authed == null) {
      return _guestView(context, ref, brand, l10n, theme);
    }

    final customer = authed.customer;
    final currency = BrandConfig.instance.store.currencySymbol;
    final fmt = NumberFormat.currency(symbol: currency, decimalDigits: 2);

    // Loyalty tier
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          // ── Profile header ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primary,
                    Color.lerp(theme.colorScheme.primary, Colors.black, 0.2)!,
                  ],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Spacer(),
                          IconButton(
                            onPressed: () =>
                                ref.read(authProvider.notifier).refresh(),
                            icon: const Icon(Icons.refresh,
                                color: Colors.white, size: 20),
                            tooltip: 'Refresh',
                          ),
                        ],
                      ),
                      CircleAvatar(
                        radius: 36,
                        backgroundColor:
                            Colors.white.withValues(alpha: 0.22),
                        child: Text(
                          customer.name.isNotEmpty
                              ? customer.name[0].toUpperCase()
                              : '?',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        customer.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (customer.email != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          customer.email!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: ListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                // ── Loyalty stamp card ────────────────────────────────────
                if (brand.features.loyalty) ...[
                  LoyaltyStampCard(customer: customer),
                  const SizedBox(height: 12),
                ],

                // ── Offers shortcut ───────────────────────────────────────
                if (brand.features.discountCodes) ...[
                  _MenuItem(
                    icon: Icons.local_offer_outlined,
                    label: 'Offers & Deals',
                    trailing: const Icon(Icons.chevron_right, size: 18),
                    onTap: () => context.go('/offers'),
                  ),
                ],

                // ── Store credit ──────────────────────────────────────────
                if (customer.storeCredit > 0) ...[
                  _StatCard(
                    icon: Icons.account_balance_wallet_outlined,
                    label: l10n.accountStoreCredit,
                    value: fmt.format(customer.storeCredit),
                    color: const Color(0xFF27AE60),
                    theme: theme,
                  ),
                  const SizedBox(height: 12),
                ],

                // ── Quick stats ───────────────────────────────────────────
                const SizedBox(height: 8),
                _SectionHeader(title: l10n.accountShopping, theme: theme),
                _MenuItem(
                  icon: Icons.receipt_long_outlined,
                  label: l10n.accountMyOrders,
                  trailing: const Icon(Icons.chevron_right, size: 18),
                  onTap: () => context.go('/orders'),
                ),

                // ── Preferences ───────────────────────────────────────────
                const SizedBox(height: 16),
                _SectionHeader(
                    title: l10n.accountPreferences, theme: theme),
                if (brand.features.darkMode)
                  Consumer(builder: (_, ref, __) {
                    final isDark = ref.watch(isDarkModeProvider);
                    return _ToggleTile(
                      icon: isDark
                          ? Icons.dark_mode_outlined
                          : Icons.light_mode_outlined,
                      label: l10n.accountDarkMode,
                      value: isDark,
                      onChanged: (v) =>
                          ref.read(isDarkModeProvider.notifier).state = v,
                    );
                  }),
                _MenuItem(
                  icon: Icons.language_outlined,
                  label: l10n.accountLanguage,
                  trailing: Consumer(builder: (_, ref, __) {
                    final locale = ref.watch(localeProvider);
                    return Text(
                      _localeName(locale.languageCode, l10n),
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant),
                    );
                  }),
                  onTap: () =>
                      _showLanguagePicker(context, ref, l10n),
                ),

                // ── Support ───────────────────────────────────────────────
                if (brand.store.supportEmail.isNotEmpty ||
                    brand.store.supportPhone.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _SectionHeader(
                      title: l10n.accountSupport, theme: theme),
                  if (brand.store.supportEmail.isNotEmpty)
                    _MenuItem(
                      icon: Icons.email_outlined,
                      label: brand.store.supportEmail,
                      onTap: () {},
                    ),
                  if (brand.store.supportPhone.isNotEmpty)
                    _MenuItem(
                      icon: Icons.phone_outlined,
                      label: brand.store.supportPhone,
                      onTap: () {},
                    ),
                ],

                // ── About ────────────────────────────────────────────────
                if (brand.tagline.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _SectionHeader(title: l10n.accountAbout, theme: theme),
                  _MenuItem(
                    icon: Icons.storefront_outlined,
                    label: brand.appName,
                    subtitle: brand.tagline,
                    onTap: () {},
                  ),
                ],

                // ── Sign out ──────────────────────────────────────────────
                const SizedBox(height: 28),
                OutlinedButton.icon(
                  onPressed: () =>
                      _confirmSignOut(context, ref, l10n),
                  icon: const Icon(Icons.logout, size: 18),
                  label: Text(l10n.authSignOut),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                    side: BorderSide(color: theme.colorScheme.error),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _guestView(BuildContext context, WidgetRef ref, BrandConfig brand,
      AppLocalizations l10n, ThemeData theme) {
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        title: Text(l10n.accountTitle,
            style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 16),
          Center(
            child: Column(
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.person_outline,
                      size: 44, color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 16),
                Text(l10n.accountSignInRequired,
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(
                  l10n.accountSignInBenefit,
                  style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          FilledButton(
            onPressed: () async {
              await ref.read(guestModeProvider.notifier).disable();
              if (context.mounted) context.go('/login');
            },
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(l10n.commonSignIn,
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () async {
              await ref.read(guestModeProvider.notifier).disable();
              if (context.mounted) context.go('/register');
            },
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(l10n.authCreateAccount),
          ),
          const SizedBox(height: 32),
          _SectionHeader(title: l10n.accountPreferences, theme: theme),
          if (brand.features.darkMode)
            Consumer(builder: (_, ref, __) {
              final isDark = ref.watch(isDarkModeProvider);
              return _ToggleTile(
                icon: isDark
                    ? Icons.dark_mode_outlined
                    : Icons.light_mode_outlined,
                label: l10n.accountDarkMode,
                value: isDark,
                onChanged: (v) =>
                    ref.read(isDarkModeProvider.notifier).state = v,
              );
            }),
          _MenuItem(
            icon: Icons.language_outlined,
            label: l10n.accountLanguage,
            onTap: () => _showLanguagePicker(context, ref, l10n),
          ),
        ],
      ),
    );
  }

  void _showLanguagePicker(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    final locales = [
      ('en', l10n.langEnglish),
      ('ar', l10n.langArabic),
      ('fr', l10n.langFrench),
      ('es', l10n.langSpanish),
    ];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ...locales.map((pair) {
                final (code, name) = pair;
                final current = ref.read(localeProvider).languageCode;
                return ListTile(
                  title: Text(name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  trailing: current == code
                      ? Icon(Icons.check,
                          color: Theme.of(context).colorScheme.primary)
                      : null,
                  onTap: () async {
                    ref.read(localeProvider.notifier).state = Locale(code);
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('locale', code);
                    if (context.mounted) Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  String _localeName(String code, AppLocalizations l10n) => switch (code) {
        'ar' => l10n.langArabic,
        'fr' => l10n.langFrench,
        'es' => l10n.langSpanish,
        _ => l10n.langEnglish,
      };

  void _confirmSignOut(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.accountSignOutTitle),
        content: Text(l10n.accountSignOutMessage),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.commonCancel)),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            child: Text(l10n.authSignOut),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final ThemeData theme;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label,
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant)),
          ),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final ThemeData theme;
  const _SectionHeader({required this.title, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    this.subtitle,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: trailing ?? const Icon(Icons.chevron_right, size: 18),
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      onTap: onTap,
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: Icon(icon),
      title: Text(label),
      value: value,
      onChanged: onChanged,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}
