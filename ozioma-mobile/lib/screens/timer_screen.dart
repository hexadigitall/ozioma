import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:async';
import '../core/database/database_providers.dart';
import '../core/database/daos/service_log_dao.dart';
import '../core/theme/sunlight_palette.dart';

class TimerScreen extends ConsumerStatefulWidget {
  const TimerScreen({super.key});

  @override
  ConsumerState<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends ConsumerState<TimerScreen> {
  Timer? _ticker;
  int _secondsElapsed = 0;
  bool _isRunning = false;
  int _placements = 0;
  int _videos = 0;
  int _bibleStudies = 0;
  int _monthlyGoalHours = 50; // Standard Regular Pioneer 50h goal

  void _toggleTimer() {
    HapticFeedback.mediumImpact();
    if (_isRunning) {
      _ticker?.cancel();
      setState(() => _isRunning = false);
    } else {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() => _secondsElapsed++);
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
      _placements = 0;
      _videos = 0;
      _bibleStudies = 0;
    });
  }

  Future<void> _logAndSaveSession() async {
    if (_secondsElapsed == 0) return;
    HapticFeedback.heavyImpact();
    final logDao = ref.read(serviceLogDaoProvider);
    final duration = Duration(seconds: _secondsElapsed);

    await logDao.logSession(
      userId: 'publisher_me',
      date: DateTime.now(),
      duration: duration,
      placementsCount: _placements,
      videoShowingsCount: _videos,
      bibleStudiesCount: _bibleStudies,
    );

    _resetTimer();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Session saved: ${duration.inMinutes} mins logged to S-4 monthly record.'),
          backgroundColor: SunlightPalette.highVisGreen,
        ),
      );
    }
  }

  void _shareMonthlyReport(List<ServiceLogItem> logs) {
    HapticFeedback.mediumImpact();
    final now = DateTime.now();
    final monthName = DateFormat('MMMM yyyy').format(now);
    final totalMinutes = logs.fold<int>(0, (sum, l) => sum + l.durationMinutes);
    final totalHours = (totalMinutes / 60.0).toStringAsFixed(1);
    final totalPlacements = logs.fold<int>(0, (sum, l) => sum + l.placementsCount);
    final totalVideos = logs.fold<int>(0, (sum, l) => sum + l.videoShowingsCount);
    final totalStudies = logs.fold<int>(0, (sum, l) => sum + l.bibleStudiesCount);

    final reportText = '''
Field Service Report (S-4) — $monthName
Publisher: Field Publisher
----------------------------------
Hours: $totalHours
Placements: $totalPlacements
Video Showings: $totalVideos
Bible Studies: $totalStudies
----------------------------------
Logged via Ozioma Platform
''';

    Share.share(reportText, subject: 'S-4 Report - $monthName');
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hours = (_secondsElapsed ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((_secondsElapsed % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsElapsed % 60).toString().padLeft(2, '0');

    final logDao = ref.watch(serviceLogDaoProvider);
    final currentMonthKey = DateFormat('yyyy-MM').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Field Service Timer'),
        actions: [
          StreamBuilder<List<ServiceLogItem>>(
            stream: logDao.watchMonthlyLogs(currentMonthKey),
            builder: (context, snapshot) {
              final logs = snapshot.data ?? [];
              return IconButton(
                icon: const Icon(Icons.share_outlined),
                tooltip: 'Share S-4 Report to Group Overseer',
                onPressed: () => _shareMonthlyReport(logs),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // Monthly Goal & Pioneer Pacing Dashboard Card
          StreamBuilder<List<ServiceLogItem>>(
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

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Monthly Goal & Pioneer Pacing',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          DropdownButton<int>(
                            value: _monthlyGoalHours,
                            isDense: true,
                            underline: const SizedBox(),
                            items: const [
                              DropdownMenuItem(value: 50, child: Text('50h (Pioneer)')),
                              DropdownMenuItem(value: 30, child: Text('30h (Auxiliary)')),
                              DropdownMenuItem(value: 15, child: Text('15h (Auxiliary)')),
                              DropdownMenuItem(value: 10, child: Text('10h (Personal)')),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _monthlyGoalHours = val);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${totalHours.toStringAsFixed(1)} / ${_monthlyGoalHours}h',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                          ),
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
                        backgroundColor: Colors.grey.shade800,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          progress >= 1.0 ? SunlightPalette.highVisGreen : SunlightPalette.sunlightYellow,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        daysRemaining > 0
                          ? '$daysRemaining days remaining • ${dailyPace.toStringAsFixed(1)} h/day needed'
                          : 'End of service month reached',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),

          // Timer Card
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Column(
                children: [
                  Text(
                    '$hours:$minutes:$seconds',
                    style: const TextStyle(
                      fontSize: 54,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isRunning ? SunlightPalette.highVisGreen : Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isRunning ? 'Logging Active Ministry' : 'Timer Paused',
                        style: TextStyle(
                          color: _isRunning ? SunlightPalette.highVisGreen : Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Primary Controls (>= 48x48dp touch targets)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton.filledTonal(
                        iconSize: 28,
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Reset',
                        onPressed: _secondsElapsed > 0 ? _resetTimer : null,
                      ),
                      const SizedBox(width: 20),
                      IconButton.filled(
                        iconSize: 44,
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
                        iconSize: 28,
                        icon: const Icon(Icons.save),
                        tooltip: 'Save Session',
                        onPressed: _secondsElapsed > 0 ? _logAndSaveSession : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Manual Adjustments / Credit Hours
                  const Text('Manual Time Adjustment / Credit', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      ActionChip(
                        label: const Text('-15m'),
                        onPressed: _secondsElapsed >= 900 ? () => _adjustTime(-15) : null,
                      ),
                      ActionChip(
                        label: const Text('+15m'),
                        onPressed: () => _adjustTime(15),
                      ),
                      ActionChip(
                        label: const Text('+30m'),
                        onPressed: () => _adjustTime(30),
                      ),
                      ActionChip(
                        label: const Text('+1h (Credit)'),
                        onPressed: () => _adjustTime(60),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Session Counters (Placements, Videos, Studies)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Session Placements & Activity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 12),
                  _buildCounterRow(
                    label: 'Publications Placed',
                    value: _placements,
                    onDecrement: () {
                      if (_placements > 0) setState(() => _placements--);
                    },
                    onIncrement: () => setState(() => _placements++),
                  ),
                  const Divider(),
                  _buildCounterRow(
                    label: 'Videos Shown',
                    value: _videos,
                    onDecrement: () {
                      if (_videos > 0) setState(() => _videos--);
                    },
                    onIncrement: () => setState(() => _videos++),
                  ),
                  const Divider(),
                  _buildCounterRow(
                    label: 'Bible Studies Conducted',
                    value: _bibleStudies,
                    onDecrement: () {
                      if (_bibleStudies > 0) setState(() => _bibleStudies--);
                    },
                    onIncrement: () => setState(() => _bibleStudies++),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCounterRow({
    required String label,
    required int value,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
  }) {
    return Row(
      children: [
        Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14))),
        IconButton.outlined(
          icon: const Icon(Icons.remove, size: 18),
          onPressed: value > 0 ? () {
            HapticFeedback.lightImpact();
            onDecrement();
          } : null,
        ),
        SizedBox(
          width: 36,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        IconButton.outlined(
          icon: const Icon(Icons.add, size: 18),
          onPressed: () {
            HapticFeedback.lightImpact();
            onIncrement();
          },
        ),
      ],
    );
  }
}
