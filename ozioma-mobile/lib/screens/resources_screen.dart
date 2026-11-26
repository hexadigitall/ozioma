import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/database/daos/ministry_planner_dao.dart';
import '../core/database/database_providers.dart';
import '../core/theme/sunlight_palette.dart';
import '../core/theme/theme_provider.dart';
import 'timer_screen.dart';

/// Field Toolkit & Congregation Expansion Hub (3 Tabs):
/// 1. Presentations & Personal Field Notes (Full CRUD)
/// 2. Biblical References & Objection Handling (Searchable Reasoning Library)
/// 3. Congregation Care & Expansion (Elderly, Special Needs, Seldom-Worked, Need-Greater)
class ResourcesScreen extends ConsumerStatefulWidget {
  final int initialTabIndex;

  const ResourcesScreen({super.key, this.initialTabIndex = 0});

  @override
  ConsumerState<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends ConsumerState<ResourcesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _refSearch = '';

  static const List<Map<String, String>> _objectionReferences = [
    {
      'topic': 'I am busy right now',
      'scripture': 'Proverbs 15:23; Matthew 5:3',
      'response': 'Acknowledge graciously: "I completely understand, everyone\'s schedule is full. In just 30 seconds, could I leave you with a comforting thought from the Bible on coping with stress?" Leave a concise tract or link.',
    },
    {
      'topic': 'I already have my own religion',
      'scripture': 'Romans 12:18; Acts 17:11',
      'response': '"That shows you value spiritual things. We visit neighbors of all faiths because Jesus encouraged examining the Scriptures personally. Have you ever wondered why the Bible says in Psalm 37:29 that the righteous will live forever on the earth?"',
    },
    {
      'topic': 'Why does God allow suffering?',
      'scripture': 'James 1:13; Job 34:10; Revelation 21:3, 4',
      'response': '"God never causes evil. Look at James 1:13 — God cannot be tried with evil things, nor does He try anyone. Soon, as Revelation 21:4 promises, He will wipe out every tear and end pain forever."',
    },
    {
      'topic': 'What happens when a person dies?',
      'scripture': 'Ecclesiastes 9:5, 10; John 11:11-14; John 5:28, 29',
      'response': '"Jesus compared death to peaceful sleep (John 11:11). The dead feel no pain (Ecclesiastes 9:5), and God promises a resurrection back to life on a peaceful earth (John 5:28, 29)."',
    },
    {
      'topic': 'Are Jehovah\'s Witnesses Christians?',
      'scripture': '1 Peter 2:21; John 14:6; Matthew 16:16',
      'response': '"Yes — we follow Jesus Christ closely as our King, Savior, and Teacher (1 Peter 2:21). Because Jesus himself taught us to worship his Father Jehovah (John 17:3), we strive to honor both."',
    },
    {
      'topic': 'Why don\'t you celebrate birthdays or Christmas?',
      'scripture': 'John 17:16; 2 Corinthians 6:17; Ecclesiastes 7:1',
      'response': '"We love giving gifts and spending joyful time with family year-round! When choosing religious observances, we follow what Jesus and the first-century Christians actually practiced and taught."',
    },
    {
      'topic': 'Why do you preach from house to house?',
      'scripture': 'Acts 5:42; Acts 20:20; Luke 8:1',
      'response': '"We follow the example Jesus set and what the apostles practiced in Acts 20:20 — teaching publicly and from house to house so every neighbor has a fair chance to hear God\'s Kingdom message."',
    },
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
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final isSunlightDark = themeMode == AppThemeMode.sunlightDark;
    final plannerDao = ref.watch(ministryPlannerDaoProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ministry Toolkit & Care'),
        actions: [
          IconButton(
            icon: Icon(isSunlightDark ? Icons.light_mode : Icons.dark_mode),
            tooltip: 'Toggle Sunlight Contrast',
            onPressed: () {
              HapticFeedback.lightImpact();
              ref.read(themeProvider.notifier).toggleSunlightMode();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(icon: Icon(Icons.edit_note, size: 18), text: 'Presentations & Notes'),
            Tab(icon: Icon(Icons.library_books_outlined, size: 18), text: 'References & Qs'),
            Tab(icon: Icon(Icons.volunteer_activism_outlined, size: 18), text: 'Care & Expansion'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPresentationsTab(context, plannerDao, isSunlightDark),
          _buildReferencesTab(context),
          _buildCongregationCareTab(context, plannerDao, isSunlightDark),
        ],
      ),
    );
  }

  // =========================================================================
  // TAB 1: PRESENTATIONS & FIELD NOTES CRUD
  // =========================================================================

  Widget _buildPresentationsTab(BuildContext context, MinistryPlannerDao plannerDao, bool isSunlightDark) {
    return StreamBuilder<List<MinistryNoteItem>>(
      stream: plannerDao.watchNotes(),
      builder: (context, snapshot) {
        final notes = (snapshot.data ?? [])
            .where((n) => n.noteType == 'presentation' || n.noteType == 'field_note')
            .toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('New Presentation'),
                    onPressed: () => _showNoteModal(context, plannerDao, defaultType: 'presentation'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.note_add_outlined),
                    label: const Text('Field Note'),
                    onPressed: () => _showNoteModal(context, plannerDao, defaultType: 'field_note'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (notes.isNotEmpty) ...[
              const Text('My Saved Presentations & Notes', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              ...notes.map(
                (n) => Padding(
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
                              Icon(
                                n.noteType == 'presentation' ? Icons.record_voice_over_outlined : Icons.sticky_note_2_outlined,
                                size: 18,
                                color: SunlightPalette.highVisGreen,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(n.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                              ),
                              if (n.isPinned)
                                const Icon(Icons.push_pin, size: 16, color: SunlightPalette.sunlightYellow),
                              PopupMenuButton<String>(
                                onSelected: (val) async {
                                  if (val == 'pin') {
                                    await plannerDao.updateNote(
                                      id: n.id,
                                      noteType: n.noteType,
                                      title: n.title,
                                      scripture: n.scripture,
                                      initialQuestion: n.initialQuestion,
                                      talkingPoints: n.talkingPoints,
                                      linkingQuestion: n.linkingQuestion,
                                      category: n.category,
                                      isPinned: !n.isPinned,
                                    );
                                  } else if (val == 'edit') {
                                    await _showNoteModal(context, plannerDao, existing: n);
                                  } else if (val == 'delete') {
                                    await plannerDao.deleteNote(n.id);
                                  }
                                },
                                itemBuilder: (_) => [
                                  PopupMenuItem(value: 'pin', child: Text(n.isPinned ? 'Unpin' : 'Pin to Top')),
                                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                                ],
                              ),
                            ],
                          ),
                          if (n.initialQuestion.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text('Question: ${n.initialQuestion}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          ],
                          if (n.scripture.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text('Scripture: ${n.scripture}', style: const TextStyle(color: SunlightPalette.highVisCyan, fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                          if (n.talkingPoints.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(n.talkingPoints, style: const TextStyle(fontSize: 13)),
                          ],
                          if (n.linkingQuestion.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text('Next Visit Link: ${n.linkingQuestion}', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey)),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            const Text('Sample Conversation Templates', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            _buildPresentationCard(
              context,
              title: 'Initial Call — Hope in Difficult Times',
              scripture: 'Jeremiah 29:11',
              scriptureText: 'For I well know the thoughts that I am thinking toward you, declares Jehovah, thoughts of peace, and not of calamity, to give you a future and a hope.',
              question: 'What kind of future do you hope to see for your family?',
              nextTopic: 'Next visit: Enjoy Life Forever! Lesson 02',
            ),
            const SizedBox(height: 10),
            _buildPresentationCard(
              context,
              title: 'Return Visit — Peaceful Earth Under God\'s Kingdom',
              scripture: 'Psalm 37:10, 11',
              scriptureText: 'Just a little while longer, and the wicked will be no more... But the meek will possess the earth, and they will find exquisite delight in the abundance of peace.',
              question: 'Why can we trust that this change will truly take place?',
              nextTopic: 'Bible Study Launch: Lesson 01 — How Can the Bible Help You?',
            ),
            const SizedBox(height: 10),
            _buildPresentationCard(
              context,
              title: 'Informal / Cart — Knowing God Personally',
              scripture: 'John 17:3',
              scriptureText: 'This means everlasting life, their coming to know you, the only true God, and the one whom you sent, Jesus Christ.',
              question: 'How does getting to know God help us right now?',
              nextTopic: 'Offer Enjoy Life Forever! brochure or jw.org video',
            ),
          ],
        );
      },
    );
  }

  // =========================================================================
  // TAB 2: BIBLICAL REFERENCES & OBJECTION HANDLER
  // =========================================================================

  Widget _buildReferencesTab(BuildContext context) {
    final filtered = _objectionReferences.where((item) {
      if (_refSearch.isEmpty) return true;
      return '${item['topic']} ${item['scripture']} ${item['response']}'
          .toLowerCase()
          .contains(_refSearch);
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          decoration: const InputDecoration(
            hintText: 'Search questions, objections, or scriptures...',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (v) => setState(() => _refSearch = v.trim().toLowerCase()),
        ),
        const SizedBox(height: 14),
        ...filtered.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Card(
              margin: EdgeInsets.zero,
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                leading: const Icon(Icons.menu_book, color: SunlightPalette.sunlightYellow),
                title: Text(item['topic']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text(
                  item['scripture']!,
                  style: const TextStyle(fontSize: 12, color: SunlightPalette.highVisCyan, fontWeight: FontWeight.w600),
                ),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(item['response']!, style: const TextStyle(fontSize: 13, height: 1.45)),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Copy Reference'),
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(text: '${item['topic']} (${item['scripture']})\n${item['response']}'),
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Copied reference to clipboard')),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // TAB 3: CONGREGATION SUPPORT, ELDERLY, SPECIAL NEEDS & EXPANDING MINISTRY
  // =========================================================================

  Widget _buildCongregationCareTab(
    BuildContext context,
    MinistryPlannerDao plannerDao,
    bool isSunlightDark,
  ) {
    return StreamBuilder<List<MinistryNoteItem>>(
      stream: plannerDao.watchNotes(),
      builder: (context, snapshot) {
        final careNotes = (snapshot.data ?? [])
            .where(
              (n) =>
                  n.noteType == 'elderly_care' ||
                  n.noteType == 'special_needs' ||
                  n.noteType == 'seldom_worked' ||
                  n.noteType == 'need_greater',
            )
            .toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Direct Action Cards for Congregation Support
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Supporting the Congregation & Special Initiatives',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Plan thoughtful support for elderly & special-needs brothers/sisters, seldom-worked territory trips, and ministry expansion.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ActionChip(
                          avatar: const Icon(Icons.elderly, size: 16),
                          label: const Text('+ Schedule Elderly Ride/Visit'),
                          onPressed: () => showAppointmentFormModal(
                            context,
                            plannerDao,
                            initialFocus: 'elderly_care',
                          ),
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.explore, size: 16),
                          label: const Text('+ Plan Seldom-Worked Trip'),
                          onPressed: () => showAppointmentFormModal(
                            context,
                            plannerDao,
                            initialFocus: 'seldom_worked',
                          ),
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.flight_takeoff, size: 16),
                          label: const Text('+ Need-Greater / Language Goal'),
                          onPressed: () => _showNoteModal(context, plannerDao, defaultType: 'need_greater'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Care & Expansion Logs', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add Initiative'),
                  onPressed: () => _showNoteModal(context, plannerDao, defaultType: 'elderly_care'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (careNotes.isEmpty)
              const Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'Track notes for working with elderly publishers (flat streets, rides, letter writing), special needs arrangements, rural seldom-worked campaigns, or moving/assisting where the need is greater.',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ),
              )
            else
              ...careNotes.map(
                (n) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    margin: EdgeInsets.zero,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: SunlightPalette.highVisCyan.withValues(alpha: 0.16),
                        child: Icon(_iconForCareType(n.noteType), color: SunlightPalette.highVisCyan),
                      ),
                      title: Text(n.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        '${_labelForCareType(n.noteType)}${n.talkingPoints.isNotEmpty ? '\n${n.talkingPoints}' : ''}',
                      ),
                      isThreeLine: n.talkingPoints.isNotEmpty,
                      trailing: PopupMenuButton<String>(
                        onSelected: (v) async {
                          if (v == 'edit') {
                            await _showNoteModal(context, plannerDao, existing: n);
                          } else if (v == 'delete') {
                            await plannerDao.deleteNote(n.id);
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'edit', child: Text('Edit')),
                          PopupMenuItem(value: 'delete', child: Text('Delete')),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 16),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isSunlightDark ? Icons.wb_sunny : Icons.shield,
                          color: isSunlightDark ? SunlightPalette.sunlightYellow : SunlightPalette.highVisGreen,
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text('Zero-Cloud PII & Sunlight Mode Active', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'All personal student records, partner appointments, care notes, and goals remain encrypted locally via device Keystore AES-256-GCM.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  IconData _iconForCareType(String t) {
    switch (t) {
      case 'elderly_care':
        return Icons.elderly;
      case 'special_needs':
        return Icons.accessible_forward;
      case 'seldom_worked':
        return Icons.explore;
      case 'need_greater':
        return Icons.flight_takeoff;
      default:
        return Icons.volunteer_activism;
    }
  }

  String _labelForCareType(String t) {
    switch (t) {
      case 'elderly_care':
        return 'Elderly Publisher Support';
      case 'special_needs':
        return 'Special Needs Care';
      case 'seldom_worked':
        return 'Seldom-Worked Territory Campaign';
      case 'need_greater':
        return 'Expanding Ministry / Need Greater';
      default:
        return 'Congregation Care';
    }
  }

  Future<void> _showNoteModal(
    BuildContext context,
    MinistryPlannerDao dao, {
    MinistryNoteItem? existing,
    String defaultType = 'presentation',
  }) async {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final qCtrl = TextEditingController(text: existing?.initialQuestion ?? '');
    final scripCtrl = TextEditingController(text: existing?.scripture ?? '');
    final bodyCtrl = TextEditingController(text: existing?.talkingPoints ?? '');
    final linkCtrl = TextEditingController(text: existing?.linkingQuestion ?? '');
    String type = existing?.noteType ?? defaultType;
    bool pinned = existing?.isPinned ?? false;

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
                existing == null ? 'Create Presentation / Ministry Note' : 'Edit Item',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: type,
                decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'presentation', child: Text('Ministry Presentation')),
                  DropdownMenuItem(value: 'field_note', child: Text('Personal Field / Meeting Note')),
                  DropdownMenuItem(value: 'elderly_care', child: Text('Elderly Publisher Support Plan')),
                  DropdownMenuItem(value: 'special_needs', child: Text('Special Needs Support')),
                  DropdownMenuItem(value: 'seldom_worked', child: Text('Seldom-Worked Territory Plan')),
                  DropdownMenuItem(value: 'need_greater', child: Text('Where Need Is Greater / Language')),
                ],
                onChanged: (v) {
                  if (v != null) setModalState(() => type = v);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Title *', border: OutlineInputBorder()),
              ),
              if (type == 'presentation') ...[
                const SizedBox(height: 12),
                TextField(
                  controller: qCtrl,
                  decoration: const InputDecoration(labelText: 'Initial Question / Hook', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: scripCtrl,
                  decoration: const InputDecoration(labelText: 'Key Scripture', border: OutlineInputBorder()),
                ),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: bodyCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Talking Points / Practical Plan Details',
                  border: OutlineInputBorder(),
                ),
              ),
              if (type == 'presentation') ...[
                const SizedBox(height: 12),
                TextField(
                  controller: linkCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Linking Question for Return Visit',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Pin to Top'),
                value: pinned,
                onChanged: (v) => setModalState(() => pinned = v),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Save'),
                  onPressed: () async {
                    if (titleCtrl.text.trim().isEmpty) return;
                    HapticFeedback.lightImpact();
                    if (existing == null) {
                      await dao.createNote(
                        noteType: type,
                        title: titleCtrl.text.trim(),
                        initialQuestion: qCtrl.text.trim(),
                        scripture: scripCtrl.text.trim(),
                        talkingPoints: bodyCtrl.text.trim(),
                        linkingQuestion: linkCtrl.text.trim(),
                        isPinned: pinned,
                      );
                    } else {
                      await dao.updateNote(
                        id: existing.id,
                        noteType: type,
                        title: titleCtrl.text.trim(),
                        initialQuestion: qCtrl.text.trim(),
                        scripture: scripCtrl.text.trim(),
                        talkingPoints: bodyCtrl.text.trim(),
                        linkingQuestion: linkCtrl.text.trim(),
                        category: existing.category,
                        isPinned: pinned,
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

  Widget _buildPresentationCard(
    BuildContext context, {
    required String title,
    required String scripture,
    required String scriptureText,
    required String question,
    required String nextTopic,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF1A2230)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(scripture, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0284C7))),
                  const SizedBox(height: 4),
                  Text('"$scriptureText"', style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text('Question: $question', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(nextTopic, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
