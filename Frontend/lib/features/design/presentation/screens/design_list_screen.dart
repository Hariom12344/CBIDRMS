import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/app_drawer_sidebar.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/models/design_model.dart';

class DesignListScreen extends StatefulWidget {
  const DesignListScreen({super.key});

  @override
  State<DesignListScreen> createState() => _DesignListScreenState();
}

class _DesignListScreenState extends State<DesignListScreen> {
  final List<DesignModel> _designs = [
    DesignModel(id: 'DSG-01', title: 'Master Bedroom 3D Layout', projectName: 'Villa Royale', version: 'v2.1', approvalStatus: 'Approved', uploadedBy: 'Sarah Designer', date: '2026-02-18'),
    DesignModel(id: 'DSG-02', title: 'Kitchen Cabinetry CAD Drawing', projectName: 'Penthouse Suite', version: 'v1.0', approvalStatus: 'Revision Needed', uploadedBy: 'Sarah Designer', date: '2026-03-01'),
    DesignModel(id: 'DSG-03', title: 'Ceiling Lighting & False Ceiling Blueprint', projectName: 'TechHub Office', version: 'v1.4', approvalStatus: 'Pending', uploadedBy: 'Michael PM', date: '2026-03-12'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Design Management & Drawings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      drawer: const AppDrawerSidebar(currentRoute: '/design'),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.upload_file, color: Colors.white),
        label: const Text('Upload Drawing', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Upload design drawing modal opened'), backgroundColor: AppColors.primary),
          );
        },
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: _designs.length,
        itemBuilder: (context, index) {
          final d = _designs[index];
          return Card(
            color: AppColors.surface,
            margin: const EdgeInsets.only(bottom: 14),
            child: ListTile(
              contentPadding: const EdgeInsets.all(18),
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.draw_outlined, color: AppColors.primary),
              ),
              title: Text(d.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text('Project: ${d.projectName} • ${d.version} • Uploaded by ${d.uploadedBy}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 6),
                  Text('Uploaded Date: ${d.date}', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  StatusBadge(status: d.approvalStatus),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
