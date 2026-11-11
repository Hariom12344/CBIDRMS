const {
    createInvoiceZodSchema,
    recordPaymentZodSchema,
    createExpenseZodSchema,
    setBudgetZodSchema
} = require("./finance.validation");
const {
    getFinanceSummary,
    getInvoicesList,
    createInvoice,
    recordPayment,
    createExpense,
    getExpensesList,
    getProjectBudgetSummary,
    setProjectBudget
} = require("../logic/finance.service");

const sendSuccess = (res, statusCode, message, data = {}) => {
    return res.status(statusCode).json({
        success: true,
        message,
        data,
        error: null
    });
};

const sendError = (res, statusCode, message, errorCode = "FINANCE_ERROR") => {
    return res.status(statusCode).json({
        success: false,
        message,
        data: null,
        error: errorCode
    });
};

const getSummaryRoute = async (req, res) => {
    try {
        const summary = await getFinanceSummary();
        return sendSuccess(res, 200, "Finance summary retrieved successfully", summary);
    } catch (error) {
        return sendError(res, error.status || 500, error.message || "Failed to fetch summary", error.code || "FINANCE_ERROR");
    }
};

const getInvoicesRoute = async (req, res) => {
    try {
        const { projectId, status, page, limit } = req.query;
        const result = await getInvoicesList({
            projectId,
            status,
            page: page ? parseInt(page, 10) : 1,
            limit: limit ? parseInt(limit, 10) : 50
        });
        return sendSuccess(res, 200, "Invoices retrieved successfully", result);
    } catch (error) {
        return sendError(res, error.status || 500, error.message || "Failed to fetch invoices", error.code || "FINANCE_ERROR");
    }
};

const createInvoiceRoute = async (req, res) => {
    try {
        const parsed = createInvoiceZodSchema.safeParse(req.body);
        if (!parsed.success) {
            const firstError = parsed.error.issues[0]?.message || "Validation failed";
            return sendError(res, 400, firstError, "VALIDATION_ERROR");
        }

        const invoice = await createInvoice(parsed.data, req.user);
        return sendSuccess(res, 201, "Invoice generated successfully", { invoice });
    } catch (error) {
        return sendError(res, error.status || 500, error.message || "Failed to generate invoice", error.code || "FINANCE_ERROR");
    }
};

const recordPaymentRoute = async (req, res) => {
    try {
        const { id } = req.params;
        const parsed = recordPaymentZodSchema.safeParse(req.body);
        if (!parsed.success) {
            const firstError = parsed.error.issues[0]?.message || "Validation failed";
            return sendError(res, 400, firstError, "VALIDATION_ERROR");
        }

        const result = await recordPayment(id, parsed.data, req.user);
        return sendSuccess(res, 201, "Payment recorded successfully", result);
    } catch (error) {
        return sendError(res, error.status || 500, error.message || "Failed to record payment", error.code || "FINANCE_ERROR");
    }
};

const createExpenseRoute = async (req, res) => {
    try {
        const parsed = createExpenseZodSchema.safeParse(req.body);
        if (!parsed.success) {
            const firstError = parsed.error.issues[0]?.message || "Validation failed";
            return sendError(res, 400, firstError, "VALIDATION_ERROR");
        }

        const expense = await createExpense(parsed.data, req.user);
        return sendSuccess(res, 201, "Expense recorded successfully", { expense });
    } catch (error) {
        return sendError(res, error.status || 500, error.message || "Failed to record expense", error.code || "FINANCE_ERROR");
    }
};

const getExpensesRoute = async (req, res) => {
    try {
        const { projectId, category, page, limit } = req.query;
        const result = await getExpensesList({
            projectId,
            category,
            page: page ? parseInt(page, 10) : 1,
            limit: limit ? parseInt(limit, 10) : 50
        });
        return sendSuccess(res, 200, "Expenses retrieved successfully", result);
    } catch (error) {
        return sendError(res, error.status || 500, error.message || "Failed to fetch expenses", error.code || "FINANCE_ERROR");
    }
};

const getBudgetRoute = async (req, res) => {
    try {
        const { id } = req.params;
        const result = await getProjectBudgetSummary(id);
        return sendSuccess(res, 200, "Project budget summary retrieved successfully", result);
    } catch (error) {
        return sendError(res, error.status || 500, error.message || "Failed to fetch project budget", error.code || "FINANCE_ERROR");
    }
};

const setBudgetRoute = async (req, res) => {
    try {
        const { id } = req.params;
        const parsed = setBudgetZodSchema.safeParse(req.body);
        if (!parsed.success) {
            const firstError = parsed.error.issues[0]?.message || "Validation failed";
            return sendError(res, 400, firstError, "VALIDATION_ERROR");
        }

        const result = await setProjectBudget(id, parsed.data.budget, req.user);
        return sendSuccess(res, 200, "Project budget set successfully", result);
    } catch (error) {
        return sendError(res, error.status || 500, error.message || "Failed to set project budget", error.code || "FINANCE_ERROR");
    }
};

module.exports = {
    getSummaryRoute,
    getInvoicesRoute,
    createInvoiceRoute,
    recordPaymentRoute,
    createExpenseRoute,
    getExpensesRoute,
    getBudgetRoute,
    setBudgetRoute
};
