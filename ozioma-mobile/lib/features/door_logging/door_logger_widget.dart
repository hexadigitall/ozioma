import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/daos/address_dao.dart';
import '../../core/database/database_providers.dart';
import '../../core/theme/sunlight_palette.dart';

/// One-Handed Door-to-Door Rapid Action Logger (Sprint 5)
/// Designed for quick thumb-reach walking in equatorial sunlight.
/// High contrast, >= 48dp touch targets, haptic feedback, 5-second undo toast.
class DoorLoggerWidget extends ConsumerWidget {
  final AddressItem address;
  final VoidCallback? onStatusChanged;

  const DoorLoggerWidget({
    super.key,
    required this.address,
    this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addressDao = ref.watch(addressDaoProvider);
    final dncManager = ref.watch(dncManagerProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getStatusBorderColor(address.status),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      address.streetAddress,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                    if (address.unit != null && address.unit!.isNotEmpty)
                      Text(
                        'Unit: ${address.unit}',
                        style: const TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                  ],
                ),
              ),
              _buildCurrentStatusPill(address.status),
            ],
          ),
          const SizedBox(height: 12),
          // Thumb-reachable 1-handed action bar (all targets >= 48x48dp)
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  context,
                  label: 'Unvisited',
                  icon: Icons.radio_button_unchecked,
                  color: const Color(0xFF64748B),
                  isSelected: address.status == 'unvisited',
                  onTap: () => _updateStatusWithUndo(
                    context,
                    addressDao,
                    newStatus: 'unvisited',
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildActionButton(
                  context,
                  label: 'NH',
                  icon: Icons.door_front_door_outlined,
                  color: SunlightPalette.highVisOrange,
                  isSelected: address.status == 'not_at_home',
                  onTap: () => _updateStatusWithUndo(
                    context,
                    addressDao,
                    newStatus: 'not_at_home',
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildActionButton(
                  context,
                  label: 'RV',
                  icon: Icons.person_add_alt_1,
                  color: SunlightPalette.highVisGreen,
                  isSelected: address.status == 'return_visit' || address.status == 'rv_active',
                  onTap: () => _updateStatusWithUndo(
                    context,
                    addressDao,
                    newStatus: 'return_visit',
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildActionButton(
                  context,
                  label: 'DNC',
                  icon: Icons.do_not_disturb_on,
                  color: SunlightPalette.highVisRed,
                  isSelected: address.status == 'do_not_call',
                  onTap: () => _confirmAndMarkDnc(context, dncManager),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 52, // Enforces >= 48dp touch target
      child: Material(
        color: isSelected ? color : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected ? Colors.black : color,
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.black : color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStatusPill(String status) {
    Color bg = const Color(0xFF64748B);
    String label = 'UNVISITED';

    switch (status) {
      case 'not_at_home':
        bg = SunlightPalette.highVisOrange;
        label = 'NOT AT HOME';
        break;
      case 'return_visit':
      case 'rv_active':
        bg = SunlightPalette.highVisGreen;
        label = 'RETURN VISIT';
        break;
      case 'do_not_call':
        bg = SunlightPalette.highVisRed;
        label = 'DO NOT CALL';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Color _getStatusBorderColor(String status) {
    switch (status) {
      case 'not_at_home':
        return SunlightPalette.highVisOrange.withValues(alpha: 0.6);
      case 'return_visit':
      case 'rv_active':
        return SunlightPalette.highVisGreen.withValues(alpha: 0.6);
      case 'do_not_call':
        return SunlightPalette.highVisRed.withValues(alpha: 0.8);
      default:
        return Colors.transparent;
    }
  }

  Future<void> _updateStatusWithUndo(
    BuildContext context,
    AddressDao dao, {
    required String newStatus,
  }) async {
    final oldStatus = address.status;
    if (oldStatus == newStatus) return;

    await dao.updateStatus(address.id, newStatus);
    onStatusChanged?.call();

    if (!context.mounted) return;

    // 5-second undo toast
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 5),
        content: Text('${address.streetAddress} -> ${_formatStatusName(newStatus)}'),
        action: SnackBarAction(
          label: 'UNDO',
          textColor: SunlightPalette.sunlightYellow,
          onPressed: () async {
            HapticFeedback.mediumImpact();
            await dao.updateStatus(address.id, oldStatus);
            onStatusChanged?.call();
          },
        ),
      ),
    );
  }

  Future<void> _confirmAndMarkDnc(BuildContext context, dynamic dncManager) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Do Not Call (DNC)'),
        content: Text(
          'Mark ${address.streetAddress} as Do Not Call?\n\n'
          'Per theocratic privacy protocols, any local Return Visit notes will be purged immediately to comply with data privacy standards.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: SunlightPalette.highVisRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm DNC', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      HapticFeedback.heavyImpact();
      await dncManager.markAsDoNotCall(address.id);
      onStatusChanged?.call();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${address.streetAddress} locked as DO NOT CALL.'),
            backgroundColor: SunlightPalette.highVisRed,
          ),
        );
      }
    }
  }

  String _formatStatusName(String s) {
    switch (s) {
      case 'not_at_home':
        return 'Not At Home (NH)';
      case 'return_visit':
        return 'Return Visit (RV)';
      case 'do_not_call':
        return 'Do Not Call (DNC)';
      default:
        return 'Unvisited';
    }
  }
}
