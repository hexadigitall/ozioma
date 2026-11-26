import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/database/daos/ministry_planner_dao.dart';
import '../core/database/daos/return_visit_dao.dart';
import '../core/database/daos/service_log_dao.dart';
import '../core/database/database_providers.dart';
import '../core/theme/sunlight_palette.dart';
import 'widgets/s4_report_sheet.dart';

/// Unified Ministry Planner Workspace (3 Focused Sub-Tabs):
/// 1. Timer & Activity Logs (Live timer + Past sessions CRUD + S-4 Report)
/// 2. Partner Appointments & Engagements (CRUD with special focus tags)
/// 3. Goals & Spiritual Growth (Hour targets, service year, custom goals)
class TimerScreen extends ConsumerStatefulWidget {
  final int initialTabIndex;

  const TimerScreen({super.key, this.initialTabIndex = 0});

  @override
  ConsumerState<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends ConsumerState<TimerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _ticker;
  int _secondsElapsed = 0;
  bool _isRunning = false;
  DateTime? _sessionStartDateTime;

  int _placements = 0;
  int _videos = 0;
  int _bibleStudies = 0;
  int _monthlyGoalHours = 50;
  String _activeActivityType = 'Door-to-Door';
  final TextEditingController _partnerCtrl = TextEditingController();
  final TextEditingController _sessionNoteCtrl = TextEditingController();

