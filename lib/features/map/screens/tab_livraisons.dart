import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:driver_app/l10n/app_localizations.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/services/sound_service.dart';
import '../providers/location_provider.dart';
import '../../orders/providers/orders_provider.dart';
import '../../../core/models/order_model.dart';

const _blue = Color(0xFF2563EB);
const _restLat = DriverFirebaseService.restaurantLat;
const _restLng = DriverFirebaseService.restaurantLng;

class LivraisonsTab extends ConsumerStatefulWidget {
  final MapController mapController;
  const LivraisonsTab({super.key, required this.mapController});

  @override
  ConsumerState<LivraisonsTab> createState() => _LivraisonsTabState();
}

class _LivraisonsTabState extends ConsumerState<LivraisonsTab> {
  Timer? _alertTimer;
  int _prevAvailableCount = 0;

  void _startAlert() {
    _alertTimer?.cancel();
    SoundService.playNotification();
    _alertTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      SoundService.playNotification();
    });
  }

  void _stopAlert() {
    _alertTimer?.cancel();
    _alertTimer = null;
  }

  @override
  void dispose() {
    _alertTimer?.cancel();
    super.dispose();
  }

  Future<void> _navigateTo(String address) async {
    final encoded = Uri.encodeComponent(address);
    final uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$encoded&travelmode=driving');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final positionAsync = ref.watch(positionStreamProvider);
    final activeOrders = ref.watch(activeOrdersListProvider).valueOrNull ?? [];
    final availableOrders = ref.watch(availableOrdersProvider).valueOrNull ?? [];
    final isOnline = ref.watch(isOnlineProvider);

    // Repeating alert when new available orders arrive
    ref.listen(availableOrdersProvider, (_, next) {
      final count = next.valueOrNull?.length ?? 0;
      if (count > _prevAvailableCount && isOnline) {
        _startAlert();
      } else if (count == 0) {
        _stopAlert();
      }
      _prevAvailableCount = count;
    });
    final statsAsync = ref.watch(dailyStatsProvider);
    final firebase = ref.read(firebaseServiceProvider);
    final hasActive = activeOrders.isNotEmpty;

    void toggleOnline() async {
      if (hasActive && isOnline) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Entrega tus pedidos antes de desconectarte'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
      SoundService.playClick();
      final newState = !isOnline;
      ref.read(isOnlineProvider.notifier).toggle();
      await firebase.updateDriverOnlineStatus(newState);
    }

    return Stack(
      children: [
        // ── Map ───────────────────────────────────────────────────
        positionAsync.when(
          data: (position) {
            final driverPt = LatLng(position.latitude, position.longitude);
            return FlutterMap(
              mapController: widget.mapController,
              options: MapOptions(initialCenter: driverPt, initialZoom: 15),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.repartidor.driver_app',
                ),
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: const LatLng(_restLat, _restLng),
                      radius: 500,
                      useRadiusInMeter: true,
                      color: Colors.blue.withAlpha(18),
                      borderColor: Colors.blue.withAlpha(120),
                      borderStrokeWidth: 1.5,
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: driverPt,
                      width: 40, height: 40,
                      child: const Icon(Icons.navigation, color: _blue, size: 36),
                    ),
                    Marker(
                      point: const LatLng(_restLat, _restLng),
                      width: 36, height: 36,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: _blue, width: 2),
                          boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black26)],
                        ),
                        child: const Icon(Icons.storefront, color: _blue, size: 20),
                      ),
                    ),
                    ...activeOrders.where((o) => o.deliveryLat != null).map((o) => Marker(
                          point: LatLng(o.deliveryLat!, o.deliveryLng!),
                          width: 20, height: 20,
                          child: Container(
                            decoration: BoxDecoration(
                              color: _blue,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black38)],
                            ),
                          ),
                        )),
                  ],
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
        ),

        // ── Floating squares for available orders ─────────────────
        if (isOnline && availableOrders.isNotEmpty)
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            bottom: hasActive ? 0 : (isOnline ? 160 : 120),
            child: Center(
              child: _FloatingOrderSquares(
                orders: availableOrders,
                onAccept: (id) async {
                  await firebase.acceptOrder(id);
                  if ((ref.read(availableOrdersProvider).valueOrNull ?? []).isEmpty) {
                    _stopAlert();
                  }
                },
              ),
            ),
          ),

        // ── Stats badge (top-center) ──────────────────────────────
        Positioned(
          top: 0, left: 0, right: 0,
          child: SafeArea(
            child: Center(
              child: statsAsync.maybeWhen(
                data: (stats) => _StatsBadge(
                  pedidos: stats.pedidos,
                  availableCount: availableOrders.length,
                ),
                orElse: () => const SizedBox.shrink(),
              ),
            ),
          ),
        ),

        // ── Settings (top-right) ──────────────────────────────────
        Positioned(
          top: 0, right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () => context.push('/settings'),
                ),
              ),
            ),
          ),
        ),

        // ── Recenter button ───────────────────────────────────────
        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          bottom: hasActive ? 260 : (isOnline ? 160 : 110),
          right: 12,
          child: FloatingActionButton.small(
            heroTag: 'recenter',
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            onPressed: () {
              final pos = ref.read(positionStreamProvider).valueOrNull;
              if (pos != null) widget.mapController.move(LatLng(pos.latitude, pos.longitude), 15);
            },
            child: const Icon(Icons.my_location),
          ),
        ),

        // ── Status pill (top-left) ────────────────────────────────
        Positioned(
          top: 0, left: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: _OnlineStatusPill(isOnline: isOnline),
            ),
          ),
        ),

        // ── OFFLINE: floating blue power button ───────────────────
        AnimatedPositioned(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          bottom: isOnline ? -140 : 36,
          left: 0, right: 0,
          child: Center(child: _OfflinePowerButton(onTap: toggleOnline)),
        ),

        // ── ONLINE: panel slides up ───────────────────────────────
        AnimatedPositioned(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          bottom: isOnline ? 0 : -320,
          left: 0, right: 0,
          child: hasActive
              ? _MultiOrderPanel(
                  orders: activeOrders,
                  firebase: firebase,
                  onNavigate: _navigateTo,
                )
              : _OnlineIdlePanel(onToggle: toggleOnline),
        ),
      ],
    );
  }
}

