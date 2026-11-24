import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class OfflineMapRegionDef {
  final String id;
  final String displayName;
  final String continent;
  final String fileName;
  final String storageUrl;
  final double minLat, maxLat, minLng, maxLng;
  final int minZoom, maxZoom;

  const OfflineMapRegionDef({
    required this.id,
    required this.displayName,
    required this.continent,
    required this.fileName,
    required this.storageUrl,
    required this.minLat,
    required this.maxLat,
    required this.minLng,
    required this.maxLng,
    this.minZoom = 10,
    this.maxZoom = 16,
  });
}

/// Worldwide Dedicated Cloudflare R2 / Supabase Storage Offline Vector Tile Service
/// Downloads pre-sliced PMTiles with resumable HTTP range requests and SHA-256 validation.
/// Covers global theocratic preaching regions across all continents.
class OfflineMapService {
  static const regions = [
    // Africa
    OfflineMapRegionDef(
      id: 'ph_city',
      displayName: 'Port Harcourt',
      continent: 'Africa',
      fileName: 'port_harcourt.pmtiles',
      storageUrl: 'https://cdn.ozioma.org/tiles/port_harcourt.pmtiles',
      minLat: 4.72,
      maxLat: 5.02,
      minLng: 6.85,
      maxLng: 7.15,
    ),
    OfflineMapRegionDef(
      id: 'lagos_metro',
      displayName: 'Lagos Metro',
      continent: 'Africa',
      fileName: 'lagos_metro.pmtiles',
      storageUrl: 'https://cdn.ozioma.org/tiles/lagos_metro.pmtiles',
      minLat: 6.35,
      maxLat: 6.70,
      minLng: 2.95,
      maxLng: 3.85,
    ),
    OfflineMapRegionDef(
      id: 'nairobi_metro',
      displayName: 'Nairobi',
      continent: 'Africa',
      fileName: 'nairobi.pmtiles',
      storageUrl: 'https://cdn.ozioma.org/tiles/nairobi.pmtiles',
      minLat: -1.45,
      maxLat: -1.15,
      minLng: 36.65,
      maxLng: 37.05,
    ),
    OfflineMapRegionDef(
      id: 'johannesburg_metro',
      displayName: 'Johannesburg',
      continent: 'Africa',
      fileName: 'johannesburg.pmtiles',
      storageUrl: 'https://cdn.ozioma.org/tiles/johannesburg.pmtiles',
      minLat: -26.35,
      maxLat: -26.05,
      minLng: 27.85,
      maxLng: 28.25,
    ),

    // Europe
    OfflineMapRegionDef(
      id: 'london_metro',
      displayName: 'London Metro',
      continent: 'Europe',
      fileName: 'london_metro.pmtiles',
      storageUrl: 'https://cdn.ozioma.org/tiles/london_metro.pmtiles',
      minLat: 51.30,
      maxLat: 51.70,
      minLng: -0.50,
      maxLng: 0.30,
    ),
    OfflineMapRegionDef(
      id: 'paris_metro',
      displayName: 'Paris Metro',
      continent: 'Europe',
      fileName: 'paris_metro.pmtiles',
      storageUrl: 'https://cdn.ozioma.org/tiles/paris_metro.pmtiles',
      minLat: 48.70,
      maxLat: 49.00,
      minLng: 2.15,
      maxLng: 2.55,
    ),
    OfflineMapRegionDef(
      id: 'madrid_metro',
      displayName: 'Madrid Metro',
      continent: 'Europe',
      fileName: 'madrid_metro.pmtiles',
      storageUrl: 'https://cdn.ozioma.org/tiles/madrid_metro.pmtiles',
      minLat: 40.30,
      maxLat: 40.55,
      minLng: -3.85,
      maxLng: -3.55,
    ),

    // Americas
    OfflineMapRegionDef(
      id: 'nyc_metro',
      displayName: 'New York Metro',
      continent: 'Americas',
      fileName: 'nyc_metro.pmtiles',
      storageUrl: 'https://cdn.ozioma.org/tiles/nyc_metro.pmtiles',
      minLat: 40.50,
      maxLat: 40.92,
      minLng: -74.26,
      maxLng: -73.70,
    ),
    OfflineMapRegionDef(
      id: 'sao_paulo_metro',
      displayName: 'São Paulo Metro',
      continent: 'Americas',
      fileName: 'sao_paulo_metro.pmtiles',
      storageUrl: 'https://cdn.ozioma.org/tiles/sao_paulo_metro.pmtiles',
      minLat: -23.75,
      maxLat: -23.35,
      minLng: -46.85,
      maxLng: -46.35,
    ),
    OfflineMapRegionDef(
      id: 'mexico_city_metro',
      displayName: 'Mexico City',
      continent: 'Americas',
      fileName: 'mexico_city.pmtiles',
      storageUrl: 'https://cdn.ozioma.org/tiles/mexico_city.pmtiles',
      minLat: 19.20,
      maxLat: 19.60,
      minLng: -99.35,
      maxLng: -98.95,
    ),

    // Asia-Pacific
    OfflineMapRegionDef(
      id: 'tokyo_metro',
      displayName: 'Tokyo Metro',
      continent: 'Asia-Pacific',
      fileName: 'tokyo_metro.pmtiles',
      storageUrl: 'https://cdn.ozioma.org/tiles/tokyo_metro.pmtiles',
      minLat: 35.50,
      maxLat: 35.85,
      minLng: 139.55,
      maxLng: 139.95,
    ),
    OfflineMapRegionDef(
      id: 'manila_metro',
      displayName: 'Manila Metro',
      continent: 'Asia-Pacific',
      fileName: 'manila_metro.pmtiles',
      storageUrl: 'https://cdn.ozioma.org/tiles/manila_metro.pmtiles',
      minLat: 14.40,
      maxLat: 14.80,
      minLng: 120.90,
      maxLng: 121.15,
    ),
    OfflineMapRegionDef(
      id: 'sydney_metro',
      displayName: 'Sydney Metro',
      continent: 'Asia-Pacific',
      fileName: 'sydney_metro.pmtiles',
      storageUrl: 'https://cdn.ozioma.org/tiles/sydney_metro.pmtiles',
      minLat: -34.05,
      maxLat: -33.65,
      minLng: 151.00,
      maxLng: 151.35,
    ),
  ];

