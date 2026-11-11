const prisma = require("../../../config/db");

const projectIncludeConfig = {
    assignedTeam: {
        include: {
            user: {
                select: {
                    id: true,
                    fullName: true,
                    email: true,
                    role: true
                }
            }
        }
    },
    stages: {
        orderBy: {
            sortOrder: "asc"
        }
    }
};

// Find all projects with optional filters
const findProjects = async (where = {}) => {
    return await prisma.project.findMany({
        where,
        include: projectIncludeConfig,
        orderBy: {
            createdAt: "desc"
        }
    });
};

// Find project by ID
const findProjectById = async (id) => {
    return await prisma.project.findUnique({
        where: { id },
        include: projectIncludeConfig
    });
};

// Create a new project
const createProject = async (projectData) => {
    return await prisma.project.create({
        data: projectData,
        include: projectIncludeConfig
    });
};

// Update an existing project
const updateProject = async (id, data) => {
    return await prisma.project.update({
        where: { id },
        data,
        include: projectIncludeConfig
    });
};

// Replace team members for a project
const replaceProjectTeam = async (projectId, teamMembers) => {
    return await prisma.$transaction(async (tx) => {
        // Delete current team members for this project
        await tx.projectTeamMember.deleteMany({
            where: { projectId }
        });

        // Insert new team members
        if (teamMembers.length > 0) {
            await tx.projectTeamMember.createMany({
                data: teamMembers.map(m => ({
                    projectId,
                    userId: m.userId,
                    role: m.role || null
                }))
            });
        }

        // Return updated project
        return await tx.project.findUnique({
            where: { id: projectId },
            include: projectIncludeConfig
        });
    });
};

// Create a new stage for a project
const createProjectStage = async (projectId, stageData) => {
    const highestStage = await prisma.projectStage.findFirst({
        where: { projectId },
        orderBy: { sortOrder: "desc" }
    });
    const nextOrder = highestStage ? highestStage.sortOrder + 1 : 1;

    await prisma.projectStage.create({
        data: {
            projectId,
            name: stageData.name,
            startDate: stageData.startDate || null,
            endDate: stageData.endDate || null,
            sortOrder: nextOrder
        }
    });

    return await findProjectById(projectId);
};

// Find stage by ID
const findStageById = async (stageId) => {
    return await prisma.projectStage.findUnique({
        where: { id: parseInt(stageId, 10) }
    });
};

// Update stage status
const updateProjectStageStatus = async (stageId, status) => {
    await prisma.projectStage.update({
        where: { id: parseInt(stageId, 10) },
        data: { status }
    });
};

// Find the last created project to get the sequence ID
const findLatestProject = async () => {
    return await prisma.project.findFirst({
        orderBy: {
            createdAt: "desc"
        }
    });
};

module.exports = {
    findProjects,
    findProjectById,
    createProject,
    updateProject,
    replaceProjectTeam,
    createProjectStage,
    findStageById,
    updateProjectStageStatus,
    findLatestProject
};
