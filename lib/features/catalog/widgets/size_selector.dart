import 'package:flutter/material.dart';
import 'package:xeboki_ordering/core/types.dart';

/// Horizontal chip row for selecting a product size variant.
///
/// Only rendered when [sizes] is non-empty — callers should check
/// [OrderingProduct.sizes.isNotEmpty] before including this widget.
class SizeSelector extends StatelessWidget {
  const SizeSelector({
    super.key,
    required this.sizes,
    required this.selected,
    required this.onSelected,
    required this.currencySymbol,
  });

  final List<ProductSize> sizes;
  final SelectedSize? selected;
  final ValueChanged<SelectedSize> onSelected;
  final String currencySymbol;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Size',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: sizes.map((size) {
            final isSelected = selected?.sizeId == size.id;
            final priceLabel = _priceLabel(size);
            return _SizeChip(
              label: size.name,
              priceLabel: priceLabel,
              isSelected: isSelected,
              onTap: () => onSelected(
                SelectedSize(
                  sizeId: size.id,
                  sizeName: size.name,
                  priceAdjustment: size.priceAdjustment,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  String _priceLabel(ProductSize size) {
    if (size.priceAdjustment == 0) return '';
    final sign = size.priceAdjustment > 0 ? '+' : '';
    return '$sign$currencySymbol${size.priceAdjustment.toStringAsFixed(2)}';
  }
}

class _SizeChip extends StatelessWidget {
  const _SizeChip({
    required this.label,
    required this.priceLabel,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final String priceLabel;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : colorScheme.surface,
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outline,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
              ),
            ),
            if (priceLabel.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(
                priceLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isSelected
                      ? colorScheme.onPrimary.withValues(alpha: 0.8)
                      : colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
