import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:xeboki_ordering/providers/delivery_providers.dart';

/// Shows the delivery fee line and a free-delivery progress bar.
///
/// Displays differently based on [DeliveryState]:
/// - [DeliveryIdle]       → nothing shown (postcode not entered yet)
/// - [DeliveryValidating] → spinner
/// - [DeliveryValid]      → fee amount (or "FREE" badge)
/// - [DeliveryOutOfRange] → error message
/// - [DeliveryInvalid]    → error message
class DeliveryFeeRow extends StatelessWidget {
  final DeliveryState deliveryState;
  final double cartSubtotal;
  final double freeThreshold;
  final NumberFormat fmt;

  const DeliveryFeeRow({
    super.key,
    required this.deliveryState,
    required this.cartSubtotal,
    required this.freeThreshold,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    switch (deliveryState) {
      case DeliveryIdle():
        return const SizedBox.shrink();

      case DeliveryValidating():
        return Row(
          children: [
            const SizedBox(
                width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
            const SizedBox(width: 10),
            Text('Checking delivery area…',
                style: theme.textTheme.bodySmall),
          ],
        );

      case DeliveryOutOfRange(:final distanceKm):
        return _ErrorRow(
          cs: cs,
          theme: theme,
          message:
              'Sorry, we don\'t deliver to this postcode (${distanceKm.toStringAsFixed(1)} km away).',
        );

      case DeliveryInvalid(:final message):
        return _ErrorRow(cs: cs, theme: theme, message: message);

      case DeliveryValid():
        // deliveryFee is already written to the cart — read from parent
        // We just show the progress bar + fee label here
        return _FeeWidget(
          cs: cs,
          theme: theme,
          fmt: fmt,
          cartSubtotal: cartSubtotal,
          freeThreshold: freeThreshold,
        );
    }
  }
}

class _FeeWidget extends StatelessWidget {
  final ColorScheme cs;
  final ThemeData theme;
  final NumberFormat fmt;
  final double cartSubtotal;
  final double freeThreshold;

  const _FeeWidget({
    required this.cs,
    required this.theme,
    required this.fmt,
    required this.cartSubtotal,
    required this.freeThreshold,
  });

  @override
  Widget build(BuildContext context) {
    final isFree = freeThreshold > 0 && cartSubtotal >= freeThreshold;
    final remaining = freeThreshold > 0 ? (freeThreshold - cartSubtotal).clamp(0.0, freeThreshold) : 0.0;
    final progress = freeThreshold > 0 ? (cartSubtotal / freeThreshold).clamp(0.0, 1.0) : 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (freeThreshold > 0 && !isFree) ...[
          Row(
            children: [
              const Icon(Icons.local_shipping_outlined, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Add ${fmt.format(remaining)} more for free delivery',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: cs.surfaceContainerHighest,
              color: cs.primary,
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (isFree)
          Row(
            children: [
              Icon(Icons.check_circle_outline, size: 16, color: cs.primary),
              const SizedBox(width: 6),
              Text(
                'Free delivery unlocked!',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: cs.primary, fontWeight: FontWeight.w600),
              ),
            ],
          ),
      ],
    );
  }
}

class _ErrorRow extends StatelessWidget {
  final ColorScheme cs;
  final ThemeData theme;
  final String message;

  const _ErrorRow(
      {required this.cs, required this.theme, required this.message});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.error_outline, size: 16, color: cs.error),
        const SizedBox(width: 6),
        Expanded(
          child: Text(message,
              style:
                  theme.textTheme.bodySmall?.copyWith(color: cs.error)),
        ),
      ],
    );
  }
}
