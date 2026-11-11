const express = require("express");
const router = express.Router();
const projectsController = require("./projects.controller");
const { verifyToken } = require("../../../middlewares/auth.middleware");

// Get all projects
router.get("/", verifyToken, projectsController.getProjects);

// Get single project details
router.get("/:id", verifyToken, projectsController.getProject);

// Create new project
router.post("/", verifyToken, projectsController.createProject);

// Update project fields / status
router.patch("/:id", verifyToken, projectsController.updateProject);

// Assign team members to a project
router.patch("/:id/team", verifyToken, projectsController.assignTeam);

// Add stage to a project
router.post("/:id/stages", verifyToken, projectsController.addStage);

// Update stage status
router.patch("/:id/stages/:stageId", verifyToken, projectsController.updateStageStatus);

module.exports = router;
