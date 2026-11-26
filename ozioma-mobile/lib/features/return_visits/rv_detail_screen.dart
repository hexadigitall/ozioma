import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/database/daos/return_visit_dao.dart';
import '../../core/database/database_providers.dart';
import '../../core/theme/sunlight_palette.dart';
import '../../screens/rv_screen.dart';

/// Comprehensive Discipleship Workspace:
/// Curriculum Progress, Study Sessions (Start/End/Summary), Student Questions, & Spiritual Milestones.
class RvDetailScreen extends ConsumerStatefulWidget {
  final ReturnVisitItem rv;

  const RvDetailScreen({
    super.key,
    required this.rv,
  });

  @override
  ConsumerState<RvDetailScreen> createState() => _RvDetailScreenState();
}

class _RvDetailScreenState extends ConsumerState<RvDetailScreen> {
  static const List<String> enjoyLifeForeverLessons = [
    '01. How Can the Bible Help You?',
    '02. The Bible Gives Hope',
    '03. Can You Trust the Bible?',
    '04. Who Is God?',
    '05. The Bible Is God\'s Message',
    '06. How Did Life Begin?',
    '07. What Is God Like?',
    '08. How Can You Become God\'s Friend?',
    '09. How to Draw Close to God in Prayer',
    '10. How Christian Meetings Help Us',
    '11. Getting the Most Out of the Bible',
    '12. How Can God\'s Word Help You?',
    '13. What Happened in Eden?',
    '14. Who Is Jesus Christ?',
    '15. What Did Jesus Do on Earth?',
    '16. What Does Jesus\' Death Mean for You?',
    '17. God\'s Kingdom: A Real Government',
    '18. The Good News of the Kingdom',
    '19. What Happens When We Die?',
    '20. What Is the Resurrection Hope?',
    '21. What Is the Truth About Angels & Demons?',
    '22. Why Does God Allow Suffering?',
    '23. How You Can Draw Close to God',
    '24. Worship That Pleases God',
    '25. True Religion: How to Identify It',
    '26. Baptism: A Public Declaration',
    '27. Friendship with God\'s People',
    '28. How God\'s Principles Protect Us',
    '29. Your View of Blood',
    '30. Marriage and Family Life',
    '31. Raising Children Who Love God',
    '32. What Does the Bible Say About Work & Money?',
    '33. Honesty and Clean Living',
    '34. What Is Sin?',
    '35. How God Views Entertainment',
    '36. Holidays and Celebrations',
    '37. Remaining Neutral in Politics',
    '38. Cultivating Love in the Congregation',
    '39. How Elders Shepherd God\'s Flock',
    '40. Handling Disagreements in Love',
    '41. Preaching the Good News',
    '42. Making Disciples of All Nations',
    '43. Overcoming Obstacles in Preaching',
    '44. Dedication and Service to Jehovah',
    '45. Becoming an Unbaptized Publisher',
    '46. Preparing for Baptism',
    '47. Keeping Your Promise to God',
    '48. Walking in Integrity',
    '49. Enduring Opposition and Persecution',
    '50. Trusting Jehovah During Trials',
    '51. Remaining Spiritually Alert',
    '52. Jehovah\'s Organization on Earth',
    '53. Supporting Congregation Activities',
    '54. Making Wise Decisions',
    '55. Living for God\'s Will',
    '56. The Role of the Holy Spirit',
    '57. Resisting Worldly Desires',
    '58. Putting the Kingdom First',
    '59. The Great Tribulation and Armageddon',
    '60. Living Forever in Paradise',
  ];

  String _sectionNameForLesson(int lesson) {
    if (lesson <= 12) return 'Section 1: Intro to the Bible';
    if (lesson <= 33) return 'Section 2: God\'s Promises';
    if (lesson <= 47) return 'Section 3: Christian Living';
    return 'Section 4: Deep Truths';
  }

