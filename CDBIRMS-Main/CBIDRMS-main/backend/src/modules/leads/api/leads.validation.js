const { z } = require("zod");

const createLeadSchema = z.object({
    clientName: z.string()
        .min(2, "Client name must be at least 2 characters")
        .max(120, "Client name cannot exceed 120 characters")
        .refine(val => val.trim().length > 0, "Client name cannot be empty"),
        
    email: z.string()
        .email("Invalid email format")
        .optional()
        .nullable()
        .or(z.literal("")),
        
    phone: z.string()
        .min(7, "Phone number must be at least 7 characters")
        .max(20, "Phone number cannot exceed 20 characters")
        .regex(/^[\d+\-\s]+$/, "Phone number can only contain digits, spaces, plus(+), and hyphens(-)")
        .optional()
        .nullable()
        .or(z.literal("")),
        
    propertyType: z.string()
        .max(120, "Property type description cannot exceed 120 characters")
        .optional()
        .nullable()
        .or(z.literal("")),
        
    estimatedBudget: z.union([z.number(), z.string()])
        .transform(val => {
            if (val === "" || val === null || val === undefined) return undefined;
            const parsed = parseFloat(val);
            if (isNaN(parsed)) return undefined;
            return parsed;
        })
        .pipe(z.number().min(0, "Estimated budget cannot be negative").optional())
        .optional()
        .nullable(),
        
    assignedTo: z.union([z.number(), z.string()])
        .optional()
        .nullable()
});

const updateLeadSchema = createLeadSchema.extend({
    clientName: z.string()
        .min(2, "Client name must be at least 2 characters")
        .max(120, "Client name cannot exceed 120 characters")
        .refine(val => val.trim().length > 0, "Client name cannot be empty")
        .optional(),
        
    status: z.enum(["New", "Contacted", "Meeting Scheduled", "Proposal Sent", "Won", "Lost"], {
        errorMap: () => ({ message: "Invalid status value" })
    }).optional()
}).partial();

module.exports = {
    createLeadSchema,
    updateLeadSchema
};
