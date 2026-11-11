import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/app_drawer_sidebar.dart';
import '../../domain/models/document_model.dart';

class DocumentListScreen extends StatefulWidget {
  const DocumentListScreen({super.key});

  @override
  State<DocumentListScreen> createState() => _DocumentListScreenState();
}

class _DocumentListScreenState extends State<DocumentListScreen> {
  final List<DocumentModel> _docs = [
    DocumentModel(id: 'DOC-01', title: 'Villa Royale Architectural Floorplan.pdf', fileType: 'PDF', fileSize: '4.2 MB', uploadedAt: '2026-02-01'),
    DocumentModel(id: 'DOC-02', title: 'Living Room 3D Render HighRes.png', fileType: 'IMAGE', fileSize: '8.7 MB', uploadedAt: '2026-02-14'),
    DocumentModel(id: 'DOC-03', title: 'Electrical & Plumbing CAD Schematic.dwg', fileType: 'CAD', fileSize: '14.1 MB', uploadedAt: '2026-03-02'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Document Management', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      drawer: const AppDrawerSidebar(currentRoute: '/documents'),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.upload_file_rounded, color: Colors.white),
        label: const Text('Upload Document', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Document upload dialog opened'), backgroundColor: AppColors.primary),
          );
        },
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: _docs.length,
        itemBuilder: (context, index) {
          final doc = _docs[index];
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
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: iconColor.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                child: Icon(iconData, color: iconColor),
              ),
              title: Text(doc.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              subtitle: Text('${doc.fileType} • ${doc.fileSize} • Uploaded: ${doc.uploadedAt}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              trailing: IconButton(
                icon: const Icon(Icons.download_rounded, color: AppColors.primary),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Downloading ${doc.title}...'), backgroundColor: AppColors.success),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
