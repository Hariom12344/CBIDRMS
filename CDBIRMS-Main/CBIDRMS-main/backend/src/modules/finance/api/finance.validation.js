const { z } = require("zod");

const createInvoiceZodSchema = z.object({
    projectId: z.string().min(1, "projectId is required"),
    clientName: z.string().trim().min(2, "clientName must be at least 2 characters"),
    amount: z.number({ invalid_type_error: "Amount must be a number" }).gt(0, "Amount must be greater than 0"),
    dueDate: z.string().min(1, "dueDate is required")
});

const recordPaymentZodSchema = z.object({
    amount: z.number({ invalid_type_error: "Amount must be a number" }).gt(0, "Payment amount must be greater than 0"),
    date: z.string().optional(),
    method: z.enum(["CASH", "BANK_TRANSFER", "CHEQUE", "UPI", "OTHER"]).optional().default("BANK_TRANSFER"),
    note: z.string().optional()
});

const createExpenseZodSchema = z.object({
    projectId: z.string().min(1, "projectId is required"),
    category: z.enum(["MATERIAL", "LABOR", "VENDOR_PAYMENT", "OTHER"]).default("OTHER"),
    amount: z.number({ invalid_type_error: "Amount must be a number" }).gt(0, "Expense amount must be greater than 0"),
    date: z.string().optional(),
    note: z.string().optional()
});

const setBudgetZodSchema = z.object({
    budget: z.number({ invalid_type_error: "Budget must be a number" }).gte(0, "Budget cannot be negative")
});

module.exports = {
    createInvoiceZodSchema,
    recordPaymentZodSchema,
    createExpenseZodSchema,
    setBudgetZodSchema
};
