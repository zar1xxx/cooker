import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../app/app_images.dart';
import '../../app/theme.dart';
import '../../core/db/app_database.dart';
import '../../core/providers.dart';
import '../../core/services/notification_service.dart';
import '../../l10n/app_localizations.dart';

class CookingScreen extends ConsumerStatefulWidget {
  const CookingScreen({super.key, required this.recipeId});

  final String recipeId;

  @override
  ConsumerState<CookingScreen> createState() => _CookingScreenState();
}

class _CookingScreenState extends ConsumerState<CookingScreen> {
  int _currentStepIndex = 0;

  // TTS
  late final FlutterTts _flutterTts;
  bool _isSpeaking = false;

  // Timers per step: stepIndex -> remaining seconds
  final Map<int, int> _timerRemaining = {};
  final Map<int, bool> _timerIsRunning = {};
  Timer? _activeTicker;

  @override
  void initState() {
    super.initState();
    _enableWakelock();
    _initTts();
  }

  void _enableWakelock() {
    try {
      WakelockPlus.enable().catchError((_) {});
    } catch (_) {
      // Ignored in test environment
    }
  }

  void _disableWakelock() {
    try {
      WakelockPlus.disable().catchError((_) {});
    } catch (_) {
      // Ignored in test environment
    }
  }

  void _initTts() {
    _flutterTts = FlutterTts();
    try {
      _flutterTts.setLanguage('ru-RU').catchError((_) {});
      _flutterTts.setSpeechRate(0.45).catchError((_) {});
      _flutterTts.setStartHandler(() {
        if (mounted) setState(() => _isSpeaking = true);
      });
      _flutterTts.setCompletionHandler(() {
        if (mounted) setState(() => _isSpeaking = false);
      });
      _flutterTts.setCancelHandler(() {
        if (mounted) setState(() => _isSpeaking = false);
      });
      _flutterTts.setErrorHandler((_) {
        if (mounted) setState(() => _isSpeaking = false);
      });
    } catch (_) {
      // Ignored in test environment
    }
  }

  @override
  void dispose() {
    _activeTicker?.cancel();
    _stopTts(updateState: false);
    _disableWakelock();
    try {
      unawaited(ref.read(notificationServiceProvider).cancelAll());
    } catch (_) {}
    super.dispose();
  }

  Future<void> _speakText(String text) async {
    if (_isSpeaking) {
      _stopTts();
    } else {
      try {
        setState(() => _isSpeaking = true);
        await _flutterTts.speak(text);
      } catch (_) {
        if (mounted) setState(() => _isSpeaking = false);
      }
    }
  }

  void _stopTts({bool updateState = true}) {
    try {
      _flutterTts.stop();
    } catch (_) {}
    if (updateState && mounted) {
      setState(() => _isSpeaking = false);
    } else {
      _isSpeaking = false;
    }
  }

  void _goToStep(int index, List<RecipeStep> steps) {
    if (index < 0 || index >= steps.length) return;
    _stopTts();
    setState(() {
      _currentStepIndex = index;
    });
  }

