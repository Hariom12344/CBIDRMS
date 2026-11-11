const {
    createVendorSchema,
    updateVendorSchema,
    queryVendorSchema
} = require("./vendors.validation");

const {
    getVendorsList,
    getVendorDetails,
    addVendor,
    editVendor
} = require("../logic/vendors.service");

const sendSuccess = (res, statusCode, message, data = {}) => {
    return res.status(statusCode).json({
        success: true,
        message,
        data,
        error: null
    });
};

const sendError = (res, statusCode, message, errorCode = "VENDOR_ERROR") => {
    return res.status(statusCode).json({
        success: false,
        message,
        data: null,
        error: errorCode
    });
};

const getVendors = async (req, res) => {
    try {
        const queryValidation = queryVendorSchema.safeParse(req.query);
        const { page, limit, search } = queryValidation.success
            ? queryValidation.data
            : { page: 1, limit: 20, search: "" };

        const companyId = req.user?.companyId;

        const result = await getVendorsList({ companyId, search, page, limit });

        return sendSuccess(res, 200, "Vendors fetched successfully", result);
    } catch (error) {
        return sendError(
            res,
            error.status || 500,
            error.message || "Failed to fetch vendors",
            error.code || "VENDOR_ERROR"
        );
    }
};

const getVendorById = async (req, res) => {
    try {
        const vendorId = req.params.id;
        const companyId = req.user?.companyId;

        const result = await getVendorDetails(vendorId, companyId);

        return sendSuccess(res, 200, "Vendor details fetched successfully", result);
    } catch (error) {
        return sendError(
            res,
            error.status || 404,
            error.message || "Vendor not found",
            error.code || "VENDOR_NOT_FOUND"
        );
    }
};

const createVendor = async (req, res) => {
    try {
        const validation = createVendorSchema.safeParse(req.body);
        if (!validation.success) {
            const firstErr = validation.error.errors[0]?.message || "Validation error";
            return sendError(res, 400, firstErr, "VALIDATION_ERROR");
        }

        const vendor = await addVendor(validation.data, req.user);

        return sendSuccess(res, 201, "Vendor created successfully", { vendor });
    } catch (error) {
        return sendError(
            res,
            error.status || 400,
            error.message || "Failed to create vendor",
            error.code || "VALIDATION_ERROR"
        );
    }
};

const updateVendor = async (req, res) => {
    try {
        const vendorId = req.params.id;
        const validation = updateVendorSchema.safeParse(req.body);

        if (!validation.success) {
            const firstErr = validation.error.errors[0]?.message || "Validation error";
            return sendError(res, 400, firstErr, "VALIDATION_ERROR");
        }

        const companyId = req.user?.companyId;
        const vendor = await editVendor(vendorId, validation.data, companyId);

        return sendSuccess(res, 200, "Vendor updated successfully", { vendor });
    } catch (error) {
        return sendError(
            res,
            error.status || 400,
            error.message || "Failed to update vendor",
            error.code || "VENDOR_NOT_FOUND"
        );
    }
};

module.exports = {
    getVendors,
    getVendorById,
    createVendor,
    updateVendor
};
