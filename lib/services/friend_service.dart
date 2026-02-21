import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for managing friendships and profile updates via Supabase.
class FriendService {
  static final _supabase = Supabase.instance.client;

  /// Get current user's email
  static String? get _currentEmail => _supabase.auth.currentUser?.email;

  // ═══════════════════════════════════════════════════════════
  // FRIEND QUERIES
  // ═══════════════════════════════════════════════════════════

  /// Get all accepted friends for the current user.
  /// Returns list of friend profile data with friendship metadata.
  static Future<List<FriendProfile>> getFriends() async {
    final email = _currentEmail;
    if (email == null) return [];

    try {
      // Get friendships where current user is requester
      final sent = await _supabase
          .from('friendships')
          .select()
          .eq('requester_email', email)
          .eq('status', 'accepted');

      // Get friendships where current user is receiver
      final received = await _supabase
          .from('friendships')
          .select()
          .eq('receiver_email', email)
          .eq('status', 'accepted');

      // Collect friend emails
      final friendEmails = <String>{};
      for (final f in sent) {
        friendEmails.add(f['receiver_email'] as String);
      }
      for (final f in received) {
        friendEmails.add(f['requester_email'] as String);
      }

      if (friendEmails.isEmpty) return [];

      // Fetch friend profiles
      final profiles = await _supabase
          .from('profiles')
          .select()
          .inFilter('email', friendEmails.toList());

      return profiles.map<FriendProfile>((p) {
        return FriendProfile.fromMap(p);
      }).toList();
    } catch (e) {
      debugPrint('❌ Error fetching friends: $e');
      return [];
    }
  }

