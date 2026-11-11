import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../app/constants/api_constants.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/custom_textfield.dart';
import '../../../projects/presentation/providers/project_provider.dart';
import '../providers/report_provider.dart';

class GenerateReportDialog extends ConsumerStatefulWidget {
  final String reportType; // PROJECT, EXPENSE, PURCHASE, REVENUE, VENDOR, TEAM
  final String reportTitle;
  final IconData icon;

  const GenerateReportDialog({
    super.key,
    required this.reportType,
    required this.reportTitle,
    required this.icon,
  });

  @override
  ConsumerState<GenerateReportDialog> createState() => _GenerateReportDialogState();
}

class _GenerateReportDialogState extends ConsumerState<GenerateReportDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fromDateCtrl;
  late TextEditingController _toDateCtrl;
  String? _selectedProjectId;
  String? _inlineError;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);

    _fromDateCtrl = TextEditingController(text: _formatDate(firstDayOfMonth));
    _toDateCtrl = TextEditingController(text: _formatDate(now));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(projectNotifierProvider.notifier).fetchProjects();
    });
  }

  String _formatDate(DateTime dt) {
    return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
  }

  @override
  void dispose() {
    _fromDateCtrl.dispose();
    _toDateCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final initialDate = DateTime.tryParse(controller.text) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        controller.text = _formatDate(picked);
        _inlineError = null;
      });
    }
  }

  Future<void> _onGenerate() async {
    if (!_formKey.currentState!.validate()) return;

    final fromStr = _fromDateCtrl.text.trim();
    final toStr = _toDateCtrl.text.trim();

    final fromDate = DateTime.tryParse(fromStr);
    final toDate = DateTime.tryParse(toStr);

    if (fromDate == null || toDate == null) {
      setState(() => _inlineError = 'Please select valid dates.');
      return;
    }

    if (fromDate.isAfter(toDate)) {
      setState(() => _inlineError = "'From Date' must be on or before 'To Date'");
      return;
    }

    final diffDays = toDate.difference(fromDate).inDays;
    if (diffDays > 365) {
      setState(() => _inlineError = "Date range cannot exceed 1 year (365 days)");
      return;
    }

    setState(() => _inlineError = null);

    final report = await ref.read(reportProvider.notifier).generateReport(
      type: widget.reportType,
      from: fromStr,
      to: toStr,
      projectId: _selectedProjectId,
    );

    if (!mounted) return;

    if (report != null) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Report ${report.id} generated! Opening document...'),
          backgroundColor: AppColors.success,
        ),
      );

      // Resolve full HTTP URL
      String fileUrlStr = report.fileUrl;
      if (!fileUrlStr.startsWith('http')) {
        final base = ApiConstants.baseUrl.replaceAll('/api', '');
        fileUrlStr = '$base$fileUrlStr';
      }

      final uri = Uri.parse(fileUrlStr);
      try {
        final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!launched) {
          await launchUrl(uri);
        }
      } catch (e) {
        debugPrint('Could not launch report URL: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportState = ref.watch(reportProvider);
    final projects = ref.watch(projectNotifierProvider).projects;

    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(widget.icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Generate ${widget.reportTitle}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select Date Range', style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _selectDate(context, _fromDateCtrl),
                      child: AbsorbPointer(
                        child: CustomTextField(
                          controller: _fromDateCtrl,
                          label: 'From Date',
                          hintText: 'YYYY-MM-DD',
                          prefixIcon: Icons.calendar_today_outlined,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _selectDate(context, _toDateCtrl),
                      child: AbsorbPointer(
                        child: CustomTextField(
                          controller: _toDateCtrl,
                          label: 'To Date',
                          hintText: 'YYYY-MM-DD',
                          prefixIcon: Icons.calendar_today_rounded,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Filter by Project (Optional)', style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value: _selectedProjectId,
                    dropdownColor: AppColors.surface,
                    isExpanded: true,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All Projects (Company Wide)', style: TextStyle(color: AppColors.primary)),
                      ),
                      ...projects.map((p) => DropdownMenuItem<String?>(
                            value: p.id,
                            child: Text('${p.id} - ${p.name}', overflow: TextOverflow.ellipsis),
                          )),
                    ],
                    onChanged: (val) {
                      setState(() => _selectedProjectId = val);
                    },
                  ),
                ),
              ),
              if (_inlineError != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_inlineError!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ],
              if (reportState.errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    reportState.errorMessage!,
                    style: const TextStyle(color: AppColors.error, fontSize: 12),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: reportState.isGenerating ? null : () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          icon: reportState.isGenerating
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 18),
          label: Text(
            reportState.isGenerating ? 'Generating...' : 'Generate & View',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          onPressed: reportState.isGenerating ? null : _onGenerate,
        ),
      ],
    );
  }
}
