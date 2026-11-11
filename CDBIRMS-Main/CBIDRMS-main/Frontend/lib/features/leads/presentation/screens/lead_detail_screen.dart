import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/permissions/app_permissions.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/lead_model.dart';
import '../providers/lead_provider.dart';

class LeadDetailScreen extends ConsumerStatefulWidget {
  final LeadModel? lead;

  const LeadDetailScreen({super.key, this.lead});

  @override
  ConsumerState<LeadDetailScreen> createState() => _LeadDetailScreenState();
}

class _LeadDetailScreenState extends ConsumerState<LeadDetailScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _clientNameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _propertyTypeController;
  late TextEditingController _budgetController;

  late String _selectedStatus;
  bool _isConverting = false;

  final List<String> _statuses = [
    'New',
    'Contacted',
    'Meeting Scheduled',
    'Proposal Sent',
    'Won',
    'Lost'
  ];

  @override
  void initState() {
    super.initState();
    final l = widget.lead;
    _clientNameController = TextEditingController(text: l?.clientName ?? '');
    _phoneController = TextEditingController(text: l?.phone ?? '');
    _emailController = TextEditingController(text: l?.email ?? '');
    _propertyTypeController = TextEditingController(text: l?.propertyType ?? '');
    _budgetController = TextEditingController(
      text: l?.estimatedBudget != null && l!.estimatedBudget > 0
          ? l.estimatedBudget.toStringAsFixed(0)
          : '',
    );
    _selectedStatus = l?.status ?? 'New';
  }

  @override
  void dispose() {
    _clientNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _propertyTypeController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lead = widget.lead;
    if (lead == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Lead Details')),
        body: const Center(child: Text('No lead selected', style: TextStyle(color: Colors.white70))),
      );
    }

    final leadsState = ref.watch(leadsNotifierProvider);
    final user = ref.watch(authNotifierProvider).user;
    final canDelete = AppPermissions.canDeleteLeads(user?.role);

    final isConverted = lead.isConverted;
    final isReadOnly = isConverted;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text('Lead ${lead.id}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          if (canDelete && !isConverted)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              tooltip: 'Delete Lead',
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final nav = GoRouter.of(context);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: AppColors.surface,
                    title: const Text('Delete Lead', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    content: Text(
                      'Are you sure you want to delete lead "${lead.clientName}"? This action cannot be undone.',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(foregroundColor: AppColors.error),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  final success = await ref.read(leadsNotifierProvider.notifier).deleteLead(
                        leadId: lead.id,
                      );
                  if (success) {
                    messenger.showSnackBar(
                      SnackBar(content: Text('Lead ${lead.id} deleted successfully!'), backgroundColor: Colors.green.shade600),
                    );
                    nav.pop();
                  } else {
                    final err = ref.read(leadsNotifierProvider).errorMessage ?? 'Failed to delete lead';
                    messenger.showSnackBar(
                      SnackBar(content: Text(err), backgroundColor: Colors.red.shade600),
                    );
                  }
                }
              },
            ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(child: StatusBadge(status: lead.status)),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isReadOnly)
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.success),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lock_outline, color: AppColors.success),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'This lead was converted into an active Project on ${lead.updatedAt?.split('T')[0] ?? "record"}. Converted leads are read-only.',
                          style: const TextStyle(color: AppColors.success, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),

              const Text('Lead Information', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              // Client Name
              TextFormField(
                controller: _clientNameController,
                enabled: !isReadOnly,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Client Name *',
                  prefixIcon: Icon(Icons.person, color: AppColors.textMuted),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Client name is required';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Phone & Email
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _phoneController,
                      enabled: !isReadOnly,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: Icon(Icons.phone, color: AppColors.textMuted),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _emailController,
                      enabled: !isReadOnly,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                        prefixIcon: Icon(Icons.email, color: AppColors.textMuted),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Property Type & Budget
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _propertyTypeController,
                      enabled: !isReadOnly,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Property Type',
                        prefixIcon: Icon(Icons.home_work, color: AppColors.textMuted),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _budgetController,
                      enabled: !isReadOnly,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Estimated Budget (₹) *',
                        prefixIcon: Icon(Icons.currency_rupee_rounded, color: AppColors.textMuted),
                      ),
                      validator: (val) {
                        if (val != null && val.isNotEmpty) {
                          final parsed = double.tryParse(val);
                          if (parsed == null || parsed < 0) return 'Invalid budget';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Status Dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedStatus,
                dropdownColor: AppColors.surface,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Pipeline Status',
                  prefixIcon: Icon(Icons.track_changes, color: AppColors.textMuted),
                ),
                items: _statuses.map((s) {
                  return DropdownMenuItem<String>(
                    value: s,
                    enabled: s != 'Won', // Won status must be done via convert button
                    child: Text(
                      s == 'Won' ? 'Won (Use Convert Button)' : s,
                      style: TextStyle(color: s == 'Won' ? AppColors.textMuted : Colors.white),
                    ),
                  );
                }).toList(),
                onChanged: isReadOnly ? null : (val) {
                  if (val != null) setState(() => _selectedStatus = val);
                },
              ),
              const SizedBox(height: 16),

              // Assigned To info
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.assignment_ind, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Assigned Designer', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                        Text(lead.assignedTo, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Buttons Section
              if (!isReadOnly) ...[
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = constraints.maxWidth < 500;

                    final saveBtn = ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: leadsState.isMutating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.save, color: Colors.white),
                      label: const Text('Save Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      onPressed: leadsState.isMutating
                          ? null
                          : () async {
                              if (_formKey.currentState!.validate()) {
                                final budget = double.tryParse(_budgetController.text);
                                final messenger = ScaffoldMessenger.of(context);
                                final nav = GoRouter.of(context);
                                final updated = await ref.read(leadsNotifierProvider.notifier).updateLead(
                                      leadId: lead.id,
                                      updateData: {
                                        'clientName': _clientNameController.text.trim(),
                                        'phone': _phoneController.text.trim(),
                                        'email': _emailController.text.trim(),
                                        'propertyType': _propertyTypeController.text.trim(),
                                        'estimatedBudget': budget,
                                        'status': _selectedStatus,
                                      },
                                    );
                                if (updated != null) {
                                  messenger.showSnackBar(
                                    SnackBar(content: Text('Lead ${lead.id} updated successfully!'), backgroundColor: Colors.green.shade600),
                                  );
                                  nav.pop();
                                } else {
                                  final err = ref.read(leadsNotifierProvider).errorMessage ?? 'Failed to update lead';
                                  messenger.showSnackBar(
                                    SnackBar(content: Text(err), backgroundColor: Colors.red.shade600),
                                  );
                                }
                              }
                            },
                    );

                    final convertBtn = ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: _isConverting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.transform, color: Colors.white),
                      label: const Text('Convert to Project', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      onPressed: (leadsState.isMutating || _isConverting)
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
                                    'Are you sure you want to convert "${lead.clientName}" into an active Project?',
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
                                setState(() => _isConverting = true);
                                final project = await ref.read(leadsNotifierProvider.notifier).convertLeadToProject(
                                      leadId: lead.id,
                                    );
                                if (mounted) {
                                  setState(() => _isConverting = false);
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
                    );

                    if (isMobile) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          saveBtn,
                          const SizedBox(height: 12),
                          convertBtn,
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(child: saveBtn),
                        const SizedBox(width: 16),
                        Expanded(child: convertBtn),
                      ],
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
