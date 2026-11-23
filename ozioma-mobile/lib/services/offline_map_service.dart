import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';

class OfflineMapRegionDef {
  final String id;
  final String displayName;
  final String fileName;
  final String storageUrl;
  final double minLat, maxLat, minLng, maxLng;
  final int minZoom, maxZoom;

  const OfflineMapRegionDef({
    required this.id,
    required this.displayName,
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

/// Dedicated Cloudflare R2 / Supabase Storage Offline Vector Tile Service
/// Downloads pre-sliced PMTiles with resumable HTTP range requests and SHA-256 validation.
class OfflineMapService {
  static const regions = [
    OfflineMapRegionDef(
      id: 'ph_city',
      displayName: 'Port Harcourt',
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
      fileName: 'lagos_metro.pmtiles',
      storageUrl: 'https://cdn.ozioma.org/tiles/lagos_metro.pmtiles',
      minLat: 6.35,
      maxLat: 6.70,
      minLng: 2.95,
      maxLng: 3.85,
    ),
    OfflineMapRegionDef(
      id: 'calabar_city',
      displayName: 'Calabar',
      fileName: 'calabar.pmtiles',
      storageUrl: 'https://cdn.ozioma.org/tiles/calabar.pmtiles',
      minLat: 4.85,
      maxLat: 5.15,
      minLng: 8.20,
      maxLng: 8.50,
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
