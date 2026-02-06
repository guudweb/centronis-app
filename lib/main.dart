import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'providers/auth_provider.dart';
import 'providers/tenant_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final container = ProviderContainer();

  // Try to initialize from storage, but don't block app if API is down
  try {
    await container.read(tenantProvider.notifier).initializeFromStorage()
        .timeout(const Duration(seconds: 5));
    await container.read(authProvider.notifier).initialize()
        .timeout(const Duration(seconds: 5));
  } catch (_) {
    // App will show tenant/login screen if initialization fails
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const CentronisApp(),
    ),
  );
}
