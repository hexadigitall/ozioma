import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class OfflineMapRegionDef {
  final String id;
  final String displayName;
  final double minLat, maxLat, minLng, maxLng;
  final int minZoom, maxZoom;
  const OfflineMapRegionDef({
    required this.id,
    required this.displayName,
    required this.minLat,
    required this.maxLat,
    required this.minLng,
    required this.maxLng,
    this.minZoom = 10,
    this.maxZoom = 16,
  });
}

class OfflineMapService {
  static const regions = [
    OfflineMapRegionDef(id: 'ph_city', displayName: 'Port Harcourt', minLat: 4.72, maxLat: 5.02, minLng: 6.85, maxLng: 7.15),
    OfflineMapRegionDef(id: 'lagos_metro', displayName: 'Lagos Metro', minLat: 6.35, maxLat: 6.70, minLng: 2.95, maxLng: 3.85),
    OfflineMapRegionDef(id: 'calabar_city', displayName: 'Calabar', minLat: 4.85, maxLat: 5.15, minLng: 8.20, maxLng: 8.50),
  ];

  late final OfflineManager offlineManager;
  late final TileStore tileStore;

  Future<void> init() async {
    offlineManager = await OfflineManager.create();
    tileStore = await TileStore.createDefault();
    MapboxOptions.setAccessToken('YOUR_MAPBOX_TOKEN');
  }

  Future<void> downloadRegion(OfflineMapRegionDef region, {void Function(double)? onProgress}) async {
    final stylePack = StylePackLoadOptions(
      glyphsRasterizationMode: GlyphsRasterizationMode.IDEOGRAPHIC_RASTERIZED_LOCALLY,
      metadata: {'name': region.displayName},
    );
    await offlineManager.loadStylePack(MapboxStyles.MAPBOX_STREETS, stylePack, (p) => onProgress?.call(p * 0.2));

    final geometry = {
      'type': 'Polygon',
      'coordinates': [[
        [region.minLng, region.minLat],
        [region.maxLng, region.minLat],
        [region.maxLng, region.maxLat],
        [region.minLng, region.maxLat],
        [region.minLng, region.minLat],
      ]]
    };

    final tileOption = TileRegionLoadOptions(
      geometry: geometry,
      descriptors: [TilesetDescriptorOptions(styleURI: MapboxStyles.MAPBOX_STREETS, minZoom: region.minZoom, maxZoom: region.maxZoom)],
      metadata: {'name': region.id},
      acceptExpired: true,
      networkRestriction: NetworkRestriction.NONE,
    );

    await tileStore.loadTileRegion(region.id, tileOption, (progress) {
      final pct = 0.2 + (progress.completedResourceCount / (progress.requiredResourceCount == 0 ? 1 : progress.requiredResourceCount)) * 0.8;
      onProgress?.call(pct);
    });
  }

  Future<void> deleteRegion(String id) async { await tileStore.removeTileRegion(id); }
}
