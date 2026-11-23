import 'dart:io';
import 'dart:convert';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

/// Export territory GeoJSON to KML for paper map users / territory servants
class KmlExportService {
  static Future<String> territoryToKml({
    required String territoryNumber,
    required String territoryName,
    required String geojsonPolygon,
    List<Map<String, dynamic>>? addresses,
  }) async {
    final poly = jsonDecode(geojsonPolygon);
    final coords = poly['coordinates'][0] as List; // outer ring
    
    final kmlCoords = coords.map((c) => '${c[0]},${c[1]},0').join(' ');
    
    final placemarks = addresses?.map((a) => '''
    <Placemark>
      <name>${a['street_address']}${a['unit']!=null?' ${a['unit']}':''}</name>
      <styleUrl>#${a['status']}</styleUrl>
      <Point><coordinates>${a['longitude']},${a['latitude']},0</coordinates></Point>
    </Placemark>''').join('\n') ?? '';

    final kml = '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <name>Territory $territoryNumber - $territoryName</name>
    <Style id="unvisited"><IconStyle><color>ff94a3b8</color></IconStyle></Style>
    <Style id="not_at_home"><IconStyle><color>fff59e0b</color></IconStyle></Style>
    <Style id="return_visit"><IconStyle><color>ff10b981</color></IconStyle></Style>
    <Style id="do_not_call"><IconStyle><color>fff43f5e</color></IconStyle></Style>
    
    <Placemark>
      <name>Boundary $territoryNumber</name>
      <Polygon>
        <outerBoundaryIs>
          <LinearRing>
            <coordinates>$kmlCoords</coordinates>
          </LinearRing>
        </outerBoundaryIs>
      </Polygon>
    </Placemark>
    $placemarks
  </Document>
</kml>''';

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/territory_$territoryNumber.kml');
    await file.writeAsString(kml);
    return file.path;
  }

  static Future<void> shareKml(String path) async {
    await Share.shareXFiles([XFile(path)], subject: 'Territory KML');
  }
}
