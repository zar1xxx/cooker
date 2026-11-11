import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/daos/plan_dao.dart';
import '../../core/db/enums.dart';
import '../../core/providers.dart';
import '../../l10n/app_localizations.dart';

/// R7-08: puts a recipe on a chosen day of the month calendar.
///
/// A locked day is never replaced. Returns true when the plan was saved.
Future<bool> planRecipeOnDate({
  required BuildContext context,
  required WidgetRef ref,
  required String recipeId,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);
  final today = clock.now();
  final picked = await showDatePicker(
    context: context,
    initialDate: today,
    firstDate: DateTime(today.year, today.month, today.day),
    lastDate: DateTime(today.year + 1, today.month, today.day),
    helpText: l10n.planPickDateHelp,
  );
  if (picked == null) return false;

  final planDao = ref.read(planDaoProvider);
  final dateKey = PlanDao.formatDate(picked);
  final existing = await planDao.getEntryForDate(dateKey);
  if (existing != null && existing.entry.locked) {
    messenger.showSnackBar(SnackBar(content: Text(l10n.planDayLocked)));
    return false;
  }
  await planDao.upsertEntry(
    date: dateKey,
    recipeId: recipeId,
    status: MealPlanStatus.planned,
  );
  ref.invalidate(calendarPlanEntriesProvider);
  ref.invalidate(todayPlanEntryProvider);
  messenger.showSnackBar(SnackBar(content: Text(l10n.recipeAddedToCalendar)));
  return true;
}
