import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/app_drawer_sidebar.dart';
import '../providers/user_provider.dart';
import '../widgets/user_card.dart';
import '../widgets/user_search_bar.dart';

import '../../../../core/permissions/app_permissions.dart';
import '../../../../core/widgets/access_denied_screen.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class UserListScreen extends ConsumerStatefulWidget {
  const UserListScreen({super.key});

  @override
  ConsumerState<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends ConsumerState<UserListScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(userNotifierProvider.notifier).fetchUsers(isInitialLoad: true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      ref.read(userNotifierProvider.notifier).setSearch(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final currentUser = authState.user;

    if (!AppPermissions.canAccessUserManagement(currentUser?.role)) {
      return const AccessDeniedScreen(
        message: 'Only Super Admins and Company Admins can access the User Management module.',
      );
    }

    final userState = ref.watch(userNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Team / Users',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refresh',
            onPressed: () => ref.read(userNotifierProvider.notifier).fetchUsers(),
          )
        ],
      ),
      drawer: const AppDrawerSidebar(currentRoute: '/users'),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.person_add_alt_1, color: Colors.white),
        label: const Text('Add User', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () => context.push('/users/add'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(userNotifierProvider.notifier).fetchUsers(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Search & Filter Header
              UserSearchBar(
                controller: _searchController,
                isSearching: userState.isSearching,
                onChanged: _onSearchChanged,
                onClear: () {
                  _searchController.clear();
                  ref.read(userNotifierProvider.notifier).setSearch('');
                },
                selectedRole: userState.roleFilter,
                onRoleFilterChanged: (val) {
                  final selected = val == 'ALL' ? '' : (val ?? '');
                  ref.read(userNotifierProvider.notifier).setRoleFilter(selected);
                },
              ),
              const SizedBox(height: 16),

              // Error banner if any
              if (userState.errorMessage != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.error),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          userState.errorMessage!,
                          style: const TextStyle(color: AppColors.error, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),

              // Skeleton loading for initial load
              Expanded(
                child: userState.isLoading
                    ? ListView.builder(
                        itemCount: 4,
                        itemBuilder: (context, index) {
                          return Card(
                            color: AppColors.surface,
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: AppColors.surfaceLight.withValues(alpha: 0.5),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 140,
                                          height: 14,
                                          color: AppColors.surfaceLight.withValues(alpha: 0.5),
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          width: 200,
                                          height: 12,
                                          color: AppColors.surfaceLight.withValues(alpha: 0.3),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      )
                    : userState.users.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.people_outline, color: AppColors.textMuted, size: 48),
                                SizedBox(height: 12),
                                Text(
                                  'No staff users found.',
                                  style: TextStyle(color: AppColors.textMuted, fontSize: 16),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: userState.users.length,
                            itemBuilder: (context, index) {
                              final user = userState.users[index];
                              final isUpdating = userState.updatingUserId == user.id;

                              return UserCard(
                                user: user,
                                isUpdating: isUpdating,
                                onTap: () {
                                  ref.read(userNotifierProvider.notifier).selectUser(user);
                                  context.push('/users/details', extra: user);
                                },
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
