const express = require("express");
const router = express.Router();
const financeController = require("./finance.controller");
const { verifyToken, requireRole } = require("../../../middlewares/auth.middleware");

const adminAccountantRoles = ["SUPER_ADMIN", "COMPANY_ADMIN", "ACCOUNTANT", "ADMIN"];

// Finance Summary Dashboard Card Totals
router.get("/summary", verifyToken, requireRole(adminAccountantRoles), financeController.getSummaryRoute);

// Invoices
router.get("/invoices", verifyToken, financeController.getInvoicesRoute);
router.post("/invoices", verifyToken, requireRole(adminAccountantRoles), financeController.createInvoiceRoute);
router.post("/invoices/:id/payments", verifyToken, requireRole(adminAccountantRoles), financeController.recordPaymentRoute);

// Expenses
router.get("/expenses", verifyToken, financeController.getExpensesRoute);
router.post("/expenses", verifyToken, requireRole(adminAccountantRoles), financeController.createExpenseRoute);

// Project Budget
router.get("/projects/:id/budget", verifyToken, financeController.getBudgetRoute);
router.post("/projects/:id/budget", verifyToken, requireRole(adminAccountantRoles), financeController.setBudgetRoute);

module.exports = router;
