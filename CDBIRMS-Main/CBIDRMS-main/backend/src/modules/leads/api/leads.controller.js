const {
    getLeadsList,
    getLeadById,
    createNewLead,
    updateExistingLead,
    convertLeadToProject,
    deleteLead
} = require("../logic/leads.service");
const { createLeadSchema, updateLeadSchema } = require("./leads.validation");

// Helper to format Zod validation errors cleanly
const formatValidationError = (zodError) => {
    const issues = zodError.issues || zodError.errors || [];
    return issues.map(e => {
        const fieldName = e.path.join(".");
        return `${fieldName ? fieldName + ": " : ""}${e.message}`;
    }).join("; ");
};

// GET /api/leads
const getLeads = async (req, res) => {
    try {
        const leads = await getLeadsList(req.user, req.query);
        res.status(200).json({
            success: true,
            message: "Leads fetched successfully",
            data: {
                leads,
                total: leads.length
            },
            error: null
        });
    } catch (error) {
        res.status(error.statusCode || 500).json({
            success: false,
            message: error.message || "Failed to fetch leads",
            data: null,
            error: error.errorCode || "INTERNAL_SERVER_ERROR"
        });
    }
};

// GET /api/leads/:id
const getLead = async (req, res) => {
    try {
        const lead = await getLeadById(req.user, req.params.id);
        res.status(200).json({
            success: true,
            message: "Lead details fetched successfully",
            data: lead,
            error: null
        });
    } catch (error) {
        res.status(error.statusCode || 500).json({
            success: false,
            message: error.message || "Failed to fetch lead details",
            data: null,
            error: error.errorCode || "INTERNAL_SERVER_ERROR"
        });
    }
};

// POST /api/leads
const createLead = async (req, res) => {
    try {
        const parsed = createLeadSchema.safeParse(req.body);
        if (!parsed.success) {
            return res.status(400).json({
                success: false,
                message: formatValidationError(parsed.error),
                data: null,
                error: "VALIDATION_ERROR"
            });
        }

        const newLead = await createNewLead(req.user, parsed.data);
        res.status(201).json({
            success: true,
            message: "Lead created successfully",
            data: newLead,
            error: null
        });
    } catch (error) {
        res.status(error.statusCode || 400).json({
            success: false,
            message: error.message || "Failed to create lead",
            data: null,
            error: error.errorCode || "VALIDATION_ERROR"
        });
    }
};

// PATCH /api/leads/:id
const updateLead = async (req, res) => {
    try {
        const parsed = updateLeadSchema.safeParse(req.body);
        if (!parsed.success) {
            return res.status(400).json({
                success: false,
                message: formatValidationError(parsed.error),
                data: null,
                error: "VALIDATION_ERROR"
            });
        }

        const updatedLead = await updateExistingLead(req.user, req.params.id, parsed.data);
        res.status(200).json({
            success: true,
            message: "Lead updated successfully",
            data: updatedLead,
            error: null
        });
    } catch (error) {
        res.status(error.statusCode || 400).json({
            success: false,
            message: error.message || "Failed to update lead",
            data: null,
            error: error.errorCode || "VALIDATION_ERROR"
        });
    }
};

// POST /api/leads/:id/convert
const convertLead = async (req, res) => {
    try {
        const result = await convertLeadToProject(req.user, req.params.id);
        res.status(200).json({
            success: true,
            message: "Lead converted into active project and customer profile successfully",
            data: result,
            error: null
        });
    } catch (error) {
        res.status(error.statusCode || 400).json({
            success: false,
            message: error.message || "Failed to convert lead",
            data: null,
            error: error.errorCode || "CONVERSION_ERROR"
        });
    }
};

// DELETE /api/leads/:id
const deleteLeadRoute = async (req, res) => {
    try {
        const result = await deleteLead(req.user, req.params.id);
        res.status(200).json({
            success: true,
            message: result.message || "Lead deleted successfully",
            data: {},
            error: null
        });
    } catch (error) {
        res.status(error.statusCode || 400).json({
            success: false,
            message: error.message || "Failed to delete lead",
            data: null,
            error: error.errorCode || "DELETE_ERROR"
        });
    }
};

module.exports = {
    getLeads,
    getLead,
    createLead,
    updateLead,
    convertLead,
    deleteLeadRoute
};
