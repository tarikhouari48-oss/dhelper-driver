import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../orders/providers/orders_provider.dart';
import 'tab_accueil.dart';
import 'tab_livraisons.dart';
import 'tab_profil.dart';

const _blue = Color(0xFF2563EB);

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  int _selectedIndex = 1; // Start on Livraisons

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final availableCount = ref.watch(availableOrdersProvider).valueOrNull?.length ?? 0;

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          const AccueilTab(),
          const LivraisonsTab(),
          const ProfilTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: availableCount > 0,
              label: Text('$availableCount'),
              child: const Icon(Icons.delivery_dining_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: availableCount > 0,
              label: Text('$availableCount'),
              child: const Icon(Icons.delivery_dining),
            ),
            label: 'Livraisons',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
