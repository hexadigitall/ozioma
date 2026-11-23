import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/daos/address_dao.dart';
import '../../core/database/database_providers.dart';
import '../../core/theme/sunlight_palette.dart';
import 'door_logger_widget.dart';

class TerritoryDoorLoggerScreen extends ConsumerStatefulWidget {
  final String territoryId;
  final String territoryNumber;
  final String territoryName;

  const TerritoryDoorLoggerScreen({
    super.key,
    required this.territoryId,
    required this.territoryNumber,
    required this.territoryName,
  });

  @override
  ConsumerState<TerritoryDoorLoggerScreen> createState() => _TerritoryDoorLoggerScreenState();
}

class _TerritoryDoorLoggerScreenState extends ConsumerState<TerritoryDoorLoggerScreen> {
  String _filter = 'all'; // all, unvisited, not_at_home, return_visit, do_not_call
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final addressDao = ref.watch(addressDaoProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Territory ${widget.territoryNumber}', style: const TextStyle(fontWeight: FontWeight.w900)),
            Text(widget.territoryName, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_home_outlined),
            tooltip: 'Add Door / Address',
            onPressed: () => _showAddAddressDialog(context, addressDao),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search street name or door #',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<AddressItem>>(
        stream: addressDao.watchAddressesForTerritory(widget.territoryId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final allAddresses = snapshot.data ?? [];

          // Compute stats
          final total = allAddresses.length;
          final completed = allAddresses.where((a) => a.status != 'unvisited').length;
          final progress = total > 0 ? completed / total : 0.0;

          // Filter by status & search
          final filtered = allAddresses.where((a) {
            if (_filter != 'all' && a.status != _filter) return false;
            if (_query.isNotEmpty) {
              final text = '${a.streetAddress} ${a.unit ?? ''}'.toLowerCase();
              if (!text.contains(_query)) return false;
            }
            return true;
          }).toList();

          return Column(
            children: [
              // Progress Bar & Quick Stats
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: Theme.of(context).cardColor,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$completed of $total doors worked (${(progress * 100).toStringAsFixed(0)}%)',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${total - completed} left',
                          style: const TextStyle(fontSize: 12, color: SunlightPalette.sunlightYellow),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: const Color(0xFF334155),
                        valueColor: const AlwaysStoppedAnimation<Color>(SunlightPalette.highVisGreen),
                      ),
                    ),
                  ],
                ),
              ),

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    _buildFilterChip('All', 'all', total),
                    const SizedBox(width: 8),
                    _buildFilterChip('Unvisited', 'unvisited', allAddresses.where((a) => a.status == 'unvisited').length),
                    const SizedBox(width: 8),
                    _buildFilterChip('NH', 'not_at_home', allAddresses.where((a) => a.status == 'not_at_home').length),
                    const SizedBox(width: 8),
                    _buildFilterChip('RV', 'return_visit', allAddresses.where((a) => a.status == 'return_visit' || a.status == 'rv_active').length),
                    const SizedBox(width: 8),
                    _buildFilterChip('DNC', 'do_not_call', allAddresses.where((a) => a.status == 'do_not_call').length),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Address Cards List
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.holiday_village_outlined, size: 56, color: Colors.grey),
                            const SizedBox(height: 12),
                            Text(
                              total == 0
                                  ? 'No doors logged yet in this territory'
                                  : 'No doors match filter "$_filter"',
                              style: const TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              icon: const Icon(Icons.add),
                              label: const Text('Add First Address'),
                              onPressed: () => _showAddAddressDialog(context, addressDao),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          return DoorLoggerWidget(
                            address: filtered[index],
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, int count) {
    final isSelected = _filter == value;
    return FilterChip(
      selected: isSelected,
      label: Text('$label ($count)'),
      onSelected: (_) {
        HapticFeedback.selectionClick();
        setState(() => _filter = value);
      },
    );
  }

  void _showAddAddressDialog(BuildContext context, AddressDao dao) {
    final streetCtrl = TextEditingController();
    final unitCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Address / Door'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: streetCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Street Address *',
                hintText: 'e.g. 14 Woji Road',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: unitCtrl,
              decoration: const InputDecoration(
                labelText: 'Unit / Flat / Floor (Optional)',
                hintText: 'e.g. Apt 3B',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final street = streetCtrl.text.trim();
              if (street.isEmpty) return;

              await dao.addAddress(
                territoryId: widget.territoryId,
                streetAddress: street,
                unit: unitCtrl.text.trim().isEmpty ? null : unitCtrl.text.trim(),
              );

              if (ctx.mounted) {
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add Door'),
          ),
        ],
      ),
    );
  }
}
