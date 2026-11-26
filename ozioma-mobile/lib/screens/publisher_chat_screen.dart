import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart' as geo;
import '../core/database/daos/collaboration_dao.dart';
import '../core/database/daos/congregation_dao.dart';
import '../core/database/database_providers.dart';
import '../core/theme/sunlight_palette.dart';

/// Real-time Congregation Publisher Chat & Location Pin Sharing Screen.
class PublisherChatScreen extends ConsumerStatefulWidget {
  const PublisherChatScreen({super.key});

  @override
  ConsumerState<PublisherChatScreen> createState() => _PublisherChatScreenState();
}

class _PublisherChatScreenState extends ConsumerState<PublisherChatScreen> {
  String _channel = 'field_service';
  final TextEditingController _msgCtrl = TextEditingController();

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(
    CollaborationDao collabDao,
    String congregationId,
    PublisherProfileItem? activePub,
  ) async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    HapticFeedback.lightImpact();
    _msgCtrl.clear();

    await collabDao.sendMessage(
      congregationId: congregationId,
      senderId: activePub?.id ?? 'device_publisher',
      senderName: activePub?.displayName ?? 'Field Publisher',
      senderRole: activePub?.role ?? 'publisher',
      channel: _channel,
      body: text,
    );
  }

  Future<void> _shareLocationPinInChat(
    BuildContext context,
    CollaborationDao collabDao,
    String congregationId,
    PublisherProfileItem? activePub,
  ) async {
    double lat = 4.821;
    double lng = 6.988;
    try {
      final perm = await geo.Geolocator.checkPermission();
      if (perm == geo.LocationPermission.always || perm == geo.LocationPermission.whileInUse) {
        final pos = await geo.Geolocator.getCurrentPosition();
        lat = pos.latitude;
        lng = pos.longitude;
      }
    } catch (_) {}

    if (!context.mounted) return;
    final titleCtrl = TextEditingController(text: 'Field Service Meeting Point');
    final notesCtrl = TextEditingController();
    final latCtrl = TextEditingController(text: lat.toStringAsFixed(5));
    final lngCtrl = TextEditingController(text: lng.toStringAsFixed(5));
    String category = 'meeting_point';

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
              const Text('Drop & Share Location Pin', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Pin Label *', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: category,
                decoration: const InputDecoration(labelText: 'Pin Category', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'meeting_point', child: Text('Meeting Point / Car Group')),
                  DropdownMenuItem(value: 'parking', child: Text('Safe Parking Spot')),
                  DropdownMenuItem(value: 'rv_hotspot', child: Text('Area / Study Hotspot')),
                  DropdownMenuItem(value: 'cart_site', child: Text('Cart Witnessing Site')),
                  DropdownMenuItem(value: 'hazard_gate', child: Text('Locked Gate / Hazard Note')),
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
                decoration: const InputDecoration(labelText: 'Directions / Note', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.add_location_alt),
                  label: const Text('Share Pin to Map & Chat'),
                  onPressed: () async {
                    if (titleCtrl.text.trim().isEmpty) return;
                    final parsedLat = double.tryParse(latCtrl.text.trim()) ?? lat;
                    final parsedLng = double.tryParse(lngCtrl.text.trim()) ?? lng;
                    final pinId = await collabDao.createSharedPin(
                      congregationId: congregationId,
                      createdBy: activePub?.displayName ?? 'Publisher',
                      title: titleCtrl.text.trim(),
                      category: category,
                      latitude: parsedLat,
                      longitude: parsedLng,
                      notes: notesCtrl.text.trim(),
                    );
                    await collabDao.sendMessage(
                      congregationId: congregationId,
                      senderId: activePub?.id ?? 'device_publisher',
                      senderName: activePub?.displayName ?? 'Field Publisher',
                      senderRole: activePub?.role ?? 'publisher',
                      channel: _channel,
                      body: 'Shared pin "${titleCtrl.text.trim()}" (${parsedLat.toStringAsFixed(4)}, ${parsedLng.toStringAsFixed(4)})',
                      pinId: pinId,
                    );
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

  @override
  Widget build(BuildContext context) {
    final collabDao = ref.watch(collaborationDaoProvider);
    final congDao = ref.watch(congregationDaoProvider);

    return StreamBuilder<PublisherProfileItem?>(
      stream: congDao.watchActivePublisher(),
      builder: (context, pubSnap) {
        final activePub = pubSnap.data;
        final activeCongId = activePub?.congregationId ?? '';
        final activeRole = activePub?.role ?? 'publisher';
        final canModerate = TheocraticRolePermissions.canModerateChat(activeRole);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Congregation Publisher Chat'),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  children: [
                    _channelChip('field_service', '# Field Service'),
                    const SizedBox(width: 8),
                    _channelChip('general', '# Congregation'),
                    const SizedBox(width: 8),
                    _channelChip('territory_updates', '# Territory Updates'),
                  ],
                ),
              ),
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: StreamBuilder<List<PublisherMessageItem>>(
                  stream: collabDao.watchMessages(congregationId: activeCongId, channel: _channel),
                  builder: (context, msgSnap) {
                    final messages = msgSnap.data ?? [];
                    if (messages.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.forum_outlined, size: 56, color: Colors.grey),
                              SizedBox(height: 10),
                              Text('No messages in this channel yet', style: TextStyle(fontWeight: FontWeight.bold)),
                              SizedBox(height: 4),
                              Text(
                                'Coordinate service partners, car groups, territory hand-offs, and shared location pins.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      reverse: true,
                      padding: const EdgeInsets.all(14),
                      itemCount: messages.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        final isMine = activePub != null ? msg.senderId == activePub.id : msg.senderId == 'device_publisher';

                        return Card(
                          margin: EdgeInsets.zero,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      msg.senderName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13,
                                        color: isMine ? SunlightPalette.sunlightYellow : SunlightPalette.highVisCyan,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.white10,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        TheocraticRolePermissions.label(msg.senderRole),
                                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                                      ),
                                    ),
                                    const Spacer(),
                                    if (isMine || canModerate)
                                      PopupMenuButton<String>(
                                        onSelected: (v) async {
                                          if (v == 'edit' && isMine) {
                                            await _editMessageDialog(context, collabDao, msg);
                                          } else if (v == 'delete') {
                                            await collabDao.deleteMessage(msg.id);
                                          }
                                        },
                                        itemBuilder: (_) => [
                                          if (isMine) const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                          const PopupMenuItem(value: 'delete', child: Text('Delete')),
                                        ],
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(msg.body, style: const TextStyle(fontSize: 14)),
                                if (msg.pinId.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  const Row(
                                    children: [
                                      Icon(Icons.location_on, size: 14, color: SunlightPalette.highVisGreen),
                                      SizedBox(width: 4),
                                      Text(
                                        'Attached Live Map Pin',
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: SunlightPalette.highVisGreen),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.grey.shade800)),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.add_location_alt_outlined, color: SunlightPalette.highVisGreen),
                        tooltip: 'Share Location Pin',
                        onPressed: () => _shareLocationPinInChat(context, collabDao, activeCongId, activePub),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _msgCtrl,
                          decoration: const InputDecoration(
                            hintText: 'Message your congregation group...',
                            isDense: true,
                          ),
                          onSubmitted: (_) => _sendMessage(collabDao, activeCongId, activePub),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        icon: const Icon(Icons.send),
                        tooltip: 'Send',
                        onPressed: () => _sendMessage(collabDao, activeCongId, activePub),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _channelChip(String key, String label) {
    return FilterChip(
      selected: _channel == key,
      label: Text(label),
      onSelected: (_) => setState(() => _channel = key),
    );
  }

  Future<void> _editMessageDialog(
    BuildContext context,
    CollaborationDao dao,
    PublisherMessageItem msg,
  ) async {
    final ctrl = TextEditingController(text: msg.body);
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Message'),
        content: TextField(controller: ctrl, maxLines: 3),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (ctrl.text.trim().isNotEmpty) {
                await dao.updateMessage(msg.id, ctrl.text.trim());
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
