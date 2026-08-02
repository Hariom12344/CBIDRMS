import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/app_drawer_sidebar.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/models/lead_model.dart';

class LeadListScreen extends StatefulWidget {
  const LeadListScreen({super.key});

  @override
  State<LeadListScreen> createState() => _LeadListScreenState();
}

class _LeadListScreenState extends State<LeadListScreen> {
  final List<LeadModel> _leads = [
    LeadModel(id: 'LD-101', clientName: 'Alexander Hayes', phone: '+1 555-0321', email: 'alex@hayes.io', status: 'Proposal Sent', propertyType: '3BHK Modern Flat', estimatedBudget: 65000, assignedTo: 'Sarah PM'),
    LeadModel(id: 'LD-102', clientName: 'Samantha Reed', phone: '+1 555-0812', email: 'sam@reeddesign.com', status: 'Meeting Scheduled', propertyType: 'Penthouse Villa', estimatedBudget: 150000, assignedTo: 'Michael PM'),
    LeadModel(id: 'LD-103', clientName: 'Urban Cafe Corp', phone: '+1 555-0994', email: 'info@urbancafe.com', status: 'New', propertyType: 'Commercial Bistro', estimatedBudget: 90000, assignedTo: 'Unassigned'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Lead Pipeline', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      drawer: const AppDrawerSidebar(currentRoute: '/leads'),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.person_add_alt_outlined, color: Colors.white),
        label: const Text('Create Lead', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () => context.push('/leads/create'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: _leads.length,
        itemBuilder: (context, index) {
          final lead = _leads[index];
          return Card(
            color: AppColors.surface,
            margin: const EdgeInsets.only(bottom: 14),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(lead.clientName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      StatusBadge(status: lead.status),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('${lead.propertyType} • Est. Budget: \$${lead.estimatedBudget.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text('Contact: ${lead.phone} • Assigned: ${lead.assignedTo}', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.success)),
                        icon: const Icon(Icons.transform, color: AppColors.success, size: 16),
                        label: const Text('Convert to Project', style: TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.bold)),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Converted ${lead.clientName} lead into active Project!'), backgroundColor: AppColors.success),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
