import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/daos/return_visit_dao.dart';
import '../../core/database/database_providers.dart';
import '../../core/theme/sunlight_palette.dart';

/// Return Visit & "Enjoy Life Forever!" Study Tracker Screen (Sprint 6)
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
  late int _currentLesson;
  final TextEditingController _newNoteCtrl = TextEditingController();

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
    // Lessons 13 - 33: Section 2
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
    // Lessons 34 - 47: Section 3
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
    // Lessons 48 - 60: Section 4
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

  @override
  void initState() {
    super.initState();
    _currentLesson = widget.rv.currentLesson.clamp(1, 60);
  }

  @override
  void dispose() {
    _newNoteCtrl.dispose();
    super.dispose();
  }

  Future<void> _updateLesson(int newLesson) async {
    final clamped = newLesson.clamp(1, 60);
    setState(() => _currentLesson = clamped);
    final dao = ref.read(returnVisitDaoProvider);
    await dao.updateLesson(widget.rv.id, clamped);
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _currentLesson / 60.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.rv.householderName.isNotEmpty ? widget.rv.householderName : 'Return Visit Profile'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Contact Profile Card
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
                        backgroundColor: widget.rv.isBibleStudy ? SunlightPalette.highVisGreen : const Color(0xFF0F172A),
                        foregroundColor: widget.rv.isBibleStudy ? Colors.black : Colors.white,
                        child: Icon(widget.rv.isBibleStudy ? Icons.menu_book : Icons.person, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.rv.householderName.isNotEmpty ? widget.rv.householderName : 'Anonymous Contact',
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.rv.isBibleStudy ? 'Active Bible Study' : 'Return Visit',
                              style: TextStyle(
                                color: widget.rv.isBibleStudy ? SunlightPalette.highVisGreen : Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      const Icon(Icons.phone_outlined, size: 18, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(widget.rv.phoneNumber.isNotEmpty ? widget.rv.phoneNumber : 'No phone recorded', style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 18, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text('Preferred call time: ${widget.rv.preferredTime}', style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.language, size: 18, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text('Language: ${widget.rv.language}', style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // "Enjoy Life Forever!" Curriculum Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_stories, color: SunlightPalette.sunlightYellow, size: 22),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          '"Enjoy Life Forever!" Curriculum',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                      Text(
                        'Lesson $_currentLesson of 60',
                        style: const TextStyle(fontWeight: FontWeight.w800, color: SunlightPalette.highVisGreen),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: const Color(0xFF334155),
                      valueColor: const AlwaysStoppedAnimation<Color>(SunlightPalette.highVisGreen),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            enjoyLifeForeverLessons[(_currentLesson - 1).clamp(0, 59)],
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Lesson Adjustment Stepper (>= 48x48dp touch targets)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.remove),
                          label: const Text('Prev Lesson'),
                          onPressed: _currentLesson > 1 ? () => _updateLesson(_currentLesson - 1) : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Next Lesson'),
                          onPressed: _currentLesson < 60 ? () => _updateLesson(_currentLesson + 1) : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Visit Notes
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Visit Notes & Topic Discussed', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 8),
                  Text(
                    widget.rv.notes.isNotEmpty ? widget.rv.notes : 'No previous visit notes recorded.',
                    style: TextStyle(
                      fontSize: 14,
                      fontStyle: widget.rv.notes.isEmpty ? FontStyle.italic : FontStyle.normal,
                      color: widget.rv.notes.isEmpty ? Colors.grey : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Encrypted locally using device Keystore AES-256-GCM. Confidential.',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
