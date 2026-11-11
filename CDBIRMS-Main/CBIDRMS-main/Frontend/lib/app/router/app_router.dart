import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/reset_password_screen.dart';
import '../../features/auth/presentation/screens/change_password_screen.dart';

import '../../features/dashboard/presentation/screens/dashboard_screen.dart';

import '../../features/leads/domain/models/lead_model.dart';
import '../../features/leads/presentation/screens/lead_list_screen.dart';
import '../../features/leads/presentation/screens/create_lead_screen.dart';
import '../../features/leads/presentation/screens/lead_detail_screen.dart';

import '../../features/projects/domain/models/project_model.dart';
import '../../features/projects/presentation/screens/project_list_screen.dart';
import '../../features/projects/presentation/screens/project_details_screen.dart';
import '../../features/projects/presentation/screens/create_project_screen.dart';

import '../../features/design/presentation/screens/design_list_screen.dart';

import '../../features/customers/domain/models/customer_model.dart';
import '../../features/customers/presentation/screens/customer_list_screen.dart';
import '../../features/customers/presentation/screens/customer_details_screen.dart';
import '../../features/customers/presentation/screens/add_customer_screen.dart';

import '../../features/boq/domain/models/boq_model.dart';
import '../../features/boq/presentation/screens/boq_list_screen.dart';
import '../../features/boq/presentation/screens/boq_details_screen.dart';
import '../../features/boq/presentation/screens/create_boq_screen.dart';

import '../../features/quotations/presentation/screens/quotation_list_screen.dart';

import '../../features/vendors/domain/models/vendor_model.dart';
import '../../features/vendors/presentation/screens/vendor_list_screen.dart';
import '../../features/vendors/presentation/screens/vendor_details_screen.dart';
import '../../features/vendors/presentation/screens/add_vendor_screen.dart';

import '../../features/purchase_orders/domain/models/purchase_order_model.dart';
import '../../features/purchase_orders/presentation/screens/purchase_order_list_screen.dart';
import '../../features/purchase_orders/presentation/screens/create_purchase_order_screen.dart';
import '../../features/purchase_orders/presentation/screens/purchase_order_details_screen.dart';
import '../../features/site/presentation/screens/site_management_screen.dart';
import '../../features/finance/presentation/screens/finance_dashboard_screen.dart';
import '../../features/documents/presentation/screens/document_list_screen.dart';
import '../../features/reports/presentation/screens/reports_screen.dart';
import '../../features/analytics/presentation/screens/analytics_screen.dart';

