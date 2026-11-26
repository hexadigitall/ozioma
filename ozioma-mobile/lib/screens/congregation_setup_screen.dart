import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../core/database/daos/congregation_dao.dart';
import '../core/database/database_providers.dart';
import '../core/theme/sunlight_palette.dart';

/// Real Setup, Access/Role Management, Congregation Registration,
/// Publisher Privilege Assignment, & Congregation S-4 Rollup Workspace.
class CongregationSetupScreen extends ConsumerStatefulWidget {
  final int initialTabIndex;

  const CongregationSetupScreen({super.key, this.initialTabIndex = 0});

  @override
  ConsumerState<CongregationSetupScreen> createState() => _CongregationSetupScreenState();
}

class _CongregationSetupScreenState extends ConsumerState<CongregationSetupScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _roleFilter = 'all';

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
    final congDao = ref.watch(congregationDaoProvider);
    final currentMonthKey = DateFormat('yyyy-MM').format(DateTime.now());

    return StreamBuilder<ActiveSessionState?>(
      stream: congDao.watchActiveSession(),
      builder: (context, sessionSnap) {
        final session = sessionSnap.data;

        return StreamBuilder<PublisherProfileItem?>(
          stream: congDao.watchActivePublisher(),
          builder: (context, activePubSnap) {
            final activePub = activePubSnap.data;
            final activeRole = activePub?.role ?? 'elder';
            final activeCongId = activePub?.congregationId.isNotEmpty == true
                ? activePub!.congregationId
                : (session?.activeCongregationId ?? '');

            return Scaffold(
              appBar: AppBar(
                title: const Text('Congregation & Role Setup'),
                bottom: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  tabs: const [
                    Tab(icon: Icon(Icons.account_balance_outlined, size: 18), text: 'Congregations & Me'),
                    Tab(icon: Icon(Icons.admin_panel_settings_outlined, size: 18), text: 'Publishers & Roles'),
                    Tab(icon: Icon(Icons.summarize_outlined, size: 18), text: 'S-4 Rollups'),
                  ],
                ),
              ),
              body: TabBarView(
                controller: _tabController,
                children: [
                  _buildSetupAndCongregationsTab(context, congDao, activePub, activeCongId),
                  _buildPublishersAndRolesTab(context, congDao, activePub, activeRole, activeCongId),
                  _buildCongregationReportsTab(context, congDao, activePub, activeRole, activeCongId, currentMonthKey),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // =========================================================================
  // TAB 1: ACTIVE PROFILE, ROLE ACCESS & CONGREGATION CRUD
  // =========================================================================

  Widget _buildSetupAndCongregationsTab(
    BuildContext context,
    CongregationDao congDao,
    PublisherProfileItem? activePub,
    String activeCongId,
  ) {
    return StreamBuilder<List<CongregationItem>>(
      stream: congDao.watchCongregations(),
      builder: (context, congSnap) {
        final congregations = congSnap.data ?? [];
        CongregationItem? currentCong;
        for (final c in congregations) {
          if (c.id == activeCongId) {
            currentCong = c;
            break;
          }
        }
        currentCong ??= congregations.isNotEmpty ? congregations.first : null;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Active Device Profile & Permissions Card
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: SunlightPalette.highVisGreen.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Image.asset(
                            'assets/images/logo_mark.png',
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(Icons.person, color: SunlightPalette.highVisGreen),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                activePub?.displayName ?? 'No Active Publisher Selected',
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                              ),
                              Text(
                                activePub != null
                                    ? '${TheocraticRolePermissions.label(activePub.role)} • ${activePub.serviceGroup}'
                                    : 'Register a congregation & create your profile below',
                                style: const TextStyle(fontSize: 12, color: SunlightPalette.highVisGreen, fontWeight: FontWeight.w600),
                              ),
                              if (currentCong != null)
                                Text(
                                  '${currentCong.name}${currentCong.circuit.isNotEmpty ? ' (${currentCong.circuit})' : ''}',
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (activePub != null) ...[
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _permChip('Congregation Admin', TheocraticRolePermissions.canManageCongregation(activePub.role)),
                          _permChip('Assign Roles', TheocraticRolePermissions.canManagePublishers(activePub.role)),
                          _permChip('Map & Assign Territories', TheocraticRolePermissions.canManageTerritories(activePub.role)),
                          _permChip('Chat & Pins', true),
                        ],
                      ),
                    ] else
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          icon: const Icon(Icons.rocket_launch_outlined),
                          label: const Text('Run Quick Congregation & Profile Setup'),
                          onPressed: () => _showCongregationWizardModal(context, congDao),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Registered Congregations (${congregations.length})',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.add_business),
                  label: const Text('Register'),
                  onPressed: () => _showCongregationFormModal(context, congDao),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (congregations.isEmpty)
              const Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'No congregations registered yet. Register your congregation to unlock territory assignment, live map sync, publisher roster, and group chat.',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ),
              )
            else
              ...congregations.map(
                (c) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    margin: EdgeInsets.zero,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: c.id == activeCongId
                            ? SunlightPalette.highVisGreen.withValues(alpha: 0.2)
                            : Colors.blueGrey.withValues(alpha: 0.2),
                        child: Icon(
                          Icons.location_city,
                          color: c.id == activeCongId ? SunlightPalette.highVisGreen : Colors.grey,
                        ),
                      ),
                      title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        '${c.circuit.isNotEmpty ? c.circuit : 'Circuit TBD'} • ${c.countryCode}'
                        '${c.kingdomHallAddress.isNotEmpty ? '\n${c.kingdomHallAddress}' : ''}'
                        '${c.meetingSchedule.isNotEmpty ? '\n${c.meetingSchedule}' : ''}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      isThreeLine: c.kingdomHallAddress.isNotEmpty || c.meetingSchedule.isNotEmpty,
                      trailing: PopupMenuButton<String>(
                        onSelected: (v) async {
                          if (v == 'activate') {
                            await congDao.setActiveSession(
                              publisherId: activePub?.id ?? '',
                              congregationId: c.id,
                            );
                          } else if (v == 'edit') {
                            await _showCongregationFormModal(context, congDao, existing: c);
                          } else if (v == 'delete') {
                            await _confirmDeleteCongregation(context, congDao, c);
                          }
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(value: 'activate', child: Text('Set as Active Congregation')),
                          const PopupMenuItem(value: 'edit', child: Text('Edit Details')),
                          const PopupMenuItem(value: 'delete', child: Text('Delete Congregation')),
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

  Widget _permChip(String label, bool allowed) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: allowed ? SunlightPalette.highVisGreen.withValues(alpha: 0.16) : Colors.grey.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            allowed ? Icons.check_circle : Icons.lock_outline,
            size: 13,
            color: allowed ? SunlightPalette.highVisGreen : Colors.grey,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: allowed ? SunlightPalette.highVisGreen : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // TAB 2: PUBLISHERS ROSTER & PRIVILEGE / ROLE ASSIGNMENT CRUD
  // =========================================================================

  Widget _buildPublishersAndRolesTab(
    BuildContext context,
    CongregationDao congDao,
    PublisherProfileItem? activePub,
    String activeRole,
    String activeCongId,
  ) {
    final canManageRoles = activePub == null || TheocraticRolePermissions.canManagePublishers(activeRole);

    return StreamBuilder<List<PublisherProfileItem>>(
      stream: congDao.watchPublishers(congregationId: activeCongId),
      builder: (context, snapshot) {
        final all = snapshot.data ?? [];
        final filtered = _roleFilter == 'all'
            ? all
            : all.where((p) => p.role == _roleFilter).toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.person_add_alt_1),
                    label: const Text('Add Publisher Profile'),
                    onPressed: activeCongId.isEmpty
                        ? () => _showCongregationWizardModal(context, congDao)
                        : () => _showPublisherFormModal(context, congDao, activeCongId),
                  ),
                ),
              ],
            ),
            if (!canManageRoles)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Read-only access for role assignments (switch to an Elder profile to modify congregation privileges).',
                  style: TextStyle(fontSize: 11, color: SunlightPalette.sunlightYellow),
                ),
              ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _roleFilterChip('all', 'All (${all.length})'),
                  const SizedBox(width: 6),
                  _roleFilterChip('elder', 'Elders'),
                  const SizedBox(width: 6),
                  _roleFilterChip('servant', 'Servants'),
                  const SizedBox(width: 6),
                  _roleFilterChip('regular_pioneer', 'Reg. Pioneers'),
                  const SizedBox(width: 6),
                  _roleFilterChip('auxiliary_pioneer', 'Aux. Pioneers'),
                  const SizedBox(width: 6),
                  _roleFilterChip('publisher', 'Publishers'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (filtered.isEmpty)
              const Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'No publisher profiles in this filter yet. Create profiles for publishers, pioneers, servants, and elders.',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ),
              )
            else
              ...filtered.map((p) {
                final isMe = activePub?.id == p.id;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Card(
                    margin: EdgeInsets.zero,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isMe
                            ? SunlightPalette.sunlightYellow
                            : SunlightPalette.highVisCyan.withValues(alpha: 0.18),
                        foregroundColor: isMe ? Colors.black : SunlightPalette.highVisCyan,
                        child: Text(
                          p.displayName.isNotEmpty ? p.displayName[0].toUpperCase() : 'P',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(p.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          if (isMe)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: SunlightPalette.sunlightYellow,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'ACTIVE',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.black),
                              ),
                            ),
                        ],
                      ),
                      subtitle: Text(
                        '${TheocraticRolePermissions.label(p.role)} • ${p.serviceGroup} • ${p.isActive ? 'Active' : 'Inactive'}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (val) async {
                          if (val == 'switch') {
                            HapticFeedback.selectionClick();
                            await congDao.setActiveSession(
                              publisherId: p.id,
                              congregationId: p.congregationId,
                            );
                          } else if (val == 'privilege' && canManageRoles) {
                            await _showPrivilegeDialog(context, congDao, p);
                          } else if (val == 'edit' && (canManageRoles || isMe)) {
                            await _showPublisherFormModal(context, congDao, activeCongId, existing: p);
                          } else if (val == 'delete' && canManageRoles) {
                            await congDao.deletePublisher(p.id);
                          }
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(value: 'switch', child: Text('Use This Profile')),
                          if (canManageRoles)
                            const PopupMenuItem(value: 'privilege', child: Text('Assign Privilege / Role')),
                          if (canManageRoles || isMe)
                            const PopupMenuItem(value: 'edit', child: Text('Edit Details')),
                          if (canManageRoles)
                            const PopupMenuItem(value: 'delete', child: Text('Remove Publisher')),
                        ],
                      ),
                    ),
                  ),
                );
              }),
          ],
        );
      },
    );
  }

  Widget _roleFilterChip(String role, String label) {
    return FilterChip(
      selected: _roleFilter == role,
      label: Text(label),
      onSelected: (_) => setState(() => _roleFilter = role),
    );
  }

  // =========================================================================
  // TAB 3: CONGREGATION MONTHLY FIELD SERVICE REPORTS ROLLUP (S-4)
  // =========================================================================

  Widget _buildCongregationReportsTab(
    BuildContext context,
    CongregationDao congDao,
    PublisherProfileItem? activePub,
    String activeRole,
    String activeCongId,
    String yearMonth,
  ) {
    final isOversight = activePub == null || TheocraticRolePermissions.canViewCongregationReports(activeRole);

    return StreamBuilder<List<CongregationReportItem>>(
      stream: congDao.watchCongregationReports(activeCongId, yearMonth),
      builder: (context, snapshot) {
        final reports = snapshot.data ?? [];
        final totalHours = reports.fold<double>(0.0, (s, r) => s + r.hours);
        final totalStudies = reports.fold<int>(0, (s, r) => s + r.bibleStudies);
        final activePublishers = reports.where((r) => r.participated).length;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Congregation Reports — $yearMonth',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                        ),
                        IconButton(
                          icon: const Icon(Icons.share),
                          tooltip: 'Export Monthly Congregation Summary',
                          onPressed: reports.isEmpty
                              ? null
                              : () {
                                  final text = 'Congregation Field Service Rollup ($yearMonth)\n'
                                      'Participating Publishers: $activePublishers\n'
                                      'Total Hours: ${totalHours.toStringAsFixed(1)}\n'
                                      'Total Bible Studies: $totalStudies';
                                  Share.share(text, subject: 'Congregation S-4 Rollup $yearMonth');
                                },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _rollupStat('$activePublishers', 'Reported')),
                        Expanded(child: _rollupStat(totalHours.toStringAsFixed(1), 'Total Hrs')),
                        Expanded(child: _rollupStat('$totalStudies', 'Studies')),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              icon: const Icon(Icons.note_add_outlined),
              label: const Text('Submit / Record Publisher S-4 Report'),
              onPressed: activeCongId.isEmpty
                  ? () => _showCongregationWizardModal(context, congDao)
                  : () => _showCongregationReportModal(context, congDao, activeCongId, yearMonth, activePub),
            ),
            const SizedBox(height: 12),
            if (!isOversight)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  'Viewing your congregation submission board. Secretary & Elders can edit or delete any entry.',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ),
            if (reports.isEmpty)
              const Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'No S-4 reports recorded for this congregation month yet.',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ),
              )
            else
              ...reports.map(
                (r) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Card(
                    margin: EdgeInsets.zero,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: r.participated
                            ? SunlightPalette.highVisGreen.withValues(alpha: 0.18)
                            : Colors.grey.withValues(alpha: 0.2),
                        child: Icon(
                          r.participated ? Icons.check : Icons.remove,
                          color: r.participated ? SunlightPalette.highVisGreen : Colors.grey,
                        ),
                      ),
                      title: Text(r.publisherName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        '${TheocraticRolePermissions.label(r.publisherRole)} • ${r.hours.toStringAsFixed(1)} hrs'
                        '${r.creditHours > 0 ? ' (+${r.creditHours.toStringAsFixed(1)} credit)' : ''}'
                        ' • ${r.bibleStudies} studies',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: isOversight || r.publisherId == activePub.id
                          ? IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                              onPressed: () => congDao.deleteCongregationReport(r.id),
                            )
                          : null,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _rollupStat(String value, String label) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: SunlightPalette.highVisCyan.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: SunlightPalette.highVisCyan)),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }

  // =========================================================================
  // MODALS (CONGREGATION, SETUP WIZARD, PUBLISHER, PRIVILEGE, S-4)
  // =========================================================================

  Future<void> _showCongregationWizardModal(BuildContext context, CongregationDao dao) async {
    final congNameCtrl = TextEditingController();
    final circuitCtrl = TextEditingController();
    final countryCtrl = TextEditingController(text: 'NG');
    final pubNameCtrl = TextEditingController();
    String role = 'elder';
    String group = 'Group 1';

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
              const Text('Register Congregation & Your Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              const Text(
                'Set up a real congregation structure and your starting publisher role. All entries can be edited or deleted anytime.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: congNameCtrl,
                decoration: const InputDecoration(labelText: 'Congregation Name *', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: circuitCtrl,
                      decoration: const InputDecoration(labelText: 'Circuit (e.g. NG-14)', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: countryCtrl,
                      decoration: const InputDecoration(labelText: 'Country Code', border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: pubNameCtrl,
                decoration: const InputDecoration(labelText: 'Your Display Name *', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: role,
                      decoration: const InputDecoration(labelText: 'Your Role / Privilege', border: OutlineInputBorder()),
                      items: TheocraticRolePermissions.allRoles
                          .map((r) => DropdownMenuItem(value: r, child: Text(TheocraticRolePermissions.label(r))))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setModalState(() => role = v);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      initialValue: group,
                      decoration: const InputDecoration(labelText: 'Service Group', border: OutlineInputBorder()),
                      onChanged: (v) => group = v.trim().isEmpty ? 'Group 1' : v.trim(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Complete Setup'),
                  onPressed: () async {
                    if (congNameCtrl.text.trim().isEmpty || pubNameCtrl.text.trim().isEmpty) return;
                    HapticFeedback.mediumImpact();
                    final congId = await dao.createCongregation(
                      name: congNameCtrl.text.trim(),
                      circuit: circuitCtrl.text.trim(),
                      countryCode: countryCtrl.text.trim().isEmpty ? 'WW' : countryCtrl.text.trim().toUpperCase(),
                    );
                    await dao.createPublisher(
                      congregationId: congId,
                      displayName: pubNameCtrl.text.trim(),
                      role: role,
                      serviceGroup: group,
                      setAsActiveOnDevice: true,
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

  Future<void> _showCongregationFormModal(
    BuildContext context,
    CongregationDao dao, {
    CongregationItem? existing,
  }) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final circuitCtrl = TextEditingController(text: existing?.circuit ?? '');
    final countryCtrl = TextEditingController(text: existing?.countryCode ?? 'WW');
    final addrCtrl = TextEditingController(text: existing?.kingdomHallAddress ?? '');
    final schedCtrl = TextEditingController(text: existing?.meetingSchedule ?? 'Thu 6:30 PM • Sun 9:30 AM');

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => SingleChildScrollView(
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
              existing == null ? 'Register Congregation' : 'Edit Congregation',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Congregation Name *', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: circuitCtrl,
                    decoration: const InputDecoration(labelText: 'Circuit', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: countryCtrl,
                    decoration: const InputDecoration(labelText: 'Country Code', border: OutlineInputBorder()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: addrCtrl,
              decoration: const InputDecoration(labelText: 'Kingdom Hall Address', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: schedCtrl,
              decoration: const InputDecoration(labelText: 'Midweek & Weekend Meeting Times', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.save),
                label: Text(existing == null ? 'Register Congregation' : 'Update Congregation'),
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty) return;
                  if (existing == null) {
                    await dao.createCongregation(
                      name: nameCtrl.text.trim(),
                      circuit: circuitCtrl.text.trim(),
                      countryCode: countryCtrl.text.trim(),
                      kingdomHallAddress: addrCtrl.text.trim(),
                      meetingSchedule: schedCtrl.text.trim(),
                    );
                  } else {
                    await dao.updateCongregation(
                      id: existing.id,
                      name: nameCtrl.text.trim(),
                      circuit: circuitCtrl.text.trim(),
                      countryCode: countryCtrl.text.trim(),
                      kingdomHallAddress: addrCtrl.text.trim(),
                      meetingSchedule: schedCtrl.text.trim(),
                    );
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteCongregation(
    BuildContext context,
    CongregationDao dao,
    CongregationItem cong,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Congregation?'),
        content: Text('Delete "${cong.name}" and its associated congregation territories, pins, chat, and publishers?'),
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
    if (ok == true) {
      await dao.deleteCongregation(cong.id);
    }
  }

  Future<void> _showPublisherFormModal(
    BuildContext context,
    CongregationDao dao,
    String congregationId, {
    PublisherProfileItem? existing,
  }) async {
    final nameCtrl = TextEditingController(text: existing?.displayName ?? '');
    final groupCtrl = TextEditingController(text: existing?.serviceGroup ?? 'Group 1');
    String role = existing?.role ?? 'publisher';
    bool isActive = existing?.isActive ?? true;
    bool setActiveDevice = false;

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
                existing == null ? 'Create Publisher Profile' : 'Edit Publisher Profile',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Full Name / Display Name *', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: role,
                decoration: const InputDecoration(labelText: 'Theocratic Privilege / Role', border: OutlineInputBorder()),
                items: TheocraticRolePermissions.allRoles
                    .map((r) => DropdownMenuItem(value: r, child: Text(TheocraticRolePermissions.label(r))))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setModalState(() => role = v);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: groupCtrl,
                decoration: const InputDecoration(labelText: 'Field Service Group', border: OutlineInputBorder()),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Active in Congregation'),
                value: isActive,
                onChanged: (v) => setModalState(() => isActive = v),
              ),
              if (existing == null)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Set as Active Profile on This Device'),
                  value: setActiveDevice,
                  onChanged: (v) => setModalState(() => setActiveDevice = v),
                ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.save),
                  label: Text(existing == null ? 'Save Publisher' : 'Update Publisher'),
                  onPressed: () async {
                    if (nameCtrl.text.trim().isEmpty) return;
                    if (existing == null) {
                      await dao.createPublisher(
                        congregationId: congregationId,
                        displayName: nameCtrl.text.trim(),
                        role: role,
                        serviceGroup: groupCtrl.text.trim().isEmpty ? 'Group 1' : groupCtrl.text.trim(),
                        isActive: isActive,
                        setAsActiveOnDevice: setActiveDevice,
                      );
                    } else {
                      await dao.updatePublisher(
                        id: existing.id,
                        displayName: nameCtrl.text.trim(),
                        role: role,
                        serviceGroup: groupCtrl.text.trim().isEmpty ? 'Group 1' : groupCtrl.text.trim(),
                        isActive: isActive,
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

  Future<void> _showPrivilegeDialog(
    BuildContext context,
    CongregationDao dao,
    PublisherProfileItem pub,
  ) async {
    String selected = pub.role;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Assign Privilege — ${pub.displayName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: TheocraticRolePermissions.allRoles
                .map(
                  (r) => RadioListTile<String>(
                    title: Text(TheocraticRolePermissions.label(r)),
                    value: r,
                    groupValue: selected,
                    onChanged: (v) {
                      if (v != null) setDialogState(() => selected = v);
                    },
                  ),
                )
                .toList(),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                await dao.assignPublisherPrivilege(pub.id, selected);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Assign'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCongregationReportModal(
    BuildContext context,
    CongregationDao dao,
    String congId,
    String yearMonth,
    PublisherProfileItem? activePub,
  ) async {
    final nameCtrl = TextEditingController(text: activePub?.displayName ?? '');
    final hoursCtrl = TextEditingController(text: '0.0');
    final creditCtrl = TextEditingController(text: '0.0');
    final studiesCtrl = TextEditingController(text: '0');
    final remarksCtrl = TextEditingController();
    String role = activePub?.role ?? 'publisher';
    bool participated = true;

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
              Text('Record S-4 Report ($yearMonth)', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Publisher Name *', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: role,
                decoration: const InputDecoration(labelText: 'Service Privilege', border: OutlineInputBorder()),
                items: TheocraticRolePermissions.allRoles
                    .map((r) => DropdownMenuItem(value: r, child: Text(TheocraticRolePermissions.label(r))))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setModalState(() => role = v);
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Participated in Ministry'),
                value: participated,
                onChanged: (v) => setModalState(() => participated = v),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: hoursCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Hours', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: creditCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Credit', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: studiesCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Studies', border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: remarksCtrl,
                decoration: const InputDecoration(labelText: 'Remarks', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.send),
                  label: const Text('Submit to Congregation Rollup'),
                  onPressed: () async {
                    if (nameCtrl.text.trim().isEmpty) return;
                    await dao.submitCongregationReport(
                      congregationId: congId,
                      publisherId: activePub?.id ?? nameCtrl.text.trim().toLowerCase().replaceAll(' ', '_'),
                      publisherName: nameCtrl.text.trim(),
                      yearMonth: yearMonth,
                      publisherRole: role,
                      participated: participated,
                      hours: double.tryParse(hoursCtrl.text.trim()) ?? 0.0,
                      creditHours: double.tryParse(creditCtrl.text.trim()) ?? 0.0,
                      bibleStudies: int.tryParse(studiesCtrl.text.trim()) ?? 0,
                      remarks: remarksCtrl.text.trim(),
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
}
