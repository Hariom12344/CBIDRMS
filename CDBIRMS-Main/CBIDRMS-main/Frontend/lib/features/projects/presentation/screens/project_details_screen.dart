import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/custom_textfield.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../users/presentation/providers/user_provider.dart';
import '../../domain/models/project_model.dart';
import '../providers/project_provider.dart';
import '../../../site/presentation/providers/site_provider.dart';
import '../../../site/presentation/widgets/add_site_update_dialog.dart';
import '../../../site/presentation/widgets/add_site_task_dialog.dart';
import '../../../documents/presentation/providers/document_provider.dart';
import '../../../documents/presentation/screens/document_list_screen.dart';
import '../../../finance/presentation/providers/finance_provider.dart';
import '../../../finance/presentation/widgets/set_budget_dialog.dart';
import '../../../finance/presentation/widgets/record_expense_dialog.dart';
import '../../../design/presentation/providers/design_provider.dart';
import '../../../design/presentation/screens/design_list_screen.dart';

class ProjectDetailsScreen extends ConsumerStatefulWidget {
  final ProjectModel? project;
  final String? projectId;

  const ProjectDetailsScreen({
    super.key,
    this.project,
    this.projectId,
  });

  @override
  ConsumerState<ProjectDetailsScreen> createState() => _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends ConsumerState<ProjectDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final id = widget.project?.id ?? widget.projectId;
      if (id != null && id.isNotEmpty) {
        ref.read(projectNotifierProvider.notifier).fetchProjectDetails(id);
        ref.read(siteNotifierProvider.notifier).fetchSiteUpdates(projectId: id);
        ref.read(siteNotifierProvider.notifier).fetchSiteTasks(projectId: id);
        ref.read(documentProvider.notifier).setProject(id);
        ref.read(designProvider.notifier).setProject(id);
        ref.read(financeNotifierProvider.notifier).fetchProjectBudget(id);
      }
      ref.read(userNotifierProvider.notifier).fetchUsers();
    });
  }

  void _showAssignTeamDialog(ProjectModel currentProject) {
    final userState = ref.read(userNotifierProvider);
    final users = userState.users;
    final Map<int, String> selectedMembers = {};

    for (var m in currentProject.assignedTeam) {
      selectedMembers[m.userId] = m.role ?? 'Team Member';
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.surface,
            title: const Text('Assign Team Members', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440, maxHeight: 360),
              child: users.isEmpty
                  ? const Center(child: Text('No users found in organization.', style: TextStyle(color: AppColors.textMuted)))
                  : ListView.builder(
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final u = users[index];
                        final isSelected = selectedMembers.containsKey(u.id);

                        return CheckboxListTile(
                          activeColor: AppColors.primary,
                          checkColor: Colors.white,
                          title: Text(u.fullName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                          subtitle: Text('${u.role} (${u.email})', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          value: isSelected,
                          onChanged: (val) {
                            setDialogState(() {
                              if (val == true) {
                                selectedMembers[u.id] = u.role;
                              } else {
                                selectedMembers.remove(u.id);
                              }
                            });
                          },
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  Navigator.pop(ctx);
                  final teamList = selectedMembers.entries.map((e) => {
                    'userId': e.key,
                    'role': e.value,
                  }).toList();

                  final ok = await ref.read(projectNotifierProvider.notifier).assignTeamToProject(currentProject.id, teamList);
                  if (ok) {
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Team assigned successfully!')),
                    );
                  }
                },
                child: const Text('Save Team', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddStageDialog(String projectId) {
    final nameCtrl = TextEditingController();
    final startCtrl = TextEditingController();
    final endCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Add Project Stage', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                controller: nameCtrl,
                label: 'Stage Name',
                hintText: 'e.g. Procurement & Framing',
                prefixIcon: Icons.task_alt_rounded,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: startCtrl,
                label: 'Start Date (Optional)',
                hintText: 'YYYY-MM-DD',
                prefixIcon: Icons.calendar_today_outlined,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: endCtrl,
                label: 'End Date (Optional)',
                hintText: 'YYYY-MM-DD',
                prefixIcon: Icons.calendar_today_rounded,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final stageName = nameCtrl.text.trim();
              if (stageName.isEmpty) return;
              Navigator.pop(ctx);

              final ok = await ref.read(projectNotifierProvider.notifier).addStageToProject(
                projectId,
                stageName,
                startDate: startCtrl.text.trim().isEmpty ? null : startCtrl.text.trim(),
                endDate: endCtrl.text.trim().isEmpty ? null : endCtrl.text.trim(),
              );

              if (ok) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('Stage added successfully!')),
                );
              }
            },
            child: const Text('Add Stage', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(projectNotifierProvider);
    final p = state.selectedProject ?? widget.project ?? ProjectModel(
      id: widget.projectId ?? 'PRJ-101',
      name: 'Project Workspace',
      clientName: 'Client',
      designerName: 'Designer',
      startDate: '2026-01-01',
      endDate: '2026-06-30',
      budget: 0,
      status: 'PLANNING',
      progress: 0,
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          onPressed: () => context.pop(),
        ),
        title: Text(p.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: state.isDetailLoading
          ? const Center(child: LoadingWidget(message: 'Loading project details...'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Overview Card
                  Card(
                    color: AppColors.surface,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('PROJECT ID: ${p.id}', style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold)),
                              PopupMenuButton<String>(
                                initialValue: p.status,
                                onSelected: (newStatus) async {
                                  final messenger = ScaffoldMessenger.of(context);
                                  final ok = await ref.read(projectNotifierProvider.notifier).updateProjectStatus(p.id, newStatus);
                                  if (ok) {
                                    messenger.showSnackBar(
                                      SnackBar(content: Text('Project status updated to $newStatus')),
                                    );
                                  }
                                },
                                child: StatusBadge(status: p.status),
                                itemBuilder: (context) => const [
                                  PopupMenuItem(value: 'PLANNING', child: Text('PLANNING', style: TextStyle(color: Colors.white))),
                                  PopupMenuItem(value: 'ONGOING', child: Text('ONGOING', style: TextStyle(color: Colors.white))),
                                  PopupMenuItem(value: 'ON_HOLD', child: Text('ON_HOLD', style: TextStyle(color: Colors.white))),
                                  PopupMenuItem(value: 'COMPLETED', child: Text('COMPLETED', style: TextStyle(color: Colors.white))),
                                  PopupMenuItem(value: 'CANCELLED', child: Text('CANCELLED', style: TextStyle(color: Colors.white))),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(p.name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 20),
                          const Divider(color: AppColors.surfaceLight),
                          const SizedBox(height: 16),
                          _buildRow(Icons.person_outline, 'Client', p.clientName),
                          const SizedBox(height: 12),
                          _buildRow(Icons.architecture, 'Designer', p.designerName),
                          const SizedBox(height: 12),
                          _buildRow(Icons.calendar_today_outlined, 'Timeline', '${p.startDate} to ${p.endDate}'),
                          const SizedBox(height: 12),
                          _buildRow(Icons.currency_rupee_rounded, 'Total Budget', '₹${p.budget.toStringAsFixed(2)}', color: AppColors.success),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Progress & Stages Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('PROJECT STAGES & PROGRESS', style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      TextButton.icon(
                        icon: const Icon(Icons.add_rounded, color: AppColors.primary, size: 18),
                        label: const Text('Add Stage', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                        onPressed: () => _showAddStageDialog(p.id),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Card(
                    color: AppColors.surface,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Calculated Progress', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              Text('${(p.progress * 100).toInt()}%', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 18)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          LinearProgressIndicator(value: p.progress, minHeight: 10, backgroundColor: AppColors.surfaceLight, color: AppColors.primary),
                          const SizedBox(height: 20),

                          if (p.stages.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Text('No stages added yet. Tap "+ Add Stage" to create milestone stages.', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: p.stages.length,
                              separatorBuilder: (context, index) => const Divider(color: AppColors.surfaceLight),
                              itemBuilder: (context, index) {
                                final stage = p.stages[index];
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(stage.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                                  subtitle: stage.startDate != null
                                      ? Text('${stage.startDate} - ${stage.endDate ?? "Ongoing"}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))
                                      : null,
                                  trailing: SegmentedButton<String>(
                                    segments: const [
                                      ButtonSegment(value: 'pending', label: Text('Pending', style: TextStyle(fontSize: 11))),
                                      ButtonSegment(value: 'in_progress', label: Text('In Progress', style: TextStyle(fontSize: 11))),
                                      ButtonSegment(value: 'done', label: Text('Done', style: TextStyle(fontSize: 11))),
                                    ],
                                    selected: {stage.status},
                                    onSelectionChanged: (Set<String> newSelection) async {
                                      final newStatus = newSelection.first;
                                      await ref.read(projectNotifierProvider.notifier).updateStageStatus(p.id, stage.id, newStatus);
                                    },
                                    style: ButtonStyle(
                                      visualDensity: VisualDensity.compact,
                                      backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
                                        if (states.contains(WidgetState.selected)) {
                                          return AppColors.primary;
                                        }
                                        return AppColors.surfaceLight;
                                      }),
                                    ),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Assigned Team Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('ASSIGNED TEAM MEMBERS', style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      TextButton.icon(
                        icon: const Icon(Icons.group_add_rounded, color: AppColors.primary, size: 18),
                        label: const Text('Manage Team', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                        onPressed: () => _showAssignTeamDialog(p),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Card(
                    color: AppColors.surface,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: p.assignedTeam.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Text('No team members assigned yet. Tap "Manage Team" to assign staff.', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: p.assignedTeam.length,
                              separatorBuilder: (context, index) => const Divider(color: AppColors.surfaceLight),
                              itemBuilder: (context, index) {
                                final member = p.assignedTeam[index];
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: CircleAvatar(
                                    backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                                    child: Text(
                                      member.userName.isNotEmpty ? member.userName[0].toUpperCase() : 'U',
                                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  title: Text(member.userName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                                  subtitle: Text(member.userEmail, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceLight,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      member.role ?? 'Team Member',
                                      style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Site Updates & Tasks Section (FC-011)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('SITE UPDATES & TASKS', style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      Row(
                        children: [
                          TextButton.icon(
                            icon: const Icon(Icons.add_a_photo_outlined, color: AppColors.primary, size: 16),
                            label: const Text('Post Update', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AddSiteUpdateDialog(preselectedProjectId: p.id),
                              );
                            },
                          ),
                          TextButton.icon(
                            icon: const Icon(Icons.add_task_rounded, color: AppColors.primary, size: 16),
                            label: const Text('Add Task', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AddSiteTaskDialog(preselectedProjectId: p.id),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Card(
                    color: AppColors.surface,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Consumer(
                        builder: (context, ref, child) {
                          final siteState = ref.watch(siteNotifierProvider);
                          final projectUpdates = siteState.siteUpdates.where((u) => u.projectId == p.id).toList();
                          final projectTasks = siteState.siteTasks.where((t) => t.projectId == p.id).toList();

                          if (projectUpdates.isEmpty && projectTasks.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Text('No site updates or tasks logged for this project yet. Tap "Post Update" or "Add Task" to log daily progress.', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                            );
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (projectUpdates.isNotEmpty) ...[
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Latest Site Update (${projectUpdates.first.updateDate})', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                    Text('By ${projectUpdates.first.supervisorName}', style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(projectUpdates.first.description, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4)),
                                if (projectUpdates.first.issueReported != null) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.warning.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 16),
                                        const SizedBox(width: 6),
                                        Expanded(child: Text('Issue: ${projectUpdates.first.issueReported}', style: const TextStyle(color: AppColors.warning, fontSize: 12))),
                                      ],
                                    ),
                                  ),
                                ],
                              ],

                              if (projectUpdates.isNotEmpty && projectTasks.isNotEmpty)
                                const Divider(height: 24, color: AppColors.surfaceLight),

                              if (projectTasks.isNotEmpty) ...[
                                Text('Site Tasks Checklist (${projectTasks.where((t) => t.status == 'DONE').length}/${projectTasks.length} Done)', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                const SizedBox(height: 8),
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: projectTasks.length,
                                  separatorBuilder: (context, index) => const SizedBox(height: 6),
                                  itemBuilder: (context, index) {
                                    final task = projectTasks[index];
                                    return Row(
                                      children: [
                                        Icon(
                                          task.status == 'DONE' ? Icons.check_circle_rounded : (task.status == 'IN_PROGRESS' ? Icons.pending_actions_rounded : Icons.radio_button_unchecked_rounded),
                                          color: task.status == 'DONE' ? AppColors.success : (task.status == 'IN_PROGRESS' ? AppColors.primary : AppColors.textMuted),
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            task.title,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 13,
                                              decoration: task.status == 'DONE' ? TextDecoration.lineThrough : null,
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Project Designs & Drawings Section (FC-010)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('PROJECT DESIGNS & DRAWINGS', style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      TextButton.icon(
                        icon: const Icon(Icons.architecture_rounded, color: AppColors.primary, size: 16),
                        label: const Text('Manage Drawings', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => DesignListScreen(projectId: p.id)),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Card(
                    color: AppColors.surface,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Consumer(
                        builder: (context, ref, child) {
                          final dState = ref.watch(designProvider);
                          final projectDesigns = dState.designs.where((d) => d.projectId == p.id).toList();

                          if (projectDesigns.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Text('No design drawings uploaded for this project yet. Tap "Manage Drawings" to upload drawings and track approval revisions.', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                            );
                          }

                          return ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: projectDesigns.length > 5 ? 5 : projectDesigns.length,
                            separatorBuilder: (context, index) => const Divider(color: AppColors.surfaceLight),
                            itemBuilder: (context, index) {
                              final design = projectDesigns[index];
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(
                                  design.category == 'FLOOR_PLAN'
                                      ? Icons.map_outlined
                                      : (design.category == 'THREE_D_RENDER'
                                          ? Icons.view_in_ar_outlined
                                          : (design.category == 'CAD_DRAWING' ? Icons.architecture_outlined : Icons.draw_outlined)),
                                  color: design.category == 'THREE_D_RENDER'
                                      ? AppColors.success
                                      : (design.category == 'FLOOR_PLAN' ? AppColors.secondary : AppColors.primary),
                                ),
                                title: Text(design.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                                subtitle: Text('${design.category.replaceAll('_', ' ')} • ${design.version} • By ${design.uploadedBy}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                trailing: StatusBadge(status: design.approvalStatus),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => DesignListScreen(projectId: p.id)),
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Project Documents Section (FC-012)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('PROJECT DOCUMENTS', style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      TextButton.icon(
                        icon: const Icon(Icons.folder_open_rounded, color: AppColors.primary, size: 16),
                        label: const Text('View All Documents', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => DocumentListScreen(projectId: p.id)),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Card(
                    color: AppColors.surface,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Consumer(
                        builder: (context, ref, child) {
                          final docState = ref.watch(documentProvider);
                          final projectDocs = docState.documents.where((d) => d.projectId == p.id).toList();

                          if (projectDocs.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Text('No documents uploaded for this project yet.', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                            );
                          }

                          return ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: projectDocs.length > 5 ? 5 : projectDocs.length,
                            separatorBuilder: (context, index) => const Divider(color: AppColors.surfaceLight),
                            itemBuilder: (context, index) {
                              final doc = projectDocs[index];
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(
                                  doc.fileType == 'PDF'
                                      ? Icons.picture_as_pdf_outlined
                                      : (doc.fileType == 'IMAGE'
                                          ? Icons.image_outlined
                                          : (doc.fileType == 'CAD' ? Icons.architecture_outlined : Icons.insert_drive_file_outlined)),
                                  color: doc.fileType == 'PDF'
                                      ? AppColors.error
                                      : (doc.fileType == 'IMAGE' ? AppColors.success : AppColors.primary),
                                ),
                                title: Text(doc.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                                subtitle: Text('${doc.category.replaceAll('_', ' ')} • ${doc.fileSize} • ${doc.uploadedAt}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Project Budget & Expenses Section (FC-013)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('PROJECT BUDGET & EXPENSES', style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      Row(
                        children: [
                          TextButton.icon(
                            icon: const Icon(Icons.account_balance_wallet_outlined, color: AppColors.primary, size: 16),
                            label: const Text('Set Budget', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                            onPressed: () {
                              final budgetObj = ref.read(financeNotifierProvider).projectBudgets[p.id];
                              showDialog(
                                context: context,
                                builder: (context) => SetBudgetDialog(projectId: p.id, currentBudget: budgetObj?.budget),
                              );
                            },
                          ),
                          TextButton.icon(
                            icon: const Icon(Icons.add_shopping_cart_rounded, color: AppColors.primary, size: 16),
                            label: const Text('Add Expense', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => RecordExpenseDialog(preselectedProjectId: p.id),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Card(
                    color: AppColors.surface,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Consumer(
                        builder: (context, ref, child) {
                          final finState = ref.watch(financeNotifierProvider);
                          final budgetObj = finState.projectBudgets[p.id];

                          final totalBudget = budgetObj?.budget;
                          final totalSpent = budgetObj?.spent ?? 0.0;
                          final remaining = budgetObj?.remaining;

                          final progress = (totalBudget != null && totalBudget > 0) ? (totalSpent / totalBudget).clamp(0.0, 1.0) : 0.0;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Total Budget', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                      const SizedBox(height: 2),
                                      Text(
                                        totalBudget != null ? '₹${totalBudget.toStringAsFixed(0)}' : 'No budget set',
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Total Spent', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                      const SizedBox(height: 2),
                                      Text(
                                        '₹${totalSpent.toStringAsFixed(0)}',
                                        style: const TextStyle(color: AppColors.warning, fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Remaining', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                      const SizedBox(height: 2),
                                      Text(
                                        remaining != null
                                            ? '₹${remaining.toStringAsFixed(0)}'
                                            : 'N/A',
                                        style: TextStyle(
                                          color: (remaining != null && remaining < 0) ? AppColors.error : AppColors.success,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 8,
                                  backgroundColor: AppColors.surfaceLight,
                                  color: progress > 0.9 ? AppColors.error : AppColors.primary,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildRow(IconData icon, String label, String value, {Color? color}) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textMuted, size: 18),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        const Spacer(),
        Text(value, style: TextStyle(color: color ?? Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }
}
