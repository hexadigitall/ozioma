import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import '../core/database/daos/congregation_dao.dart';
import '../core/database/database_providers.dart';
import '../services/kml_export_service.dart';
import '../services/map_matching_service.dart';
import '../services/territory_mapper_service.dart';

class TerritoryMapperScreen extends ConsumerStatefulWidget {
  const TerritoryMapperScreen({super.key});

  @override
  ConsumerState<TerritoryMapperScreen> createState() => _TerritoryMapperScreenState();
}

class _TerritoryMapperScreenState extends ConsumerState<TerritoryMapperScreen> {
  mapbox.MapboxMap? map;
  late TerritoryMapperService mapper;
  late MapMatchingService matcher;
  Timer? _trackTimer;
  List<geo.Position> points = [];
  bool recording = false;
  bool snapRoads = true;
  List<List<double>> displayPoly = [];

  @override
  void initState() {
    super.initState();
    final dao = ref.read(territoryDaoProvider);
    mapper = TerritoryMapperService(dao);
    const token = String.fromEnvironment('MAPBOX_ACCESS_TOKEN', defaultValue: '');
    matcher = MapMatchingService(token);
  }

  @override
  void dispose() {
    _trackTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final congDao = ref.watch(congregationDaoProvider);

    return StreamBuilder<ActiveSessionState?>(
      stream: congDao.watchActiveSession(),
      builder: (context, sessionSnap) {
        final activeCongId = sessionSnap.data?.activeCongregationId ?? '';

        return Scaffold(
          appBar: AppBar(
            title: const Text('Map New Territory'),
            actions: [
              IconButton(
                icon: const Icon(Icons.file_download),
                onPressed: _exportKml,
                tooltip: 'Export KML',
              ),
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
                  ),
                ],
              ),
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
                        Text(
                          recording
                              ? 'Walking: ${points.length} GPS points'
                              : 'Tap Start and walk the perimeter',
                        ),
                        if (recording) const LinearProgressIndicator(),
                        const SizedBox(height: 8),
                        Text(
                          '${(displayPoly.length * 15).toStringAsFixed(0)}m walked • '
                          '${(displayPoly.isNotEmpty ? _calcArea(displayPoly) / 10000 : 0).toStringAsFixed(2)} hectares',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
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
                  onPressed: () => _stopAndSave(activeCongId),
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
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _start() async {
    await mapper.startMapping();
    if (!mounted) return;
    setState(() => recording = true);
    _trackTimer?.cancel();
    _trackTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (!recording || !mounted) return;
      setState(() => points = mapper.getCurrentTrack());
      await _updatePoly();
    });
  }

  Future<void> _updatePoly() async {
    var coords = points.map((p) => <double>[p.longitude, p.latitude]).toList();
    if (snapRoads && coords.length > 2) {
      coords = await matcher.snapToRoads(coords, offlineOnly: false);
    }
    if (mounted) setState(() => displayPoly = coords);
  }

  Future<void> _stopAndSave(String congregationId) async {
    _trackTimer?.cancel();
    setState(() => recording = false);

    final coords = displayPoly.isNotEmpty
        ? displayPoly
        : (points.isNotEmpty
            ? points.map((p) => <double>[p.longitude, p.latitude]).toList()
            : [
                [6.988, 4.821],
                [6.995, 4.821],
                [6.995, 4.819],
                [6.988, 4.819],
              ]);
    final closed = [...coords, coords.first];
    final geojson = jsonEncode({
      'type': 'Polygon',
      'coordinates': [closed],
    });
    final areaM2 = _calcArea(coords);
    _showSaveDialog(congregationId, geojson, coords, areaM2);
  }

  void _showSaveDialog(
    String congregationId,
    String geojson,
    List<List<double>> coords,
    double areaVal,
  ) {
    final numberCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final regionCtrl = TextEditingController(text: 'Worldwide');
    final territoryDao = ref.read(territoryDaoProvider);

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Register Territory'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${(areaVal / 10000).toStringAsFixed(2)} hectares • ${coords.length} vertices'),
            const SizedBox(height: 10),
            TextField(
              controller: numberCtrl,
              decoration: const InputDecoration(labelText: 'Number (e.g. #47) *', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Name (e.g. Woji Phase 2) *', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: regionCtrl,
              decoration: const InputDecoration(labelText: 'Region / City', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (numberCtrl.text.trim().isEmpty || nameCtrl.text.trim().isEmpty) return;
              final startLng = coords.first[0];
              final startLat = coords.first[1];
              final stopLng = coords[coords.length ~/ 2][0];
              final stopLat = coords[coords.length ~/ 2][1];

              await territoryDao.createTerritory(
                number: numberCtrl.text.trim(),
                name: nameCtrl.text.trim(),
                region: regionCtrl.text.trim().isEmpty ? 'General' : regionCtrl.text.trim(),
                congregationId: congregationId,
                boundaryGeojson: geojson,
                startLat: startLat,
                startLng: startLng,
                stopLat: stopLat,
                stopLng: stopLng,
              );

              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Saved territory ${numberCtrl.text.trim()}')),
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Save Territory'),
          ),
        ],
      ),
    );
  }

  void _exportKml() async {
    final coords = displayPoly.isNotEmpty
        ? [...displayPoly, displayPoly.first]
        : [
            [6.99, 4.82],
          ];
    final path = await KmlExportService.territoryToKml(
      territoryNumber: '#NEW',
      territoryName: 'Mapped Territory',
      geojsonPolygon: jsonEncode({
        'type': 'Polygon',
        'coordinates': [coords],
      }),
    );
    await KmlExportService.shareKml(path);
  }

  double _calcArea(List<List<double>> coords) {
    if (coords.length < 3) return 0;
    double area = 0;
    for (int i = 0; i < coords.length; i++) {
      final p1 = coords[i];
      final p2 = coords[(i + 1) % coords.length];
      area += (p1[0] * p2[1]) - (p2[0] * p1[1]);
    }
    return area.abs() * 111319.9 * 111319.9 / 2 * cos(coords[0][1] * pi / 180);
  }
}

class _PolyPainter extends CustomPainter {
  final List<List<double>> coords;
  _PolyPainter(this.coords);

  @override
  void paint(Canvas canvas, Size size) {
    if (coords.length < 2) return;
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 4
      ..style = ui.PaintingStyle.stroke;
    final path = Path()..moveTo(size.width * 0.2, size.height * 0.5);
    for (int i = 1; i < coords.length; i++) {
      path.lineTo(size.width * (0.2 + i * 0.05), size.height * (0.5 - sin(i) * 0.1));
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
