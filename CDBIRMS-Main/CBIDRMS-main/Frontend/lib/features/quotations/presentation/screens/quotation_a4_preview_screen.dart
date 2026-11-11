import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/constants/api_constants.dart';
import '../../domain/models/quotation_model.dart';
import '../../data/quotation_service.dart';
import '../widgets/share_quotation_dialog.dart';

class QuotationA4PreviewScreen extends StatefulWidget {
  final String quotationId;

  const QuotationA4PreviewScreen({super.key, required this.quotationId});

  @override
  State<QuotationA4PreviewScreen> createState() => _QuotationA4PreviewScreenState();
}

class _QuotationA4PreviewScreenState extends State<QuotationA4PreviewScreen> {
  final QuotationService _service = QuotationService();
  QuotationModel? _quotation;
  List<Map<String, dynamic>> _revisions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData([String? targetId]) async {
    setState(() => _isLoading = true);
    try {
      final quote = await _service.fetchQuotationById(targetId ?? widget.quotationId);
      setState(() {
        _quotation = quote;
        _revisions = quote.revisions ?? [];
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  void _showCreateRevisionDialog() {
    final noteController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Create New Quotation Revision', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Creating revision from ${_quotation?.quotationNumber} (Current Rev ${_quotation?.revisionNumber}). This will generate Rev ${(_quotation?.revisionNumber ?? 0) + 1}.',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Revision Reason / Notes',
                hintText: 'e.g., Client requested scope changes in carpentry & rates',
                labelStyle: TextStyle(color: AppColors.primary),
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            icon: const Icon(Icons.history_edu, color: Colors.white),
            label: const Text('Create Rev', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              if (_quotation != null) {
                final newRev = await _service.createRevision(_quotation!.id, {'revisionNotes': noteController.text});
                messenger.showSnackBar(
                  SnackBar(content: Text('Revision Rev ${newRev.revisionNumber} created!'), backgroundColor: AppColors.success),
                );
                _loadData(newRev.id);
              }
            },
          ),
        ],
      ),
    );
  }

  void _showShareDialog() {
    if (_quotation == null) return;
    showDialog(
      context: context,
      builder: (context) => ShareQuotationDialog(
        quotation: _quotation!,
        onShared: () => _loadData(_quotation!.id),
      ),
    );
  }

