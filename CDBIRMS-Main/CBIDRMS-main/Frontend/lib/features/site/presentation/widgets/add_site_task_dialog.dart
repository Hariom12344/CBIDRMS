import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/custom_textfield.dart';
import '../../../projects/presentation/providers/project_provider.dart';
import '../../../users/presentation/providers/user_provider.dart';
import '../providers/site_provider.dart';

class AddSiteTaskDialog extends ConsumerStatefulWidget {
  final String? preselectedProjectId;

  const AddSiteTaskDialog({super.key, this.preselectedProjectId});

  @override
  ConsumerState<AddSiteTaskDialog> createState() => _AddSiteTaskDialogState();
}

class _AddSiteTaskDialogState extends ConsumerState<AddSiteTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  late String? _selectedProjectId;
  final _titleCtrl = TextEditingController();
  final _dueDateCtrl = TextEditingController();
  int? _selectedAssigneeId;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    _selectedProjectId = widget.preselectedProjectId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(projectNotifierProvider.notifier).fetchProjects();
      ref.read(userNotifierProvider.notifier).fetchUsers();
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _dueDateCtrl.dispose();
    super.dispose();
  }

  void _submit() async {
    setState(() {
      _validationError = null;
    });

    if (_selectedProjectId == null || _selectedProjectId!.isEmpty) {
      setState(() {
        _validationError = 'Please select a project.';
      });
      return;
    }

    final title = _titleCtrl.text.trim();
    if (title.length < 2) {
      setState(() {
        _validationError = 'Task title must be at least 2 characters long.';
      });
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);

    final success = await ref.read(siteNotifierProvider.notifier).postSiteTask(
      projectId: _selectedProjectId!,
      title: title,
      assignedTo: _selectedAssigneeId,
      dueDate: _dueDateCtrl.text.trim().isEmpty ? null : _dueDateCtrl.text.trim(),
    );

    if (success) {
      nav.pop();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Site task created successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      final err = ref.read(siteNotifierProvider).errorMessage ?? 'Failed to create task.';
      setState(() {
        _validationError = err;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final projectState = ref.watch(projectNotifierProvider);
    final projects = projectState.projects;

    if (_selectedProjectId == null && projects.isNotEmpty) {
      _selectedProjectId = projects.first.id;
    }

    final userState = ref.watch(userNotifierProvider);
    final users = userState.users.where((u) => u.role == 'SITE_SUPERVISOR' || u.role == 'PROJECT_MANAGER' || u.role == 'SUPER_ADMIN' || u.role == 'COMPANY_ADMIN').toList();

    final siteState = ref.watch(siteNotifierProvider);

    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.add_task_rounded, color: AppColors.primary),
          SizedBox(width: 10),
          Expanded(
            child: Text('Create Site Task', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_validationError != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.error.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
                        const SizedBox(width: 10),
                        Expanded(child: Text(_validationError!, style: const TextStyle(color: AppColors.error, fontSize: 13))),
                      ],
                    ),
                  ),
                ],

                // Project Selector
                const Text('PROJECT', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _selectedProjectId,
                  dropdownColor: AppColors.surface,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.surfaceLight,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  items: projects.map((p) {
                    return DropdownMenuItem(
                      value: p.id,
                      child: Text(p.name, style: const TextStyle(color: Colors.white)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedProjectId = val;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Task Title
                CustomTextField(
                  controller: _titleCtrl,
                  label: 'TASK TITLE',
                  hintText: 'e.g. Italian Marble Polishing - Living Room',
                  prefixIcon: Icons.task_alt_rounded,
                ),
                const SizedBox(height: 16),

                // Assignee Dropdown
                const Text('ASSIGN TO SUPERVISOR (OPTIONAL)', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                const SizedBox(height: 6),
                DropdownButtonFormField<int?>(
                  initialValue: _selectedAssigneeId,
                  dropdownColor: AppColors.surface,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.surfaceLight,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Unassigned', style: TextStyle(color: AppColors.textMuted)),
                    ),
                    ...users.map((u) {
                      return DropdownMenuItem<int?>(
                        value: u.id,
                        child: Text('${u.fullName} (${u.role})', style: const TextStyle(color: Colors.white)),
                      );
                    }),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _selectedAssigneeId = val;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Due Date
                CustomTextField(
                  controller: _dueDateCtrl,
                  label: 'DUE DATE (OPTIONAL)',
                  hintText: 'YYYY-MM-DD',
                  prefixIcon: Icons.calendar_today_outlined,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: siteState.isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          onPressed: siteState.isSubmitting ? null : _submit,
          child: siteState.isSubmitting
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Create Task', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
