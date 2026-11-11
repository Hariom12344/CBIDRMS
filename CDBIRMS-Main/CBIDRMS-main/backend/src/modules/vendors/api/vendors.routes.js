const express = require("express");
const router = express.Router();
const vendorsController = require("./vendors.controller");
const { verifyToken, requireRole } = require("../../../middlewares/auth.middleware");

const allowedMutateRoles = ["SUPER_ADMIN", "COMPANY_ADMIN", "PROJECT_MANAGER", "ADMIN", "MANAGER"];

// Read routes (all authenticated users with vendor read permissions)
router.get("/", verifyToken, vendorsController.getVendors);
router.get("/:id", verifyToken, vendorsController.getVendorById);

// Write routes (Super Admin, Company Admin, Project Manager)
router.post("/", verifyToken, requireRole(allowedMutateRoles), vendorsController.createVendor);
router.put("/:id", verifyToken, requireRole(allowedMutateRoles), vendorsController.updateVendor);

module.exports = router;
