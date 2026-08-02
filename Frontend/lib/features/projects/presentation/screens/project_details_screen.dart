import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/models/project_model.dart';

class ProjectDetailsScreen extends StatelessWidget {
  final ProjectModel? project;

  const ProjectDetailsScreen({super.key, this.project});

  @override
  Widget build(BuildContext context) {
    final p = project ??
        ProjectModel(
          id: 'PRJ-101',
          name: 'Villa Royale Interior Renovation',
          clientName: 'Robert Vance',
          designerName: 'Sarah Jenkins',
          startDate: '2026-01-15',
          endDate: '2026-08-30',
          budget: 125000,
          status: 'ONGOING',
          progress: 0.65,
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                        StatusBadge(status: p.status),
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
                    _buildRow(Icons.attach_money_rounded, 'Total Budget', '\$${p.budget.toStringAsFixed(2)}', color: AppColors.success),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('COMPLETION PROGRESS', style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
            const SizedBox(height: 12),
            Card(
              color: AppColors.surface,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Overall Status', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        Text('${(p.progress * 100).toInt()}%', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(value: p.progress, minHeight: 8, backgroundColor: AppColors.surfaceLight, color: AppColors.primary),
                  ],
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
