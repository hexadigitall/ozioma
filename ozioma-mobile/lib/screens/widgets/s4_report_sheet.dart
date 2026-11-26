import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/database/daos/ministry_planner_dao.dart';
import '../../core/database/daos/service_log_dao.dart';
import '../../core/theme/sunlight_palette.dart';

/// Prompts & builds an official Form S-4 Monthly Field Service Report
/// with role selection, credit hours, participation check, persistence, and sharing.
Future<void> showS4ReportSheet({
  required BuildContext context,
  required ServiceLogDao serviceLogDao,
  required MinistryPlannerDao plannerDao,
  required String yearMonth,
  required List<ServiceLogItem> monthlyLogs,
  MonthlyReportRecord? existingRecord,
  int suggestedStudiesCount = 0,
}) async {
  final totalMinutes = monthlyLogs.fold<int>(0, (sum, l) => sum + l.durationMinutes);
  final loggedHours = totalMinutes / 60.0;
  final loggedStudies = monthlyLogs.fold<int>(0, (sum, l) => sum + l.bibleStudiesCount);
  final defaultStudies = existingRecord?.bibleStudiesCount ??
      (suggestedStudiesCount > 0 ? suggestedStudiesCount : loggedStudies);

  String role = existingRecord?.publisherRole ?? 'reg_pioneer';
  int hourGoal = existingRecord?.monthlyHourGoal ?? 50;
  bool participated = existingRecord?.participatedInMinistry ?? (totalMinutes > 0 || defaultStudies > 0);
  final hoursCtrl = TextEditingController(
    text: (existingRecord != null && existingRecord.hoursReported > 0
            ? existingRecord.hoursReported
            : loggedHours)
        .toStringAsFixed(1),
  );
  final creditCtrl = TextEditingController(
    text: (existingRecord?.creditHours ?? 0.0).toStringAsFixed(1),
  );
  final studiesCtrl = TextEditingController(text: '$defaultStudies');
  final commentsCtrl = TextEditingController(text: existingRecord?.comments ?? '');
  bool isSubmitted = existingRecord?.isSubmitted ?? false;

  final parsedMonth = DateTime.tryParse('$yearMonth-01') ?? DateTime.now();
  final monthTitle = DateFormat('MMMM yyyy').format(parsedMonth);

  int goalForRole(String r) {
    switch (r) {
      case 'reg_pioneer':
        return 50;
      case 'aux_pioneer_30':
        return 30;
      case 'aux_pioneer_15':
        return 15;
      default:
        return 0;
    }
  }

  String roleLabel(String r) {
    switch (r) {
      case 'reg_pioneer':
        return 'Regular Pioneer (50h)';
      case 'aux_pioneer_30':
        return 'Auxiliary Pioneer (30h)';
      case 'aux_pioneer_15':
        return 'Auxiliary Pioneer (15h)';
      default:
        return 'Publisher';
    }
  }

  String buildShareText() {
    final h = double.tryParse(hoursCtrl.text.trim()) ?? loggedHours;
    final c = double.tryParse(creditCtrl.text.trim()) ?? 0.0;
    final st = int.tryParse(studiesCtrl.text.trim()) ?? defaultStudies;
    final buf = StringBuffer()
      ..writeln('FIELD SERVICE REPORT (S-4) — $monthTitle')
      ..writeln('Service Privilege: ${roleLabel(role)}')
      ..writeln('Participated in Ministry: ${participated ? "Yes" : "No"}');
    if (role != 'publisher' || h > 0) {
      buf.writeln('Hours: ${h.toStringAsFixed(1)}');
    }
    if (c > 0) {
      buf.writeln('Credit Hours: ${c.toStringAsFixed(1)}');
    }
    buf.writeln('Different Bible Studies: $st');
    if (commentsCtrl.text.trim().isNotEmpty) {
      buf.writeln('Comments: ${commentsCtrl.text.trim()}');
    }
    buf.writeln('Submitted promptly via Ozioma');
    return buf.toString();
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
            Row(
              children: [
                const Icon(Icons.assignment_turned_in, color: SunlightPalette.highVisGreen),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Form S-4 Report — $monthTitle',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            if (isSubmitted)
              Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: SunlightPalette.highVisGreen.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.verified, size: 16, color: SunlightPalette.highVisGreen),
                      SizedBox(width: 6),
                      Text(
                        'Marked as Submitted to Group Overseer',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: SunlightPalette.highVisGreen),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: role,
              decoration: const InputDecoration(
                labelText: 'Service Privilege / Goal',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'publisher', child: Text('Publisher (Active Checkmark)')),
                DropdownMenuItem(value: 'aux_pioneer_15', child: Text('Auxiliary Pioneer (15 hrs)')),
                DropdownMenuItem(value: 'aux_pioneer_30', child: Text('Auxiliary Pioneer (30 hrs)')),
                DropdownMenuItem(value: 'reg_pioneer', child: Text('Regular Pioneer (50 hrs)')),
              ],
              onChanged: (val) {
                if (val != null) {
                  setModalState(() {
                    role = val;
                    hourGoal = goalForRole(val);
                  });
                }
              },
            ),
            const SizedBox(height: 10),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Participated in Ministry This Month', style: TextStyle(fontWeight: FontWeight.bold)),
              value: participated,
              onChanged: (v) => setModalState(() => participated = v),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: hoursCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Hours',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: creditCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Credit Hours',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: studiesCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Bible Studies',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: commentsCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Comments (e.g. Special assignments, LDC, illness)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy Text'),
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: buildShareText()));
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(content: Text('S-4 Report copied to clipboard')),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
                    onPressed: () async {
                      await Share.share(buildShareText(), subject: 'S-4 Report — $monthTitle');
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.check_circle_outline),
                label: Text(isSubmitted ? 'Update Saved Report' : 'Save & Mark Submitted'),
                onPressed: () async {
                  HapticFeedback.mediumImpact();
                  await plannerDao.upsertMonthlyReport(
                    yearMonth: yearMonth,
                    publisherRole: role,
                    monthlyHourGoal: hourGoal,
                    participatedInMinistry: participated,
                    hoursReported: double.tryParse(hoursCtrl.text.trim()) ?? loggedHours,
                    creditHours: double.tryParse(creditCtrl.text.trim()) ?? 0.0,
                    bibleStudiesCount: int.tryParse(studiesCtrl.text.trim()) ?? defaultStudies,
                    comments: commentsCtrl.text.trim(),
                    isSubmitted: true,
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
