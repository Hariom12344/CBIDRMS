import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_textfield.dart';

class CreateProjectScreen extends StatefulWidget {
  const CreateProjectScreen({super.key});

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _clientController = TextEditingController();
  final _designerController = TextEditingController();
  final _budgetController = TextEditingController();
  String _status = 'PLANNING';

  @override
  void dispose() {
    _nameController.dispose();
    _clientController.dispose();
    _designerController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  void _handleCreate() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Project created successfully!'), backgroundColor: AppColors.success),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text('Create Project', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Form(
              key: _formKey,
              child: Card(
                color: AppColors.surface,
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CustomTextField(
                        controller: _nameController,
                        label: 'Project Name',
                        hintText: 'e.g. Skyline Residence',
                        prefixIcon: Icons.home_work_outlined,
                        validator: (v) => v == null || v.trim().isEmpty ? 'Enter project name' : null,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _clientController,
                        label: 'Client Name',
                        hintText: 'John Doe',
                        prefixIcon: Icons.person_outline,
                        validator: (v) => v == null || v.trim().isEmpty ? 'Enter client name' : null,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _designerController,
                        label: 'Assigned Designer',
                        hintText: 'Sarah Jenkins',
                        prefixIcon: Icons.architecture,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _budgetController,
                        label: 'Budget (₹)',
                        hintText: '50000',
                        prefixIcon: Icons.currency_rupee_rounded,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      const Text('Initial Status', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: _status,
                        dropdownColor: AppColors.surface,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(prefixIcon: Icon(Icons.flag_outlined, color: AppColors.textMuted)),
                        items: const [
                          DropdownMenuItem(value: 'PLANNING', child: Text('Planning')),
                          DropdownMenuItem(value: 'ONGOING', child: Text('Ongoing')),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _status = v);
                        },
                      ),
                      const SizedBox(height: 28),
                      CustomButton(
                        text: 'Save & Create Project',
                        onPressed: _handleCreate,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
