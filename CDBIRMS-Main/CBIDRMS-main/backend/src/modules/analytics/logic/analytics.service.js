const analyticsRepository = require("../data/analytics.repository");

class AnalyticsService {
  /**
   * Helper: Calculate range length in days.
   */
  _diffDays(fromDateStr, toDateStr) {
    const from = new Date(fromDateStr);
    const to = new Date(toDateStr);
    const diffTime = Math.abs(to - from);
    return Math.ceil(diffTime / (1000 * 60 * 60 * 24));
  }

  /**
   * Filter metrics based on caller role per FC-015 §14.
   */
  _getAllowedMetrics(userRole, requestedMetrics) {
    const normRole = (userRole || "").toUpperCase();
    const rolePermissions = {
      REVENUE: ["SUPER_ADMIN", "COMPANY_ADMIN"],
      ACTIVE_PROJECTS: ["SUPER_ADMIN", "COMPANY_ADMIN", "PROJECT_MANAGER"],
      TEAM_ACTIVITY: ["SUPER_ADMIN", "COMPANY_ADMIN", "PROJECT_MANAGER"],
    };

    const defaultMetrics = ["REVENUE", "ACTIVE_PROJECTS", "TEAM_ACTIVITY"];
    const metricsToTest = requestedMetrics && requestedMetrics.length > 0 ? requestedMetrics : defaultMetrics;

    return metricsToTest.filter((m) => {
      const allowedRoles = rolePermissions[m];
      return allowedRoles && allowedRoles.includes(normRole);
    });
  }

  /**
   * Get analytics trend series per FC-015.
   */
  async getTrends({ from, to, metrics, user }) {
    const allowedMetrics = this._getAllowedMetrics(user.role, metrics);

    if (allowedMetrics.length === 0) {
      const err = new Error("None of the requested/permitted metrics are available for your role");
      err.statusCode = 422;
      err.code = "NO_DATA_SOURCE";
      throw err;
    }

    const rangeDays = this._diffDays(from, to);
    const isWeekly = rangeDays > 31;
    const companyId = user.companyId || null;

    const seriesList = [];

    for (const metric of allowedMetrics) {
      try {
        let points = [];
        if (metric === "REVENUE") {
          points = await analyticsRepository.getRevenueTrend(from, to, companyId, isWeekly);
        } else if (metric === "ACTIVE_PROJECTS") {
          points = await analyticsRepository.getActiveProjectsTrend(from, to, companyId, isWeekly);
        } else if (metric === "TEAM_ACTIVITY") {
          points = await analyticsRepository.getTeamActivityTrend(from, to, companyId, isWeekly);
        }

        seriesList.push({
          metric,
          points,
        });
      } catch (err) {
        console.error(`Error aggregating metric ${metric}:`, err);
        seriesList.push({
          metric,
          points: [],
          status: "NOT_AVAILABLE",
        });
      }
    }

    if (seriesList.length === 0) {
      const err = new Error("No computable data series available for specified range");
      err.statusCode = 422;
      err.code = "NO_DATA_SOURCE";
      throw err;
    }

    return {
      series: seriesList,
    };
  }
}

module.exports = new AnalyticsService();
