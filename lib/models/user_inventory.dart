class UserInventory {
  final String id;
  final String userId;
  final String characterId; // Matches 'caustica', 'zoro', etc.
  final DateTime acquiredAt;
  final String? source; // e.g., 'fbs_launch'

  UserInventory({
    required this.id,
    required this.userId,
    required this.characterId,
    required this.acquiredAt,
    this.source,
  });

  // Convert Supabase Map to UserInventory Object
  factory UserInventory.fromMap(Map<String, dynamic> map) {
    return UserInventory(
      id: map['id'],
      userId: map['user_id'],
      characterId: map['character_id'],
      acquiredAt: DateTime.parse(map['acquired_at']),
      source: map['source'],
    );
  }
}
