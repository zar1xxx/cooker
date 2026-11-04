import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onLongPress: () => context.push('/settings/ai'),
          child: Text(l10n.screenTodayTitle),
        ),
      ),
      body: Center(
        child: Text(
          l10n.screenTodayTitle,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );
  }
}
