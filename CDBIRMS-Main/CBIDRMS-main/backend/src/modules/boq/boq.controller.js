const { createBoqSchema, updateBoqSchema } = require("./boq.validation");
const {
    getAllBoqsService,
    getBoqByIdService,
    createBoqService,
    updateBoqService,
    deleteBoqService
} = require("./boq.service");

const getAllBoqs = async (req, res) => {
    try {
        const { projectId } = req.query;
        const boqs = await getAllBoqsService(projectId);
        res.status(200).json({
            success: true,
            message: "BOQs retrieved successfully",
            data: { boqs },
            error: null
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: "Failed to retrieve BOQs",
            data: null,
            error: error.message
        });
    }
};

const getBoqById = async (req, res) => {
    try {
        const { id } = req.params;
        const boq = await getBoqByIdService(id);
        res.status(200).json({
            success: true,
            message: "BOQ retrieved successfully",
            data: { boq },
            error: null
        });
    } catch (error) {
        const statusCode = error.message === "BOQ_NOT_FOUND" ? 404 : 500;
        res.status(statusCode).json({
            success: false,
            message: "Failed to retrieve BOQ",
            data: null,
            error: error.message
        });
    }
};

const createBoq = async (req, res) => {
    try {
        const validatedData = createBoqSchema.parse(req.body);
        const boq = await createBoqService(validatedData, req.user);
        res.status(201).json({
            success: true,
            message: "BOQ created successfully",
            data: { boq },
            error: null
        });
    } catch (error) {
        if (error.name === "ZodError") {
            return res.status(400).json({
                success: false,
                message: "Validation Error",
                data: null,
                error: error.errors.map(e => `${e.path.join(".")}: ${e.message}`).join(", ")
            });
        }
        let statusCode = 500;
        if (error.message === "PROJECT_NOT_FOUND") statusCode = 404;
        if (error.message === "BOQ_ALREADY_EXISTS") statusCode = 409;

        res.status(statusCode).json({
            success: false,
            message: "Failed to create BOQ",
            data: null,
            error: error.message
        });
    }
};

const updateBoq = async (req, res) => {
    try {
        const { id } = req.params;
        const validatedData = updateBoqSchema.parse(req.body);
        const boq = await updateBoqService(id, validatedData, req.user);
        res.status(200).json({
            success: true,
            message: "BOQ updated successfully",
            data: { boq },
            error: null
        });
    } catch (error) {
        if (error.name === "ZodError") {
            return res.status(400).json({
                success: false,
                message: "Validation Error",
                data: null,
                error: error.errors.map(e => `${e.path.join(".")}: ${e.message}`).join(", ")
            });
        }
        const statusCode = error.message === "BOQ_NOT_FOUND" ? 404 : 500;
        res.status(statusCode).json({
            success: false,
            message: "Failed to update BOQ",
            data: null,
            error: error.message
        });
    }
};

const deleteBoqHandler = async (req, res) => {
    try {
        const { id } = req.params;
        await deleteBoqService(id);
        res.status(200).json({
            success: true,
            message: "BOQ deleted successfully",
            data: null,
            error: null
        });
    } catch (error) {
        const statusCode = error.message === "BOQ_NOT_FOUND" ? 404 : 500;
        res.status(statusCode).json({
            success: false,
            message: "Failed to delete BOQ",
            data: null,
            error: error.message
        });
    }
};

module.exports = {
    getAllBoqs,
    getBoqById,
    createBoq,
    updateBoq,
    deleteBoq: deleteBoqHandler
};
