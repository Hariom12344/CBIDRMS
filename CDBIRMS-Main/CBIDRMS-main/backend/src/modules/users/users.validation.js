const { z } = require("zod");

const ALLOWED_ROLES = [
    "SUPER_ADMIN",
    "COMPANY_ADMIN",
    "ADMIN",
    "PROJECT_MANAGER",
    "SITE_SUPERVISOR",
    "DESIGNER",
    "ACCOUNTANT",
    "VENDOR",
    "CLIENT"
];

const createUserSchema = z.object({
    fullName: z
        .string({ required_error: "Full name is required" })
        .trim()
        .min(2, "Full name must be at least 2 characters")
        .max(100, "Full name cannot exceed 100 characters")
        .refine((val) => val.trim().length > 0, "Full name cannot be empty or only spaces"),
    email: z
        .string({ required_error: "Email is required" })
        .trim()
        .toLowerCase()
        .email("Invalid email format"),
    phone: z
        .string({ required_error: "Phone number is required" })
        .transform((val) => val.replace(/\D/g, ""))
        .refine((val) => val.length === 10, "Phone number must be exactly 10 digits"),
    role: z
        .string({ required_error: "Role is required" })
        .refine((val) => ALLOWED_ROLES.includes(val), "Invalid role specified")
});

const updateUserSchema = z.object({
    fullName: z
        .string()
        .trim()
        .min(2, "Full name must be at least 2 characters")
        .max(100, "Full name cannot exceed 100 characters")
        .refine((val) => val.trim().length > 0, "Full name cannot be empty or only spaces")
        .optional(),
    email: z
        .string()
        .trim()
        .toLowerCase()
        .email("Invalid email format")
        .optional(),
    phone: z
        .string()
        .transform((val) => val.replace(/\D/g, ""))
        .refine((val) => val.length === 10, "Phone number must be exactly 10 digits")
        .optional(),
    role: z
        .string()
        .refine((val) => ALLOWED_ROLES.includes(val), "Invalid role specified")
        .optional()
});

const updateStatusSchema = z.object({
    isActive: z.boolean({ required_error: "isActive boolean flag is required" })
});

module.exports = {
    ALLOWED_ROLES,
    createUserSchema,
    updateUserSchema,
    updateStatusSchema
};
