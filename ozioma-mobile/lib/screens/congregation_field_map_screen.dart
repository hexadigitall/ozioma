import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mb;
import '../core/database/daos/collaboration_dao.dart';
import '../core/database/daos/congregation_dao.dart';
import '../core/database/daos/territory_dao.dart';
import '../core/database/database_providers.dart';
import '../core/theme/sunlight_palette.dart';
import '../features/door_logging/territory_door_logger_screen.dart';
import '../services/presence_service.dart';
import '../services/voice_guidance_service.dart';
import 'publisher_chat_screen.dart';

/// Live Congregation Field Map:
/// - Real territories synced from PowerSync SQLite (`TerritoryDao`)
/// - Territory coverage heatmap saturation overlay
/// - Location management & shared pins CRUD (`CollaborationDao`)
/// - Live publisher tracking (`PresenceService` + `publisher_locations`)
class CongregationFieldMapScreen extends ConsumerStatefulWidget {
  const CongregationFieldMapScreen({super.key});

  @override
  ConsumerState<CongregationFieldMapScreen> createState() => _CongregationFieldMapScreenState();
}

class _CongregationFieldMapScreenState extends ConsumerState<CongregationFieldMapScreen> {
  mb.MapboxMap? map;
  mb.PointAnnotationManager? pinManager;
  mb.PolylineAnnotationManager? lineManager;
  geo.Position? myPosition;
  StreamSubscription<geo.Position>? posSub;
  StreamSubscription<Map<String, dynamic>>? brotherSub;

  String? _selectedTerritoryId;
  final presence = PresenceService();
  final voice = VoiceGuidanceService();
  final Map<String, mb.PointAnnotation> _mapPins = {};

  bool voiceEnabled = true;
  bool shareLocation = false;
  bool showHeatmapOverlay = true;

