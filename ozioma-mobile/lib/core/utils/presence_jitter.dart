import 'dart:math' as math;

/// Calculates random privacy jitter (between 5m and 15m) to prevent pinpointing
/// exact householder doors while showing territory partner presence.
Map<String, double> applyPrivacyJitter(
  double lat,
  double lng, {
  double minJitterMeters = 5.0,
  double maxJitterMeters = 15.0,
  math.Random? random,
}) {
  final rng = random ?? math.Random();
  final distance = minJitterMeters + rng.nextDouble() * (maxJitterMeters - minJitterMeters);
  final angle = rng.nextDouble() * 2 * math.pi;

  // 1 degree latitude ~ 111,320 meters
  final dLat = (distance * math.cos(angle)) / 111320.0;
  // 1 degree longitude ~ 111,320m * cos(latitude)
  final radLat = lat * math.pi / 180.0;
  final cosLat = math.cos(radLat).abs();
  final dLng = (distance * math.sin(angle)) / (111320.0 * (cosLat < 0.0001 ? 1.0 : cosLat));

  return {
    'lat': lat + dLat,
    'lng': lng + dLng,
    'jitter_meters': distance,
  };
}

/// Evaluates whether location broadcasting is permitted based on theocratic ministry hours
/// and session duration (auto-terminates at 12:00 PM or after 4 hours).
bool isBroadcastPermitted(
  DateTime now, {
  DateTime? sessionStartTime,
  int maxDurationHours = 4,
  int startHour = 8,
  int endHour = 12,
}) {
  if (now.hour < startHour || now.hour >= endHour) {
    return false;
  }
  if (sessionStartTime != null) {
    final diff = now.difference(sessionStartTime);
    if (diff.inHours >= maxDurationHours) {
      return false;
    }
  }
  return true;
}
