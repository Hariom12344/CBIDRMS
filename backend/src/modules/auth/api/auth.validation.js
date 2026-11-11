const { z } = require("zod");

const registerSchema = z.object({
    fullName: z.string().min(3, "Full name must be at least 3 characters"),

    email: z.email("Invalid email address"),

    password: z.string().min(8, "Password must be at least 8 characters"),

    role: z.enum(["ADMIN", "MANAGER", "DESIGNER", "ACCOUNTANT"])
});

module.exports = {
    registerSchema
};