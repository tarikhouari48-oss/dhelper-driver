import 'package:flutter_riverpod/flutter_riverpod.dart';

// null = not logged in  |  set to non-null to bypass login (dev mode)
final authStateProvider = StateProvider<String?>((ref) => 'driver-demo');
