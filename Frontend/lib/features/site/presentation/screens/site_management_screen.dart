import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/app_drawer_sidebar.dart';
import '../../domain/models/site_update_model.dart';

class SiteManagementScreen extends StatefulWidget {
  const SiteManagementScreen({super.key});

  @override
  State<SiteManagementScreen> createState() => _SiteManagementScreenState();
}

class _SiteManagementScreenState extends State<SiteManagementScreen> {
  final List<SiteUpdateModel> _siteUpdates = [
    SiteUpdateModel(
      id: 'SU-501',
      projectName: 'Villa Royale Interior Renovation',
      supervisorName: 'Tom Supervisor',
      updateDate: '2026-03-12',
      description: 'Completed Italian Marble flooring installation in Living Room. Drywall prep ongoing.',
      issueReported: 'None',
      photosAttached: true,
    ),
    SiteUpdateModel(
      id: 'SU-502',
      projectName: 'TechHub Open Plan Office',
      supervisorName: 'Tom Supervisor',
      updateDate: '2026-03-10',
      description: 'Ceiling wiring finished. Awaiting acoustic panel shipment.',
      issueReported: 'Minor delay in panel delivery from vendor.',
      photosAttached: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Site Work & Daily Reports', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      drawer: const AppDrawerSidebar(currentRoute: '/site'),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_a_photo_outlined, color: Colors.white),
        label: const Text('Add Site Update', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Add Site Update & Upload Photos dialog opened'), backgroundColor: AppColors.primary),
          );
        },
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: _siteUpdates.length,
        itemBuilder: (context, index) {
          final su = _siteUpdates[index];
          return Card(
            color: AppColors.surface,
            margin: const EdgeInsets.only(bottom: 14),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(su.projectName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(su.updateDate, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('Supervisor: ${su.supervisorName}', style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(su.description, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.4)),
                  if (su.issueReported != 'None') ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text('Issue: ${su.issueReported}', style: const TextStyle(color: AppColors.warning, fontSize: 12))),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