  @override
  void initState() {
    super.initState();
    voice.init();
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      final perm = await geo.Geolocator.requestPermission();
      if (perm == geo.LocationPermission.denied || perm == geo.LocationPermission.deniedForever) {
        return;
      }

      posSub = geo.Geolocator.getPositionStream(
        locationSettings: const geo.LocationSettings(accuracy: geo.LocationAccuracy.high, distanceFilter: 10),
      ).listen((pos) {
        if (!mounted) return;
        setState(() => myPosition = pos);
        _updateMyLocationPin();
        if (voiceEnabled) {
          voice.updateLocation(pos);
        }
      });

      final current = await geo.Geolocator.getCurrentPosition();
      if (mounted) setState(() => myPosition = current);
    } catch (_) {
      // Location services disabled on emulator/host
    }
  }

  Future<void> _onMapCreated(mb.MapboxMap m) async {
    map = m;
    pinManager = await m.annotations.createPointAnnotationManager();
    lineManager = await m.annotations.createPolylineAnnotationManager();
    await _updateMyLocationPin();
  }

  Future<void> _syncMapAnnotations(
    List<TerritoryItem> territories,
    List<SharedPinItem> sharedPins,
    List<PublisherLocationItem> trackedPublishers,
  ) async {
    if (map == null || pinManager == null) return;
    await pinManager!.deleteAll();
    _mapPins.clear();

    for (final t in territories) {
      if (t.startLat != null && t.startLng != null) {
        await pinManager!.create(
          mb.PointAnnotationOptions(
            geometry: mb.Point(coordinates: mb.Position(t.startLng!, t.startLat!)),
            iconSize: 1.2,
            textField: '${t.number} (${(t.progress * 100).toStringAsFixed(0)}%)',
            textOffset: [0, 1.5],
          ),
        );
      }
    }

    for (final pin in sharedPins) {
      await pinManager!.create(
        mb.PointAnnotationOptions(
          geometry: mb.Point(coordinates: mb.Position(pin.longitude, pin.latitude)),
          iconSize: 1.3,
          textField: 'PIN: ${pin.title}',
          textOffset: [0, 1.5],
        ),
      );
    }

    for (final p in trackedPublishers) {
      await pinManager!.create(
        mb.PointAnnotationOptions(
          geometry: mb.Point(coordinates: mb.Position(p.longitude, p.latitude)),
          iconSize: 1.4,
          textField: p.displayName,
          textOffset: [0, 1.5],
        ),
      );
    }

    await _updateMyLocationPin();
  }

  Future<void> _updateMyLocationPin() async {
    if (map == null || myPosition == null || pinManager == null) return;
    final oldPin = _mapPins['you'];
    if (oldPin != null) {
      await pinManager!.delete(oldPin);
    }
    final pin = await pinManager!.create(
      mb.PointAnnotationOptions(
        geometry: mb.Point(coordinates: mb.Position(myPosition!.longitude, myPosition!.latitude)),
        iconSize: 1.7,
        textField: 'You',
      ),
    );
    _mapPins['you'] = pin;
  }

  Future<void> _togglePresence(
    TerritoryItem? activeTerritory,
    PublisherProfileItem? activePub,
    CollaborationDao collabDao,
    String congId,
  ) async {
    final nextState = !shareLocation;
    setState(() => shareLocation = nextState);
    final messenger = ScaffoldMessenger.of(context);
    final pubId = activePub?.id ?? 'device_publisher';
    final pubName = activePub?.displayName ?? 'Field Publisher';
    final pubRole = activePub?.role ?? 'publisher';

    if (nextState) {
      final permitted = await presence.startBroadcasting(
        activeTerritory?.id ?? 'congregation_field',
        pubId,
        displayName: pubName,
        onLocalCoordinate: (lat, lng) {
          collabDao.upsertPublisherLocation(
            congregationId: congId,
            publisherId: pubId,
            displayName: pubName,
            role: pubRole,
            territoryId: activeTerritory?.id ?? '',
            latitude: lat,
            longitude: lng,
          );
        },
      );
      if (!permitted && myPosition != null) {
        await collabDao.upsertPublisherLocation(
          congregationId: congId,
          publisherId: pubId,
          displayName: pubName,
          role: pubRole,
          territoryId: activeTerritory?.id ?? '',
          latitude: myPosition!.latitude,
          longitude: myPosition!.longitude,
        );
      }
      _listenForBrothers();
      messenger.showSnackBar(
        const SnackBar(content: Text('Publisher tracking active (with +/-15m privacy jitter)')),
      );
    } else {
      await presence.stopBroadcasting();
      await collabDao.stopTrackingPublisher(pubId);
      await brotherSub?.cancel();
      brotherSub = null;
    }
  }

  void _listenForBrothers() {
    brotherSub?.cancel();
    brotherSub = presence.brotherLocationsStream.listen((brothers) async {
      if (!shareLocation || pinManager == null) return;
      for (final entry in brothers.entries) {
        final data = entry.value as Map<String, dynamic>;
        final lat = (data['lat'] as num?)?.toDouble();
        final lng = (data['lng'] as num?)?.toDouble();
        final name = data['display_name'] as String? ?? 'Partner';
        if (lat != null && lng != null) {
          final oldPin = _mapPins[entry.key];
          if (oldPin != null) await pinManager!.delete(oldPin);
          final p = await pinManager!.create(
            mb.PointAnnotationOptions(
              geometry: mb.Point(coordinates: mb.Position(lng, lat)),
              iconSize: 1.5,
              textField: name,
            ),
          );
          _mapPins[entry.key] = p;
        }
      }
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    posSub?.cancel();
    brotherSub?.cancel();
    presence.dispose();
    voice.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final territoryDao = ref.watch(territoryDaoProvider);
    final collabDao = ref.watch(collaborationDaoProvider);
    final congDao = ref.watch(congregationDaoProvider);

    return StreamBuilder<PublisherProfileItem?>(
      stream: congDao.watchActivePublisher(),
      builder: (context, pubSnap) {
        final activePub = pubSnap.data;
        final activeCongId = activePub?.congregationId ?? '';

        return StreamBuilder<List<TerritoryItem>>(
          stream: territoryDao.watchTerritories(congregationId: activeCongId),
          builder: (context, tSnap) {
            final territories = tSnap.data ?? [];
            TerritoryItem? activeTerritory;
            if (territories.isNotEmpty) {
              activeTerritory = territories.firstWhere(
                (t) => t.id == _selectedTerritoryId,
                orElse: () => territories.first,
              );
            }

            return StreamBuilder<List<SharedPinItem>>(
              stream: collabDao.watchSharedPins(congregationId: activeCongId),
              builder: (context, pinSnap) {
                final sharedPins = pinSnap.data ?? [];

                return StreamBuilder<List<PublisherLocationItem>>(
                  stream: collabDao.watchTrackedPublishers(congregationId: activeCongId),
                  builder: (context, locSnap) {
                    final trackedPublishers = locSnap.data ?? [];

                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted && map != null) {
                        _syncMapAnnotations(territories, sharedPins, trackedPublishers);
                      }
                    });

                    final distToStart = (myPosition != null &&
                            activeTerritory?.startLat != null &&
                            activeTerritory?.startLng != null)
                        ? geo.Geolocator.distanceBetween(
                            myPosition!.latitude,
                            myPosition!.longitude,
                            activeTerritory!.startLat!,
                            activeTerritory.startLng!,
                          )
                        : null;

                    return Scaffold(
                      appBar: AppBar(
                        title: const Text('Live Field Map & Heatmap'),
                        actions: [
                          IconButton(
                            icon: Icon(
                              showHeatmapOverlay ? Icons.layers : Icons.layers_outlined,
                              color: showHeatmapOverlay ? SunlightPalette.sunlightYellow : null,
                            ),
                            tooltip: 'Toggle Territory Heatmap Overlay',
                            onPressed: () => setState(() => showHeatmapOverlay = !showHeatmapOverlay),
                          ),
                          IconButton(
                            icon: Icon(
                              shareLocation ? Icons.gps_fixed : Icons.gps_not_fixed,
                              color: shareLocation ? SunlightPalette.highVisGreen : null,
                            ),
                            tooltip: 'Toggle Publisher Live Tracking',
                            onPressed: () => _togglePresence(activeTerritory, activePub, collabDao, activeCongId),
                          ),
                          IconButton(
                            icon: const Icon(Icons.forum_outlined),
                            tooltip: 'Congregation Chat',
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const PublisherChatScreen()),
                            ),
                          ),
                        ],
                      ),
                      body: Stack(
                        children: [
                          mb.MapWidget(
                            styleUri: mb.MapboxStyles.MAPBOX_STREETS,
                            cameraOptions: mb.CameraOptions(
                              center: mb.Point(
                                coordinates: mb.Position(
                                  activeTerritory?.startLng ?? myPosition?.longitude ?? 6.99,
                                  activeTerritory?.startLat ?? myPosition?.latitude ?? 4.82,
                                ),
                              ),
                              zoom: 14,
                            ),
                            onMapCreated: _onMapCreated,
                          ),

                          // Top Live Territory Coverage Heatmap & Tracker Ribbon
                          if (showHeatmapOverlay)
                            Positioned(
                              top: 10,
                              left: 12,
                              right: 12,
                              child: Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.local_fire_department, size: 16, color: SunlightPalette.sunlightYellow),
                                          const SizedBox(width: 6),
                                          const Expanded(
                                            child: Text(
                                              'Active Territory Coverage Heatmap',
                                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                                            ),
                                          ),
                                          Text(
                                            '${trackedPublishers.length} live • ${sharedPins.length} pins',
                                            style: const TextStyle(fontSize: 11, color: SunlightPalette.highVisCyan, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                      if (territories.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        SizedBox(
                                          height: 36,
                                          child: ListView.separated(
                                            scrollDirection: Axis.horizontal,
                                            itemCount: territories.length,
                                            separatorBuilder: (_, __) => const SizedBox(width: 6),
                                            itemBuilder: (_, idx) {
                                              final t = territories[idx];
                                              final pct = (t.progress * 100).round();
                                              final heatColor = pct >= 75
                                                  ? SunlightPalette.highVisGreen
                                                  : (pct >= 30 ? SunlightPalette.sunlightYellow : SunlightPalette.highVisRed);
                                              final isSel = activeTerritory?.id == t.id;
                                              return ChoiceChip(
                                                selected: isSel,
                                                avatar: CircleAvatar(
                                                  backgroundColor: heatColor,
                                                  radius: 6,
                                                ),
                                                label: Text('${t.number} ($pct%)', style: const TextStyle(fontSize: 11)),
                                                onSelected: (_) => setState(() => _selectedTerritoryId = t.id),
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),

                          // Bottom Live Sync Controls, Pins CRUD & Active Territory Card
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Card(
                              margin: EdgeInsets.zero,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (activeTerritory != null) ...[
                                      Row(
                                        children: [
                                          Image.asset(
                                            activeTerritory.status == 'completed'
                                                ? 'assets/icons/pin_territory_completed.png'
                                                : 'assets/icons/pin_territory_active.png',
                                            width: 24,
                                            height: 24,
                                            errorBuilder: (_, __, ___) => const Icon(Icons.location_on, color: SunlightPalette.highVisGreen),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '${activeTerritory.number} ${activeTerritory.name}',
                                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                                                ),
                                                Text(
                                                  '${activeTerritory.visitedAddresses}/${activeTerritory.totalAddresses} doors • ${activeTerritory.rvAddresses} RVs • ${activeTerritory.dncAddresses} DNC',
                                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (distToStart != null)
                                            Chip(
                                              label: Text('${distToStart.toStringAsFixed(0)}m'),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                    ] else
                                      const Padding(
                                        padding: EdgeInsets.only(bottom: 10),
                                        child: Text(
                                          'No territory selected. Map or register a territory to navigate & log doors.',
                                          style: TextStyle(fontSize: 12, color: Colors.grey),
                                        ),
                                      ),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            icon: const Icon(Icons.push_pin_outlined, size: 18),
                                            label: Text('Pins (${sharedPins.length})'),
                                            onPressed: () => _showPinManagerSheet(
                                              context,
                                              collabDao,
                                              activeCongId,
                                              activeTerritory?.id ?? '',
                                              activePub,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: FilledButton.icon(
                                            icon: const Icon(Icons.door_front_door_outlined, size: 18),
                                            label: const Text('Begin Work'),
                                            onPressed: activeTerritory == null
                                                ? null
                                                : () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (_) => TerritoryDoorLoggerScreen(
                                                          territoryId: activeTerritory!.id,
                                                          territoryNumber: activeTerritory.number,
                                                          territoryName: activeTerritory.name,
                                                        ),
                                                      ),
                                                    );
                                                  },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _showPinManagerSheet(
    BuildContext context,
    CollaborationDao collabDao,
    String congId,
    String territoryId,
    PublisherProfileItem? activePub,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => StreamBuilder<List<SharedPinItem>>(
        stream: collabDao.watchSharedPins(congregationId: congId),
        builder: (ctx, snap) {
          final pins = snap.data ?? [];
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Shared Locations & Pins', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    FilledButton.tonalIcon(
                      icon: const Icon(Icons.add_location_alt),
                      label: const Text('Drop Pin'),
                      onPressed: () => _showPinFormModal(ctx, collabDao, congId, territoryId, activePub),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (pins.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text('No shared location pins yet.', style: TextStyle(color: Colors.grey)),
                  )
                else
                  ...pins.map(
                    (p) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.location_pin, color: SunlightPalette.highVisGreen),
                      title: Text(p.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        '${p.category} • ${p.latitude.toStringAsFixed(4)}, ${p.longitude.toStringAsFixed(4)} • by ${p.createdBy}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => _showPinFormModal(ctx, collabDao, congId, territoryId, activePub, existing: p),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                            onPressed: () => collabDao.deleteSharedPin(p.id),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showPinFormModal(
    BuildContext context,
    CollaborationDao dao,
    String congId,
    String territoryId,
    PublisherProfileItem? activePub, {
    SharedPinItem? existing,
  }) async {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final latCtrl = TextEditingController(
      text: (existing?.latitude ?? myPosition?.latitude ?? 4.821).toStringAsFixed(5),
    );
    final lngCtrl = TextEditingController(
      text: (existing?.longitude ?? myPosition?.longitude ?? 6.988).toStringAsFixed(5),
    );
    final notesCtrl = TextEditingController(text: existing?.notes ?? '');
    String category = existing?.category ?? 'meeting_point';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            left: 16,
            right: 16,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(existing == null ? 'Drop Shared Location Pin' : 'Edit Shared Pin', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Title *', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: category,
                decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'meeting_point', child: Text('Meeting Point')),
                  DropdownMenuItem(value: 'parking', child: Text('Parking')),
                  DropdownMenuItem(value: 'rv_hotspot', child: Text('RV Hotspot')),
                  DropdownMenuItem(value: 'cart_site', child: Text('Cart Witnessing Site')),
                  DropdownMenuItem(value: 'hazard_gate', child: Text('Hazard / Locked Gate')),
                ],
                onChanged: (v) {
                  if (v != null) setModalState(() => category = v);
                },
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: latCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                      decoration: const InputDecoration(labelText: 'Latitude', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: lngCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                      decoration: const InputDecoration(labelText: 'Longitude', border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: notesCtrl,
                decoration: const InputDecoration(labelText: 'Notes / Directions', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.save),
                  label: Text(existing == null ? 'Save & Share Pin' : 'Update Pin'),
                  onPressed: () async {
                    if (titleCtrl.text.trim().isEmpty) return;
                    HapticFeedback.lightImpact();
                    final lat = double.tryParse(latCtrl.text.trim()) ?? 0.0;
                    final lng = double.tryParse(lngCtrl.text.trim()) ?? 0.0;
                    if (existing == null) {
                      await dao.createSharedPin(
                        congregationId: congId,
                        territoryId: territoryId,
                        createdBy: activePub?.displayName ?? 'Publisher',
                        title: titleCtrl.text.trim(),
                        category: category,
                        latitude: lat,
                        longitude: lng,
                        notes: notesCtrl.text.trim(),
                      );
                    } else {
                      await dao.updateSharedPin(
                        id: existing.id,
                        title: titleCtrl.text.trim(),
                        category: category,
                        latitude: lat,
                        longitude: lng,
                        notes: notesCtrl.text.trim(),
                      );
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
