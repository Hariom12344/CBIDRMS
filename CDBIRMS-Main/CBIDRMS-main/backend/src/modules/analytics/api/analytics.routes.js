const express = require("express");
const router = express.Router();
const analyticsController = require("./analytics.controller");
const { verifyToken } = require("../../../middlewares/auth.middleware");

// GET /api/analytics/trends (or /api/v1/analytics/trends)
router.get("/trends", verifyToken, analyticsController.getTrends);

module.exports = router;
