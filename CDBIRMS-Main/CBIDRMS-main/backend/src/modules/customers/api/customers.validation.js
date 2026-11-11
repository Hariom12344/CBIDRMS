const { z } = require("zod");

const createCustomerSchema = z.object({
    name: z.string().trim().min(2, "Name must be at least 2 characters").max(100, "Name cannot exceed 100 characters"),
    email: z.string().trim().email("Invalid email address"),
    phone: z.string().trim().min(5, "Phone number is required"),
    address: z.string().trim().min(5, "Address must be at least 5 characters").max(250, "Address cannot exceed 250 characters"),
    companyName: z.string().trim().optional(),
    gstin: z.string().trim().optional(),
    contactPerson: z.string().trim().optional()
});

const updateCustomerSchema = z.object({
    name: z.string().trim().min(2, "Name must be at least 2 characters").max(100, "Name cannot exceed 100 characters").optional(),
    email: z.string().trim().email("Invalid email address").optional(),
    phone: z.string().trim().min(5, "Phone number must be at least 5 characters").optional(),
    address: z.string().trim().min(5, "Address must be at least 5 characters").max(250, "Address cannot exceed 250 characters").optional(),
    companyName: z.string().trim().optional(),
    gstin: z.string().trim().optional(),
    contactPerson: z.string().trim().optional()
});

const queryCustomerSchema = z.object({
    page: z.string().optional().transform((val) => (val ? parseInt(val, 10) : 1)),
    limit: z.string().optional().transform((val) => (val ? parseInt(val, 10) : 20)),
    search: z.string().optional()
});

module.exports = {
    createCustomerSchema,
    updateCustomerSchema,
    queryCustomerSchema
};
