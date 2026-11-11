const express = require("express");
const router = express.Router();
const reportsController = require("./reports.controller");
const { verifyToken } = require("../../../middlewares/auth.middleware");

// Generate report for type (PROJECT, EXPENSE, PURCHASE, REVENUE, VENDOR, TEAM)
router.post("/:type/generate", verifyToken, reportsController.generateReportRoute);

// Report History
router.get("/history", verifyToken, reportsController.getReportHistoryRoute);

module.exports = router;
