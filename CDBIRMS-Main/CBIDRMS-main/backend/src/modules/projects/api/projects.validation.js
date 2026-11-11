const { z } = require("zod");

const createProjectSchema = z.object({
    name: z.string()
        .min(3, "Project name must be at least 3 characters")
        .max(150, "Project name cannot exceed 150 characters")
        .refine(val => val.trim().length > 0, "Project name cannot be empty"),

    clientName: z.string()
        .min(2, "Client name must be at least 2 characters")
        .max(120, "Client name cannot exceed 120 characters")
        .refine(val => val.trim().length > 0, "Client name cannot be empty"),

    designerName: z.string()
        .max(120, "Designer name cannot exceed 120 characters")
        .optional()
        .nullable(),

    startDate: z.string()
        .regex(/^\d{4}-\d{2}-\d{2}$/, "Start date must be in YYYY-MM-DD format")
        .optional()
        .nullable()
        .or(z.literal("")),

    endDate: z.string()
        .regex(/^\d{4}-\d{2}-\d{2}$/, "End date must be in YYYY-MM-DD format")
        .optional()
        .nullable()
        .or(z.literal("")),

    budget: z.union([z.number(), z.string()])
        .transform(val => {
            if (val === "" || val === null || val === undefined) return undefined;
            const parsed = parseFloat(val);
            if (isNaN(parsed)) return undefined;
            return parsed;
        })
        .pipe(z.number().min(0, "Budget cannot be negative").optional())
        .optional()
        .nullable(),

    status: z.enum(["PLANNING", "ONGOING", "COMPLETED", "CANCELLED", "ON_HOLD"]).optional(),

    progress: z.union([z.number(), z.string()])
        .transform(val => {
            if (val === "" || val === null || val === undefined) return undefined;
            const parsed = parseFloat(val);
            if (isNaN(parsed)) return undefined;
            return parsed;
        })
        .pipe(z.number().min(0).max(1, "Progress must be between 0.0 and 1.0").optional())
        .optional()
        .nullable(),

    leadId: z.string().optional().nullable()
});

const updateProjectSchema = z.object({
    name: z.string().min(3).max(150).optional(),
    clientName: z.string().min(2).max(120).optional(),
    designerName: z.string().max(120).optional().nullable(),
    startDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional().nullable(),
    endDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional().nullable(),
    budget: z.number().min(0).optional().nullable(),
    status: z.enum(["PLANNING", "ONGOING", "COMPLETED", "CANCELLED", "ON_HOLD"]).optional(),
    progress: z.number().min(0).max(1).optional().nullable()
});

const assignTeamSchema = z.object({
    assignedTeam: z.array(z.object({
        userId: z.number({ required_error: "userId is required" }),
        role: z.string().optional().nullable()
    }))
});

const addStageSchema = z.object({
    name: z.string().min(2, "Stage name must be at least 2 characters").max(100),
    startDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional().nullable().or(z.literal("")),
    endDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional().nullable().or(z.literal(""))
});

const updateStageStatusSchema = z.object({
    status: z.enum(["pending", "in_progress", "done"], {
        errorMap: () => ({ message: "Status must be pending, in_progress, or done" })
    })
});

module.exports = {
    createProjectSchema,
    updateProjectSchema,
    assignTeamSchema,
    addStageSchema,
    updateStageStatusSchema
};
