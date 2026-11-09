import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'ui_profile.dart';

/// Service managing persistent storage and logic for [UiProfile].
class UiProfileService {
  final File? _file;
  UiProfile _current;

  UiProfileService([this._file]) : _current = UiProfile.defaultSimple();

  UiProfile get current => _current;

  /// Loads the profile from disk or defaults.
  Future<UiProfile> loadProfile() async {
    try {
      final file = await _resolveFile();
      if (file != null && await file.exists()) {
        final content = await file.readAsString();
        if (content.trim().isNotEmpty) {
          final json = jsonDecode(content) as Map<String, dynamic>;
          _current = UiProfile.fromJson(json);
          return _current;
        }
      }
    } catch (e) {
      debugPrint('UiProfileService.loadProfile error: $e');
    }
    return _current;
  }

  /// Saves the profile to disk.
  Future<void> saveProfile(UiProfile profile) async {
    _current = profile;
    try {
      final file = await _resolveFile();
      if (file != null) {
        await file.parent.create(recursive: true);
        await file.writeAsString(jsonEncode(profile.toJson()));
      }
    } catch (e) {
      debugPrint('UiProfileService.saveProfile error: $e');
    }
  }

  /// Evaluates whether to suggest Full mode to a user in Simple mode.
  /// Suggested at most once per 30 days if user regularly filters/searches.
  bool shouldPromptFullMode({
    required int searchAndFilterCount,
    required DateTime now,
  }) {
    if (_current.mode == UiMode.full) return false;
    if (_current.suppressModePrompt) return false;
    if (searchAndFilterCount < 10) return false;

    final last = _current.lastModePromptDate;
    if (last != null && now.difference(last).inDays < 30) {
      return false;
    }
    return true;
  }

  /// Evaluates whether to suggest Simple mode to a user in Full mode
  /// when system font scale is enlarged (>= 1.3).
  bool shouldPromptSimpleMode({
    required double systemFontScale,
    required DateTime now,
  }) {
    if (_current.mode == UiMode.simple) return false;
    if (_current.suppressModePrompt) return false;
    if (systemFontScale < 1.3) return false;

    final last = _current.lastModePromptDate;
    if (last != null && now.difference(last).inDays < 30) {
      return false;
    }
    return true;
  }

  /// Records that a mode prompt was presented.
  Future<void> recordModePromptPresented({
    required DateTime now,
    bool suppressForever = false,
  }) async {
    final updated = _current.copyWith(
      lastModePromptDate: now,
      suppressModePrompt: suppressForever ? true : _current.suppressModePrompt,
    );
    await saveProfile(updated);
  }

  /// Export for backup JSON.
  Map<String, dynamic> exportData() => _current.toJson();

  /// Import from backup JSON.
  Future<void> importData(Map<String, dynamic> json) async {
    final profile = UiProfile.fromJson(json);
    await saveProfile(profile);
  }

  Future<File?> _resolveFile() async {
    if (_file != null) return _file;
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return null;
    }
    try {
      final dir = await getApplicationDocumentsDirectory();
      return File('${dir.path}/ui_profile.json');
    } catch (_) {
      // In tests or headless where path_provider is not mocked.
      return null;
    }
  }
}
