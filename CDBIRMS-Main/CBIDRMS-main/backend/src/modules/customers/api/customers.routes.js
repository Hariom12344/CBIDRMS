const express = require("express");
const router = express.Router();
const customersController = require("./customers.controller");
const { verifyToken, requireRole } = require("../../../middlewares/auth.middleware");

const allowedMutateRoles = ["SUPER_ADMIN", "COMPANY_ADMIN", "PROJECT_MANAGER", "ADMIN", "MANAGER"];

// Read routes (all authenticated users)
router.get("/", verifyToken, customersController.getCustomers);
router.get("/:id", verifyToken, customersController.getCustomerById);

// Write routes (Admin and Project Manager only)
router.post("/", verifyToken, requireRole(allowedMutateRoles), customersController.createCustomer);
router.put("/:id", verifyToken, requireRole(allowedMutateRoles), customersController.updateCustomer);

module.exports = router;
