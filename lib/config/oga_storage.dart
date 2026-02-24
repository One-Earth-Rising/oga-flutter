// ═══════════════════════════════════════════════════════════════════
// OGA STORAGE CONFIG
// Central configuration for Supabase Storage image URLs.
// Update _projectId if Supabase project changes.
// ═══════════════════════════════════════════════════════════════════

class OgaStorage {
  // ─── Supabase Project ─────────────────────────────────────
  // UPDATE THIS if you switch Supabase projects
  static const String _projectId = 'jmbzrbteizvuqwukojzu';

  // ─── Bucket Names ─────────────────────────────────────────
  static const String _characterBucket = 'characters';

  // ─── Base URL ─────────────────────────────────────────────
  static const String _storageBase =
      'https://$_projectId.supabase.co/storage/v1/object/public';

  /// Resolve a relative storage path to a full Supabase Storage URL.
  ///
  /// Usage:
  /// ```dart
  /// OgaStorage.url('heroes/ryu.png')
  /// // → https://xxx.supabase.co/storage/v1/object/public/characters/heroes/ryu.png
  /// ```
  static String url(String relativePath) {
    return '$_storageBase/$_characterBucket/$relativePath';
  }

  /// Check if a path is already a full URL (for future migration)
  static bool isFullUrl(String path) {
    return path.startsWith('http://') || path.startsWith('https://');
  }

  /// Resolve any image path — handles both relative and full URLs
  static String resolve(String path) {
    if (isFullUrl(path)) return path;
    return url(path);
  }
}
