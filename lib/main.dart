import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'providers/auth_provider.dart';
import 'providers/tenant_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final container = ProviderContainer();

  // Initialize tenant and auth before app starts
  await container.read(tenantProvider.notifier).initializeFromStorage();
  await container.read(authProvider.notifier).initialize();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const CentronisApp(),
    ),
  );
}
