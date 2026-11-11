import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/app_drawer_sidebar.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/models/project_model.dart';

class ProjectListScreen extends StatefulWidget {
  const ProjectListScreen({super.key});

  @override
  State<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends State<ProjectListScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'ALL';

  final List<ProjectModel> _mockProjects = [
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
    ),
    ProjectModel(
      id: 'PRJ-102',
      name: 'TechHub Open Plan Office',
      clientName: 'Apex Innovations',
      designerName: 'Michael Chen',
      startDate: '2026-03-01',
      endDate: '2026-11-15',
      budget: 85000,
      status: 'PLANNING',
      progress: 0.20,
    ),
    ProjectModel(
      id: 'PRJ-103',
      name: 'Ocean View Penthouse Suite',
      clientName: 'Elena Rostova',
      designerName: 'Sarah Jenkins',
      startDate: '2025-06-01',
      endDate: '2026-02-10',
      budget: 210000,
      status: 'COMPLETED',
      progress: 1.0,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final filteredProjects = _mockProjects.where((p) {
      final matchesSearch = p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.clientName.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesFilter = _selectedFilter == 'ALL' || p.status == _selectedFilter;
      return matchesSearch && matchesFilter;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Project Management', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      drawer: const AppDrawerSidebar(currentRoute: '/projects'),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Project', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () => context.push('/projects/create'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Search projects or clients...',
                      prefixIcon: Icon(Icons.search, color: AppColors.textMuted),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _selectedFilter,
                  dropdownColor: AppColors.surface,
                  style: const TextStyle(color: Colors.white),
                  items: const [
                    DropdownMenuItem(value: 'ALL', child: Text('All Status')),
                    DropdownMenuItem(value: 'PLANNING', child: Text('Planning')),
                    DropdownMenuItem(value: 'ONGOING', child: Text('Ongoing')),
                    DropdownMenuItem(value: 'COMPLETED', child: Text('Completed')),
                    DropdownMenuItem(value: 'CANCELLED', child: Text('Cancelled')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedFilter = val);
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: filteredProjects.isEmpty
                  ? const Center(child: Text('No projects found', style: TextStyle(color: AppColors.textMuted)))
                  : ListView.builder(
                      itemCount: filteredProjects.length,
                      itemBuilder: (context, index) {
                        final project = filteredProjects[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 14),
                          color: AppColors.surface,
                          child: InkWell(
                            onTap: () => context.push('/projects/details', extra: project),
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        project.name,
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      StatusBadge(status: project.status),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Client: ${project.clientName} • Designer: ${project.designerName}',
                                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Budget: \$${project.budget.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                                      Text('${(project.progress * 100).toInt()}% Done', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  LinearProgressIndicator(
                                    value: project.progress,
                                    backgroundColor: AppColors.surfaceLight,
                                    color: AppColors.primary,
                                    minHeight: 6,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
