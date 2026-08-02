import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/reset_password_screen.dart';

import '../../features/dashboard/presentation/screens/dashboard_screen.dart';

import '../../features/leads/presentation/screens/lead_list_screen.dart';
import '../../features/leads/presentation/screens/create_lead_screen.dart';

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

import '../../features/purchase_orders/presentation/screens/purchase_order_list_screen.dart';
import '../../features/site/presentation/screens/site_management_screen.dart';
import '../../features/finance/presentation/screens/finance_dashboard_screen.dart';
import '../../features/documents/presentation/screens/document_list_screen.dart';
import '../../features/reports/presentation/screens/reports_screen.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
      GoRoute(path: '/forgot-password', builder: (context, state) => const ForgotPasswordScreen()),
      GoRoute(path: '/reset-password', builder: (context, state) => const ResetPasswordScreen()),
      
      // Feature Routes
      GoRoute(path: '/dashboard', builder: (context, state) => const DashboardScreen()),
      
      // Leads
      GoRoute(path: '/leads', builder: (context, state) => const LeadListScreen()),
      GoRoute(path: '/leads/create', builder: (context, state) => const CreateLeadScreen()),

      // Projects
      GoRoute(path: '/projects', builder: (context, state) => const ProjectListScreen()),
      GoRoute(
        path: '/projects/details',
        builder: (context, state) => ProjectDetailsScreen(project: state.extra as ProjectModel?),
      ),
      GoRoute(path: '/projects/create', builder: (context, state) => const CreateProjectScreen()),
      
      // Design Drawings
      GoRoute(path: '/design', builder: (context, state) => const DesignListScreen()),

      // Customers
      GoRoute(path: '/customers', builder: (context, state) => const CustomerListScreen()),
      GoRoute(
        path: '/customers/details',
        builder: (context, state) => CustomerDetailsScreen(customer: state.extra as CustomerModel?),
      ),
      GoRoute(path: '/customers/add', builder: (context, state) => const AddCustomerScreen()),

      // BOQ
      GoRoute(path: '/boq', builder: (context, state) => const BoqListScreen()),
      GoRoute(
        path: '/boq/details',
        builder: (context, state) => BoqDetailsScreen(boq: state.extra as BoqModel?),
      ),
      GoRoute(path: '/boq/create', builder: (context, state) => const CreateBoqScreen()),

      // Quotations
      GoRoute(path: '/quotations', builder: (context, state) => const QuotationListScreen()),

      // Vendors
      GoRoute(path: '/vendors', builder: (context, state) => const VendorListScreen()),
      GoRoute(
        path: '/vendors/details',
        builder: (context, state) => VendorDetailsScreen(vendor: state.extra as VendorModel?),
      ),
      GoRoute(path: '/vendors/add', builder: (context, state) => const AddVendorScreen()),

      // Purchase Orders & Site Management
      GoRoute(path: '/purchase_orders', builder: (context, state) => const PurchaseOrderListScreen()),
      GoRoute(path: '/site', builder: (context, state) => const SiteManagementScreen()),

      // Finance, Documents, Reports
      GoRoute(path: '/finance', builder: (context, state) => const FinanceDashboardScreen()),
      GoRoute(path: '/documents', builder: (context, state) => const DocumentListScreen()),
      GoRoute(path: '/reports', builder: (context, state) => const ReportsScreen()),
    ],
  );
}
