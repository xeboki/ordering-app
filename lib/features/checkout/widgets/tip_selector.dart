import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Tip selector shown at checkout when `brand.features.tipping == true`.
///
/// Shows preset percentage buttons, a "No Tip" button, and a custom amount
/// text field. Calls [onTipChanged] with the absolute tip amount.
class TipSelector extends StatefulWidget {
  final double orderTotal;
  final double selectedTip;
  final List<int> presets;
  final ValueChanged<double> onTipChanged;

  const TipSelector({
    super.key,
    required this.orderTotal,
    required this.selectedTip,
    required this.presets,
    required this.onTipChanged,
  });

  @override
  State<TipSelector> createState() => _TipSelectorState();
}

class _TipSelectorState extends State<TipSelector> {
  int? _selectedPct;   // null = custom
  bool _showCustom = false;
  final _customCtrl = TextEditingController();

  @override
  void dispose() {
    _customCtrl.dispose();
    super.dispose();
  }

  void _selectPreset(int pct) {
    setState(() {
      _selectedPct = pct;
      _showCustom = false;
    });
    _customCtrl.clear();
    widget.onTipChanged(_tipAmount(pct));
  }

  void _selectNoTip() {
    setState(() {
      _selectedPct = 0;
      _showCustom = false;
    });
    _customCtrl.clear();
    widget.onTipChanged(0);
  }

  void _selectCustom() {
    setState(() {
      _selectedPct = null;
      _showCustom = true;
    });
  }

  double _tipAmount(int pct) =>
      double.parse((widget.orderTotal * pct / 100).toStringAsFixed(2));

  bool _isActive(int pct) => _selectedPct == pct && !_showCustom;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // Preset buttons
            for (final pct in widget.presets)
              _TipChip(
                label: '$pct%',
                sublabel: '\$${_tipAmount(pct).toStringAsFixed(2)}',
                selected: _isActive(pct),
                onTap: () => _selectPreset(pct),
              ),
            // No Tip
            _TipChip(
              label: 'No Tip',
              selected: _selectedPct == 0 && !_showCustom,
              onTap: _selectNoTip,
            ),
            // Custom
            _TipChip(
              label: 'Custom',
              selected: _showCustom,
              onTap: _selectCustom,
            ),
          ],
        ),
        if (_showCustom) ...[
          const SizedBox(height: 10),
          TextField(
            controller: _customCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.attach_money, size: 18, color: cs.primary),
              labelText: 'Custom tip amount',
              isDense: true,
            ),
            onChanged: (v) {
              final amount = double.tryParse(v) ?? 0;
              widget.onTipChanged(amount);
            },
          ),
        ],
      ],
    );
  }
}

class _TipChip extends StatelessWidget {
  final String label;
  final String? sublabel;
  final bool selected;
  final VoidCallback onTap;

  const _TipChip({
    required this.label,
    this.sublabel,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? cs.primary : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? cs.primary : cs.outlineVariant,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: selected ? cs.onPrimary : cs.onSurface,
                fontSize: 13,
              ),
            ),
            if (sublabel != null)
              Text(
                sublabel!,
                style: TextStyle(
                  fontSize: 11,
                  color: selected
                      ? cs.onPrimary.withValues(alpha: 0.8)
                      : cs.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
