import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/app_drawer_sidebar.dart';
import '../../../projects/presentation/providers/project_provider.dart';
import '../../domain/models/document_model.dart';
import '../providers/document_provider.dart';

class DocumentListScreen extends ConsumerStatefulWidget {
  final String? projectId;
  const DocumentListScreen({super.key, this.projectId});

  @override
  ConsumerState<DocumentListScreen> createState() => _DocumentListScreenState();
}

class _DocumentListScreenState extends ConsumerState<DocumentListScreen> {
  final TextEditingController _searchController = TextEditingController();

  static const List<String> _categories = [
    'ALL',
    'CONTRACT',
    'FLOOR_PLAN',
    'INVOICE',
    'REFERENCE',
    'OTHER',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(projectNotifierProvider.notifier).fetchProjects();
      if (widget.projectId != null) {
        ref.read(documentProvider.notifier).setProject(widget.projectId);
      } else {
        ref.read(documentProvider.notifier).fetchDocuments();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(documentProvider);
    final notifier = ref.read(documentProvider.notifier);
    final projectState = ref.watch(projectNotifierProvider);
    final projects = projectState.projects;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          widget.projectId != null ? 'Project Documents (${widget.projectId})' : 'Document Management',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: () => notifier.fetchDocuments(),
          ),
        ],
      ),
      drawer: widget.projectId == null ? const AppDrawerSidebar(currentRoute: '/documents') : null,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.upload_file_rounded, color: Colors.white),
        label: const Text('Upload Document', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () => _showUploadDialog(context),
      ),
      body: Column(
        children: [
          // Filter Header Section
          Container(
            padding: const EdgeInsets.all(16.0),
            color: AppColors.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Project Selector Dropdown Row (if global view)
                if (widget.projectId == null) ...[
                  Row(
                    children: [
                      const Icon(Icons.folder_special_outlined, color: AppColors.textMuted, size: 18),
                      const SizedBox(width: 8),
                      const Text('Filter Project:', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String?>(
                            value: state.selectedProjectId,
                            dropdownColor: AppColors.surface,
                            isExpanded: true,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            items: [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text('All Projects', style: TextStyle(color: AppColors.primary), overflow: TextOverflow.ellipsis),
                              ),
                              ...projects.map((p) => DropdownMenuItem<String?>(
                                value: p.id,
                                child: Text('${p.id} - ${p.name}', overflow: TextOverflow.ellipsis),
                              )),
                            ],
                            onChanged: (val) {
                              notifier.setProject(val);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],

                // Search Bar
                TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search documents by title...',
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
                  onChanged: (val) {
                    notifier.setSearchQuery(val);
                  },
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

          // Content List / Loading / Empty State
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : state.documents.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.folder_off_outlined, size: 64, color: AppColors.textSecondary),
                            const SizedBox(height: 16),
                            const Text(
                              'No documents found',
                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              state.searchQuery.isNotEmpty || state.selectedCategory != 'ALL'
                                  ? 'Try broadening your search or filter'
                                  : 'Tap "Upload Document" to add your first file',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => notifier.fetchDocuments(),
                        color: AppColors.primary,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: state.documents.length,
                          itemBuilder: (context, index) {
                            final doc = state.documents[index];
                            return _buildDocumentCard(context, doc);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentCard(BuildContext context, DocumentModel doc) {
    IconData iconData = Icons.insert_drive_file_outlined;
    Color iconColor = AppColors.primary;

    if (doc.fileType == 'PDF') {
      iconData = Icons.picture_as_pdf_outlined;
      iconColor = AppColors.error;
    } else if (doc.fileType == 'IMAGE') {
      iconData = Icons.image_outlined;
      iconColor = AppColors.success;
    } else if (doc.fileType == 'CAD') {
      iconData = Icons.architecture_outlined;
      iconColor = AppColors.secondary;
    }

    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(iconData, color: iconColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    doc.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      doc.category.replaceAll('_', ' '),
                      style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '${doc.fileType} • ${doc.fileSize}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                    ),
                    if (doc.projectId.isNotEmpty)
                      Text(
                        '• Proj: ${doc.projectId}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                      ),
                    Text(
                      '• ${doc.uploadedAt}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Download Button
                    IconButton(
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(6),
                      icon: const Icon(Icons.download_rounded, color: AppColors.primary, size: 20),
                      tooltip: 'Download Document',
                      onPressed: () => _handleDownload(context, doc),
                    ),
                    const SizedBox(width: 8),
                    // Delete Button
                    IconButton(
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(6),
                      icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                      tooltip: 'Delete Document',
                      onPressed: () => _confirmDelete(context, doc),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleDownload(BuildContext context, DocumentModel doc) async {
    final messenger = ScaffoldMessenger.of(context);
    final res = await ref.read(documentProvider.notifier).downloadDocument(doc.id);

    if (res != null) {
      final rawUrl = res['downloadUrl'] as String? ?? doc.fileUrl ?? '';
      if (rawUrl.isNotEmpty) {
        final uri = Uri.parse(rawUrl);
        try {
          final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
          if (launched) {
            messenger.showSnackBar(
              SnackBar(
                content: Text('Downloading ${doc.title}...'),
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
              content: Text('Downloading ${doc.title}...'),
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

  void _confirmDelete(BuildContext context, DocumentModel doc) {
    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Document?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete "${doc.title}"? This action cannot be undone.',
            style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await ref.read(documentProvider.notifier).deleteDocument(doc.id);
              messenger.showSnackBar(
                SnackBar(
                  content: Text(success ? 'Document deleted successfully' : 'Failed to delete document'),
                  backgroundColor: success ? AppColors.success : AppColors.error,
                ),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showUploadDialog(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    
    final projects = ref.read(projectNotifierProvider).projects;
    String selectedProjectId = widget.projectId ?? (projects.isNotEmpty ? projects.first.id : 'PRJ-101');
    String selectedCategory = 'CONTRACT';
    String selectedFileType = 'PDF';
    String estimatedSize = '1.0 MB';
    PlatformFile? pickedFile;
    bool isUploading = false;
    String? dialogError;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> pickFile() async {
              try {
                final result = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg', 'dwg', 'dxf', 'docx', 'xlsx'],
                  withData: true,
                );

                if (result != null && result.files.isNotEmpty) {
                  final file = result.files.first;

                  if (file.size > 25 * 1024 * 1024) {
                    setModalState(() {
                      dialogError = 'File exceeds maximum allowed size of 25MB';
                    });
                    return;
                  }

                  final ext = (file.extension ?? '').toLowerCase();
                  String ft = 'PDF';
                  if (['png', 'jpg', 'jpeg'].contains(ext)) {
                    ft = 'IMAGE';
                  } else if (['dwg', 'dxf'].contains(ext)) {
                    ft = 'CAD';
                  } else if (['docx', 'xlsx'].contains(ext)) {
                    ft = 'OTHER';
                  }

                  final sizeMb = (file.size / (1024 * 1024)).toStringAsFixed(1);

                  setModalState(() {
                    pickedFile = file;
                    if (titleController.text.trim().isEmpty) {
                      titleController.text = file.name;
                    }
                    selectedFileType = ft;
                    estimatedSize = '$sizeMb MB';
                    dialogError = null;
                  });
                }
              } catch (e) {
                setModalState(() {
                  dialogError = 'Failed to pick file: $e';
                });
              }
            }

            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.upload_file_rounded, color: AppColors.primary),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text('Upload Project Document', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  ),
                ],
              ),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (dialogError != null) ...[
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
                                Expanded(child: Text(dialogError!, style: const TextStyle(color: AppColors.error, fontSize: 13))),
                              ],
                            ),
                          ),
                        ],

                        // Project Selector
                        const Text('PROJECT *', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: selectedProjectId,
                          dropdownColor: AppColors.surface,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: AppColors.surfaceLight,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          items: projects.isEmpty
                              ? [DropdownMenuItem(value: selectedProjectId, child: Text(selectedProjectId))]
                              : projects.map((p) => DropdownMenuItem(value: p.id, child: Text('${p.id} - ${p.name}'))).toList(),
                          onChanged: (val) {
                            if (val != null) setModalState(() => selectedProjectId = val);
                          },
                        ),
                        const SizedBox(height: 16),

                        // Document Title
                        TextFormField(
                          controller: titleController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Document Title *',
                            labelStyle: const TextStyle(color: AppColors.textSecondary),
                            hintText: 'e.g. Architectural Floorplan v2.pdf',
                            hintStyle: const TextStyle(color: Colors.white30),
                            filled: true,
                            fillColor: AppColors.surfaceLight,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Title is required' : null,
                        ),
                        const SizedBox(height: 16),

                        // Category Dropdown
                        const Text('CATEGORY *', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: selectedCategory,
                          dropdownColor: AppColors.surface,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: AppColors.surfaceLight,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          ),
                          items: ['CONTRACT', 'FLOOR_PLAN', 'INVOICE', 'REFERENCE', 'OTHER']
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

                        // File Picker Button
                        const Text('SELECT FILE (Max 25MB)', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.primary, width: 1.5),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.attach_file_rounded, size: 20),
                            label: Text(
                              pickedFile != null ? 'Selected: ${pickedFile!.name}' : 'Choose File from Device / Browser',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                            onPressed: pickFile,
                          ),
                        ),

                        if (pickedFile != null) ...[
                          const SizedBox(height: 8),
                          Text('Type: $selectedFileType • Size: $estimatedSize', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isUploading ? null : () => Navigator.pop(ctx),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  onPressed: isUploading
                      ? null
                      : () async {
                          if (formKey.currentState!.validate()) {
                            setModalState(() => isUploading = true);
                            final success = await ref.read(documentProvider.notifier).uploadDocument(
                                  title: titleController.text.trim(),
                                  projectId: selectedProjectId,
                                  category: selectedCategory,
                                  fileType: selectedFileType,
                                  fileSize: estimatedSize,
                                  pickedFile: pickedFile,
                                );
                            setModalState(() => isUploading = false);

                            if (success) {
                              if (ctx.mounted) Navigator.pop(ctx);
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Document uploaded successfully'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            } else {
                              final err = ref.read(documentProvider).errorMessage ?? 'Failed to upload document';
                              setModalState(() {
                                dialogError = err;
                              });
                            }
                          }
                        },
                  child: isUploading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Upload', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
