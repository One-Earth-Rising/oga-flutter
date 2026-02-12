import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_inventory.dart';

class InventoryService {
  final _supabase = Supabase.instance.client;

  Stream<List<UserInventory>> getInventoryStream() {
    final user = _supabase.auth.currentUser;
    if (user == null) return const Stream.empty();

    return _supabase
        .from('user_inventory')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .order('acquired_at', ascending: false)
        .map((data) => data.map((map) => UserInventory.fromMap(map)).toList());
  }
}
