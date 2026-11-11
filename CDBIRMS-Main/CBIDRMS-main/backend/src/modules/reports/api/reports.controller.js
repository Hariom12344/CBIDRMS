const { generateReportZodSchema } = require("./reports.validation");
const { generateReport, getReportHistoryList } = require("../logic/reports.service");

const sendSuccess = (res, statusCode, message, data = {}) => {
    return res.status(statusCode).json({
        success: true,
        message,
        data,
        error: null
    });
};

const sendError = (res, statusCode, message, errorCode = "REPORT_ERROR") => {
    return res.status(statusCode).json({
        success: false,
        message,
        data: null,
        error: errorCode
    });
};

const generateReportRoute = async (req, res) => {
    try {
        const { type } = req.params;
        if (!type) {
            return sendError(res, 400, "Report type parameter is required", "VALIDATION_ERROR");
        }

        const parsed = generateReportZodSchema.safeParse(req.body);
        if (!parsed.success) {
            const firstError = parsed.error.issues[0]?.message || "Validation failed";
            return sendError(res, 400, firstError, "VALIDATION_ERROR");
        }

        const report = await generateReport({
            type: type.toUpperCase(),
            ...parsed.data
        }, req.user);

        return sendSuccess(res, 200, "Report generated successfully", { report });
    } catch (error) {
        return sendError(res, error.status || 500, error.message || "Failed to generate report", error.code || "REPORT_ERROR");
    }
};

const getReportHistoryRoute = async (req, res) => {
    try {
        const { type } = req.query;
        const reports = await getReportHistoryList({ type }, req.user);
        return sendSuccess(res, 200, "Report history retrieved successfully", { reports });
    } catch (error) {
        return sendError(res, error.status || 500, error.message || "Failed to fetch report history", error.code || "REPORT_ERROR");
    }
};

module.exports = {
    generateReportRoute,
    getReportHistoryRoute
};
