/// OneSignal configuration for BookNBytes cross-platform push notifications.
///
/// NOTE: The REST API key is stored securely in Supabase Edge Function secrets
/// and is never bundled into client applications.
class OneSignalConfig {
  OneSignalConfig._();

  /// OneSignal App ID (Client-side identifier)
  static const String appId = '0aa2c7f5-ea36-478d-91af-a74e0a756cdb';

  static bool get isConfigured =>
      appId.isNotEmpty &&
      appId != 'ONESIGNAL_APP_ID_PLACEHOLDER' &&
      !appId.startsWith('YOUR_');
}
