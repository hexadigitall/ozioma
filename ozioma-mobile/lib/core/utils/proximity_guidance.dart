/// Pure helper to evaluate proximity announcements for navigation to territory pins.
/// Prevents repeating announcements within the same distance band.
String? evaluateProximityPrompt({
  required double distanceMeters,
  required String pointType,
  required Set<int> announcedThresholds,
  String languageCode = 'en',
}) {
  final upperType = pointType.toUpperCase();

  // Arrival threshold (<= 30m)
  if (distanceMeters <= 30.0) {
    if (!announcedThresholds.contains(30)) {
      announcedThresholds.add(30);
      switch (languageCode) {
        case 'es':
          return 'Llegando al punto de $upperType del territorio';
        case 'fr':
          return 'Arrivée au point de $upperType du territoire';
        case 'pcm':
          return 'You don reach the $upperType point for territory';
        default:
          return 'Arriving at territory $upperType boundary point';
      }
    }
    return null;
  }

  // 100 meters threshold (> 50m and <= 100m)
  if (distanceMeters <= 100.0 && distanceMeters > 50.0) {
    if (!announcedThresholds.contains(100)) {
      announcedThresholds.add(100);
      switch (languageCode) {
        case 'es':
          return '100 metros para el punto de $upperType';
        case 'fr':
          return '100 mètres jusqu\'au point de $upperType';
        case 'pcm':
          return '100 meters remain to reach $upperType point';
        default:
          return '100 meters to $upperType point';
      }
    }
    return null;
  }

  // 200 meters threshold (> 150m and <= 200m)
  if (distanceMeters <= 200.0 && distanceMeters > 150.0) {
    if (!announcedThresholds.contains(200)) {
      announcedThresholds.add(200);
      switch (languageCode) {
        case 'es':
          return '200 metros para el punto de $upperType';
        case 'fr':
          return '200 mètres jusqu\'au point de $upperType';
        case 'pcm':
          return '200 meters remain to reach $upperType point';
        default:
          return '200 meters to $upperType point';
      }
    }
    return null;
  }

  return null;
}
