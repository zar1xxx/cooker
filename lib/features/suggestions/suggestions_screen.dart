import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';

class SuggestionsScreen extends ConsumerWidget {
  const SuggestionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.dishesScreenTitle)),
      body: Center(
        child: Text(
          l10n.dishesScreenTitle,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );
  }
}
