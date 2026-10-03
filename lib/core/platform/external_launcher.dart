import 'package:flutter/services.dart';

/// Opens URLs in other apps (Google Maps, browser) through a tiny platform
/// channel implemented in `MainActivity.kt` / `AppDelegate.swift` – no extra
/// packages needed.
abstract final class ExternalLauncher {
  static const MethodChannel _channel =
      MethodChannel('pl.hackyeah.jakwypije/external');

  /// Returns `true` when another app handled the URL.
  static Future<bool> openUrl(Uri url) async {
    try {
      return await _channel.invokeMethod<bool>(
            'openUrl',
            {'url': url.toString()},
          ) ??
          false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }
}
