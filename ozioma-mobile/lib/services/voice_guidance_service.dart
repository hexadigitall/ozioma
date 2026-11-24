import 'package:flutter_tts/flutter_tts.dart';
import 'package:geolocator/geolocator.dart';
import '../core/utils/proximity_guidance.dart';

export '../core/utils/proximity_guidance.dart';

/// Offline voice prompts: "200 meters to START point. Turn left on Market Road"
class VoiceGuidanceService {
  final FlutterTts tts = FlutterTts();
  final Set<int> announcedThresholds = {};
  List<Map<String, dynamic>> _waypoints = [];
  String _currentPointType = 'START';
  String _language = 'en-US';

  Future<void> init({String language = 'en-US'}) async {
    _language = language;
    await tts.setLanguage(language);
    await tts.setSpeechRate(0.5);
    await tts.setVolume(1.0);
  }

  void resetNavigation(String pointType) {
    _currentPointType = pointType;
    announcedThresholds.clear();
  }

  Future<void> loadRouteToStart(
    double startLat,
    double startLng,
    Position current, {
    String pointType = 'START',
  }) async {
    resetNavigation(pointType);
    _waypoints = [
      {
        'lat': current.latitude,
        'lng': current.longitude,
        'instruction': 'Head towards $pointType point',
      },
      {
        'lat': startLat,
        'lng': startLng,
        'instruction': 'You have arrived at territory $pointType boundary',
      },
    ];
  }

  void updateLocation(Position pos) {
    if (_waypoints.isEmpty) return;
    final destination = _waypoints.last;
    final dist = Geolocator.distanceBetween(
      pos.latitude,
      pos.longitude,
      destination['lat'] as double,
      destination['lng'] as double,
    );

    final langPrefix = _language.split('-').first;
    final prompt = evaluateProximityPrompt(
      distanceMeters: dist,
      pointType: _currentPointType,
      announcedThresholds: announcedThresholds,
      languageCode: langPrefix,
    );

    if (prompt != null) {
      _speak(prompt);
    }
  }

  Future<void> _speak(String text) async {
    await tts.speak(text);
  }

  Future<void> stop() async => await tts.stop();
}
