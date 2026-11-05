import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('S6-02 Branding, Icon, Splash and App Name', () {
    test('AndroidManifest.xml points to @string/app_name', () {
      final manifestFile = File('android/app/src/main/AndroidManifest.xml');
      expect(manifestFile.existsSync(), isTrue);
      final content = manifestFile.readAsStringSync();
      expect(content.contains('android:label="@string/app_name"'), isTrue);
    });

    test('strings.xml defines app_name as "Что приготовить?"', () {
      final stringsFile = File('android/app/src/main/res/values/strings.xml');
      expect(stringsFile.existsSync(), isTrue);
      final content = stringsFile.readAsStringSync();
      expect(
        content.contains('<string name="app_name">Что приготовить?</string>'),
        isTrue,
      );
    });

    test('colors.xml defines brand icon background #226440 and splash', () {
      final colorsFile = File('android/app/src/main/res/values/colors.xml');
      expect(colorsFile.existsSync(), isTrue);
      final content = colorsFile.readAsStringSync();
      expect(
        content.contains(
          '<color name="ic_launcher_background">#226440</color>',
        ),
        isTrue,
      );
      expect(
        content.contains('<color name="splash_background">#F9F9F6</color>'),
        isTrue,
      );
      expect(
        content.contains(
          '<color name="splash_background_dark">#121413</color>',
        ),
        isTrue,
      );
    });

    test('adaptive icon definition exists for Android 8.0+ (API 26+)', () {
      final adaptiveXml = File(
        'android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml',
      );
      expect(adaptiveXml.existsSync(), isTrue);
      final content = adaptiveXml.readAsStringSync();
      expect(
        content.contains('android:drawable="@color/ic_launcher_background"'),
        isTrue,
      );
      expect(
        content.contains('android:drawable="@mipmap/ic_launcher_foreground"'),
        isTrue,
      );
      expect(
        content.contains('android:drawable="@mipmap/ic_launcher_monochrome"'),
        isTrue,
      );
    });

    test('all density mipmap icons exist and are non-empty', () {
      final densities = [
        'mipmap-mdpi',
        'mipmap-hdpi',
        'mipmap-xhdpi',
        'mipmap-xxhdpi',
        'mipmap-xxxhdpi',
      ];

      for (final density in densities) {
        final launcher = File(
          'android/app/src/main/res/$density/ic_launcher.png',
        );
        final fg = File(
          'android/app/src/main/res/$density/ic_launcher_foreground.png',
        );
        final mono = File(
          'android/app/src/main/res/$density/ic_launcher_monochrome.png',
        );

        expect(
          launcher.existsSync() && launcher.lengthSync() > 0,
          isTrue,
          reason: '$density ic_launcher.png missing or empty',
        );
        expect(
          fg.existsSync() && fg.lengthSync() > 0,
          isTrue,
          reason: '$density ic_launcher_foreground.png missing or empty',
        );
        expect(
          mono.existsSync() && mono.lengthSync() > 0,
          isTrue,
          reason: '$density ic_launcher_monochrome.png missing or empty',
        );
      }
    });

    test('splash screen drawables and XML definitions exist', () {
      final splashDrawables = [
        'drawable/splash_icon.png',
        'drawable-mdpi/splash_icon.png',
        'drawable-hdpi/splash_icon.png',
        'drawable-xhdpi/splash_icon.png',
        'drawable-xxhdpi/splash_icon.png',
        'drawable-xxxhdpi/splash_icon.png',
      ];

      for (final splash in splashDrawables) {
        final file = File('android/app/src/main/res/$splash');
        expect(
          file.existsSync() && file.lengthSync() > 0,
          isTrue,
          reason: '$splash missing or empty',
        );
      }

      final launchBg = File(
        'android/app/src/main/res/drawable/launch_background.xml',
      );
      expect(launchBg.existsSync(), isTrue);
      expect(
        launchBg.readAsStringSync().contains('@drawable/splash_icon'),
        isTrue,
      );

      final launchBgNight = File(
        'android/app/src/main/res/drawable-night/launch_background.xml',
      );
      expect(launchBgNight.existsSync(), isTrue);
      expect(
        launchBgNight.readAsStringSync().contains('@drawable/splash_icon'),
        isTrue,
      );
    });

    test('notification icon exists in drawable', () {
      final notifIcon = File(
        'android/app/src/main/res/drawable/ic_notification.png',
      );
      expect(notifIcon.existsSync() && notifIcon.lengthSync() > 0, isTrue);
    });
  });
}
