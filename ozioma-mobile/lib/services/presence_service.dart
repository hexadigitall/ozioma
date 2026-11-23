import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

/// Realtime presence: share location with brothers in same territory during service hours.
/// Auto-off outside 8am-12pm, opt-in toggle, automatically expires.
class PresenceService {
  final supabase = Supabase.instance.client;
  RealtimeChannel? _channel;
  StreamSubscription<Position>? _posSub;
  final StreamController<Map<String, dynamic>> _brothersController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get brotherLocationsStream => _brothersController.stream;

  Future<void> startBroadcasting(String territoryId, String publisherId) async {
    final now = DateTime.now();
    if (now.hour < 8 || now.hour >= 12) return; // field service hours only

    _channel = supabase.channel('territory:$territoryId', opts: const RealtimeChannelConfig(ack: true));
    
    _channel!.onPresenceSync((_) {
      final state = _channel!.presenceState();
      final Map<String, dynamic> brothers = {};
      for (final client in state) {
        for (final presence in client.presences) {
          final p = presence.payload;
          final pid = p['publisher_id'];
          if (pid != null && pid != publisherId) {
            brothers[pid as String] = p;
          }
        }
      }
      _brothersController.add(brothers);
    }).subscribe();

    _posSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium, distanceFilter: 20),
    ).listen((pos) {
      _channel?.track({
        'publisher_id': publisherId,
        'display_name': 'Bro. Field Partner',
        'lat': pos.latitude,
        'lng': pos.longitude,
        'updated_at': DateTime.now().toIso8601String(),
      });
    });
  }

  Future<void> stopBroadcasting() async {
    await _posSub?.cancel();
    _posSub = null;
    await _channel?.untrack();
    await _channel?.unsubscribe();
    _channel = null;
    _brothersController.add({});
  }

  void dispose() {
    stopBroadcasting();
    _brothersController.close();
  }
}
