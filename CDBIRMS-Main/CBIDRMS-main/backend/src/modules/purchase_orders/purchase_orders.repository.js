const prisma = require("../../config/db");

const poInclude = {
    items: {
        orderBy: { sortOrder: "asc" }
    },
    vendor: {
        select: { id: true, companyName: true, contactPerson: true, phone: true, email: true }
    },
    project: {
        select: { id: true, name: true, clientName: true, status: true }
    }
};

const findPurchaseOrders = async (filter = {}) => {
    return await prisma.purchaseOrder.findMany({
        where: filter,
        include: poInclude,
        orderBy: { createdAt: "desc" }
    });
};

const findPurchaseOrderById = async (id) => {
    return await prisma.purchaseOrder.findUnique({
        where: { id },
        include: poInclude
    });
};

const createPurchaseOrder = async ({ vendorId, vendorName, projectId, projectName, boqId, status, totalAmount, companyId, createdBy, date, items }) => {
    return await prisma.purchaseOrder.create({
        data: {
            vendorId,
            vendorName,
            projectId,
            projectName,
            boqId: boqId || null,
            status: status || "Draft",
            totalAmount,
            companyId: companyId || null,
            createdBy: createdBy || null,
            date: date || new Date().toISOString().split("T")[0],
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
        include: poInclude
    });
};

const updatePurchaseOrderItems = async (id, { totalAmount, items }) => {
    return await prisma.$transaction(async (tx) => {
        // Delete existing items
        await tx.poItem.deleteMany({
            where: { purchaseOrderId: id }
        });

        // Update header & create new items
        return await tx.purchaseOrder.update({
            where: { id },
            data: {
                totalAmount,
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
            include: poInclude
        });
    });
};

const updatePurchaseOrderStatus = async (id, status) => {
    return await prisma.purchaseOrder.update({
        where: { id },
        data: { status },
        include: poInclude
    });
};

const deletePurchaseOrder = async (id) => {
    return await prisma.purchaseOrder.delete({
        where: { id }
    });
};

module.exports = {
    findPurchaseOrders,
    findPurchaseOrderById,
    createPurchaseOrder,
    updatePurchaseOrderItems,
    updatePurchaseOrderStatus,
    deletePurchaseOrder
};
