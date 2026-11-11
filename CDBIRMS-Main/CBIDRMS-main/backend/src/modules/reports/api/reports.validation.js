const { z } = require("zod");

const getTodayFormatted = () => {
    return new Date().toISOString().split("T")[0];
};

const generateReportZodSchema = z.object({
    from: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, "from date must be in YYYY-MM-DD format"),
    to: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, "to date must be in YYYY-MM-DD format"),
    projectId: z.string().optional()
}).refine((data) => {
    return data.from <= data.to;
}, {
    message: "'from' date must be less than or equal to 'to' date",
    path: ["from"]
}).refine((data) => {
    const today = getTodayFormatted();
    return data.to <= today;
}, {
    message: "'to' date cannot be in the future",
    path: ["to"]
}).refine((data) => {
    const startDate = new Date(data.from);
    const endDate = new Date(data.to);
    const diffTime = Math.abs(endDate - startDate);
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
    return diffDays <= 365;
}, {
    message: "Date range cannot exceed 1 year (365 days)",
    path: ["to"]
});

module.exports = {
    generateReportZodSchema
};
