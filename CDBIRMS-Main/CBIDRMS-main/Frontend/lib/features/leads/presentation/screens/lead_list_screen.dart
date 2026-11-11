import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/app_drawer_sidebar.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/lead_provider.dart';

class LeadListScreen extends ConsumerStatefulWidget {
  const LeadListScreen({super.key});

  @override
  ConsumerState<LeadListScreen> createState() => _LeadListScreenState();
}

class _LeadListScreenState extends ConsumerState<LeadListScreen> {
  String? _convertingLeadId;
  String? _deletingLeadId;
  final TextEditingController _searchController = TextEditingController();

  final List<String> _statusFilters = [
    'All',
    'New',
    'Contacted',
    'Meeting Scheduled',
    'Proposal Sent',
    'Won',
    'Lost',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(leadsNotifierProvider.notifier).fetchLeads();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final leadsState = ref.watch(leadsNotifierProvider);
    final authState = ref.watch(authNotifierProvider);
    final isAdmin = authState.user?.role.toUpperCase() == 'ADMIN';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text(
          'Lead Pipeline (Sales/CRM)',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refresh Pipeline',
            onPressed: () => ref.read(leadsNotifierProvider.notifier).fetchLeads(),
          )
        ],
      ),
      drawer: const AppDrawerSidebar(currentRoute: '/leads'),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.person_add_alt_outlined, color: Colors.white),
        label: const Text('Create Lead', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () => context.push('/leads/create'),
      ),
      body: Column(
        children: [
          _buildFilterBar(leadsState),
          Expanded(child: _buildBody(leadsState, isAdmin)),
        ],
      ),
    );
  }

  Widget _buildFilterBar(LeadsState state) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        children: [
          // Search Input
          TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search by client name, Lead ID, property...',
              hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
              prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: AppColors.textMuted),
                      onPressed: () {
                        _searchController.clear();
                        ref.read(leadsNotifierProvider.notifier).setSearchQuery('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppColors.background,
              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (val) => ref.read(leadsNotifierProvider.notifier).setSearchQuery(val),
          ),
          const SizedBox(height: 10),

          // Horizontal Status Filter Chips
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _statusFilters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final filter = _statusFilters[index];
                final isSelected = state.selectedStatusFilter == filter;

                return ChoiceChip(
                  label: Text(
                    filter,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.background,
                  showCheckmark: false,
                  onSelected: (selected) {
                    if (selected) {
                      ref.read(leadsNotifierProvider.notifier).setStatusFilter(filter);
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(LeadsState state, bool isAdmin) {
    if (state.isLoading) {
      return const LoadingWidget(message: 'Loading Lead Pipeline...');
    }

    if (state.errorMessage != null && state.leads.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                state.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text('Retry', style: TextStyle(color: Colors.white)),
                onPressed: () => ref.read(leadsNotifierProvider.notifier).fetchLeads(),
              )
            ],
          ),
        ),
      );
    }

    final filteredList = state.filteredLeads;

    if (filteredList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.filter_alt_off_outlined, color: AppColors.textMuted, size: 44),
            const SizedBox(height: 12),
            const Text(
              'No leads found matching criteria.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 14),
            ),
            if (state.selectedStatusFilter != 'All' || state.searchQuery.isNotEmpty)
              TextButton(
                onPressed: () {
                  _searchController.clear();
                  ref.read(leadsNotifierProvider.notifier).setSearchQuery('');
                  ref.read(leadsNotifierProvider.notifier).setStatusFilter('All');
                },
                child: const Text('Reset Filters', style: TextStyle(color: AppColors.primary)),
              ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(leadsNotifierProvider.notifier).fetchLeads(),
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredList.length,
        itemBuilder: (context, index) {
          final lead = filteredList[index];
          final isThisLeadConverting = _convertingLeadId == lead.id && state.isMutating;
          final isThisLeadDeleting = _deletingLeadId == lead.id && state.isMutating;
          final isConverted = lead.isConverted;

          return Card(
            color: AppColors.surface,
            margin: const EdgeInsets.only(bottom: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isConverted ? AppColors.success.withValues(alpha: 0.4) : Colors.white10,
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Lead ID, Client Name, and Status Badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          lead.id,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          lead.clientName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      StatusBadge(status: lead.status),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Middle Info
                  Text(
                    '${lead.propertyType.isNotEmpty ? lead.propertyType : "Residential"} • Est. Budget: ₹${lead.estimatedBudget.toStringAsFixed(0)}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Phone: ${lead.phone.isNotEmpty ? lead.phone : "N/A"} • Assigned: ${lead.assignedTo}',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 14),

                  // Bottom Action Buttons Row
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                      // View / Edit Details Button
                      TextButton.icon(
                        style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                        icon: const Icon(Icons.info_outline, size: 16),
                        label: Text(
                          isConverted ? 'View Details' : 'Edit / Details',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {
                          context.push('/leads/details', extra: lead);
                        },
                      ),

                      Row(
                        children: [
                          // Admin Delete Button
                          if (isAdmin && !isConverted)
                            IconButton(
                              icon: isThisLeadDeleting
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red),
                                    )
                                  : const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                              tooltip: 'Delete Lead',
                              onPressed: state.isMutating || isThisLeadDeleting
                                  ? null
                                  : () async {
                                      final messenger = ScaffoldMessenger.of(context);
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          backgroundColor: AppColors.surface,
                                          title: const Text('Delete Lead', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                          content: Text(
                                            'Are you sure you want to delete lead "${lead.clientName}" (${lead.id})?',
                                            style: const TextStyle(color: AppColors.textSecondary),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(ctx, false),
                                              child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
                                            ),
                                            TextButton(
                                              style: TextButton.styleFrom(foregroundColor: Colors.red),
                                              onPressed: () => Navigator.pop(ctx, true),
                                              child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (confirm == true) {
                                        setState(() => _deletingLeadId = lead.id);
                                        final success = await ref.read(leadsNotifierProvider.notifier).deleteLead(
                                              leadId: lead.id,
                                            );
                                        if (mounted) {
                                          setState(() => _deletingLeadId = null);
                                        }
                                        if (success) {
                                          messenger.showSnackBar(
                                            SnackBar(content: Text('Lead ${lead.id} deleted successfully!'), backgroundColor: Colors.green.shade600),
                                          );
                                        } else {
                                          final err = ref.read(leadsNotifierProvider).errorMessage ?? 'Failed to delete lead';
                                          messenger.showSnackBar(
                                            SnackBar(content: Text(err), backgroundColor: Colors.red.shade600),
                                          );
                                        }
                                      }
                                    },
                            ),

                          const SizedBox(width: 8),

                          // Convert to Project / Converted Button
                          if (isConverted)
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: AppColors.success.withValues(alpha: 0.4)),
                              ),
                              icon: const Icon(Icons.check_circle_outline, color: AppColors.success, size: 16),
                              label: const Text(
                                'Converted to Project',
                                style: TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              onPressed: null,
                            )
                          else
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.success,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              ),
                              icon: isThisLeadConverting
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.transform, color: Colors.white, size: 16),
                              label: Text(
                                isThisLeadConverting ? 'Converting...' : 'Convert to Project',
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              onPressed: state.isMutating
                                  ? null
                                  : () async {
                                      final messenger = ScaffoldMessenger.of(context);
                                      final nav = GoRouter.of(context);
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          backgroundColor: AppColors.surface,
                                          title: const Text('Convert Lead to Project', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                          content: Text(
                                            'Are you sure you want to convert the lead for "${lead.clientName}" into an active Project? This will set status to Won and lock lead editing.',
                                            style: const TextStyle(color: AppColors.textSecondary),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(ctx, false),
                                              child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
                                            ),
                                            TextButton(
                                              style: TextButton.styleFrom(foregroundColor: AppColors.success),
                                              onPressed: () => Navigator.pop(ctx, true),
                                              child: const Text('Convert', style: TextStyle(fontWeight: FontWeight.bold)),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (confirm == true) {
                                        setState(() => _convertingLeadId = lead.id);
                                        final project = await ref.read(leadsNotifierProvider.notifier).convertLeadToProject(
                                              leadId: lead.id,
                                            );
                                        if (mounted) {
                                          setState(() => _convertingLeadId = null);
                                        }
                                        if (project != null) {
                                          messenger.showSnackBar(
                                            SnackBar(content: const Text('Lead converted into active project!'), backgroundColor: Colors.green.shade600),
                                          );
                                          nav.push('/projects/details', extra: project);
                                        } else {
                                          final err = ref.read(leadsNotifierProvider).errorMessage ?? 'Failed to convert lead';
                                          messenger.showSnackBar(
                                            SnackBar(content: Text(err), backgroundColor: Colors.red.shade600),
                                          );
                                        }
                                      }
                                    },
                            ),
                        ],
                      ),
                    ],
                  ),
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
