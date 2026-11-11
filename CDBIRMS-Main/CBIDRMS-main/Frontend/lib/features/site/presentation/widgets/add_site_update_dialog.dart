import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/custom_textfield.dart';
import '../../../projects/presentation/providers/project_provider.dart';
import '../providers/site_provider.dart';

class AddSiteUpdateDialog extends ConsumerStatefulWidget {
  final String? preselectedProjectId;

  const AddSiteUpdateDialog({super.key, this.preselectedProjectId});

  @override
  ConsumerState<AddSiteUpdateDialog> createState() => _AddSiteUpdateDialogState();
}

class _AddSiteUpdateDialogState extends ConsumerState<AddSiteUpdateDialog> {
  final _formKey = GlobalKey<FormState>();
  late String? _selectedProjectId;
  final _descriptionCtrl = TextEditingController();
  
  bool _hasIssue = false;
  final _issueCtrl = TextEditingController();
  String? _selectedSeverity = 'MEDIUM';

  final _photoUrlCtrl = TextEditingController();
  final List<String> _photoUrls = [];
  final List<PlatformFile> _pickedFiles = [];
  String? _validationError;

  @override
  void initState() {
    super.initState();
    _selectedProjectId = widget.preselectedProjectId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(projectNotifierProvider.notifier).fetchProjects();
    });
  }

  @override
  void dispose() {
    _descriptionCtrl.dispose();
    _issueCtrl.dispose();
    _photoUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFilesFromDevice() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final totalCount = _photoUrls.length + _pickedFiles.length + result.files.length;
        if (totalCount > 10) {
          setState(() {
            _validationError = 'Maximum 10 photos allowed per site update.';
          });
          return;
        }

        setState(() {
          _pickedFiles.addAll(result.files);
          _validationError = null;
        });
      }
    } catch (e) {
      setState(() {
        _validationError = 'Failed to pick files from device: $e';
      });
    }
  }

  void _addPhotoUrl() {
    final url = _photoUrlCtrl.text.trim();
    if (url.isNotEmpty) {
      if (_photoUrls.length + _pickedFiles.length >= 10) {
        setState(() {
          _validationError = 'Maximum 10 photos allowed per site update.';
        });
        return;
      }
      setState(() {
        _photoUrls.add(url);
        _photoUrlCtrl.clear();
        _validationError = null;
      });
    }
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

    final desc = _descriptionCtrl.text.trim();
    if (desc.length < 10) {
      setState(() {
        _validationError = 'Description must be at least 10 characters long.';
      });
      return;
    }

    String? issueText;
    String? severity;
    if (_hasIssue) {
      issueText = _issueCtrl.text.trim();
      if (issueText.isEmpty) {
        setState(() {
          _validationError = 'Please describe the issue or uncheck "Report Issue".';
        });
        return;
      }
      severity = _selectedSeverity;
      if (severity == null || severity.isEmpty) {
        setState(() {
          _validationError = 'Please select an issue severity level.';
        });
        return;
      }
    }

    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);

    final success = await ref.read(siteNotifierProvider.notifier).postSiteUpdate(
      projectId: _selectedProjectId!,
      description: desc,
      issueReported: issueText,
      issueSeverity: severity,
      photoUrls: _photoUrls,
      pickedFiles: _pickedFiles,
    );

    if (success) {
      nav.pop();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Site update posted successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      final err = ref.read(siteNotifierProvider).errorMessage ?? 'Failed to post update.';
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

    final siteState = ref.watch(siteNotifierProvider);

    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.camera_alt_outlined, color: AppColors.primary),
          SizedBox(width: 10),
          Expanded(
            child: Text('Add Daily Site Update', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
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

                // Description
                CustomTextField(
                  controller: _descriptionCtrl,
                  label: 'DAILY PROGRESS DESCRIPTION',
                  hintText: 'e.g. Completed tile installation in living room. Drywall prep ongoing...',
                  maxLines: 4,
                  prefixIcon: Icons.notes_rounded,
                ),
                const SizedBox(height: 16),

                // Issue Flag Toggle
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: SwitchListTile(
                    title: const Text('Flag an Issue or Blocker', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: const Text('Notify PM and track on site feed', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    value: _hasIssue,
                    activeThumbColor: AppColors.warning,
                    onChanged: (val) {
                      setState(() {
                        _hasIssue = val;
                      });
                    },
                  ),
                ),

                if (_hasIssue) ...[
                  const SizedBox(height: 14),
                  CustomTextField(
                    controller: _issueCtrl,
                    label: 'ISSUE DESCRIPTION',
                    hintText: 'Describe material delay, site damage, or blocker...',
                    prefixIcon: Icons.warning_amber_rounded,
                  ),
                  const SizedBox(height: 12),
                  const Text('ISSUE SEVERITY', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedSeverity,
                    dropdownColor: AppColors.surface,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.surfaceLight,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'LOW', child: Text('LOW — Minor delay', style: TextStyle(color: Colors.blueAccent))),
                      DropdownMenuItem(value: 'MEDIUM', child: Text('MEDIUM — Needs PM attention', style: TextStyle(color: Colors.orangeAccent))),
                      DropdownMenuItem(value: 'HIGH', child: Text('HIGH — Critical Blocker (Alerts PM/Admin)', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _selectedSeverity = val;
                      });
                    },
                  ),
                ],

                const SizedBox(height: 18),

                // Device Photo Upload Options
                const Text('ATTACH SITE PHOTOS (Max 10 total)', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                const SizedBox(height: 10),

                // Device Browser File Upload Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.file_upload_outlined, size: 20),
                    label: const Text('Choose Photos from Device / Browser', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: _pickFilesFromDevice,
                  ),
                ),

                const SizedBox(height: 12),
                const Row(
                  children: [
                    Expanded(child: Divider(color: AppColors.surfaceLight)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('OR VIA URL', style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                    Expanded(child: Divider(color: AppColors.surfaceLight)),
                  ],
                ),
                const SizedBox(height: 10),

                // Photo URL Row
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _photoUrlCtrl,
                        label: 'PHOTO IMAGE URL',
                        hintText: 'Paste Image URL (https://...)',
                        prefixIcon: Icons.link_rounded,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.surfaceLight,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        ),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add URL'),
                        onPressed: _addPhotoUrl,
                      ),
                    ),
                  ],
                ),

                // Attached Photo Chips Display
                if (_pickedFiles.isNotEmpty || _photoUrls.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const Text('ATTACHED PHOTOS', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ..._pickedFiles.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final f = entry.value;
                        return Chip(
                          backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                          avatar: const Icon(Icons.file_present_rounded, size: 16, color: AppColors.primary),
                          label: Text(f.name, style: const TextStyle(color: Colors.white, fontSize: 12)),
                          deleteIcon: const Icon(Icons.close, size: 14, color: AppColors.textMuted),
                          onDeleted: () {
                            setState(() {
                              _pickedFiles.removeAt(idx);
                            });
                          },
                        );
                      }),
                      ..._photoUrls.asMap().entries.map((entry) {
                        final idx = entry.key;
                        return Chip(
                          backgroundColor: AppColors.surfaceLight,
                          avatar: const Icon(Icons.link_rounded, size: 16, color: AppColors.primary),
                          label: Text('Photo URL ${idx + 1}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                          deleteIcon: const Icon(Icons.close, size: 14, color: AppColors.textMuted),
                          onDeleted: () {
                            setState(() {
                              _photoUrls.removeAt(idx);
                            });
                          },
                        );
                      }),
                    ],
                  ),
                ],
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
              : const Text('Post Update', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