  static const List<String> activityTypes = [
    'Door-to-Door',
    'Return Visits / Studies',
    'Cart Witnessing',
    'Business Witnessing',
    'Informal Witnessing',
    'Letter / Telephone',
    'Rural / Seldom Worked',
    'Elderly / Special Care',
    'Approved Credit Hours',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 2),
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _tabController.dispose();
    _partnerCtrl.dispose();
    _sessionNoteCtrl.dispose();
    super.dispose();
  }

  void _toggleTimer() {
    HapticFeedback.mediumImpact();
    if (_isRunning) {
      _ticker?.cancel();
      setState(() => _isRunning = false);
    } else {
      _sessionStartDateTime ??= DateTime.now();
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _secondsElapsed++);
      });
      setState(() => _isRunning = true);
    }
  }

  void _adjustTime(int minutes) {
    HapticFeedback.lightImpact();
    setState(() {
      final newSec = _secondsElapsed + (minutes * 60);
      _secondsElapsed = newSec < 0 ? 0 : newSec;
    });
  }

  void _resetTimer() {
    HapticFeedback.lightImpact();
    _ticker?.cancel();
    setState(() {
      _isRunning = false;
      _secondsElapsed = 0;
      _sessionStartDateTime = null;
      _placements = 0;
      _videos = 0;
      _bibleStudies = 0;
      _partnerCtrl.clear();
      _sessionNoteCtrl.clear();
    });
  }

  Future<void> _logAndSaveSession() async {
    if (_secondsElapsed == 0) return;
    HapticFeedback.heavyImpact();
    final logDao = ref.read(serviceLogDaoProvider);
    final now = DateTime.now();
    final start = _sessionStartDateTime ?? now.subtract(Duration(seconds: _secondsElapsed));
    final startStr = DateFormat('HH:mm').format(start);
    final endStr = DateFormat('HH:mm').format(now);
    final duration = Duration(seconds: _secondsElapsed);

    await logDao.logSession(
      userId: 'publisher_me',
      date: now,
      duration: duration,
      placementsCount: _placements,
      videoShowingsCount: _videos,
      bibleStudiesCount: _bibleStudies,
      startTime: startStr,
      endTime: endStr,
      activityType: _activeActivityType,
      partnerName: _partnerCtrl.text.trim(),
      notes: _sessionNoteCtrl.text.trim(),
    );

    _resetTimer();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved ${duration.inMinutes} mins ($startStr - $endStr) to S-4 record.'),
          backgroundColor: SunlightPalette.highVisGreen,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final logDao = ref.watch(serviceLogDaoProvider);
    final plannerDao = ref.watch(ministryPlannerDaoProvider);
    final rvDao = ref.watch(returnVisitDaoProvider);
    final currentMonthKey = DateFormat('yyyy-MM').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ministry Planner & Timer'),
        actions: [
          StreamBuilder<List<ServiceLogItem>>(
            stream: logDao.watchMonthlyLogs(currentMonthKey),
            builder: (context, logSnap) {
              return StreamBuilder<MonthlyReportRecord?>(
                stream: plannerDao.watchMonthlyReport(currentMonthKey),
                builder: (context, reportSnap) {
                  return StreamBuilder<List<ReturnVisitItem>>(
                    stream: rvDao.watchReturnVisits(),
                    builder: (context, rvSnap) {
                      final activeStudies = (rvSnap.data ?? []).where((r) => r.isBibleStudy).length;
                      return IconButton(
                        icon: const Icon(Icons.assignment_turned_in_outlined),
                        tooltip: 'Generate & Submit Monthly S-4 Report',
                        onPressed: () => showS4ReportSheet(
                          context: context,
                          serviceLogDao: logDao,
                          plannerDao: plannerDao,
                          yearMonth: currentMonthKey,
                          monthlyLogs: logSnap.data ?? [],
                          existingRecord: reportSnap.data,
                          suggestedStudiesCount: activeStudies,
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.timer_outlined, size: 18), text: 'Timer & Logs'),
            Tab(icon: Icon(Icons.handshake_outlined, size: 18), text: 'Partners'),
            Tab(icon: Icon(Icons.flag_outlined, size: 18), text: 'Goals'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTimerAndLogsTab(logDao, plannerDao, rvDao, currentMonthKey),
          _buildAppointmentsTab(plannerDao),
          _buildGoalsTab(logDao, plannerDao, rvDao, currentMonthKey),
        ],
      ),
    );
  }

  // =========================================================================
  // TAB 1: SERVICE TIMER, MONTHLY PACE, MANUAL LOG CRUD & S-4
  // =========================================================================

  Widget _buildTimerAndLogsTab(
    ServiceLogDao logDao,
    MinistryPlannerDao plannerDao,
    ReturnVisitDao rvDao,
    String currentMonthKey,
  ) {
    final hours = (_secondsElapsed ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((_secondsElapsed % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsElapsed % 60).toString().padLeft(2, '0');

    return StreamBuilder<List<ServiceLogItem>>(
      stream: logDao.watchMonthlyLogs(currentMonthKey),
      builder: (context, snapshot) {
        final logs = snapshot.data ?? [];
        final totalMins = logs.fold<int>(0, (sum, l) => sum + l.durationMinutes);
        final totalHours = totalMins / 60.0;
        final now = DateTime.now();
        final lastDayOfMonth = DateTime(now.year, now.month + 1, 0).day;
        final daysRemaining = (lastDayOfMonth - now.day) + 1;
        final hoursRemaining = (_monthlyGoalHours - totalHours).clamp(0.0, 999.0);
        final dailyPace = daysRemaining > 0 ? (hoursRemaining / daysRemaining) : 0.0;
        final progress = _monthlyGoalHours > 0 ? (totalHours / _monthlyGoalHours).clamp(0.0, 1.0) : 0.0;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Pacing Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Monthly Goal & Pacing', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        DropdownButton<int>(
                          value: _monthlyGoalHours,
                          isDense: true,
                          underline: const SizedBox(),
                          items: const [
                            DropdownMenuItem(value: 50, child: Text('50h (Reg. Pioneer)')),
                            DropdownMenuItem(value: 30, child: Text('30h (Aux. Pioneer)')),
                            DropdownMenuItem(value: 15, child: Text('15h (Aux. Pioneer)')),
                            DropdownMenuItem(value: 10, child: Text('10h (Personal)')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _monthlyGoalHours = val);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${totalHours.toStringAsFixed(1)} / ${_monthlyGoalHours}h', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                        Text(
                          '${(progress * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: progress >= 1.0 ? SunlightPalette.highVisGreen : SunlightPalette.sunlightYellow,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        progress >= 1.0 ? SunlightPalette.highVisGreen : SunlightPalette.sunlightYellow,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$daysRemaining days left in ${DateFormat('MMMM').format(now)} • ${dailyPace.toStringAsFixed(1)} h/day needed',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Live Timer Card
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                child: Column(
                  children: [
                    Text(
                      '$hours:$minutes:$seconds',
                      style: const TextStyle(fontSize: 50, fontWeight: FontWeight.w900, letterSpacing: 2),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isRunning
                          ? 'Started at ${DateFormat('HH:mm').format(_sessionStartDateTime ?? now)} • Active'
                          : (_secondsElapsed > 0 ? 'Paused (Ready to save)' : 'Ready to start ministry'),
                      style: TextStyle(
                        color: _isRunning ? SunlightPalette.highVisGreen : Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton.filledTonal(
                          iconSize: 26,
                          icon: const Icon(Icons.refresh),
                          tooltip: 'Reset Timer',
                          onPressed: _secondsElapsed > 0 ? _resetTimer : null,
                        ),
                        const SizedBox(width: 20),
                        IconButton.filled(
                          iconSize: 42,
                          style: IconButton.styleFrom(
                            backgroundColor: _isRunning ? SunlightPalette.sunlightYellow : SunlightPalette.highVisGreen,
                            foregroundColor: Colors.black,
                          ),
                          icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
                          tooltip: _isRunning ? 'Pause' : 'Start',
                          onPressed: _toggleTimer,
                        ),
                        const SizedBox(width: 20),
                        IconButton.filledTonal(
                          iconSize: 26,
                          icon: const Icon(Icons.save),
                          tooltip: 'Save Session',
                          onPressed: _secondsElapsed > 0 ? _logAndSaveSession : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        ActionChip(
                          label: const Text('-15m'),
                          onPressed: _secondsElapsed >= 900 ? () => _adjustTime(-15) : null,
                        ),
                        ActionChip(label: const Text('+15m'), onPressed: () => _adjustTime(15)),
                        ActionChip(label: const Text('+30m'), onPressed: () => _adjustTime(30)),
                        ActionChip(label: const Text('+1h'), onPressed: () => _adjustTime(60)),
                      ],
                    ),
                    const Divider(height: 24),
                    DropdownButtonFormField<String>(
                      value: _activeActivityType,
                      decoration: const InputDecoration(
                        labelText: 'Ministry Activity Type',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: activityTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _activeActivityType = v);
                      },
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _partnerCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Service Partner',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _sessionNoteCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Summary Note',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildCounterRow(
                      label: 'Publications Placed',
                      value: _placements,
                      onDecrement: () => setState(() => _placements--),
                      onIncrement: () => setState(() => _placements++),
                    ),
                    _buildCounterRow(
                      label: 'Videos Shown',
                      value: _videos,
                      onDecrement: () => setState(() => _videos--),
                      onIncrement: () => setState(() => _videos++),
                    ),
                    _buildCounterRow(
                      label: 'Bible Studies Conducted',
                      value: _bibleStudies,
                      onDecrement: () => setState(() => _bibleStudies--),
                      onIncrement: () => setState(() => _bibleStudies++),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Past Sessions Header & Manual Log CTA
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Activity Logs (${logs.length})',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.add),
                  label: const Text('Log Past Session'),
                  onPressed: () => _showManualSessionModal(context, logDao),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (logs.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'No service logs recorded this month yet. Start the timer or tap "Log Past Session" to add activity with start & end times.',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ),
              )
            else
              ...logs.map(
                (log) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Card(
                    margin: EdgeInsets.zero,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: SunlightPalette.highVisGreen.withValues(alpha: 0.16),
                        foregroundColor: SunlightPalette.highVisGreen,
                        child: Text(
                          '${(log.durationMinutes / 60.0).toStringAsFixed(1)}h',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(
                        '${log.logDate}${log.startTime.isNotEmpty ? ' • ${log.startTime}-${log.endTime}' : ''}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      subtitle: Text(
                        '${log.activityType}'
                        '${log.partnerName.isNotEmpty ? ' with ${log.partnerName}' : ''}'
                        ' • ${log.placementsCount} pl, ${log.videoShowingsCount} vid, ${log.bibleStudiesCount} st'
                        '${log.notes.isNotEmpty ? '\n${log.notes}' : ''}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      isThreeLine: log.notes.isNotEmpty,
                      trailing: PopupMenuButton<String>(
                        onSelected: (v) async {
                          if (v == 'edit') {
                            await _showManualSessionModal(context, logDao, existing: log);
                          } else if (v == 'delete') {
                            await logDao.deleteSession(log.id);
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'edit', child: Text('Edit Session')),
                          PopupMenuItem(value: 'delete', child: Text('Delete')),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _showManualSessionModal(
    BuildContext context,
    ServiceLogDao logDao, {
    ServiceLogItem? existing,
  }) async {
    final now = DateTime.now();
    final dateCtrl = TextEditingController(text: existing?.logDate ?? DateFormat('yyyy-MM-dd').format(now));
    final startCtrl = TextEditingController(text: existing?.startTime.isNotEmpty == true ? existing!.startTime : '09:00');
    final endCtrl = TextEditingController(text: existing?.endTime.isNotEmpty == true ? existing!.endTime : '11:00');
    final minsCtrl = TextEditingController(text: '${existing?.durationMinutes ?? 120}');
    final partnerCtrl = TextEditingController(text: existing?.partnerName ?? '');
    final notesCtrl = TextEditingController(text: existing?.notes ?? '');
    final plCtrl = TextEditingController(text: '${existing?.placementsCount ?? 0}');
    final vidCtrl = TextEditingController(text: '${existing?.videoShowingsCount ?? 0}');
    final stCtrl = TextEditingController(text: '${existing?.bibleStudiesCount ?? 0}');
    String activity = existing != null && activityTypes.contains(existing.activityType)
        ? existing.activityType
        : 'Door-to-Door';

    void syncDurationFromStartEnd() {
      final sp = startCtrl.text.split(':');
      final ep = endCtrl.text.split(':');
      if (sp.length == 2 && ep.length == 2) {
        final sM = (int.tryParse(sp[0]) ?? 9) * 60 + (int.tryParse(sp[1]) ?? 0);
        final eM = (int.tryParse(ep[0]) ?? 11) * 60 + (int.tryParse(ep[1]) ?? 0);
        if (eM > sM) minsCtrl.text = '${eM - sM}';
      }
    }

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
                existing == null ? 'Log Service Session' : 'Edit Service Session',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: dateCtrl,
                decoration: InputDecoration(
                  labelText: 'Date (YYYY-MM-DD)',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: ctx,
                        initialDate: now,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (d != null) setModalState(() => dateCtrl.text = DateFormat('yyyy-MM-dd').format(d));
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: startCtrl,
                      decoration: const InputDecoration(labelText: 'Start (HH:MM)', border: OutlineInputBorder()),
                      onChanged: (_) => setModalState(syncDurationFromStartEnd),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: endCtrl,
                      decoration: const InputDecoration(labelText: 'End (HH:MM)', border: OutlineInputBorder()),
                      onChanged: (_) => setModalState(syncDurationFromStartEnd),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: minsCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Minutes', border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: activity,
                decoration: const InputDecoration(labelText: 'Activity Type', border: OutlineInputBorder()),
                items: activityTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) {
                  if (v != null) setModalState(() => activity = v);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: partnerCtrl,
                decoration: const InputDecoration(labelText: 'Partner / Group Name', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: plCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Placements', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: vidCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Videos', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: stCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Studies', border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesCtrl,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Session Summary & Highlights', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.save),
                  label: Text(existing == null ? 'Save Service Log' : 'Update Service Log'),
                  onPressed: () async {
                    final mins = int.tryParse(minsCtrl.text.trim()) ?? 60;
                    final parsedDate = DateTime.tryParse(dateCtrl.text.trim()) ?? now;
                    HapticFeedback.lightImpact();
                    if (existing == null) {
                      await logDao.logSession(
                        userId: 'publisher_me',
                        date: parsedDate,
                        duration: Duration(minutes: mins),
                        placementsCount: int.tryParse(plCtrl.text.trim()) ?? 0,
                        videoShowingsCount: int.tryParse(vidCtrl.text.trim()) ?? 0,
                        bibleStudiesCount: int.tryParse(stCtrl.text.trim()) ?? 0,
                        startTime: startCtrl.text.trim(),
                        endTime: endCtrl.text.trim(),
                        activityType: activity,
                        partnerName: partnerCtrl.text.trim(),
                        notes: notesCtrl.text.trim(),
                      );
                    } else {
                      await logDao.updateSession(
                        id: existing.id,
                        logDate: dateCtrl.text.trim(),
                        durationMinutes: mins,
                        placementsCount: int.tryParse(plCtrl.text.trim()) ?? 0,
                        videoShowingsCount: int.tryParse(vidCtrl.text.trim()) ?? 0,
                        bibleStudiesCount: int.tryParse(stCtrl.text.trim()) ?? 0,
                        startTime: startCtrl.text.trim(),
                        endTime: endCtrl.text.trim(),
                        activityType: activity,
                        partnerName: partnerCtrl.text.trim(),
                        notes: notesCtrl.text.trim(),
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

  // =========================================================================
  // TAB 2: FIELD SERVICE PARTNER APPOINTMENTS & ENGAGEMENTS CRUD
  // =========================================================================

  String _focusLabel(String f) {
    switch (f) {
      case 'elderly_care':
        return 'Elderly Publisher Support';
      case 'special_needs':
        return 'Special Needs Care';
      case 'youth_training':
        return 'Youth / New Publisher';
      case 'foreign_language':
        return 'Foreign Language Group';
      case 'seldom_worked':
        return 'Seldom-Worked Territory';
      case 'need_greater':
        return 'Where Need Is Greater';
      default:
        return 'Standard Ministry';
    }
  }

  Widget _buildAppointmentsTab(MinistryPlannerDao plannerDao) {
    return StreamBuilder<List<MinistryAppointmentItem>>(
      stream: plannerDao.watchAppointments(),
      builder: (context, snapshot) {
        final items = snapshot.data ?? [];
        final partners = items.map((e) => e.partnerName).where((p) => p.isNotEmpty).toSet().toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            FilledButton.icon(
              icon: const Icon(Icons.event_available),
              label: const Text('Schedule Field Service Partner Appointment'),
              onPressed: () => showAppointmentFormModal(context, plannerDao),
            ),
            if (partners.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Regular Ministry Partners', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: partners
                    .map(
                      (p) => ActionChip(
                        avatar: const Icon(Icons.person, size: 16),
                        label: Text(p),
                        onPressed: () => showAppointmentFormModal(context, plannerDao, initialPartner: p),
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: 14),
            if (items.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(Icons.handshake_outlined, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('No field service appointments scheduled', style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text(
                        'Organize dates with preaching partners, rides for elderly publishers, return visit runs, cart shifts, and rural seldom-worked days.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...items.map(
                (a) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: a.status == 'completed'
                                    ? SunlightPalette.highVisGreen.withValues(alpha: 0.2)
                                    : SunlightPalette.sunlightYellow.withValues(alpha: 0.2),
                                child: Icon(
                                  a.status == 'completed' ? Icons.check : Icons.event,
                                  color: a.status == 'completed' ? SunlightPalette.highVisGreen : SunlightPalette.sunlightYellow,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(a.partnerName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                                    Text(
                                      '${a.appointmentDate} • ${a.startTime} - ${a.endTime}',
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuButton<String>(
                                onSelected: (v) async {
                                  if (v == 'complete') {
                                    await plannerDao.updateAppointmentStatus(a.id, 'completed');
                                  } else if (v == 'reopen') {
                                    await plannerDao.updateAppointmentStatus(a.id, 'scheduled');
                                  } else if (v == 'edit') {
                                    await showAppointmentFormModal(context, plannerDao, existing: a);
                                  } else if (v == 'delete') {
                                    await plannerDao.deleteAppointment(a.id);
                                  }
                                },
                                itemBuilder: (_) => [
                                  PopupMenuItem(
                                    value: a.status == 'completed' ? 'reopen' : 'complete',
                                    child: Text(a.status == 'completed' ? 'Mark Scheduled' : 'Mark Completed'),
                                  ),
                                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              Chip(
                                visualDensity: VisualDensity.compact,
                                label: Text(a.ministryType, style: const TextStyle(fontSize: 11)),
                              ),
                              if (a.specialFocus != 'standard')
                                Chip(
                                  visualDensity: VisualDensity.compact,
                                  label: Text(_focusLabel(a.specialFocus), style: const TextStyle(fontSize: 11)),
                                ),
                              if (a.location.isNotEmpty)
                                Chip(
                                  visualDensity: VisualDensity.compact,
                                  avatar: const Icon(Icons.place, size: 14),
                                  label: Text(a.location, style: const TextStyle(fontSize: 11)),
                                ),
                            ],
                          ),
                          if (a.notes.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(a.notes, style: const TextStyle(fontSize: 12)),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  // =========================================================================
  // TAB 3: PERSONAL & SPIRITUAL GOALS + GROWTH METRICS
  // =========================================================================

  Widget _buildGoalsTab(
    ServiceLogDao logDao,
    MinistryPlannerDao plannerDao,
    ReturnVisitDao rvDao,
    String currentMonthKey,
  ) {
    final now = DateTime.now();
    final serviceYearEnd = now.month >= 9 ? now.year + 1 : now.year;

    return StreamBuilder<List<ServiceLogItem>>(
      stream: logDao.watchServiceYearLogs(serviceYearEnd),
      builder: (context, sySnap) {
        final syMinutes = (sySnap.data ?? []).fold<int>(0, (s, l) => s + l.durationMinutes);
        final syHours = syMinutes / 60.0;
        const annualPioneerTarget = 600.0;

        return StreamBuilder<List<MinistryGoalItem>>(
          stream: plannerDao.watchGoals(),
          builder: (context, goalSnap) {
            final goals = goalSnap.data ?? [];

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Service Year $serviceYearEnd Progress',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                            ),
                            Text(
                              '${syHours.toStringAsFixed(1)} / 600h',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: SunlightPalette.highVisCyan),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: (syHours / annualPioneerTarget).clamp(0.0, 1.0),
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Tracks Sept 1 – Aug 31 hours automatically alongside your personal spiritual goals below.',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  icon: const Icon(Icons.add_chart),
                  label: const Text('Create Personal Spiritual / Ministry Goal'),
                  onPressed: () => _showGoalModal(context, plannerDao),
                ),
                const SizedBox(height: 12),
                if (goals.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Quick-Start Recommended Goals', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ActionChip(
                                label: const Text('+ Start 1 New Bible Study'),
                                onPressed: () => plannerDao.createGoal(
                                  title: 'Start a New Progressive Bible Study',
                                  category: 'studies',
                                  targetValue: 1,
                                  unit: 'studies',
                                  period: 'service_year',
                                ),
                              ),
                              ActionChip(
                                label: const Text('+ Daily Bible Reading (30d)'),
                                onPressed: () => plannerDao.createGoal(
                                  title: 'Examine Daily Text & Bible Reading',
                                  category: 'spiritual_routine',
                                  targetValue: 30,
                                  unit: 'days',
                                  period: 'monthly',
                                ),
                              ),
                              ActionChip(
                                label: const Text('+ Elderly / Special Care Visits'),
                                onPressed: () => plannerDao.createGoal(
                                  title: 'Work with Elderly & Infirm Publishers',
                                  category: 'congregation_support',
                                  targetValue: 4,
                                  unit: 'sessions',
                                  period: 'monthly',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...goals.map(
                    (g) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Card(
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(g.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                                        Text(
                                          '${g.category.replaceAll('_', ' ').toUpperCase()} • ${g.period}',
                                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    onSelected: (v) async {
                                      if (v == 'edit') {
                                        await _showGoalModal(context, plannerDao, existing: g);
                                      } else if (v == 'delete') {
                                        await plannerDao.deleteGoal(g.id);
                                      }
                                    },
                                    itemBuilder: (_) => const [
                                      PopupMenuItem(value: 'edit', child: Text('Edit Goal')),
                                      PopupMenuItem(value: 'delete', child: Text('Delete Goal')),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: g.progress,
                                minHeight: 7,
                                borderRadius: BorderRadius.circular(4),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  g.isCompleted ? SunlightPalette.highVisGreen : SunlightPalette.sunlightYellow,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Text(
                                    '${g.currentValue.toStringAsFixed(g.currentValue % 1 == 0 ? 0 : 1)} / ${g.targetValue.toStringAsFixed(g.targetValue % 1 == 0 ? 0 : 1)} ${g.unit}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  const Spacer(),
                                  IconButton.outlined(
                                    icon: const Icon(Icons.remove, size: 18),
                                    onPressed: g.currentValue > 0
                                        ? () {
                                            HapticFeedback.lightImpact();
                                            plannerDao.updateGoalProgress(
                                              g.id,
                                              (g.currentValue - 1).clamp(0, g.targetValue * 2),
                                              g.targetValue,
                                            );
                                          }
                                        : null,
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton.filledTonal(
                                    icon: const Icon(Icons.add, size: 18),
                                    onPressed: () {
                                      HapticFeedback.lightImpact();
                                      plannerDao.updateGoalProgress(g.id, g.currentValue + 1, g.targetValue);
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showGoalModal(
    BuildContext context,
    MinistryPlannerDao plannerDao, {
    MinistryGoalItem? existing,
  }) async {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final targetCtrl = TextEditingController(text: '${existing?.targetValue ?? 10}');
    final currentCtrl = TextEditingController(text: '${existing?.currentValue ?? 0}');
    final unitCtrl = TextEditingController(text: existing?.unit ?? 'sessions');
    final notesCtrl = TextEditingController(text: existing?.notes ?? '');
    String category = existing?.category ?? 'spiritual_routine';
    String period = existing?.period ?? 'monthly';

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
                existing == null ? 'New Spiritual / Ministry Goal' : 'Edit Goal',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Goal Title *',
                  hintText: 'e.g. Read 4 Bible chapters daily / Join Rural Campaign',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: category,
                      decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'hours', child: Text('Hours / Pioneering')),
                        DropdownMenuItem(value: 'studies', child: Text('Bible Studies')),
                        DropdownMenuItem(value: 'return_visits', child: Text('Return Visits')),
                        DropdownMenuItem(value: 'spiritual_routine', child: Text('Spiritual Routine')),
                        DropdownMenuItem(value: 'congregation_support', child: Text('Congregation Care')),
                        DropdownMenuItem(value: 'expanding_ministry', child: Text('Need-Greater / Lang')),
                      ],
                      onChanged: (v) {
                        if (v != null) setModalState(() => category = v);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: period,
                      decoration: const InputDecoration(labelText: 'Period', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                        DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                        DropdownMenuItem(value: 'service_year', child: Text('Service Year')),
                        DropdownMenuItem(value: 'milestone', child: Text('Milestone')),
                      ],
                      onChanged: (v) {
                        if (v != null) setModalState(() => period = v);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: currentCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Current', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: targetCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Target', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: unitCtrl,
                      decoration: const InputDecoration(labelText: 'Unit', border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesCtrl,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Action Steps / Prayerful Reflection', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.save),
                  label: Text(existing == null ? 'Save Goal' : 'Update Goal'),
                  onPressed: () async {
                    if (titleCtrl.text.trim().isEmpty) return;
                    final tVal = double.tryParse(targetCtrl.text.trim()) ?? 1.0;
                    final cVal = double.tryParse(currentCtrl.text.trim()) ?? 0.0;
                    HapticFeedback.lightImpact();
                    if (existing == null) {
                      await plannerDao.createGoal(
                        title: titleCtrl.text.trim(),
                        category: category,
                        targetValue: tVal,
                        currentValue: cVal,
                        unit: unitCtrl.text.trim().isEmpty ? 'items' : unitCtrl.text.trim(),
                        period: period,
                        notes: notesCtrl.text.trim(),
                      );
                    } else {
                      await plannerDao.updateGoal(
                        id: existing.id,
                        title: titleCtrl.text.trim(),
                        category: category,
                        targetValue: tVal,
                        currentValue: cVal,
                        unit: unitCtrl.text.trim().isEmpty ? 'items' : unitCtrl.text.trim(),
                        period: period,
                        notes: notesCtrl.text.trim(),
                        isCompleted: cVal >= tVal,
                        dueDate: '',
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

  Widget _buildCounterRow({
    required String label,
    required int value,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14))),
          IconButton.outlined(
            icon: const Icon(Icons.remove, size: 18),
            onPressed: value > 0
                ? () {
                    HapticFeedback.lightImpact();
                    onDecrement();
                  }
                : null,
          ),
          SizedBox(
            width: 36,
            child: Text('$value', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          IconButton.outlined(
            icon: const Icon(Icons.add, size: 18),
            onPressed: () {
              HapticFeedback.lightImpact();
              onIncrement();
            },
          ),
        ],
      ),
    );
  }
}

/// Reusable modal for scheduling or editing a Field Service Partner Appointment.
Future<void> showAppointmentFormModal(
  BuildContext context,
  MinistryPlannerDao plannerDao, {
  MinistryAppointmentItem? existing,
  String? initialPartner,
  String? initialFocus,
}) async {
  final now = DateTime.now();
  final partnerCtrl = TextEditingController(text: existing?.partnerName ?? initialPartner ?? '');
  final dateCtrl = TextEditingController(text: existing?.appointmentDate ?? DateFormat('yyyy-MM-dd').format(now));
  final startCtrl = TextEditingController(text: existing?.startTime ?? '09:00');
  final endCtrl = TextEditingController(text: existing?.endTime ?? '11:30');
  final locCtrl = TextEditingController(text: existing?.location ?? 'Kingdom Hall Car Park');
  final notesCtrl = TextEditingController(text: existing?.notes ?? '');
  String ministryType = existing?.ministryType ?? 'Door-to-Door';
  String specialFocus = existing?.specialFocus ?? initialFocus ?? 'standard';
  String status = existing?.status ?? 'scheduled';

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
              existing == null ? 'Schedule Ministry Appointment' : 'Edit Ministry Appointment',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: partnerCtrl,
              decoration: const InputDecoration(
                labelText: 'Service Partner(s) / Group *',
                hintText: 'e.g. Bro. Chinedu / Service Group 2',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: dateCtrl,
              decoration: InputDecoration(
                labelText: 'Date (YYYY-MM-DD)',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: now,
                      firstDate: now.subtract(const Duration(days: 30)),
                      lastDate: now.add(const Duration(days: 365)),
                    );
                    if (d != null) setModalState(() => dateCtrl.text = DateFormat('yyyy-MM-dd').format(d));
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: startCtrl,
                    decoration: const InputDecoration(labelText: 'Start (HH:MM)', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: endCtrl,
                    decoration: const InputDecoration(labelText: 'End (HH:MM)', border: OutlineInputBorder()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: locCtrl,
              decoration: const InputDecoration(
                labelText: 'Meeting Point / Territory',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: ministryType,
              decoration: const InputDecoration(labelText: 'Ministry Activity', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'Door-to-Door', child: Text('Door-to-Door')),
                DropdownMenuItem(value: 'Return Visits / Studies', child: Text('Return Visits / Bible Studies')),
                DropdownMenuItem(value: 'Cart Witnessing', child: Text('Public / Cart Witnessing')),
                DropdownMenuItem(value: 'Business Witnessing', child: Text('Commercial / Business Territory')),
                DropdownMenuItem(value: 'Letter / Telephone', child: Text('Letter Writing / Telephone')),
                DropdownMenuItem(value: 'Rural / Seldom Worked', child: Text('Rural / Seldom-Worked Territory')),
              ],
              onChanged: (v) {
                if (v != null) setModalState(() => ministryType = v);
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: specialFocus,
              decoration: const InputDecoration(labelText: 'Congregation Support / Focus', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'standard', child: Text('Standard Service')),
                DropdownMenuItem(value: 'elderly_care', child: Text('Working with Elderly Publishers')),
                DropdownMenuItem(value: 'special_needs', child: Text('Special Needs Care & Transport')),
                DropdownMenuItem(value: 'youth_training', child: Text('Working with Youth / New Publisher')),
                DropdownMenuItem(value: 'foreign_language', child: Text('Foreign-Language Outreach')),
                DropdownMenuItem(value: 'seldom_worked', child: Text('Seldom-Worked Territory Drive')),
                DropdownMenuItem(value: 'need_greater', child: Text('Expanding Ministry (Where Need Greater)')),
              ],
              onChanged: (v) {
                if (v != null) setModalState(() => specialFocus = v);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Preparation Notes (rides, accessible route, supplies)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.save),
                label: Text(existing == null ? 'Save Appointment' : 'Update Appointment'),
                onPressed: () async {
                  if (partnerCtrl.text.trim().isEmpty) return;
                  HapticFeedback.lightImpact();
                  if (existing == null) {
                    await plannerDao.createAppointment(
                      partnerName: partnerCtrl.text.trim(),
                      appointmentDate: dateCtrl.text.trim(),
                      startTime: startCtrl.text.trim(),
                      endTime: endCtrl.text.trim(),
                      location: locCtrl.text.trim(),
                      ministryType: ministryType,
                      specialFocus: specialFocus,
                      notes: notesCtrl.text.trim(),
                    );
                  } else {
                    await plannerDao.updateAppointment(
                      id: existing.id,
                      partnerName: partnerCtrl.text.trim(),
                      appointmentDate: dateCtrl.text.trim(),
                      startTime: startCtrl.text.trim(),
                      endTime: endCtrl.text.trim(),
                      location: locCtrl.text.trim(),
                      ministryType: ministryType,
                      specialFocus: specialFocus,
                      notes: notesCtrl.text.trim(),
                      status: status,
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
