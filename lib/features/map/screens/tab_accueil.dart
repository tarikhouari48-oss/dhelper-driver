import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

const _blue = Color(0xFF2563EB);
const _dbUrl = 'https://d-helper-f1331-default-rtdb.firebaseio.com';

final _restaurantInfoProvider = FutureProvider<Map<String, String>>((ref) async {
  try {
    final res = await http.get(Uri.parse('$_dbUrl/settings/restaurant.json'))
        .timeout(const Duration(seconds: 8));
    if (res.statusCode == 200 && res.body != 'null') {
      final m = Map<String, dynamic>.from(jsonDecode(res.body) as Map);
      return {
        'name':    m['name']?.toString()    ?? 'D-helper Restaurant',
        'address': m['address']?.toString() ?? '',
        'phone':   m['phone']?.toString()   ?? '',
        'hours':   m['hours']?.toString()   ?? '',
      };
    }
  } catch (_) {}
  return {
    'name':    'D-helper Restaurant',
    'address': '',
    'phone':   '',
    'hours':   '',
  };
});

class AccueilTab extends ConsumerWidget {
  const AccueilTab({super.key});

  Future<void> _openMaps(String address) async {
    if (address.isEmpty) return;
    final encoded = Uri.encodeComponent(address);
    final uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$encoded&travelmode=driving');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _call(String phone) async {
    if (phone.isEmpty) return;
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final infoAsync = ref.watch(_restaurantInfoProvider);

    return SafeArea(
      child: infoAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _buildContent(context, theme, cs,
            {'name': 'D-helper Restaurant', 'address': '', 'phone': '', 'hours': ''}),
        data: (info) => _buildContent(context, theme, cs, info),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ThemeData theme,
      ColorScheme cs, Map<String, String> info) {
    final name    = info['name']    ?? '';
    final address = info['address'] ?? '';
    final phone   = info['phone']   ?? '';
    final hours   = info['hours']   ?? '';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      children: [
        // Header
        Row(
          children: [
            Image.asset('assets/images/logo.png', height: 36),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('D-helper Rider',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _blue)),
                Text('Restaurante activo',
                    style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 28),

        // Restaurant card
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: cs.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _blue.withAlpha(20),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.storefront, color: _blue, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name.isNotEmpty ? name : 'D-helper Restaurant',
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          Row(
                            children: [
                              Container(
                                width: 8, height: 8,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text('Abierto',
                                  style: TextStyle(fontSize: 12, color: Colors.green.shade600)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Address
                if (address.isNotEmpty)
                  InkWell(
                    onTap: () => _openMaps(address),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on, color: Colors.red, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Dirección',
                                    style: theme.textTheme.labelSmall
                                        ?.copyWith(color: cs.onSurfaceVariant)),
                                Text(address,
                                    style: theme.textTheme.bodyMedium
                                        ?.copyWith(fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                          const Icon(Icons.open_in_new, size: 16, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),

                if (address.isNotEmpty) const SizedBox(height: 10),

                // Hours
                if (hours.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time_outlined, color: _blue, size: 20),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Horario',
                                style: theme.textTheme.labelSmall
                                    ?.copyWith(color: cs.onSurfaceVariant)),
                            Text(hours,
                                style: theme.textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ),
                  ),

                if (address.isNotEmpty || hours.isNotEmpty) const SizedBox(height: 16),

                // Navigate + Call buttons
                Row(
                  children: [
                    if (address.isNotEmpty)
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _openMaps(address),
                          icon: const Icon(Icons.navigation_outlined, size: 18),
                          label: const Text('Navegar'),
                          style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12)),
                        ),
                      ),
                    if (address.isNotEmpty && phone.isNotEmpty) const SizedBox(width: 10),
                    if (phone.isNotEmpty)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _call(phone),
                          icon: const Icon(Icons.phone_outlined, size: 18),
                          label: Text(phone),
                          style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12)),
                        ),
                      ),
                  ],
                ),

                if (address.isEmpty && phone.isEmpty)
                  const Text(
                    'El operador aún no ha configurado la información del restaurante.',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
