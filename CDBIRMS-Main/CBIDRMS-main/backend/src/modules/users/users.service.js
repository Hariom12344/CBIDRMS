const prisma = require("../../config/db");
const bcrypt = require("bcrypt");
const crypto = require("crypto");
const { sendUserWelcomeEmail } = require("../../utils/email.service");

/**
 * Exclude sensitive password fields from user object
 */
const sanitizeUser = (user) => {
    if (!user) return null;
    const { password, refreshToken, resetToken, resetTokenExpiry, ...cleanUser } = user;
    return cleanUser;
};

/**
 * List paginated and searchable users
 */
const listUsers = async ({ page = 1, limit = 20, search = "", role = "", companyId = null }) => {
    const pageNum = Math.max(1, parseInt(page, 10) || 1);
    const limitNum = Math.max(1, parseInt(limit, 10) || 20);
    const skip = (pageNum - 1) * limitNum;

    const where = {};

    if (companyId) {
        where.companyId = companyId;
    }

    if (role) {
        where.role = role;
    }

    if (search && search.trim() !== "") {
        const cleanSearch = search.trim();
        where.OR = [
            { fullName: { contains: cleanSearch } },
            { email: { contains: cleanSearch } },
            { phone: { contains: cleanSearch } }
        ];
    }

    const [total, rawUsers] = await prisma.$transaction([
        prisma.user.count({ where }),
        prisma.user.findMany({
            where,
            skip,
            take: limitNum,
            orderBy: { createdAt: "desc" }
        })
    ]);

    const users = rawUsers.map(sanitizeUser);

    return {
        users,
        total,
        page: pageNum,
        limit: limitNum
    };
};

/**
 * Get single user by ID
 */
const getUserById = async (id) => {
    const user = await prisma.user.findUnique({
        where: { id: parseInt(id, 10) }
    });

    if (!user) {
        const error = new Error("User not found");
        error.code = "USER_NOT_FOUND";
        error.status = 404;
        throw error;
    }

    return sanitizeUser(user);
};

/**
 * Create new staff user account
 */
const createUser = async (data, performedByUserId, reqInfo = {}) => {
    const { fullName, email, phone, role, companyId } = data;
    const normalizedEmail = email.toLowerCase().trim();

    // Check email uniqueness
    const existingUser = await prisma.user.findUnique({
        where: { email: normalizedEmail }
    });

    if (existingUser) {
        const error = new Error("Email already registered");
        error.code = "USER_EMAIL_EXISTS";
        error.status = 409;
        throw error;
    }

    // Generate random temporary password and set-password token
    const tempPassword = "Password123";
    const hashedPassword = await bcrypt.hash(tempPassword, 10);
    const resetToken = crypto.randomBytes(32).toString("hex");
    const resetTokenExpiry = new Date(Date.now() + 24 * 60 * 60 * 1000); // 24 hours

    // Prisma Transaction: Create User + UserAuditLog
    const newUser = await prisma.$transaction(async (tx) => {
        const user = await tx.user.create({
            data: {
                fullName,
                email: normalizedEmail,
                phone,
                role,
                password: hashedPassword,
                companyId: companyId ? parseInt(companyId, 10) : null,
                createdBy: performedByUserId ? parseInt(performedByUserId, 10) : null,
                isActive: true,
                passwordSet: true,
                resetToken,
                resetTokenExpiry
            }
        });

        await tx.userAuditLog.create({
            data: {
                userId: user.id,
                action: "USER_CREATED",
                performedBy: parseInt(performedByUserId, 10),
                newValue: JSON.stringify(sanitizeUser(user)),
                ipAddress: reqInfo.ipAddress || null,
                userAgent: reqInfo.userAgent || null
            }
        });

        return user;
    });

    // Dispatch set-password email (via SMTP or console fallback)
    await sendUserWelcomeEmail(normalizedEmail, resetToken);

    return sanitizeUser(newUser);
};

/**
 * Edit existing staff user account
 */
