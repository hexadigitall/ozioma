import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/database/database_providers.dart';
import '../core/database/daos/return_visit_dao.dart';

class RVScreen extends ConsumerWidget {
  const RVScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rvDao = ref.watch(returnVisitDaoProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Return Visits & Bible Studies'),
      ),
      body: StreamBuilder<List<ReturnVisitItem>>(
        stream: rvDao.watchReturnVisits(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final returnVisits = snapshot.data ?? [];

          if (returnVisits.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.people_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 12),
                  const Text('No return visits logged yet', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 4),
                  const Text('All householder data is encrypted with local AES-256', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    icon: const Icon(Icons.person_add),
                    label: const Text('Add Return Visit'),
                    onPressed: () => _showAddDialog(context, rvDao),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: returnVisits.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final rv = returnVisits[index];
              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: rv.isBibleStudy ? const Color(0xFF10B981) : Colors.blueGrey,
                    foregroundColor: Colors.white,
                    child: Icon(rv.isBibleStudy ? Icons.menu_book : Icons.person),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          rv.householderName.isNotEmpty ? rv.householderName : 'Anonymous Contact',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (rv.isBibleStudy)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(4)),
                          child: Text(
                            'Lesson ${rv.currentLesson}',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                          ),
                        ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('Call time: ${rv.preferredTime} • Language: ${rv.language}', style: const TextStyle(fontSize: 12)),
                      if (rv.notes.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          rv.notes,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontStyle: FontStyle.italic),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // Profile details
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.person_add),
        label: const Text('New RV'),
        onPressed: () => _showAddDialog(context, rvDao),
      ),
    );
  }

  void _showAddDialog(BuildContext context, ReturnVisitDao dao) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    bool isStudy = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            left: 16,
            right: 16,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add Return Visit / Bible Study', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('Saved locally with AES-256 hardware encryption. Zero-cloud PII.', style: TextStyle(fontSize: 11, color: Colors.grey)),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Householder Name', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesCtrl,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Initial Topic & Question Discussed', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Active Bible Study'),
                subtitle: const Text('Studying "Enjoy Life Forever!" curriculum'),
                value: isStudy,
                onChanged: (val) => setModalState(() => isStudy = val),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    if (nameCtrl.text.trim().isEmpty) return;
                    await dao.createReturnVisit(
                      addressId: 'addr-manual',
                      territoryId: 'territory-manual',
                      householderName: nameCtrl.text.trim(),
                      phoneNumber: phoneCtrl.text.trim(),
                      notes: notesCtrl.text.trim(),
                      isBibleStudy: isStudy,
                    );
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Save Return Visit'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
