import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/app_drawer_sidebar.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../providers/boq_provider.dart';

class BoqListScreen extends ConsumerStatefulWidget {
  const BoqListScreen({super.key});

  @override
  ConsumerState<BoqListScreen> createState() => _BoqListScreenState();
}

class _BoqListScreenState extends ConsumerState<BoqListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(boqNotifierProvider.notifier).fetchBoqs();
    });
  }

  @override
  Widget build(BuildContext context) {
    final boqState = ref.watch(boqNotifierProvider);
    final boqs = boqState.boqs;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Bill of Quantities (BOQ)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
            onPressed: () {
              ref.read(boqNotifierProvider.notifier).fetchBoqs();
            },
          ),
        ],
      ),
      drawer: const AppDrawerSidebar(currentRoute: '/boq'),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.note_add_outlined, color: Colors.white),
        label: const Text('Create BOQ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () => context.push('/boq/create'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(boqNotifierProvider.notifier).fetchBoqs();
        },
        child: boqState.isLoading
            ? const Center(child: LoadingWidget(message: 'Loading BOQ estimates...'))
            : boqs.isEmpty
                ? SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Container(
                      height: MediaQuery.of(context).size.height * 0.7,
                      alignment: Alignment.center,
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long_outlined, size: 64, color: AppColors.textMuted),
                          SizedBox(height: 16),
                          Text('No BOQ documents created yet', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          SizedBox(height: 8),
                          Text('Tap "Create BOQ" to estimate project line items and costs.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(24),
                    itemCount: boqs.length,
                    itemBuilder: (context, index) {
                      final boq = boqs[index];
                      final formattedDate = boq.createdAt.length >= 10 ? boq.createdAt.substring(0, 10) : boq.createdAt;

                      return Card(
                        color: AppColors.surface,
                        margin: const EdgeInsets.only(bottom: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(20),
                          leading: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                            child: const Icon(Icons.receipt_long_outlined, color: AppColors.primary),
                          ),
                          title: Text(boq.projectName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('${boq.items.length} Line Items • Created: $formattedDate', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                              const SizedBox(height: 8),
                              Text('Total BOQ Cost: ₹${boq.totalCost.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 14)),
                            ],
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 16),
                          onTap: () => context.push('/boq/details', extra: boq),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
