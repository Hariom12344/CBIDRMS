const { z } = require("zod");

const poItemSchema = z.object({
    itemName: z.string().min(2, "Item name must be at least 2 characters").max(150),
    unit: z.string().default("nos"),
    quantity: z.number().positive("Quantity must be greater than 0"),
    unitPrice: z.number().min(0, "Unit price cannot be negative"),
});

const createPurchaseOrderSchema = z.object({
    vendorId: z.number({ required_error: "vendorId is required" }),
    projectId: z.string().min(1, "projectId is required"),
    boqId: z.string().optional().nullable(),
    date: z.string().optional(),
    items: z.array(poItemSchema).min(1, "Purchase order must contain at least 1 line item"),
});

const updatePurchaseOrderItemsSchema = z.object({
    items: z.array(poItemSchema).min(1, "Purchase order must contain at least 1 line item"),
});

const updatePurchaseOrderStatusSchema = z.object({
    status: z.enum(["Draft", "Approved", "Ordered", "Delivered", "Cancelled"], {
        errorMap: () => ({ message: "Status must be one of: Draft, Approved, Ordered, Delivered, Cancelled" })
    }),
});

module.exports = {
    createPurchaseOrderSchema,
    updatePurchaseOrderItemsSchema,
    updatePurchaseOrderStatusSchema,
};
