import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:driver_app/l10n/app_localizations.dart';
import '../../../app.dart';
import '../../../core/services/firebase_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);
    final driver = ref.watch(firebaseServiceProvider).currentDriver;

    const languages = [
      ('English', Locale('en')),
      ('Español', Locale('es')),
      ('Français', Locale('fr')),
      ('العربية', Locale('ar')),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF2563EB),
              child: Text(driver.name[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            title: Text(driver.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(driver.phone),
          ),
          const Divider(),
          _SectionHeader('APARIENCIA'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.brightness_auto), label: Text('Auto')),
                ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode), label: Text('Claro')),
                ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode), label: Text('Oscuro')),
              ],
              selected: {themeMode},
              onSelectionChanged: (s) => ref.read(themeModeProvider.notifier).state = s.first,
            ),
          ),
          const Divider(),
          _SectionHeader(l10n.language.toUpperCase()),
          ...languages.map(
            (lang) => RadioListTile<Locale>(
              title: Text(lang.$1),
              value: lang.$2,
              groupValue: currentLocale,
              onChanged: (v) => ref.read(localeProvider.notifier).state = v!,
            ),
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.delivery_dining, color: Color(0xFF2563EB)),
            title: Text('D-helper Rider'),
            subtitle: Text('v1.0'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
      );
}
