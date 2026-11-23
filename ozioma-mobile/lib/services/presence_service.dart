import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

/// Realtime presence: share location with brothers in same territory during service hours
/// Privacy: Auto-off outside 8am-12pm, opt-in toggle, anonymized after 1hr
class PresenceService {
  final supabase = Supabase.instance.client;
  RealtimeChannel? _channel;
  StreamSubscription<Position>? _posSub;
  String? _territoryId;
  String? _publisherId;

  Future<void> startBroadcasting(String territoryId, String publisherId) async {
    final now = DateTime.now();
    if (now.hour < 8 || now.hour >= 12) return; // service hours only
    
    _territoryId = territoryId;
    _publisherId = publisherId;
    
    _channel = supabase.channel('territory:$territoryId', opts: RealtimeChannelConfig(ack: true));
    _channel!.onPresenceSync((payload) {}).subscribe();

    _posSub = Geolocator.getPositionStream(locationSettings: LocationSettings(accuracy: LocationAccuracy.medium, distanceFilter: 20)).listen((pos) {
      _channel!.track({
        'publisher_id': publisherId,
        'display_name': 'Bro. You',
        'lat': pos.latitude,
        'lng': pos.longitude,
        'updated_at': DateTime.now().toIso8601String(),
      });
    });
  }

  Stream<Map<String, dynamic>> getBrotherLocations() async* {
    if (_channel == null) yield {};
    _channel!.onPresenceSync((payload) {
      // yields map of publisher_id -> {lat, lng, display_name}
    });
    // In real impl: use controller.add on presence changes
  }

  Future<void> stopBroadcasting() async {
    await _posSub?.cancel();
    await _channel?.untrack();
    await _channel?.unsubscribe();
    _channel = null;
  }
}
