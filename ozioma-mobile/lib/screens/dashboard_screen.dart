import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/database/daos/congregation_dao.dart';
import '../core/database/daos/ministry_planner_dao.dart';
import '../core/database/daos/return_visit_dao.dart';
import '../core/database/daos/service_log_dao.dart';
import '../core/database/database_providers.dart';
import '../core/theme/sunlight_palette.dart';
import '../core/theme/theme_provider.dart';
import 'congregation_field_map_screen.dart';
import 'congregation_setup_screen.dart';
import 'publisher_chat_screen.dart';
import 'resources_screen.dart';
import 'rv_screen.dart';
import 'territories_screen.dart';
import 'timer_screen.dart';
import 'widgets/s4_report_sheet.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final currentMonthKey = DateFormat('yyyy-MM').format(now);
    final monthDisplayName = DateFormat('MMMM yyyy').format(now);
    final serviceLogDao = ref.watch(serviceLogDaoProvider);
    final rvDao = ref.watch(returnVisitDaoProvider);
    final plannerDao = ref.watch(ministryPlannerDaoProvider);
    final congDao = ref.watch(congregationDaoProvider);
    final themeMode = ref.watch(themeProvider);
    final isSunlightDark = themeMode == AppThemeMode.sunlightDark;

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(10),
          child: Image.asset(
            'assets/images/logo_mark.png',
            errorBuilder: (_, __, ___) => const Icon(Icons.explore, color: SunlightPalette.highVisGreen),
          ),
        ),
        title: StreamBuilder<PublisherProfileItem?>(
          stream: congDao.watchActivePublisher(),
          builder: (context, pubSnap) {
            final pub = pubSnap.data;
            return GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CongregationSetupScreen()),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Ozioma Ministry Hub', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                  Text(
                    pub != null
                        ? '${pub.displayName} • ${TheocraticRolePermissions.label(pub.role)}'
                        : 'Tap to register congregation & role',
                    style: const TextStyle(fontSize: 11, color: SunlightPalette.highVisGreen),
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.forum_outlined),
            tooltip: 'Publisher Chat & Pins',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PublisherChatScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.admin_panel_settings_outlined),
            tooltip: 'Congregation & Role Setup',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CongregationSetupScreen()),
            ),
          ),
          IconButton(
            icon: Icon(isSunlightDark ? Icons.light_mode : Icons.dark_mode),
            tooltip: 'Toggle Sunlight Contrast',
            onPressed: () {
              HapticFeedback.lightImpact();
              ref.read(themeProvider.notifier).toggleSunlightMode();
            },
          ),
        ],
      ),
      body: StreamBuilder<List<ServiceLogItem>>(
        stream: serviceLogDao.watchMonthlyLogs(currentMonthKey),
        builder: (context, logSnap) {
          final logs = logSnap.data ?? [];
          final totalMinutes = logs.fold<int>(0, (sum, log) => sum + log.durationMinutes);
          final totalHours = totalMinutes / 60.0;
          final totalPlacements = logs.fold<int>(0, (sum, log) => sum + log.placementsCount);
          final totalVideos = logs.fold<int>(0, (sum, log) => sum + log.videoShowingsCount);

          return StreamBuilder<MonthlyReportRecord?>(
            stream: plannerDao.watchMonthlyReport(currentMonthKey),
            builder: (context, reportSnap) {
              final report = reportSnap.data;
              final monthlyGoal = (report != null && report.monthlyHourGoal > 0)
                  ? report.monthlyHourGoal.toDouble()
                  : 50.0;
              final progress = (totalHours / monthlyGoal).clamp(0.0, 1.0);
              final lastDay = DateTime(now.year, now.month + 1, 0).day;
              final daysLeft = (lastDay - now.day) + 1;
              final paceNeeded = daysLeft > 0 ? ((monthlyGoal - totalHours).clamp(0.0, 999.0) / daysLeft) : 0.0;

              return StreamBuilder<List<ReturnVisitItem>>(
                stream: rvDao.watchReturnVisits(),
                builder: (context, rvSnap) {
                  final rvs = rvSnap.data ?? [];
                  final activeStudies = rvs.where((r) => r.isBibleStudy).length;

                  return StreamBuilder<int>(
                    stream: rvDao.watchOpenQuestionCount(),
                    builder: (context, qSnap) {
                      final openQuestions = qSnap.data ?? 0;

                      return StreamBuilder<Map<String, int>>(
                        stream: rvDao.watchMilestoneCountsByStudent(),
                        builder: (context, mSnap) {
                          final totalMilestones = (mSnap.data ?? {}).values.fold<int>(0, (a, b) => a + b);

                          return ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              // Hero Monthly Pacing & S-4 Card
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: SunlightPalette.highVisGreen.withValues(alpha: 0.35),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          monthDisplayName.toUpperCase(),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.8,
                                            color: Color(0xFF10B981),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: report?.isSubmitted == true
                                                ? SunlightPalette.highVisGreen.withValues(alpha: 0.22)
                                                : Colors.white12,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            report?.isSubmitted == true
                                                ? 'S-4 Submitted'
                                                : 'Goal: ${monthlyGoal.toInt()}h',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: report?.isSubmitted == true
                                                  ? SunlightPalette.highVisGreen
                                                  : Colors.white70,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          totalHours.toStringAsFixed(1),
                                          style: const TextStyle(
                                            fontSize: 42,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                            height: 1,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Padding(
                                          padding: const EdgeInsets.only(bottom: 5),
                                          child: Text(
                                            '/ ${monthlyGoal.toInt()} hrs',
                                            style: const TextStyle(fontSize: 15, color: Colors.white70, fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(5),
                                      child: LinearProgressIndicator(
                                        value: progress,
                                        backgroundColor: Colors.white12,
                                        color: const Color(0xFF10B981),
                                        minHeight: 8,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '$daysLeft days left • ${paceNeeded.toStringAsFixed(1)}h/day pace',
                                          style: const TextStyle(fontSize: 12, color: Colors.white70),
                                        ),
                                        Text(
                                          '${(progress * 100).toStringAsFixed(0)}%',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF10B981),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: FilledButton.icon(
                                            style: FilledButton.styleFrom(
                                              backgroundColor: SunlightPalette.sunlightYellow,
                                              foregroundColor: Colors.black,
                                            ),
                                            icon: const Icon(Icons.play_arrow),
                                            label: const Text('Start Service'),
                                            onPressed: () => Navigator.push(
                                              context,
                                              MaterialPageRoute(builder: (_) => const TimerScreen(initialTabIndex: 0)),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: Colors.white,
                                              side: const BorderSide(color: Colors.white38),
                                            ),
                                            icon: const Icon(Icons.assignment_turned_in_outlined),
                                            label: const Text('S-4 Report'),
                                            onPressed: () => showS4ReportSheet(
                                              context: context,
                                              serviceLogDao: serviceLogDao,
                                              plannerDao: plannerDao,
                                              yearMonth: currentMonthKey,
                                              monthlyLogs: logs,
                                              existingRecord: report,
                                              suggestedStudiesCount: activeStudies,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Effectiveness & Growth Pulse Grid
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildMetricTile(
                                      icon: Icons.menu_book,
                                      color: SunlightPalette.highVisGreen,
                                      value: '$activeStudies',
                                      label: 'Bible Studies',
                                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RVScreen())),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildMetricTile(
                                      icon: Icons.help_outline,
                                      color: openQuestions > 0 ? SunlightPalette.sunlightYellow : Colors.blueGrey,
                                      value: '$openQuestions',
                                      label: 'Open Qs',
                                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RVScreen())),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildMetricTile(
                                      icon: Icons.emoji_events_outlined,
                                      color: SunlightPalette.highVisCyan,
                                      value: '$totalMilestones',
                                      label: 'Milestones',
                                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RVScreen())),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildMetricTile(
                                      icon: Icons.newspaper_outlined,
                                      color: Colors.orangeAccent,
                                      value: '${totalPlacements + totalVideos}',
                                      label: 'Plc / Vid',
                                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TimerScreen())),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),

                              // Upcoming Field Appointments & Partners
                              StreamBuilder<List<MinistryAppointmentItem>>(
                                stream: plannerDao.watchAppointments(statusFilter: 'scheduled'),
                                builder: (context, apptSnap) {
                                  final upcoming = (apptSnap.data ?? []).take(3).toList();
                                  return Card(
                                    margin: EdgeInsets.zero,
                                    child: Padding(
                                      padding: const EdgeInsets.all(14),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text(
                                                'Upcoming Partner Appointments',
                                                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                                              ),
                                              TextButton.icon(
                                                icon: const Icon(Icons.add, size: 16),
                                                label: const Text('Schedule'),
                                                onPressed: () => showAppointmentFormModal(context, plannerDao),
                                              ),
                                            ],
                                          ),
                                          if (upcoming.isEmpty)
                                            const Padding(
                                              padding: EdgeInsets.symmetric(vertical: 6),
                                              child: Text(
                                                'No upcoming partner engagements scheduled yet.',
                                                style: TextStyle(fontSize: 12, color: Colors.grey),
                                              ),
                                            )
                                          else
                                            ...upcoming.map(
                                              (a) => ListTile(
                                                contentPadding: EdgeInsets.zero,
                                                dense: true,
                                                leading: const Icon(Icons.handshake_outlined, color: SunlightPalette.sunlightYellow),
                                                title: Text(a.partnerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                                subtitle: Text('${a.appointmentDate} ${a.startTime} • ${a.ministryType}'),
                                                trailing: const Icon(Icons.chevron_right, size: 18),
                                                onTap: () => showAppointmentFormModal(context, plannerDao, existing: a),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 18),

                              const Text(
                                'Organize Every Aspect of Ministry',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 10),
                              _buildWorkflowTile(
                                context,
                                icon: Icons.school_outlined,
                                color: SunlightPalette.highVisGreen,
                                title: 'Students, Questions & Milestones',
                                subtitle: 'Log study start/end, doubts, goals & baptism journey',
                                destination: const RVScreen(),
                              ),
                              const SizedBox(height: 8),
                              _buildWorkflowTile(
                                context,
                                icon: Icons.flag_outlined,
                                color: SunlightPalette.sunlightYellow,
                                title: 'Personal Goals & Partner Planner',
                                subtitle: 'Pioneer pace, service year goals & partner schedule',
                                destination: const TimerScreen(initialTabIndex: 1),
                              ),
                              const SizedBox(height: 8),
                              _buildWorkflowTile(
                                context,
                                icon: Icons.volunteer_activism_outlined,
                                color: SunlightPalette.highVisCyan,
                                title: 'Congregation Care & Need-Greater Hub',
                                subtitle: 'Elderly/special needs, seldom-worked, presentations',
                                destination: const ResourcesScreen(initialTabIndex: 2),
                              ),
                              const SizedBox(height: 8),
                              _buildWorkflowTile(
                                context,
                                icon: Icons.map_outlined,
                                color: Colors.blueAccent,
                                title: 'Live Territory Map, Heatmap & Pins',
                                subtitle: 'Sync territory heatmap, pin sharing & live publisher tracking',
                                destination: const CongregationFieldMapScreen(),
                              ),
                              const SizedBox(height: 8),
                              _buildWorkflowTile(
                                context,
                                icon: Icons.forum_outlined,
                                color: SunlightPalette.highVisGreen,
                                title: 'Congregation Publisher Chat',
                                subtitle: 'Coordinate partners, car groups & drop live pins in chat',
                                destination: const PublisherChatScreen(),
                              ),
                              const SizedBox(height: 8),
                              _buildWorkflowTile(
                                context,
                                icon: Icons.admin_panel_settings_outlined,
                                color: SunlightPalette.sunlightYellow,
                                title: 'Congregation Setup, Publishers & Roles',
                                subtitle: 'Register congregation, assign privileges & S-4 rollups',
                                destination: const CongregationSetupScreen(),
                              ),
                              const SizedBox(height: 8),
                              _buildWorkflowTile(
                                context,
                                icon: Icons.door_front_door_outlined,
                                color: Colors.tealAccent,
                                title: 'Territories & Door Logger',
                                subtitle: 'Create/assign territories & log door statuses offline',
                                destination: const TerritoriesScreen(),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required Color color,
    required String value,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.28)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkflowTile(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required Widget destination,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.16),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          HapticFeedback.selectionClick();
          Navigator.push(context, MaterialPageRoute(builder: (_) => destination));
        },
      ),
    );
  }
}
