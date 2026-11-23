import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Territory Split Info & Desktop GIS Handoff Screen
/// Under Ozioma dual-platform architecture (AGENTS.md), precision topological polygon carving
/// is executed natively in Ozioma Desktop using the Rust geo/geos topological engine.
class TerritorySplitScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> territory;
  const TerritorySplitScreen({super.key, required this.territory});
  @override
  ConsumerState<TerritorySplitScreen> createState() => _TerritorySplitScreenState();
}

class _TerritorySplitScreenState extends ConsumerState<TerritorySplitScreen> {
  MapboxMap? map;

  @override
  Widget build(BuildContext context) {
    final territoryNumber = widget.territory['number'] ?? '';
    final territoryName = widget.territory['name'] ?? '';

    return Scaffold(
      appBar: AppBar(title: Text('Split Territory $territoryNumber')),
      body: Stack(
        children: [
          MapWidget(
            styleUri: MapboxStyles.MAPBOX_STREETS,
            cameraOptions: CameraOptions(center: Point(coordinates: Position(6.99, 4.82)), zoom: 14),
            onMapCreated: (m) => map = m,
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.computer, color: Color(0xFF0F172A), size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Administrative GIS Operation',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Per theocratic administration standards, topological polygon subdivision for $territoryNumber ($territoryName) '
                      'is performed using Ozioma Desktop with mouse precision, vertex snapping, and official S-13 card re-generation.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Return to Territory Catalog'),
                        onPressed: () => Navigator.pop(context),
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
