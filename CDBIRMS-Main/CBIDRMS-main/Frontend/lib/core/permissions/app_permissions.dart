/// Centralized Role-Based Access Control (RBAC) System for IDPMS
class AppPermissions {
  // Available Role Constants
  static const String superAdmin = 'SUPER_ADMIN';
  static const String companyAdmin = 'COMPANY_ADMIN';
  static const String legacyAdmin = 'ADMIN';
  static const String projectManager = 'PROJECT_MANAGER';
  static const String siteSupervisor = 'SITE_SUPERVISOR';
  static const String designer = 'DESIGNER';
  static const String accountant = 'ACCOUNTANT';
  static const String vendor = 'VENDOR';
  static const String client = 'CLIENT';

  /// User Management Module Access: SUPER_ADMIN, COMPANY_ADMIN, ADMIN
  static bool canAccessUserManagement(String? role) {
    if (role == null) return false;
    return role == superAdmin || role == companyAdmin || role == legacyAdmin;
  }

  /// Can create or manage Company Admins: SUPER_ADMIN only
  static bool canManageCompanyAdmins(String? role) {
    return role == superAdmin;
  }

  /// Can create or edit Customer records: SUPER_ADMIN, COMPANY_ADMIN, ADMIN, PROJECT_MANAGER
  static bool canManageCustomers(String? role) {
    if (role == null) return false;
    return role == superAdmin ||
        role == companyAdmin ||
        role == legacyAdmin ||
        role == projectManager;
  }

  /// Can create or edit Vendor records: SUPER_ADMIN, COMPANY_ADMIN, ADMIN, PROJECT_MANAGER
  static bool canManageVendors(String? role) {
    if (role == null) return false;
    return role == superAdmin ||
        role == companyAdmin ||
        role == legacyAdmin ||
        role == projectManager;
  }

  /// Vendor Module Access: SUPER_ADMIN, COMPANY_ADMIN, ADMIN, PROJECT_MANAGER, SITE_SUPERVISOR, DESIGNER, ACCOUNTANT
  static bool canViewVendors(String? role) {
    if (role == null) return false;
    return role == superAdmin ||
        role == companyAdmin ||
        role == legacyAdmin ||
        role == projectManager ||
        role == siteSupervisor ||
        role == designer ||
        role == accountant;
  }

  /// Can approve Purchase Orders: SUPER_ADMIN, COMPANY_ADMIN, ADMIN only (Separation of Duties)
  static bool canApprovePurchaseOrders(String? role) {
    if (role == null) return false;
    return role == superAdmin || role == companyAdmin || role == legacyAdmin;
  }

  /// Can create or edit Purchase Orders (Draft): SUPER_ADMIN, COMPANY_ADMIN, ADMIN, PROJECT_MANAGER
  static bool canCreatePurchaseOrders(String? role) {
    if (role == null) return false;
    return role == superAdmin ||
        role == companyAdmin ||
        role == legacyAdmin ||
        role == projectManager;
  }

  /// Projects Module Access: SUPER_ADMIN, COMPANY_ADMIN, ADMIN, PROJECT_MANAGER, SITE_SUPERVISOR, DESIGNER
  static bool canAccessProjects(String? role) {
    if (role == null) return false;
    return role == superAdmin ||
        role == companyAdmin ||
        role == legacyAdmin ||
        role == projectManager ||
        role == siteSupervisor ||
        role == designer;
  }

  /// Finance / Accounting Module Access: SUPER_ADMIN, COMPANY_ADMIN, ADMIN, ACCOUNTANT
  static bool canAccessFinance(String? role) {
    if (role == null) return false;
    return role == superAdmin || role == companyAdmin || role == legacyAdmin || role == accountant;
  }

  /// Site Updates Module Access: SUPER_ADMIN, COMPANY_ADMIN, ADMIN, SITE_SUPERVISOR, PROJECT_MANAGER
  static bool canAccessSiteUpdates(String? role) {
    if (role == null) return false;
    return role == superAdmin || role == companyAdmin || role == legacyAdmin || role == siteSupervisor || role == projectManager;
  }

  /// Client Portal Access: CLIENT
  static bool canAccessClientPortal(String? role) {
    return role == client;
  }

  /// Lead Pipeline Module Access: SUPER_ADMIN, COMPANY_ADMIN, ADMIN, PROJECT_MANAGER
  static bool canAccessLeads(String? role) {
    if (role == null) return false;
    return role == superAdmin ||
        role == companyAdmin ||
        role == legacyAdmin ||
        role == projectManager;
  }

  /// Can Delete Leads: SUPER_ADMIN, COMPANY_ADMIN, ADMIN
  static bool canDeleteLeads(String? role) {
    if (role == null) return false;
    return role == superAdmin || role == companyAdmin || role == legacyAdmin;
  }

  /// Check if role is allowed for a specific sidebar navigation path
  static bool isRouteAllowed(String route, String? role) {
    if (role == null) return false;
    if (role == superAdmin) return true; // Super Admin has unrestricted access to all routes

    switch (route) {
      case '/users':
      case '/users/add':
      case '/users/edit':
      case '/users/details':
        return canAccessUserManagement(role);
      case '/leads':
      case '/leads/create':
      case '/leads/detail':
        return canAccessLeads(role);
      case '/finance':
        return canAccessFinance(role);
      case '/site':
        return canAccessSiteUpdates(role);
      case '/client_portal':
        return canAccessClientPortal(role);
      default:
        // By default, clients cannot access internal admin modules
        if (role == client) return route == '/client_portal';
        return true;
    }
  }
}
