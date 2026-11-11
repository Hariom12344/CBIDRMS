const { z } = require("zod");

// Zod Validation Schemas per FC-010 §13
const createDesignSchema = z.object({
    title: z.string().trim().min(2, "Title must be between 2 and 150 characters").max(150, "Title must be between 2 and 150 characters"),
    projectId: z.string().min(1, "projectId is required"),
    category: z.enum(["FLOOR_PLAN", "THREE_D_RENDER", "CAD_DRAWING", "ELEVATION", "OTHER"], {
        errorMap: () => ({ message: "Invalid category. Must be one of: FLOOR_PLAN, THREE_D_RENDER, CAD_DRAWING, ELEVATION, OTHER" })
    }).default("THREE_D_RENDER")
});

const createRevisionSchema = z.object({
    title: z.string().trim().min(2, "Title must be between 2 and 150 characters").max(150, "Title must be between 2 and 150 characters").optional(),
    category: z.enum(["FLOOR_PLAN", "THREE_D_RENDER", "CAD_DRAWING", "ELEVATION", "OTHER"]).optional(),
    isMajorVersion: z.union([z.boolean(), z.string().transform(val => val === "true" || val === "1")]).optional().default(false)
});

const approveDesignSchema = z.object({
    action: z.enum(["APPROVE", "REQUEST_REVISION"], {
        errorMap: () => ({ message: "Action must be APPROVE or REQUEST_REVISION" })
    }),
    note: z.string().optional()
});

module.exports = {
    createDesignSchema,
    createRevisionSchema,
    approveDesignSchema
};
