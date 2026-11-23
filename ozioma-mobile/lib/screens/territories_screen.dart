import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/database/database_providers.dart';
import '../core/database/daos/territory_dao.dart';
import 'territory_map_screen.dart';
import 'territory_mapper_screen.dart';
import '../features/door_logging/territory_door_logger_screen.dart';

class TerritoriesScreen extends ConsumerStatefulWidget {
  const TerritoriesScreen({super.key});

  @override
  ConsumerState<TerritoriesScreen> createState() => _TerritoriesScreenState();
}

class _TerritoriesScreenState extends ConsumerState<TerritoriesScreen> {
  String selectedRegion = 'All';

  @override
  Widget build(BuildContext context) {
    final territoryDao = ref.watch(territoryDaoProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Territories'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_location_alt_outlined),
            tooltip: 'Walk New Territory',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TerritoryMapperScreen()),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: ['All', 'Port Harcourt', 'Lagos Metro', 'Calabar'].map((region) {
                final isSelected = selectedRegion == region;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(region),
                    selected: isSelected,
                    onSelected: (val) {
                      setState(() => selectedRegion = region);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<TerritoryItem>>(
        stream: territoryDao.watchTerritories(region: selectedRegion),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final territories = snapshot.data ?? [];

          if (territories.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.map_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text('No territories found for $selectedRegion', style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Map Perimeter Territory'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const TerritoryMapperScreen()),
                      );
                    },
                  )
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: territories.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final t = territories[index];
              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    child: Text(t.number.replaceAll('#', ''), style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  title: Text(t.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _buildStatusBadge(t.status),
                          const SizedBox(width: 8),
                          Text('${t.region} • ${t.assignedTo ?? 'Unassigned'}', style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: t.progress,
                        backgroundColor: Colors.grey.shade200,
                        color: const Color(0xFF10B981),
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.map_outlined),
                        tooltip: 'View Map',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TerritoryMapScreen(
                                territory: {
                                  'id': t.id,
                                  'number': t.number,
                                  'name': t.name,
                                  'region': t.region,
                                  'boundary_geojson': t.boundaryGeojson,
                                },
                                addresses: const [],
                              ),
                            ),
                          );
                        },
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TerritoryDoorLoggerScreen(
                          territoryId: t.id,
                          territoryNumber: t.number,
                          territoryName: t.name,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg = Colors.grey.shade200;
    Color fg = Colors.grey.shade700;

    if (status == 'assigned') {
      bg = Colors.blue.shade50;
      fg = Colors.blue.shade700;
    } else if (status == 'available') {
      bg = Colors.green.shade50;
      fg = Colors.green.shade700;
    } else if (status == 'completed') {
      bg = Colors.purple.shade50;
      fg = Colors.purple.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: fg)),
    );
  }
}
