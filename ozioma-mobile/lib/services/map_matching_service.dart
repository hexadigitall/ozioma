import 'package:dio/dio.dart';

/// Snap walked GPS points to nearest roads using Mapbox Map Matching API
/// Offline fallback: uses Ramer-Douglas-Peucker simplification only
class MapMatchingService {
  final dio = Dio();
  final String token; // 'YOUR_MAPBOX_TOKEN'
  MapMatchingService(this.token);

  Future<List<List<double>>> snapToRoads(List<List<double>> rawCoords, {bool offlineOnly = false}) async {
    if (offlineOnly || rawCoords.length < 2) return _simplify(rawCoords);
    
    // Mapbox allows up to 100 points per request
    final chunks = <List<List<double>>>[];
    for (var i = 0; i < rawCoords.length; i += 90) {
      chunks.add(rawCoords.sublist(i, i + 90 > rawCoords.length ? rawCoords.length : i + 90));
    }

    final snapped = <List<double>>[];
    for (var chunk in chunks) {
      final coords = chunk.map((c) => '${c[0]},${c[1]}').join(';');
      try {
        final resp = await dio.get(
          'https://api.mapbox.com/matching/v5/mapbox/walking/$coords',
          queryParameters: {
            'access_token': token,
            'geometries': 'geojson',
            'steps': false,
            'tidy': true,
          },
        );
        if (resp.statusCode == 200) {
          final geom = resp.data['matchings'][0]['geometry']['coordinates'] as List;
          snapped.addAll(geom.map((e) => [e[0] as double, e[1] as double]));
        } else {
          snapped.addAll(chunk);
        }
      } catch (e) {
        snapped.addAll(_simplify(chunk)); // offline fallback
      }
    }
    return _simplify(snapped);
  }

  List<List<double>> _simplify(List<List<double>> pts, [double e=0.00005]) {
    // RDP - same as territory_mapper_service
    if (pts.length < 3) return pts;
    int index = -1; double dmax = 0;
    for (int i=1;i<pts.length-1;i++){
      double d = _dist(pts[i], pts.first, pts.last);
      if (d>dmax){dmax=d; index=i;}
    }
    if (dmax>e){
      var r1=_simplify(pts.sublist(0,index+1),e);
      var r2=_simplify(pts.sublist(index),e);
      return [...r1.sublist(0,r1.length-1), ...r2];
    }
    return [pts.first, pts.last];
  }
  double _dist(List<double> p, List<double> a, List<double> b){
    double x0=p[0],y0=p[1],x1=a[0],y1=a[1],x2=b[0],y2=b[1];
    double num=((y2-y1)*x0-(x2-x1)*y0+x2*y1-y2*x1).abs();
    double den = ( (y2-y1)*(y2-y1)+(x2-x1)*(x2-x1) ).abs();
    return den==0?0:num/den;
  }
}
