import 'package:geolocator/geolocator.dart';
import 'dart:math';
import 'package:uuid/uuid.dart';
import 'secure_db.dart';

/// Territory Mapping by walking: Start -> track GPS points -> Stop -> Polygonize
/// Produces GeoJSON polygon for territory boundary + centroid for map camera
class TerritoryMapperService {
  final SecureDatabase db;
  TerritoryMapperService(this.db);

  bool _isRecording = false;
  List<Position> _track = [];
  Stream<Position>? _positionStream;
  final double minDistanceM = 5.0; // ignore jitter under 5m

  Future<bool> ensurePermissions() async {
    bool service = await Geolocator.isLocationServiceEnabled();
    if (!service) return false;
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
    return perm == LocationPermission.always || perm == LocationPermission.whileInUse;
  }

  Future<void> startMapping() async {
    if (_isRecording) return;
    final ok = await ensurePermissions();
    if (!ok) throw Exception('Location permission required');
    _track = [];
    _isRecording = true;
    _positionStream = Geolocator.getPositionStream(locationSettings: LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: minDistanceM));
    _positionStream!.listen((pos) {
      if (_track.isEmpty || Geolocator.distanceBetween(_track.last.latitude, _track.last.longitude, pos.latitude, pos.longitude) >= minDistanceM) {
        _track.add(pos);
      }
    });
  }

  List<Position> getCurrentTrack() => List.unmodifiable(_track);

  /// Stop and create polygon by closing the path
  Future<Map<String, dynamic>> stopMapping({required String number, required String name, required String congregationId}) async {
    if (!_isRecording || _track.length < 3) throw Exception('Walk a larger area with at least 3 points');
    _isRecording = false;
    await _positionStream?.drain();

    // Close polygon
    final coords = _track.map((p) => [p.longitude, p.latitude]).toList();
    coords.add([_track.first.longitude, _track.first.latitude]);

    // Simplify with Ramer-Douglas-Peucker epsilon ~ 0.00005 deg ~5m
    final simplified = _simplify(coords, 0.00005);

    // Compute area m2 using shoelace + haversine approx
    final areaM2 = _polygonAreaMeters(simplified);
    final centroid = _centroid(simplified);

    final geojson = {
      'type': 'Polygon',
      'coordinates': [simplified],
    };

    final id = const Uuid().v4();
    await db.into(db.territories).insert(TerritoriesCompanion.insert(
      id: id,
      number: number,
      name: name,
      boundaryGeojson: geojson.toString(),
      status: const Value('available'),
      congregationId: congregationId,
    ));

    return {
      'id': id,
      'geojson': geojson,
      'area_m2': areaM2,
      'centroid': centroid,
      'points': simplified.length,
    };
  }

  List<List<double>> _simplify(List<List<double>> points, double epsilon) {
    // RDP implementation
    if (points.length < 3) return points;
    int index = -1;
    double dmax = 0;
    var line = _perpendicularDistanceLine(points.first, points.last);
    for (int i = 1; i < points.length - 1; i++) {
      double d = _perpendicularDistance(points[i], line);
      if (d > dmax) { dmax = d; index = i; }
    }
    if (dmax > epsilon) {
      var rec1 = _simplify(points.sublist(0, index+1), epsilon);
      var rec2 = _simplify(points.sublist(index), epsilon);
      return [...rec1.sublist(0, rec1.length-1), ...rec2];
    } else {
      return [points.first, points.last];
    }
  }

  List<double> _perpendicularDistanceLine(List<double> a, List<double> b) => [a[0], a[1], b[0], b[1]];
  double _perpendicularDistance(List<double> p, List<double> line) {
    double x0=p[0], y0=p[1], x1=line[0], y1=line[1], x2=line[2], y2=line[3];
    double num = ((y2-y1)*x0 - (x2-x1)*y0 + x2*y1 - y2*x1).abs();
    double den = sqrt(pow(y2-y1,2)+pow(x2-x1,2));
    return den==0?0:num/den;
  }

  double _polygonAreaMeters(List<List<double>> pts) {
    // Shoelace in degrees then convert ~111km per deg lat, lon varies with cos(lat)
    double area = 0;
    double latAvg = pts.map((e)=>e[1]).reduce((a,b)=>a+b)/pts.length;
    double mPerDegLat = 111320;
    double mPerDegLon = 111320 * cos(latAvg * pi/180);
    for (int i=0;i<pts.length-1;i++){
      double x1 = pts[i][0]*mPerDegLon, y1 = pts[i][1]*mPerDegLat;
      double x2 = pts[i+1][0]*mPerDegLon, y2 = pts[i+1][1]*mPerDegLat;
      area += x1*y2 - x2*y1;
    }
    return (area.abs()/2);
  }

  List<double> _centroid(List<List<double>> pts){
    double sumX=0,sumY=0;
    for(var p in pts.sublist(0, pts.length-1)){ sumX+=p[0]; sumY+=p[1]; }
    int n = pts.length-1;
    return [sumX/n, sumY/n];
  }
}
