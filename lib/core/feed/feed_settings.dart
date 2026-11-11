import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Feed switches from the settings screen (R7-10).
@immutable
class FeedSettings {
  const FeedSettings({
    this.considerHolidays = true,
    this.considerFasts = false,
    this.showNew = true,
  });

  /// Use the offline holiday calendar for the «К празднику» row and reasons.
  final bool considerHolidays;

  /// On fasting days keep only lenten dishes in the feed.
  final bool considerFasts;

  /// Give some places to dishes outside the profile («Попробуйте новое»).
  final bool showNew;

  FeedSettings copyWith({
    bool? considerHolidays,
    bool? considerFasts,
    bool? showNew,
  }) {
    return FeedSettings(
      considerHolidays: considerHolidays ?? this.considerHolidays,
      considerFasts: considerFasts ?? this.considerFasts,
      showNew: showNew ?? this.showNew,
    );
  }

  Map<String, Object?> toJson() => {
    'consider_holidays': considerHolidays,
    'consider_fasts': considerFasts,
    'show_new': showNew,
  };

  factory FeedSettings.fromJson(Map<String, dynamic> json) {
    const defaults = FeedSettings();
    return FeedSettings(
      considerHolidays:
          json['consider_holidays'] as bool? ?? defaults.considerHolidays,
      considerFasts: json['consider_fasts'] as bool? ?? defaults.considerFasts,
      showNew: json['show_new'] as bool? ?? defaults.showNew,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is FeedSettings &&
      other.considerHolidays == considerHolidays &&
      other.considerFasts == considerFasts &&
      other.showNew == showNew;

  @override
  int get hashCode => Object.hash(considerHolidays, considerFasts, showNew);
}

/// Stores [FeedSettings] in `feed_settings.json` in the app documents folder.
///
/// Same approach as `UiProfileService`: a missing or broken file gives the
/// defaults, and a failed write keeps the value in memory.
class FeedSettingsService {
  FeedSettingsService([this._file]);

  final File? _file;
  FeedSettings _current = const FeedSettings();

  FeedSettings get current => _current;

  Future<FeedSettings> load() async {
    try {
      final file = await _resolveFile();
      if (file != null && await file.exists()) {
        final content = await file.readAsString();
        if (content.trim().isNotEmpty) {
          _current = FeedSettings.fromJson(
            jsonDecode(content) as Map<String, dynamic>,
          );
        }
      }
    } catch (error) {
      debugPrint('FeedSettingsService.load error: $error');
    }
    return _current;
  }

  Future<void> save(FeedSettings settings) async {
    _current = settings;
    try {
      final file = await _resolveFile();
      if (file != null) {
        await file.parent.create(recursive: true);
        await file.writeAsString(jsonEncode(settings.toJson()));
      }
    } catch (error) {
      debugPrint('FeedSettingsService.save error: $error');
    }
  }

  Future<File?> _resolveFile() async {
    final file = _file;
    if (file != null) return file;
    try {
      final dir = await getApplicationDocumentsDirectory();
      return File('${dir.path}/feed_settings.json');
    } catch (_) {
      // No path provider (unit tests): keep the settings in memory only.
      return null;
    }
  }
}
