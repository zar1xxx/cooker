import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.screenCalendarTitle)),
      body: Center(
        child: Text(
          l10n.screenCalendarTitle,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );
  }
}