  Future<void> _handleConvertToProject() async {
    if (_quotation == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Convert Quotation to Project?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'This will create a new Project ("${_quotation!.buyer.name} Project") in PLANNING status, seed a BOQ from this quotation\'s line items, and mark this quotation as CONVERTED.',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Convert Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        setState(() => _isLoading = true);
        await _service.convertToProject(_quotation!.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Quotation successfully converted into Project and BOQ seeded!'), backgroundColor: AppColors.success),
          );
          _loadData(_quotation!.id);
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Conversion failed: $e'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(backgroundColor: AppColors.surface, title: const Text('Loading Quotation...')),
        body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (_quotation == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(backgroundColor: AppColors.surface, title: const Text('Error')),
        body: const Center(child: Text('Quotation not found', style: TextStyle(color: Colors.white))),
      );
    }

    final q = _quotation!;
    final isConverted = q.status == 'CONVERTED';

    return Scaffold(
      backgroundColor: const Color(0xFF1E293B),
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 2,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(q.quotationNumber, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            Text('Revision ${q.revisionNumber} • ${q.status}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
        actions: [
          if (_revisions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: PopupMenuButton<String>(
                color: AppColors.surface,
                tooltip: 'Select Revision History',
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.primary),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.history, color: AppColors.primary, size: 16),
                      const SizedBox(width: 4),
                      Text('Rev ${q.revisionNumber}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      const Icon(Icons.arrow_drop_down, color: Colors.white, size: 16),
                    ],
                  ),
                ),
                onSelected: (selectedId) => _loadData(selectedId),
                itemBuilder: (context) {
                  return _revisions.map((rev) {
                    final revNum = rev['revisionNumber'];
                    final revNotes = rev['revisionNotes'] ?? '';
                    return PopupMenuItem<String>(
                      value: rev['id'],
                      child: Text('Rev $revNum ($revNotes)', style: const TextStyle(color: Colors.white, fontSize: 13)),
                    );
                  }).toList();
                },
              ),
            ),
          IconButton(
            icon: const Icon(Icons.share_rounded, color: Colors.lightGreenAccent),
            tooltip: 'Share Quotation',
            onPressed: isConverted ? null : _showShareDialog,
          ),
          if (!isConverted)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
                icon: const Icon(Icons.rocket_launch_rounded, size: 16, color: Colors.white),
                label: const Text('Convert to Project', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                onPressed: _handleConvertToProject,
              ),
            )
          else
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.success),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: AppColors.success, size: 14),
                  SizedBox(width: 4),
                  Text('CONVERTED', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 11)),
                ],
              ),
            ),
          IconButton(
            icon: const Icon(Icons.history_edu, color: Colors.amber),
            tooltip: 'Create New Revision',
            onPressed: isConverted ? null : _showCreateRevisionDialog,
          ),
          IconButton(
            icon: const Icon(Icons.copy, color: Colors.lightBlueAccent),
            tooltip: 'Duplicate Quotation',
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              try {
                final dup = await _service.duplicateQuotation(q.id);
                messenger.showSnackBar(
                  SnackBar(content: Text('Duplicated as ${dup.quotationNumber}'), backgroundColor: AppColors.success),
                );
                _loadData(dup.id);
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text('Duplication failed: $e'), backgroundColor: AppColors.error),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.print_outlined, color: Colors.white),
            tooltip: 'Print / Download PDF',
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final pdfUrl = Uri.parse('${ApiConstants.baseUrl}/quotations/${q.id}/pdf');
              if (await canLaunchUrl(pdfUrl)) {
                await launchUrl(pdfUrl, mode: LaunchMode.externalApplication);
              } else {
                messenger.showSnackBar(
                  SnackBar(content: Text('Opening PDF at $pdfUrl'), backgroundColor: AppColors.info),
                );
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Center(
            child: Container(
              width: 794,
              constraints: const BoxConstraints(maxWidth: 794),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2),
                boxShadow: const [
                  BoxShadow(color: Colors.black45, blurRadius: 16, offset: Offset(0, 6)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Centered Top Header Title
                  const Text(
                    'Quotation',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Main Outer Border Box
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black, width: 1.2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Top Row: Logo & Company vs Meta Table
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                flex: 55,
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: const BoxDecoration(
                                    border: Border(right: BorderSide(color: Colors.black, width: 1)),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Logo Triangle Icon
                                      Column(
                                        children: [
                                          CustomPaint(
                                            size: const Size(40, 40),
                                            painter: LogoPainter(),
                                          ),
                                          const SizedBox(height: 2),
                                          const Text('TRIROOP', style: TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.bold)),
                                          const Text('Precision in every layer', style: TextStyle(color: Colors.grey, fontSize: 5)),
                                        ],
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(q.company.name, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                                            const SizedBox(height: 2),
                                            Text(q.company.address, style: const TextStyle(color: Colors.black, fontSize: 10, height: 1.3)),
                                            Text('Phone: ${q.company.phone}', style: const TextStyle(color: Colors.black, fontSize: 10)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 45,
                                child: Column(
                                  children: [
                                    _metaRow('Quotation No.', q.quotationNumber),
                                    _metaRow('Dated', q.date),
                                    _metaRow('Valid Till', q.validTill),
                                    _metaRow('Reference No.', q.refNumber ?? '—'),
                                    _metaRow('Terms of Delivery', q.termsOfDelivery ?? '', isLast: true),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        _lineDivider(),

                        // Consignee (Ship to)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Consignee (Ship to)', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11)),
                              const SizedBox(height: 2),
                              Text(q.consignee.name, style: const TextStyle(color: Colors.black, fontSize: 10.5)),
                              Text(q.consignee.address, style: const TextStyle(color: Colors.black, fontSize: 10.5)),
                            ],
                          ),
                        ),

                        _lineDivider(),

                        // Buyer (Bill to)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Buyer (Bill to)', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11)),
                              const SizedBox(height: 2),
                              Text(q.buyer.name, style: const TextStyle(color: Colors.black, fontSize: 10.5)),
                              Text(q.buyer.address, style: const TextStyle(color: Colors.black, fontSize: 10.5)),
                            ],
                          ),
                        ),

                        _lineDivider(),

                        // Item Table Header & Rows
                        Table(
                          border: const TableBorder(
                            horizontalInside: BorderSide(color: Colors.black, width: 0.5),
                            verticalInside: BorderSide(color: Colors.black, width: 1),
                          ),
                          columnWidths: const {
                            0: FlexColumnWidth(0.6),
                            1: FlexColumnWidth(3.2),
                            2: FlexColumnWidth(1.0),
                            3: FlexColumnWidth(1.0),
                            4: FlexColumnWidth(1.2),
                            5: FlexColumnWidth(0.8),
                            6: FlexColumnWidth(0.8),
                            7: FlexColumnWidth(1.4),
                          },
                          children: [
                            TableRow(
                              decoration: const BoxDecoration(color: Colors.white),
                              children: [
                                _th('Sr.\nNo.'),
                                _th('Description of Goods', align: TextAlign.left),
                                _th('HSN /\nSAC'),
                                _th('Quantity'),
                                _th('Rate', align: TextAlign.right),
                                _th('UOM'),
                                _th('Disc.'),
                                _th('Amount', align: TextAlign.right),
                              ],
                            ),
                            ...q.items.map((item) {
                              return TableRow(
                                children: [
                                  _td('${item.srNo}', align: TextAlign.center),
                                  _td(item.description),
                                  _td(item.hsnSac ?? '', align: TextAlign.center),
                                  _td(item.quantity.toStringAsFixed(0), align: TextAlign.center),
                                  _td('₹${item.rate.toStringAsFixed(0)}', align: TextAlign.right),
                                  _td(item.uom, align: TextAlign.center),
                                  _td(item.discountPercent > 0 ? '${item.discountPercent.toStringAsFixed(0)}%' : '', align: TextAlign.center),
                                  _td('₹${item.amount.toStringAsFixed(0)}', align: TextAlign.right),
                                ],
                              );
                            }),
                            // Subtotal
                            TableRow(
                              decoration: const BoxDecoration(border: Border(top: BorderSide(color: Colors.black, width: 1))),
                              children: [
                                Container(),
                                Container(),
                                Container(),
                                Container(),
                                Container(),
                                Container(),
                                _th('Subtotal', align: TextAlign.left),
                                _td('₹${q.subtotal.toStringAsFixed(0)}', align: TextAlign.right, isBold: true),
                              ],
                            ),
                            // Discount
                            if (q.discountTotal > 0)
                              TableRow(
                                children: [
                                  Container(), Container(), Container(), Container(), Container(), Container(),
                                  _th('Discount', align: TextAlign.left),
                                  _td('- ₹${q.discountTotal.toStringAsFixed(0)}', align: TextAlign.right, isBold: true),
                                ],
                              ),
                            // Grand Total
                            TableRow(
                              decoration: const BoxDecoration(border: Border(top: BorderSide(color: Colors.black, width: 1))),
                              children: [
                                Container(), Container(), Container(), Container(), Container(), Container(),
                                _th('Grand Total', align: TextAlign.left),
                                _td('₹${q.grandTotal.toStringAsFixed(0)}', align: TextAlign.right, isBold: true),
                              ],
                            ),
                          ],
                        ),

                        _lineDivider(),

                        // Amount Chargeable Box
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Amount Chargeable (in words)', style: TextStyle(color: Colors.black, fontSize: 10)),
                                  Text(q.amountInWords.isEmpty ? 'INR Fourteen Thousand Only' : q.amountInWords, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11)),
                                ],
                              ),
                              const Text('E. & O.E', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 10)),
                            ],
                          ),
                        ),

                        _lineDivider(),

                        // Declaration & Signature Grid
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                flex: 55,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(border: Border(right: BorderSide(color: Colors.black, width: 1))),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Declaration', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11)),
                                      const SizedBox(height: 2),
                                      Text(
                                        q.declarationText ?? '1. Not included (to be paid directly by the client):\n1.1. Domain purchase.\n1.2. Google Workspace subscription charges.\n1.3. Future feature additions beyond the agreed scope.\n1.4. Annual maintenance and support.',
                                        style: const TextStyle(color: Colors.black, fontSize: 10, height: 1.3),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 45,
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('for ${q.company.name}', style: const TextStyle(color: Colors.black, fontSize: 10.5)),
                                      const SizedBox(height: 35),
                                      const Text('Authorised Signatory', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        _lineDivider(),

                        // Footer inside box
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          color: Colors.white,
                          child: const Text(
                            'This is a Computer Generated Quotation',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Outer Sub-footer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Vyapar Book by ${q.company.name}', style: const TextStyle(color: Colors.grey, fontSize: 9)),
                      const Text('Page | 1', style: TextStyle(color: Colors.grey, fontSize: 9)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _metaRow(String label, String value, {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border(bottom: isLast ? BorderSide.none : const BorderSide(color: Colors.black, width: 1)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 10.5)),
          ),
          Container(width: 1, height: 14, color: Colors.black),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.black, fontSize: 10.5)),
          ),
        ],
      ),
    );
  }

  Widget _lineDivider() {
    return Container(height: 1, color: Colors.black);
  }

  Widget _th(String text, {TextAlign align = TextAlign.center}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Text(
        text,
        textAlign: align,
        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 10),
      ),
    );
  }

  Widget _td(String text, {TextAlign align = TextAlign.left, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
      child: Text(
        text,
        textAlign: align,
        style: TextStyle(
          color: Colors.black,
          fontSize: 10,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}

class LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final path1 = Path()
      ..moveTo(size.width / 2, 2)
      ..lineTo(size.width - 2, size.height - 2)
      ..lineTo(2, size.height - 2)
      ..close();

    final path2 = Path()
      ..moveTo(size.width / 2, 10)
      ..lineTo(size.width - 8, size.height - 6)
      ..lineTo(8, size.height - 6)
      ..close();

    final path3 = Path()
      ..moveTo(size.width / 2, 18)
      ..lineTo(size.width - 14, size.height - 10)
      ..lineTo(14, size.height - 10)
      ..close();

    canvas.drawPath(path1, paint);
    canvas.drawPath(path2, paint);
    canvas.drawPath(path3, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
