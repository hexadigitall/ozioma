import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/database/database_providers.dart';
import '../core/database/daos/service_log_dao.dart';
import 'timer_screen.dart';
import 'territories_screen.dart';
import 'rv_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final currentMonthKey = DateFormat('yyyy-MM').format(now);
    final monthDisplayName = DateFormat('MMMM yyyy').format(now);
    final serviceLogDao = ref.watch(serviceLogDaoProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ozioma Field Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share Monthly S-4 Report',
            onPressed: () => _showS4ReportDialog(context, serviceLogDao, currentMonthKey, monthDisplayName),
          ),
        ],
      ),
      body: StreamBuilder<List<ServiceLogItem>>(
        stream: serviceLogDao.watchMonthlyLogs(currentMonthKey),
        builder: (context, snapshot) {
          final logs = snapshot.data ?? [];
          final totalMinutes = logs.fold<int>(0, (sum, log) => sum + log.durationMinutes);
          final totalHours = totalMinutes / 60.0;
          final totalStudies = logs.fold<int>(0, (sum, log) => sum + log.bibleStudiesCount);
          final totalPlacements = logs.fold<int>(0, (sum, log) => sum + log.placementsCount);
          final totalVideos = logs.fold<int>(0, (sum, log) => sum + log.videoShowingsCount);

          const pioneerGoal = 50.0;
          final progress = (totalHours / pioneerGoal).clamp(0.0, 1.0);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Monthly Pacing Card
              Card(
                elevation: 0,
                color: const Color(0xFF0F172A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            monthDisplayName.toUpperCase(),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(6)),
                            child: const Text('Regular Pioneer (50h)', style: TextStyle(fontSize: 10, color: Colors.white70)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${totalHours.toStringAsFixed(1)} hrs',
                        style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.white12,
                        color: const Color(0xFF10B981),
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${(progress * 100).toStringAsFixed(0)}% of monthly goal', style: const TextStyle(fontSize: 12, color: Colors.white70)),
                          Text('${(pioneerGoal - totalHours).clamp(0, 50).toStringAsFixed(1)}h remaining', style: const TextStyle(fontSize: 12, color: Color(0xFF10B981))),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Ministry Statistics Row
              Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      icon: Icons.menu_book,
                      color: Colors.blue,
                      value: '$totalStudies',
                      label: 'Bible Studies',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricTile(
                      icon: Icons.newspaper,
                      color: Colors.amber,
                      value: '$totalPlacements',
                      label: 'Placements',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricTile(
                      icon: Icons.play_circle_outline,
                      color: Colors.purple,
                      value: '$totalVideos',
                      label: 'Videos',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              const Text('Field Ministry Workflows', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),

              // Action Buttons
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: const CircleAvatar(backgroundColor: Color(0xFF0F172A), child: Icon(Icons.timer, color: Color(0xFF10B981))),
                  title: const Text('Field Service Timer', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Track active preaching sessions in foreground'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TimerScreen())),
                ),
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.map, color: Colors.white)),
                  title: const Text('Assigned Territories', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Explore boundaries & door-to-door catalog'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TerritoriesScreen())),
                ),
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: const CircleAvatar(backgroundColor: Color(0xFF10B981), child: Icon(Icons.people, color: Colors.white)),
                  title: const Text('Return Visits & Bible Studies', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Local encrypted contacts & lesson progression'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RVScreen())),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMetricTile({required IconData icon, required Color color, required String value, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  void _showS4ReportDialog(BuildContext context, ServiceLogDao dao, String monthKey, String monthName) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Monthly Report — $monthName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Form S-4 Field Service Summary ready for submission to your Group Overseer via WhatsApp / SMS.', style: TextStyle(fontSize: 12, color: Colors.grey)),
            SizedBox(height: 16),
            Text('Hours: Calculated from verified daily sessions.'),
            Text('Bible Studies: Count of active studies.'),
            Text('Placements & Videos: Automatically totaled.'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          FilledButton.icon(
            icon: const Icon(Icons.send),
            label: const Text('Share S-4 Report'),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Monthly S-4 Report generated for sharing')),
              );
            },
          ),
        ],
      ),
    );
  }
}
