import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../services/presence_service.dart';
import '../services/voice_guidance_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

class CongregationFieldMapScreen extends ConsumerStatefulWidget {
  const CongregationFieldMapScreen({super.key});
  @override ConsumerState<CongregationFieldMapScreen> createState() => _CongregationFieldMapScreenState();
}

class _CongregationFieldMapScreenState extends ConsumerState<CongregationFieldMapScreen> {
  MapboxMap? map;
  PointAnnotationManager? pinManager;
  PolylineAnnotationManager? lineManager;
  Position? myPosition;
  StreamSubscription<Position>? posSub;
  Map<String, dynamic>? activeTerritory;
  List<Map<String, dynamic>> assignments = [];
  final presence = PresenceService();
  final voice = VoiceGuidanceService();
  Map<String, PointAnnotation> brotherPins = {};
  bool voiceEnabled = true;
  bool shareLocation = false;

  @override void initState() {
    super.initState();
    voice.init();
    _initLocation();
    _loadAssignments();
  }

  Future<void> _initLocation() async {
    await Geolocator.requestPermission();
    posSub = Geolocator.getPositionStream(locationSettings: LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10)).listen((pos) {
      setState(()=>myPosition=pos);
      _updateMyLocationPin();
      if (voiceEnabled && activeTerritory != null) {
        voice.updateLocation(pos);
      }
    });
    myPosition = await Geolocator.getCurrentPosition();
  }

  Future<void> _loadAssignments() async {
    assignments = [
      {'id':'t14','number':'#14','name':'Oakwood - Port Harcourt','status':'assigned','start_lat':4.821,'start_lng':6.988,'stop_lat':4.819,'stop_lng':6.995,'boundary_geojson':'{"type":"Polygon","coordinates":[[[6.988,4.821],[6.995,4.821],[6.995,4.819],[6.988,4.819],[6.988,4.821]]]}'},
    ];
    setState(()=>activeTerritory = assignments.first);
  }

  Future<void> _onMapCreated(MapboxMap m) async {
    map = m;
    pinManager = await m.annotations.createPointAnnotationManager();
    lineManager = await m.annotations.createPolylineAnnotationManager();
    await _drawTerritories();
    await _updateMyLocationPin();
    await _drawRouteToStart();
  }

  Future<void> _drawTerritories() async {
    if (map == null) return;
    await pinManager!.deleteAll();
    for (var t in assignments) {
      await pinManager!.create(PointAnnotationOptions(
        geometry: Point(coordinates: Position(t['start_lng'], t['start_lat'])),
        iconSize: 1.2,
        textField: 'START ${t['number']}',
        textOffset: [0, 1.5],
      ));
      await pinManager!.create(PointAnnotationOptions(
        geometry: Point(coordinates: Position(t['stop_lng'], t['stop_lat'])),
        iconSize: 1.2,
        textField: 'STOP ${t['number']}',
        textOffset: [0, 1.5],
      ));
    }
  }

  Future<void> _updateMyLocationPin() async {
    if (map == null || myPosition == null) return;
    // Remove old "You" pin
    final oldPin = brotherPins['you'];
    if (oldPin != null && pinManager != null) {
      await pinManager!.delete(oldPin);
    }
    final pin = await pinManager!.create(PointAnnotationOptions(
      geometry: Point(coordinates: Position(myPosition!.longitude, myPosition!.latitude)),
      iconSize: 1.8,
      textField: 'You',
    ));
    brotherPins['you'] = pin;
  }

  Future<void> _drawRouteToStart() async {
    if (myPosition == null || activeTerritory == null) return;
    await lineManager!.deleteAll();
    await lineManager!.create(PolylineAnnotationOptions(
      geometry: LineString(coordinates: [
        Position(myPosition!.longitude, myPosition!.latitude),
        Position(activeTerritory!['start_lng'], activeTerritory!['start_lat']),
      ]),
      lineColor: Colors.blue.value,
      lineWidth: 4.0,
      lineDasharray: [2, 2],
    ));
  }

  Future<void> _togglePresence() async {
    setState(()=>shareLocation=!shareLocation);
    if (shareLocation && activeTerritory != null) {
      await presence.startBroadcasting(activeTerritory!['id'], 'publisher_me');
      _listenForBrothers();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Location sharing ON - visible to brothers in #14 until 12pm')));
    } else {
      await presence.stopBroadcasting();
      // remove other brother pins
      for (var id in brotherPins.keys.where((k)=>k!='you')) {
        await pinManager!.delete(brotherPins[id]!);
      }
      brotherPins.removeWhere((k,v)=>k!='you');
    }
  }

  void _listenForBrothers() {
    // Mock: add 2 brothers
    Future.delayed(Duration(seconds:2), () async {
      if (!shareLocation) return;
      final b1 = await pinManager!.create(PointAnnotationOptions(
        geometry: Point(coordinates: Position(6.990, 4.820)),
        iconSize: 1.5,
        textField: 'Bro. Emeka',
      ));
      brotherPins['emeka'] = b1;
      final b2 = await pinManager!.create(PointAnnotationOptions(
        geometry: Point(coordinates: Position(6.992, 4.818)),
        iconSize: 1.5,
        textField: 'Sis. Grace',
      ));
      brotherPins['grace'] = b2;
    });
  }

  @override void dispose() {
    posSub?.cancel();
    presence.stopBroadcasting();
    voice.stop();
    super.dispose();
  }

  @override Widget build(BuildContext context) {
    final distToStart = myPosition!=null && activeTerritory!=null ? Geolocator.distanceBetween(myPosition!.latitude, myPosition!.longitude, activeTerritory!['start_lat'], activeTerritory!['start_lng']) : 0;
    return Scaffold(
      appBar: AppBar(
        title: Text('Field Map'),
        actions: [
          IconButton(icon: Icon(voiceEnabled?Icons.volume_up:Icons.volume_off), onPressed: ()=>setState(()=>voiceEnabled=!voiceEnabled), tooltip: 'Voice Guidance'),
          IconButton(icon: Icon(shareLocation?Icons.people:Icons.people_outline), onPressed: _togglePresence, tooltip: 'Share Location'),
          IconButton(icon: Icon(Icons.my_location), onPressed: () async {
            if (myPosition != null && map != null) {
              map!.flyTo(CameraOptions(center: Point(coordinates: Position(myPosition!.longitude, myPosition!.latitude)), zoom: 16), MapAnimationOptions(duration: 1000));
            }
          }),
        ],
      ),
      body: Stack(children: [
        MapWidget(styleUri: MapboxStyles.MAPBOX_STREETS, cameraOptions: CameraOptions(center: Point(coordinates: Position(6.99,4.82)), zoom: 14), onMapCreated: _onMapCreated),
        Positioned(bottom: 0, left: 0, right: 0, child: Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(16)), boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black26)]),
          padding: EdgeInsets.all(16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              Icon(Icons.location_on, color: Colors.green), SizedBox(width:8),
              Expanded(child: Text('START: ${activeTerritory?['name']}', style: TextStyle(fontWeight: FontWeight.bold))),
              Text('${distToStart.toStringAsFixed(0)}m'),
            ]),
            SizedBox(height:8),
            Row(children: [
              Icon(Icons.flag, color: Colors.red), SizedBox(width:8),
              Expanded(child: Text('STOP: Corner of Woji Rd')),
              Text('2.1km route'),
            ]),
            if (shareLocation) ...[
              SizedBox(height:8),
              Row(children:[Icon(Icons.people, color: Colors.blue, size:16), SizedBox(width:4), Text('${brotherPins.length-1} brothers visible', style: TextStyle(fontSize:12, color: Colors.blue))]),
            ],
            SizedBox(height:12),
            Row(children: [
              Expanded(child: OutlinedButton.icon(icon: Icon(Icons.directions), label: Text('Navigate'), onPressed: () async {
                await voice.loadRouteToStart(activeTerritory!['start_lat'], activeTerritory!['start_lng'], myPosition!);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Voice guidance: 200 meters to START')));
              })),
              SizedBox(width:8),
              Expanded(child: FilledButton.icon(icon: Icon(Icons.play_arrow), label: Text('Begin Work'), onPressed: (){})),
            ])
          ]),
        ))
      ]),
    );
  }
}

extension on PointAnnotation? {
  void let(void Function(PointAnnotation) fn) { if (this != null) fn(this!); }
}
