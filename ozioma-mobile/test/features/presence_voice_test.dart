import 'package:flutter_test/flutter_test.dart';
import 'package:ozioma/core/utils/presence_jitter.dart';
import 'package:ozioma/core/utils/proximity_guidance.dart';
import 'dart:math' as math;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Field Presence & Privacy Jitter Tests (Sprint 8)', () {
    test('applyPrivacyJitter bounds: distance offset must be between 5m and 15m', () {
      const origLat = 4.8156;
      const origLng = 7.0498;

      for (int i = 0; i < 50; i++) {
        final jitter = applyPrivacyJitter(origLat, origLng);
        final dist = jitter['jitter_meters']!;
        expect(dist, greaterThanOrEqualTo(5.0));
        expect(dist, lessThanOrEqualTo(15.0));

        // Coordinate must differ from original
        expect(jitter['lat'], isNot(equals(origLat)));
        expect(jitter['lng'], isNot(equals(origLng)));
      }
    });

    test('applyPrivacyJitter is deterministic when provided a seeded Random', () {
      const origLat = 51.5074; // London
      const origLng = -0.1278;

      final resultA = applyPrivacyJitter(origLat, origLng, random: math.Random(42));
      final resultB = applyPrivacyJitter(origLat, origLng, random: math.Random(42));

      expect(resultA['lat'], equals(resultB['lat']));
      expect(resultA['lng'], equals(resultB['lng']));
      expect(resultA['jitter_meters'], equals(resultB['jitter_meters']));
    });

    test('isBroadcastPermitted permits morning field ministry hours (8:00 AM - 12:00 PM)', () {
      final morning9Am = DateTime(2026, 11, 24, 9, 30);
      final morning11Am = DateTime(2026, 11, 24, 11, 45);

      expect(isBroadcastPermitted(morning9Am), isTrue);
      expect(isBroadcastPermitted(morning11Am), isTrue);
    });

    test('isBroadcastPermitted blocks outside ministry hours (before 8 AM, after 12 PM)', () {
      final early7Am = DateTime(2026, 11, 24, 7, 59);
      final afternoon12Pm = DateTime(2026, 11, 24, 12, 0);
      final evening5Pm = DateTime(2026, 11, 24, 17, 30);

      expect(isBroadcastPermitted(early7Am), isFalse);
      expect(isBroadcastPermitted(afternoon12Pm), isFalse);
      expect(isBroadcastPermitted(evening5Pm), isFalse);
    });

    test('isBroadcastPermitted terminates when 4-hour max session duration exceeded', () {
      final sessionStart = DateTime(2026, 11, 24, 8, 0);
      final after3Hours = DateTime(2026, 11, 24, 11, 0);
      final after4Hours = DateTime(2026, 11, 24, 12, 1);

      expect(isBroadcastPermitted(after3Hours, sessionStartTime: sessionStart), isTrue);
      expect(isBroadcastPermitted(after4Hours, sessionStartTime: sessionStart), isFalse);
    });
  });

  group('Voice Guidance Proximity Triggers & Debouncing Tests (Sprint 8)', () {
    test('evaluateProximityPrompt announces 200m threshold and debounces duplicates', () {
      final Set<int> thresholds = {};

      // 190m triggers 200m announcement
      final prompt1 = evaluateProximityPrompt(
        distanceMeters: 190.0,
        pointType: 'START',
        announcedThresholds: thresholds,
      );
      expect(prompt1, contains('200 meters to START point'));
      expect(thresholds.contains(200), isTrue);

      // Subsequent position still within 200m band does NOT re-announce
      final prompt2 = evaluateProximityPrompt(
        distanceMeters: 185.0,
        pointType: 'START',
        announcedThresholds: thresholds,
      );
      expect(prompt2, isNull);
    });

    test('evaluateProximityPrompt announces 100m threshold', () {
      final Set<int> thresholds = {};

      final prompt = evaluateProximityPrompt(
        distanceMeters: 85.0,
        pointType: 'STOP',
        announcedThresholds: thresholds,
      );
      expect(prompt, contains('100 meters to STOP point'));
      expect(thresholds.contains(100), isTrue);
    });

    test('evaluateProximityPrompt announces arrival at <= 30m', () {
      final Set<int> thresholds = {};

      final prompt = evaluateProximityPrompt(
        distanceMeters: 25.0,
        pointType: 'START',
        announcedThresholds: thresholds,
      );
      expect(prompt, contains('Arriving at territory START boundary point'));
      expect(thresholds.contains(30), isTrue);
    });

    test('evaluateProximityPrompt supports Spanish localization', () {
      final Set<int> thresholds = {};

      final prompt = evaluateProximityPrompt(
        distanceMeters: 20.0,
        pointType: 'START',
        announcedThresholds: thresholds,
        languageCode: 'es',
      );
      expect(prompt, equals('Llegando al punto de START del territorio'));
    });

    test('evaluateProximityPrompt supports Nigerian Pidgin localization', () {
      final Set<int> thresholds = {};

      final prompt = evaluateProximityPrompt(
        distanceMeters: 90.0,
        pointType: 'STOP',
        announcedThresholds: thresholds,
        languageCode: 'pcm',
      );
      expect(prompt, equals('100 meters remain to reach STOP point'));
    });
  });
}
