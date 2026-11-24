import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import '../core/utils/presence_jitter.dart';

export '../core/utils/presence_jitter.dart';

/// Realtime presence: share location with brothers in same territory during service hours.
/// Features:
/// - Auto-off outside 8:00 AM - 12:00 PM
/// - Max 4-hour session auto-expiration timer
/// - Randomized $\pm 15$m privacy jitter on coordinates
/// - Scoped Supabase Realtime channel per territory
class PresenceService {
  final supabase = Supabase.instance.client;
  RealtimeChannel? _channel;
  StreamSubscription<Position>? _posSub;
  Timer? _expirationTimer;
  DateTime? _sessionStartTime;
  DateTime? _sessionExpiresAt;

  final StreamController<Map<String, dynamic>> _brothersController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get brotherLocationsStream => _brothersController.stream;
  DateTime? get sessionExpiresAt => _sessionExpiresAt;
  bool get isBroadcasting => _channel != null;

  Future<bool> startBroadcasting(String territoryId, String publisherId) async {
    final now = DateTime.now();
    if (!isBroadcastPermitted(now)) return false;

    _sessionStartTime = now;
    final todayNoon = DateTime(now.year, now.month, now.day, 12, 0, 0);
    final maxFourHours = now.add(const Duration(hours: 4));
    _sessionExpiresAt = todayNoon.isBefore(maxFourHours) ? todayNoon : maxFourHours;

    final remaining = _sessionExpiresAt!.difference(now);
    _expirationTimer?.cancel();
    _expirationTimer = Timer(remaining, () {
      stopBroadcasting();
    });

    _channel = supabase.channel(
      'territory:$territoryId',
      opts: const RealtimeChannelConfig(ack: true),
    );

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
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        distanceFilter: 20,
      ),
    ).listen((pos) {
      if (!isBroadcastPermitted(DateTime.now(), sessionStartTime: _sessionStartTime)) {
        stopBroadcasting();
        return;
      }

      // Apply privacy jitter before broadcasting to channel
      final jittered = applyPrivacyJitter(pos.latitude, pos.longitude);

      _channel?.track({
        'publisher_id': publisherId,
        'display_name': 'Bro. Field Partner',
        'lat': jittered['lat'],
        'lng': jittered['lng'],
        'updated_at': DateTime.now().toUtc().toIso8601String(),
        'expires_at': _sessionExpiresAt?.toUtc().toIso8601String(),
      });
    });

    return true;
  }

  Future<void> stopBroadcasting() async {
    _expirationTimer?.cancel();
    _expirationTimer = null;
    _sessionStartTime = null;
    _sessionExpiresAt = null;

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
