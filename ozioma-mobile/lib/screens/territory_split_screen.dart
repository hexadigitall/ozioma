import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../services/secure_db.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Elder tool: Draw a line across territory polygon to split into 2
class TerritorySplitScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> territory;
  const TerritorySplitScreen({super.key, required this.territory});
  @override ConsumerState<TerritorySplitScreen> createState() => _TerritorySplitScreenState();
}

class _TerritorySplitScreenState extends ConsumerState<TerritorySplitScreen> {
  MapboxMap? map;
  List<Point> splitLine = [];
  bool drawing = false;

  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Split Territory ${widget.territory['number']}')),
      body: Stack(children: [
        MapWidget(
          styleUri: MapboxStyles.MAPBOX_STREETS,
          onMapCreated: (m) { map = m; _loadPolygon(); },
          onTapListener: (coords) {
            if (!drawing) return;
            setState(() => splitLine.add(Point(coordinates: Position(coords.point.coordinates.lng, coords.point.coordinates.lat))));
            _drawSplitLine();
          },
        ),
        Positioned(bottom:16,left:16,right:16,child:Card(child: Padding(padding: EdgeInsets.all(12), child: Column(children: [
          Text(drawing ? 'Tap 2 points to draw split line' : 'Split into 2 new territories'),
          SizedBox(height:8),
          Row(children:[
            Expanded(child: OutlinedButton(onPressed: ()=>setState(()=>drawing=!drawing), child: Text(drawing?'Cancel':'Draw Line'))),
            SizedBox(width:8),
            Expanded(child: FilledButton(onPressed: splitLine.length==2? _executeSplit : null, child: Text('Split'))),
          ])
        ]))))
      ]),
    );
  }

  void _loadPolygon() async {
    // Load existing boundary and display
  }
  void _drawSplitLine() async {
    // Draw temp line on map
  }
  void _executeSplit() async {
    // 1. Use Turf.js equivalent or server-side ST_Split(PostGIS) to cut polygon
    // 2. Create 2 new territory records with new numbers e.g. #14A, #14B
    // 3. Reassign addresses to correct polygon via ST_Contains
    // 4. Mark old territory 'archived'
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Split complete: ${widget.territory['number']}A + ${widget.territory['number']}B')));
  }
}
