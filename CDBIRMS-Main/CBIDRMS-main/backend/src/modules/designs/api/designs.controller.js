const { createDesignSchema, createRevisionSchema, approveDesignSchema } = require("./designs.validation");
const {
    getDesignsList,
    getDesignById,
    createDesign,
    createRevision,
    approveOrRejectDesign,
    getDownloadLink,
    serveFile
} = require("../logic/designs.service");

const sendSuccess = (res, statusCode, message, data = {}) => {
    return res.status(statusCode).json({
        success: true,
        message,
        data,
        error: null
    });
};

const sendError = (res, statusCode, message, errorCode = "DESIGN_ERROR") => {
    return res.status(statusCode).json({
        success: false,
        message,
        data: null,
        error: errorCode
    });
};

const getDesigns = async (req, res) => {
    try {
        const { projectId, category, search, page, limit } = req.query;

        const result = await getDesignsList({
            projectId,
            category,
            search,
            page: page ? parseInt(page, 10) : 1,
            limit: limit ? parseInt(limit, 10) : 50,
            currentUser: req.user
        });

        return sendSuccess(res, 200, "Designs retrieved successfully", result);
    } catch (error) {
        return sendError(
            res,
            error.status || 500,
            error.message || "Failed to fetch designs",
            error.code || "DESIGN_ERROR"
        );
    }
};

const getDesign = async (req, res) => {
    try {
        const { id } = req.params;
        const result = await getDesignById(id, req.user);

        return sendSuccess(res, 200, "Design details retrieved successfully", result);
    } catch (error) {
        return sendError(
            res,
            error.status || 404,
            error.message || "Design not found",
            error.code || "DESIGN_NOT_FOUND"
        );
    }
};

const createDesignRoute = async (req, res) => {
    try {
        const parsed = createDesignSchema.safeParse(req.body);

        if (!parsed.success) {
            const firstError = parsed.error.issues[0]?.message || "Validation failed";
            return sendError(res, 400, firstError, "VALIDATION_ERROR");
        }

        if (!req.file && (!req.body.fileUrl || req.body.fileUrl.trim() === "")) {
            return sendError(res, 400, "Design file is required", "VALIDATION_ERROR");
        }

        const design = await createDesign({
            ...parsed.data,
            file: req.file,
            fileUrl: req.body.fileUrl,
            fileType: req.body.fileType,
            fileSize: req.body.fileSize
        }, req.user);

        return sendSuccess(res, 201, "Design uploaded successfully", { design });
    } catch (error) {
        return sendError(
            res,
            error.status || 500,
            error.message || "Failed to upload design",
            error.code || "DESIGN_ERROR"
        );
    }
};

const createRevisionRoute = async (req, res) => {
    try {
        const { id } = req.params;
        const parsed = createRevisionSchema.safeParse(req.body);

        if (!parsed.success) {
            const firstError = parsed.error.issues[0]?.message || "Validation failed";
            return sendError(res, 400, firstError, "VALIDATION_ERROR");
        }

        if (!req.file && (!req.body.fileUrl || req.body.fileUrl.trim() === "")) {
            return sendError(res, 400, "Revision file is required", "VALIDATION_ERROR");
        }

        const revision = await createRevision(id, {
            ...parsed.data,
            file: req.file,
            fileUrl: req.body.fileUrl,
            fileType: req.body.fileType,
            fileSize: req.body.fileSize
        }, req.user);

        return sendSuccess(res, 201, "Design revision created successfully", { design: revision });
    } catch (error) {
        return sendError(
            res,
            error.status || 500,
            error.message || "Failed to create design revision",
            error.code || "DESIGN_ERROR"
        );
    }
};

const approveDesignRoute = async (req, res) => {
    try {
        const { id } = req.params;
        const parsed = approveDesignSchema.safeParse(req.body);

        if (!parsed.success) {
            const firstError = parsed.error.issues[0]?.message || "Validation failed";
            return sendError(res, 400, firstError, "VALIDATION_ERROR");
        }

        const updatedDesign = await approveOrRejectDesign(id, parsed.data, req.user);

        return sendSuccess(
            res,
            200,
            `Design ${parsed.data.action === "APPROVE" ? "approved" : "revision requested"} successfully`,
            { design: updatedDesign }
        );
    } catch (error) {
        return sendError(
            res,
            error.status || 404,
            error.message || "Failed to process design approval",
            error.code || "DESIGN_NOT_FOUND"
        );
    }
};

const downloadDesign = async (req, res) => {
    try {
        const { id } = req.params;
        const downloadInfo = await getDownloadLink(id, req.user);

        return sendSuccess(res, 200, "Download URL generated successfully", downloadInfo);
    } catch (error) {
        return sendError(
            res,
            error.status || 404,
            error.message || "Design not found",
            error.code || "DESIGN_NOT_FOUND"
        );
    }
};

const serveDesignFile = async (req, res) => {
    try {
        const { id } = req.params;
        await serveFile(id, res);
    } catch (error) {
        return sendError(
            res,
            error.status || 404,
            error.message || "Design file not found",
            error.code || "DESIGN_NOT_FOUND"
        );
    }
};

module.exports = {
    getDesigns,
    getDesign,
    createDesignRoute,
    createRevisionRoute,
    approveDesignRoute,
    downloadDesign,
    serveDesignFile
};
