class SupabaseConfig {
  static const String url = 'https://zmbutpslrmbrqncuiowr.supabase.co';
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InptYnV0cHNscm1icnFuY3Vpb3dyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTMxMjM1MDUsImV4cCI6MjEwODY5OTUwNX0.lViAWCu7qNUdpgWa-3vjguZ0KS32IfB0TyLKJeFsIc8';
  static const String serviceRoleKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InptYnV0cHNscm1icnFuY3Vpb3dyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc5MzEyMzUwNSwiZXhwIjoyMTA4Njk5NTA1fQ.8BI7ssPAeY2CAtca1F3tCfHC1w1wt-rd4ssYM59sGkM';

  // Edge Function endpoints
  static const String fnSignupOwner = '$url/functions/v1/signup-owner';
  static const String fnActivateRestaurant = '$url/functions/v1/activate-restaurant';
  static const String fnUpdateManagerPassword = '$url/functions/v1/update-manager-password';
  static const String fnSignupDiner = '$url/functions/v1/signup-diner';
}
