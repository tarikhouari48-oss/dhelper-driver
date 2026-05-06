import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:driver_app/l10n/app_localizations.dart';
import '../../../core/models/order_model.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/services/sound_service.dart';
import '../providers/orders_provider.dart';

const _blue = Color(0xFF2563EB);
const _kAutoAcceptSeconds = 5;

class OrderIncomingScreen extends ConsumerWidget {
  const OrderIncomingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final ordersAsync = ref.watch(availableOrdersProvider);

    return Scaffold(
      body: ordersAsync.when(
        data: (orders) {
          if (orders.isEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) context.go('/');
            });
            return const Center(child: CircularProgressIndicator());
          }
          return _IncomingOrderCard(order: orders.first, l10n: l10n);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.error)),
      ),
    );
  }
}

class _IncomingOrderCard extends ConsumerStatefulWidget {
  final OrderModel order;
  final AppLocalizations l10n;
  const _IncomingOrderCard({required this.order, required this.l10n});

  @override
  ConsumerState<_IncomingOrderCard> createState() => _IncomingOrderCardState();
}

class _IncomingOrderCardState extends ConsumerState<_IncomingOrderCard>
    with SingleTickerProviderStateMixin {
  late int _seconds;
  Timer? _timer;
  late AnimationController _pulseController;
  bool _accepting = false;

  @override
  void initState() {
    super.initState();
    _seconds = _kAutoAcceptSeconds;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    SoundService.playNotification();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _seconds--);
      if (_seconds <= 0) {
        _timer?.cancel();
        _accept();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _accept() async {
    if (_accepting || !mounted) return;
    setState(() => _accepting = true);
    _timer?.cancel();
    await ref.read(firebaseServiceProvider).acceptOrder(widget.order.id);
    if (mounted) context.go('/order/active');
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final progress = _seconds / _kAutoAcceptSeconds;

    return SafeArea(
      child: Column(
        children: [
          // ── Auto-accept progress bar ───────────────────────────────
          LinearProgressIndicator(
            value: progress,
            backgroundColor: _blue.withValues(alpha: 0.15),
            color: _blue,
            minHeight: 4,
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                children: [
                  // ── Header ───────────────────────────────────────────
                  Row(
                    children: [
                      ScaleTransition(
                        scale: Tween(begin: 1.0, end: 1.18).animate(_pulseController),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _blue.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.delivery_dining, color: _blue, size: 30),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.l10n.newOrderAvailable,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Pedido #${order.id.substring(0, 6).toUpperCase()} · Aceptando en $_seconds s',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Order details card ───────────────────────────────
                  Expanded(
                    child: Card(
                      child: ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          _InfoRow(icon: Icons.person_outline, label: widget.l10n.customerName, value: order.customerName),
                          const Divider(height: 28),
                          _InfoRow(icon: Icons.phone_outlined, label: 'Teléfono', value: order.phoneNumber),
                          const Divider(height: 28),
                          _InfoRow(icon: Icons.restaurant_outlined, label: widget.l10n.restaurantLocation, value: 'D-helper Restaurant'),
                          const Divider(height: 28),
                          _InfoRow(icon: Icons.location_on_outlined, label: widget.l10n.deliveryAddress, value: order.deliveryAddress),
                          const Divider(height: 28),
                          _InfoRow(
                            icon: Icons.shopping_bag_outlined,
                            label: 'Artículos',
                            value: '${order.items.length} art. · ${order.paymentType.name}',
                          ),
                          const SizedBox(height: 6),
                          ...order.items.map((item) => Padding(
                                padding: const EdgeInsets.only(left: 32, top: 4),
                                child: Text('${item.quantity}× ${item.name}',
                                    style: const TextStyle(fontSize: 13, color: Colors.grey)),
                              )),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Accept button only ───────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _accepting ? null : _accept,
                      style: FilledButton.styleFrom(
                        backgroundColor: _blue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _accepting
                          ? const SizedBox(
                              height: 20, width: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(widget.l10n.acceptOrder,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: _blue, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }
}
