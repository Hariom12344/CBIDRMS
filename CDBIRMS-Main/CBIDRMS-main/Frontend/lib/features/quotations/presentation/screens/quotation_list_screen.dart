import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/app_drawer_sidebar.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/models/quotation_model.dart';
import '../../data/quotation_service.dart';
import 'quotation_a4_preview_screen.dart';
import 'create_edit_quotation_screen.dart';
import '../widgets/share_quotation_dialog.dart';

class QuotationListScreen extends StatefulWidget {
  const QuotationListScreen({super.key});

  @override
  State<QuotationListScreen> createState() => _QuotationListScreenState();
}

class _QuotationListScreenState extends State<QuotationListScreen> {
  final QuotationService _service = QuotationService();
  List<QuotationModel> _quotes = [];
  bool _isLoading = true;
  String _selectedStatus = 'ALL';
  String _searchQuery = '';

  final List<String> _statusFilters = ['ALL', 'DRAFT', 'SENT', 'APPROVED', 'REVISED', 'CONVERTED'];

  @override
  void initState() {
    super.initState();
    _loadQuotations();
  }

  Future<void> _loadQuotations() async {
    setState(() => _isLoading = true);
    final data = await _service.fetchQuotations(search: _searchQuery, status: _selectedStatus);
    setState(() {
      _quotes = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Quotation Generator & Management', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      drawer: const AppDrawerSidebar(currentRoute: '/quotations'),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_shopping_cart_outlined, color: Colors.white),
        label: const Text('Create Quotation', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () async {
          final res = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateEditQuotationScreen()),
          );
          if (res == true) _loadQuotations();
        },
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Search and Status Filters Bar
            LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 700;
                final searchField = TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search by Quotation #, Buyer, or Consignee...',
                    hintStyle: const TextStyle(color: AppColors.textSecondary),
                    prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                    fillColor: AppColors.surface,
                    filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  ),
                  onChanged: (val) {
                    _searchQuery = val;
                    _loadQuotations();
                  },
                );

                final filterChips = SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _statusFilters.map((st) {
                      final isSelected = _selectedStatus == st;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilterChip(
                          label: Text(st),
                          selected: isSelected,
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(color: isSelected ? Colors.white : AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 12),
                          onSelected: (selected) {
                            setState(() => _selectedStatus = st);
                            _loadQuotations();
                          },
                        ),
                      );
                    }).toList(),
                  ),
                );

                if (isMobile) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      searchField,
                      const SizedBox(height: 12),
                      filterChips,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: searchField),
                    const SizedBox(width: 16),
                    filterChips,
                  ],
                );
              },
            ),

            const SizedBox(height: 16),

            // Main List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : _quotes.isEmpty
                      ? const Center(child: Text('No quotations found', style: TextStyle(color: AppColors.textSecondary)))
                      : ListView.builder(
                          itemCount: _quotes.length,
                          itemBuilder: (context, index) {
                            final q = _quotes[index];
                            return Card(
                              color: AppColors.surface,
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => QuotationA4PreviewScreen(quotationId: q.id),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: const Icon(Icons.receipt_long_outlined, color: AppColors.primary, size: 28),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Wrap(
                                                  spacing: 8,
                                                  runSpacing: 4,
                                                  crossAxisAlignment: WrapCrossAlignment.center,
                                                  children: [
                                                    Text(
                                                      q.quotationNumber,
                                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                                    ),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: AppColors.info.withValues(alpha: 0.2),
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                      child: Text(
                                                        'Rev ${q.revisionNumber}',
                                                        style: const TextStyle(color: AppColors.info, fontWeight: FontWeight.bold, fontSize: 11),
                                                      ),
                                                    ),
                                                    StatusBadge(status: q.status),
                                                  ],
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  'Buyer: ${q.buyer.name} • Consignee: ${q.consignee.name}',
                                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Date: ${q.date} | Valid Till: ${q.validTill}',
                                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            '₹${q.grandTotal.toStringAsFixed(2)}',
                                            style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Wrap(
                                        alignment: WrapAlignment.end,
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          OutlinedButton.icon(
                                            style: OutlinedButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                              minimumSize: const Size(0, 34),
                                              alignment: Alignment.center,
                                              side: const BorderSide(color: AppColors.primary),
                                            ),
                                            icon: const Icon(Icons.remove_red_eye_outlined, size: 14, color: AppColors.primary),
                                            label: const Text('View ERP A4', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => QuotationA4PreviewScreen(quotationId: q.id),
                                                ),
                                              );
                                            },
                                          ),
                                          OutlinedButton.icon(
                                            style: OutlinedButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                              minimumSize: const Size(0, 34),
                                              alignment: Alignment.center,
                                              side: const BorderSide(color: AppColors.secondary),
                                            ),
                                            icon: const Icon(Icons.share_outlined, size: 14, color: AppColors.secondary),
                                            label: const Text('Share', style: TextStyle(color: AppColors.secondary, fontSize: 12, fontWeight: FontWeight.bold)),
                                            onPressed: () {
                                              showDialog(
                                                context: context,
                                                builder: (context) => ShareQuotationDialog(
                                                  quotation: q,
                                                  onShared: () {},
                                                ),
                                              );
                                            },
                                          ),
                                        ],
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
