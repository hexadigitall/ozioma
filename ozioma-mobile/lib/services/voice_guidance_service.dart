import 'package:flutter_tts/flutter_tts.dart';
import 'package:geolocator/geolocator.dart';

/// Voice prompts: "200 meters to START. Turn left on Woji Road"
class VoiceGuidanceService {
  final FlutterTts tts = FlutterTts();
  Position? _lastAnnounced;
  List<Map<String, dynamic>> _waypoints = []; // from Mapbox Directions

  Future<void> init() async {
    await tts.setLanguage("en-US");
    await tts.setSpeechRate(0.5);
    await tts.setVolume(1.0);
  }

  Future<void> loadRouteToStart(double startLat, double startLng, Position current) async {
    _waypoints = [
      {'lat': current.latitude, 'lng': current.longitude, 'instruction': 'Head towards start point'},
      {'lat': startLat, 'lng': startLng, 'instruction': 'You have arrived at territory START boundary'},
    ];
  }

  void updateLocation(Position pos) {
    if (_waypoints.isEmpty) return;
    final next = _waypoints.first;
    final dist = Geolocator.distanceBetween(pos.latitude, pos.longitude, next['lat'] as double, next['lng'] as double);

    // Announce at 200m, 100m, 50m thresholds
    if (_lastAnnounced == null || Geolocator.distanceBetween(_lastAnnounced!.latitude, _lastAnnounced!.longitude, pos.latitude, pos.longitude) > 50) {
      if (dist < 200 && dist > 180) {
        _speak('${dist.toStringAsFixed(0)} meters to START. ${next['instruction']}');
        _lastAnnounced = pos;
      } else if (dist < 50) {
        _speak('Arriving at START point');
        _waypoints.removeAt(0);
        _lastAnnounced = pos;
      }
    }
  }

  Future<void> _speak(String text) async {
    await tts.speak(text);
  }

  Future<void> stop() async => await tts.stop();
}
