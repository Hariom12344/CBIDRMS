import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/app_drawer_sidebar.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/models/design_model.dart';
import '../providers/design_provider.dart';

class DesignListScreen extends ConsumerStatefulWidget {
  final String? projectId;
  const DesignListScreen({super.key, this.projectId});

  @override
  ConsumerState<DesignListScreen> createState() => _DesignListScreenState();
}

class _DesignListScreenState extends ConsumerState<DesignListScreen> {
  final TextEditingController _searchController = TextEditingController();

  static const List<String> _categories = [
    'ALL',
    'THREE_D_RENDER',
    'FLOOR_PLAN',
    'CAD_DRAWING',
    'ELEVATION',
    'OTHER',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.projectId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(designProvider.notifier).setProject(widget.projectId);
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(designProvider);
    final notifier = ref.read(designProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          widget.projectId != null ? 'Project Drawings (${widget.projectId})' : 'Design Management & Drawings',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: () => notifier.fetchDesigns(),
          ),
        ],
      ),
      drawer: widget.projectId == null ? const AppDrawerSidebar(currentRoute: '/design') : null,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.upload_file, color: Colors.white),
        label: const Text('Upload Drawing', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () => _showUploadDialog(context),
      ),
      body: Column(
        children: [
          // Search Bar & Filter Chips Header
          Container(
            padding: const EdgeInsets.all(16.0),
            color: AppColors.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Input
                TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search drawings by title...',
                    hintStyle: const TextStyle(color: AppColors.textSecondary),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, color: AppColors.textSecondary),
                            onPressed: () {
                              _searchController.clear();
                              notifier.setSearchQuery('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (val) => notifier.setSearchQuery(val),
                ),
                const SizedBox(height: 12),
                // Category Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categories.map((cat) {
                      final isSelected = state.selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(
                            cat.replaceAll('_', ' '),
                            style: TextStyle(
                              color: isSelected ? Colors.white : AppColors.textSecondary,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: AppColors.primary,
                          backgroundColor: AppColors.background,
                          onSelected: (selected) {
                            if (selected) {
                              notifier.setCategory(cat);
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white10),

          // Main List View / Loading / Empty State
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : state.designs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.draw_outlined, size: 64, color: AppColors.textSecondary),
                            const SizedBox(height: 16),
                            const Text(
                              'No design drawings found',
                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              state.searchQuery.isNotEmpty || state.selectedCategory != 'ALL'
                                  ? 'Try broadening your search or filter'
                                  : 'Tap "Upload Drawing" to add your first design',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => notifier.fetchDesigns(),
                        color: AppColors.primary,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: state.designs.length,
                          itemBuilder: (context, index) {
                            final d = state.designs[index];
                            return _buildDesignCard(context, d);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesignCard(BuildContext context, DesignModel d) {
    IconData iconData = Icons.draw_outlined;
    Color iconColor = AppColors.primary;

    if (d.category == 'FLOOR_PLAN') {
      iconData = Icons.map_outlined;
      iconColor = AppColors.secondary;
    } else if (d.category == 'THREE_D_RENDER') {
      iconData = Icons.view_in_ar_outlined;
      iconColor = AppColors.success;
    } else if (d.category == 'CAD_DRAWING') {
      iconData = Icons.architecture_outlined;
      iconColor = Colors.orangeAccent;
    } else if (d.category == 'ELEVATION') {
      iconData = Icons.aspect_ratio_outlined;
      iconColor = Colors.purpleAccent;
    }

    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showDetailDialog(context, d),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(iconData, color: iconColor),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          d.title,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Project: ${d.projectName.isNotEmpty ? d.projectName : d.projectId}',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  StatusBadge(status: d.approvalStatus),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      d.category.replaceAll('_', ' '),
                      style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      d.version,
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text(
                    '${d.fileType} • ${d.fileSize}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                  ),
                  Text(
                    '• By ${d.uploadedBy} • ${d.date}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: Colors.white10),
              const SizedBox(height: 8),
              // Action Buttons Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // History Button
                    TextButton.icon(
                      icon: const Icon(Icons.history_rounded, size: 16, color: AppColors.textSecondary),
                      label: const Text('History', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      onPressed: () => _showDetailDialog(context, d),
                    ),
                    // Revise Button
                    TextButton.icon(
                      icon: const Icon(Icons.update_rounded, size: 16, color: AppColors.secondary),
                      label: const Text('New Revision', style: TextStyle(color: AppColors.secondary, fontSize: 12)),
                      onPressed: () => _showRevisionDialog(context, d),
                    ),
                    // Approve / Reject Button
                    TextButton.icon(
                      icon: const Icon(Icons.fact_check_outlined, size: 16, color: AppColors.primary),
                      label: const Text('Approve / Note', style: TextStyle(color: AppColors.primary, fontSize: 12)),
                      onPressed: () => _showApproveDialog(context, d),
                    ),
                    // Download Button
                    IconButton(
                      icon: const Icon(Icons.download_rounded, color: AppColors.success),
                      tooltip: 'Download File',
                      onPressed: () => _handleDownload(context, d),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleDownload(BuildContext context, DesignModel d) async {
    final messenger = ScaffoldMessenger.of(context);
    final res = await ref.read(designProvider.notifier).downloadDesign(d.id);

    if (res != null) {
      final rawUrl = res['downloadUrl'] as String? ?? d.fileUrl;
      if (rawUrl.isNotEmpty) {
        final uri = Uri.parse(rawUrl);
        try {
          final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
          if (launched) {
            messenger.showSnackBar(
              SnackBar(
                content: Text('Downloading ${d.title} (${d.version})...'),
                backgroundColor: AppColors.success,
                duration: const Duration(seconds: 3),
              ),
            );
            return;
          }
        } catch (_) {
          await launchUrl(uri);
          messenger.showSnackBar(
            SnackBar(
              content: Text('Downloading ${d.title} (${d.version})...'),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 3),
            ),
          );
          return;
        }
      }
    }

    messenger.showSnackBar(
      const SnackBar(content: Text('Failed to generate download link'), backgroundColor: AppColors.error),
    );
  }

  void _showApproveDialog(BuildContext context, DesignModel d) {
    final messenger = ScaffoldMessenger.of(context);
    final noteController = TextEditingController();
    String selectedAction = 'APPROVE';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              title: Text('Design Approval - ${d.title}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Select Action:', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Approve'),
                            selected: selectedAction == 'APPROVE',
                            selectedColor: AppColors.success,
                            onSelected: (val) {
                              if (val) setModalState(() => selectedAction = 'APPROVE');
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Request Revision'),
                            selected: selectedAction == 'REQUEST_REVISION',
                            selectedColor: AppColors.error,
                            onSelected: (val) {
                              if (val) setModalState(() => selectedAction = 'REQUEST_REVISION');
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: noteController,
                      style: const TextStyle(color: Colors.white),
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Approval Note / Feedback Comments',
                        labelStyle: const TextStyle(color: AppColors.textSecondary),
                        hintText: selectedAction == 'APPROVE'
                            ? 'Approved for execution'
                            : 'Please update kitchen dimensions and electrical placement',
                        hintStyle: const TextStyle(color: Colors.white30),
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedAction == 'APPROVE' ? AppColors.success : AppColors.error,
                  ),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final success = await ref.read(designProvider.notifier).approveDesign(
                          id: d.id,
                          action: selectedAction,
                          note: noteController.text.trim(),
                        );
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(success ? 'Design status updated' : 'Failed to update design status'),
                        backgroundColor: success ? AppColors.success : AppColors.error,
                      ),
                    );
                  },
                  child: const Text('Submit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showRevisionDialog(BuildContext context, DesignModel parentDesign) {
    final messenger = ScaffoldMessenger.of(context);
    final titleController = TextEditingController(text: parentDesign.title);
    bool isMajor = false;
    PlatformFile? selectedFile;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final designState = ref.watch(designProvider);

            return AlertDialog(
              backgroundColor: AppColors.surface,
              title: Text('Upload Revision for ${parentDesign.version}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Revision Title',
                        labelStyle: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // File Picker Button
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      ),
                      icon: const Icon(Icons.attach_file_rounded, color: AppColors.primary),
                      label: Text(
                        selectedFile != null ? selectedFile!.name : 'Choose File (PDF, PNG, JPG, DWG, DXF)',
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                      onPressed: () async {
                        final result = await FilePicker.platform.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg', 'dwg', 'dxf'],
                        );
                        if (result != null && result.files.isNotEmpty) {
                          final file = result.files.first;
                          // 25MB check (25 * 1024 * 1024 = 26214400 bytes)
                          if (file.size > 26214400) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('FILE_TOO_LARGE: File exceeds maximum allowed size of 25MB'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                            return;
                          }
                          setModalState(() => selectedFile = file);
                        }
                      },
                    ),
                    if (selectedFile != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Size: ${(selectedFile!.size / (1024 * 1024)).toStringAsFixed(2)} MB',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                      ),
                    ],
                    const SizedBox(height: 16),
                    CheckboxListTile(
                      activeColor: AppColors.primary,
                      title: const Text('Major Version Increment',
                          style: TextStyle(color: Colors.white, fontSize: 14)),
                      subtitle: const Text('Check for major rework (e.g. v2.0). Default is minor (e.g. v1.1).',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                      value: isMajor,
                      onChanged: (val) {
                        setModalState(() => isMajor = val ?? false);
                      },
                    ),
                    if (designState.isUploading) ...[
                      const SizedBox(height: 16),
                      LinearProgressIndicator(
                        value: designState.uploadProgress > 0 ? designState.uploadProgress : null,
                        color: AppColors.primary,
                        backgroundColor: AppColors.surfaceLight,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Uploading revision... ${(designState.uploadProgress * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(color: AppColors.primary, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: designState.isUploading ? null : () => Navigator.pop(ctx),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
                  onPressed: designState.isUploading
                      ? null
                      : () async {
                          if (selectedFile == null) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Please select a file to upload revision'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                            return;
                          }
                          final success = await ref.read(designProvider.notifier).uploadRevision(
                                parentId: parentDesign.id,
                                title: titleController.text.trim(),
                                pickedFile: selectedFile,
                                isMajorVersion: isMajor,
                              );
                          if (context.mounted) Navigator.pop(ctx);
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(success ? 'New design revision uploaded' : (ref.read(designProvider).errorMessage ?? 'Failed to upload revision')),
                              backgroundColor: success ? AppColors.success : AppColors.error,
                            ),
                          );
                        },
                  child: const Text('Upload Revision', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDetailDialog(BuildContext context, DesignModel d) async {
    final details = await ref.read(designProvider.notifier).getDesignDetails(d.id);
    if (!mounted) return;

    final historyLogs = (details?['approvalHistory'] as List<DesignApprovalLogModel>?) ?? d.approvalLogs;
    final revisionsList = (details?['revisions'] as List<DesignModel>?) ?? [];

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: Row(
            children: [
              Expanded(
                child: Text(d.title,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              StatusBadge(status: d.approvalStatus),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Project: ${d.projectName.isNotEmpty ? d.projectName : d.projectId}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  Text('Category: ${d.category.replaceAll('_', ' ')} • Version: ${d.version}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  Text('Uploaded by: ${d.uploadedBy} on ${d.date}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  const SizedBox(height: 16),
                  const Text('Approval History & Audit Trail:',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  historyLogs.isEmpty
                      ? const Text('No approval notes recorded yet.',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 12))
                      : Column(
                          children: historyLogs.map((log) {
                            return Card(
                              color: AppColors.background,
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                dense: true,
                                title: Text(
                                  '${log.action == 'APPROVE' ? 'Approved' : 'Revision Requested'} by ${log.actorName ?? 'User'}',
                                  style: TextStyle(
                                    color: log.action == 'APPROVE' ? AppColors.success : AppColors.error,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(log.note ?? '', style: const TextStyle(color: Colors.white70)),
                                trailing: Text(log.createdAt, style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
                              ),
                            );
                          }).toList(),
                        ),
                  if (revisionsList.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text('Revision Chain:',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    Column(
                      children: revisionsList.map((rev) {
                        return ListTile(
                          dense: true,
                          title: Text('${rev.version} - ${rev.title}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          subtitle: Text('Status: ${rev.approvalStatus} • ${rev.date}',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                          trailing: IconButton(
                            icon: const Icon(Icons.download_rounded, size: 18, color: AppColors.primary),
                            onPressed: () => _handleDownload(context, rev),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close', style: TextStyle(color: AppColors.primary)),
            ),
          ],
        );
      },
    );
  }

  void _showUploadDialog(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final projectController = TextEditingController(text: widget.projectId ?? 'PRJ-101');
    String selectedCategory = 'THREE_D_RENDER';
    String selectedFileType = 'PDF';
    PlatformFile? selectedFile;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final designState = ref.watch(designProvider);

            return AlertDialog(
              backgroundColor: AppColors.surface,
              title: const Text('Upload Design Drawing',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: titleController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Design Title *',
                          labelStyle: TextStyle(color: AppColors.textSecondary),
                          hintText: 'e.g. Master Bedroom 3D Layout',
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Title is required';
                          if (v.trim().length < 2 || v.trim().length > 150) {
                            return 'Title must be between 2 and 150 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: projectController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Project ID *',
                          labelStyle: TextStyle(color: AppColors.textSecondary),
                          hintText: 'e.g. PRJ-101',
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Project ID is required' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: selectedCategory,
                        dropdownColor: AppColors.surface,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          labelStyle: TextStyle(color: AppColors.textSecondary),
                        ),
                        items: ['THREE_D_RENDER', 'FLOOR_PLAN', 'CAD_DRAWING', 'ELEVATION', 'OTHER']
                            .map((cat) => DropdownMenuItem(
                                  value: cat,
                                  child: Text(cat.replaceAll('_', ' ')),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setModalState(() => selectedCategory = val);
                        },
                      ),
                      const SizedBox(height: 16),
                      // File Picker Section per FC-010 §4 & §9
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.primary),
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        ),
                        icon: const Icon(Icons.attach_file_rounded, color: AppColors.primary),
                        label: Text(
                          selectedFile != null ? selectedFile!.name : 'Choose File * (PDF, PNG, JPG, DWG, DXF)',
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                        onPressed: () async {
                          final result = await FilePicker.platform.pickFiles(
                            type: FileType.custom,
                            allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg', 'dwg', 'dxf'],
                          );
                          if (result != null && result.files.isNotEmpty) {
                            final file = result.files.first;
                            // 25MB limit check (25 * 1024 * 1024 = 26214400 bytes)
                            if (file.size > 26214400) {
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('FILE_TOO_LARGE: File exceeds maximum allowed size of 25MB'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                              return;
                            }
                            setModalState(() {
                              selectedFile = file;
                              final ext = file.name.split('.').last.toLowerCase();
                              if (ext == 'pdf') {
                                selectedFileType = 'PDF';
                              } else if (['png', 'jpg', 'jpeg'].contains(ext)) {
                                selectedFileType = 'IMAGE';
                              } else if (['dwg', 'dxf'].contains(ext)) {
                                selectedFileType = 'CAD';
                              }
                            });
                          }
                        },
                      ),
                      if (selectedFile != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Selected: ${selectedFile!.name} (${(selectedFile!.size / (1024 * 1024)).toStringAsFixed(2)} MB)',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                        ),
                      ],
                      if (designState.isUploading) ...[
                        const SizedBox(height: 16),
                        LinearProgressIndicator(
                          value: designState.uploadProgress > 0 ? designState.uploadProgress : null,
                          color: AppColors.primary,
                          backgroundColor: AppColors.surfaceLight,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Uploading drawing... ${(designState.uploadProgress * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(color: AppColors.primary, fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: designState.isUploading ? null : () => Navigator.pop(ctx),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  onPressed: designState.isUploading
                      ? null
                      : () async {
                          if (formKey.currentState!.validate()) {
                            if (selectedFile == null) {
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Please select a file to upload'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                              return;
                            }

                            final success = await ref.read(designProvider.notifier).uploadDesign(
                                  title: titleController.text.trim(),
                                  projectId: projectController.text.trim(),
                                  category: selectedCategory,
                                  fileType: selectedFileType,
                                  fileSize: '${(selectedFile!.size / (1024 * 1024)).toStringAsFixed(1)} MB',
                                  pickedFile: selectedFile,
                                );
                            if (context.mounted) Navigator.pop(ctx);
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(success ? 'Design uploaded successfully' : (ref.read(designProvider).errorMessage ?? 'Failed to upload design')),
                                backgroundColor: success ? AppColors.success : AppColors.error,
                              ),
                            );
                          }
                        },
                  child: const Text('Upload', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
