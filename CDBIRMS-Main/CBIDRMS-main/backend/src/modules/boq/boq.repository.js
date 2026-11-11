const prisma = require("../../config/db");

const boqInclude = {
    items: {
        orderBy: { sortOrder: "asc" }
    },
    project: {
        select: { id: true, name: true, status: true, budget: true }
    }
};

const findBoqs = async (filter = {}) => {
    return await prisma.boq.findMany({
        where: filter,
        include: boqInclude,
        orderBy: { createdAt: "desc" }
    });
};

const findBoqById = async (id) => {
    return await prisma.boq.findUnique({
        where: { id },
        include: boqInclude
    });
};

const findBoqByProjectId = async (projectId) => {
    return await prisma.boq.findUnique({
        where: { projectId },
        include: boqInclude
    });
};

const createBoq = async ({ projectId, projectName, companyId, createdBy, totalCost, items }) => {
    return await prisma.boq.create({
        data: {
            projectId,
            projectName,
            companyId: companyId || null,
            createdBy: createdBy || null,
            totalCost,
            items: {
                create: items.map((item, index) => ({
                    itemName: item.itemName,
                    unit: item.unit || "nos",
                    quantity: item.quantity,
                    unitPrice: item.unitPrice,
                    totalAmount: item.quantity * item.unitPrice,
                    sortOrder: index
                }))
            }
        },
        include: boqInclude
    });
};

const updateBoqItems = async (id, { totalCost, items }) => {
    return await prisma.$transaction(async (tx) => {
        // Delete existing items
        await tx.boqItem.deleteMany({
            where: { boqId: id }
        });

        // Update header & create new items
        return await tx.boq.update({
            where: { id },
            data: {
                totalCost,
                items: {
                    create: items.map((item, index) => ({
                        itemName: item.itemName,
                        unit: item.unit || "nos",
                        quantity: item.quantity,
                        unitPrice: item.unitPrice,
                        totalAmount: item.quantity * item.unitPrice,
                        sortOrder: index
                    }))
                }
            },
            include: boqInclude
        });
    });
};

const deleteBoq = async (id) => {
    return await prisma.boq.delete({
        where: { id }
    });
};

module.exports = {
    findBoqs,
    findBoqById,
    findBoqByProjectId,
    createBoq,
    updateBoqItems,
    deleteBoq
};
