const { z } = require("zod");

const boqItemSchema = z.object({
    itemName: z.string().min(2, "Item name must be at least 2 characters").max(150),
    unit: z.string().default("nos"),
    quantity: z.number().positive("Quantity must be greater than 0"),
    unitPrice: z.number().min(0, "Unit price cannot be negative"),
});

const createBoqSchema = z.object({
    projectId: z.string().min(1, "projectId is required"),
    items: z.array(boqItemSchema).min(1, "BOQ must contain at least 1 line item"),
});

const updateBoqSchema = z.object({
    items: z.array(boqItemSchema).min(1, "BOQ must contain at least 1 line item"),
});

module.exports = {
    createBoqSchema,
    updateBoqSchema,
};
