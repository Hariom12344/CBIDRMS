const prisma = require("../../../config/db");

// Create new user
const createUser = async (userData) => {
    return await prisma.user.create({
        data: {
            ...userData,
            email: userData.email.toLowerCase()
        }
    });
};

// Find user by email (lowercased)
const findUserByEmail = async (email) => {
    if (!email) return null;
    return await prisma.user.findUnique({
        where: {
            email: email.toLowerCase()
        }
    });
};

// Find user by ID
const findUserById = async (id) => {
    return await prisma.user.findUnique({
        where: { id }
    });
};

// Update user data
const updateUser = async (id, data) => {
    if (data.email) {
        data.email = data.email.toLowerCase();
    }
    return await prisma.user.update({
        where: { id },
        data
    });
};

// RefreshToken repository functions
const createRefreshToken = async ({ userId, tokenHash, expiresAt }) => {
    return await prisma.refreshToken.create({
        data: {
            userId,
            tokenHash,
            expiresAt
        }
    });
};

const findRefreshTokenByHash = async (tokenHash) => {
    return await prisma.refreshToken.findUnique({
        where: { tokenHash },
        include: { user: true }
    });
};

const revokeRefreshToken = async (tokenHash) => {
    try {
        return await prisma.refreshToken.update({
            where: { tokenHash },
            data: { revokedAt: new Date() }
        });
    } catch (_) {
        return null;
    }
};

const revokeAllRefreshTokensForUser = async (userId) => {
    return await prisma.refreshToken.updateMany({
        where: {
            userId,
            revokedAt: null
        },
        data: {
            revokedAt: new Date()
        }
    });
};

// PasswordResetToken repository functions
const createPasswordResetToken = async ({ userId, tokenHash, expiresAt }) => {
    return await prisma.passwordResetToken.create({
        data: {
            userId,
            tokenHash,
            expiresAt
        }
    });
};

const findPasswordResetTokenByHash = async (tokenHash) => {
    return await prisma.passwordResetToken.findUnique({
        where: { tokenHash },
        include: { user: true }
    });
};

const markPasswordResetTokenUsed = async (id) => {
    return await prisma.passwordResetToken.update({
        where: { id },
        data: { usedAt: new Date() }
    });
};

const invalidatePreviousResetTokens = async (userId) => {
    return await prisma.passwordResetToken.updateMany({
        where: {
            userId,
            usedAt: null
        },
        data: {
            usedAt: new Date()
        }
    });
};

// Audit Log repository function
const createAuditLog = async ({ userId, action, performedBy, oldValue, newValue, ipAddress, userAgent }) => {
    try {
        return await prisma.userAuditLog.create({
            data: {
                userId: userId || 0,
                action,
                performedBy: performedBy || userId || 0,
                oldValue: oldValue ? JSON.stringify(oldValue) : null,
                newValue: newValue ? JSON.stringify(newValue) : null,
                ipAddress: ipAddress || null,
                userAgent: userAgent || null
            }
        });
    } catch (e) {
        console.error("Failed to write audit log:", e.message);
        return null;
    }
};

module.exports = {
    createUser,
    findUserByEmail,
    findUserById,
    updateUser,
    createRefreshToken,
    findRefreshTokenByHash,
    revokeRefreshToken,
    revokeAllRefreshTokensForUser,
    createPasswordResetToken,
    findPasswordResetTokenByHash,
    markPasswordResetTokenUsed,
    invalidatePreviousResetTokens,
    createAuditLog
};