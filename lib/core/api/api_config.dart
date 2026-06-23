import 'package:flutter/foundation.dart';

/// Resolves the base URL of the Badar Tyres mock API.
///
/// - Android emulator reaches the host machine via `10.0.2.2`.
/// - Web / desktop / iOS simulator use `localhost`.
/// - Override at build time with
///   `--dart-define=API_BASE_URL=http://<host>:3000/api` (handy for physical
///   devices), or programmatically via [overrideBaseUrl].
abstract final class BadarApiConfig {
  const BadarApiConfig._();

  static const String _defineBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// Optional runtime override (takes precedence over everything else).
  static String? overrideBaseUrl;

  static String get baseUrl {
    if (overrideBaseUrl != null && overrideBaseUrl!.isNotEmpty) {
      return overrideBaseUrl!;
    }
    if (_defineBaseUrl.isNotEmpty) return _defineBaseUrl;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      // Updated to your laptop's Wi-Fi IP address so the physical device can connect over the local network.
      // (10.0.2.2 only works for Android Emulators)
      return 'http://10.25.163.209:3000/api';
    }
    return 'http://localhost:3000/api';
  }
}
