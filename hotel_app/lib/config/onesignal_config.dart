/// OneSignal configuration for BookNBytes cross-platform push notifications.
/// Replace placeholder values with your actual OneSignal App ID and REST API Key
/// obtained from https://dashboard.onesignal.com -> Settings -> Keys & IDs.
class OneSignalConfig {
  OneSignalConfig._();

  /// OneSignal App ID (Client-side)
  static const String appId = 'ONESIGNAL_APP_ID_PLACEHOLDER';

  /// OneSignal REST API Key (Used by Supabase Edge Functions / Backend Webhooks)
  static const String restApiKey = 'ONESIGNAL_REST_API_KEY_PLACEHOLDER';

  static bool get isConfigured =>
      appId.isNotEmpty &&
      appId != 'ONESIGNAL_APP_ID_PLACEHOLDER' &&
      !appId.startsWith('YOUR_');
}
