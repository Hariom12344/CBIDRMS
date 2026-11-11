import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../domain/models/customer_model.dart';

class CustomerDetailsScreen extends StatelessWidget {
  final CustomerModel? customer;

  const CustomerDetailsScreen({super.key, this.customer});

  @override
  Widget build(BuildContext context) {
    final c = customer ??
        CustomerModel(
          id: 'CUST-001',
          name: 'Robert Vance',
          email: 'robert@vancecorp.com',
          phone: '+1 555-0192',
          address: '742 Evergreen Terrace, Beverly Hills, CA',
          projectHistory: ['Villa Royale Interior Renovation'],
          totalSpent: 125000,
        );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          onPressed: () => context.pop(),
        ),
        title: Text(c.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: AppColors.primary,
                          child: Text(c.name[0], style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c.name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                            Text(c.id, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(color: AppColors.surfaceLight),
                    const SizedBox(height: 16),
                    _buildInfo(Icons.email_outlined, 'Email', c.email),
                    const SizedBox(height: 12),
                    _buildInfo(Icons.phone_outlined, 'Phone', c.phone),
                    const SizedBox(height: 12),
                    _buildInfo(Icons.location_on_outlined, 'Address', c.address),
                    const SizedBox(height: 12),
                    _buildInfo(Icons.payments_outlined, 'Lifetime Value', '\$${c.totalSpent.toStringAsFixed(2)}', color: AppColors.success),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('PROJECT HISTORY', style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
            const SizedBox(height: 12),
            ...c.projectHistory.map(
              (p) => Card(
                color: AppColors.surface,
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.folder_outlined, color: AppColors.primary),
                  title: Text(p, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfo(IconData icon, String label, String value, {Color? color}) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textMuted, size: 18),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        const Spacer(),
        Expanded(
          flex: 2,
          child: Text(value, textAlign: TextAlign.right, style: TextStyle(color: color ?? Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        ),
      ],
    );
  }
}
