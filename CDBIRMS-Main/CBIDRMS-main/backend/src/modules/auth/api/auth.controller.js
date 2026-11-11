const {
    registerSchema,
    loginSchema,
    forgotPasswordSchema,
    resetPasswordSchema,
    changePasswordSchema
} = require("./auth.validation");

const {
    registerUser,
    loginUser,
    logoutUser,
    refreshTokenUser,
    forgotPasswordUser,
    resetPasswordUser,
    changePasswordUser
} = require("../logic/auth.service");

const extractMeta = (req) => ({
    ip: req.ip || req.headers["x-forwarded-for"] || req.socket.remoteAddress,
    userAgent: req.headers["user-agent"]
});

// helper helper to send standardized response envelope
const sendSuccess = (res, statusCode, message, data = {}) => {
    return res.status(statusCode).json({
        success: true,
        message,
        data,
        error: null
    });
};

const sendError = (res, statusCode, message, errorCode = "AUTH_ERROR") => {
    return res.status(statusCode).json({
        success: false,
        message,
        data: null,
        error: errorCode
    });
};

// REGISTER
const register = async (req, res) => {
    try {
        const validation = registerSchema.safeParse(req.body);
        if (!validation.success) {
            const firstErr = validation.error.issues?.[0]?.message || validation.error.errors?.[0]?.message || "Validation error";
            return sendError(res, 400, firstErr, "VALIDATION_ERROR");
        }

        const result = await registerUser(validation.data, extractMeta(req));

        const { password, ...safeUser } = result.user;

        return sendSuccess(res, 201, "User registered successfully", {
            accessToken: result.accessToken,
            refreshToken: result.refreshToken,
            user: safeUser
        });
    } catch (error) {
        return sendError(
            res,
            error.status || 400,
            error.message,
            error.code || "VALIDATION_ERROR"
        );
    }
};

// LOGIN
const login = async (req, res) => {
    try {
        const validation = loginSchema.safeParse(req.body);
        if (!validation.success) {
            const firstErr = validation.error.issues?.[0]?.message || validation.error.errors?.[0]?.message || "Validation error";
            return sendError(res, 400, firstErr, "VALIDATION_ERROR");
        }

        const result = await loginUser(validation.data, extractMeta(req));

        const { password, ...safeUser } = result.user;

        return sendSuccess(res, 200, "Login successful", {
            accessToken: result.accessToken,
            refreshToken: result.refreshToken,
            user: safeUser
        });
    } catch (error) {
        return sendError(
            res,
            error.status || 401,
            error.message,
            error.code || "INVALID_CREDENTIALS"
        );
    }
};

// LOGOUT
const logout = async (req, res) => {
    try {
        const refreshToken = req.body?.refreshToken;
        const userId = req.user?.id;

        const result = await logoutUser(refreshToken, userId, extractMeta(req));

        return sendSuccess(res, 200, result.message, {});
    } catch (error) {
        // Logout is best-effort
        return sendSuccess(res, 200, "Logout processed", {});
    }
};

// REFRESH TOKEN
const refreshToken = async (req, res) => {
    try {
        const token = req.body?.refreshToken;
        if (!token) {
            return sendError(res, 401, "Refresh token missing", "REFRESH_TOKEN_INVALID");
        }

        const result = await refreshTokenUser(token);

        return sendSuccess(res, 200, "Token refreshed successfully", {
            accessToken: result.accessToken,
            refreshToken: result.refreshToken
        });
    } catch (error) {
        return sendError(
            res,
            error.status || 401,
            error.message,
            error.code || "REFRESH_TOKEN_INVALID"
        );
    }
};

// FORGOT PASSWORD
const forgotPassword = async (req, res) => {
    try {
        const validation = forgotPasswordSchema.safeParse(req.body);
        if (!validation.success) {
            const firstErr = validation.error.issues?.[0]?.message || validation.error.errors?.[0]?.message || "Invalid email format";
            return sendError(res, 400, firstErr, "VALIDATION_ERROR");
        }

        const result = await forgotPasswordUser(validation.data.email, extractMeta(req));

        return sendSuccess(res, 200, result.message);
    } catch (error) {
        return sendError(
            res,
            error.status || 400,
            error.message,
            error.code || "VALIDATION_ERROR"
        );
    }
};

// RESET PASSWORD
const resetPassword = async (req, res) => {
    try {
        const validation = resetPasswordSchema.safeParse(req.body);
        if (!validation.success) {
            const firstErr = validation.error.issues?.[0]?.message || validation.error.errors?.[0]?.message || "Validation error";
            return sendError(res, 400, firstErr, "VALIDATION_ERROR");
        }

        const result = await resetPasswordUser(validation.data, extractMeta(req));

        return sendSuccess(res, 200, result.message, null);
    } catch (error) {
        return sendError(
            res,
            error.status || 400,
            error.message,
            error.code || "RESET_TOKEN_INVALID"
        );
    }
};

// CHANGE PASSWORD (AUTHENTICATED)
const changePassword = async (req, res) => {
    try {
        if (!req.user?.id) {
            return sendError(res, 401, "Unauthorized access", "UNAUTHORIZED");
        }

        const validation = changePasswordSchema.safeParse(req.body);
        if (!validation.success) {
            const firstErr = validation.error.issues?.[0]?.message || validation.error.errors?.[0]?.message || "Validation error";
            return sendError(res, 400, firstErr, "VALIDATION_ERROR");
        }

        const result = await changePasswordUser(req.user.id, validation.data, extractMeta(req));

        return sendSuccess(res, 200, result.message, {});
    } catch (error) {
        return sendError(
            res,
            error.status || 401,
            error.message,
            error.code || "CURRENT_PASSWORD_INCORRECT"
        );
    }
};

module.exports = {
    register,
    login,
    logout,
    refreshToken,
    forgotPassword,
    resetPassword,
    changePassword
};