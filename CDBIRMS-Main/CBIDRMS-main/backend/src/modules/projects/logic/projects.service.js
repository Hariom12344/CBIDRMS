const prisma = require("../../../config/db");
const projectsRepository = require("../data/projects.repository");

// Helper to generate sequential Project ID: PRJ-<n>
const generateNextProjectId = async () => {
    const latest = await projectsRepository.findLatestProject();
    let nextNum = 101;
    if (latest && latest.id) {
        const match = latest.id.match(/^PRJ-(\d+)$/);
        if (match) {
            nextNum = parseInt(match[1], 10) + 1;
        }
    }
    return `PRJ-${nextNum}`;
};

// List all projects with optional filters
const getProjectsList = async (user, query) => {
    const where = {};

    if (query.status) {
        where.status = query.status;
    }

    if (query.designerName) {
        where.designerName = query.designerName;
    }

    if (user.role === "DESIGNER" && query.own === "true") {
        where.designerName = user.fullName;
    }

    return await projectsRepository.findProjects(where);
};

// Get project by ID
const getProjectById = async (user, id) => {
    const project = await projectsRepository.findProjectById(id);
    if (!project) {
        const err = new Error("Project not found");
        err.statusCode = 404;
        err.errorCode = "PROJECT_NOT_FOUND";
        throw err;
    }
    return project;
};

// Create a new project manually
const createNewProject = async (user, data) => {
    const nextId = await generateNextProjectId();
    const todayStr = new Date().toISOString().split("T")[0];
    
    // Default timeline: 6 months
    const sixMonthsLater = new Date();
    sixMonthsLater.setMonth(sixMonthsLater.getMonth() + 6);
    const endDateStr = sixMonthsLater.toISOString().split("T")[0];

    const projectData = {
        id: nextId,
        name: data.name.trim(),
        clientName: data.clientName.trim(),
        designerName: data.designerName ? data.designerName.trim() : user.fullName,
        startDate: data.startDate || todayStr,
        endDate: data.endDate || endDateStr,
        budget: data.budget !== undefined ? parseFloat(data.budget) : 0.0,
        status: data.status || "PLANNING",
        progress: data.progress !== undefined ? parseFloat(data.progress) : 0.0,
        leadId: data.leadId || null
    };

    return await projectsRepository.createProject(projectData);
};

// Update an existing project
const updateProjectDetails = async (user, id, data) => {
    const project = await getProjectById(user, id);
    const updatePayload = {};

    if (data.name !== undefined) updatePayload.name = data.name.trim();
    if (data.clientName !== undefined) updatePayload.clientName = data.clientName.trim();
    if (data.designerName !== undefined) updatePayload.designerName = data.designerName ? data.designerName.trim() : "";
    if (data.startDate !== undefined) updatePayload.startDate = data.startDate;
    if (data.endDate !== undefined) updatePayload.endDate = data.endDate;
    if (data.budget !== undefined) updatePayload.budget = parseFloat(data.budget);
    if (data.status !== undefined) updatePayload.status = data.status;
    if (data.progress !== undefined) updatePayload.progress = parseFloat(data.progress);

    return await projectsRepository.updateProject(id, updatePayload);
};

// Assign team members to a project
const assignTeamToProject = async (user, id, assignedTeam) => {
    const project = await getProjectById(user, id);

    // Verify all userIds exist
    const userIds = assignedTeam.map(t => t.userId);
    const users = await prisma.user.findMany({
        where: { id: { in: userIds } }
    });

    if (users.length !== userIds.length) {
        const err = new Error("One or more selected team members do not exist");
        err.statusCode = 404;
        err.errorCode = "USER_NOT_FOUND";
        throw err;
    }

    return await projectsRepository.replaceProjectTeam(id, assignedTeam);
};

// Add a stage to a project
const addStageToProject = async (user, id, stageData) => {
    await getProjectById(user, id);
    return await projectsRepository.createProjectStage(id, stageData);
};

// Update a stage status and auto-recalculate project progress
const updateStageStatus = async (user, id, stageId, status) => {
    const project = await getProjectById(user, id);

    const stage = await projectsRepository.findStageById(stageId);
    if (!stage || stage.projectId !== id) {
        const err = new Error("Stage not found on this project");
        err.statusCode = 404;
        err.errorCode = "STAGE_NOT_FOUND";
        throw err;
    }

    await projectsRepository.updateProjectStageStatus(stageId, status);

    // Re-fetch project to get updated stages list
    const updatedProject = await getProjectById(user, id);
    const stages = updatedProject.stages || [];
    
    let newProgress = updatedProject.progress;
    if (stages.length > 0) {
        const doneCount = stages.filter(s => s.status === "done").length;
        newProgress = parseFloat((doneCount / stages.length).toFixed(2));
    }

    // Auto-update project progress
    return await projectsRepository.updateProject(id, { progress: newProgress });
};

module.exports = {
    getProjectsList,
    getProjectById,
    createNewProject,
    updateProjectDetails,
    assignTeamToProject,
    addStageToProject,
    updateStageStatus
};