const updateUser = async (id, data, performedByUserId, reqInfo = {}) => {
    const userId = parseInt(id, 10);
    const existingUser = await prisma.user.findUnique({
        where: { id: userId }
    });

    if (!existingUser) {
        const error = new Error("User not found");
        error.code = "USER_NOT_FOUND";
        error.status = 404;
        throw error;
    }

    const updateData = {};
    if (data.fullName !== undefined) updateData.fullName = data.fullName;
    if (data.phone !== undefined) updateData.phone = data.phone;
    if (data.role !== undefined) updateData.role = data.role;

    if (data.email && data.email.toLowerCase().trim() !== existingUser.email) {
        const normalizedEmail = data.email.toLowerCase().trim();
        const emailCheck = await prisma.user.findUnique({
            where: { email: normalizedEmail }
        });
        if (emailCheck) {
            const error = new Error("Email already registered");
            error.code = "USER_EMAIL_EXISTS";
            error.status = 409;
            throw error;
        }
        updateData.email = normalizedEmail;
    }

    // Prisma Transaction: Update User + UserAuditLog
    const updatedUser = await prisma.$transaction(async (tx) => {
        const user = await tx.user.update({
            where: { id: userId },
            data: updateData
        });

        await tx.userAuditLog.create({
            data: {
                userId: user.id,
                action: "USER_UPDATED",
                performedBy: parseInt(performedByUserId, 10),
                oldValue: JSON.stringify(sanitizeUser(existingUser)),
                newValue: JSON.stringify(sanitizeUser(user)),
                ipAddress: reqInfo.ipAddress || null,
                userAgent: reqInfo.userAgent || null
            }
        });

        return user;
    });

    return sanitizeUser(updatedUser);
};

/**
 * Activate or Deactivate staff user account
 */
const updateUserStatus = async (id, isActive, performedByUserId, reqInfo = {}) => {
    const userId = parseInt(id, 10);
    const existingUser = await prisma.user.findUnique({
        where: { id: userId }
    });

    if (!existingUser) {
        const error = new Error("User not found");
        error.code = "USER_NOT_FOUND";
        error.status = 404;
        throw error;
    }

    const action = isActive ? "USER_ACTIVATED" : "USER_DEACTIVATED";

    const updatedUser = await prisma.$transaction(async (tx) => {
        const user = await tx.user.update({
            where: { id: userId },
            data: { isActive }
        });

        await tx.userAuditLog.create({
            data: {
                userId: user.id,
                action,
                performedBy: parseInt(performedByUserId, 10),
                oldValue: JSON.stringify({ isActive: existingUser.isActive }),
                newValue: JSON.stringify({ isActive: user.isActive }),
                ipAddress: reqInfo.ipAddress || null,
                userAgent: reqInfo.userAgent || null
            }
        });

        return user;
    });

    if (!isActive) {
        console.log(`[EMAIL DISPATCH] Deactivation notice sent to ${existingUser.email}`);
    }

    return sanitizeUser(updatedUser);
};

/**
 * Delete worker/staff user account
 */
const deleteUser = async (id, performedByUserId, reqInfo = {}) => {
    const userId = parseInt(id, 10);
    const existingUser = await prisma.user.findUnique({
        where: { id: userId }
    });

    if (!existingUser) {
        const error = new Error("User not found");
        error.code = "USER_NOT_FOUND";
        error.status = 404;
        throw error;
    }

    await prisma.$transaction(async (tx) => {
        await tx.userAuditLog.create({
            data: {
                userId,
                action: "USER_DELETED",
                performedBy: parseInt(performedByUserId, 10),
                oldValue: JSON.stringify(sanitizeUser(existingUser)),
                newValue: null,
                ipAddress: reqInfo.ipAddress || null,
                userAgent: reqInfo.userAgent || null
            }
        });

        await tx.user.delete({
            where: { id: userId }
        });
    });

    return { message: "User account deleted successfully" };
};

module.exports = {
    listUsers,
    getUserById,
    createUser,
    updateUser,
    updateUserStatus,
    deleteUser
};
