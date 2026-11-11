import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';

class UserSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final bool isSearching;
  final String selectedRole;
  final ValueChanged<String?> onRoleFilterChanged;

  const UserSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
    this.isSearching = false,
    required this.selectedRole,
    required this.onRoleFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search by name, email, or phone...',
              hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
              prefixIcon: isSearching
                  ? const UnconstrainedBox(
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  : const Icon(Icons.search, color: AppColors.textMuted),
              suffixIcon: controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: AppColors.textMuted),
                      onPressed: onClear,
                    )
                  : null,
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: onChanged,
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedRole.isEmpty ? 'ALL' : selectedRole,
              dropdownColor: AppColors.surface,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              items: const [
                DropdownMenuItem(value: 'ALL', child: Text('All Roles')),
                DropdownMenuItem(value: 'COMPANY_ADMIN', child: Text('Company Admin')),
                DropdownMenuItem(value: 'PROJECT_MANAGER', child: Text('Project Manager')),
                DropdownMenuItem(value: 'SITE_SUPERVISOR', child: Text('Site Supervisor')),
                DropdownMenuItem(value: 'DESIGNER', child: Text('Designer')),
                DropdownMenuItem(value: 'ACCOUNTANT', child: Text('Accountant')),
                DropdownMenuItem(value: 'VENDOR', child: Text('Vendor')),
                DropdownMenuItem(value: 'CLIENT', child: Text('Client')),
              ],
              onChanged: onRoleFilterChanged,
            ),
          ),
        ),
      ],
    );
  }
}
