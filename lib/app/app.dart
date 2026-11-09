import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/adaptive/adaptive_provider.dart';
import '../core/adaptive/adaptive_spec.dart';
import '../l10n/app_localizations.dart';
import 'router.dart';
import 'theme.dart';

class ChtoPrigotovitApp extends ConsumerWidget {
  const ChtoPrigotovitApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spec = ref.watch(adaptiveSpecProvider);

    return AdaptiveScope(
      spec: spec,
      child: MaterialApp.router(
        routerConfig: appRouter,
        onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ru'),
        theme: AppTheme.lightFor(spec),
        darkTheme: AppTheme.darkFor(spec),
        themeMode: ThemeMode.system,
        builder: (context, child) {
          return AdaptiveScope(
            spec: spec,
            child: child ?? const SizedBox.shrink(),
          );
        },
      ),
    );
  }
}
