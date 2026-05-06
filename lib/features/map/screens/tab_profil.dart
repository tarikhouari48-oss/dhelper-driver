import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/firebase_service.dart' show firebaseServiceProvider, DriverFirebaseService;
import '../../../features/auth/providers/auth_provider.dart';
import '../providers/location_provider.dart';

const _blue = Color(0xFF2563EB);

class ProfilTab extends ConsumerWidget {
  const ProfilTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final driver = ref.watch(firebaseServiceProvider).currentDriver;
    final isOnline = ref.watch(isOnlineProvider);

    final vehicleLabel = switch (driver.vehicleType.name) {
      'motorcycle' => 'Motocicleta',
      'car' => 'Coche',
      _ => 'Bicicleta',
    };

    final vehicleIcon = switch (driver.vehicleType.name) {
      'motorcycle' => Icons.two_wheeler,
      'car' => Icons.directions_car_outlined,
      _ => Icons.pedal_bike_outlined,
    };

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
        children: [
          // Avatar + name
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: _blue,
                  child: Text(
                    driver.name.isNotEmpty ? driver.name[0].toUpperCase() : 'D',
                    style: const TextStyle(fontSize: 38, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 12),
                Text(driver.name,
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: isOnline ? Colors.green.withAlpha(25) : cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isOnline ? Colors.green : Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isOnline ? 'En línea' : 'Desconectado',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isOnline ? Colors.green : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Info card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: cs.outlineVariant),
            ),
            child: Column(
              children: [
                _InfoTile(icon: Icons.phone_outlined, label: 'Teléfono', value: driver.phone),
                Divider(height: 1, indent: 56, color: cs.outlineVariant),
                _InfoTile(icon: vehicleIcon, label: 'Vehículo', value: vehicleLabel),
                Divider(height: 1, indent: 56, color: cs.outlineVariant),
                _InfoTile(
                  icon: Icons.badge_outlined,
                  label: 'ID Repartidor',
                  value: driver.id.toUpperCase(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Disconnect button
          OutlinedButton.icon(
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Desconectarse'),
                  content: const Text('¿Seguro que quieres desconectarte?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancelar'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: FilledButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('Desconectar'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                ref.read(isOnlineProvider.notifier).state = false;
                await ref.read(firebaseServiceProvider).updateDriverOnlineStatus(false);
                ref.read(authStateProvider.notifier).state = null;
                if (context.mounted) context.go('/login');
              }
            },
            icon: const Icon(Icons.logout, color: Colors.red),
            label: const Text('Desconectar', style: TextStyle(color: Colors.red)),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              side: const BorderSide(color: Colors.red),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: _blue, size: 22),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              Text(value,
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCol extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _StatCol({required this.icon, required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
        Text(label,
            style: TextStyle(fontSize: 11, color: color.withAlpha(180)),
            textAlign: TextAlign.center),
      ],
    );
  }
}
