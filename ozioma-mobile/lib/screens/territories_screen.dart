import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/database/daos/congregation_dao.dart';
import '../core/database/daos/territory_dao.dart';
import '../core/database/database_providers.dart';
import '../core/theme/sunlight_palette.dart';
import '../features/door_logging/territory_door_logger_screen.dart';
import 'congregation_field_map_screen.dart';
import 'publisher_chat_screen.dart';
import 'territory_map_screen.dart';
import 'territory_mapper_screen.dart';

class TerritoriesScreen extends ConsumerStatefulWidget {
  const TerritoriesScreen({super.key});

  @override
  ConsumerState<TerritoriesScreen> createState() => _TerritoriesScreenState();
}

class _TerritoriesScreenState extends ConsumerState<TerritoriesScreen> {
  String _selectedStatus = 'all';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final territoryDao = ref.watch(territoryDaoProvider);
    final congDao = ref.watch(congregationDaoProvider);

    return StreamBuilder<PublisherProfileItem?>(
      stream: congDao.watchActivePublisher(),
      builder: (context, pubSnap) {
        final activePub = pubSnap.data;
        final activeCongId = activePub?.congregationId ?? '';
        final canManage = activePub == null || TheocraticRolePermissions.canManageTerritories(activePub.role);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Territories & Heatmap'),
            actions: [
              IconButton(
                icon: const Icon(Icons.layers),
                tooltip: 'Live Congregation Map & Heatmap',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CongregationFieldMapScreen()),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.forum_outlined),
                tooltip: 'Publisher Chat & Pins',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PublisherChatScreen()),
                  );
                },
              ),
              if (canManage)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.add_location_alt_outlined),
                  tooltip: 'Add Territory',
                  onSelected: (val) {
                    if (val == 'walk') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const TerritoryMapperScreen()),
                      );
                    } else if (val == 'manual') {
                      _showTerritoryCrudModal(context, territoryDao, activeCongId);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'manual', child: Text('Create Territory Form')),
                    PopupMenuItem(value: 'walk', child: Text('GPS Perimeter Walk Mapper')),
                  ],
                ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(98),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Column(
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search territory #, area, assignee...',
                        prefixIcon: Icon(Icons.search),
                        isDense: true,
                      ),
                      onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ['all', 'available', 'assigned', 'completed'].map((st) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(st.toUpperCase()),
                              selected: _selectedStatus == st,
                              onSelected: (_) => setState(() => _selectedStatus = st),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          body: StreamBuilder<List<TerritoryItem>>(
            stream: territoryDao.watchTerritories(congregationId: activeCongId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final all = snapshot.data ?? [];
              final filtered = all.where((t) {
                if (_selectedStatus != 'all' && t.status != _selectedStatus) return false;
                if (_searchQuery.isNotEmpty) {
                  final hay = '${t.number} ${t.name} ${t.region} ${t.assignedTo ?? ''}'.toLowerCase();
                  if (!hay.contains(_searchQuery)) return false;
                }
                return true;
              }).toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.map_outlined, size: 64, color: Colors.grey),
                        const SizedBox(height: 12),
                        Text(
                          all.isEmpty ? 'No territories registered yet' : 'No territories match filter',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Register territory cards manually or map boundaries by walking the perimeter with GPS.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        if (canManage)
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            alignment: WrapAlignment.center,
                            children: [
                              FilledButton.icon(
                                icon: const Icon(Icons.add),
                                label: const Text('Create Territory'),
                                onPressed: () => _showTerritoryCrudModal(context, territoryDao, activeCongId),
                              ),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.directions_walk),
                                label: const Text('Walk Perimeter'),
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const TerritoryMapperScreen()),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 80),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final t = filtered[index];
                  final pct = (t.progress * 100).round();
                  final heatColor = pct >= 75
                      ? SunlightPalette.highVisGreen
                      : (pct >= 30 ? SunlightPalette.sunlightYellow : SunlightPalette.highVisRed);

                  return Card(
                    margin: EdgeInsets.zero,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
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
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: heatColor.withValues(alpha: 0.2),
                                  foregroundColor: heatColor,
                                  child: Text(
                                    t.number.replaceAll('#', ''),
                                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(t.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                                      Text(
                                        '${t.region} • ${t.assignedTo ?? 'Available'}',
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.map_outlined),
                                  tooltip: 'Offline Map View',
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
                                PopupMenuButton<String>(
                                  onSelected: (val) async {
                                    if (val == 'assign' && canManage) {
                                      await _showAssignModal(context, territoryDao, congDao, t, activeCongId);
                                    } else if (val == 'complete') {
                                      await territoryDao.updateStatus(t.id, 'completed');
                                    } else if (val == 'return' && canManage) {
                                      await territoryDao.returnTerritory(t.id);
                                    } else if (val == 'edit' && canManage) {
                                      await _showTerritoryCrudModal(context, territoryDao, activeCongId, existing: t);
                                    } else if (val == 'delete' && canManage) {
                                      await _confirmDeleteTerritory(context, territoryDao, t);
                                    }
                                  },
                                  itemBuilder: (_) => [
                                    if (canManage)
                                      const PopupMenuItem(value: 'assign', child: Text('Assign to Publisher')),
                                    const PopupMenuItem(value: 'complete', child: Text('Mark Completed')),
                                    if (canManage)
                                      const PopupMenuItem(value: 'return', child: Text('Check In / Make Available')),
                                    if (canManage) const PopupMenuItem(value: 'edit', child: Text('Edit Territory')),
                                    if (canManage) const PopupMenuItem(value: 'delete', child: Text('Delete Territory')),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                _buildStatusBadge(t.status),
                                const SizedBox(width: 8),
                                Text(
                                  '$pct% heatmap • ${t.visitedAddresses}/${t.totalAddresses} doors • ${t.dncAddresses} DNC',
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: t.progress,
                                minHeight: 6,
                                valueColor: AlwaysStoppedAnimation<Color>(heatColor),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
          floatingActionButton: canManage
              ? FloatingActionButton.extended(
                  icon: const Icon(Icons.add),
                  label: const Text('New Territory'),
                  onPressed: () => _showTerritoryCrudModal(context, territoryDao, activeCongId),
                )
              : null,
        );
      },
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.grey;
    if (status == 'assigned') color = SunlightPalette.highVisCyan;
    if (status == 'available') color = SunlightPalette.highVisGreen;
    if (status == 'completed') color = SunlightPalette.sunlightYellow;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Future<void> _showTerritoryCrudModal(
    BuildContext context,
    TerritoryDao dao,
    String congregationId, {
    TerritoryItem? existing,
  }) async {
    final numCtrl = TextEditingController(text: existing?.number ?? '#');
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final regionCtrl = TextEditingController(text: existing?.region ?? 'General');
    final latCtrl = TextEditingController(text: '${existing?.startLat ?? 4.821}');
    final lngCtrl = TextEditingController(text: '${existing?.startLng ?? 6.988}');
    String status = existing?.status ?? 'available';

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
              Text(
                existing == null ? 'Register Territory' : 'Edit Territory',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: numCtrl,
                      decoration: const InputDecoration(labelText: 'Number *', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Territory Name *', border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: regionCtrl,
                decoration: const InputDecoration(labelText: 'City / Region', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: status,
                decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'available', child: Text('Available')),
                  DropdownMenuItem(value: 'assigned', child: Text('Assigned')),
                  DropdownMenuItem(value: 'completed', child: Text('Completed')),
                  DropdownMenuItem(value: 'archived', child: Text('Archived')),
                ],
                onChanged: (v) {
                  if (v != null) setModalState(() => status = v);
                },
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: latCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                      decoration: const InputDecoration(labelText: 'Start Latitude', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: lngCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                      decoration: const InputDecoration(labelText: 'Start Longitude', border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.save),
                  label: Text(existing == null ? 'Save Territory' : 'Update Territory'),
                  onPressed: () async {
                    if (nameCtrl.text.trim().isEmpty) return;
                    HapticFeedback.lightImpact();
                    final lat = double.tryParse(latCtrl.text.trim()) ?? 4.821;
                    final lng = double.tryParse(lngCtrl.text.trim()) ?? 6.988;

                    if (existing == null) {
                      final poly = jsonEncode({
                        'type': 'Polygon',
                        'coordinates': [
                          [
                            [lng, lat],
                            [lng + 0.005, lat],
                            [lng + 0.005, lat - 0.004],
                            [lng, lat - 0.004],
                            [lng, lat],
                          ],
                        ],
                      });
                      await dao.createTerritory(
                        number: numCtrl.text.trim().isEmpty ? '#1' : numCtrl.text.trim(),
                        name: nameCtrl.text.trim(),
                        region: regionCtrl.text.trim().isEmpty ? 'General' : regionCtrl.text.trim(),
                        congregationId: congregationId,
                        boundaryGeojson: poly,
                        startLat: lat,
                        startLng: lng,
                        stopLat: lat - 0.002,
                        stopLng: lng + 0.004,
                        status: status,
                      );
                    } else {
                      await dao.updateTerritory(
                        id: existing.id,
                        number: numCtrl.text.trim(),
                        name: nameCtrl.text.trim(),
                        region: regionCtrl.text.trim(),
                        status: status,
                        assignedTo: existing.assignedTo,
                        dueDate: existing.dueDate,
                        startLat: lat,
                        startLng: lng,
                        stopLat: existing.stopLat,
                        stopLng: existing.stopLng,
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

  Future<void> _showAssignModal(
    BuildContext context,
    TerritoryDao dao,
    CongregationDao congDao,
    TerritoryItem territory,
    String congId,
  ) async {
    final nameCtrl = TextEditingController(text: territory.assignedTo ?? '');
    final dueCtrl = TextEditingController(
      text: territory.dueDate ?? DateFormat('yyyy-MM-dd').format(DateTime.now().add(const Duration(days: 120))),
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => StreamBuilder<List<PublisherProfileItem>>(
        stream: congDao.watchPublishers(congregationId: congId),
        builder: (ctx, pubSnap) {
          final publishers = pubSnap.data ?? [];
          return Padding(
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
                Text('Assign ${territory.number} ${territory.name}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                if (publishers.isNotEmpty) ...[
                  const Text('Select from Congregation Roster:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: publishers
                        .map(
                          (p) => ActionChip(
                            label: Text(p.displayName),
                            onPressed: () => nameCtrl.text = p.displayName,
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 10),
                ],
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Assigned Publisher Name *', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: dueCtrl,
                  decoration: const InputDecoration(labelText: 'Due Date (YYYY-MM-DD)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.assignment_ind),
                    label: const Text('Assign Territory'),
                    onPressed: () async {
                      if (nameCtrl.text.trim().isEmpty) return;
                      await dao.assignTerritory(
                        id: territory.id,
                        publisherName: nameCtrl.text.trim(),
                        dueDate: dueCtrl.text.trim(),
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmDeleteTerritory(
    BuildContext context,
    TerritoryDao dao,
    TerritoryItem t,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Territory?'),
        content: Text('Delete "${t.number} ${t.name}" and its associated addresses?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: SunlightPalette.highVisRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await dao.deleteTerritory(t.id);
    }
  }
}
