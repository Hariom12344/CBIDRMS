const { z } = require("zod");

const ALLOWED_METRICS = ["REVENUE", "ACTIVE_PROJECTS", "TEAM_ACTIVITY"];

const getTrendsSchema = z.object({
  from: z.string().refine((val) => !isNaN(Date.parse(val)), {
    message: "from must be a valid ISO date string (YYYY-MM-DD)",
  }),
  to: z.string().refine((val) => !isNaN(Date.parse(val)), {
    message: "to must be a valid ISO date string (YYYY-MM-DD)",
  }),
  metrics: z.string().optional().transform((val) => {
    if (!val) return undefined;
    return val.split(",").map((m) => m.trim()).filter(Boolean);
  }),
}).superRefine((data, ctx) => {
  const fromDate = new Date(data.from);
  const toDate = new Date(data.to);
  const today = new Date();
  today.setHours(23, 59, 59, 999);

  if (fromDate > toDate) {
    ctx.addIssue({
      code: z.ZodIssueCode.custom,
      message: "from date must be less than or equal to to date",
      path: ["from"],
    });
  }

  if (toDate > today) {
    ctx.addIssue({
      code: z.ZodIssueCode.custom,
      message: "to date cannot be in the future",
      path: ["to"],
    });
  }

  const diffTime = Math.abs(toDate - fromDate);
  const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
  if (diffDays > 365) {
    ctx.addIssue({
      code: z.ZodIssueCode.custom,
      message: "Date range cannot exceed 1 year (365 days)",
      path: ["to"],
    });
  }

  if (data.metrics && data.metrics.length > 0) {
    for (const m of data.metrics) {
      if (!ALLOWED_METRICS.includes(m)) {
        ctx.addIssue({
          code: z.ZodIssueCode.custom,
          message: `Unknown metric '${m}'. Allowed metrics: ${ALLOWED_METRICS.join(", ")}`,
          path: ["metrics"],
        });
      }
    }
  }
});

module.exports = {
  getTrendsSchema,
};
