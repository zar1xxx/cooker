import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/daos/recipe_dao.dart';
import '../../core/shopping/missing_products.dart';
import '../../l10n/app_localizations.dart';
import '../feed/feed_providers.dart';

/// Converts recipe lines into the plain input of [missingProducts].
List<MissingProductInput> missingInputsOf(List<RecipeIngredientLine> lines) {
  return [
    for (final line in lines)
      MissingProductInput(
        ingredientId: line.recipeIngredient.ingredientId,
        name: line.ingredient?.name ?? line.recipeIngredient.ingredientId,
        amount: line.recipeIngredient.amount,
        unit: line.recipeIngredient.unit,
        isOptional: line.recipeIngredient.isOptional,
        isStaple: line.ingredient?.isStaple ?? false,
      ),
  ];
}

/// R7-09: «Чего не хватает» with «Поделиться списком» and «Искать в Купере».
///
/// No logins, no site parsing: the list goes to the system share menu, and
/// Kuper opens as a web search in the browser with only the product name.
class MissingProductsSheet extends ConsumerWidget {
  const MissingProductsSheet({
    super.key,
    required this.recipeTitle,
    required this.products,
    required this.unitLabel,
  });

  final String recipeTitle;
  final List<MissingProduct> products;
  final String Function(String? unit) unitLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final actions = ref.read(externalActionsProvider);

    String amountText(MissingProduct product) {
      final amount = product.amount;
      if (amount == null || amount <= 0) return unitLabel(product.unit);
      return '${formatAmount(amount)} ${unitLabel(product.unit)}'.trim();
    }

    Future<void> openKuper(String name) async {
      final messenger = ScaffoldMessenger.of(context);
      var opened = false;
      try {
        opened = await actions.openUrl(kuperSearchUri(name));
      } catch (_) {
        opened = false;
      }
      if (!opened) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.missingOpenFailed)));
      }
    }

    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Text(
            l10n.missingButton,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (products.isEmpty)
            Text(l10n.missingNone, style: theme.textTheme.bodyLarge)
          else ...[
            for (final product in products)
              Card(
                key: Key('missing_${product.ingredientId}'),
                elevation: 0,
                color: theme.colorScheme.surfaceContainerLow,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        product.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (amountText(product).isNotEmpty)
                        Text(
                          amountText(product),
                          style: theme.textTheme.bodyLarge,
                        ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 48),
                          child: TextButton.icon(
                            key: Key('kuper_${product.ingredientId}'),
                            icon: const Icon(Icons.open_in_browser),
                            label: Text(l10n.missingKuper),
                            onPressed: () => openKuper(product.name),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Text(l10n.missingKuperHint, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 4),
            Text(l10n.missingSamokatHint, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: FilledButton.icon(
                key: const Key('missing_share'),
                icon: const Icon(Icons.share),
                label: Text(l10n.missingShare),
                onPressed: () => actions.shareText(
                  shoppingListText(
                    title: l10n.missingShareTitle(recipeTitle),
                    products: products,
                    unitLabel: unitLabel,
                  ),
                  subject: l10n.missingShareTitle(recipeTitle),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
