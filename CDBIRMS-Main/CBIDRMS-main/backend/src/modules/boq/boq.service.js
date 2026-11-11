const { findBoqs, findBoqById, findBoqByProjectId, createBoq, updateBoqItems, deleteBoq } = require("./boq.repository");
const { findProjectById } = require("../projects/data/projects.repository");
const { logActivity } = require("../dashboard/dashboard.service");

const getAllBoqsService = async (projectId) => {
    const filter = {};
    if (projectId) {
        filter.projectId = projectId;
    }
    return await findBoqs(filter);
};

const getBoqByIdService = async (id) => {
    const boq = await findBoqById(id);
    if (!boq) {
        throw new Error("BOQ_NOT_FOUND");
    }
    return boq;
};

const createBoqService = async (data, user) => {
    const { projectId, items } = data;

    // Check project exists
    const project = await findProjectById(projectId);
    if (!project) {
        throw new Error("PROJECT_NOT_FOUND");
    }

    // Check BOQ doesn't already exist for this project
    const existingBoq = await findBoqByProjectId(projectId);
    if (existingBoq) {
        throw new Error("BOQ_ALREADY_EXISTS");
    }

    // Compute total cost server-side
    const totalCost = items.reduce((sum, item) => sum + (item.quantity * item.unitPrice), 0);

    const boq = await createBoq({
        projectId,
        projectName: project.name,
        companyId: user.companyId || null,
        createdBy: user.fullName || "System Admin",
        totalCost,
        items
    });

    // Log activity
    await logActivity({
        companyId: user.companyId,
        type: "BOQ_CREATED",
        message: `BOQ created for project '${project.name}' (${items.length} items, total ₹${totalCost.toFixed(2)})`,
        actorId: user.id,
        actorName: user.fullName,
        relatedEntityType: "BOQ",
        relatedEntityId: boq.id
    });

    return boq;
};

const updateBoqService = async (id, data, user) => {
    const { items } = data;

    const existingBoq = await findBoqById(id);
    if (!existingBoq) {
        throw new Error("BOQ_NOT_FOUND");
    }

    const totalCost = items.reduce((sum, item) => sum + (item.quantity * item.unitPrice), 0);

    const updatedBoq = await updateBoqItems(id, {
        totalCost,
        items
    });

    // Log activity
    await logActivity({
        companyId: user.companyId,
        type: "BOQ_UPDATED",
        message: `BOQ for project '${existingBoq.projectName}' updated (${items.length} items, total ₹${totalCost.toFixed(2)})`,
        actorId: user.id,
        actorName: user.fullName,
        relatedEntityType: "BOQ",
        relatedEntityId: updatedBoq.id
    });

    return updatedBoq;
};

const deleteBoqService = async (id) => {
    const existing = await findBoqById(id);
    if (!existing) {
        throw new Error("BOQ_NOT_FOUND");
    }
    return await deleteBoq(id);
};

module.exports = {
    getAllBoqsService,
    getBoqByIdService,
    createBoqService,
    updateBoqService,
    deleteBoqService
};
