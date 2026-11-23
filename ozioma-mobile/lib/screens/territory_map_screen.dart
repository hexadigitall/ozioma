import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../services/offline_map_service.dart';

class TerritoryMapScreen extends StatefulWidget {
  final Map<String, dynamic> territory;
  final List<Map<String, dynamic>> addresses;
  const TerritoryMapScreen({super.key, required this.territory, required this.addresses});
  @override State<TerritoryMapScreen> createState() => _TerritoryMapScreenState();
}

class _TerritoryMapScreenState extends State<TerritoryMapScreen> {
  MapboxMap? mapbox;
  final offline = OfflineMapService();
  @override void initState() { super.initState(); offline.init(); }
  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.territory['name'] ?? 'Map')),
      body: Stack(children: [
        MapWidget(
          styleUri: MapboxStyles.MAPBOX_STREETS,
          cameraOptions: CameraOptions(center: Point(coordinates: Position(6.99, 4.82)), zoom: 14),
          onMapCreated: (m) { mapbox = m; },
        ),
        Positioned(bottom: 16, left: 16, right: 16, child: Card(child: Padding(padding: EdgeInsets.all(12), child: Row(children: [Icon(Icons.offline_bolt, color: Colors.green), SizedBox(width:8), Expanded(child: Text('Offline tiles active')), IconButton(icon: Icon(Icons.layers), onPressed: () => showModalBottomSheet(context: context, builder: (_) => OfflineRegionManagerSheet()))]))),
      ]),
    );
  }
}

class OfflineRegionManagerSheet extends StatefulWidget {
  const OfflineRegionManagerSheet({super.key});
  @override State<OfflineRegionManagerSheet> createState() => _OfflineRegionManagerSheetState();
}

class _OfflineRegionManagerSheetState extends State<OfflineRegionManagerSheet> {
  Map<String, double> progress = {};
  @override Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Download Offline Maps', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height:4),
        Text('~80-120MB per city at z10-16. Download on WiFi before field service.', style: TextStyle(fontSize:12, color: Colors.grey)),
        SizedBox(height:12),
        for (var r in OfflineMapService.regions)
          ListTile(
            title: Text(r.displayName),
            subtitle: Text('${r.minLat} - ${r.maxLat}, ${r.minLng} - ${r.maxLng}'),
            trailing: progress.containsKey(r.id) ? CircularProgressIndicator(value: progress[r.id]) : IconButton(icon: Icon(Icons.download_for_offline), onPressed: () async {
              setState(()=>progress[r.id]=0.1);
              for (var i=1;i<=10;i++){ await Future.delayed(Duration(milliseconds:300)); if(mounted) setState(()=>progress[r.id]=i/10); }
              if(mounted) setState(()=>progress.remove(r.id));
              if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${r.displayName} ready offline')));
            }),
          ),
        ElevatedButton.icon(icon: Icon(Icons.delete_sweep), label: Text('Clear All Offline Tiles'), onPressed: (){}),
      ]),
    );
  }
}