  @override
  Widget build(BuildContext context) {
    final dao = ref.watch(returnVisitDaoProvider);

    return StreamBuilder<ReturnVisitItem?>(
      stream: dao.watchReturnVisitById(widget.rv.id),
      initialData: widget.rv,
      builder: (context, snapshot) {
        final currentRv = snapshot.data ?? widget.rv;

        return DefaultTabController(
          length: 4,
          child: Scaffold(
            appBar: AppBar(
              title: Text(
                currentRv.householderName.isNotEmpty ? currentRv.householderName : 'Contact Profile',
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Edit Student Profile',
                  onPressed: () => showReturnVisitFormModal(context, dao, existing: currentRv),
                ),
                IconButton(
                  icon: const Icon(Icons.add_task),
                  tooltip: 'Log Study Session',
                  onPressed: () => _showStudySessionModal(context, dao, currentRv),
                ),
              ],
              bottom: const TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: [
                  Tab(icon: Icon(Icons.person_outline, size: 18), text: 'Overview'),
                  Tab(icon: Icon(Icons.history_edu, size: 18), text: 'Sessions'),
                  Tab(icon: Icon(Icons.help_outline, size: 18), text: 'Questions'),
                  Tab(icon: Icon(Icons.emoji_events_outlined, size: 18), text: 'Milestones'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _buildOverviewTab(context, dao, currentRv),
                _buildSessionsTab(context, dao, currentRv),
                _buildQuestionsTab(context, dao, currentRv),
                _buildMilestonesTab(context, dao, currentRv),
              ],
            ),
          ),
        );
      },
    );
  }

  // =========================================================================
  // TAB 1: OVERVIEW & CURRICULUM
  // =========================================================================

