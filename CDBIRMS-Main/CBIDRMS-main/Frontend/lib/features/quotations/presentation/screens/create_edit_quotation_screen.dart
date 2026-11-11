import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../domain/models/quotation_item_model.dart';
import '../../data/quotation_service.dart';

class CreateEditQuotationScreen extends StatefulWidget {
  const CreateEditQuotationScreen({super.key});

  @override
  State<CreateEditQuotationScreen> createState() => _CreateEditQuotationScreenState();
}

class _CreateEditQuotationScreenState extends State<CreateEditQuotationScreen> {
  final _formKey = GlobalKey<FormState>();
  final QuotationService _service = QuotationService();

  // Header info
  late TextEditingController _dateController;
  late TextEditingController _validTillController;
  late TextEditingController _refNumberController;
  late TextEditingController _deliveryTermsController;

  // Consignee (Ship To)
  final _consigneeName = TextEditingController(text: 'Apex Innovations Pvt Ltd (Data Center)');
  final _consigneeAddress = TextEditingController(text: 'Building 4B, Cyber City, Magarpatta, Pune 411028');
  final _consigneeGstin = TextEditingController(text: '27AABCA5678K1ZB');
  final _consigneeContact = TextEditingController(text: 'Rajesh Sharma');
  final _consigneeMobile = TextEditingController(text: '+91 98220 11223');

  // Buyer (Bill To)
  final _buyerName = TextEditingController(text: 'Apex Innovations Pvt Ltd');
  final _buyerAddress = TextEditingController(text: 'Unit 102, Commercial Hub, SB Road, Pune 411016');
  final _buyerGstin = TextEditingController(text: '27AABCA5678K1ZB');
  final _buyerContact = TextEditingController(text: 'Anita Roy');
  final _buyerMobile = TextEditingController(text: '+91 98220 44556');

  // Items
  final List<QuotationItemModel> _items = [
    QuotationItemModel(
      srNo: 1,
      description: 'Custom ERP Module Development & Integration',
      hsnSac: '998313',
      quantity: 1,
      uom: 'NOS',
      rate: 125000,
      discountPercent: 5,
      discountAmount: 6250,
      amount: 118750,
    ),
  ];

  // Taxes
  double _cgstRate = 9.0;
  double _sgstRate = 9.0;
  final double _igstRate = 0.0;
  final double _discountTotal = 0.0;

