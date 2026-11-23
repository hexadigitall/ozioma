import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import '../services/territory_mapper_service.dart';
import '../services/map_matching_service.dart';
import '../services/kml_export_service.dart';
import '../core/database/database_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TerritoryMapperScreen extends ConsumerStatefulWidget {
  const TerritoryMapperScreen({super.key});
  @override
  ConsumerState<TerritoryMapperScreen> createState() => _TerritoryMapperScreenState();
}

class _TerritoryMapperScreenState extends ConsumerState<TerritoryMapperScreen> {
  mapbox.MapboxMap? map;
  late TerritoryMapperService mapper;
  late MapMatchingService matcher;
  List<geo.Position> points = [];
  bool recording = false;
  bool snapRoads = true;
  List<List<double>> displayPoly = [];

  @override
  void initState() {
    super.initState();
    final dao = ref.read(territoryDaoProvider);
    mapper = TerritoryMapperService(dao);
    matcher = MapMatchingService('YOUR_MAPBOX_TOKEN');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map New Territory'),
        actions: [
          IconButton(icon: const Icon(Icons.file_download), onPressed: _exportKml, tooltip: 'Export KML'),
          PopupMenuButton(
            itemBuilder: (_) => [
              PopupMenuItem(
                child: Row(
                  children: [
                    const Icon(Icons.route),
                    const SizedBox(width: 8),
                    const Text('Snap to Roads'),
                    const Spacer(),
                    Switch(value: snapRoads, onChanged: (v) => setState(() => snapRoads = v)),
                  ],
                ),
              )
            ],
          )
        ],
      ),
      body: Stack(
        children: [
          mapbox.MapWidget(
            styleUri: mapbox.MapboxStyles.MAPBOX_STREETS,
            cameraOptions: mapbox.CameraOptions(
              center: mapbox.Point(coordinates: mapbox.Position(6.99, 4.82)),
              zoom: 16,
            ),
            onMapCreated: (m) => map = m,
          ),
          if (displayPoly.isNotEmpty)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(painter: _PolyPainter(displayPoly)),
              ),
            ),
          Positioned(
            bottom: 100,
            left: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(recording ? 'Walking: ${points.length} GPS points' : 'Tap Start and walk the perimeter'),
                    if (recording) const LinearProgressIndicator(),
                    const SizedBox(height: 8),
                    Text(
                      '${(displayPoly.length * 15).toStringAsFixed(0)}m walked • ${(displayPoly.isNotEmpty ? _calcArea(displayPoly) / 10000 : 0).toStringAsFixed(2)} hectares',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!recording)
            FloatingActionButton.extended(
              heroTag: 'start',
              onPressed: _start,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start'),
            ),
          if (recording) ...[
            FloatingActionButton.extended(
              heroTag: 'stop',
              backgroundColor: Colors.red,
              onPressed: _stop,
              icon: const Icon(Icons.stop),
              label: const Text('Stop & Save'),
            ),
            const SizedBox(height: 12),
            FloatingActionButton(
              heroTag: 'undo',
              mini: true,
              onPressed: points.isNotEmpty
                  ? () {
                      setState(() => points.removeLast());
                      _updatePoly();
                    }
                  : null,
              child: const Icon(Icons.undo),
            ),
          ]
        ],
      ),
    );
  }

  Future<void> _start() async {
    await mapper.startMapping();
    setState(() => recording = true);
    Stream.periodic(const Duration(seconds: 1)).listen((_) async {
      if (!recording) return;
      setState(() => points = mapper.getCurrentTrack());
      await _updatePoly();
    });
  }

  Future<void> _updatePoly() async {
    var coords = points.map((p) => <double>[p.longitude, p.latitude]).toList();
    if (snapRoads && coords.length > 2) {
      coords = await matcher.snapToRoads(coords, offlineOnly: false);
    }
    setState(() => displayPoly = coords);
  }

  Future<void> _stop() async {
    final res = await mapper.stopMapping(number: 'NEW', name: 'New', congregationId: 'rumuola');
    setState(() => recording = false);
    _showSaveDialog(res);
  }

  void _showSaveDialog(Map<String, dynamic> res) {
    final numberCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final areaVal = (res['area_m2'] as double? ?? 0.0);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Register Territory'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${(areaVal / 10000).toStringAsFixed(2)} hectares • ${res['points']} vertices'),
            TextField(controller: numberCtrl, decoration: const InputDecoration(labelText: 'Number e.g. #47')),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name e.g. Woji Phase 2')),
            SwitchListTile(
              value: snapRoads,
              onChanged: (v) => setState(() => snapRoads = v),
              title: const Text('Snap to Roads'),
            )
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved ${numberCtrl.text}')));
            },
            child: const Text('Save'),
          )
        ],
      ),
    );
  }

  void _exportKml() async {
    final path = await KmlExportService.territoryToKml(
      territoryNumber: '#14',
      territoryName: 'Oakwood',
      geojsonPolygon: '{"type":"Polygon","coordinates":[[[6.99,4.82]]]}',
    );
    await KmlExportService.shareKml(path);
  }

  double _calcArea(List<List<double>> pts) {
    if (pts.length < 3) return 0;
    double area = 0;
    double latAvg = pts.map((e) => e[1]).reduce((a, b) => a + b) / pts.length;
    double mLat = 111320, mLon = 111320 * cos(latAvg * 3.14159 / 180);
    for (int i = 0; i < pts.length - 1; i++) {
      area += (pts[i][0] * mLon) * (pts[i + 1][1] * mLat) - (pts[i + 1][0] * mLon) * (pts[i][1] * mLat);
    }
    return area.abs() / 2;
  }
}

class _PolyPainter extends CustomPainter {
  final List<List<double>> pts;
  _PolyPainter(this.pts);

  @override
  void paint(Canvas c, ui.Size s) {
    if (pts.length < 2) return;
    final p = Paint()
      ..color = Colors.blue.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    final path = Path();
    for (int i = 0; i < pts.length; i++) {
      if (i == 0) {
        path.moveTo(50.0 + i * 2, 50.0 + i);
      } else {
        path.lineTo(50.0 + i * 2, 50.0 + i);
      }
    }
    path.close();
    c.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant _PolyPainter old) => old.pts != pts;
}