  Widget _buildOverviewTab(BuildContext context, ReturnVisitDao dao, ReturnVisitItem rv) {
    final currentLesson = rv.currentLesson.clamp(1, 60);
    final progress = currentLesson / 60.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: rv.isBibleStudy ? SunlightPalette.highVisGreen : const Color(0xFF0F172A),
                      foregroundColor: rv.isBibleStudy ? Colors.black : Colors.white,
                      child: Icon(rv.isBibleStudy ? Icons.menu_book : Icons.person, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rv.householderName.isNotEmpty ? rv.householderName : 'Anonymous Contact',
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            rv.isBibleStudy ? 'Active Bible Study (${rv.studyPublication})' : 'Return Visit',
                            style: TextStyle(
                              color: rv.isBibleStudy ? SunlightPalette.highVisGreen : Colors.grey,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 22),
                _detailRow(Icons.phone_outlined, rv.phoneNumber.isNotEmpty ? rv.phoneNumber : 'No phone recorded'),
                const SizedBox(height: 6),
                _detailRow(
                  Icons.location_on_outlined,
                  rv.addressText.isNotEmpty ? rv.addressText : 'No street / landmark recorded',
                ),
                const SizedBox(height: 6),
                _detailRow(Icons.access_time, 'Best time: ${rv.preferredTime} • Language: ${rv.language}'),
                if (rv.nextVisitDate.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _detailRow(Icons.event_available, 'Scheduled Next Study: ${rv.nextVisitDate}'),
                ],
                if (rv.goal.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: SunlightPalette.sunlightYellow.withValues(alpha: isDark ? 0.14 : 0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: SunlightPalette.sunlightYellow.withValues(alpha: 0.45)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.flag_outlined, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Student Goal: ${rv.goal}',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Enjoy Life Forever Curriculum Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_stories, color: SunlightPalette.sunlightYellow, size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Bible Study Curriculum', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          Text(_sectionNameForLesson(currentLesson), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                    Text(
                      'Lesson $currentLesson / 60',
                      style: const TextStyle(fontWeight: FontWeight.w800, color: SunlightPalette.highVisGreen),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: const Color(0xFF334155),
                    valueColor: const AlwaysStoppedAnimation<Color>(SunlightPalette.highVisGreen),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: currentLesson,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Select Current Lesson',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: List.generate(
                    60,
                    (idx) => DropdownMenuItem<int>(
                      value: idx + 1,
                      child: Text(
                        enjoyLifeForeverLessons[idx],
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  onChanged: (val) async {
                    if (val != null) {
                      HapticFeedback.lightImpact();
                      await dao.updateLesson(rv.id, val);
                    }
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.remove),
                        label: const Text('Prev Lesson'),
                        onPressed: currentLesson > 1
                            ? () async {
                                HapticFeedback.lightImpact();
                                await dao.updateLesson(rv.id, currentLesson - 1);
                              }
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Next Lesson'),
                        onPressed: currentLesson < 60
                            ? () async {
                                HapticFeedback.lightImpact();
                                await dao.updateLesson(rv.id, currentLesson + 1);
                              }
                            : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Personal Notes & Quick Log Button
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Personal Notes & Background', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    TextButton.icon(
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Edit'),
                      onPressed: () => showReturnVisitFormModal(context, dao, existing: rv),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  rv.notes.isNotEmpty ? rv.notes : 'No background notes recorded yet.',
                  style: TextStyle(
                    fontSize: 14,
                    fontStyle: rv.notes.isEmpty ? FontStyle.italic : FontStyle.normal,
                    color: rv.notes.isEmpty ? Colors.grey : null,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.history_edu),
                    label: const Text('Record Last Study / Visit Summary'),
                    onPressed: () => _showStudySessionModal(context, dao, rv),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _detailRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
      ],
    );
  }

  // =========================================================================
  // TAB 2: STUDY SESSIONS (STARTS, ENDS, SUMMARIES, NEXT QUESTIONS)
  // =========================================================================

  Widget _buildSessionsTab(BuildContext context, ReturnVisitDao dao, ReturnVisitItem rv) {
    return StreamBuilder<List<StudySessionItem>>(
      stream: dao.watchStudySessions(rv.id),
      builder: (context, snapshot) {
        final sessions = snapshot.data ?? [];
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            FilledButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Log Study Session (Start, End & Summary)'),
              onPressed: () => _showStudySessionModal(context, dao, rv),
            ),
            const SizedBox(height: 14),
            if (sessions.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(Icons.history_edu, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('No study sessions logged yet', style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text(
                        'Log when each study started & ended, scriptures discussed, a summary of the student\'s response, and the question left for next time.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...sessions.map(
                (s) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 15, color: SunlightPalette.highVisGreen),
                              const SizedBox(width: 6),
                              Text(
                                '${s.sessionDate} (${s.startTime} - ${s.endTime})',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: SunlightPalette.highVisGreen.withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'L${s.lessonNumber} • ${s.durationMinutes}m',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: SunlightPalette.highVisGreen),
                                ),
                              ),
                              PopupMenuButton<String>(
                                onSelected: (val) async {
                                  if (val == 'edit') {
                                    await _showStudySessionModal(context, dao, rv, existing: s);
                                  } else if (val == 'delete') {
                                    await dao.deleteStudySession(s.id);
                                  }
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(value: 'edit', child: Text('Edit Session')),
                                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                                ],
                              ),
                            ],
                          ),
                          if (s.scriptures.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Scriptures: ${s.scriptures}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: SunlightPalette.highVisCyan),
                            ),
                          ],
                          if (s.summary.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(s.summary, style: const TextStyle(fontSize: 13)),
                          ],
                          if (s.nextQuestion.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blueGrey.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.arrow_forward, size: 15),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Next Discussion: ${s.nextQuestion}',
                                      style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                                    ),
                                  ),
                                ],
                              ),
                            ),
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

  Future<void> _showStudySessionModal(
    BuildContext context,
    ReturnVisitDao dao,
    ReturnVisitItem rv, {
    StudySessionItem? existing,
  }) async {
    final now = DateTime.now();
    final dateCtrl = TextEditingController(
      text: existing?.sessionDate ?? DateFormat('yyyy-MM-dd').format(now),
    );
    final startCtrl = TextEditingController(text: existing?.startTime ?? '09:00');
    final endCtrl = TextEditingController(text: existing?.endTime ?? '09:45');
    final scripturesCtrl = TextEditingController(text: existing?.scriptures ?? '');
    final summaryCtrl = TextEditingController(text: existing?.summary ?? '');
    final nextQCtrl = TextEditingController(text: existing?.nextQuestion ?? '');
    int lesson = existing?.lessonNumber ?? rv.currentLesson.clamp(1, 60);
    int durationMins = existing?.durationMinutes ?? 45;

    int calcMinutes(String start, String end) {
      final sp = start.split(':');
      final ep = end.split(':');
      if (sp.length == 2 && ep.length == 2) {
        final sM = (int.tryParse(sp[0]) ?? 9) * 60 + (int.tryParse(sp[1]) ?? 0);
        final eM = (int.tryParse(ep[0]) ?? 9) * 60 + (int.tryParse(ep[1]) ?? 45);
        if (eM >= sM) return eM - sM;
      }
      return 45;
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
                existing == null ? 'Log Study / Visit Session' : 'Edit Study Session',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: dateCtrl,
                decoration: InputDecoration(
                  labelText: 'Session Date (YYYY-MM-DD)',
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
                      if (d != null) {
                        setModalState(() => dateCtrl.text = DateFormat('yyyy-MM-dd').format(d));
                      }
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
                      onChanged: (_) => setModalState(() => durationMins = calcMinutes(startCtrl.text, endCtrl.text)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: endCtrl,
                      decoration: const InputDecoration(labelText: 'End (HH:MM)', border: OutlineInputBorder()),
                      onChanged: (_) => setModalState(() => durationMins = calcMinutes(startCtrl.text, endCtrl.text)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Chip(label: Text('${durationMins}m')),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: lesson.clamp(1, 60),
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Lesson Studied', border: OutlineInputBorder()),
                items: List.generate(
                  60,
                  (i) => DropdownMenuItem(
                    value: i + 1,
                    child: Text(enjoyLifeForeverLessons[i], overflow: TextOverflow.ellipsis),
                  ),
                ),
                onChanged: (v) {
                  if (v != null) setModalState(() => lesson = v);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: scripturesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Scriptures Discussed',
                  hintText: 'e.g. Rev 21:3, 4; John 17:3',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: summaryCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Session Summary & Student Progress',
                  hintText: 'Key points student grasped, attitude, action steps...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nextQCtrl,
                decoration: const InputDecoration(
                  labelText: 'Linking Question for Next Time',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Save Session'),
                  onPressed: () async {
                    HapticFeedback.lightImpact();
                    if (existing == null) {
                      await dao.addStudySession(
                        studentId: rv.id,
                        sessionDate: dateCtrl.text.trim(),
                        startTime: startCtrl.text.trim(),
                        endTime: endCtrl.text.trim(),
                        durationMinutes: durationMins,
                        lessonNumber: lesson,
                        scriptures: scripturesCtrl.text.trim(),
                        summary: summaryCtrl.text.trim(),
                        nextQuestion: nextQCtrl.text.trim(),
                      );
                    } else {
                      await dao.updateStudySession(
                        id: existing.id,
                        sessionDate: dateCtrl.text.trim(),
                        startTime: startCtrl.text.trim(),
                        endTime: endCtrl.text.trim(),
                        durationMinutes: durationMins,
                        lessonNumber: lesson,
                        scriptures: scripturesCtrl.text.trim(),
                        summary: summaryCtrl.text.trim(),
                        nextQuestion: nextQCtrl.text.trim(),
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
  // TAB 3: STUDENT QUESTIONS & BIBLICAL REFERENCES
  // =========================================================================

  Widget _buildQuestionsTab(BuildContext context, ReturnVisitDao dao, ReturnVisitItem rv) {
    return StreamBuilder<List<StudentQuestionItem>>(
      stream: dao.watchStudentQuestions(rv.id),
      builder: (context, snapshot) {
        final questions = snapshot.data ?? [];
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            FilledButton.icon(
              icon: const Icon(Icons.add_comment_outlined),
              label: const Text('Add Student Question / Topic'),
              onPressed: () => _showQuestionModal(context, dao, rv),
            ),
            const SizedBox(height: 14),
            if (questions.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(Icons.help_outline, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('No student questions recorded', style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text(
                        'Capture every question your student asks so you can research thorough, loving Scriptural answers before your next visit.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...questions.map(
                (q) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                q.isAnswered ? Icons.check_circle : Icons.pending_actions,
                                color: q.isAnswered ? SunlightPalette.highVisGreen : SunlightPalette.sunlightYellow,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  q.question,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                              ),
                              PopupMenuButton<String>(
                                onSelected: (val) async {
                                  if (val == 'toggle') {
                                    await dao.updateStudentQuestion(
                                      id: q.id,
                                      question: q.question,
                                      answer: q.answer,
                                      scriptures: q.scriptures,
                                      isAnswered: !q.isAnswered,
                                    );
                                  } else if (val == 'edit') {
                                    await _showQuestionModal(context, dao, rv, existing: q);
                                  } else if (val == 'delete') {
                                    await dao.deleteStudentQuestion(q.id);
                                  }
                                },
                                itemBuilder: (_) => [
                                  PopupMenuItem(
                                    value: 'toggle',
                                    child: Text(q.isAnswered ? 'Mark Pending' : 'Mark Answered'),
                                  ),
                                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                                ],
                              ),
                            ],
                          ),
                          if (q.scriptures.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              'References: ${q.scriptures}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: SunlightPalette.highVisCyan),
                            ),
                          ],
                          if (q.answer.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(q.answer, style: const TextStyle(fontSize: 13)),
                          ],
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: OutlinedButton.icon(
                              icon: Icon(q.isAnswered ? Icons.undo : Icons.check, size: 16),
                              label: Text(q.isAnswered ? 'Reopen Question' : 'Mark Discussed & Answered'),
                              onPressed: () async {
                                HapticFeedback.lightImpact();
                                await dao.updateStudentQuestion(
                                  id: q.id,
                                  question: q.question,
                                  answer: q.answer,
                                  scriptures: q.scriptures,
                                  isAnswered: !q.isAnswered,
                                );
                              },
                            ),
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
  }

  Future<void> _showQuestionModal(
    BuildContext context,
    ReturnVisitDao dao,
    ReturnVisitItem rv, {
    StudentQuestionItem? existing,
  }) async {
    final qCtrl = TextEditingController(text: existing?.question ?? '');
    final scripCtrl = TextEditingController(text: existing?.scriptures ?? '');
    final ansCtrl = TextEditingController(text: existing?.answer ?? '');
    bool answered = existing?.isAnswered ?? false;

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
                existing == null ? 'Record Student Question' : 'Update Student Question',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: qCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Question / Doubt Raised *',
                  hintText: 'e.g. Why doesn\'t God destroy Satan right away?',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: scripCtrl,
                decoration: const InputDecoration(
                  labelText: 'Key Scriptures & jw.org References',
                  hintText: 'e.g. Job 1:9-11; 2 Pet 3:9; Lesson 22',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ansCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Prepared Scriptural Explanation',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Answered with Student'),
                value: answered,
                onChanged: (v) => setModalState(() => answered = v),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Save Question'),
                  onPressed: () async {
                    if (qCtrl.text.trim().isEmpty) return;
                    HapticFeedback.lightImpact();
                    if (existing == null) {
                      await dao.addStudentQuestion(
                        studentId: rv.id,
                        question: qCtrl.text.trim(),
                        scriptures: scripCtrl.text.trim(),
                        answer: ansCtrl.text.trim(),
                        isAnswered: answered,
                      );
                    } else {
                      await dao.updateStudentQuestion(
                        id: existing.id,
                        question: qCtrl.text.trim(),
                        scriptures: scripCtrl.text.trim(),
                        answer: ansCtrl.text.trim(),
                        isAnswered: answered,
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
  // TAB 4: SPIRITUAL DISCIPLESHIP MILESTONES TIMELINE
  // =========================================================================

  Widget _buildMilestonesTab(BuildContext context, ReturnVisitDao dao, ReturnVisitItem rv) {
    return StreamBuilder<List<StudentMilestoneItem>>(
      stream: dao.watchStudentMilestones(rv.id),
      builder: (context, snapshot) {
        final achievedList = snapshot.data ?? [];
        final byKey = {for (final m in achievedList) m.milestoneKey: m};
        final total = canonicalStudentMilestones.length;
        final doneCount = byKey.length;

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
                        const Text(
                          'Discipleship Journey Timeline',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                        Text(
                          '$doneCount / $total',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: SunlightPalette.highVisGreen,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: total > 0 ? doneCount / total : 0,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tap any milestone to record the date, personal reflection, and help your student take the next loving step.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ...List.generate(canonicalStudentMilestones.length, (index) {
              final def = canonicalStudentMilestones[index];
              final record = byKey[def.key];
              final isDone = record != null;
              final isLast = index == canonicalStudentMilestones.length - 1;

              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: 36,
                      child: Column(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDone ? SunlightPalette.highVisGreen : Colors.grey.shade800,
                              border: Border.all(
                                color: isDone ? SunlightPalette.highVisGreen : Colors.grey,
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: isDone
                                  ? const Icon(Icons.check, size: 16, color: Colors.black)
                                  : Text(
                                      '${def.order}',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                            ),
                          ),
                          if (!isLast)
                            Expanded(
                              child: Container(
                                width: 2,
                                color: isDone ? SunlightPalette.highVisGreen : Colors.grey.shade700,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Card(
                          margin: EdgeInsets.zero,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _showMilestoneModal(context, dao, rv, def, record),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          def.title,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 15,
                                            color: isDone ? SunlightPalette.highVisGreen : null,
                                          ),
                                        ),
                                      ),
                                      if (isDone)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: SunlightPalette.highVisGreen.withValues(alpha: 0.18),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            record.achievedDate,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: SunlightPalette.highVisGreen,
                                            ),
                                          ),
                                        )
                                      else
                                        const Text(
                                          'Tap to log',
                                          style: TextStyle(fontSize: 11, color: Colors.grey),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(def.subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                  const SizedBox(height: 6),
                                  if (isDone && record.notes.isNotEmpty)
                                    Text(
                                      record.notes,
                                      style: const TextStyle(fontSize: 13),
                                    )
                                  else if (!isDone)
                                    Text(
                                      'Tip: ${def.encouragement}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                        color: SunlightPalette.sunlightYellow,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Future<void> _showMilestoneModal(
    BuildContext context,
    ReturnVisitDao dao,
    ReturnVisitItem rv,
    DiscipleshipMilestoneDef def,
    StudentMilestoneItem? existing,
  ) async {
    final dateCtrl = TextEditingController(
      text: existing?.achievedDate ?? DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );
    final notesCtrl = TextEditingController(text: existing?.notes ?? '');

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => Padding(
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
            Text(def.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(def.subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 14),
            TextField(
              controller: dateCtrl,
              decoration: InputDecoration(
                labelText: 'Date Achieved (YYYY-MM-DD)',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2015),
                      lastDate: DateTime(2035),
                    );
                    if (d != null) {
                      dateCtrl.text = DateFormat('yyyy-MM-dd').format(d);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Encouraging Memory / Reflection Notes',
                hintText: 'e.g. Shared their first comment during the Watchtower study!',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (existing != null) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Clear'),
                      onPressed: () async {
                        await dao.removeStudentMilestone(rv.id, def.key);
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.check),
                    label: Text(existing == null ? 'Record Milestone' : 'Update Milestone'),
                    onPressed: () async {
                      HapticFeedback.mediumImpact();
                      await dao.setStudentMilestone(
                        studentId: rv.id,
                        milestoneKey: def.key,
                        achievedDate: dateCtrl.text.trim(),
                        notes: notesCtrl.text.trim(),
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
