const express = require("express");
const cors = require("cors");
const cookieParser = require("cookie-parser");

const authRoutes = require("./modules/auth/api/auth.routes");
const leadsRoutes = require("./modules/leads/api/leads.routes");
const projectsRoutes = require("./modules/projects/api/projects.routes");
const quotationRoutes = require("./modules/quotations/quotation.routes");
const usersRoutes = require("./modules/users/users.routes");
const customersRoutes = require("./modules/customers/api/customers.routes");
const dashboardRoutes = require("./modules/dashboard/dashboard.routes");
const boqRoutes = require("./modules/boq/boq.routes");
const vendorsRoutes = require("./modules/vendors/api/vendors.routes");
const purchaseOrdersRoutes = require("./modules/purchase_orders/purchase_orders.routes");
const documentsRoutes = require("./modules/documents/documents.routes");
const designsRoutes = require("./modules/designs/api/designs.routes");

const path = require("path");
const siteRoutes = require("./modules/site/site.routes");
const financeRoutes = require("./modules/finance/api/finance.routes");
const reportsRoutes = require("./modules/reports/api/reports.routes");
const analyticsRoutes = require("./modules/analytics/api/analytics.routes");

const app = express();

app.use(cors({
    origin: "*",
    methods: ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
    allowedHeaders: ["Content-Type", "Authorization", "X-Requested-With", "Accept"],
}));
app.use(express.json());
app.use(cookieParser());
app.use("/uploads", express.static(path.join(__dirname, "../uploads")));

app.get("/", (req, res) => {
    res.json({ status: "success", message: "IDPMS Backend API is running" });
});

app.get("/api", (req, res) => {
    res.json({ status: "success", message: "IDPMS API Health Check OK" });
});

app.use("/api/auth", authRoutes);
app.use("/api/v1/auth", authRoutes);
app.use("/api/leads", leadsRoutes);
app.use("/api/v1/leads", leadsRoutes);
app.use("/api/projects", projectsRoutes);
app.use("/api/v1/projects", projectsRoutes);
app.use("/api/quotations", quotationRoutes);
app.use("/api/v1/quotations", quotationRoutes);
app.use("/api/users", usersRoutes);
app.use("/api/v1/users", usersRoutes);
app.use("/api/customers", customersRoutes);
app.use("/api/v1/customers", customersRoutes);
app.use("/api/dashboard", dashboardRoutes);
app.use("/api/v1/dashboard", dashboardRoutes);
app.use("/api/boq", boqRoutes);
app.use("/api/v1/boq", boqRoutes);
app.use("/api/vendors", vendorsRoutes);
app.use("/api/v1/vendors", vendorsRoutes);
app.use("/api/purchase-orders", purchaseOrdersRoutes);
app.use("/api/v1/purchase-orders", purchaseOrdersRoutes);
app.use("/api/documents", documentsRoutes);
app.use("/api/v1/documents", documentsRoutes);
app.use("/api/designs", designsRoutes);
app.use("/api/v1/designs", designsRoutes);

// Site Management Routes
app.use("/api", siteRoutes);
app.use("/api/v1", siteRoutes);

// Finance Management Routes
app.use("/api/finance", financeRoutes);
app.use("/api/v1/finance", financeRoutes);
app.use("/api", financeRoutes);
app.use("/api/v1", financeRoutes);

// Reports Management Routes
app.use("/api/reports", reportsRoutes);
app.use("/api/v1/reports", reportsRoutes);

// Analytics Management Routes
app.use("/api/analytics", analyticsRoutes);
app.use("/api/v1/analytics", analyticsRoutes);

module.exports = app;