const bcrypt = require("bcrypt");
const crypto = require("crypto");

const {
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
} = require("../data/auth.repository");

const {
    generateAccessToken,
    generateRefreshToken
} = require("../../../utils/token");
const { sendPasswordResetEmail, sendRegistrationWelcomeEmail } = require("../email/passwordResetEmail");

const hashToken = (token) => {
    return crypto.createHash("sha256").update(token).digest("hex");
};

// ================= REGISTER =================

const registerUser = async (userData, reqMeta = {}) => {
    const emailLower = userData.email.trim().toLowerCase();
    const existingUser = await findUserByEmail(emailLower);

    if (existingUser) {
        const error = new Error("Email already registered");
        error.code = "USER_EMAIL_EXISTS";
        error.status = 409;
        throw error;
    }

    const hashedPassword = await bcrypt.hash(userData.password, 10);

    const createData = {
        fullName: userData.fullName.trim(),
        email: emailLower,
        password: hashedPassword,
        role: userData.role,
        passwordSet: true,
        isActive: true
    };

    if (userData.phone) {
        createData.phone = userData.phone.trim();
    }

    const user = await createUser(createData);

    const payload = {
        id: user.id,
        email: user.email,
        role: user.role
    };

    const accessToken = generateAccessToken(payload);
    const refreshToken = generateRefreshToken(payload);
    const refreshTokenHash = hashToken(refreshToken);

    // Save refresh token in RefreshToken table (7 days expiry)
    await createRefreshToken({
        userId: user.id,
        tokenHash: refreshTokenHash,
        expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000)
    });

    await createAuditLog({
        userId: user.id,
        action: "USER_REGISTERED",
        ipAddress: reqMeta.ip,
        userAgent: reqMeta.userAgent,
        newValue: { email: user.email, role: user.role }
    });

    // Send registration welcome email (non-blocking)
    sendRegistrationWelcomeEmail(user.email, user.fullName, user.role).catch(err => {
        console.error(`[REGISTRATION EMAIL ERROR] Failed for ${user.email}:`, err.message);
    });

    return {
        accessToken,
        refreshToken,
        user
    };
};

// ================= LOGIN =================

const loginUser = async (userData, reqMeta = {}) => {
    const emailLower = userData.email.trim().toLowerCase();
    const user = await findUserByEmail(emailLower);

    if (!user || !user.password) {
        await createAuditLog({
            userId: 0,
            action: "LOGIN_FAILED",
            ipAddress: reqMeta.ip,
            userAgent: reqMeta.userAgent,
            newValue: { email: emailLower, reason: "INVALID_CREDENTIALS" }
        });
        const error = new Error("Incorrect email or password.");
        error.code = "INVALID_CREDENTIALS";
        error.status = 401;
        throw error;
    }

    if (user.isActive === false) {
        await createAuditLog({
            userId: user.id,
            action: "LOGIN_FAILED",
            ipAddress: reqMeta.ip,
            userAgent: reqMeta.userAgent,
            newValue: { reason: "ACCOUNT_DEACTIVATED" }
        });
        const error = new Error("Your account has been deactivated. Contact your admin.");
        error.code = "ACCOUNT_DEACTIVATED";
        error.status = 403;
        throw error;
    }

    if (user.passwordSet === false) {
        await createAuditLog({
            userId: user.id,
            action: "LOGIN_FAILED",
            ipAddress: reqMeta.ip,
            userAgent: reqMeta.userAgent,
            newValue: { reason: "PASSWORD_NOT_SET" }
        });
        const error = new Error("Your account setup isn't complete. Check your email for the set-password link.");
        error.code = "PASSWORD_NOT_SET";
        error.status = 403;
        throw error;
    }

    const passwordMatch = await bcrypt.compare(userData.password, user.password);

    if (!passwordMatch) {
        await createAuditLog({
            userId: user.id,
            action: "LOGIN_FAILED",
            ipAddress: reqMeta.ip,
            userAgent: reqMeta.userAgent,
            newValue: { reason: "INVALID_CREDENTIALS" }
        });
        const error = new Error("Incorrect email or password.");
        error.code = "INVALID_CREDENTIALS";
        error.status = 401;
        throw error;
    }

    const payload = {
        id: user.id,
        email: user.email,
        role: user.role
    };

    const accessToken = generateAccessToken(payload);
    const refreshToken = generateRefreshToken(payload);
    const refreshTokenHash = hashToken(refreshToken);

    await createRefreshToken({
        userId: user.id,
        tokenHash: refreshTokenHash,
        expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000)
    });

    await createAuditLog({
        userId: user.id,
        action: "LOGIN_SUCCESS",
        ipAddress: reqMeta.ip,
        userAgent: reqMeta.userAgent
    });

    return {
        accessToken,
        refreshToken,
        user
    };
};

// ================= LOGOUT =================

const logoutUser = async (token, userId, reqMeta = {}) => {
    if (token) {
        const tokenHash = hashToken(token);
        await revokeRefreshToken(tokenHash);
    }

    if (userId) {
        await createAuditLog({
            userId,
            action: "LOGOUT",
            ipAddress: reqMeta.ip,
            userAgent: reqMeta.userAgent
        });
    }

    return {
        message: "Logout successful"
    };
};

// ================= REFRESH TOKEN =================

