import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:driver_app/l10n/app_localizations.dart';
import '../../../core/models/order_model.dart';
import '../../../core/services/firebase_service.dart';
import '../providers/orders_provider.dart';

class OrderActiveScreen extends ConsumerWidget {
  const OrderActiveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final orderAsync = ref.watch(activeOrderProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pedido Activo'),
        centerTitle: true,
        leading: const SizedBox.shrink(),
      ),
      body: orderAsync.when(
        data: (order) {
          if (order == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/map'));
            return const SizedBox.shrink();
          }
          return _ActiveOrderView(order: order, l10n: l10n);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.error)),
      ),
    );
  }
}

class _ActiveOrderView extends ConsumerWidget {
  final OrderModel order;
  final AppLocalizations l10n;

  const _ActiveOrderView({required this.order, required this.l10n});

  Future<void> _navigate(String address) async {
    final encoded = Uri.encodeComponent(address);
    final uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$encoded');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _call(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firebase = ref.read(firebaseServiceProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isPickedUp = order.status == OrderStatus.pickedUp;

    return Column(
      children: [
        // Step progress bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: _StepBar(status: order.status),
        ),

        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              // Phase banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isPickedUp ? Colors.green.withAlpha(25) : cs.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      isPickedUp ? Icons.directions_bike : Icons.storefront_outlined,
                      color: isPickedUp ? Colors.green : cs.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      isPickedUp ? 'Llevar al cliente' : 'Ir al restaurante',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isPickedUp ? Colors.green : cs.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Info card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isPickedUp ? l10n.customerName : l10n.restaurantLocation,
                        style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isPickedUp ? order.customerName : 'D-helper Restaurant',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.location_on_outlined, size: 16, color: cs.onSurfaceVariant),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              isPickedUp ? order.deliveryAddress : 'Carrer de Provença, 78, Barcelona',
                              style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                            ),
                          ),
                        ],
                      ),
                      if (isPickedUp) ...[
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () => _call(order.phoneNumber),
                          icon: const Icon(Icons.phone_outlined, size: 18),
                          label: Text(order.phoneNumber),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 40),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Items card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Artículos (${order.items.length})',
                        style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                      ),
                      const SizedBox(height: 8),
                      ...order.items.map((item) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              children: [
                                Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: cs.primaryContainer,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${item.quantity}',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: cs.primary),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(child: Text(item.name, style: theme.textTheme.bodyMedium)),
                                Text(
                                  '€${(item.price * item.quantity).toStringAsFixed(2)}',
                                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          )),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total pedido', style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                          Text('€${order.itemsTotal.toStringAsFixed(2)}',
                              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Tip card — shown when tip > 0
              if (order.tip > 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.savings_outlined, color: Colors.amber, size: 28),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Propina del cliente',
                              style: theme.textTheme.labelSmall?.copyWith(color: Colors.amber.shade700)),
                          Text('€${order.tip.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.amber)),
                        ],
                      ),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Total c/ propina',
                              style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
                          Text('€${order.grandTotal.toStringAsFixed(2)}',
                              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        // Bottom action buttons
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Navigate button
                OutlinedButton.icon(
                  onPressed: () => _navigate(isPickedUp ? order.deliveryAddress : 'Carrer de Provença 78 Barcelona'),
                  icon: const Icon(Icons.navigation_outlined, size: 20),
                  label: Text(isPickedUp ? l10n.navigateToCustomer : l10n.navigateToRestaurant),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
                const SizedBox(height: 10),

                // Main action button with price
                FilledButton(
                  onPressed: () async {
                    if (isPickedUp) {
                      await firebase.updateOrderStatus(order.id, OrderStatus.delivered);
                      if (context.mounted) context.go('/map');
                    } else {
                      await firebase.updateOrderStatus(order.id, OrderStatus.pickedUp);
                    }
                  },
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 64),
                    backgroundColor: isPickedUp ? Colors.green : cs.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(isPickedUp ? Icons.done_all : Icons.check_circle_outline, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            isPickedUp ? l10n.orderDelivered : l10n.pickedUpOrder,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      Text(
                        isPickedUp
                            ? '€${order.grandTotal.toStringAsFixed(2)}${order.tip > 0 ? ' (+ €${order.tip.toStringAsFixed(2)} propina)' : ''}'
                            : '€${order.itemsTotal.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StepBar extends StatelessWidget {
  final OrderStatus status;

  const _StepBar({required this.status});

  static const _steps = [
    (OrderStatus.accepted, Icons.check, 'Aceptado'),
    (OrderStatus.ready, Icons.storefront, 'Listo'),
    (OrderStatus.pickedUp, Icons.directions_bike, 'Recogido'),
    (OrderStatus.delivered, Icons.home, 'Entregado'),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final activeIndex = _steps.indexWhere((s) => s.$1 == status);

    return Row(
      children: [
        for (int i = 0; i < _steps.length; i++) ...[
          _StepDot(
            icon: _steps[i].$2,
            label: _steps[i].$3,
            isDone: i < activeIndex,
            isActive: i == activeIndex,
            cs: cs,
          ),
          if (i < _steps.length - 1)
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.only(bottom: 18),
                color: i < activeIndex ? cs.primary : cs.outlineVariant,
              ),
            ),
        ],
      ],
    );
  }
}

class _StepDot extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDone;
  final bool isActive;
  final ColorScheme cs;

  const _StepDot({
    required this.icon,
    required this.label,
    required this.isDone,
    required this.isActive,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    final color = (isDone || isActive) ? cs.primary : cs.outlineVariant;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDone ? cs.primary : isActive ? cs.primaryContainer : cs.surfaceContainerHighest,
            border: isActive ? Border.all(color: cs.primary, width: 2) : null,
          ),
          child: Icon(
            isDone ? Icons.check : icon,
            size: 16,
            color: isDone ? cs.onPrimary : isActive ? cs.primary : cs.outlineVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 9, color: color, fontWeight: isActive ? FontWeight.bold : FontWeight.normal),
        ),
      ],
    );
  }
}
