const {
    createCustomerSchema,
    updateCustomerSchema,
    queryCustomerSchema
} = require("./customers.validation");

const {
    getCustomersList,
    getCustomerDetails,
    addCustomer,
    editCustomer
} = require("../logic/customers.service");

const sendSuccess = (res, statusCode, message, data = {}) => {
    return res.status(statusCode).json({
        success: true,
        message,
        data,
        error: null
    });
};

const sendError = (res, statusCode, message, errorCode = "CUSTOMER_ERROR") => {
    return res.status(statusCode).json({
        success: false,
        message,
        data: null,
        error: errorCode
    });
};

const getCustomers = async (req, res) => {
    try {
        const queryValidation = queryCustomerSchema.safeParse(req.query);
        const { page, limit, search } = queryValidation.success
            ? queryValidation.data
            : { page: 1, limit: 20, search: "" };

        const companyId = req.user?.companyId;

        const result = await getCustomersList({ companyId, search, page, limit });

        return sendSuccess(res, 200, "Customers fetched successfully", result);
    } catch (error) {
        return sendError(
            res,
            error.status || 500,
            error.message || "Failed to fetch customers",
            error.code || "CUSTOMER_ERROR"
        );
    }
};

const getCustomerById = async (req, res) => {
    try {
        const customerId = req.params.id;
        const companyId = req.user?.companyId;

        const customer = await getCustomerDetails(customerId, companyId);

        return sendSuccess(res, 200, "Customer details fetched successfully", { customer });
    } catch (error) {
        return sendError(
            res,
            error.status || 404,
            error.message || "Customer not found",
            error.code || "CUSTOMER_NOT_FOUND"
        );
    }
};

const createCustomer = async (req, res) => {
    try {
        const validation = createCustomerSchema.safeParse(req.body);
        if (!validation.success) {
            const firstErr = validation.error.errors[0]?.message || "Validation error";
            return sendError(res, 400, firstErr, "VALIDATION_ERROR");
        }

        const customer = await addCustomer(validation.data, req.user);

        return sendSuccess(res, 201, "Customer created successfully", { customer });
    } catch (error) {
        return sendError(
            res,
            error.status || 400,
            error.message || "Failed to create customer",
            error.code || "VALIDATION_ERROR"
        );
    }
};

const updateCustomer = async (req, res) => {
    try {
        const customerId = req.params.id;
        const validation = updateCustomerSchema.safeParse(req.body);

        if (!validation.success) {
            const firstErr = validation.error.errors[0]?.message || "Validation error";
            return sendError(res, 400, firstErr, "VALIDATION_ERROR");
        }

        const companyId = req.user?.companyId;
        const customer = await editCustomer(customerId, validation.data, companyId);

        return sendSuccess(res, 200, "Customer updated successfully", { customer });
    } catch (error) {
        return sendError(
            res,
            error.status || 400,
            error.message || "Failed to update customer",
            error.code || "CUSTOMER_NOT_FOUND"
        );
    }
};

module.exports = {
    getCustomers,
    getCustomerById,
    createCustomer,
    updateCustomer
};
