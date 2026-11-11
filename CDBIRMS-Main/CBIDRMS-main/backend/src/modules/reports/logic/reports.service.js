const prisma = require("../../../config/db");
const {
    findCachedReport,
    createReportRecord,
    findReportHistory,
    fetchProjectReportData,
    fetchExpenseReportData,
    fetchPurchaseReportData,
    fetchRevenueReportData,
    fetchVendorReportData,
    fetchTeamReportData
} = require("../data/reports.repository");
const { generateReportDocument } = require("./pdf_generator.service");

// Permissions matrix according to FC-014 §14
const ROLE_PERMISSIONS = {
    PROJECT: ["SUPER_ADMIN", "COMPANY_ADMIN", "ADMIN", "PROJECT_MANAGER", "SITE_SUPERVISOR"],
    EXPENSE: ["SUPER_ADMIN", "COMPANY_ADMIN", "ADMIN", "PROJECT_MANAGER", "ACCOUNTANT"],
    PURCHASE: ["SUPER_ADMIN", "COMPANY_ADMIN", "ADMIN", "PROJECT_MANAGER"],
    REVENUE: ["SUPER_ADMIN", "COMPANY_ADMIN", "ADMIN", "PROJECT_MANAGER", "ACCOUNTANT"],
    VENDOR: ["SUPER_ADMIN", "COMPANY_ADMIN", "ADMIN", "PROJECT_MANAGER"],
    TEAM: ["SUPER_ADMIN", "COMPANY_ADMIN", "ADMIN", "PROJECT_MANAGER", "SITE_SUPERVISOR"]
};

/**
 * Verify user role is permitted for report type.
 */
const verifyRolePermission = (type, role) => {
    const allowed = ROLE_PERMISSIONS[type] || [];
    const normalizedRole = (role || "").toUpperCase();
    if (!allowed.includes(normalizedRole)) {
        const error = new Error(`Role '${role}' is not authorized to generate '${type}' report.`);
        error.status = 403;
        error.code = "FORBIDDEN";
        throw error;
    }
};

/**
 * Generate report or retrieve from 24h cache.
 */
const generateReport = async ({ type, from, to, projectId }, currentUser) => {
    const reportType = type.toUpperCase();
    verifyRolePermission(reportType, currentUser?.role);

    const companyId = currentUser?.companyId || null;

    // 1. Check 24h cache for identical request
    const cached = await findCachedReport({
        type: reportType,
        fromDate: from,
        toDate: to,
        projectId: projectId || null,
        companyId
    });

    if (cached) {
        return cached;
    }

    // 2. Fetch source data for the report type
    let reportData;
    switch (reportType) {
        case "PROJECT":
            reportData = await fetchProjectReportData({ fromDate: from, toDate: to, projectId, companyId });
            break;
        case "EXPENSE":
            reportData = await fetchExpenseReportData({ fromDate: from, toDate: to, projectId, companyId });
            break;
        case "PURCHASE":
            reportData = await fetchPurchaseReportData({ fromDate: from, toDate: to, projectId, companyId });
            break;
        case "REVENUE":
            reportData = await fetchRevenueReportData({ fromDate: from, toDate: to, projectId, companyId });
            break;
        case "VENDOR":
            reportData = await fetchVendorReportData({ companyId });
            break;
        case "TEAM":
            reportData = await fetchTeamReportData({ fromDate: from, toDate: to, companyId });
            break;
        default:
            throw new Error(`Unsupported report type '${type}'`);
    }

    // 3. Generate Report Document
    const count = await prisma.report.count();
    const reportId = `RPT-${reportType}-${new Date().getFullYear()}-${String(count + 1).padStart(3, "0")}`;

    const fileUrl = await generateReportDocument({
        reportId,
        type: reportType,
        fromDate: from,
        toDate: to,
        data: reportData,
        companyName: currentUser?.companyName || "Interior Design PMS"
    });

    // 4. Create Report record
    const reportRecord = await createReportRecord({
        id: reportId,
        type: reportType,
        fromDate: from,
        toDate: to,
        projectId: projectId || null,
        fileUrl,
        companyId,
        generatedBy: currentUser?.id && typeof currentUser.id === "number" ? currentUser.id : null
    });

    // 5. Audit Log entry
    try {
        await prisma.activityLog.create({
            data: {
                companyId,
                type: "REPORT_GENERATED",
                message: `${reportType} Report generated for period ${from} to ${to} (${reportId})`,
                actorId: currentUser?.id && typeof currentUser.id === "number" ? currentUser.id : null,
                actorName: currentUser?.fullName || "User",
                relatedEntityType: "REPORT",
                relatedEntityId: reportId
            }
        });
    } catch (e) {
        console.error("Failed to log activity for report generation:", e.message);
    }

    return reportRecord;
};

/**
 * Get past generated report history.
 */
const getReportHistoryList = async ({ type }, currentUser) => {
    const companyId = currentUser?.companyId || null;
    return await findReportHistory({ type, companyId });
};

module.exports = {
    generateReport,
    getReportHistoryList,
    ROLE_PERMISSIONS
};
