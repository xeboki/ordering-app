import 'package:flutter/material.dart';
import 'package:xeboki_ordering/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xeboki_ordering/core/types.dart';
import 'package:xeboki_ordering/providers/auth_providers.dart';
import 'package:xeboki_ordering/providers/orders_providers.dart';
import 'package:xeboki_ordering/widgets/error_view.dart';
import 'package:intl/intl.dart';

class AppointmentsScreen extends ConsumerWidget {
  const AppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isLoggedIn = ref.watch(isLoggedInProvider);

    if (!isLoggedIn) {
      return _guestView(context, l10n);
    }

    final apptAsync = ref.watch(appointmentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.apptTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(appointmentsProvider.notifier).refresh(),
          ),
        ],
      ),
      body: apptAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          message: l10n.ordersFailed,
          onRetry: () => ref.read(appointmentsProvider.notifier).refresh(),
        ),
        data: (appointments) {
          if (appointments.isEmpty) return _emptyState(context, l10n);
          return RefreshIndicator(
            onRefresh: () => ref.read(appointmentsProvider.notifier).refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: appointments.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) =>
                  _AppointmentCard(appointment: appointments[i], l10n: l10n),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showBookSheet(context, ref, l10n),
        icon: const Icon(Icons.add),
        label: Text(l10n.apptBook),
      ),
    );
  }

  Widget _emptyState(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.calendar_today_outlined,
              size: 56, color: theme.colorScheme.outline),
          const SizedBox(height: 16),
          Text(l10n.apptEmpty, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            l10n.apptEmptyHint,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _guestView(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.apptTitle)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline,
                  size: 48, color: theme.colorScheme.outline),
              const SizedBox(height: 16),
              Text(l10n.apptSignInRequired,
                  style: theme.textTheme.titleMedium,
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showBookSheet(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _BookAppointmentSheet(
          onBooked: () =>
              ref.read(appointmentsProvider.notifier).refresh(),
          l10n: l10n),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final OrderingAppointment appointment;
  final AppLocalizations l10n;
  const _AppointmentCard(
      {required this.appointment, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFmt = DateFormat('EEE, MMM d · h:mm a');
    final (label, color) = switch (appointment.status) {
      'pending' => (l10n.statusPending, Colors.orange),
      'confirmed' => (l10n.statusConfirmed, Colors.blue),
      'completed' => (l10n.statusCompleted, theme.colorScheme.primary),
      'cancelled' => (l10n.statusCancelled, theme.colorScheme.error),
      _ => (appointment.status, theme.colorScheme.outline),
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    appointment.serviceName,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    label,
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: color, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today_outlined,
                    size: 14, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(
                  dateFmt.format(appointment.startTime.toLocal()),
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.timer_outlined,
                    size: 14, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(
                  '${appointment.durationMinutes} min',
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant),
                ),
                if (appointment.staffName != null) ...[
                  const SizedBox(width: 14),
                  Icon(Icons.person_outline,
                      size: 14, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    appointment.staffName!,
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BookAppointmentSheet extends ConsumerStatefulWidget {
  final VoidCallback onBooked;
  final AppLocalizations l10n;
  const _BookAppointmentSheet(
      {required this.onBooked, required this.l10n});

  @override
  ConsumerState<_BookAppointmentSheet> createState() =>
      _BookAppointmentSheetState();
}

class _BookAppointmentSheetState
    extends ConsumerState<_BookAppointmentSheet> {
  final _notesCtrl = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 10, minute: 0);
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final customerId = ref.read(authProvider)?.customer.id;
    if (customerId == null) return;

    setState(() { _loading = true; _error = null; });
    try {
      widget.onBooked();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _error = widget.l10n.apptBookingFailed);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final theme = Theme.of(context);
    final dateFmt = DateFormat('EEE, MMMM d, y');

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.apptBookTitle,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),

          if (_error != null) ...[
            Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            const SizedBox(height: 12),
          ],

          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today_outlined),
            title: Text(dateFmt.format(_selectedDate)),
            trailing: const Icon(Icons.chevron_right, size: 18),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 90)),
              );
              if (picked != null) setState(() => _selectedDate = picked);
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.access_time_outlined),
            title: Text(_selectedTime.format(context)),
            trailing: const Icon(Icons.chevron_right, size: 18),
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: _selectedTime,
              );
              if (picked != null) setState(() => _selectedTime = picked);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesCtrl,
            maxLines: 2,
            decoration: InputDecoration(hintText: l10n.apptNotesHint),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white))
                : Text(l10n.apptConfirm),
          ),
        ],
      ),
    );
  }
}
