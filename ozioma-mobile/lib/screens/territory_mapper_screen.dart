import 'package:flutter/material.dart';
import 'dart:math';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../services/territory_mapper_service.dart';
import '../services/map_matching_service.dart';
import '../services/kml_export_service.dart';
import '../services/secure_db.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TerritoryMapperScreen extends ConsumerStatefulWidget {
  const TerritoryMapperScreen({super.key});
  @override ConsumerState<TerritoryMapperScreen> createState() => _TerritoryMapperScreenState();
}

class _TerritoryMapperScreenState extends ConsumerState<TerritoryMapperScreen> {
  MapboxMap? map;
  late TerritoryMapperService mapper;
  late MapMatchingService matcher;
  List<Position> points = [];
  bool recording = false;
  bool snapRoads = true;
  List<List<double>> displayPoly = [];

  @override void initState() {
    super.initState();
    final db = ref.read(databaseProvider);
    mapper = TerritoryMapperService(db);
    matcher = MapMatchingService('YOUR_MAPBOX_TOKEN');
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Map New Territory'), actions: [
        IconButton(icon: Icon(Icons.file_download), onPressed: _exportKml, tooltip: 'Export KML'),
        PopupMenuButton(itemBuilder: (_)=>[
          PopupMenuItem(child: Row(children:[Icon(Icons.route), SizedBox(width:8), Text('Snap to Roads'), Spacer(), Switch(value: snapRoads, onChanged: (v)=>setState(()=>snapRoads=v))]))
        ])
      ]),
      body: Stack(children: [
        MapWidget(styleUri: MapboxStyles.MAPBOX_STREETS, cameraOptions: CameraOptions(center: Point(coordinates: Position(6.99,4.82)), zoom: 16), onMapCreated: (m)=>map=m),
        if (displayPoly.isNotEmpty) Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _PolyPainter(displayPoly)))),
        Positioned(bottom: 100, left: 16, right: 16, child: Card(child: Padding(padding: EdgeInsets.all(12), child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(recording ? 'Walking: ${points.length} GPS points' : 'Tap Start and walk the perimeter'),
          if (recording) LinearProgressIndicator(),
          SizedBox(height:8),
          Text('${(displayPoly.length*15).toStringAsFixed(0)}m walked • ${(displayPoly.isNotEmpty?_calcArea(displayPoly)/10000:0).toStringAsFixed(2)} hectares', style: TextStyle(fontSize:12, color: Colors.grey)),
        ]))))
      ]),
      floatingActionButton: Column(mainAxisSize: MainAxisSize.end, children: [
        if (!recording) FloatingActionButton.extended(heroTag:'start', onPressed: _start, icon: Icon(Icons.play_arrow), label: Text('Start')),
        if (recording) ...[
          FloatingActionButton.extended(heroTag:'stop', backgroundColor: Colors.red, onPressed: _stop, icon: Icon(Icons.stop), label: Text('Stop & Save')),
          SizedBox(height:12),
          FloatingActionButton(heroTag:'undo', mini: true, onPressed: points.isNotEmpty? (){ setState(()=>points.removeLast()); _updatePoly(); }:null, child: Icon(Icons.undo)),
        ]
      ]),
    );
  }

  Future<void> _start() async {
    await mapper.startMapping();
    setState(()=>recording=true);
    Stream.periodic(Duration(seconds:1)).listen((_) async {
      if (!recording) return;
      setState(()=>points = mapper.getCurrentTrack());
      await _updatePoly();
    });
  }

  Future<void> _updatePoly() async {
    var coords = points.map((p)=>[p.longitude, p.latitude]).toList();
    if (snapRoads && coords.length > 2) coords = await matcher.snapToRoads(coords, offlineOnly: false);
    setState(()=>displayPoly = coords);
    // draw on map via annotations
  }

  Future<void> _stop() async {
    final res = await mapper.stopMapping(number: 'NEW', name: 'New', congregationId: 'rumuola');
    setState(()=>recording=false);
    _showSaveDialog(res);
  }

  void _showSaveDialog(Map<String, dynamic> res) {
    final num = TextEditingController(); final name = TextEditingController();
    showDialog(context: context, builder: (_) => AlertDialog(
      title: Text('Register Territory'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('${(res['area_m2']/10000).toStringAsFixed(2)} hectares • ${res['points']} vertices'),
        TextField(controller: num, decoration: InputDecoration(labelText: 'Number e.g. #47')),
        TextField(controller: name, decoration: InputDecoration(labelText: 'Name e.g. Woji Phase 2')),
        SwitchListTile(value: snapRoads, onChanged: (v)=>setState(()=>snapRoads=v), title: Text('Snap to Roads'))
      ]),
      actions: [TextButton(onPressed: ()=>Navigator.pop(context), child: Text('Cancel')), FilledButton(onPressed: (){Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved ${num.text}')));}, child: Text('Save'))],
    ));
  }

  void _exportKml() async {
    // get current territory from DB
    final path = await KmlExportService.territoryToKml(territoryNumber: '#14', territoryName: 'Oakwood', geojsonPolygon: '{"type":"Polygon","coordinates":[[[6.99,4.82]]]}');
    await KmlExportService.shareKml(path);
  }

  double _calcArea(List<List<double>> pts){
    if (pts.length<3) return 0;
    double area=0; double latAvg=pts.map((e)=>e[1]).reduce((a,b)=>a+b)/pts.length;
    double mLat=111320, mLon=111320*cos(latAvg*3.14159/180);
    for(int i=0;i<pts.length-1;i++){ area+=(pts[i][0]*mLon)*(pts[i+1][1]*mLat)-(pts[i+1][0]*mLon)*(pts[i][1]*mLat); }
    return area.abs()/2;
  }
}

class _PolyPainter extends CustomPainter {
  final List<List<double>> pts; _PolyPainter(this.pts);
  @override void paint(Canvas c, Size s){
    if(pts.length<2) return;
    final p = Paint()..color=Colors.blue.withOpacity(0.3)..style=PaintingStyle.fill;
    final path = Path();
    // naive screen projection - real impl uses mapbox projection
    for(int i=0;i<pts.length;i++){ if(i==0) path.moveTo(50+i*2,50+i); else path.lineTo(50+i*2,50+i); }
    path.close(); c.drawPath(path, p);
  }
  @override bool shouldRepaint(covariant _PolyPainter old) => old.pts!=pts;
}