import '../../features/users/domain/entities/user_entity.dart';
import '../../features/users/data/models/user_model.dart';
import '../../features/users/presentation/screens/user_list_screen.dart';
import '../../features/users/presentation/screens/add_user_screen.dart';
import '../../features/users/presentation/screens/user_details_screen.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
      GoRoute(path: '/forgot-password', builder: (context, state) => const ForgotPasswordScreen()),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) {
          final token = state.uri.queryParameters['token'] ?? (state.extra as String?);
          return ResetPasswordScreen(initialToken: token);
        },
      ),
      GoRoute(path: '/change-password', builder: (context, state) => const ChangePasswordScreen()),
      
      // Feature Routes
      GoRoute(path: '/dashboard', builder: (context, state) => const DashboardScreen()),
      
      // Leads
      GoRoute(path: '/leads', builder: (context, state) => const LeadListScreen()),
      GoRoute(path: '/leads/create', builder: (context, state) => const CreateLeadScreen()),
      GoRoute(
        path: '/leads/details',
        builder: (context, state) => LeadDetailScreen(lead: state.extra as LeadModel?),
      ),

      // Projects
      GoRoute(path: '/projects', builder: (context, state) => const ProjectListScreen()),
      GoRoute(
        path: '/projects/details',
        builder: (context, state) {
          if (state.extra is ProjectModel) {
            return ProjectDetailsScreen(project: state.extra as ProjectModel);
          } else if (state.extra is String) {
            return ProjectDetailsScreen(projectId: state.extra as String);
          }
          return const ProjectDetailsScreen();
        },
      ),
      GoRoute(path: '/projects/create', builder: (context, state) => const CreateProjectScreen()),
      
      // Design Drawings
      GoRoute(path: '/design', builder: (context, state) => const DesignListScreen()),

      // Customers
      GoRoute(path: '/customers', builder: (context, state) => const CustomerListScreen()),
      GoRoute(
        path: '/customers/details',
        builder: (context, state) {
          final e = state.extra;
          final model = e is CustomerModel ? e : (e is Map<String, dynamic> ? CustomerModel.fromJson(e) : null);
          return CustomerDetailsScreen(customer: model);
        },
      ),
      GoRoute(path: '/customers/add', builder: (context, state) => const AddCustomerScreen()),
      GoRoute(
        path: '/customers/edit',
        builder: (context, state) {
          final e = state.extra;
          final model = e is CustomerModel ? e : (e is Map<String, dynamic> ? CustomerModel.fromJson(e) : null);
          return AddCustomerScreen(customerToEdit: model);
        },
      ),

      // Team & Users Management
      GoRoute(path: '/users', builder: (context, state) => const UserListScreen()),
      GoRoute(
        path: '/users/add',
        builder: (context, state) {
          final e = state.extra;
          final model = e is UserEntity ? e : (e is Map<String, dynamic> ? UserModel.fromJson(e) : null);
          return AddUserScreen(userToEdit: model);
        },
      ),
      GoRoute(
        path: '/users/edit',
        builder: (context, state) {
          final e = state.extra;
          final model = e is UserEntity ? e : (e is Map<String, dynamic> ? UserModel.fromJson(e) : null);
          return AddUserScreen(userToEdit: model);
        },
      ),
      GoRoute(
        path: '/users/details',
        builder: (context, state) {
          final e = state.extra;
          final model = e is UserEntity ? e : (e is Map<String, dynamic> ? UserModel.fromJson(e) : null);
          return UserDetailsScreen(user: model);
        },
      ),

      // BOQ
      GoRoute(path: '/boq', builder: (context, state) => const BoqListScreen()),
      GoRoute(
        path: '/boq/details',
        builder: (context, state) {
          final e = state.extra;
          final model = e is BoqModel ? e : (e is Map<String, dynamic> ? BoqModel.fromJson(e) : null);
          return BoqDetailsScreen(boq: model);
        },
      ),
      GoRoute(path: '/boq/create', builder: (context, state) => const CreateBoqScreen()),

      // Quotations
      GoRoute(path: '/quotations', builder: (context, state) => const QuotationListScreen()),

      // Vendors
      GoRoute(path: '/vendors', builder: (context, state) => const VendorListScreen()),
      GoRoute(
        path: '/vendors/details',
        builder: (context, state) {
          final e = state.extra;
          final model = e is VendorModel ? e : (e is Map<String, dynamic> ? VendorModel.fromJson(e) : null);
          return VendorDetailsScreen(vendor: model);
        },
      ),
      GoRoute(path: '/vendors/add', builder: (context, state) => const AddVendorScreen()),
      GoRoute(
        path: '/vendors/edit',
        builder: (context, state) {
          final e = state.extra;
          final model = e is VendorModel ? e : (e is Map<String, dynamic> ? VendorModel.fromJson(e) : null);
          return AddVendorScreen(vendorToEdit: model);
        },
      ),

      // Purchase Orders & Site Management
      GoRoute(path: '/purchase_orders', builder: (context, state) => const PurchaseOrderListScreen()),
      GoRoute(path: '/purchase_orders/create', builder: (context, state) => const CreatePurchaseOrderScreen()),
      GoRoute(
        path: '/purchase_orders/details',
        builder: (context, state) {
          final e = state.extra;
          final model = e is PurchaseOrderModel ? e : (e is Map<String, dynamic> ? PurchaseOrderModel.fromJson(e) : null);
          return PurchaseOrderDetailsScreen(initialPo: model);
        },
      ),
      GoRoute(path: '/site', builder: (context, state) => const SiteManagementScreen()),

      // Finance, Documents, Reports, Analytics
      GoRoute(path: '/finance', builder: (context, state) => const FinanceDashboardScreen()),
      GoRoute(path: '/documents', builder: (context, state) => const DocumentListScreen()),
      GoRoute(path: '/reports', builder: (context, state) => const ReportsScreen()),
      GoRoute(path: '/analytics', builder: (context, state) => const AnalyticsScreen()),
    ],
  );
}
