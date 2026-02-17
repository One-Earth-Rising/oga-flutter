/// Environment configuration for OGA Web Showcase
///
/// Controls which Supabase project and base URLs are used based on the build environment.
///
/// USAGE:
/// 1. For local development: Set to Environment.development
/// 2. For staging deploys: Set to Environment.staging
/// 3. For production deploys: Set to Environment.production
///
/// IMPORTANT: Change the `current` value before building for different environments.

enum Environment {
  development, // localhost:3000
  staging, // staging-oga.netlify.app or Netlify branch deploys
  production, // oga.oneearthrising.com
}

class EnvironmentConfig {
  /// ⚠️ CHANGE THIS BEFORE BUILDING ⚠️
  ///
  /// - development: Local testing on localhost:3000
  /// - staging: Netlify staging site with test Supabase data
  /// - production: Live site with production Supabase data
  static const Environment current = Environment.development;

  /// Returns true if running in production
  static bool get isProduction => current == Environment.production;

  /// Returns true if running in staging
  static bool get isStaging => current == Environment.staging;

  /// Returns true if running in development
  static bool get isDevelopment => current == Environment.development;

  /// Supabase Project URL
  ///
  /// STAGING: Your current project (mlpinkcxdsmxicipseux)
  /// PRODUCTION: Create new Supabase project and update this URL
  static String get supabaseUrl {
    switch (current) {
      case Environment.development:
      case Environment.staging:
        // Current Supabase project - becomes staging environment
        return 'https://mlpinkcxdsmxicipseux.supabase.co';

      case Environment.production:
        // TODO: Replace with production Supabase project URL
        // Create new project at https://supabase.com/dashboard
        return 'https://jmbzrbteizvuqwukojzu.supabase.co';
    }
  }

  /// Supabase Anonymous Key (public key, safe to expose)
  ///
  /// Find these in Supabase Dashboard → Settings → API
  static String get supabaseAnonKey {
    switch (current) {
      case Environment.development:
      case Environment.staging:
        // Current staging anon key
        return 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1scGlua2N4ZHNteGljaXBzZXV4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njc4MTI4MDAsImV4cCI6MjA4MzM4ODgwMH0.iX7By6rcSDrQ13reRrZ12C5SfHGOkKDvEOfI2dxfuDA ';

      case Environment.production:
        // TODO: Replace with production Supabase anon key
        return 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImptYnpyYnRlaXp2dXF3dWtvanp1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzEyNzgwOTIsImV4cCI6MjA4Njg1NDA5Mn0.Gqu3FeNnhU0X58skdhhX4woSqpk5jVd_mJ2ELxT5bGg';
    }
  }

  /// Base URL for the application
  ///
  /// Used for:
  /// - Supabase auth redirects
  /// - Invite link generation (/#/invite/OGA-XXXX)
  /// - Email template URLs
  static String get baseUrl {
    switch (current) {
      case Environment.development:
        return 'http://localhost:3000';

      case Environment.staging:
        // Update this after setting up Netlify staging site
        return 'https://staging-oga.netlify.app';

      case Environment.production:
        return 'https://oga.oneearthrising.com';
    }
  }

  /// Display name for current environment (for debugging)
  static String get environmentName {
    switch (current) {
      case Environment.development:
        return 'Development';
      case Environment.staging:
        return 'Staging';
      case Environment.production:
        return 'Production';
    }
  }

  /// Enable debug logging (off in production)
  static bool get enableDebugLogging {
    return current != Environment.production;
  }

  /// Supabase auth redirect URL
  ///
  /// This is what gets set in Supabase Dashboard → Authentication → URL Configuration
  static String get authRedirectUrl {
    return '$baseUrl/#/confirm';
  }

  /// Print environment info to console (for debugging)
  static void printEnvironmentInfo() {
    if (enableDebugLogging) {
      print('╔════════════════════════════════════════════════════════════╗');
      print('║  OGA Web Showcase - Environment Configuration              ║');
      print('╠════════════════════════════════════════════════════════════╣');
      print('║  Environment: $environmentName');
      print('║  Base URL: $baseUrl');
      print('║  Supabase: ${supabaseUrl.substring(0, 40)}...');
      print('║  Debug Logging: ${enableDebugLogging ? "ENABLED" : "DISABLED"}');
      print('╚════════════════════════════════════════════════════════════╝');
    }
  }
}

/// Helper function to get environment-specific invite URL
String getInviteUrl(String inviteCode) {
  return '${EnvironmentConfig.baseUrl}/#/invite/$inviteCode';
}

/// Helper function to get environment-specific join URL
String getJoinUrl(String inviteCode) {
  return '${EnvironmentConfig.baseUrl}/#/join?code=$inviteCode';
}
