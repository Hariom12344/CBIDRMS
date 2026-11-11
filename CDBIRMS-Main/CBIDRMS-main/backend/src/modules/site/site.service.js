const prisma = require("../../config/db");

/**
 * Fetch site updates feed
 */
const getSiteUpdatesList = async ({ projectId, page = 1, limit = 50, companyId }) => {
    const where = {};
    if (projectId) {
        where.projectId = projectId;
    }
    if (companyId) {
        where.companyId = companyId;
    }

    const skip = (page - 1) * limit;

    const [total, updatesRaw] = await Promise.all([
        prisma.siteUpdate.count({ where }),
        prisma.siteUpdate.findMany({
            where,
            include: {
                project: {
                    select: { id: true, name: true }
                },
                supervisor: {
                    select: { id: true, fullName: true, email: true }
                }
            },
            orderBy: { createdAt: "desc" },
            skip,
            take: limit
        })
    ]);

    const updates = updatesRaw.map(u => {
        let photoUrls = [];
        try {
            photoUrls = u.photoUrls ? JSON.parse(u.photoUrls) : [];
        } catch (e) {
            photoUrls = [];
        }

        return {
            id: u.id,
            projectId: u.projectId,
            projectName: u.project?.name || "Unknown Project",
            supervisorId: u.supervisorId,
            supervisorName: u.supervisor?.fullName || "Site Supervisor",
            updateDate: u.updateDate,
            description: u.description,
            issueReported: u.issueReported || null,
            issueSeverity: u.issueSeverity || null,
            photoUrls,
            createdAt: u.createdAt
        };
    });

    return { updates, total, page, limit };
};

/**
 * Post a new site update
 */
const createSiteUpdate = async (data, user) => {
    const { projectId, description, issueReported, issueSeverity, photoUrls = [] } = data;

    // Check if project exists
    const project = await prisma.project.findUnique({
        where: { id: projectId }
    });
    if (!project) {
        const error = new Error("Project not found");
        error.status = 404;
        error.code = "PROJECT_NOT_FOUND";
        throw error;
    }

    const nowIso = new Date().toISOString().split("T")[0];
    const stringifiedPhotos = JSON.stringify(photoUrls);

    const update = await prisma.siteUpdate.create({
        data: {
            projectId,
            supervisorId: user.id && typeof user.id === "number" ? user.id : 1,
            updateDate: nowIso,
            description: description.trim(),
            issueReported: issueReported ? issueReported.trim() : null,
            issueSeverity: issueReported ? issueSeverity : null,
            photoUrls: stringifiedPhotos,
            companyId: user.companyId || null
        },
        include: {
            project: { select: { name: true } },
            supervisor: { select: { fullName: true } }
        }
    });

    // High severity issue notification/activity log
    if (issueSeverity === "HIGH") {
        try {
            await prisma.activityLog.create({
                data: {
                    companyId: user.companyId || null,
                    type: "SITE_ISSUE_HIGH",
                    message: `HIGH Severity Issue reported on site "${project.name}": ${issueReported}`,
                    actorId: user.id && typeof user.id === "number" ? user.id : null,
                    actorName: user.fullName || "Site Supervisor",
                    relatedEntityType: "PROJECT",
                    relatedEntityId: projectId
                }
            });
        } catch (e) {
            console.error("Failed to log activity for high severity issue:", e.message);
        }
    }

    return {
        id: update.id,
        projectId: update.projectId,
        projectName: update.project?.name || project.name,
        supervisorId: update.supervisorId,
        supervisorName: update.supervisor?.fullName || "Site Supervisor",
        updateDate: update.updateDate,
        description: update.description,
        issueReported: update.issueReported,
        issueSeverity: update.issueSeverity,
        photoUrls,
        createdAt: update.createdAt
    };
};

/**
 * Fetch tasks for a project
 */
const getSiteTasksList = async ({ projectId, companyId }) => {
    const where = {};
    if (projectId) {
        where.projectId = projectId;
    }
    if (companyId) {
        where.companyId = companyId;
    }

    const tasksRaw = await prisma.siteTask.findMany({
        where,
        include: {
            project: { select: { id: true, name: true } },
            assignee: { select: { id: true, fullName: true } },
            linkedSiteUpdate: { select: { id: true, description: true } }
        },
        orderBy: { createdAt: "desc" }
    });

    const tasks = tasksRaw.map(t => ({
        id: t.id,
        projectId: t.projectId,
        projectName: t.project?.name || "Unknown Project",
        title: t.title,
        assignedTo: t.assignedTo,
        assigneeName: t.assignee?.fullName || null,
        status: t.status,
        dueDate: t.dueDate,
        linkedSiteUpdateId: t.linkedSiteUpdateId,
        createdAt: t.createdAt,
        updatedAt: t.updatedAt
    }));

    return { tasks };
};

/**
 * Create a new site task
 */
const createSiteTask = async (data, user) => {
    const { projectId, title, assignedTo, dueDate } = data;

    const project = await prisma.project.findUnique({
        where: { id: projectId }
    });
    if (!project) {
        const error = new Error("Project not found");
        error.status = 404;
        error.code = "PROJECT_NOT_FOUND";
        throw error;
    }

    let assignedToId = null;
    if (assignedTo) {
        assignedToId = parseInt(assignedTo, 10);
        if (isNaN(assignedToId)) assignedToId = null;
    }

    const task = await prisma.siteTask.create({
        data: {
            projectId,
            title: title.trim(),
            assignedTo: assignedToId,
            status: "PENDING",
            dueDate: dueDate || null,
            companyId: user.companyId || null
        },
        include: {
            project: { select: { name: true } },
            assignee: { select: { fullName: true } }
        }
    });

    return {
        id: task.id,
        projectId: task.projectId,
        projectName: task.project?.name || project.name,
        title: task.title,
        assignedTo: task.assignedTo,
        assigneeName: task.assignee?.fullName || null,
        status: task.status,
        dueDate: task.dueDate,
        linkedSiteUpdateId: task.linkedSiteUpdateId,
        createdAt: task.createdAt,
        updatedAt: task.updatedAt
    };
};

/**
 * Update task status
 */
const updateSiteTaskStatus = async (id, { status, linkedSiteUpdateId }, user) => {
    const existingTask = await prisma.siteTask.findUnique({
        where: { id }
    });

    if (!existingTask) {
        const error = new Error("Task not found");
        error.status = 404;
        error.code = "TASK_NOT_FOUND";
        throw error;
    }

    const task = await prisma.siteTask.update({
        where: { id },
        data: {
            status,
            ...(linkedSiteUpdateId !== undefined ? { linkedSiteUpdateId } : {})
        },
        include: {
            project: { select: { name: true } },
            assignee: { select: { fullName: true } }
        }
    });

    return {
        id: task.id,
        projectId: task.projectId,
        projectName: task.project?.name || "",
        title: task.title,
        assignedTo: task.assignedTo,
        assigneeName: task.assignee?.fullName || null,
        status: task.status,
        dueDate: task.dueDate,
        linkedSiteUpdateId: task.linkedSiteUpdateId,
        createdAt: task.createdAt,
        updatedAt: task.updatedAt
    };
};

module.exports = {
    getSiteUpdatesList,
    createSiteUpdate,
    getSiteTasksList,
    createSiteTask,
    updateSiteTaskStatus
};
