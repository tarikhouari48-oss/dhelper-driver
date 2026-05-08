import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://iatefokxwbgexcetgkcs.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlhdGVmb2t4d2JnZXhjZXRna2NzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgxNjk0MzEsImV4cCI6MjA5Mzc0NTQzMX0.4qtREM3sEgcFmo1nPl7h0QY5tUlRJUFaSzlv3z5uKww',
  );
  runApp(const ProviderScope(child: DriverApp()));
}
