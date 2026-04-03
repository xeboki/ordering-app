import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:xeboki_ordering/core/config/brand_config.dart';
import 'package:xeboki_ordering/core/types.dart';
import 'package:xeboki_ordering/providers/offers_providers.dart';

/// Visual loyalty stamp card + recent transaction history.
///
/// Shows a grid of stamps (1 stamp = [_stampUnit] points), the customer's
/// current points balance, and the last few transactions.
class LoyaltyStampCard extends ConsumerWidget {
  const LoyaltyStampCard({
    super.key,
    required this.customer,
  });

  final OrderingCustomer customer;

  /// How many points represent one "stamp" on the card.
  static const int _stampUnit = 10;
  /// Total stamps per card before a reward is unlocked.
  static const int _stampsPerCard = 10;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final configAsync = ref.watch(loyaltyConfigProvider);
    final currency = BrandConfig.instance.store.currencySymbol;

    return configAsync.when(
      loading: () => const _StampCardShimmer(),
      error: (_, __) => const SizedBox.shrink(),
      data: (config) {
        final pts = customer.loyaltyPoints;
        final stampsEarned = (pts ~/ _stampUnit).clamp(0, _stampsPerCard);
        final stampsOnCard = stampsEarned % _stampsPerCard;
        final cardsCompleted = stampsEarned ~/ _stampsPerCard;
        final rewardValue = config.pointsToCurrency(config.redemptionThreshold);
        final canRedeem = pts >= config.redemptionThreshold;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Card ──────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primary,
                    Color.lerp(
                        theme.colorScheme.primary, Colors.black, 0.25)!,
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    children: [
                      const Icon(Icons.stars_rounded,
                          color: Colors.white, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Loyalty Card',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      // Points balance pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$pts pts',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Stamp grid
                  _StampGrid(
                    stampsOnCard: stampsOnCard,
                    totalStamps: _stampsPerCard,
                  ),

                  const SizedBox(height: 16),

                  // Progress caption
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          stampsOnCard == 0 && cardsCompleted > 0
                              ? '🎉 Card complete! Start collecting again.'
                              : '${_stampsPerCard - stampsOnCard} more stamp${_stampsPerCard - stampsOnCard == 1 ? '' : 's'} to unlock a reward',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ),
                      if (cardsCompleted > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFB800).withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: const Color(0xFFFFB800)
                                    .withValues(alpha: 0.5)),
                          ),
                          child: Text(
                            '×$cardsCompleted completed',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: const Color(0xFFFFD700),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Redeem banner ─────────────────────────────────────────────
            if (canRedeem) ...[
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.redeem_outlined,
                        color: Colors.green, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Reward available!',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Colors.green[700],
                            ),
                          ),
                          Text(
                            'Redeem $currency${rewardValue.toStringAsFixed(2)} off your next order at checkout.',
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.green[700]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ── Recent transactions ───────────────────────────────────────
            const SizedBox(height: 20),
            _TransactionHistory(customerId: customer.id, theme: theme),
          ],
        );
      },
    );
  }
}

// ── Stamp grid ────────────────────────────────────────────────────────────────

class _StampGrid extends StatelessWidget {
  const _StampGrid({
    required this.stampsOnCard,
    required this.totalStamps,
  });

  final int stampsOnCard;
  final int totalStamps;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(totalStamps, (i) {
        final filled = i < stampsOnCard;
        return AnimatedContainer(
          duration: Duration(milliseconds: 150 + i * 30),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled
                ? Colors.white
                : Colors.white.withValues(alpha: 0.15),
            border: Border.all(
              color: Colors.white.withValues(alpha: filled ? 1 : 0.3),
              width: filled ? 0 : 1.5,
            ),
          ),
          child: filled
              ? const Icon(Icons.star_rounded,
                  size: 18, color: Color(0xFFFFB800))
              : null,
        );
      }),
    );
  }
}

// ── Transaction history ───────────────────────────────────────────────────────

class _TransactionHistory extends ConsumerWidget {
  const _TransactionHistory({
    required this.customerId,
    required this.theme,
  });

  final String customerId;
  final ThemeData theme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txAsync = ref.watch(loyaltyTransactionsProvider);

    return txAsync.when(
      loading: () => const Center(
          child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator())),
      error: (_, __) => const SizedBox.shrink(),
      data: (txs) {
        if (txs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'No transactions yet. Start earning stamps!',
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'RECENT ACTIVITY',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            ...txs.take(8).map((tx) => _TxTile(tx: tx, theme: theme)),
          ],
        );
      },
    );
  }
}

class _TxTile extends StatelessWidget {
  const _TxTile({required this.tx, required this.theme});
  final LoyaltyTransaction tx;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final isEarn = tx.isEarn;
    final color = isEarn ? Colors.green : theme.colorScheme.secondary;
    final sign = isEarn ? '+' : '';
    final dateFmt = DateFormat('d MMM');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isEarn ? Icons.add_circle_outline : Icons.remove_circle_outline,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.description ?? (isEarn ? 'Points earned' : 'Points redeemed'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  dateFmt.format(tx.createdAt.toLocal()),
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Text(
            '$sign${tx.points} pts',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Loading shimmer ───────────────────────────────────────────────────────────

class _StampCardShimmer extends StatelessWidget {
  const _StampCardShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}
