import 'package:supabase_flutter/supabase_flutter.dart';

/// Congregation Territory Assignment Sync Logic
/// - Elder dashboard: list all territories, assign to publisher, set due date, reclaim
/// - Publisher: receives assigned territories via RLS, gets push via PowerSync
/// - Offline: assignments cached locally, can still work; sync when online
class AssignmentService {
  final supabase = Supabase.instance.client;

  Future<List<Map<String,dynamic>>> getCongregationTerritories(String congregationId) async {
    return await supabase.from('territories').select().eq('congregation_id', congregationId);
  }

  Future<void> assignTerritory({required String territoryId, required String publisherId, required DateTime dueDate}) async {
    await supabase.from('territories').update({
      'assigned_to': publisherId,
      'status': 'assigned',
      'due_date': dueDate.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', territoryId);
    // Trigger push notification via Supabase Edge Function
    await supabase.functions.invoke('notify-assignment', body: {'territoryId': territoryId, 'publisherId': publisherId});
  }

  Future<void> returnTerritory(String territoryId) async {
    await supabase.from('territories').update({
      'assigned_to': null,
      'status': 'available',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', territoryId);
  }

  Future<void> completeTerritory(String territoryId, String notes) async {
    await supabase.from('territories').update({
      'status': 'completed',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', territoryId);
  }
}