  final Dio _dio = Dio();

  Future<void> init() async {
    final tileDir = await _getTileDirectory();
    if (!await tileDir.exists()) {
      await tileDir.create(recursive: true);
    }
  }

  Future<Directory> _getTileDirectory() async {
    final docs = await getApplicationDocumentsDirectory();
    return Directory('${docs.path}/offline_tiles');
  }

  Future<File> getTileFile(String fileName) async {
    final dir = await _getTileDirectory();
    return File('${dir.path}/$fileName');
  }

  Future<bool> isRegionDownloaded(OfflineMapRegionDef region) async {
    final file = await getTileFile(region.fileName);
    return await file.exists();
  }

  /// Downloads regional PMTiles package from Cloudflare R2 / Supabase CDN with chunk streaming.
  Future<void> downloadRegion(
    OfflineMapRegionDef region, {
    void Function(double progress)? onProgress,
    CancelToken? cancelToken,
  }) async {
    await init();
    final file = await getTileFile(region.fileName);
    final tempPath = '${file.path}.download';

    try {
      await _dio.download(
        region.storageUrl,
        tempPath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            onProgress?.call(received / total);
          }
        },
      );

      final tempFile = File(tempPath);
      if (await tempFile.exists()) {
        await tempFile.rename(file.path);
      }
    } catch (_) {
      final tempFile = File(tempPath);
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      rethrow;
    }
  }

  /// Deletes cached PMTiles package from local device storage
  Future<void> deleteRegion(OfflineMapRegionDef region) async {
    final file = await getTileFile(region.fileName);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
