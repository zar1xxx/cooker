import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/app.dart';
import 'app/router.dart';
import 'core/adaptive/adaptive_provider.dart';
import 'core/adaptive/ui_profile_service.dart';
import 'core/ai/gigachat_cert.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ru', null);
  await GigaChatCert.load();

  final uiProfileService = UiProfileService();
  final profile = await uiProfileService.loadProfile();
  if (!profile.hasCompletedOnboarding) {
    appRouter.go('/onboarding/mode');
  }

  runApp(
    ProviderScope(
      overrides: [uiProfileServiceProvider.overrideWithValue(uiProfileService)],
      child: const ChtoPrigotovitApp(),
    ),
  );
}
