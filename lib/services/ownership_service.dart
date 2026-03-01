// ═══════════════════════════════════════════════════════════════════
// OWNERSHIP SERVICE — Sprint 12
// Manages character ownership, tradeable status, and history.
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/oga_character.dart';
import 'character_service.dart';

/// Represents an owned character (ownership record + catalog data).
class OwnedCharacter {
  final String ownershipId;
  final String characterId;
  final String acquiredVia;
  final DateTime acquiredAt;
  final bool isLentOut;
  final OGACharacter? character; // populated from catalog

  const OwnedCharacter({
    required this.ownershipId,
    required this.characterId,
    required this.acquiredVia,
    required this.acquiredAt,
    this.isLentOut = false,
    this.character,
  });

  factory OwnedCharacter.fromMap(
    Map<String, dynamic> map, {
    OGACharacter? character,
  }) {
    return OwnedCharacter(
      ownershipId: map['id']?.toString() ?? '',
      characterId: map['character_id'] ?? '',
      acquiredVia: map['acquired_via'] ?? '',
      acquiredAt: map['acquired_at'] != null
          ? DateTime.tryParse(map['acquired_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isLentOut: map['is_lent_out'] ?? false,
      character: character,
    );
  }
}

/// Represents a borrowed character (active lend where user is borrower).
class BorrowedCharacter {
  final String lendId;
  final String characterId;
  final String lenderEmail;
  final DateTime returnDueAt;
  final OGACharacter? character;

  const BorrowedCharacter({
    required this.lendId,
    required this.characterId,
    required this.lenderEmail,
    required this.returnDueAt,
    this.character,
  });

  factory BorrowedCharacter.fromMap(
    Map<String, dynamic> map, {
    OGACharacter? character,
  }) {
    return BorrowedCharacter(
      lendId: map['id']?.toString() ?? '',
      characterId: map['character_id'] ?? '',
      lenderEmail: map['lender_email'] ?? '',
      returnDueAt: map['return_due_at'] != null
          ? DateTime.tryParse(map['return_due_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      character: character,
    );
  }
}

/// Ownership history record for timeline display.
class OwnershipRecord {
  final String ownerEmail;
  final String ownerUsername;
  final String? ownerAvatarUrl;
  final String acquiredVia;
  final DateTime acquiredAt;
  final String status; // 'active', 'traded_away', etc.

  const OwnershipRecord({
    required this.ownerEmail,
    this.ownerUsername = '',
    this.ownerAvatarUrl,
    required this.acquiredVia,
    required this.acquiredAt,
    required this.status,
  });
}

class OwnershipService {
  static final _supabase = Supabase.instance.client;
  static String? get _currentEmail => _supabase.auth.currentUser?.email;

  // ─── My Characters ────────────────────────────────────────

  /// Get all characters actively owned by the current user.
  static Future<List<OwnedCharacter>> getMyCharacters() async {
    final email = _currentEmail;
    if (email == null) return [];

    try {
      final rows = await _supabase
          .from('character_ownership')
          .select()
          .eq('owner_email', email)
          .eq('status', 'active')
          .order('acquired_at');

      final catalog = await CharacterService.getAll();
      final charMap = {for (final c in catalog) c.id: c};

      return rows.map<OwnedCharacter>((row) {
        final charId = row['character_id'] as String;
        return OwnedCharacter.fromMap(row, character: charMap[charId]);
      }).toList();
    } catch (e) {
      debugPrint('❌ OwnershipService.getMyCharacters error: $e');
      return [];
    }
  }

  /// Get characters that can be traded (owned + not lent out).
  static Future<List<OwnedCharacter>> getTradeableCharacters() async {
    final owned = await getMyCharacters();
    return owned.where((o) => !o.isLentOut).toList();
  }

  /// Get a friend's owned characters.
  static Future<List<OwnedCharacter>> getFriendCharacters(
    String friendEmail,
  ) async {
    try {
      final rows = await _supabase
          .from('character_ownership')
          .select()
          .eq('owner_email', friendEmail)
          .eq('status', 'active')
          .order('acquired_at');

      final catalog = await CharacterService.getAll();
      final charMap = {for (final c in catalog) c.id: c};

      return rows.map<OwnedCharacter>((row) {
        final charId = row['character_id'] as String;
        return OwnedCharacter.fromMap(row, character: charMap[charId]);
      }).toList();
    } catch (e) {
      debugPrint('❌ OwnershipService.getFriendCharacters error: $e');
      return [];
    }
  }

  // ─── Borrowed Characters ──────────────────────────────────

  /// Get characters currently borrowed by the current user.
  static Future<List<BorrowedCharacter>> getBorrowedCharacters() async {
    final email = _currentEmail;
    if (email == null) return [];

    try {
      final rows = await _supabase
          .from('lends')
          .select()
          .eq('borrower_email', email)
          .eq('status', 'active');

      final catalog = await CharacterService.getAll();
      final charMap = {for (final c in catalog) c.id: c};

      return rows.map<BorrowedCharacter>((row) {
        final charId = row['character_id'] as String;
        return BorrowedCharacter.fromMap(row, character: charMap[charId]);
      }).toList();
    } catch (e) {
      debugPrint('❌ OwnershipService.getBorrowedCharacters error: $e');
      return [];
    }
  }

  // ─── Ownership Checks ────────────────────────────────────

  /// Check if current user owns a specific character.
  static Future<bool> isOwned(String characterId) async {
    final email = _currentEmail;
    if (email == null) return false;

    try {
      final result = await _supabase
          .from('character_ownership')
          .select('id')
          .eq('owner_email', email)
          .eq('character_id', characterId)
          .eq('status', 'active')
          .maybeSingle();

      return result != null;
    } catch (e) {
      debugPrint('❌ OwnershipService.isOwned error: $e');
      return false;
    }
  }

  /// Check if a character is currently lent out.
  static Future<bool> isLentOut(String characterId) async {
    final email = _currentEmail;
    if (email == null) return false;

    try {
      final result = await _supabase
          .from('character_ownership')
          .select('id')
          .eq('owner_email', email)
          .eq('character_id', characterId)
          .eq('status', 'active')
          .eq('is_lent_out', true)
          .maybeSingle();

      return result != null;
    } catch (e) {
      debugPrint('❌ OwnershipService.isLentOut error: $e');
      return false;
    }
  }

  // ─── Ownership History (for detail screen timeline) ───────

  /// Get ownership history for a character (all owners, past and present).
  static Future<List<OwnershipRecord>> getCharacterHistory(
    String characterId,
  ) async {
    try {
      // Get all ownership records for this character (any status)
      final rows = await _supabase
          .from('character_ownership')
          .select('owner_email, acquired_via, acquired_at, status')
          .eq('character_id', characterId)
          .order('acquired_at');

      if (rows.isEmpty) return [];

      // Fetch profile data for all owners
      final emails = rows
          .map<String>((r) => r['owner_email'] as String)
          .toSet()
          .toList();
      final profiles = await _supabase
          .from('profiles')
          .select(
            'email, username, full_name, first_name, last_name, avatar_url',
          )
          .inFilter('email', emails);

      final profileMap = <String, Map<String, dynamic>>{};
      for (final p in profiles) {
        profileMap[p['email'] as String] = Map<String, dynamic>.from(p);
      }

      return rows.map<OwnershipRecord>((row) {
        final email = row['owner_email'] as String;
        final profile = profileMap[email];
        final username = profile?['username'] as String? ?? '';
        final firstName = profile?['first_name'] as String? ?? '';
        final lastName = profile?['last_name'] as String? ?? '';
        final fullName = profile?['full_name'] as String? ?? '';

        // Build display name
        String displayName = username.isNotEmpty
            ? '@$username'
            : '$firstName $lastName'.trim().isNotEmpty
            ? '$firstName $lastName'.trim()
            : fullName.isNotEmpty
            ? fullName
            : email.split('@').first;

        return OwnershipRecord(
          ownerEmail: email,
          ownerUsername: displayName,
          ownerAvatarUrl: profile?['avatar_url'] as String?,
          acquiredVia: row['acquired_via'] ?? '',
          acquiredAt:
              DateTime.tryParse(row['acquired_at']?.toString() ?? '') ??
              DateTime.now(),
          status: row['status'] ?? 'active',
        );
      }).toList();
    } catch (e) {
      debugPrint('❌ OwnershipService.getCharacterHistory error: $e');
      return [];
    }
  }

  // ─── Build display list (catalog + ownership overlay) ─────

  /// Merges the character catalog with per-user ownership data.
  /// This is the main method the dashboard calls.
  ///
  /// Returns ALL characters from the catalog, with `isOwned`,
  /// `isBorrowed`, and `acquiredDate` set based on the current user.
  /// Owned characters sort first, then locked.
  static Future<List<OGACharacter>> getDisplayCharacters() async {
    final catalog = await CharacterService.getAll();
    final owned = await getMyCharacters();
    final borrowed = await getBorrowedCharacters();

    final ownedMap = {for (final o in owned) o.characterId: o};
    final borrowedIds = borrowed.map((b) => b.characterId).toSet();

    final displayList = catalog.map((c) {
      final ownership = ownedMap[c.id];
      return c.copyWith(
        isOwned: ownership != null,
        isBorrowed: borrowedIds.contains(c.id),
        isLentOut: ownership?.isLentOut ?? false,
        acquiredDate: ownership?.acquiredAt,
      );
    }).toList();

    // Sort: owned first, then borrowed, then locked
    displayList.sort((a, b) {
      if (a.isOwned && !b.isOwned) return -1;
      if (!a.isOwned && b.isOwned) return 1;
      if (a.isBorrowed && !b.isBorrowed) return -1;
      if (!a.isBorrowed && b.isBorrowed) return 1;
      return 0;
    });

    return displayList;
  }
}
