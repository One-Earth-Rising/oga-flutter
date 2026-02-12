import 'package:flutter/material.dart';

/// Campaign configuration model
/// Defines settings and metadata for each campaign variant
class CampaignConfig {
  final String id;
  final String name;
  final Color primaryColor;
  final String heroImage;
  final List<String> characters;

  const CampaignConfig({
    required this.id,
    required this.name,
    required this.primaryColor,
    required this.heroImage,
    required this.characters,
  });

  // Main (default) campaign
  static const main = CampaignConfig(
    id: 'main',
    name: 'OGA',
    primaryColor: Color(0xFF00C806),
    heroImage: 'assets/heroes/hero.png',
    characters: ['ryu', 'vegeta', 'guggimon'],
  );

  // FBS Launch campaign
  static const fbs = CampaignConfig(
    id: 'fbs_launch',
    name: 'FBS Launch',
    primaryColor: Color(0xFFFF4400),
    heroImage: 'assets/campaigns/fbs_launch/caustica_hero.png',
    characters: ['caustica', 'browbill', 'brimblebutt'],
  );

  /// Get campaign config by ID, defaults to main
  static CampaignConfig fromId(String? id) {
    return id == 'fbs_launch' ? fbs : main;
  }
}
