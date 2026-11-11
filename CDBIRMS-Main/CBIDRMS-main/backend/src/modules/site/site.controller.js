const { z } = require("zod");
const {
    getSiteUpdatesList,
    createSiteUpdate,
    getSiteTasksList,
    createSiteTask,
    updateSiteTaskStatus
} = require("./site.service");

const sendSuccess = (res, statusCode, message, data = {}) => {
    return res.status(statusCode).json({
        success: true,
        message,
        data,
        error: null
    });
};

const sendError = (res, statusCode, message, errorCode = "SITE_ERROR") => {
    return res.status(statusCode).json({
        success: false,
        message,
        data: null,
        error: errorCode
    });
};

// Zod Schemas
const createSiteUpdateZodSchema = z.object({
    projectId: z.string().min(1, "projectId is required"),
    description: z.string().trim().min(10, "Description must be at least 10 characters").max(2000, "Description cannot exceed 2000 characters"),
    issueReported: z.string().trim().max(500, "Issue description cannot exceed 500 characters").optional().nullable(),
    issueSeverity: z.enum(["LOW", "MEDIUM", "HIGH"]).optional().nullable(),
    photoUrls: z.array(z.string()).optional()
}).refine(data => {
    const hasIssue = Boolean(data.issueReported && data.issueReported.trim().length > 0);
    const hasSeverity = Boolean(data.issueSeverity);
    if (hasIssue && !hasSeverity) return false;
    if (!hasIssue && hasSeverity) return false;
    return true;
}, {
    message: "issueSeverity is required when issueReported is set, and vice versa",
    path: ["issueSeverity"]
});

const createSiteTaskZodSchema = z.object({
    projectId: z.string().min(1, "projectId is required"),
    title: z.string().trim().min(2, "Title must be at least 2 characters").max(150, "Title cannot exceed 150 characters"),
    assignedTo: z.union([z.number(), z.string()]).optional().nullable(),
    dueDate: z.string().optional().nullable()
});

const updateSiteTaskStatusZodSchema = z.object({
    status: z.enum(["PENDING", "IN_PROGRESS", "DONE"]),
    linkedSiteUpdateId: z.string().optional().nullable()
});

// Controllers
const getSiteUpdates = async (req, res) => {
    try {
        const { projectId, page, limit } = req.query;

        const result = await getSiteUpdatesList({
            projectId,
            page: page ? parseInt(page, 10) : 1,
            limit: limit ? parseInt(limit, 10) : 50,
            companyId: req.user?.companyId
        });

        return sendSuccess(res, 200, "Site updates retrieved successfully", result);
    } catch (error) {
        return sendError(
            res,
            error.status || 500,
            error.message || "Failed to fetch site updates",
            error.code || "SITE_ERROR"
        );
    }
};

const postSiteUpdate = async (req, res) => {
    try {
        let photoUrls = [];

        // If photoUrls is passed in req.body (e.g. JSON array string or array)
        if (req.body.photoUrls) {
            if (typeof req.body.photoUrls === "string") {
                try {
                    photoUrls = JSON.parse(req.body.photoUrls);
                } catch (e) {
                    photoUrls = [req.body.photoUrls];
                }
            } else if (Array.isArray(req.body.photoUrls)) {
                photoUrls = req.body.photoUrls;
            }
        }

        // If files uploaded via multer
        if (req.files && Array.isArray(req.files) && req.files.length > 0) {
            const host = req.get("host") || "localhost:5000";
            const protocol = req.protocol || "http";
            const fileUrls = req.files.map(f => `${protocol}://${host}/uploads/site-photos/${f.filename}`);
            photoUrls = [...photoUrls, ...fileUrls];
        }

        if (photoUrls.length > 10) {
            return sendError(res, 400, "Maximum 10 photos allowed per site update", "VALIDATION_ERROR");
        }

        const bodyToValidate = {
            ...req.body,
            photoUrls
        };

        // Standardize issueReported null if empty
        if (!bodyToValidate.issueReported || bodyToValidate.issueReported.trim() === "" || bodyToValidate.issueReported === "None") {
            bodyToValidate.issueReported = null;
            bodyToValidate.issueSeverity = null;
        }

        const parsed = createSiteUpdateZodSchema.safeParse(bodyToValidate);
        if (!parsed.success) {
            const firstError = parsed.error.issues[0]?.message || "Validation failed";
            return sendError(res, 400, firstError, "VALIDATION_ERROR");
        }

        const update = await createSiteUpdate(parsed.data, req.user);
        return sendSuccess(res, 201, "Site update posted successfully", { update });
    } catch (error) {
        return sendError(
            res,
            error.status || 500,
            error.message || "Failed to post site update",
            error.code || "SITE_ERROR"
        );
    }
};

const getSiteTasks = async (req, res) => {
    try {
        const { projectId } = req.query;

        const result = await getSiteTasksList({
            projectId,
            companyId: req.user?.companyId
        });

        return sendSuccess(res, 200, "Site tasks retrieved successfully", result);
    } catch (error) {
        return sendError(
            res,
            error.status || 500,
            error.message || "Failed to fetch site tasks",
            error.code || "SITE_ERROR"
        );
    }
};

const postSiteTask = async (req, res) => {
    try {
        const parsed = createSiteTaskZodSchema.safeParse(req.body);
        if (!parsed.success) {
            const firstError = parsed.error.issues[0]?.message || "Validation failed";
            return sendError(res, 400, firstError, "VALIDATION_ERROR");
        }

        const task = await createSiteTask(parsed.data, req.user);
        return sendSuccess(res, 201, "Site task created successfully", { task });
    } catch (error) {
        return sendError(
            res,
            error.status || 500,
            error.message || "Failed to create site task",
            error.code || "SITE_ERROR"
        );
    }
};

const updateTaskStatusRoute = async (req, res) => {
    try {
        const { id } = req.params;
        const parsed = updateSiteTaskStatusZodSchema.safeParse(req.body);
        if (!parsed.success) {
            const firstError = parsed.error.issues[0]?.message || "Validation failed";
            return sendError(res, 400, firstError, "VALIDATION_ERROR");
        }

        const task = await updateSiteTaskStatus(id, parsed.data, req.user);
        return sendSuccess(res, 200, "Task status updated successfully", { task });
    } catch (error) {
        return sendError(
            res,
            error.status || 500,
            error.message || "Failed to update task status",
            error.code || "SITE_ERROR"
        );
    }
};

module.exports = {
    getSiteUpdates,
    postSiteUpdate,
    getSiteTasks,
    postSiteTask,
    updateTaskStatusRoute
};
