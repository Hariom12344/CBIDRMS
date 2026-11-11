const express = require("express");
const router = express.Router();
const leadsController = require("./leads.controller");
const { verifyToken, requireRole } = require("../../../middlewares/auth.middleware");

// Roles allowed for sales pipeline management (Admins & Project Managers)
const PIPELINE_ROLES = ["SUPER_ADMIN", "COMPANY_ADMIN", "ADMIN", "PROJECT_MANAGER", "MANAGER"];
// Roles allowed for deletion (Admins only)
const DELETE_ROLES = ["SUPER_ADMIN", "COMPANY_ADMIN", "ADMIN"];

// GET /api/leads - List leads (filterable by status)
router.get("/", verifyToken, requireRole(PIPELINE_ROLES), leadsController.getLeads);

// GET /api/leads/:id - Get single lead details
router.get("/:id", verifyToken, requireRole(PIPELINE_ROLES), leadsController.getLead);

// POST /api/leads - Create a new lead
router.post("/", verifyToken, requireRole(PIPELINE_ROLES), leadsController.createLead);

// PATCH /api/leads/:id - Update lead details / status
router.patch("/:id", verifyToken, requireRole(PIPELINE_ROLES), leadsController.updateLead);

// POST /api/leads/:id/convert - Convert lead to active project & customer
router.post("/:id/convert", verifyToken, requireRole(PIPELINE_ROLES), leadsController.convertLead);

// DELETE /api/leads/:id - Delete lead (Admins only)
router.delete("/:id", verifyToken, requireRole(DELETE_ROLES), leadsController.deleteLeadRoute);

module.exports = router;