// ── Offline floating button ───────────────────────────────────────────────────

class _OfflinePowerButton extends StatefulWidget {
  final VoidCallback onTap;
  const _OfflinePowerButton({required this.onTap});

  @override
  State<_OfflinePowerButton> createState() => _OfflinePowerButtonState();
}

class _OfflinePowerButtonState extends State<_OfflinePowerButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween<double>(begin: 1.0, end: 0.86)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _ctrl.forward().then((_) => _ctrl.reverse());
        widget.onTap();
      },
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _blue,
            boxShadow: [
              BoxShadow(blurRadius: 24, color: _blue.withAlpha(140), spreadRadius: 4),
              const BoxShadow(blurRadius: 8, color: Colors.black26),
            ],
          ),
          child: const Icon(Icons.power_settings_new_rounded, color: Colors.white, size: 36),
        ),
      ),
    );
  }
}

// ── Online idle panel (no active orders) ─────────────────────────────────────

class _OnlineIdlePanel extends StatefulWidget {
  final VoidCallback onToggle;
  const _OnlineIdlePanel({required this.onToggle});

  @override
  State<_OnlineIdlePanel> createState() => _OnlineIdlePanelState();
}

class _OnlineIdlePanelState extends State<_OnlineIdlePanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween<double>(begin: 1.0, end: 0.86)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: const [BoxShadow(blurRadius: 16, color: Colors.black26)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () {
              _ctrl.forward().then((_) => _ctrl.reverse());
              widget.onToggle();
            },
            child: ScaleTransition(
              scale: _scale,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red.shade400,
                  boxShadow: [
                    BoxShadow(blurRadius: 16, color: Colors.red.withAlpha(100), spreadRadius: 2),
                  ],
                ),
                child: const Icon(Icons.power_settings_new_rounded, color: Colors.white, size: 32),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text('Toca para desconectarte',
              style: TextStyle(fontSize: 12, color: Colors.red.shade400, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ── Multi-order panel (has active orders) ────────────────────────────────────

class _MultiOrderPanel extends ConsumerStatefulWidget {
  final List<OrderModel> orders;
  final DriverFirebaseService firebase;
  final Future<void> Function(String) onNavigate;
  const _MultiOrderPanel({required this.orders, required this.firebase, required this.onNavigate});

  @override
  ConsumerState<_MultiOrderPanel> createState() => _MultiOrderPanelState();
}

class _MultiOrderPanelState extends ConsumerState<_MultiOrderPanel> {
  bool _collapsed = false;
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  int _remainingSeconds(OrderModel order) {
    if (order.status != OrderStatus.pickedUp || order.deliveryStartedAt == null) return -1;
    final elapsed = DateTime.now().difference(order.deliveryStartedAt!).inSeconds;
    return (600 - elapsed).clamp(0, 600);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final pendingCount = widget.orders.where((o) =>
      o.status == OrderStatus.accepted || o.status == OrderStatus.ready || o.status == OrderStatus.preparing).length;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      constraints: BoxConstraints(maxHeight: _collapsed ? 56 : 300),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: const [BoxShadow(blurRadius: 16, color: Colors.black26)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header — always visible, tap to collapse/expand
          GestureDetector(
            onTap: () => setState(() => _collapsed = !_collapsed),
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
              child: Row(
                children: [
                  Container(
                    width: 8, height: 8,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: _blue),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${widget.orders.length} pedido${widget.orders.length > 1 ? 's' : ''} activo${widget.orders.length > 1 ? 's' : ''}',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  if (!_collapsed && pendingCount > 1) ...[
                    FilledButton.tonal(
                      onPressed: () => widget.firebase.confirmAllRecogida(),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text('Recogida todos ($pendingCount)', style: const TextStyle(fontSize: 10)),
                    ),
                    const SizedBox(width: 6),
                  ],
                  AnimatedRotation(
                    turns: _collapsed ? 0.5 : 0,
                    duration: const Duration(milliseconds: 280),
                    child: Icon(Icons.keyboard_arrow_down, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),

          // Orders list — hidden when collapsed
          if (!_collapsed)
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                itemCount: widget.orders.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (ctx, i) {
                  final order = widget.orders[i];
                  final canDeliver = widget.firebase.canDeliver(order.id);
                  final isPickedUp = order.status == OrderStatus.pickedUp;
                  final remaining = _remainingSeconds(order);
                  return _ActiveOrderTile(
                    order: order,
                    index: i,
                    canDeliver: canDeliver,
                    remainingSeconds: remaining,
                    onNavigate: () => widget.onNavigate(isPickedUp ? order.deliveryAddress : 'Carrer de Provença 78 Barcelona'),
                    onTap: () => _showDetail(ctx, order, widget.firebase, canDeliver, remaining),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  void _showDetail(BuildContext context, OrderModel order, DriverFirebaseService firebase, bool canDeliver, int remainingSeconds) {
    final isPickedUp = order.status == OrderStatus.pickedUp;
    final hasPending = order.status == OrderStatus.accepted ||
        order.status == OrderStatus.ready ||
        order.status == OrderStatus.preparing;
    final allPickedUp = firebase.allPickedUp();

    String? lockedMessage;
    if (isPickedUp && !allPickedUp) {
      lockedMessage = 'Recoge todos los pedidos primero';
    } else if (isPickedUp && allPickedUp && !canDeliver) {
      lockedMessage = 'Entrega el pedido anterior primero';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _OrderDetailSheet(
        order: order,
        onRecogida: hasPending
            ? () {
                firebase.updateOrderStatus(order.id, OrderStatus.pickedUp);
                Navigator.pop(ctx);
              }
            : null,
        onEntrega: isPickedUp && canDeliver
            ? () {
                firebase.updateOrderStatus(order.id, OrderStatus.delivered);
                Navigator.pop(ctx);
              }
            : null,
        onCallStarted: isPickedUp ? () => firebase.startDelivery(order.id) : null,
        lockedMessage: lockedMessage,
        onCancel: isPickedUp
            ? () {
                firebase.cancelOrder(order.id);
                Navigator.pop(ctx);
              }
            : null,
      ),
    );
  }
}

// ── Active order tile ─────────────────────────────────────────────────────────

class _ActiveOrderTile extends StatelessWidget {
  final OrderModel order;
  final int index;
  final bool canDeliver;
  final int remainingSeconds;
  final VoidCallback onNavigate;
  final VoidCallback onTap;

  const _ActiveOrderTile({
    required this.order,
    required this.index,
    required this.canDeliver,
    required this.remainingSeconds,
    required this.onNavigate,
    required this.onTap,
  });

  String get _countdown {
    final r = remainingSeconds.clamp(0, 600);
    final m = r ~/ 60;
    final s = r % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isPickedUp = order.status == OrderStatus.pickedUp;
    final locked = isPickedUp && !canDeliver;
    final deliveryStarted = order.deliveryStartedAt != null;
    final expired = deliveryStarted && remainingSeconds <= 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: locked ? cs.surfaceContainerHighest : isPickedUp ? Colors.green.withAlpha(15) : _blue.withAlpha(12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: locked ? cs.outlineVariant : isPickedUp ? Colors.green.withAlpha(80) : _blue.withAlpha(60),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: locked ? cs.outlineVariant : isPickedUp ? Colors.green : _blue,
              ),
              alignment: Alignment.center,
              child: Text('${index + 1}',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(order.customerName,
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(
                    isPickedUp ? order.deliveryAddress : 'Restaurante → ${order.deliveryAddress}',
                    style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                  if (isPickedUp && deliveryStarted) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          expired ? Icons.warning_amber_rounded : Icons.timer_outlined,
                          size: 11,
                          color: expired ? Colors.red : remainingSeconds < 120 ? Colors.orange : Colors.green,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          expired ? '¡Puede cancelar!' : _countdown,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: expired ? Colors.red : remainingSeconds < 120 ? Colors.orange : Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              children: [
                IconButton(
                  onPressed: onNavigate,
                  icon: const Icon(Icons.navigation_outlined, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: cs.surfaceContainerHighest,
                    minimumSize: const Size(32, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(height: 4),
                const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Order detail sheet ────────────────────────────────────────────────────────

class _OrderDetailSheet extends StatefulWidget {
  final OrderModel order;
  final VoidCallback? onRecogida;
  final VoidCallback? onEntrega;
  final VoidCallback? onCallStarted;
  final String? lockedMessage;
  final VoidCallback? onCancel;

  const _OrderDetailSheet({
    required this.order,
    required this.onRecogida,
    required this.onEntrega,
    this.onCallStarted,
    this.lockedMessage,
    this.onCancel,
  });

  @override
  State<_OrderDetailSheet> createState() => _OrderDetailSheetState();
}

class _OrderDetailSheetState extends State<_OrderDetailSheet> {
  DateTime? _callStartedAt;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.order.status == OrderStatus.pickedUp &&
        widget.order.deliveryStartedAt != null) {
      _callStartedAt = widget.order.deliveryStartedAt;
      _startTimer();
    }
  }

  @override
  void didUpdateWidget(_OrderDetailSheet old) {
    super.didUpdateWidget(old);
    if (widget.order.status != OrderStatus.pickedUp) {
      _timer?.cancel();
      _timer = null;
      _callStartedAt = null;
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  int get _remainingSeconds {
    if (_callStartedAt == null) return 600;
    final elapsed = DateTime.now().difference(_callStartedAt!).inSeconds;
    return (600 - elapsed).clamp(0, 600);
  }

  bool get _canCancel => _callStartedAt != null && _remainingSeconds <= 0;

  String get _countdown {
    final r = _remainingSeconds;
    final m = r ~/ 60;
    final s = r % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _onLlamar() async {
    if (widget.order.status == OrderStatus.pickedUp && _callStartedAt == null) {
      setState(() => _callStartedAt = DateTime.now());
      _startTimer();
      widget.onCallStarted?.call();
    }
    final uri = Uri.parse('tel:${widget.order.phoneNumber}');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  void _confirmCancel(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar pedido'),
        content: Text('¿Cancelar el pedido de ${widget.order.customerName}? Volverá a estar disponible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.onCancel?.call();
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );
  }

  Future<void> _navigate(String address) async {
    final encoded = Uri.encodeComponent(address);
    final uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$encoded&travelmode=driving');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final order = widget.order;
    final isPickedUp = order.status == OrderStatus.pickedUp;
    final chronoActive = _callStartedAt != null;
    final expired = chronoActive && _remainingSeconds <= 0;

    final statusLabel = switch (order.status) {
      OrderStatus.accepted => 'Aceptado',
      OrderStatus.preparing => 'Preparando',
      OrderStatus.ready => 'Listo · En restaurante',
      OrderStatus.pickedUp => 'Recogido · En camino',
      _ => 'Pendiente',
    };
    final statusColor = switch (order.status) {
      OrderStatus.ready => _blue,
      OrderStatus.pickedUp => Colors.green,
      _ => Colors.orange,
    };

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: cs.outlineVariant, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),

            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(order.customerName,
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(color: statusColor.withAlpha(25), borderRadius: BorderRadius.circular(10)),
                        child: Text(statusLabel, style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _onLlamar,
                      icon: const Icon(Icons.phone_outlined, size: 16),
                      label: const Text('Llamar', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    if (isPickedUp && chronoActive) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            expired ? Icons.warning_amber_rounded : Icons.timer_outlined,
                            size: 12,
                            color: expired ? Colors.red : _remainingSeconds < 120 ? Colors.orange : Colors.green,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            expired ? '¡Puede cancelar!' : _countdown,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: expired ? Colors.red : _remainingSeconds < 120 ? Colors.orange : Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Address
            InkWell(
              onTap: () => _navigate(order.deliveryAddress),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(10)),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.red, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(order.deliveryAddress,
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500))),
                    const Icon(Icons.open_in_new, size: 14, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Items
            Text('Artículos', style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: 6),
            ...order.items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Container(
                        width: 22, height: 22,
                        decoration: BoxDecoration(color: _blue.withAlpha(25), borderRadius: BorderRadius.circular(6)),
                        alignment: Alignment.center,
                        child: Text('${item.quantity}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _blue)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(item.name, style: theme.textTheme.bodyMedium)),
                      Text('€${(item.price * item.quantity).toStringAsFixed(2)}',
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                    ],
                  ),
                )),
            const Divider(height: 20),

            // Totals
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Subtotal', style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                Text('€${order.itemsTotal.toStringAsFixed(2)}', style: theme.textTheme.bodySmall),
              ],
            ),
            if (order.tip > 0) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    const Icon(Icons.savings_outlined, size: 14, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text('Propina', style: theme.textTheme.bodySmall?.copyWith(color: Colors.amber)),
                  ]),
                  Text('€${order.tip.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.amber)),
                ],
              ),
            ],
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                Text('€${order.grandTotal.toStringAsFixed(2)}',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: _blue)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              order.paymentType == PaymentType.cash ? '💵 Pago en efectivo' : '💳 Pago con tarjeta',
              style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 20),

            // Action button
            if (widget.lockedMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_outline, size: 16, color: cs.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Text(widget.lockedMessage!, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
                  ],
                ),
              )
            else if (widget.onRecogida != null)
              FilledButton(
                onPressed: widget.onRecogida,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  backgroundColor: _blue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Confirmar Recogida', style: TextStyle(fontSize: 13)),
                    Text('€${order.itemsTotal.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                  ],
                ),
              )
            else if (widget.onEntrega != null)
              FilledButton(
                onPressed: widget.onEntrega,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Confirmar Entrega', style: TextStyle(fontSize: 13)),
                    Text(
                      '€${order.grandTotal.toStringAsFixed(2)}${order.tip > 0 ? ' (+ €${order.tip.toStringAsFixed(2)} propina)' : ''}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: isPickedUp ? Colors.green.withAlpha(20) : cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isPickedUp ? Colors.green.withAlpha(80) : cs.outlineVariant),
                ),
                child: Center(
                  child: Text(
                    isPickedUp ? '✓ En camino al cliente' : '✓ Pedido recogido',
                    style: TextStyle(color: isPickedUp ? Colors.green : cs.onSurfaceVariant, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            if (_canCancel) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => _confirmCancel(context),
                icon: const Icon(Icons.cancel_outlined, size: 18, color: Colors.red),
                label: const Text('Cancelar pedido',
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 46),
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Floating order squares ────────────────────────────────────────────────────

class _FloatingOrderSquares extends StatelessWidget {
  final List<OrderModel> orders;
  final Future<void> Function(String) onAccept;
  const _FloatingOrderSquares({required this.orders, required this.onAccept});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: orders.take(4).map((o) => _OrderSquare(order: o, onAccept: onAccept)).toList(),
    );
  }
}

class _OrderSquare extends StatefulWidget {
  final OrderModel order;
  final Future<void> Function(String) onAccept;
  const _OrderSquare({required this.order, required this.onAccept});

  @override
  State<_OrderSquare> createState() => _OrderSquareState();
}

class _OrderSquareState extends State<_OrderSquare> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        width: _expanded ? 270 : 76,
        height: _expanded ? 210 : 76,
        decoration: BoxDecoration(
          color: _expanded ? cs.surface : _blue,
          borderRadius: BorderRadius.circular(_expanded ? 18 : 16),
          boxShadow: const [BoxShadow(blurRadius: 12, color: Colors.black38, offset: Offset(0, 4))],
        ),
        clipBehavior: Clip.hardEdge,
        child: _expanded
            ? _ExpandedContent(
                order: widget.order,
                onAccept: () async {
                  await widget.onAccept(widget.order.id);
                  if (mounted) setState(() => _expanded = false);
                },
                onClose: () => setState(() => _expanded = false),
              )
            : _SmallContent(order: widget.order),
      ),
    );
  }
}

class _SmallContent extends StatelessWidget {
  final OrderModel order;
  const _SmallContent({required this.order});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.receipt_outlined, color: Colors.white, size: 26),
        const SizedBox(height: 4),
        Text(order.customerName.split(' ').first,
            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
        Text('€${order.grandTotal.toStringAsFixed(0)}',
            style: const TextStyle(color: Colors.white70, fontSize: 9)),
      ],
    );
  }
}

class _ExpandedContent extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onAccept;
  final VoidCallback onClose;
  const _ExpandedContent({required this.order, required this.onAccept, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(order.customerName,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
              GestureDetector(onTap: onClose, child: Icon(Icons.close, size: 16, color: cs.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 4),
          Text(order.deliveryAddress,
              style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 6),
          Row(
            children: [
              Text('${order.items.length} art.',
                  style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
              const SizedBox(width: 8),
              Text('€${order.grandTotal.toStringAsFixed(2)}',
                  style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold)),
              if (order.tip > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(color: Colors.amber.withAlpha(40), borderRadius: BorderRadius.circular(6)),
                  child: Text('+€${order.tip.toStringAsFixed(2)} tip',
                      style: const TextStyle(fontSize: 8, color: Colors.amber, fontWeight: FontWeight.bold)),
                ),
              ],
            ],
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onAccept,
              style: FilledButton.styleFrom(
                backgroundColor: _blue,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Aceptar', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stats badge ───────────────────────────────────────────────────────────────

class _StatsBadge extends StatelessWidget {
  final int pedidos;
  final int availableCount;
  const _StatsBadge({required this.pedidos, required this.availableCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(blurRadius: 8, color: Colors.black26)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_shipping_outlined, size: 14, color: _blue),
          const SizedBox(width: 6),
          Text('$pedidos pedido${pedidos == 1 ? '' : 's'} hoy',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _blue)),
          if (availableCount > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(10)),
              child: Text('$availableCount nuevo${availableCount == 1 ? '' : 's'}',
                  style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Online status pill ────────────────────────────────────────────────────────

class _OnlineStatusPill extends StatelessWidget {
  final bool isOnline;
  const _OnlineStatusPill({required this.isOnline});

  @override
  Widget build(BuildContext context) {
    final color = isOnline ? const Color(0xFF10B981) : Colors.grey.shade600;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(blurRadius: 8, color: Colors.black26)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(isOnline ? 'En línea' : 'Desconectado',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}
