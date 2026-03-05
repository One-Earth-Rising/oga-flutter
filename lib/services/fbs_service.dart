// lib/services/fbs_service.dart
// Sprint 17 — FBS Code Redemption
// Handles candy code validation and character unlock via Supabase RPC.

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Result model for a redeem attempt
class FbsRedeemResult {
  final bool success;
  final String? characterId;
  final FbsRedeemError? error;

  const FbsRedeemResult({required this.success, this.characterId, this.error});
}

enum FbsRedeemError {
  invalidCode,
  alreadyRedeemed,
  characterAlreadyOwned,
  notAuthenticated,
  networkError,
  unknown,
}

// FBS character metadata for display in Portal Pass
class FbsCharacter {
  final String id;
  final String name;
  final String flavor; // short tagline shown on locked card
  final String imageUrl; // path in Supabase Storage or assets/
  bool isOwned;

  FbsCharacter({
    required this.id,
    required this.name,
    required this.flavor,
    required this.imageUrl,
    this.isOwned = false,
  });
}

class FbsService {
  static final _supabase = Supabase.instance.client;

  // All FBS characters available via candy redemption
  static List<FbsCharacter> get allFbsCharacters => [
    FbsCharacter(
      id: 'melsh',
      name: 'MELSH',
      flavor: 'The sweet destroyer',
      imageUrl: 'assets/characters/fbs/melsh.png',
    ),
    FbsCharacter(
      id: 'caustica',
      name: 'CAUSTICA',
      flavor: 'Acid-tongued and unstoppable',
      imageUrl: 'assets/characters/fbs/caustica.png',
    ),
    FbsCharacter(
      id: 'brumblebutt',
      name: 'BRUMBLEBUTT',
      flavor: 'Chaos in a small package',
      imageUrl: 'assets/characters/fbs/brumblebutt.png',
    ),
    FbsCharacter(
      id: 'bigwell',
      name: 'BIGWELL',
      flavor: 'Slow to start, impossible to stop',
      imageUrl: 'assets/characters/fbs/bigwell.png',
    ),
  ];

  /// Redeem a candy code. Calls the atomic Supabase RPC.
  /// Returns [FbsRedeemResult] with success/character or error type.
  static Future<FbsRedeemResult> redeemCode(String rawCode) async {
    final code = rawCode.trim().toUpperCase();
    if (code.isEmpty) {
      return const FbsRedeemResult(
        success: false,
        error: FbsRedeemError.invalidCode,
      );
    }

    try {
      final response = await _supabase.rpc(
        'redeem_fbs_code',
        params: {'p_code': code},
      );

      debugPrint('[FbsService] redeemCode response: $response');

      final data = response as Map<String, dynamic>;
      final success = data['success'] as bool? ?? false;

      if (success) {
        return FbsRedeemResult(
          success: true,
          characterId: data['character_id'] as String?,
        );
      } else {
        final errorStr = data['error'] as String? ?? 'unknown';
        return FbsRedeemResult(success: false, error: _parseError(errorStr));
      }
    } catch (e) {
      debugPrint('[FbsService] redeemCode exception: $e');
      return const FbsRedeemResult(
        success: false,
        error: FbsRedeemError.networkError,
      );
    }
  }

  /// Load which FBS characters the current user owns.
  /// Returns list of character IDs with isOwned = true.
  static Future<List<FbsCharacter>> loadFbsCharactersForUser() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return allFbsCharacters;

    try {
      final owned = await _supabase
          .from('character_ownership')
          .select('character_id')
          .eq('owner_email', user.email!)
          .eq('status', 'active')
          .inFilter('character_id', allFbsCharacters.map((c) => c.id).toList());

      final ownedIds = (owned as List)
          .map((row) => row['character_id'] as String)
          .toSet();

      return allFbsCharacters.map((c) {
        c.isOwned = ownedIds.contains(c.id);
        return c;
      }).toList();
    } catch (e) {
      debugPrint('[FbsService] loadFbsCharactersForUser error: $e');
      return allFbsCharacters;
    }
  }

  static FbsRedeemError _parseError(String errorStr) {
    switch (errorStr) {
      case 'invalid_code':
        return FbsRedeemError.invalidCode;
      case 'already_redeemed':
        return FbsRedeemError.alreadyRedeemed;
      case 'character_already_owned':
        return FbsRedeemError.characterAlreadyOwned;
      case 'not_authenticated':
        return FbsRedeemError.notAuthenticated;
      default:
        return FbsRedeemError.unknown;
    }
  }

  /// Human-readable error message for display in the modal
  static String errorMessage(FbsRedeemError error) {
    switch (error) {
      case FbsRedeemError.invalidCode:
        return 'That code doesn\'t exist. Check the packaging and try again.';
      case FbsRedeemError.alreadyRedeemed:
        return 'This code has already been used. Each code unlocks one character.';
      case FbsRedeemError.characterAlreadyOwned:
        return 'This character is already in someone\'s library. Codes are unique.';
      case FbsRedeemError.notAuthenticated:
        return 'Please sign in to redeem a code.';
      case FbsRedeemError.networkError:
        return 'Connection error. Check your internet and try again.';
      case FbsRedeemError.unknown:
        return 'Something went wrong. Please try again.';
    }
  }
}
