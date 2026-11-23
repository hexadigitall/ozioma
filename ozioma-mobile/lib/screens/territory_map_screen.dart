import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../services/offline_map_service.dart';

class TerritoryMapScreen extends StatefulWidget {
  final Map<String, dynamic> territory;
  final List<Map<String, dynamic>> addresses;
  const TerritoryMapScreen({super.key, required this.territory, required this.addresses});
  @override
  State<TerritoryMapScreen> createState() => _TerritoryMapScreenState();
}

class _TerritoryMapScreenState extends State<TerritoryMapScreen> {
  MapboxMap? mapbox;
  final offline = OfflineMapService();
  @override
  void initState() {
    super.initState();
    offline.init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.territory['name'] ?? 'Map')),
      body: Stack(
        children: [
          MapWidget(
            styleUri: MapboxStyles.MAPBOX_STREETS,
            cameraOptions: CameraOptions(center: Point(coordinates: Position(6.99, 4.82)), zoom: 14),
            onMapCreated: (m) {
              mapbox = m;
            },
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.offline_bolt, color: Colors.green),
                    const SizedBox(width: 8),
                    const Expanded(child: Text('Offline tiles active')),
                    IconButton(
                      icon: const Icon(Icons.layers),
                      onPressed: () => showModalBottomSheet(
                        context: context,
                        builder: (_) => const OfflineRegionManagerSheet(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OfflineRegionManagerSheet extends StatefulWidget {
  const OfflineRegionManagerSheet({super.key});
  @override
  State<OfflineRegionManagerSheet> createState() => _OfflineRegionManagerSheetState();
}

class _OfflineRegionManagerSheetState extends State<OfflineRegionManagerSheet> {
  Map<String, double> progress = {};
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Download Offline Maps', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text(
            '~80-120MB per city at z10-16. Download on WiFi before field service.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          for (var r in OfflineMapService.regions)
            ListTile(
              title: Text(r.displayName),
              subtitle: Text('${r.minLat} - ${r.maxLat}, ${r.minLng} - ${r.maxLng}'),
              trailing: progress.containsKey(r.id)
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(value: progress[r.id], strokeWidth: 3),
                    )
                  : IconButton(
                      icon: const Icon(Icons.download_for_offline, color: Colors.blue),
                      onPressed: () async {
                        final svc = OfflineMapService();
                        final messenger = ScaffoldMessenger.of(context);
                        setState(() => progress[r.id] = 0.05);
                        try {
                          await svc.downloadRegion(
                            r,
                            onProgress: (pct) {
                              if (mounted) setState(() => progress[r.id] = pct);
                            },
                          );
                          if (mounted) {
                            setState(() => progress.remove(r.id));
                            messenger.showSnackBar(
                              SnackBar(content: Text('${r.displayName} PMTiles cached offline')),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            setState(() => progress.remove(r.id));
                            messenger.showSnackBar(
                              SnackBar(content: Text('Download failed: $e')),
                            );
                          }
                        }
                      },
                    ),
            ),
          ElevatedButton.icon(
            icon: const Icon(Icons.delete_sweep),
            label: const Text('Clear All Offline Tiles'),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
