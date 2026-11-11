const { z } = require("zod");

const passwordPattern = /^(?=.*[A-Za-z])(?=.*\d).{8,}$/;

const loginSchema = z.object({
    email: z.string().trim().email("Invalid email address"),
    password: z.string().min(1, "Password is required")
});

const registerSchema = z.object({
    fullName: z.string().trim().min(2, "Full name must be at least 2 characters").max(100, "Full name cannot exceed 100 characters"),
    email: z.string().trim().email("Invalid email address"),
    password: z.string().regex(passwordPattern, "Password must be at least 8 characters long and contain at least one letter and one number"),
    phone: z.string().optional(),
    role: z.string().min(1, "Role is required")
});

const forgotPasswordSchema = z.object({
    email: z.string().trim().email("Invalid email address")
});

const resetPasswordSchema = z.object({
    token: z.string().optional(),
    resetToken: z.string().optional(),
    newPassword: z.string().min(1, "New password is required").regex(passwordPattern, "Password must be at least 8 characters long and contain at least one letter and one number"),
    confirmPassword: z.string().optional()
}).refine((data) => (data.token && data.token.trim().length > 0) || (data.resetToken && data.resetToken.trim().length > 0), {
    message: "Reset token is required",
    path: ["token"]
}).refine((data) => !data.confirmPassword || data.newPassword === data.confirmPassword, {
    message: "Passwords do not match.",
    path: ["confirmPassword"]
});

const changePasswordSchema = z.object({
    currentPassword: z.string().min(1, "Current password is required"),
    newPassword: z.string().regex(passwordPattern, "New password must be at least 8 characters long and contain at least one letter and one number")
});

module.exports = {
    loginSchema,
    registerSchema,
    forgotPasswordSchema,
    resetPasswordSchema,
    changePasswordSchema
};