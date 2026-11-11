const analyticsService = require("../logic/analytics.service");
const { getTrendsSchema } = require("./analytics.validation");

class AnalyticsController {
  async getTrends(req, res) {
    try {
      const validation = getTrendsSchema.safeParse(req.query);

      if (!validation.success) {
        return res.status(400).json({
          success: false,
          message: "Validation Error",
          error: validation.error.errors.map((e) => e.message).join("; "),
          code: "VALIDATION_ERROR",
        });
      }

      const { from, to, metrics } = validation.data;
      const data = await analyticsService.getTrends({
        from,
        to,
        metrics,
        user: req.user,
      });

      return res.status(200).json({
        success: true,
        message: "Analytics trend data fetched successfully",
        data,
      });
    } catch (err) {
      console.error("Error in AnalyticsController.getTrends:", err);
      const statusCode = err.statusCode || 500;
      return res.status(statusCode).json({
        success: false,
        message: err.message || "Failed to fetch analytics trends",
        error: err.message,
        code: err.code || "INTERNAL_ERROR",
      });
    }
  }
}

module.exports = new AnalyticsController();
