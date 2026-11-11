import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/app_drawer_sidebar.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../domain/models/project_model.dart';
import '../providers/project_provider.dart';

class ProjectListScreen extends ConsumerStatefulWidget {
  const ProjectListScreen({super.key});


  @override
  ConsumerState<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends ConsumerState<ProjectListScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(projectNotifierProvider.notifier).fetchProjects();
    });
  }

  @override
  Widget build(BuildContext context) {
    final projectsState = ref.watch(projectNotifierProvider);

    final filteredProjects = projectsState.projects.where((p) {
      final matchesSearch = p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.clientName.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesFilter = _selectedFilter == 'ALL' || p.status == _selectedFilter;
      return matchesSearch && matchesFilter;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Project Management', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => ref.read(projectNotifierProvider.notifier).fetchProjects(),
          )
        ],
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
              child: _buildProjectList(projectsState, filteredProjects),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectList(ProjectsState state, List<ProjectModel> filteredList) {
    if (state.isLoading) {
      return const LoadingWidget(message: 'Loading Projects...');
    }

    if (state.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 40),
            const SizedBox(height: 12),
            Text(state.errorMessage!, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () => ref.read(projectNotifierProvider.notifier).fetchProjects(),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      );
    }

    if (filteredList.isEmpty) {
      return const Center(
        child: Text('No projects found', style: TextStyle(color: AppColors.textMuted)),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(projectNotifierProvider.notifier).fetchProjects(),
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      child: ListView.builder(
        itemCount: filteredList.length,
        itemBuilder: (context, index) {
          final project = filteredList[index];
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
                        Expanded(
                          child: Text(
                            project.name,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(width: 8),
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
                        Text('Budget: ₹${project.budget.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
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
    );
  }
}

