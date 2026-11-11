const {
    getProjectsList,
    getProjectById,
    createNewProject,
    updateProjectDetails,
    assignTeamToProject,
    addStageToProject,
    updateStageStatus: updateStageStatusService
} = require("../logic/projects.service");
const {
    createProjectSchema,
    updateProjectSchema,
    assignTeamSchema,
    addStageSchema,
    updateStageStatusSchema
} = require("./projects.validation");

// Helper to format validation errors
const formatValidationError = (zodError) => {
    const issues = zodError.issues || zodError.errors || [];
    return issues.map(e => {
        const fieldName = e.path.join(".");
        return `${fieldName ? fieldName + ": " : ""}${e.message}`;
    }).join("; ");
};

// GET /api/projects
const getProjects = async (req, res) => {
    try {
        const projects = await getProjectsList(req.user, req.query);
        res.status(200).json({
            success: true,
            message: "Projects fetched successfully",
            data: {
                projects,
                total: projects.length
            },
            error: null
        });
    } catch (error) {
        res.status(error.statusCode || 500).json({
            success: false,
            message: error.errorCode || "INTERNAL_SERVER_ERROR",
            data: null,
            error: error.message
        });
    }
};

// GET /api/projects/:id
const getProject = async (req, res) => {
    try {
        const project = await getProjectById(req.user, req.params.id);
        res.status(200).json({
            success: true,
            message: "Project fetched successfully",
            data: project,
            error: null
        });
    } catch (error) {
        res.status(error.statusCode || 500).json({
            success: false,
            message: error.errorCode || "INTERNAL_SERVER_ERROR",
            data: null,
            error: error.message
        });
    }
};

// POST /api/projects
const createProject = async (req, res) => {
    try {
        const parsed = createProjectSchema.safeParse(req.body);
        if (!parsed.success) {
            return res.status(400).json({
                message: "VALIDATION_ERROR",
                error: formatValidationError(parsed.error)
            });
        }

        const project = await createNewProject(req.user, parsed.data);
        res.status(201).json({
            message: "Project created successfully",
            data: project
        });
    } catch (error) {
        res.status(error.statusCode || 400).json({
            message: error.errorCode || "VALIDATION_ERROR",
            error: error.message
        });
    }
};

// PATCH /api/projects/:id
const updateProject = async (req, res) => {
    try {
        const parsed = updateProjectSchema.safeParse(req.body);
        if (!parsed.success) {
            return res.status(400).json({
                message: "VALIDATION_ERROR",
                error: formatValidationError(parsed.error)
            });
        }

        const project = await updateProjectDetails(req.user, req.params.id, parsed.data);
        res.status(200).json({
            message: "Project updated successfully",
            data: project
        });
    } catch (error) {
        res.status(error.statusCode || 400).json({
            message: error.errorCode || "VALIDATION_ERROR",
            error: error.message
        });
    }
};

// PATCH /api/projects/:id/team
const assignTeam = async (req, res) => {
    try {
        const parsed = assignTeamSchema.safeParse(req.body);
        if (!parsed.success) {
            return res.status(400).json({
                message: "VALIDATION_ERROR",
                error: formatValidationError(parsed.error)
            });
        }

        const project = await assignTeamToProject(req.user, req.params.id, parsed.data.assignedTeam);
        res.status(200).json({
            message: "Team assigned successfully",
            data: project
        });
    } catch (error) {
        res.status(error.statusCode || 400).json({
            message: error.errorCode || "VALIDATION_ERROR",
            error: error.message
        });
    }
};

// POST /api/projects/:id/stages
const addStage = async (req, res) => {
    try {
        const parsed = addStageSchema.safeParse(req.body);
        if (!parsed.success) {
            return res.status(400).json({
                message: "VALIDATION_ERROR",
                error: formatValidationError(parsed.error)
            });
        }

        const project = await addStageToProject(req.user, req.params.id, parsed.data);
        res.status(201).json({
            message: "Stage added successfully",
            data: project
        });
    } catch (error) {
        res.status(error.statusCode || 400).json({
            message: error.errorCode || "VALIDATION_ERROR",
            error: error.message
        });
    }
};

// PATCH /api/projects/:id/stages/:stageId
const updateStageStatus = async (req, res) => {
    try {
        const parsed = updateStageStatusSchema.safeParse(req.body);
        if (!parsed.success) {
            return res.status(400).json({
                message: "VALIDATION_ERROR",
                error: formatValidationError(parsed.error)
            });
        }

        const project = await updateStageStatusService(req.user, req.params.id, req.params.stageId, parsed.data.status);
        res.status(200).json({
            message: "Stage status updated successfully",
            data: project
        });
    } catch (error) {
        res.status(error.statusCode || 400).json({
            message: error.errorCode || "VALIDATION_ERROR",
            error: error.message
        });
    }
};

module.exports = {
    getProjects,
    getProject,
    createProject,
    updateProject,
    assignTeam,
    addStage,
    updateStageStatus
};
