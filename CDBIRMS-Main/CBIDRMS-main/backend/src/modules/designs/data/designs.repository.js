const prisma = require("../../../config/db");

const buildWhereClause = ({ projectId, category, search }) => {
    const where = {};

    if (projectId) {
        where.projectId = projectId;
    }

    if (category && category !== "ALL") {
        where.category = category;
    }

    if (search && search.trim() !== "") {
        where.title = {
            contains: search.trim()
        };
    }

    return where;
};

const findDesigns = async ({ projectId, category, search, skip = 0, take = 50 }) => {
    const where = buildWhereClause({ projectId, category, search });

    return await prisma.design.findMany({
        where,
        include: {
            project: {
                select: { id: true, name: true, clientName: true }
            },
            approvalLogs: {
                orderBy: { createdAt: "desc" }
            }
        },
        orderBy: { createdAt: "desc" },
        skip,
        take: Number(take)
    });
};

const countDesigns = async ({ projectId, category, search }) => {
    const where = buildWhereClause({ projectId, category, search });
    return await prisma.design.count({ where });
};

const findDesignById = async (id) => {
    return await prisma.design.findUnique({
        where: { id },
        include: {
            project: {
                select: { id: true, name: true, clientName: true }
            },
            approvalLogs: {
                orderBy: { createdAt: "desc" }
            }
        }
    });
};

const findRevisionChain = async (rootId) => {
    return await prisma.design.findMany({
        where: {
            OR: [
                { id: rootId },
                { rootDesignId: rootId }
            ]
        },
        orderBy: { createdAt: "desc" },
        include: {
            approvalLogs: {
                orderBy: { createdAt: "desc" }
            }
        }
    });
};

const createDesignRecord = async (data) => {
    return await prisma.design.create({
        data,
        include: {
            project: {
                select: { id: true, name: true, clientName: true }
            }
        }
    });
};

const updateDesignStatus = async (id, approvalStatus) => {
    return await prisma.design.update({
        where: { id },
        data: { approvalStatus },
        include: {
            project: {
                select: { id: true, name: true, clientName: true }
            },
            approvalLogs: {
                orderBy: { createdAt: "desc" }
            }
        }
    });
};

const createApprovalLog = async (data) => {
    return await prisma.designApprovalLog.create({
        data
    });
};

const findProjectById = async (id) => {
    return await prisma.project.findUnique({
        where: { id }
    });
};

const findProjectAssignment = async (projectId, userId) => {
    return await prisma.projectTeamMember.findFirst({
        where: {
            projectId,
            userId: Number(userId)
        }
    });
};

const findProjectManagers = async (projectId) => {
    return await prisma.projectTeamMember.findMany({
        where: {
            projectId,
            role: { in: ["PROJECT_MANAGER", "COMPANY_ADMIN", "SUPER_ADMIN"] }
        },
        include: { user: true }
    });
};

const findUserById = async (id) => {
    return await prisma.user.findUnique({
        where: { id: Number(id) }
    });
};

module.exports = {
    findDesigns,
    countDesigns,
    findDesignById,
    findRevisionChain,
    createDesignRecord,
    updateDesignStatus,
    createApprovalLog,
    findProjectById,
    findProjectAssignment,
    findProjectManagers,
    findUserById
};
