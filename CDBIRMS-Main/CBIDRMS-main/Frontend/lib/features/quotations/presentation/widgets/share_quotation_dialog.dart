import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../app/theme/app_theme.dart';
import '../../data/quotation_service.dart';
import '../../domain/models/quotation_model.dart';

class ShareQuotationDialog extends StatefulWidget {
  final QuotationModel quotation;
  final VoidCallback onShared;

  const ShareQuotationDialog({
    super.key,
    required this.quotation,
    required this.onShared,
  });

  @override
  State<ShareQuotationDialog> createState() => _ShareQuotationDialogState();
}

class _ShareQuotationDialogState extends State<ShareQuotationDialog> {
  final _service = QuotationService();
  bool _isSharing = false;

  Future<void> _handleShare(String channel) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _isSharing = true);
    try {
      final res = await _service.shareQuotation(widget.quotation.id, channel);
      final shareUrl = res['shareUrl'] ?? '';

      if (mounted) {
        if (channel == 'LINK') {
          await Clipboard.setData(ClipboardData(text: shareUrl));
          messenger.showSnackBar(
            const SnackBar(content: Text('Quotation PDF link copied to clipboard!'), backgroundColor: AppColors.success),
          );
        } else if (channel == 'WHATSAPP') {
          final text = Uri.encodeComponent('Hello, please review Quotation ${widget.quotation.quotationNumber}:\n$shareUrl');
          final waUri = Uri.parse('https://wa.me/?text=$text');
          if (await canLaunchUrl(waUri)) {
            await launchUrl(waUri, mode: LaunchMode.externalApplication);
          }
        } else if (channel == 'EMAIL') {
          final subject = Uri.encodeComponent('Quotation ${widget.quotation.quotationNumber}');
          final body = Uri.encodeComponent('Dear Customer,\n\nPlease find the quotation link below:\n$shareUrl\n\nThank you!');
          final mailUri = Uri.parse('mailto:?subject=$subject&body=$body');
          if (await canLaunchUrl(mailUri)) {
            await launchUrl(mailUri);
          }
        }

        widget.onShared();
        navigator.pop(true);
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.share_rounded, color: AppColors.primary, size: 22),
          const SizedBox(width: 10),
          Text(
            'Share Quotation ${widget.quotation.quotationNumber}',
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select a sharing method to generate a client-facing PDF link. Sharing will set the quotation status to SENT.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 20),
          if (_isSharing)
            const Center(child: CircularProgressIndicator(color: AppColors.primary))
          else ...[
            _buildOption(
              icon: Icons.link_rounded,
              color: Colors.blueAccent,
              title: 'Copy Public PDF Link',
              subtitle: 'Copy URL directly to clipboard',
              onTap: () => _handleShare('LINK'),
            ),
            const SizedBox(height: 12),
            _buildOption(
              icon: Icons.chat_bubble_outline_rounded,
              color: Colors.green,
              title: 'Share via WhatsApp',
              subtitle: 'Send quotation link directly via WhatsApp',
              onTap: () => _handleShare('WHATSAPP'),
            ),
            const SizedBox(height: 12),
            _buildOption(
              icon: Icons.email_outlined,
              color: Colors.amber,
              title: 'Share via Email',
              subtitle: 'Open default email app with quotation link',
              onTap: () => _handleShare('EMAIL'),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
        ),
      ],
    );
  }

  Widget _buildOption({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.surfaceLight),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 14),
          ],
        ),
      ),
    );
  }
}
