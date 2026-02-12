/// Simple Image Helper for Campaign Assets
/// Provides URLs for images hosted in Supabase Storage
library;

class CampaignImageHelper {
  // Your Supabase URL
  static const String supabaseUrl = 'https://mlpinkcxdsmxicipseux.supabase.co';

  // Storage bucket name
  static const String bucketName = 'campaign-assets';

  /// Get character image URL from Supabase Storage
  ///
  /// Example:
  /// ```dart
  /// final url = CampaignImageHelper.getCharacterImage('caustica');
  /// Image.network(url);
  /// ```
  static String getCharacterImage(
    String characterName, {
    String campaign = 'fbs_launch',
  }) {
    final name = characterName.toLowerCase();
    return '$supabaseUrl/storage/v1/object/public/$bucketName/$campaign/$name.png';
  }

  /// Get hero background image URL
  static String getHeroImage(
    String characterName, {
    String campaign = 'fbs_launch',
  }) {
    final name = characterName.toLowerCase();
    return '$supabaseUrl/storage/v1/object/public/$bucketName/$campaign/${name}_hero.png';
  }

  // FBS Launch specific images
  static String get causticaImage => getCharacterImage('caustica');
  static String get bigwellImage => getCharacterImage('bigwell');
  static String get brumblebuttImage => getCharacterImage('brumblebutt');
  static String get melshImage => getCharacterImage('melsh');
  static String get causticaHero => getHeroImage('caustica');
  static String get heroPromo =>
      '$supabaseUrl/storage/v1/object/public/$bucketName/fbs_launch/fbs_hero_promo.png';
}
