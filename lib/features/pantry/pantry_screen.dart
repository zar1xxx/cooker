import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

class PantryScreen extends StatelessWidget {
  const PantryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.screenPantryTitle)),
      body: Center(
        child: Text(
          l10n.screenPantryTitle,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );
  }
}
