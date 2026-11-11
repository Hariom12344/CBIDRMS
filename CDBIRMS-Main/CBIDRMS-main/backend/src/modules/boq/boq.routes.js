const express = require("express");
const router = express.Router();
const { getAllBoqs, getBoqById, createBoq, updateBoq, deleteBoq } = require("./boq.controller");
const { verifyToken, requireRole } = require("../../middlewares/auth.middleware");

// GET /api/boq - List all BOQs
router.get("/", verifyToken, getAllBoqs);

// GET /api/boq/:id - Get BOQ by ID
router.get("/:id", verifyToken, getBoqById);

// POST /api/boq - Create BOQ (Admin, PM)
router.post("/", verifyToken, requireRole(["SUPER_ADMIN", "COMPANY_ADMIN", "ADMIN", "PROJECT_MANAGER"]), createBoq);

// PUT /api/boq/:id - Update BOQ (Admin, PM)
router.put("/:id", verifyToken, requireRole(["SUPER_ADMIN", "COMPANY_ADMIN", "ADMIN", "PROJECT_MANAGER"]), updateBoq);

// DELETE /api/boq/:id - Delete BOQ (Admin only)
router.delete("/:id", verifyToken, requireRole(["SUPER_ADMIN", "COMPANY_ADMIN", "ADMIN"]), deleteBoq);

module.exports = router;
