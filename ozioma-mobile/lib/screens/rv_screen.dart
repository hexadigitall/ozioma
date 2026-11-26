import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/database/database_providers.dart';
import '../core/database/daos/return_visit_dao.dart';
import '../core/theme/sunlight_palette.dart';
import '../features/return_visits/rv_detail_screen.dart';

class RVScreen extends ConsumerStatefulWidget {
  const RVScreen({super.key});

  @override
  ConsumerState<RVScreen> createState() => _RVScreenState();
}

class _RVScreenState extends ConsumerState<RVScreen> {
  String _searchQuery = '';
  String _filter = 'all'; // 'all', 'studies', 'rvs', 'upcoming'

  @override
  Widget build(BuildContext context) {
    final rvDao = ref.watch(returnVisitDaoProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discipleship & Studies'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1),
            tooltip: 'Add Return Visit or Bible Student',
            onPressed: () => showReturnVisitFormModal(context, rvDao),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search students, languages, addresses...',
                    prefixIcon: const Icon(Icons.search),
                    isDense: true,
                    filled: true,
                    fillColor: isDark ? const Color(0xFF141A24) : const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('all', 'All Contacts', Icons.groups_outlined),
                      const SizedBox(width: 8),
                      _buildFilterChip('studies', 'Bible Studies', Icons.menu_book_outlined),
                      const SizedBox(width: 8),
                      _buildFilterChip('rvs', 'Return Visits', Icons.person_pin_circle_outlined),
                      const SizedBox(width: 8),
                      _buildFilterChip('upcoming', 'Scheduled Next', Icons.event_available),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<ReturnVisitItem>>(
              stream: rvDao.watchReturnVisits(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allContacts = snapshot.data ?? [];
                final filtered = allContacts.where((rv) {
                  if (_filter == 'studies' && !rv.isBibleStudy) return false;
                  if (_filter == 'rvs' && rv.isBibleStudy) return false;
                  if (_filter == 'upcoming' && rv.nextVisitDate.isEmpty) return false;
                  if (_searchQuery.isNotEmpty) {
                    final hay = '${rv.householderName} ${rv.language} ${rv.addressText} ${rv.notes}'.toLowerCase();
                    if (!hay.contains(_searchQuery)) return false;
                  }
                  return true;
                }).toList();

                return StreamBuilder<Map<String, int>>(
                  stream: rvDao.watchMilestoneCountsByStudent(),
                  builder: (context, milestoneSnap) {
                    final milestoneCounts = milestoneSnap.data ?? {};

                    if (filtered.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                allContacts.isEmpty ? Icons.school_outlined : Icons.filter_list_off,
                                size: 64,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 14),
                              Text(
                                allContacts.isEmpty
                                    ? 'Start Tracking Your Return Visits & Bible Students'
                                    : 'No contacts match this filter',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Keep detailed study summaries, student questions, goals, and spiritual milestones — encrypted locally with AES-256-GCM.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              const SizedBox(height: 20),
                              FilledButton.icon(
                                icon: const Icon(Icons.person_add),
                                label: const Text('Add Contact or Student'),
                                onPressed: () => showReturnVisitFormModal(context, rvDao),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final rv = filtered[index];
                        final milestonesReached = milestoneCounts[rv.id] ?? 0;
                        return _buildStudentCard(context, rvDao, rv, milestonesReached);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.person_add),
        label: const Text('New Contact'),
        onPressed: () => showReturnVisitFormModal(context, rvDao),
      ),
    );
  }

  Widget _buildFilterChip(String key, String label, IconData icon) {
    final selected = _filter == key;
    return FilterChip(
      selected: selected,
      avatar: Icon(icon, size: 16),
      label: Text(label),
      onSelected: (_) {
        HapticFeedback.selectionClick();
        setState(() => _filter = key);
      },
    );
  }

  Widget _buildStudentCard(
    BuildContext context,
    ReturnVisitDao dao,
    ReturnVisitItem rv,
    int milestonesReached,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = rv.isBibleStudy ? SunlightPalette.highVisGreen : SunlightPalette.highVisCyan;
    final progress = (rv.currentLesson / 60.0).clamp(0.0, 1.0);

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          HapticFeedback.selectionClick();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => RvDetailScreen(rv: rv)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: accent.withValues(alpha: 0.18),
                    foregroundColor: isDark ? accent : Colors.black87,
                    child: Icon(rv.isBibleStudy ? Icons.menu_book : Icons.person),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rv.householderName.isNotEmpty ? rv.householderName : 'Anonymous Contact',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${rv.language} • ${rv.preferredTime}'
                              '${rv.addressText.isNotEmpty ? ' • ${rv.addressText}' : ''}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'Contact Actions',
                    onSelected: (value) async {
                      if (value == 'edit') {
                        await showReturnVisitFormModal(context, dao, existing: rv);
                      } else if (value == 'delete') {
                        await _confirmDelete(context, dao, rv);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit Profile')),
                      PopupMenuItem(value: 'delete', child: Text('Delete Contact')),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _infoBadge(
                    context,
                    label: rv.isBibleStudy ? 'Bible Study • L${rv.currentLesson}/60' : 'Return Visit',
                    color: accent,
                    icon: rv.isBibleStudy ? Icons.auto_stories : Icons.bookmark_outline,
                  ),
                  if (rv.isBibleStudy)
                    _infoBadge(
                      context,
                      label: '$milestonesReached/8 Milestones',
                      color: SunlightPalette.sunlightYellow,
                      icon: Icons.emoji_events_outlined,
                    ),
                  if (rv.nextVisitDate.isNotEmpty)
                    _infoBadge(
                      context,
                      label: 'Next: ${rv.nextVisitDate}',
                      color: Colors.blueAccent,
                      icon: Icons.event,
                    ),
                ],
              ),
              if (rv.isBibleStudy) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: isDark ? Colors.white12 : Colors.black12,
                    valueColor: AlwaysStoppedAnimation<Color>(accent),
                  ),
                ),
              ],
              if (rv.goal.isNotEmpty || rv.notes.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  rv.goal.isNotEmpty ? 'Goal: ${rv.goal}' : rv.notes,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoBadge(
    BuildContext context, {
    required String label,
    required Color color,
    required IconData icon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.16 : 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: isDark ? color : Colors.black87),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isDark ? color : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, ReturnVisitDao dao, ReturnVisitItem rv) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Contact?'),
        content: Text(
          'Delete "${rv.householderName}" along with local study sessions, questions, and milestones?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: SunlightPalette.highVisRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await dao.deleteReturnVisit(rv.id);
    }
  }
}

/// Reusable modal form for creating or editing a Return Visit / Bible Student.
Future<void> showReturnVisitFormModal(
  BuildContext context,
  ReturnVisitDao dao, {
  ReturnVisitItem? existing,
}) async {
  final nameCtrl = TextEditingController(text: existing?.householderName ?? '');
  final phoneCtrl = TextEditingController(text: existing?.phoneNumber ?? '');
  final addrCtrl = TextEditingController(text: existing?.addressText ?? '');
  final prefCtrl = TextEditingController(text: existing?.preferredTime ?? 'Saturday Mornings');
  final langCtrl = TextEditingController(text: existing?.language ?? 'English');
  final goalCtrl = TextEditingController(text: existing?.goal ?? '');
  final notesCtrl = TextEditingController(text: existing?.notes ?? '');
  String publication = existing?.studyPublication ?? 'Enjoy Life Forever! Book';
  int currentLesson = existing?.currentLesson.clamp(1, 60) ?? 1;
  bool isStudy = existing?.isBibleStudy ?? false;
  String nextVisit = existing?.nextVisitDate ?? '';

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
                Expanded(
                  child: Text(
                    existing == null ? 'New Return Visit / Bible Student' : 'Edit Contact Profile',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const Text(
              'Zero-Cloud PII: Personal details stay encrypted locally via AES-256.',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Name *',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: Icon(Icons.phone_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: langCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Language',
                      prefixIcon: Icon(Icons.language),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: addrCtrl,
              decoration: const InputDecoration(
                labelText: 'Street Address / Landmark Directions',
                prefixIcon: Icon(Icons.location_on_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: prefCtrl,
              decoration: const InputDecoration(
                labelText: 'Preferred Contact Day & Time',
                prefixIcon: Icon(Icons.schedule),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.event),
              label: Text(
                nextVisit.isEmpty ? 'Schedule Next Visit / Study Date' : 'Next Visit: $nextVisit',
              ),
              onPressed: () async {
                final pickedDate = await showDatePicker(
                  context: ctx,
                  initialDate: DateTime.now().add(const Duration(days: 3)),
                  firstDate: DateTime.now().subtract(const Duration(days: 1)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (pickedDate != null && ctx.mounted) {
                  final pickedTime = await showTimePicker(
                    context: ctx,
                    initialTime: const TimeOfDay(hour: 10, minute: 0),
                  );
                  final formattedDate = DateFormat('yyyy-MM-dd').format(pickedDate);
                  final formattedTime = pickedTime != null
                      ? '${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}'
                      : '10:00';
                  setModalState(() => nextVisit = '$formattedDate $formattedTime');
                }
              },
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Active Bible Study', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Track lessons, study sessions, and discipleship milestones'),
              value: isStudy,
              onChanged: (val) => setModalState(() => isStudy = val),
            ),
            if (isStudy) ...[
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: publication,
                decoration: const InputDecoration(
                  labelText: 'Study Publication',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'Enjoy Life Forever! Book', child: Text('Enjoy Life Forever! Book (60 Lessons)')),
                  DropdownMenuItem(value: 'Enjoy Life Forever! Brochure', child: Text('Enjoy Life Forever! Brochure (3 Lessons)')),
                  DropdownMenuItem(value: 'Bible Stories / Family', child: Text('Learn From Bible Stories / Family')),
                  DropdownMenuItem(value: 'Custom Study Reference', child: Text('Custom Topic / Scriptural Study')),
                ],
                onChanged: (val) {
                  if (val != null) setModalState(() => publication = val);
                },
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Text('Current Lesson:', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Slider(
                      value: currentLesson.toDouble(),
                      min: 1,
                      max: 60,
                      divisions: 59,
                      label: 'Lesson $currentLesson',
                      onChanged: (v) => setModalState(() => currentLesson = v.round()),
                    ),
                  ),
                  Text('L$currentLesson', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ],
            const SizedBox(height: 8),
            TextField(
              controller: goalCtrl,
              decoration: const InputDecoration(
                labelText: 'Current Discipleship Goal (for student)',
                hintText: 'e.g. Read Lesson 4 & invite to Sunday meeting',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Personal Notes & Background',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.save),
                label: Text(existing == null ? 'Save Contact' : 'Update Contact'),
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty) return;
                  HapticFeedback.lightImpact();
                  if (existing == null) {
                    await dao.createReturnVisit(
                      addressId: 'addr-manual',
                      territoryId: 'territory-manual',
                      householderName: nameCtrl.text.trim(),
                      phoneNumber: phoneCtrl.text.trim(),
                      addressText: addrCtrl.text.trim(),
                      preferredTime: prefCtrl.text.trim().isEmpty ? 'Any time' : prefCtrl.text.trim(),
                      language: langCtrl.text.trim().isEmpty ? 'English' : langCtrl.text.trim(),
                      studyPublication: publication,
                      currentLesson: currentLesson,
                      isBibleStudy: isStudy,
                      notes: notesCtrl.text.trim(),
                      goal: goalCtrl.text.trim(),
                      nextVisitDate: nextVisit,
                    );
                  } else {
                    await dao.updateReturnVisit(
                      id: existing.id,
                      householderName: nameCtrl.text.trim(),
                      phoneNumber: phoneCtrl.text.trim(),
                      addressText: addrCtrl.text.trim(),
                      preferredTime: prefCtrl.text.trim().isEmpty ? 'Any time' : prefCtrl.text.trim(),
                      language: langCtrl.text.trim().isEmpty ? 'English' : langCtrl.text.trim(),
                      studyPublication: publication,
                      currentLesson: currentLesson,
                      isBibleStudy: isStudy,
                      notes: notesCtrl.text.trim(),
                      goal: goalCtrl.text.trim(),
                      nextVisitDate: nextVisit,
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