  /// Get pending friend requests received by current user.
  static Future<List<FriendProfile>> getPendingRequests() async {
    final email = _currentEmail;
    if (email == null) return [];

    try {
      final pending = await _supabase
          .from('friendships')
          .select()
          .eq('receiver_email', email)
          .eq('status', 'pending');

      final requesterEmails = pending
          .map<String>((f) => f['requester_email'] as String)
          .toList();

      if (requesterEmails.isEmpty) return [];

      final profiles = await _supabase
          .from('profiles')
          .select()
          .inFilter('email', requesterEmails);

      return profiles.map<FriendProfile>((p) {
        return FriendProfile.fromMap(p, isPending: true);
      }).toList();
    } catch (e) {
      debugPrint('❌ Error fetching pending requests: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════
  // INVITE CODE
  // ═══════════════════════════════════════════════════════════

  /// Look up a user by invite code.
  /// Returns profile data or null if not found.
  static Future<FriendProfile?> findByInviteCode(String code) async {
    final trimmed = code.trim().toUpperCase();
    if (trimmed.isEmpty) return null;

    try {
      final result = await _supabase
          .from('profiles')
          .select()
          .eq('invite_code', trimmed)
          .maybeSingle();

      if (result == null) return null;

      // Don't return self
      if (result['email'] == _currentEmail) return null;

      return FriendProfile.fromMap(result);
    } catch (e) {
      debugPrint('❌ Error looking up invite code: $e');
      return null;
    }
  }

  /// Get current user's invite code.
  static Future<String?> getMyInviteCode() async {
    final email = _currentEmail;
    if (email == null) return null;

    try {
      final result = await _supabase
          .from('profiles')
          .select('invite_code')
          .eq('email', email)
          .maybeSingle();

      return result?['invite_code'] as String?;
    } catch (e) {
      debugPrint('❌ Error getting invite code: $e');
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // PUBLIC INVITE FLOW (works without auth)
  // ═══════════════════════════════════════════════════════════

  /// Look up a profile by invite code — works for unauthenticated guests.
  /// Returns only safe public fields (no email exposed to guest UI).
  static Future<InviterProfile?> getPublicProfile(String inviteCode) async {
    final trimmed = inviteCode.trim().toUpperCase();
    if (trimmed.isEmpty) return null;

    try {
      final result = await _supabase
          .from('profiles')
          .select(
            'full_name, first_name, last_name, username, avatar_url, '
            'starter_character, invite_code, created_at',
          )
          .eq('invite_code', trimmed)
          .maybeSingle();

      if (result == null) return null;

      return InviterProfile(
        firstName: result['first_name'] as String? ?? '',
        lastName: result['last_name'] as String? ?? '',
        fullName: result['full_name'] as String? ?? '',
        username: result['username'] as String? ?? '',
        avatarUrl: result['avatar_url'] as String?,
        starterCharacter: result['starter_character'] as String?,
        inviteCode: result['invite_code'] as String? ?? '',
        createdAt: result['created_at'] != null
            ? DateTime.tryParse(result['created_at'].toString())
            : null,
      );
    } catch (e) {
      debugPrint('❌ Error fetching public profile: $e');
      return null;
    }
  }

  /// Set the invited_by field on the current user's profile.
  /// Call this after signup when the user was invited via code.
  static Future<bool> setInvitedBy(String inviteCode) async {
    final email = _currentEmail;
    if (email == null) return false;

    try {
      await _supabase
          .from('profiles')
          .update({'invited_by': inviteCode.trim().toUpperCase()})
          .eq('email', email);

      return true;
    } catch (e) {
      debugPrint('❌ Error setting invited_by: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // FRIEND ACTIONS
  // ═══════════════════════════════════════════════════════════

  /// Send a friend request to another user by email.
  static Future<bool> sendFriendRequest(String friendEmail) async {
    final email = _currentEmail;
    if (email == null || friendEmail == email) return false;

    try {
      // Check if friendship already exists (either direction)
      final existing = await _supabase
          .from('friendships')
          .select()
          .or(
            'and(requester_email.eq.$email,receiver_email.eq.$friendEmail),'
            'and(requester_email.eq.$friendEmail,receiver_email.eq.$email)',
          );

      if (existing.isNotEmpty) {
        debugPrint('⚠️ Friendship already exists');
        return false;
      }

      await _supabase.from('friendships').insert({
        'requester_email': email,
        'receiver_email': friendEmail,
        'status': 'pending',
      });

      return true;
    } catch (e) {
      debugPrint('❌ Error sending friend request: $e');
      return false;
    }
  }

  /// Accept a pending friend request.
  static Future<bool> acceptRequest(String requesterEmail) async {
    final email = _currentEmail;
    if (email == null) return false;

    try {
      await _supabase
          .from('friendships')
          .update({
            'status': 'accepted',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('requester_email', requesterEmail)
          .eq('receiver_email', email);

      return true;
    } catch (e) {
      debugPrint('❌ Error accepting request: $e');
      return false;
    }
  }

  /// Decline a pending friend request.
  static Future<bool> declineRequest(String requesterEmail) async {
    final email = _currentEmail;
    if (email == null) return false;

    try {
      await _supabase
          .from('friendships')
          .delete()
          .eq('requester_email', requesterEmail)
          .eq('receiver_email', email);

      return true;
    } catch (e) {
      debugPrint('❌ Error declining request: $e');
      return false;
    }
  }

  /// Remove a friend (unfriend).
  static Future<bool> removeFriend(String friendEmail) async {
    final email = _currentEmail;
    if (email == null) return false;

    try {
      // Delete in both directions
      await _supabase
          .from('friendships')
          .delete()
          .or(
            'and(requester_email.eq.$email,receiver_email.eq.$friendEmail),'
            'and(requester_email.eq.$friendEmail,receiver_email.eq.$email)',
          );

      return true;
    } catch (e) {
      debugPrint('❌ Error removing friend: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // PROFILE UPDATES
  // ═══════════════════════════════════════════════════════════

  /// Update profile fields.
  static Future<bool> updateProfile({
    String? fullName,
    String? firstName,
    String? lastName,
    String? username,
    String? bio,
    String? location,
  }) async {
    final email = _currentEmail;
    if (email == null) return false;

    try {
      final updates = <String, dynamic>{};
      if (fullName != null) updates['full_name'] = fullName;
      if (firstName != null) updates['first_name'] = firstName;
      if (lastName != null) updates['last_name'] = lastName;
      if (username != null) updates['username'] = username;
      if (bio != null) updates['bio'] = bio;
      if (location != null) updates['location'] = location;

      if (updates.isEmpty) return true;

      await _supabase.from('profiles').update(updates).eq('email', email);

      return true;
    } catch (e) {
      debugPrint('❌ Error updating profile: $e');
      return false;
    }
  }

  /// Upload avatar image and save URL to profile.
  /// [imageBytes] is the raw image data.
  /// [fileName] is the original file name (for extension detection).
  static Future<String?> uploadAvatar(
    Uint8List imageBytes,
    String fileName,
  ) async {
    final email = _currentEmail;
    if (email == null) return null;

    try {
      // Use email hash as folder to avoid conflicts
      final ext = fileName.split('.').last.toLowerCase();
      final validExt = ['png', 'jpg', 'jpeg', 'webp'].contains(ext)
          ? ext
          : 'png';
      final path = '${email.hashCode.abs()}/avatar.$validExt';

      // Upload to Supabase Storage
      await _supabase.storage
          .from('avatars')
          .uploadBinary(
            path,
            imageBytes,
            fileOptions: FileOptions(
              upsert: true,
              contentType: 'image/$validExt',
            ),
          );

      // Get public URL
      final publicUrl =
          '${_supabase.storage.from('avatars').getPublicUrl(path)}?v=${DateTime.now().millisecondsSinceEpoch}';

      // Save to profile
      await _supabase
          .from('profiles')
          .update({'avatar_url': publicUrl})
          .eq('email', email);

      return publicUrl;
    } catch (e) {
      debugPrint('❌ Error uploading avatar: $e');
      return null;
    }
  }
}

/// Friend profile data model.
class FriendProfile {
  final String email;
  final String name;
  final String? avatarUrl;
  final String? starterCharacter;
  final String? inviteCode;
  final String? bio;
  final DateTime? createdAt;
  final bool isPending;

  const FriendProfile({
    required this.email,
    required this.name,
    this.avatarUrl,
    this.starterCharacter,
    this.inviteCode,
    this.bio,
    this.createdAt,
    this.isPending = false,
  });

  factory FriendProfile.fromMap(
    Map<String, dynamic> map, {
    bool isPending = false,
  }) {
    return FriendProfile(
      email: map['email'] as String? ?? '',
      name: map['full_name'] as String? ?? 'Player',
      avatarUrl: map['avatar_url'] as String?,
      starterCharacter: map['starter_character'] as String?,
      inviteCode: map['invite_code'] as String?,
      bio: map['bio'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
      isPending: isPending,
    );
  }

  /// Get the character color for this friend's starter character.
  Color get characterColor {
    switch (starterCharacter?.toLowerCase()) {
      case 'vegeta':
        return const Color(0xFF2563EB);
      case 'ryu':
        return const Color(0xFFDC2626);
      case 'guggimon':
        return const Color(0xFF7C3AED);
      default:
        return const Color(0xFF39FF14);
    }
  }
}

/// Public inviter profile — safe for guest display (no email).
class InviterProfile {
  final String firstName;
  final String lastName;
  final String fullName;
  final String username;
  final String? avatarUrl;
  final String? starterCharacter;
  final String inviteCode;
  final DateTime? createdAt;

  const InviterProfile({
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.username,
    this.avatarUrl,
    this.starterCharacter,
    required this.inviteCode,
    this.createdAt,
  });

  String get displayName {
    final name = '$firstName $lastName'.trim();
    return name.isNotEmpty ? name : fullName;
  }

  Color get characterColor {
    switch (starterCharacter?.toLowerCase()) {
      case 'vegeta':
        return const Color(0xFF2563EB);
      case 'ryu':
        return const Color(0xFFDC2626);
      case 'guggimon':
        return const Color(0xFF7C3AED);
      default:
        return const Color(0xFF39FF14);
    }
  }
}
