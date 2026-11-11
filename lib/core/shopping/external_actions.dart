import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Actions that leave the app: the system share sheet and the browser.
///
/// Wrapped in an interface so widget tests can record calls instead of
/// talking to platform plugins.
abstract class ExternalActions {
  const ExternalActions();

  /// Opens the system «Поделиться» menu with plain text.
  Future<void> shareText(String text, {String? subject});

  /// Opens [uri] in an external app (the browser). Returns false when no
  /// app could open it.
  Future<bool> openUrl(Uri uri);
}

class PlatformExternalActions extends ExternalActions {
  const PlatformExternalActions();

  @override
  Future<void> shareText(String text, {String? subject}) async {
    await SharePlus.instance.share(ShareParams(text: text, subject: subject));
  }

  @override
  Future<bool> openUrl(Uri uri) {
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
