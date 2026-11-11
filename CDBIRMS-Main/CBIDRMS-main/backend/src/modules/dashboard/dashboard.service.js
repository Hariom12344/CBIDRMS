const prisma = require("../../config/db");

// Log an activity entry
const logActivity = async ({ companyId, type, message, actorId, actorName, relatedEntityType, relatedEntityId }) => {
    try {
        return await prisma.activityLog.create({
            data: {
                companyId: companyId || null,
                type,
                message,
                actorId: actorId || null,
                actorName: actorName || "System",
                relatedEntityType: relatedEntityType || null,
                relatedEntityId: relatedEntityId ? String(relatedEntityId) : null,
            }
        });
    } catch (err) {
        console.error("Failed to log activity:", err.message);
        return null;
    }
};

// Calculate summary metrics based on caller role
const getSummary = async (user) => {
    const role = user.role || "COMPANY_ADMIN";

    if (role === "SUPER_ADMIN" || role === "COMPANY_ADMIN" || role === "ADMIN") {
        const totalProjects = await prisma.project.count();
        const activeProjects = await prisma.project.count({
            where: { status: { in: ["PLANNING", "ONGOING", "ON_HOLD"] } }
        });
        const totalClients = await prisma.customer.count();
        const totalVendors = await prisma.user.count({
            where: { role: "VENDOR" }
        });

        // Revenue sum from APPROVED/CONVERTED quotations
        const approvedQuotations = await prisma.quotation.findMany({
            where: { status: { in: ["APPROVED", "CONVERTED"] } },
            select: { grandTotal: true }
        });
        const revenue = approvedQuotations.reduce((sum, q) => sum + (q.grandTotal || 0), 0);

        // Pending payments estimate
        const pendingQuotations = await prisma.quotation.findMany({
            where: { status: { in: ["DRAFT", "SENT"] } },
            select: { grandTotal: true }
        });
        const pendingPayments = pendingQuotations.reduce((sum, q) => sum + (q.grandTotal || 0), 0);

        return {
            role: "ADMIN",
            totalProjects,
            activeProjects,
            totalClients,
            totalVendors,
            revenue,
            pendingPayments
        };
    } else if (role === "PROJECT_MANAGER") {
        const assignedProjects = await prisma.project.count({
            where: {
                OR: [
                    { assignedTeam: { some: { userId: user.id } } },
                    { designerName: user.fullName }
                ]
            }
        });
        const upcomingTasks = await prisma.projectStage.count({
            where: { status: { in: ["pending", "in_progress"] } }
        });
        const pendingApprovals = await prisma.project.count({
            where: { status: "PLANNING" }
        });

        return {
            role: "PROJECT_MANAGER",
            assignedProjects,
            upcomingTasks,
            pendingApprovals
        };
    } else if (role === "SITE_SUPERVISOR") {
        const assignedProjects = await prisma.project.count({
            where: { assignedTeam: { some: { userId: user.id } } }
        });
        const todaysSiteUpdates = await prisma.projectStage.count({
            where: { status: "in_progress" }
        });

        return {
            role: "SITE_SUPERVISOR",
            assignedProjects,
            todaysSiteUpdates,
            pendingMaterialRequests: 0
        };
    } else if (role === "DESIGNER") {
        const assignedProjects = await prisma.project.count({
            where: {
                OR: [
                    { designerName: user.fullName },
                    { assignedTeam: { some: { userId: user.id } } }
                ]
            }
        });
        const pendingDesignReviews = await prisma.project.count({
            where: { status: "PLANNING" }
        });

        return {
            role: "DESIGNER",
            assignedProjects,
            pendingDesignReviews
        };
    } else {
        // ACCOUNTANT or default fallback
        const approvedQuotations = await prisma.quotation.findMany({
            where: { status: { in: ["APPROVED", "CONVERTED"] } },
            select: { grandTotal: true }
        });
        const totalRevenue = approvedQuotations.reduce((sum, q) => sum + (q.grandTotal || 0), 0);

        const pendingQuotations = await prisma.quotation.findMany({
            where: { status: { in: ["DRAFT", "SENT"] } },
            select: { grandTotal: true }
        });
        const pendingPayments = pendingQuotations.reduce((sum, q) => sum + (q.grandTotal || 0), 0);

        return {
            role: "ACCOUNTANT",
            pendingPayments,
            totalRevenue,
            overdueInvoices: 0
        };
    }
};

// Fetch recent activity logs
const getRecentActivities = async (user, limit = 10) => {
    const activities = await prisma.activityLog.findMany({
        take: parseInt(limit, 10),
        orderBy: { createdAt: "desc" }
    });

    if (activities.length === 0) {
        // Return default seeded activities if database is fresh
        return [
            {
                id: 1,
                type: "PROJECT_CREATED",
                message: "Penthouse Luxury Renovation project created",
                actorName: "System Admin",
                createdAt: new Date(Date.now() - 1000 * 60 * 30).toISOString()
            },
            {
                id: 2,
                type: "LEAD_WON",
                message: "Lead Robert Vance converted to active project",
                actorName: "Sales Manager",
                createdAt: new Date(Date.now() - 1000 * 60 * 120).toISOString()
            },
            {
                id: 3,
                type: "QUOTATION_CREATED",
                message: "Quotation TTPL/QTN/2026-27/002 approved",
                actorName: "Project Manager",
                createdAt: new Date(Date.now() - 1000 * 60 * 360).toISOString()
            }
        ];
    }

    return activities;
};

module.exports = {
    logActivity,
    getSummary,
    getRecentActivities
};
