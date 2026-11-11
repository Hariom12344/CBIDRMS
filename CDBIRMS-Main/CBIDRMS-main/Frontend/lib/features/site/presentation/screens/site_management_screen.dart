import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/app_drawer_sidebar.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../projects/presentation/providers/project_provider.dart';
import '../providers/site_provider.dart';
import '../widgets/add_site_update_dialog.dart';
import '../widgets/add_site_task_dialog.dart';
import '../../domain/models/site_update_model.dart';
import '../../domain/models/site_task_model.dart';

class SiteManagementScreen extends ConsumerStatefulWidget {
  const SiteManagementScreen({super.key});

  @override
  ConsumerState<SiteManagementScreen> createState() => _SiteManagementScreenState();
}

class _SiteManagementScreenState extends ConsumerState<SiteManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedProjectId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(projectNotifierProvider.notifier).fetchProjects();
      ref.read(siteNotifierProvider.notifier).fetchSiteUpdates();
      ref.read(siteNotifierProvider.notifier).fetchSiteTasks();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddUpdateDialog() {
    showDialog(
      context: context,
      builder: (context) => AddSiteUpdateDialog(preselectedProjectId: _selectedProjectId),
    );
  }

  void _showAddTaskDialog() {
    showDialog(
      context: context,
      builder: (context) => AddSiteTaskDialog(preselectedProjectId: _selectedProjectId),
    );
  }

  void _showPhotoPreview(BuildContext context, String photoUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                photoUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Container(
                  padding: const EdgeInsets.all(32),
                  color: AppColors.surface,
                  child: const Column(
                    children: [
                      Icon(Icons.broken_image_rounded, color: AppColors.textMuted, size: 48),
                      SizedBox(height: 8),
                      Text('Image preview unavailable', style: TextStyle(color: AppColors.textMuted)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final siteState = ref.watch(siteNotifierProvider);
    final projectState = ref.watch(projectNotifierProvider);
    final projects = projectState.projects;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Site Work & Daily Reports', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(icon: Icon(Icons.feed_outlined), text: 'Daily Updates'),
            Tab(icon: Icon(Icons.checklist_rtl_rounded), text: 'Site Tasks (PRD §7.9)'),
          ],
        ),
      ),
      drawer: const AppDrawerSidebar(currentRoute: '/site'),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: Icon(_tabController.index == 0 ? Icons.add_a_photo_outlined : Icons.add_task_rounded, color: Colors.white),
        label: Text(
          _tabController.index == 0 ? 'Add Site Update' : 'Create Site Task',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        onPressed: () {
          if (_tabController.index == 0) {
            _showAddUpdateDialog();
          } else {
            _showAddTaskDialog();
          }
        },
      ),
      body: Column(
        children: [
          // Project Filter Header
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.filter_list_rounded, color: AppColors.textMuted, size: 18),
                const SizedBox(width: 8),
                const Text('Filter Project:', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: _selectedProjectId,
                      dropdownColor: AppColors.surface,
                      isExpanded: true,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('All Projects', style: TextStyle(color: AppColors.primary)),
                        ),
                        ...projects.map((p) => DropdownMenuItem<String?>(
                          value: p.id,
                          child: Text(p.name, overflow: TextOverflow.ellipsis),
                        )),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _selectedProjectId = val;
                        });
                        ref.read(siteNotifierProvider.notifier).setSelectedProject(val);
                      },
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
                  tooltip: 'Refresh Feed',
                  onPressed: () {
                    ref.read(siteNotifierProvider.notifier).fetchSiteUpdates(projectId: _selectedProjectId);
                    ref.read(siteNotifierProvider.notifier).fetchSiteTasks(projectId: _selectedProjectId);
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.surfaceLight),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Daily Updates Feed
                _buildUpdatesFeed(siteState),
                // Tab 2: Site Tasks Checklist
                _buildTasksChecklist(siteState),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdatesFeed(SiteState siteState) {
    if (siteState.isUpdatesLoading) {
      return const Center(child: LoadingWidget(message: 'Loading site updates feed...'));
    }

    if (siteState.siteUpdates.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.photo_library_outlined, color: AppColors.textMuted, size: 48),
            const SizedBox(height: 16),
            const Text('No site updates posted yet', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Site Supervisors can log daily progress and upload photos.', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              icon: const Icon(Icons.add_a_photo_outlined, color: Colors.white),
              label: const Text('Add First Site Update', style: TextStyle(color: Colors.white)),
              onPressed: _showAddUpdateDialog,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(siteNotifierProvider.notifier).fetchSiteUpdates(projectId: _selectedProjectId);
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: siteState.siteUpdates.length,
        itemBuilder: (context, index) {
          final su = siteState.siteUpdates[index];
          return _buildUpdateCard(su);
        },
      ),
    );
  }

  Widget _buildUpdateCard(SiteUpdateModel su) {
    final hasIssue = su.issueReported != null && su.issueReported!.isNotEmpty;
    Color severityColor = AppColors.warning;
    if (su.issueSeverity == 'HIGH') {
      severityColor = AppColors.error;
    } else if (su.issueSeverity == 'LOW') {
      severityColor = Colors.blueAccent;
    }

    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    su.projectName,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(su.updateDate, style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.person_pin_circle_rounded, color: AppColors.primary, size: 16),
                const SizedBox(width: 6),
                Text('Supervisor: ${su.supervisorName}', style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),

            // Description Body
            Text(
              su.description,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.4),
            ),

            // Issue Banner
            if (hasIssue) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: severityColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: severityColor.withValues(alpha: 0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: severityColor, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'ISSUE REPORTED (${su.issueSeverity ?? "MEDIUM"})',
                          style: TextStyle(color: severityColor, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      su.issueReported!,
                      style: TextStyle(color: severityColor, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],

            // Photos Thumbnails Grid
            if (su.photoUrls.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('SITE PHOTOS', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
              const SizedBox(height: 8),
              SizedBox(
                height: 80,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: su.photoUrls.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final url = su.photoUrls[index];
                    return GestureDetector(
                      onTap: () => _showPhotoPreview(context, url),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 100,
                          color: AppColors.surfaceLight,
                          child: Image.network(
                            url,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: AppColors.surfaceLight,
                              child: const Icon(Icons.image_not_supported_rounded, color: AppColors.textMuted),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTasksChecklist(SiteState siteState) {
    if (siteState.isTasksLoading) {
      return const Center(child: LoadingWidget(message: 'Loading site tasks...'));
    }

    if (siteState.siteTasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.checklist_rtl_rounded, color: AppColors.textMuted, size: 48),
            const SizedBox(height: 16),
            const Text('No site tasks tracked yet', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('PRD §7.9 Track site tasks across ongoing projects.', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              icon: const Icon(Icons.add_task_rounded, color: Colors.white),
              label: const Text('Create First Site Task', style: TextStyle(color: Colors.white)),
              onPressed: _showAddTaskDialog,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(siteNotifierProvider.notifier).fetchSiteTasks(projectId: _selectedProjectId);
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: siteState.siteTasks.length,
        itemBuilder: (context, index) {
          final task = siteState.siteTasks[index];
          return _buildTaskCard(task);
        },
      ),
    );
  }

  Widget _buildTaskCard(SiteTaskModel task) {
    Color statusColor = AppColors.textMuted;
    if (task.status == 'IN_PROGRESS') {
      statusColor = AppColors.primary;
    } else if (task.status == 'DONE') {
      statusColor = AppColors.success;
    }

    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (task.projectName != null) ...[
                        Text(
                          task.projectName!,
                          style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                      ],
                      Text(
                        task.title,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          decoration: task.status == 'DONE' ? TextDecoration.lineThrough : null,
                          decorationColor: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'PENDING', label: Text('Pending', style: TextStyle(fontSize: 11))),
                    ButtonSegment(value: 'IN_PROGRESS', label: Text('In Progress', style: TextStyle(fontSize: 11))),
                    ButtonSegment(value: 'DONE', label: Text('Done', style: TextStyle(fontSize: 11))),
                  ],
                  selected: {task.status},
                  onSelectionChanged: (Set<String> newSelection) async {
                    final newStatus = newSelection.first;
                    await ref.read(siteNotifierProvider.notifier).updateTaskStatus(
                      taskId: task.id,
                      newStatus: newStatus,
                    );
                  },
                  style: ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
                      if (states.contains(WidgetState.selected)) {
                        return statusColor;
                      }
                      return AppColors.surfaceLight;
                    }),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (task.assigneeName != null) ...[
                  const Icon(Icons.person_outline, color: AppColors.textMuted, size: 14),
                  const SizedBox(width: 4),
                  Text('Assignee: ${task.assigneeName}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(width: 16),
                ],
                if (task.dueDate != null) ...[
                  const Icon(Icons.calendar_today_outlined, color: AppColors.textMuted, size: 14),
                  const SizedBox(width: 4),
                  Text('Due: ${task.dueDate}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
                if (task.linkedSiteUpdateId != null) ...[
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('Linked to Update', style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
