const express = require("express");
const router = express.Router();
const { getSummaryHandler, getActivitiesHandler } = require("./dashboard.controller");
const { verifyToken } = require("../../middlewares/auth.middleware");

// GET /api/dashboard/summary
router.get("/summary", verifyToken, getSummaryHandler);

// GET /api/dashboard/activities
router.get("/activities", verifyToken, getActivitiesHandler);

module.exports = router;
