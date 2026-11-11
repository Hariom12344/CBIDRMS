const prisma = require("../../../config/db");

/**
 * Find cached report generated within the last 24 hours matching parameters.
 */
const findCachedReport = async ({ type, fromDate, toDate, projectId, companyId }) => {
    const twentyFourHoursAgo = new Date(Date.now() - 24 * 60 * 60 * 1000);

    const where = {
        type,
        fromDate,
        toDate,
        createdAt: { gte: twentyFourHoursAgo }
    };

    if (projectId) {
        where.projectId = projectId;
    }
    if (companyId) {
        where.companyId = companyId;
    }

    return await prisma.report.findFirst({
        where,
        orderBy: { createdAt: "desc" }
    });
};

/**
 * Save new generated Report record.
 */
const createReportRecord = async (data) => {
    return await prisma.report.create({
        data
    });
};

/**
 * Fetch report generation history for a user or company.
 */
const findReportHistory = async ({ type, companyId, limit = 50 }) => {
    const where = {};
    if (type && type !== "ALL") {
        where.type = type;
    }
    if (companyId) {
        where.companyId = companyId;
    }

    return await prisma.report.findMany({
        where,
        orderBy: { createdAt: "desc" },
        take: Number(limit)
    });
};

/**
 * Aggregation Queries for Source Data
 */
const fetchProjectReportData = async ({ fromDate, toDate, projectId, companyId }) => {
    const where = {};
    if (projectId) {
        where.id = projectId;
    }
    if (companyId) {
        where.companyId = companyId;
    }

    const projects = await prisma.project.findMany({
        where,
        include: {
            stages: { orderBy: { sortOrder: "asc" } },
            assignedTeam: { include: { user: true } },
            expenses: true,
            projectBudget: true
        },
        orderBy: { createdAt: "desc" }
    });

    return projects;
};

const fetchExpenseReportData = async ({ fromDate, toDate, projectId, companyId }) => {
    const where = {
        date: { gte: fromDate, lte: toDate }
    };
    if (projectId) {
        where.projectId = projectId;
    }
    if (companyId) {
        where.companyId = companyId;
    }

    const expenses = await prisma.expense.findMany({
        where,
        include: { project: true },
        orderBy: { date: "desc" }
    });

    return expenses;
};

const fetchPurchaseReportData = async ({ fromDate, toDate, projectId, companyId }) => {
    const where = {};
    if (projectId) {
        where.projectId = projectId;
    }
    if (companyId) {
        where.companyId = companyId;
    }

    const purchaseOrders = await prisma.purchaseOrder.findMany({
        where,
        include: {
            vendor: true,
            project: true,
            items: true
        },
        orderBy: { createdAt: "desc" }
    });

    return purchaseOrders;
};

const fetchRevenueReportData = async ({ fromDate, toDate, projectId, companyId }) => {
    const invWhere = {};
    if (projectId) {
        invWhere.projectId = projectId;
    }
    if (companyId) {
        invWhere.companyId = companyId;
    }

    const [invoices, payments] = await Promise.all([
        prisma.invoice.findMany({
            where: invWhere,
            include: { project: true, payments: true },
            orderBy: { createdAt: "desc" }
        }),
        prisma.payment.findMany({
            where: { date: { gte: fromDate, lte: toDate } },
            include: { invoice: true },
            orderBy: { date: "desc" }
        })
    ]);

    return { invoices, payments };
};

const fetchVendorReportData = async ({ companyId }) => {
    const where = {};
    if (companyId) {
        where.companyId = companyId;
    }

    const vendors = await prisma.vendor.findMany({
        where,
        include: {
            purchaseOrders: {
                include: { items: true }
            }
        },
        orderBy: { companyName: "asc" }
    });

    return vendors;
};

const fetchTeamReportData = async ({ fromDate, toDate, companyId }) => {
    const where = {};
    if (companyId) {
        where.companyId = companyId;
    }

    const [users, tasks, siteUpdates, activityLogs] = await Promise.all([
        prisma.user.findMany({
            where,
            orderBy: { fullName: "asc" }
        }),
        prisma.siteTask.findMany({
            where,
            include: { project: true, assignee: true },
            orderBy: { createdAt: "desc" }
        }),
        prisma.siteUpdate.findMany({
            where: { updateDate: { gte: fromDate, lte: toDate } },
            include: { project: true, supervisor: true },
            orderBy: { updateDate: "desc" }
        }),
        prisma.activityLog.findMany({
            where: {
                createdAt: {
                    gte: new Date(fromDate),
                    lte: new Date(`${toDate}T23:59:59.999Z`)
                }
            },
            orderBy: { createdAt: "desc" },
            take: 100
        })
    ]);

    return { users, tasks, siteUpdates, activityLogs };
};

module.exports = {
    findCachedReport,
    createReportRecord,
    findReportHistory,
    fetchProjectReportData,
    fetchExpenseReportData,
    fetchPurchaseReportData,
    fetchRevenueReportData,
    fetchVendorReportData,
    fetchTeamReportData
};