const refreshTokenUser = async (rawRefreshToken) => {
    if (!rawRefreshToken) {
        const error = new Error("Refresh token missing");
        error.code = "REFRESH_TOKEN_INVALID";
        error.status = 401;
        throw error;
    }

    const tokenHash = hashToken(rawRefreshToken);
    const storedToken = await findRefreshTokenByHash(tokenHash);

    if (!storedToken || storedToken.revokedAt || storedToken.expiresAt < new Date()) {
        const error = new Error("Invalid, revoked, or expired refresh token");
        error.code = "REFRESH_TOKEN_INVALID";
        error.status = 401;
        throw error;
    }

    // Refresh token rotation: revoke used token
    await revokeRefreshToken(tokenHash);

    const user = storedToken.user;
    if (!user || !user.isActive) {
        const error = new Error("Account is inactive or non-existent");
        error.code = "REFRESH_TOKEN_INVALID";
        error.status = 401;
        throw error;
    }

    const payload = {
        id: user.id,
        email: user.email,
        role: user.role
    };

    const newAccessToken = generateAccessToken(payload);
    const newRefreshToken = generateRefreshToken(payload);
    const newRefreshTokenHash = hashToken(newRefreshToken);

    await createRefreshToken({
        userId: user.id,
        tokenHash: newRefreshTokenHash,
        expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000)
    });

    return {
        accessToken: newAccessToken,
        refreshToken: newRefreshToken
    };
};

// ================= FORGOT PASSWORD =================

const forgotPasswordUser = async (email, reqMeta = {}) => {
    const genericResponse = {
        message: "If an account exists for this email, a password reset link has been sent."
    };

    if (!email) return genericResponse;

    const emailLower = email.trim().toLowerCase();
    const user = await findUserByEmail(emailLower);

    if (user) {
        // Invalidate previous active reset tokens for this user
        await invalidatePreviousResetTokens(user.id);

        const rawToken = crypto.randomBytes(32).toString("hex");
        const tokenHash = hashToken(rawToken);

        const expiryMinutes = parseInt(process.env.RESET_TOKEN_EXPIRY_MINUTES || "30", 10);
        const expiresAt = new Date(Date.now() + expiryMinutes * 60 * 1000);

        await createPasswordResetToken({
            userId: user.id,
            tokenHash,
            expiresAt
        });

        await createAuditLog({
            userId: user.id,
            action: "FORGOT_PASSWORD_REQUEST",
            ipAddress: reqMeta.ip,
            userAgent: reqMeta.userAgent
        });

        // Dispatch password reset email (via SMTP or Ethereal test inbox)
        await sendPasswordResetEmail(user.email, rawToken);

        return {
            message: "If an account exists for this email, a password reset link has been sent."
        };
    }

    console.log(`[AUTH SERVICE] Password reset requested for non-existent email: ${emailLower}`);

    // Generic response regardless of email existence (enumeration protection)
    return genericResponse;
};

// ================= RESET PASSWORD =================

const resetPasswordUser = async (data, reqMeta = {}) => {
    const rawToken = data.token || data.resetToken;

    if (!rawToken || typeof rawToken !== "string" || !rawToken.trim()) {
        const error = new Error("Invalid password reset link. Please request a new link.");
        error.code = "RESET_TOKEN_INVALID";
        error.status = 400;
        throw error;
    }

    const tokenHash = hashToken(rawToken.trim());
    const resetRecord = await findPasswordResetTokenByHash(tokenHash);

    if (!resetRecord) {
        const error = new Error("Invalid password reset link. Please request a new link.");
        error.code = "RESET_TOKEN_INVALID";
        error.status = 400;
        throw error;
    }

    if (resetRecord.usedAt) {
        const error = new Error("This password reset link has already been used.");
        error.code = "RESET_TOKEN_USED";
        error.status = 400;
        throw error;
    }

    if (resetRecord.expiresAt < new Date()) {
        const error = new Error("This password reset link has expired. Please request a new link.");
        error.code = "RESET_TOKEN_EXPIRED";
        error.status = 400;
        throw error;
    }

    const user = resetRecord.user;
    const hashedPassword = await bcrypt.hash(data.newPassword, 10);

    await updateUser(user.id, {
        password: hashedPassword,
        passwordSet: true
    });

    await markPasswordResetTokenUsed(resetRecord.id);

    // Invalidate active refresh tokens for defensive security
    await revokeAllRefreshTokensForUser(user.id);

    await createAuditLog({
        userId: user.id,
        action: "PASSWORD_RESET",
        ipAddress: reqMeta.ip,
        userAgent: reqMeta.userAgent
    });

    return {
        message: "Password reset successfully."
    };
};

// ================= CHANGE PASSWORD =================

const changePasswordUser = async (userId, data, reqMeta = {}) => {
    const user = await findUserById(userId);

    if (!user) {
        const error = new Error("User not found");
        error.code = "UNAUTHORIZED";
        error.status = 401;
        throw error;
    }

    const passwordMatch = await bcrypt.compare(data.currentPassword, user.password);

    if (!passwordMatch) {
        const error = new Error("Current password entered is incorrect");
        error.code = "CURRENT_PASSWORD_INCORRECT";
        error.status = 401;
        throw error;
    }

    const hashedPassword = await bcrypt.hash(data.newPassword, 10);

    await updateUser(user.id, {
        password: hashedPassword,
        passwordSet: true
    });

    // Invalidate other sessions
    await revokeAllRefreshTokensForUser(user.id);

    await createAuditLog({
        userId: user.id,
        action: "PASSWORD_CHANGED",
        ipAddress: reqMeta.ip,
        userAgent: reqMeta.userAgent
    });

    return {
        message: "Password changed successfully"
    };
};

module.exports = {
    registerUser,
    loginUser,
    logoutUser,
    refreshTokenUser,
    forgotPasswordUser,
    resetPasswordUser,
    changePasswordUser
};