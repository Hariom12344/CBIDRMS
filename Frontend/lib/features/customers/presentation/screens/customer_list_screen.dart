import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/app_drawer_sidebar.dart';
import '../../domain/models/customer_model.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  final List<CustomerModel> _customers = [
    CustomerModel(
      id: 'CUST-001',
      name: 'Robert Vance',
      email: 'robert@vancecorp.com',
      phone: '+1 555-0192',
      address: '742 Evergreen Terrace, Beverly Hills, CA',
      projectHistory: ['Villa Royale Interior Renovation'],
      totalSpent: 125000,
    ),
    CustomerModel(
      id: 'CUST-002',
      name: 'Apex Innovations',
      email: 'contact@apexinno.io',
      phone: '+1 555-0144',
      address: '100 Innovation Way, San Francisco, CA',
      projectHistory: ['TechHub Open Plan Office'],
      totalSpent: 85000,
    ),
    CustomerModel(
      id: 'CUST-003',
      name: 'Elena Rostova',
      email: 'elena@rostovagroup.com',
      phone: '+1 555-0831',
      address: '12 Luxury Drive, Miami, FL',
      projectHistory: ['Ocean View Penthouse Suite', 'Beach Villa Design'],
      totalSpent: 310000,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Customer Directory', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      drawer: const AppDrawerSidebar(currentRoute: '/customers'),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.person_add_alt_1, color: Colors.white),
        label: const Text('Add Customer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () => context.push('/customers/add'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: _customers.length,
        itemBuilder: (context, index) {
          final customer = _customers[index];
          return Card(
            color: AppColors.surface,
            margin: const EdgeInsets.only(bottom: 14),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                backgroundColor: AppColors.primary,
                child: Text(customer.name[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              title: Text(customer.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text('${customer.email} • ${customer.phone}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 6),
                  Text('${customer.projectHistory.length} Projects • \$${customer.totalSpent.toStringAsFixed(0)} Total', style: const TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 16),
              onTap: () => context.push('/customers/details', extra: customer),
            ),
          );
        },
      ),
    );
  }
}
