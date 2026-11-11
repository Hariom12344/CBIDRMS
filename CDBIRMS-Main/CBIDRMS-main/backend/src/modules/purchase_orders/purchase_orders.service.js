const {
    findPurchaseOrders,
    findPurchaseOrderById,
    createPurchaseOrder,
    updatePurchaseOrderItems,
    updatePurchaseOrderStatus,
    deletePurchaseOrder
} = require("./purchase_orders.repository");
const { findVendorById } = require("../vendors/data/vendors.repository");
const { findProjectById } = require("../projects/data/projects.repository");
const { logActivity } = require("../dashboard/dashboard.service");

const ALLOWED_TRANSITIONS = {
    "Draft": ["Approved", "Cancelled"],
    "Approved": ["Ordered", "Cancelled"],
    "Ordered": ["Delivered"],
    "Delivered": [],
    "Cancelled": []
};

const isAdminRole = (role) => {
    return ["SUPER_ADMIN", "COMPANY_ADMIN", "ADMIN"].includes(role);
};

const getPurchaseOrdersService = async (user, query = {}) => {
    const filter = {};
    if (user.companyId) {
        filter.companyId = user.companyId;
    }
    if (query.status) {
        filter.status = query.status;
    }
    if (query.vendorId) {
        filter.vendorId = parseInt(query.vendorId, 10);
    }
    if (query.projectId) {
        filter.projectId = query.projectId;
    }

    return await findPurchaseOrders(filter);
};

const getPurchaseOrderByIdService = async (id) => {
    const po = await findPurchaseOrderById(id);
    if (!po) {
        const err = new Error("PO_NOT_FOUND");
        err.statusCode = 404;
        throw err;
    }
    return po;
};

const createPurchaseOrderService = async (data, user) => {
    const { vendorId, projectId, boqId, date, items } = data;

    // Fetch Vendor
    const vendor = await findVendorById(vendorId);
    if (!vendor) {
        const err = new Error("VENDOR_NOT_FOUND");
        err.statusCode = 404;
        throw err;
    }

    // Fetch Project
    const project = await findProjectById(projectId);
    if (!project) {
        const err = new Error("PROJECT_NOT_FOUND");
        err.statusCode = 404;
        throw err;
    }

    // Compute totalAmount server-side
    const totalAmount = items.reduce((sum, item) => sum + (item.quantity * item.unitPrice), 0);

    const po = await createPurchaseOrder({
        vendorId,
        vendorName: vendor.companyName,
        projectId,
        projectName: project.name,
        boqId: boqId || null,
        status: "Draft",
        totalAmount,
        companyId: user.companyId || null,
        createdBy: user.fullName || "System Admin",
        date: date || new Date().toISOString().split("T")[0],
        items
    });

    // Log Activity
    await logActivity({
        companyId: user.companyId,
        type: "PO_CREATED",
        message: `Purchase Order created for vendor '${vendor.companyName}' on project '${project.name}' (Total ₹${totalAmount.toFixed(2)})`,
        actorId: user.id,
        actorName: user.fullName,
        relatedEntityType: "PURCHASE_ORDER",
        relatedEntityId: po.id
    });

    return po;
};

const updatePurchaseOrderItemsService = async (id, data, user) => {
    const existingPo = await findPurchaseOrderById(id);
    if (!existingPo) {
        const err = new Error("PO_NOT_FOUND");
        err.statusCode = 404;
        throw err;
    }

    if (existingPo.status !== "Draft") {
        const err = new Error("PO_LOCKED");
        err.statusCode = 409;
        throw err;
    }

    const { items } = data;
    const totalAmount = items.reduce((sum, item) => sum + (item.quantity * item.unitPrice), 0);

    const updatedPo = await updatePurchaseOrderItems(id, {
        totalAmount,
        items
    });

    await logActivity({
        companyId: user.companyId,
        type: "PO_ITEMS_EDITED",
        message: `Items updated on Purchase Order for vendor '${existingPo.vendorName}' (Total ₹${totalAmount.toFixed(2)})`,
        actorId: user.id,
        actorName: user.fullName,
        relatedEntityType: "PURCHASE_ORDER",
        relatedEntityId: id
    });

    return updatedPo;
};

const updatePurchaseOrderStatusService = async (id, newStatus, user) => {
    const existingPo = await findPurchaseOrderById(id);
    if (!existingPo) {
        const err = new Error("PO_NOT_FOUND");
        err.statusCode = 404;
        throw err;
    }

    const currentStatus = existingPo.status;

    // Same status request -> idempotent
    if (currentStatus === newStatus) {
        return existingPo;
    }

    // State machine check
    const validNextStates = ALLOWED_TRANSITIONS[currentStatus] || [];
    if (!validNextStates.includes(newStatus)) {
        const err = new Error("INVALID_STATUS_TRANSITION");
        err.statusCode = 409;
        throw err;
    }

    // Role authorization per transition
    const userRole = user.role || "COMPANY_ADMIN";

    if (newStatus === "Approved") {
        // Only Admin tier can approve POs
        if (!isAdminRole(userRole)) {
            const err = new Error("FORBIDDEN");
            err.statusCode = 403;
            err.message = "Only an Admin can approve this Purchase Order";
            throw err;
        }
    } else if (newStatus === "Cancelled") {
        if (currentStatus === "Approved" && !isAdminRole(userRole)) {
            const err = new Error("FORBIDDEN");
            err.statusCode = 403;
            err.message = "Only an Admin can cancel an Approved Purchase Order";
            throw err;
        }
    } else if (newStatus === "Delivered") {
        if (!["SUPER_ADMIN", "COMPANY_ADMIN", "ADMIN", "PROJECT_MANAGER", "SITE_SUPERVISOR"].includes(userRole)) {
            const err = new Error("FORBIDDEN");
            err.statusCode = 403;
            throw err;
        }
    }

    const updatedPo = await updatePurchaseOrderStatus(id, newStatus);

    await logActivity({
        companyId: user.companyId,
        type: `PO_${newStatus.toUpperCase()}`,
        message: `Purchase Order status changed from '${currentStatus}' to '${newStatus}' for vendor '${existingPo.vendorName}'`,
        actorId: user.id,
        actorName: user.fullName,
        relatedEntityType: "PURCHASE_ORDER",
        relatedEntityId: id
    });

    return updatedPo;
};

const deletePurchaseOrderService = async (id) => {
    const existingPo = await findPurchaseOrderById(id);
    if (!existingPo) {
        const err = new Error("PO_NOT_FOUND");
        err.statusCode = 404;
        throw err;
    }
    return await deletePurchaseOrder(id);
};

module.exports = {
    getPurchaseOrdersService,
    getPurchaseOrderByIdService,
    createPurchaseOrderService,
    updatePurchaseOrderItemsService,
    updatePurchaseOrderStatusService,
    deletePurchaseOrderService
};
