const { z } = require("zod");

// Helper to strip non-digit characters from phone strings
const sanitizePhone = (val) => (typeof val === "string" ? val.replace(/\D/g, "") : val);

const createVendorSchema = z.object({
    companyName: z
        .string()
        .trim()
        .min(2, "Company name must be between 2 and 150 characters")
        .max(150, "Company name must be between 2 and 150 characters")
        .refine((val) => val.trim().length > 0, "Company name cannot be blank"),
    contactPerson: z
        .string()
        .trim()
        .min(2, "Contact person must be between 2 and 100 characters")
        .max(100, "Contact person must be between 2 and 100 characters")
        .refine((val) => val.trim().length > 0, "Contact person cannot be blank"),
    email: z
        .string()
        .trim()
        .email("Invalid email address format")
        .transform((val) => val.toLowerCase()),
    phone: z
        .string()
        .trim()
        .transform(sanitizePhone)
        .refine((val) => /^\d{10}$/.test(val), "Phone number must be a 10-digit number"),
    materialsSupplied: z
        .array(
            z.string().trim().min(1, "Material item cannot be empty").max(50, "Material tag length cannot exceed 50 characters")
        )
        .optional()
        .default([])
        .transform((tags) => {
            if (!Array.isArray(tags)) return [];
            // Case-insensitive deduplication, keeping trimmed values
            const seen = new Set();
            const result = [];
            for (const tag of tags) {
                const trimmed = tag.trim();
                const lower = trimmed.toLowerCase();
                if (trimmed.length > 0 && !seen.has(lower)) {
                    seen.add(lower);
                    result.push(trimmed);
                }
            }
            return result;
        })
});

const updateVendorSchema = createVendorSchema;

const queryVendorSchema = z.object({
    page: z.string().optional().transform((val) => (val ? Math.max(1, parseInt(val, 10) || 1) : 1)),
    limit: z.string().optional().transform((val) => (val ? Math.max(1, parseInt(val, 10) || 20) : 20)),
    search: z.string().optional().default("")
});

module.exports = {
    createVendorSchema,
    updateVendorSchema,
    queryVendorSchema
};