  void _toggleStepTimer(int stepIndex, int totalSeconds, String recipeTitle) {
    final isRunning = _timerIsRunning[stepIndex] ?? false;
    if (isRunning) {
      // Pause
      _activeTicker?.cancel();
      try {
        ref.read(notificationServiceProvider).cancelTimer(stepIndex);
      } catch (_) {}
      setState(() {
        _timerIsRunning[stepIndex] = false;
      });
    } else {
      // Start or Resume
      _timerRemaining.putIfAbsent(stepIndex, () => totalSeconds);
      if ((_timerRemaining[stepIndex] ?? 0) <= 0) {
        _timerRemaining[stepIndex] = totalSeconds;
      }

      final remaining = _timerRemaining[stepIndex] ?? totalSeconds;
      try {
        ref
            .read(notificationServiceProvider)
            .scheduleTimer(
              id: stepIndex,
              recipeTitle: recipeTitle,
              stepNumber: stepIndex + 1,
              seconds: remaining,
            );
      } catch (_) {}

      _activeTicker?.cancel();
      setState(() {
        _timerIsRunning[stepIndex] = true;
      });

      _activeTicker = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        final rem = _timerRemaining[stepIndex] ?? 0;
        if (rem <= 1) {
          timer.cancel();
          try {
            ref.read(notificationServiceProvider).cancelTimer(stepIndex);
          } catch (_) {}
          setState(() {
            _timerRemaining[stepIndex] = 0;
            _timerIsRunning[stepIndex] = false;
          });
        } else {
          setState(() {
            _timerRemaining[stepIndex] = rem - 1;
          });
        }
      });
    }
  }

  void _resetStepTimer(int stepIndex, int totalSeconds) {
    _activeTicker?.cancel();
    try {
      ref.read(notificationServiceProvider).cancelTimer(stepIndex);
    } catch (_) {}
    setState(() {
      _timerRemaining[stepIndex] = totalSeconds;
      _timerIsRunning[stepIndex] = false;
    });
  }

  String _formatTimerDigits(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    final mm = m.toString().padLeft(2, '0');
    final ss = s.toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  void _onFinishCooking(Recipe recipe, AppLocalizations l10n) {
    _showRatingDialog(recipe, l10n);
  }

  Future<void> _showRatingDialog(Recipe recipe, AppLocalizations l10n) async {
    _stopTts();
    try {
      await ref.read(notificationServiceProvider).cancelAll();
    } catch (_) {}
    if (!mounted) return;

    int? selectedRating = 5;
    bool wouldRepeat = true;
    final noteController = TextEditingController();

    String ratingLabel(int? rating) {
      switch (rating) {
        case 1:
          return l10n.cookingRate1;
        case 2:
          return l10n.cookingRate2;
        case 3:
          return l10n.cookingRate3;
        case 4:
          return l10n.cookingRate4;
        case 5:
          return l10n.cookingRate5;
        default:
          return '';
      }
    }

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.cookingRateTitle,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      recipe.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),

                    // 5 Star Buttons Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (int star = 1; star <= 5; star++)
                          Semantics(
                            label: '$star ${ratingLabel(star)}',
                            button: true,
                            child: SizedBox(
                              width: 56,
                              height: 56,
                              child: IconButton(
                                iconSize: 36,
                                padding: EdgeInsets.zero,
                                icon: Icon(
                                  star <= (selectedRating ?? 0)
                                      ? Icons.star_rounded
                                      : Icons.star_outline_rounded,
                                  color: star <= (selectedRating ?? 0)
                                      ? const Color(0xFFF9A825)
                                      : theme.colorScheme.outlineVariant,
                                ),
                                onPressed: () {
                                  setModalState(() {
                                    selectedRating = star;
                                    wouldRepeat = star >= 4;
                                  });
                                },
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (selectedRating != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        ratingLabel(selectedRating),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFE65100),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Would repeat switch
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        l10n.cookingRateRepeat,
                        style: theme.textTheme.bodyLarge,
                      ),
                      value: wouldRepeat,
                      onChanged: (val) {
                        setModalState(() {
                          wouldRepeat = val;
                        });
                      },
                    ),
                    const SizedBox(height: 8),

                    // Note input
                    TextField(
                      controller: noteController,
                      style: theme.textTheme.bodyLarge,
                      decoration: InputDecoration(
                        hintText: l10n.cookingRateNoteHint,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.edit_note),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Save button
                    SizedBox(
                      height: 56,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () => Navigator.of(sheetContext).pop(true),
                        child: Text(
                          l10n.cookingRateSave,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Skip button
                    SizedBox(
                      height: 48,
                      child: TextButton(
                        onPressed: () {
                          selectedRating = null;
                          Navigator.of(sheetContext).pop(true);
                        },
                        child: Text(
                          l10n.cookingRateSkip,
                          style: theme.textTheme.bodyLarge,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (saved == true && mounted) {
      final noteText = noteController.text.trim();
      await ref
          .read(historyDaoProvider)
          .recordCooked(
            recipeId: recipe.id,
            rating: selectedRating,
            wouldRepeat: selectedRating != null ? wouldRepeat : null,
            note: noteText.isNotEmpty ? noteText : null,
          );
      ref.invalidate(historyEntriesProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.cookingSavedToHistory,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onInverseSurface,
            ),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final detailAsync = ref.watch(recipeDetailProvider(widget.recipeId));

    return detailAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(l10n.cookingScreenTitle)),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: Text(l10n.cookingScreenTitle)),
        body: Center(
          child: Text(e.toString(), style: theme.textTheme.bodyLarge),
        ),
      ),
      data: (detail) {
        if (detail == null || detail.steps.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.cookingScreenTitle)),
            body: Center(
              child: Text(
                l10n.cookingNoSteps,
                style: theme.textTheme.titleLarge,
              ),
            ),
          );
        }

        final steps = detail.steps;
        final currentStep = steps[_currentStepIndex.clamp(0, steps.length - 1)];
        final totalSteps = steps.length;
        final isFirst = _currentStepIndex == 0;
        final isLast = _currentStepIndex == totalSteps - 1;

        final timerSeconds = currentStep.timerSeconds;
        final remainingSeconds =
            _timerRemaining[_currentStepIndex] ?? timerSeconds ?? 0;
        final isTimerRunning = _timerIsRunning[_currentStepIndex] ?? false;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              detail.recipe.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              // TTS button in header
              IconButton(
                icon: Icon(
                  _isSpeaking ? Icons.volume_off : Icons.volume_up,
                  size: 28,
                ),
                tooltip: _isSpeaking
                    ? l10n.cookingTtsStop
                    : l10n.cookingTtsSpeak,
                onPressed: () => _speakText(currentStep.textContent),
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                // Step Progress Indicator
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.4,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.cookingStepProgress(
                            _currentStepIndex + 1,
                            totalSteps,
                          ),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Linear visual progress bar
                      SizedBox(
                        width: 100,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: (_currentStepIndex + 1) / totalSteps,
                            minHeight: 10,
                            backgroundColor:
                                theme.colorScheme.surfaceContainerHighest,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Main step body (28 sp text per senior UX rules)
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (isFirst) ...[
                          const Center(
                            child: AppStateIllustration(
                              assetPath: AppImages.cookingStepStart,
                              height: 140,
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                        // Giant step text 28 sp
                        Text(
                          currentStep.textContent,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontSize: AppTheme.cookingStepFontSize,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Tip if present
                        if (currentStep.tip != null &&
                            currentStep.tip!.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9A825)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFF9A825)
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.lightbulb_outline,
                                  color: Color(0xFFD84315),
                                  size: 26,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    '${l10n.recipeTipPrefix}${currentStep.tip}',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w500,
                                          height: 1.3,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Step Timer card if timer is defined for this step
                        if (timerSeconds != null && timerSeconds > 0) ...[
                          _buildTimerCard(
                            theme: theme,
                            l10n: l10n,
                            recipeTitle: detail.recipe.title,
                            stepIndex: _currentStepIndex,
                            totalSeconds: timerSeconds,
                            remainingSeconds: remainingSeconds,
                            isRunning: isTimerRunning,
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Quick TTS button right on the screen
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: Icon(
                            _isSpeaking ? Icons.volume_off : Icons.volume_up,
                            size: 24,
                          ),
                          label: Text(
                            _isSpeaking
                                ? l10n.cookingTtsStop
                                : l10n.cookingTtsSpeak,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: () => _speakText(currentStep.textContent),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom navigation buttons: «Назад» / «Дальше» (>= 56 dp)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrowOrLargeFont =
                          constraints.maxWidth < 340 ||
                          MediaQuery.textScalerOf(context).scale(1) > 1.25;

                      final prevButton = ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 56),
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: const Icon(Icons.arrow_back_rounded, size: 26),
                          label: Text(
                            l10n.cookingButtonPrevious,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: isFirst
                              ? () => Navigator.of(context).pop()
                              : () => _goToStep(_currentStepIndex - 1, steps),
                        ),
                      );

                      final nextButton = ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 56),
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            backgroundColor: isLast
                                ? const Color(0xFF2E7D32)
                                : theme.colorScheme.primary,
                          ),
                          icon: Icon(
                            isLast
                                ? Icons.check_circle_rounded
                                : Icons.arrow_forward_rounded,
                            size: 26,
                          ),
                          label: Text(
                            isLast
                                ? l10n.cookingButtonFinish
                                : l10n.cookingButtonNext,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: isLast
                              ? () => _onFinishCooking(detail.recipe, l10n)
                              : () => _goToStep(_currentStepIndex + 1, steps),
                        ),
                      );

                      if (isNarrowOrLargeFont) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            nextButton,
                            const SizedBox(height: 8),
                            prevButton,
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(child: prevButton),
                          const SizedBox(width: 12),
                          Expanded(child: nextButton),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimerCard({
    required ThemeData theme,
    required AppLocalizations l10n,
    required String recipeTitle,
    required int stepIndex,
    required int totalSeconds,
    required int remainingSeconds,
    required bool isRunning,
  }) {
    final isDone = remainingSeconds == 0;

    return Card(
      elevation: 0,
      color: isDone
          ? const Color(0xFF2E7D32).withValues(alpha: 0.15)
          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDone
              ? const Color(0xFF2E7D32)
              : isRunning
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant,
          width: isRunning ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          children: [
            // Big digital clock display
            Text(
              _formatTimerDigits(remainingSeconds),
              style: theme.textTheme.displaySmall?.copyWith(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                color: isDone
                    ? const Color(0xFF2E7D32)
                    : theme.colorScheme.primary,
              ),
            ),
            if (isDone) ...[
              const SizedBox(height: 12),
              const Center(
                child: AppStateIllustration(
                  assetPath: AppImages.cookingTimerRing,
                  height: 120,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.cookingTimerDone,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2E7D32),
                ),
              ),
            ],
            const SizedBox(height: 14),

            // Start / Pause button (one-tap start)
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: Icon(
                        isRunning
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        size: 28,
                      ),
                      label: Text(
                        isRunning
                            ? l10n.cookingTimerPause
                            : (remainingSeconds < totalSeconds && !isDone)
                            ? l10n.cookingTimerResume
                            : l10n.cookingTimerStart,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () => _toggleStepTimer(
                        stepIndex,
                        totalSeconds,
                        recipeTitle,
                      ),
                    ),
                  ),
                ),
                if (remainingSeconds < totalSeconds) ...[
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 56,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => _resetStepTimer(stepIndex, totalSeconds),
                      child: Text(
                        l10n.cookingTimerReset,
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
