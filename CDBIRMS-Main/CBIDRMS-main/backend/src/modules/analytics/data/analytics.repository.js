const { PrismaClient } = require("@prisma/client");
const prisma = new PrismaClient();

class AnalyticsRepository {
  /**
   * Helper: Generate continuous list of date buckets between start and end date.
   */
  _generateBuckets(fromDateStr, toDateStr, isWeekly) {
    const buckets = [];
    let current = new Date(fromDateStr);
    const end = new Date(toDateStr);

    if (isNaN(current.getTime()) || isNaN(end.getTime())) {
      return buckets;
    }

    while (current <= end) {
      const iso = current.toISOString().split("T")[0];
      buckets.push(iso);

      if (isWeekly) {
        current.setDate(current.getDate() + 7);
      } else {
        current.setDate(current.getDate() + 1);
      }
    }
    return buckets;
  }

  /**
   * Helper: Find corresponding bucket key for a given date.
   */
  _getBucketKey(dateStr, buckets, isWeekly) {
    const d = new Date(dateStr);
    if (isNaN(d.getTime())) return buckets[0];

    const iso = d.toISOString().split("T")[0];
    if (!isWeekly) return iso;

    let lastBucket = buckets[0];
    for (const b of buckets) {
      if (b <= iso) {
        lastBucket = b;
      } else {
        break;
      }
    }
    return lastBucket;
  }

  /**
   * Revenue Trend: Sum of realized Payment records per bucket
   */
  async getRevenueTrend(fromDate, toDate, companyId, isWeekly) {
    const payments = await prisma.payment.findMany({
      where: {
        createdAt: {
          gte: new Date(fromDate),
          lte: new Date(`${toDate}T23:59:59.999Z`),
        },
      },
      select: {
        amount: true,
        createdAt: true,
      },
    });

    const buckets = this._generateBuckets(fromDate, toDate, isWeekly);
    const bucketMap = {};
    buckets.forEach((b) => (bucketMap[b] = 0));

    payments.forEach((p) => {
      const key = this._getBucketKey(p.createdAt.toISOString().split("T")[0], buckets, isWeekly);
      if (bucketMap[key] !== undefined) {
        bucketMap[key] += p.amount || 0;
      }
    });

    return buckets.map((b) => ({
      bucket: b,
      value: Number(bucketMap[b].toFixed(2)),
    }));
  }

  /**
   * Active Projects Trend: Count of projects not COMPLETED or ON_HOLD
   */
  async getActiveProjectsTrend(fromDate, toDate, companyId, isWeekly) {
    const projects = await prisma.project.findMany({
      where: {
        status: {
          notIn: ["COMPLETED", "ON_HOLD", "CANCELLED"],
        },
      },
      select: {
        id: true,
        startDate: true,
        createdAt: true,
      },
    });

    const buckets = this._generateBuckets(fromDate, toDate, isWeekly);
    const totalActiveProjects = projects.length;

    return buckets.map((b) => ({
      bucket: b,
      value: totalActiveProjects,
    }));
  }

  /**
   * Team Activity Trend: SiteUpdate posts + SiteTask completions per bucket
   */
  async getTeamActivityTrend(fromDate, toDate, companyId, isWeekly) {
    const siteUpdates = await prisma.siteUpdate.findMany({
      where: {
        createdAt: {
          gte: new Date(fromDate),
          lte: new Date(`${toDate}T23:59:59.999Z`),
        },
      },
      select: {
        createdAt: true,
      },
    });

    const completedTasks = await prisma.siteTask.findMany({
      where: {
        status: "COMPLETED",
        updatedAt: {
          gte: new Date(fromDate),
          lte: new Date(`${toDate}T23:59:59.999Z`),
        },
      },
      select: {
        updatedAt: true,
      },
    });

    const buckets = this._generateBuckets(fromDate, toDate, isWeekly);
    const bucketMap = {};
    buckets.forEach((b) => (bucketMap[b] = 0));

    siteUpdates.forEach((u) => {
      const key = this._getBucketKey(u.createdAt.toISOString().split("T")[0], buckets, isWeekly);
      if (bucketMap[key] !== undefined) {
        bucketMap[key] += 1;
      }
    });

    completedTasks.forEach((t) => {
      const key = this._getBucketKey(t.updatedAt.toISOString().split("T")[0], buckets, isWeekly);
      if (bucketMap[key] !== undefined) {
        bucketMap[key] += 1;
      }
    });

    return buckets.map((b) => ({
      bucket: b,
      value: bucketMap[b],
    }));
  }
}

module.exports = new AnalyticsRepository();
