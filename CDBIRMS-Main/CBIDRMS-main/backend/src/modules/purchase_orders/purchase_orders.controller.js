const {
    createPurchaseOrderSchema,
    updatePurchaseOrderItemsSchema,
    updatePurchaseOrderStatusSchema
} = require("./purchase_orders.validation");
const {
    getPurchaseOrdersService,
    getPurchaseOrderByIdService,
    createPurchaseOrderService,
    updatePurchaseOrderItemsService,
    updatePurchaseOrderStatusService,
    deletePurchaseOrderService
} = require("./purchase_orders.service");

const getPurchaseOrders = async (req, res) => {
    try {
        const purchaseOrders = await getPurchaseOrdersService(req.user, req.query);
        res.status(200).json({
            success: true,
            message: "Purchase Orders retrieved successfully",
            data: { purchaseOrders },
            error: null
        });
    } catch (error) {
        res.status(error.statusCode || 500).json({
            success: false,
            message: "Failed to retrieve Purchase Orders",
            data: null,
            error: error.message
        });
    }
};

const getPurchaseOrderById = async (req, res) => {
    try {
        const { id } = req.params;
        const purchaseOrder = await getPurchaseOrderByIdService(id);
        res.status(200).json({
            success: true,
            message: "Purchase Order retrieved successfully",
            data: { purchaseOrder },
            error: null
        });
    } catch (error) {
        const statusCode = error.statusCode || 500;
        res.status(statusCode).json({
            success: false,
            message: "Failed to retrieve Purchase Order",
            data: null,
            error: error.message
        });
    }
};

const createPurchaseOrder = async (req, res) => {
    try {
        const validatedData = createPurchaseOrderSchema.parse(req.body);
        const purchaseOrder = await createPurchaseOrderService(validatedData, req.user);
        res.status(201).json({
            success: true,
            message: "Purchase Order created successfully",
            data: { purchaseOrder },
            error: null
        });
    } catch (error) {
        if (error.name === "ZodError") {
            return res.status(400).json({
                success: false,
                message: "VALIDATION_ERROR",
                data: null,
                error: error.errors.map(e => `${e.path.join(".")}: ${e.message}`).join(", ")
            });
        }
        const statusCode = error.statusCode || 500;
        res.status(statusCode).json({
            success: false,
            message: error.message || "Failed to create Purchase Order",
            data: null,
            error: error.message
        });
    }
};

const updatePurchaseOrderItems = async (req, res) => {
    try {
        const { id } = req.params;
        const validatedData = updatePurchaseOrderItemsSchema.parse(req.body);
        const purchaseOrder = await updatePurchaseOrderItemsService(id, validatedData, req.user);
        res.status(200).json({
            success: true,
            message: "Purchase Order items updated successfully",
            data: { purchaseOrder },
            error: null
        });
    } catch (error) {
        if (error.name === "ZodError") {
            return res.status(400).json({
                success: false,
                message: "VALIDATION_ERROR",
                data: null,
                error: error.errors.map(e => `${e.path.join(".")}: ${e.message}`).join(", ")
            });
        }
        const statusCode = error.statusCode || 500;
        res.status(statusCode).json({
            success: false,
            message: error.message || "Failed to update Purchase Order items",
            data: null,
            error: error.message
        });
    }
};

const updatePurchaseOrderStatus = async (req, res) => {
    try {
        const { id } = req.params;
        const validatedData = updatePurchaseOrderStatusSchema.parse(req.body);
        const purchaseOrder = await updatePurchaseOrderStatusService(id, validatedData.status, req.user);
        res.status(200).json({
            success: true,
            message: `Purchase Order status updated to ${validatedData.status}`,
            data: { purchaseOrder },
            error: null
        });
    } catch (error) {
        if (error.name === "ZodError") {
            return res.status(400).json({
                success: false,
                message: "VALIDATION_ERROR",
                data: null,
                error: error.errors.map(e => `${e.path.join(".")}: ${e.message}`).join(", ")
            });
        }
        const statusCode = error.statusCode || 500;
        res.status(statusCode).json({
            success: false,
            message: error.message || "Failed to update Purchase Order status",
            data: null,
            error: error.message
        });
    }
};

const deletePurchaseOrder = async (req, res) => {
    try {
        const { id } = req.params;
        await deletePurchaseOrderService(id);
        res.status(200).json({
            success: true,
            message: "Purchase Order deleted successfully",
            data: null,
            error: null
        });
    } catch (error) {
        const statusCode = error.statusCode || 500;
        res.status(statusCode).json({
            success: false,
            message: "Failed to delete Purchase Order",
            data: null,
            error: error.message
        });
    }
};

module.exports = {
    getPurchaseOrders,
    getPurchaseOrderById,
    createPurchaseOrder,
    updatePurchaseOrderItems,
    updatePurchaseOrderStatus,
    deletePurchaseOrder
};
