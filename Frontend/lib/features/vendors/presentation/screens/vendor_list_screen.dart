import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/app_drawer_sidebar.dart';
import '../../domain/models/vendor_model.dart';

class VendorListScreen extends StatefulWidget {
  const VendorListScreen({super.key});

  @override
  State<VendorListScreen> createState() => _VendorListScreenState();
}

class _VendorListScreenState extends State<VendorListScreen> {
  final List<VendorModel> _vendors = [
    VendorModel(
      id: 'VND-301',
      companyName: 'Luxe Marble & Granite Co.',
      contactPerson: 'David Miller',
      email: 'david@luxemarble.com',
      phone: '+1 555-0711',
      materialsSupplied: ['Italian Marble', 'Quartz Countertops', 'Granite Slabs'],
    ),
    VendorModel(
      id: 'VND-302',
      companyName: 'TimberCraft Woodworks',
      contactPerson: 'Arthur Pendelton',
      email: 'arthur@timbercraft.io',
      phone: '+1 555-0842',
      materialsSupplied: ['Solid Oak Flooring', 'Custom Cabinetry', 'Teak Paneling'],
    ),
    VendorModel(
      id: 'VND-303',
      companyName: 'Lumina Smart Lighting Solutions',
      contactPerson: 'Claire Bennett',
      email: 'claire@luminalighting.com',
      phone: '+1 555-0912',
      materialsSupplied: ['LED Strips', 'Smart Switches', 'Chandelairs'],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Vendor Directory', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      drawer: const AppDrawerSidebar(currentRoute: '/vendors'),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_business_outlined, color: Colors.white),
        label: const Text('Add Vendor', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () => context.push('/vendors/add'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: _vendors.length,
        itemBuilder: (context, index) {
          final vendor = _vendors[index];
          return Card(
            color: AppColors.surface,
            margin: const EdgeInsets.only(bottom: 14),
            child: ListTile(
              contentPadding: const EdgeInsets.all(18),
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.secondary.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.storefront_outlined, color: AppColors.secondary),
              ),
              title: Text(vendor.companyName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text('Contact: ${vendor.contactPerson} • ${vendor.phone}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: vendor.materialsSupplied
                        .map((m) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(6)),
                              child: Text(m, style: const TextStyle(color: AppColors.textPrimary, fontSize: 11)),
                            ))
                        .toList(),
                  ),
                ],
              ),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 16),
              onTap: () => context.push('/vendors/details', extra: vendor),
            ),
          );
        },
      ),
    );
  }
}
