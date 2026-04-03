import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:xeboki_ordering/core/types.dart';

/// OpenStreetMap widget showing the driver's live position and the
/// delivery destination.
///
/// Only rendered when [tracking.hasDriverLocation] is true.
/// Falls back to a status-only card when no coordinates are available.
class DeliveryMap extends StatefulWidget {
  const DeliveryMap({super.key, required this.tracking});

  final NashDeliveryTracking tracking;

  @override
  State<DeliveryMap> createState() => _DeliveryMapState();
}

class _DeliveryMapState extends State<DeliveryMap> {
  late final MapController _mapCtrl;

  @override
  void initState() {
    super.initState();
    _mapCtrl = MapController();
  }

  @override
  void didUpdateWidget(DeliveryMap old) {
    super.didUpdateWidget(old);
    // Pan map to driver position on each update
    if (widget.tracking.hasDriverLocation) {
      final pos = LatLng(
          widget.tracking.driverLat!, widget.tracking.driverLng!);
      _mapCtrl.move(pos, _mapCtrl.camera.zoom);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tracking = widget.tracking;

    if (!tracking.hasDriverLocation) {
      return _StatusOnlyCard(tracking: tracking, theme: theme);
    }

    final driverPos =
        LatLng(tracking.driverLat!, tracking.driverLng!);
    final destPos = tracking.hasDestination
        ? LatLng(tracking.destinationLat!, tracking.destinationLng!)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── ETA / driver banner ──────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(Icons.delivery_dining_outlined,
                  color: theme.colorScheme.onPrimaryContainer, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tracking.driverName != null
                          ? '${tracking.driverName} is on the way'
                          : 'Your order is on the way',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    if (tracking.driverVehicle != null)
                      Text(
                        tracking.driverVehicle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer
                                .withValues(alpha: 0.75)),
                      ),
                  ],
                ),
              ),
              if (tracking.etaMinutes != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '~${tracking.etaMinutes} min',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // ── Map ──────────────────────────────────────────────────────────
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 260,
            child: FlutterMap(
              mapController: _mapCtrl,
              options: MapOptions(
                initialCenter: driverPos,
                initialZoom: 15,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.pinchZoom |
                      InteractiveFlag.drag |
                      InteractiveFlag.doubleTapZoom,
                ),
              ),
              children: [
                // OSM tile layer — no API key needed
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.xeboki.ordering',
                  maxZoom: 19,
                ),

                // Route line (driver → destination)
                if (destPos != null)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: [driverPos, destPos],
                        color: theme.colorScheme.primary.withValues(alpha: 0.6),
                        strokeWidth: 3,
                        pattern: StrokePattern.dashed(
                            segments: [8.0, 4.0]),
                      ),
                    ],
                  ),

                // Markers
                MarkerLayer(
                  markers: [
                    // Driver marker
                    Marker(
                      point: driverPos,
                      width: 44,
                      height: 44,
                      child: _DriverMarker(theme: theme),
                    ),
                    // Destination pin
                    if (destPos != null)
                      Marker(
                        point: destPos,
                        width: 36,
                        height: 44,
                        alignment: Alignment.topCenter,
                        child: Icon(
                          Icons.location_on,
                          size: 36,
                          color: theme.colorScheme.error,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // OSM attribution (required by OSM tile usage policy)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '© OpenStreetMap contributors',
            style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}

// ── Driver marker widget ──────────────────────────────────────────────────────

class _DriverMarker extends StatelessWidget {
  const _DriverMarker({required this.theme});
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.colorScheme.primary,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Icon(
        Icons.delivery_dining,
        color: theme.colorScheme.onPrimary,
        size: 24,
      ),
    );
  }
}

// ── Status-only fallback (no GPS yet) ────────────────────────────────────────

class _StatusOnlyCard extends StatelessWidget {
  const _StatusOnlyCard({required this.tracking, required this.theme});
  final NashDeliveryTracking tracking;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.delivery_dining_outlined,
              color: theme.colorScheme.primary, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _statusLabel(tracking.status),
                  style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700),
                ),
                if (tracking.etaMinutes != null)
                  Text(
                    'Estimated: ~${tracking.etaMinutes} min',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(String s) => switch (s.toLowerCase()) {
        'created' => 'Delivery confirmed',
        'driver_assigned' => 'Driver assigned',
        'driver_at_pickup' => 'Driver at store',
        'pickup' || 'picked_up' => 'Order picked up',
        'dropoff' || 'en_route' => 'On the way to you',
        'delivered' => 'Delivered!',
        'cancelled' => 'Delivery cancelled',
        _ => 'Driver on the way',
      };
}
