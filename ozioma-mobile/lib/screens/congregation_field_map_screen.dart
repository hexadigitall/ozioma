import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mb;
import 'package:geolocator/geolocator.dart' as geo;
import '../services/presence_service.dart';
import '../services/voice_guidance_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

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
  Map<String, dynamic>? activeTerritory;
  List<Map<String, dynamic>> assignments = [];
  final presence = PresenceService();
  final voice = VoiceGuidanceService();
  final Map<String, mb.PointAnnotation> brotherPins = {};
  bool voiceEnabled = true;
  bool shareLocation = false;

  @override
  void initState() {
    super.initState();
    voice.init();
    _initLocation();
    _loadAssignments();
  }

  Future<void> _initLocation() async {
    final perm = await geo.Geolocator.requestPermission();
    if (perm == geo.LocationPermission.denied || perm == geo.LocationPermission.deniedForever) {
      return;
    }

    posSub = geo.Geolocator.getPositionStream(
      locationSettings: const geo.LocationSettings(accuracy: geo.LocationAccuracy.high, distanceFilter: 10),
    ).listen((pos) {
      setState(() => myPosition = pos);
      _updateMyLocationPin();
      if (voiceEnabled && activeTerritory != null) {
        voice.updateLocation(pos);
      }
    });

    myPosition = await geo.Geolocator.getCurrentPosition();
  }

  Future<void> _loadAssignments() async {
    assignments = [
      {
        'id': 't14',
        'number': '#14',
        'name': 'Oakwood - Port Harcourt',
        'status': 'assigned',
        'start_lat': 4.821,
        'start_lng': 6.988,
        'stop_lat': 4.819,
        'stop_lng': 6.995,
        'boundary_geojson':
            '{"type":"Polygon","coordinates":[[[6.988,4.821],[6.995,4.821],[6.995,4.819],[6.988,4.819],[6.988,4.821]]]}',
      },
    ];
    if (assignments.isNotEmpty) {
      setState(() => activeTerritory = assignments.first);
    }
  }

  Future<void> _onMapCreated(mb.MapboxMap m) async {
    map = m;
    pinManager = await m.annotations.createPointAnnotationManager();
    lineManager = await m.annotations.createPolylineAnnotationManager();
    await _drawTerritories();
    await _updateMyLocationPin();
    await _drawRouteToStart();
  }

  Future<void> _drawTerritories() async {
    if (map == null || pinManager == null) return;
    await pinManager!.deleteAll();
    for (var t in assignments) {
      await pinManager!.create(mb.PointAnnotationOptions(
        geometry: mb.Point(coordinates: mb.Position(t['start_lng'] as num, t['start_lat'] as num)),
        iconSize: 1.2,
        textField: 'START ${t['number']}',
        textOffset: [0, 1.5],
      ));
      await pinManager!.create(mb.PointAnnotationOptions(
        geometry: mb.Point(coordinates: mb.Position(t['stop_lng'] as num, t['stop_lat'] as num)),
        iconSize: 1.2,
        textField: 'STOP ${t['number']}',
        textOffset: [0, 1.5],
      ));
    }
  }

  Future<void> _updateMyLocationPin() async {
    if (map == null || myPosition == null || pinManager == null) return;
    final oldPin = brotherPins['you'];
    if (oldPin != null) {
      await pinManager!.delete(oldPin);
    }
    final pin = await pinManager!.create(mb.PointAnnotationOptions(
      geometry: mb.Point(coordinates: mb.Position(myPosition!.longitude, myPosition!.latitude)),
      iconSize: 1.8,
      textField: 'You',
    ));
    brotherPins['you'] = pin;
  }

  Future<void> _drawRouteToStart() async {
    if (myPosition == null || activeTerritory == null || lineManager == null) return;
    await lineManager!.deleteAll();
    await lineManager!.create(mb.PolylineAnnotationOptions(
      geometry: mb.LineString(coordinates: [
        mb.Position(myPosition!.longitude, myPosition!.latitude),
        mb.Position(activeTerritory!['start_lng'] as num, activeTerritory!['start_lat'] as num),
      ]),
      lineColor: Colors.blue.toARGB32(),
      lineWidth: 4.0,
    ));
  }

  Future<void> _togglePresence() async {
    setState(() => shareLocation = !shareLocation);
    final messenger = ScaffoldMessenger.of(context);
    if (shareLocation && activeTerritory != null) {
      await presence.startBroadcasting(activeTerritory!['id'] as String, 'publisher_me');
      _listenForBrothers();
      messenger.showSnackBar(
        const SnackBar(content: Text('Field presence active: visible to service partners until 12:00 PM')),
      );
    } else {
      await presence.stopBroadcasting();
      await brotherSub?.cancel();
      brotherSub = null;
      if (pinManager != null) {
        for (var id in brotherPins.keys.where((k) => k != 'you').toList()) {
          final p = brotherPins[id];
          if (p != null) await pinManager!.delete(p);
        }
      }
      brotherPins.removeWhere((k, _) => k != 'you');
    }
  }

  void _listenForBrothers() {
    brotherSub?.cancel();
    brotherSub = presence.brotherLocationsStream.listen((brothers) async {
      if (!shareLocation || pinManager == null) return;
      for (final entry in brothers.entries) {
        final data = entry.value as Map<String, dynamic>;
        final lat = data['lat'] as double?;
        final lng = data['lng'] as double?;
        final name = data['display_name'] as String? ?? 'Brother';
        if (lat != null && lng != null) {
          final oldPin = brotherPins[entry.key];
          if (oldPin != null) await pinManager!.delete(oldPin);
          final p = await pinManager!.create(mb.PointAnnotationOptions(
            geometry: mb.Point(coordinates: mb.Position(lng, lat)),
            iconSize: 1.5,
            textField: name,
          ));
          brotherPins[entry.key] = p;
        }
      }
      setState(() {});
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
    final distToStart = myPosition != null && activeTerritory != null
        ? geo.Geolocator.distanceBetween(
            myPosition!.latitude,
            myPosition!.longitude,
            activeTerritory!['start_lat'] as double,
            activeTerritory!['start_lng'] as double,
          )
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Field Map'),
        actions: [
          IconButton(
            icon: Icon(voiceEnabled ? Icons.volume_up : Icons.volume_off),
            onPressed: () => setState(() => voiceEnabled = !voiceEnabled),
            tooltip: 'Voice Guidance',
          ),
          IconButton(
            icon: Icon(shareLocation ? Icons.people : Icons.people_outline),
            onPressed: _togglePresence,
            tooltip: 'Share Location',
          ),
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: () async {
              if (myPosition != null && map != null) {
                map!.flyTo(
                  mb.CameraOptions(
                    center: mb.Point(coordinates: mb.Position(myPosition!.longitude, myPosition!.latitude)),
                    zoom: 16,
                  ),
                  mb.MapAnimationOptions(duration: 1000),
                );
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          mb.MapWidget(
            styleUri: mb.MapboxStyles.MAPBOX_STREETS,
            cameraOptions: mb.CameraOptions(
              center: mb.Point(coordinates: mb.Position(6.99, 4.82)),
              zoom: 14,
            ),
            onMapCreated: _onMapCreated,
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black26)],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'START: ${activeTerritory?['name'] ?? ''}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text('${distToStart.toStringAsFixed(0)}m'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      Icon(Icons.flag, color: Colors.red),
                      SizedBox(width: 8),
                      Expanded(child: Text('STOP: Corner of Woji Rd')),
                      Text('2.1km route'),
                    ],
                  ),
                  if (shareLocation) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.people, color: Colors.blue, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${brotherPins.length > 1 ? brotherPins.length - 1 : 0} brothers visible',
                          style: const TextStyle(fontSize: 12, color: Colors.blue),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.directions),
                          label: const Text('Navigate'),
                          onPressed: () async {
                            if (activeTerritory != null && myPosition != null) {
                              await voice.loadRouteToStart(
                                activeTerritory!['start_lat'] as double,
                                activeTerritory!['start_lng'] as double,
                                myPosition!,
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Voice guidance: navigating to territory START')),
                                );
                              }
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.icon(
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Begin Work'),
                          onPressed: () {},
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