  // Exclusions & Terms
  final _declarationController = TextEditingController(
    text: 'Not included:\n- Domain Purchase & Hosting Renewal Fees\n- Third-party API Subscriptions\n- Annual Maintenance beyond 60 days',
  );
  final _termsController = TextEditingController(
    text: '1. 50% advance payment required upon purchase order confirmation.\n2. 40% upon completion of development milestone.\n3. 10% before final deployment.',
  );

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final valid = now.add(const Duration(days: 30));
    _dateController = TextEditingController(text: now.toISOStringDate());
    _validTillController = TextEditingController(text: valid.toISOStringDate());
    _refNumberController = TextEditingController(text: 'RF-${now.millisecondsSinceEpoch.toString().substring(7)}');
    _deliveryTermsController = TextEditingController(text: 'Immediate (Digital Handover)');
  }

  void _addItemRow() {
    setState(() {
      _items.add(
        QuotationItemModel(
          srNo: _items.length + 1,
          description: '',
          hsnSac: '998314',
          quantity: 1,
          uom: 'NOS',
          rate: 10000,
          amount: 10000,
        ),
      );
    });
  }

  void _removeItemRow(int index) {
    if (_items.length > 1) {
      setState(() {
        _items.removeAt(index);
        for (int i = 0; i < _items.length; i++) {
          _items[i].srNo = i + 1;
        }
      });
    }
  }

  double get _calculatedSubtotal {
    return _items.fold(0.0, (sum, item) => sum + item.amount);
  }

  double get _taxableSubtotal {
    return (_calculatedSubtotal - _discountTotal).clamp(0.0, double.infinity);
  }

  double get _cgstAmount => _taxableSubtotal * (_cgstRate / 100);
  double get _sgstAmount => _taxableSubtotal * (_sgstRate / 100);
  double get _igstAmount => _taxableSubtotal * (_igstRate / 100);

  double get _totalBeforeRound => _taxableSubtotal + _cgstAmount + _sgstAmount + _igstAmount;
  double get _grandTotal => _totalBeforeRound.roundToDouble();

  Future<void> _submitForm(String status) async {
    if (!_formKey.currentState!.validate()) return;

    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least 1 line item is required to save quotation'), backgroundColor: AppColors.error),
      );
      return;
    }

    if (_igstRate > 0 && (_cgstRate > 0 || _sgstRate > 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('GST Error: Intra-state (CGST+SGST) and Inter-state (IGST) are mutually exclusive'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final payload = {
        'date': _dateController.text,
        'validTill': _validTillController.text,
        'refNumber': _refNumberController.text,
        'termsOfDelivery': _deliveryTermsController.text,

        'consigneeName': _consigneeName.text,
        'consigneeAddress': _consigneeAddress.text,
        'consigneeGstin': _consigneeGstin.text,
        'consigneeContact': _consigneeContact.text,
        'consigneeMobile': _consigneeMobile.text,

        'buyerName': _buyerName.text,
        'buyerAddress': _buyerAddress.text,
        'buyerGstin': _buyerGstin.text,
        'buyerContact': _buyerContact.text,
        'buyerMobile': _buyerMobile.text,

        'items': _items.map((i) => i.toJson()).toList(),

        'discountTotal': _discountTotal,
        'cgstRate': _cgstRate,
        'sgstRate': _sgstRate,
        'igstRate': _igstRate,

        'declarationText': _declarationController.text,
        'termsAndConditions': _termsController.text,
        'status': status,
      };

      final result = await _service.createQuotation(payload);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Quotation ${result.quotationNumber} saved!'), backgroundColor: AppColors.success),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save quotation: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Create ERP Quotation', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header Information Box
              _buildSectionCard(
                title: 'Quotation Header Information',
                icon: Icons.receipt_long,
                child: Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    SizedBox(width: 180, child: _textField(_dateController, 'Quotation Date', true)),
                    SizedBox(width: 180, child: _textField(_validTillController, 'Valid Till Date', true)),
                    SizedBox(width: 180, child: _textField(_refNumberController, 'Reference Number', false)),
                    SizedBox(width: 220, child: _textField(_deliveryTermsController, 'Terms of Delivery', false)),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 2. Party Information (Consignee vs Buyer)
              LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 700;
                  final consigneeCard = _buildSectionCard(
                    title: 'Consignee (Ship To)',
                    icon: Icons.local_shipping_outlined,
                    child: Column(
                      children: [
                        _textField(_consigneeName, 'Customer / Company Name', true),
                        const SizedBox(height: 10),
                        _textField(_consigneeAddress, 'Full Delivery Address', true, maxLines: 2),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(child: _textField(_consigneeGstin, 'GSTIN (Optional)', false)),
                            const SizedBox(width: 10),
                            Expanded(child: _textField(_consigneeMobile, 'Mobile Number', false)),
                          ],
                        ),
                      ],
                    ),
                  );

                  final buyerCard = _buildSectionCard(
                    title: 'Buyer (Bill To)',
                    icon: Icons.business_outlined,
                    child: Column(
                      children: [
                        _textField(_buyerName, 'Buyer Company Name', true),
                        const SizedBox(height: 10),
                        _textField(_buyerAddress, 'Billing Address', true, maxLines: 2),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(child: _textField(_buyerGstin, 'GSTIN (Optional)', false)),
                            const SizedBox(width: 10),
                            Expanded(child: _textField(_buyerMobile, 'Mobile Number', false)),
                          ],
                        ),
                      ],
                    ),
                  );

                  if (isMobile) {
                    return Column(
                      children: [
                        consigneeCard,
                        const SizedBox(height: 16),
                        buyerCard,
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: consigneeCard),
                      const SizedBox(width: 16),
                      Expanded(child: buyerCard),
                    ],
                  );
                },
              ),

              const SizedBox(height: 16),

              // 3. Dynamic Items Table
              _buildSectionCard(
                title: 'Items & Services Table',
                icon: Icons.table_chart_outlined,
                action: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Row'),
                  onPressed: _addItemRow,
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: 700,
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _items.length,
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        return Card(
                          color: const Color(0xFF1E293B),
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                                  child: Text('${item.srNo}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 4,
                                  child: TextFormField(
                                    initialValue: item.description,
                                    style: const TextStyle(color: Colors.white, fontSize: 13),
                                    decoration: const InputDecoration(labelText: 'Description of Service / Item', isDense: true, border: OutlineInputBorder()),
                                    onChanged: (val) => item.description = val,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 90,
                                  child: TextFormField(
                                    initialValue: item.hsnSac,
                                    style: const TextStyle(color: Colors.white, fontSize: 13),
                                    decoration: const InputDecoration(labelText: 'HSN/SAC', isDense: true, border: OutlineInputBorder()),
                                    onChanged: (val) => item.hsnSac = val,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 70,
                                  child: TextFormField(
                                    initialValue: item.quantity.toStringAsFixed(0),
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(color: Colors.white, fontSize: 13),
                                    decoration: const InputDecoration(labelText: 'Qty', isDense: true, border: OutlineInputBorder()),
                                    onChanged: (val) {
                                      setState(() {
                                        item.quantity = double.tryParse(val) ?? 1;
                                        item.recalculateAmount();
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 100,
                                  child: TextFormField(
                                    initialValue: item.rate.toStringAsFixed(0),
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(color: Colors.white, fontSize: 13),
                                    decoration: const InputDecoration(labelText: 'Rate (₹)', isDense: true, border: OutlineInputBorder()),
                                    onChanged: (val) {
                                      setState(() {
                                        item.rate = double.tryParse(val) ?? 0;
                                        item.recalculateAmount();
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                SizedBox(
                                  width: 110,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Text('Amount', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                                      Text('₹${item.amount.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 14)),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                  onPressed: () => _removeItemRow(index),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 4. Calculations Summary
              _buildSectionCard(
                title: 'Taxes & Totals Summary',
                icon: Icons.calculate_outlined,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = constraints.maxWidth < 600;
                    final taxInputs = SizedBox(
                      width: 250,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Text('CGST %: ', style: TextStyle(color: Colors.white)),
                              SizedBox(
                                width: 60,
                                child: TextFormField(
                                  initialValue: '9',
                                  style: const TextStyle(color: Colors.white),
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                                  onChanged: (val) => setState(() => _cgstRate = double.tryParse(val) ?? 0),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Text('SGST %: ', style: TextStyle(color: Colors.white)),
                              SizedBox(
                                width: 60,
                                child: TextFormField(
                                  initialValue: '9',
                                  style: const TextStyle(color: Colors.white),
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                                  onChanged: (val) => setState(() => _sgstRate = double.tryParse(val) ?? 0),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );

                    final totalsBox = Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(8)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Subtotal: ₹${_calculatedSubtotal.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 13)),
                          Text('CGST ($_cgstRate%): ₹${_cgstAmount.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          Text('SGST ($_sgstRate%): ₹${_sgstAmount.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          const Divider(color: Colors.white24),
                          Text('Grand Total: ₹${_grandTotal.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 18)),
                        ],
                      ),
                    );

                    if (isMobile) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          taxInputs,
                          const SizedBox(height: 14),
                          totalsBox,
                        ],
                      );
                    }

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        taxInputs,
                        totalsBox,
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // 5. Declarations & Terms
              _buildSectionCard(
                title: 'Declarations & Terms',
                icon: Icons.gavel_outlined,
                child: Column(
                  children: [
                    _textField(_declarationController, 'Declaration / Scope Exclusions', false, maxLines: 3),
                    const SizedBox(height: 10),
                    _textField(_termsController, 'Terms & Conditions', false, maxLines: 3),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Action Buttons
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      side: const BorderSide(color: AppColors.textSecondary),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel', style: TextStyle(color: Colors.white)),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      side: const BorderSide(color: AppColors.primary),
                    ),
                    icon: const Icon(Icons.save_outlined, color: AppColors.primary),
                    label: const Text('Save Draft', style: TextStyle(color: AppColors.primary)),
                    onPressed: _isSaving ? null : () => _submitForm('DRAFT'),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    icon: const Icon(Icons.send_rounded),
                    label: const Text('Save & Finalize', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: _isSaving ? null : () => _submitForm('SENT'),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required Widget child, Widget? action}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                ],
              ),
              if (action != null) action,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _textField(TextEditingController controller, String label, bool isRequired, {int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      maxLines: maxLines,
      validator: isRequired ? (val) => val == null || val.isEmpty ? '$label is required' : null : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }
}

extension DateTimeFormat on DateTime {
  String toISOStringDate() {
    return "$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}";
  }
}
