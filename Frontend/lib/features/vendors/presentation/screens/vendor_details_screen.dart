import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../domain/models/vendor_model.dart';

class VendorDetailsScreen extends StatelessWidget {
  final VendorModel? vendor;

  const VendorDetailsScreen({super.key, this.vendor});

  @override
  Widget build(BuildContext context) {
    final v = vendor ??
        VendorModel(
          id: 'VND-301',
          companyName: 'Luxe Marble & Granite Co.',
          contactPerson: 'David Miller',
          email: 'david@luxemarble.com',
          phone: '+1 555-0711',
          materialsSupplied: ['Italian Marble', 'Quartz Countertops', 'Granite Slabs'],
        );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          onPressed: () => context.pop(),
        ),
        title: Text(v.companyName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: AppColors.surface,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(v.companyName, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    Text('Vendor ID: ${v.id}', style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                    const SizedBox(height: 20),
                    const Divider(color: AppColors.surfaceLight),
                    const SizedBox(height: 16),
                    _buildRow(Icons.person_outline, 'Contact Person', v.contactPerson),
                    const SizedBox(height: 12),
                    _buildRow(Icons.email_outlined, 'Email', v.email),
                    const SizedBox(height: 12),
                    _buildRow(Icons.phone_outlined, 'Phone', v.phone),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('MATERIALS & SUPPLIES', style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
            const SizedBox(height: 12),
            ...v.materialsSupplied.map(
              (m) => Card(
                color: AppColors.surface,
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.check_circle_outline, color: AppColors.success),
                  title: Text(m, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textMuted, size: 18),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        const Spacer(),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }
}
