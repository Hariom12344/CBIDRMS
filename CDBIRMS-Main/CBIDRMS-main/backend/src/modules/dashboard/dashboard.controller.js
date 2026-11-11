const { getSummary, getRecentActivities } = require("./dashboard.service");

// GET /api/dashboard/summary
const getSummaryHandler = async (req, res) => {
    try {
        const summary = await getSummary(req.user);
        res.status(200).json({
            success: true,
            message: "Dashboard summary loaded successfully",
            data: summary,
            error: null
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: "Failed to load dashboard summary",
            data: null,
            error: error.message
        });
    }
};

// GET /api/dashboard/activities
const getActivitiesHandler = async (req, res) => {
    try {
        const limit = req.query.limit || 10;
        const activities = await getRecentActivities(req.user, limit);
        res.status(200).json({
            success: true,
            message: "Recent activities loaded successfully",
            data: { activities },
            error: null
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: "Failed to load recent activities",
            data: null,
            error: error.message
        });
    }
};

module.exports = {
    getSummaryHandler,
    getActivitiesHandler
};
