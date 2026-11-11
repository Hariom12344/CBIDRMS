const userService = require("./users.service");
const { createUserSchema, updateUserSchema, updateStatusSchema } = require("./users.validation");

const extractReqInfo = (req) => ({
    ipAddress: req.ip || req.headers["x-forwarded-for"] || req.connection?.remoteAddress,
    userAgent: req.headers["user-agent"]
});

/**
 * GET /api/users
 */
const getUsers = async (req, res) => {
    try {
        const { page, limit, search, role } = req.query;
        const result = await userService.listUsers({
            page,
            limit,
            search,
            role,
            companyId: req.user?.companyId || null
        });

        return res.status(200).json({
            success: true,
            message: "Users retrieved successfully",
            data: result,
            error: null
        });
    } catch (error) {
        return res.status(error.status || 500).json({
            success: false,
            message: error.message || "Failed to retrieve users",
            data: null,
            error: error.code || "SERVER_ERROR"
        });
    }
};

/**
 * GET /api/users/:id
 */
const getUserById = async (req, res) => {
    try {
        const { id } = req.params;
        const user = await userService.getUserById(id);

        return res.status(200).json({
            success: true,
            message: "User details retrieved successfully",
            data: { user },
            error: null
        });
    } catch (error) {
        return res.status(error.status || 500).json({
            success: false,
            message: error.message || "Failed to fetch user details",
            data: null,
            error: error.code || "SERVER_ERROR"
        });
    }
};

/**
 * POST /api/users
 */
const createUser = async (req, res) => {
    try {
        const validation = createUserSchema.safeParse(req.body);
        if (!validation.success) {
            return res.status(400).json({
                success: false,
                message: validation.error.errors[0]?.message || "Validation failed",
                data: null,
                error: "VALIDATION_ERROR",
                details: validation.error.errors
            });
        }

        const { fullName, email, phone, role } = validation.data;

        // Role restriction check: Only SUPER_ADMIN can create/assign SUPER_ADMIN role
        if (role === "SUPER_ADMIN" && req.user?.role !== "SUPER_ADMIN") {
            return res.status(403).json({
                success: false,
                message: "Company Admins cannot create or assign the Super Admin role.",
                data: null,
                error: "ROLE_NOT_ASSIGNABLE"
            });
        }

        const newUser = await userService.createUser(
            {
                fullName,
                email,
                phone,
                role,
                companyId: req.user?.companyId || null
            },
            req.user.id,
            extractReqInfo(req)
        );

        return res.status(201).json({
            success: true,
            message: "User created. Login details sent to their email.",
            data: { user: newUser },
            error: null
        });
    } catch (error) {
        return res.status(error.status || 500).json({
            success: false,
            message: error.message || "Failed to create user",
            data: null,
            error: error.code || "SERVER_ERROR"
        });
    }
};

/**
 * PUT /api/users/:id
 */
const updateUser = async (req, res) => {
    try {
        const { id } = req.params;
        const validation = updateUserSchema.safeParse(req.body);
        if (!validation.success) {
            return res.status(400).json({
                success: false,
                message: validation.error.errors[0]?.message || "Validation failed",
                data: null,
                error: "VALIDATION_ERROR",
                details: validation.error.errors
            });
        }

        const targetUser = await userService.getUserById(id);
        const { role } = validation.data;

        // Role restriction check: Only SUPER_ADMIN can edit a SUPER_ADMIN account or assign SUPER_ADMIN role
        if ((targetUser.role === "SUPER_ADMIN" || role === "SUPER_ADMIN") && req.user?.role !== "SUPER_ADMIN") {
            return res.status(403).json({
                success: false,
                message: "Company Admins cannot edit Super Admin accounts or assign the Super Admin role.",
                data: null,
                error: "ROLE_NOT_ASSIGNABLE"
            });
        }

        const updatedUser = await userService.updateUser(
            id,
            validation.data,
            req.user.id,
            extractReqInfo(req)
        );

        return res.status(200).json({
            success: true,
            message: "User updated successfully",
            data: { user: updatedUser },
            error: null
        });
    } catch (error) {
        return res.status(error.status || 500).json({
            success: false,
            message: error.message || "Failed to update user",
            data: null,
            error: error.code || "SERVER_ERROR"
        });
    }
};

/**
 * PATCH /api/users/:id/status
 */
const updateUserStatus = async (req, res) => {
    try {
        const { id } = req.params;
        const validation = updateStatusSchema.safeParse(req.body);
        if (!validation.success) {
            return res.status(400).json({
                success: false,
                message: "isActive boolean is required",
                data: null,
                error: "VALIDATION_ERROR"
            });
        }

        const targetUserId = parseInt(id, 10);
        const { isActive } = validation.data;

        // Prevent self-deactivation
        if (req.user?.id === targetUserId && !isActive) {
            return res.status(403).json({
                success: false,
                message: "You cannot deactivate your own account",
                data: null,
                error: "CANNOT_DEACTIVATE_SELF"
            });
        }

        const targetUser = await userService.getUserById(id);
        if (targetUser.role === "SUPER_ADMIN" && req.user?.role !== "SUPER_ADMIN") {
            return res.status(403).json({
                success: false,
                message: "Company Admins cannot deactivate Super Admin accounts.",
                data: null,
                error: "FORBIDDEN"
            });
        }

        const updatedUser = await userService.updateUserStatus(
            id,
            isActive,
            req.user.id,
            extractReqInfo(req)
        );

        return res.status(200).json({
            success: true,
            message: `User account successfully ${isActive ? "activated" : "deactivated"}`,
            data: { user: updatedUser },
            error: null
        });
    } catch (error) {
        return res.status(error.status || 500).json({
            success: false,
            message: error.message || "Failed to update user status",
            data: null,
            error: error.code || "SERVER_ERROR"
        });
    }
};

/**
 * DELETE /api/users/:id
 */
const deleteUser = async (req, res) => {
    try {
        const { id } = req.params;
        const targetUserId = parseInt(id, 10);

        // Self-deletion block
        if (req.user?.id === targetUserId) {
            return res.status(403).json({
                success: false,
                message: "You cannot delete your own account",
                data: null,
                error: "CANNOT_DELETE_SELF"
            });
        }

        const targetUser = await userService.getUserById(id);
        if (
            (targetUser.role === "SUPER_ADMIN" || targetUser.role === "COMPANY_ADMIN") &&
            req.user?.role !== "SUPER_ADMIN"
        ) {
            return res.status(403).json({
                success: false,
                message: "Only Super Admins can delete Company Admin or Super Admin accounts.",
                data: null,
                error: "FORBIDDEN"
            });
        }

        const result = await userService.deleteUser(
            id,
            req.user.id,
            extractReqInfo(req)
        );

        return res.status(200).json({
            success: true,
            message: result.message,
            data: null,
            error: null
        });
    } catch (error) {
        return res.status(error.status || 500).json({
            success: false,
            message: error.message || "Failed to delete user",
            data: null,
            error: error.code || "SERVER_ERROR"
        });
    }
};

module.exports = {
    getUsers,
    getUserById,
    createUser,
    updateUser,
    updateUserStatus,
    deleteUser
};
