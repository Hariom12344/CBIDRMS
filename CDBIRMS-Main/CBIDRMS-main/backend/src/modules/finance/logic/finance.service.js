const prisma = require("../../../config/db");
const {
    findAllInvoices,
    findAllPayments,
    findInvoices,
    countInvoices,
    findInvoiceById,
    createInvoiceRecord,
    countInvoicesTotal,
    recordPaymentTransaction,
    createExpenseRecord,
    findExpenses,
    countExpenses,
    findProjectWithBudgetAndExpenses,
    upsertProjectBudgetRecord,
    findProjectById
} = require("../data/finance.repository");

const getTodayFormatted = () => {
    return new Date().toISOString().split("T")[0];
};

/**
 * Get dashboard finance summary (Received, Pending, Overdue).
 */
const getFinanceSummary = async () => {
    const today = getTodayFormatted();

    const [allInvoices, allPayments] = await Promise.all([
        findAllInvoices(),
        findAllPayments()
    ]);

    const received = allPayments.reduce((sum, p) => sum + (p.amount || 0), 0);

    let pending = 0;
    let overdue = 0;

    for (const inv of allInvoices) {
        if (inv.pendingAmount > 0) {
            pending += inv.pendingAmount;
            if (inv.dueDate && inv.dueDate < today) {
                overdue += inv.pendingAmount;
            }
        }
    }

    return {
        received,
        pending,
        overdue
    };
};

/**
 * Get list of invoices with optional filtering.
 */
const getInvoicesList = async ({ projectId, status, page = 1, limit = 50 }) => {
    const today = getTodayFormatted();
    const skip = (Math.max(1, page) - 1) * limit;

    const [invoices, total] = await Promise.all([
        findInvoices({ projectId, status, skip, take: limit }),
        countInvoices({ projectId, status })
    ]);

    const mappedInvoices = invoices.map(inv => {
        let derivedStatus = "PENDING";
        if (inv.pendingAmount <= 0) {
            derivedStatus = "PAID";
        } else if (inv.dueDate && inv.dueDate < today) {
            derivedStatus = "OVERDUE";
        }
        return {
            ...inv,
            status: derivedStatus
        };
    });

    return {
        invoices: mappedInvoices,
        total,
        page: Number(page),
        limit: Number(limit)
    };
};

/**
 * Generate a new invoice.
 */
const createInvoice = async (data, currentUser) => {
    const { projectId, clientName, amount, dueDate } = data;

    const project = await findProjectById(projectId);
    if (!project) {
        const error = new Error(`Project '${projectId}' not found`);
        error.status = 404;
        error.code = "PROJECT_NOT_FOUND";
        throw error;
    }

    const count = await countInvoicesTotal();
    const invId = `INV-${new Date().getFullYear()}-${String(count + 1).padStart(3, "0")}`;

    const invoice = await createInvoiceRecord({
        id: invId,
        projectId,
        clientName: clientName.trim(),
        amount: Number(amount),
        pendingAmount: Number(amount),
        dueDate,
        status: "PENDING",
        companyId: currentUser?.companyId || null,
        createdBy: currentUser?.id && typeof currentUser.id === "number" ? currentUser.id : null
    });

    try {
        await prisma.activityLog.create({
            data: {
                companyId: currentUser?.companyId || null,
                type: "INVOICE_GENERATED",
                message: `Invoice ${invId} created for project ${projectId} (Amount: ₹${amount})`,
                actorId: currentUser?.id && typeof currentUser.id === "number" ? currentUser.id : null,
                actorName: currentUser?.fullName || "Accountant",
                relatedEntityType: "INVOICE",
                relatedEntityId: invId
            }
        });
    } catch (e) {
        console.error("Failed to log activity for invoice creation:", e.message);
    }

    return invoice;
};

/**
 * Record a payment against an invoice in a DB transaction.
 */
const recordPayment = async (invoiceId, paymentData, currentUser) => {
    const { amount, date, method, note } = paymentData;
    const paymentAmount = Number(amount);

    const invoice = await findInvoiceById(invoiceId);
    if (!invoice) {
        const error = new Error(`Invoice '${invoiceId}' not found`);
        error.status = 404;
        error.code = "INVOICE_NOT_FOUND";
        throw error;
    }

    if (paymentAmount > invoice.pendingAmount) {
        const error = new Error(`Payment amount (₹${paymentAmount}) exceeds pending balance of ₹${invoice.pendingAmount}`);
        error.status = 400;
        error.code = "VALIDATION_ERROR";
        throw error;
    }

    const today = getTodayFormatted();
    const newPending = Math.max(0, invoice.pendingAmount - paymentAmount);
    let newStatus = "PENDING";
    if (newPending <= 0) {
        newStatus = "PAID";
    } else if (invoice.dueDate && invoice.dueDate < today) {
        newStatus = "OVERDUE";
    }

    const result = await recordPaymentTransaction(
        invoiceId,
        {
            amount: paymentAmount,
            date: date || today,
            method: method || "BANK_TRANSFER",
            note: note?.trim() || null,
            recordedBy: currentUser?.id && typeof currentUser.id === "number" ? currentUser.id : null
        },
        newPending,
        newStatus
    );

    try {
        await prisma.activityLog.create({
            data: {
                companyId: currentUser?.companyId || null,
                type: "PAYMENT_RECORDED",
                message: `Payment of ₹${paymentAmount} recorded for invoice ${invoiceId} (New pending balance: ₹${newPending})`,
                actorId: currentUser?.id && typeof currentUser.id === "number" ? currentUser.id : null,
                actorName: currentUser?.fullName || "Accountant",
                relatedEntityType: "INVOICE",
                relatedEntityId: invoiceId
            }
        });
    } catch (e) {
        console.error("Failed to log activity for payment recording:", e.message);
    }

    return result;
};

/**
 * Record a project expense.
 */
const createExpense = async (data, currentUser) => {
    const { projectId, category, amount, date, note } = data;

    const project = await findProjectById(projectId);
    if (!project) {
        const error = new Error(`Project '${projectId}' not found`);
        error.status = 404;
        error.code = "PROJECT_NOT_FOUND";
        throw error;
    }

    const expense = await createExpenseRecord({
        projectId,
        category: category || "OTHER",
        amount: Number(amount),
        date: date || getTodayFormatted(),
        note: note?.trim() || null,
        recordedBy: currentUser?.id && typeof currentUser.id === "number" ? currentUser.id : null,
        companyId: currentUser?.companyId || null
    });

    try {
        await prisma.activityLog.create({
            data: {
                companyId: currentUser?.companyId || null,
                type: "EXPENSE_RECORDED",
                message: `Expense of ₹${amount} (${category}) recorded for project ${projectId}`,
                actorId: currentUser?.id && typeof currentUser.id === "number" ? currentUser.id : null,
                actorName: currentUser?.fullName || "Accountant",
                relatedEntityType: "PROJECT",
                relatedEntityId: projectId
            }
        });
    } catch (e) {
        console.error("Failed to log activity for expense creation:", e.message);
    }

    return expense;
};

/**
 * Get expenses list.
 */
const getExpensesList = async ({ projectId, category, page = 1, limit = 50 }) => {
    const skip = (Math.max(1, page) - 1) * limit;

    const [expenses, total] = await Promise.all([
        findExpenses({ projectId, category, skip, take: limit }),
        countExpenses({ projectId, category })
    ]);

    return {
        expenses,
        total,
        page: Number(page),
        limit: Number(limit)
    };
};

/**
 * Get project budget summary (budget, spent, remaining).
 */
const getProjectBudgetSummary = async (projectId) => {
    const project = await findProjectWithBudgetAndExpenses(projectId);
    if (!project) {
        const error = new Error(`Project '${projectId}' not found`);
        error.status = 404;
        error.code = "PROJECT_NOT_FOUND";
        throw error;
    }

    const spent = (project.expenses || []).reduce((sum, e) => sum + (e.amount || 0), 0);
    const budgetVal = project.projectBudget ? project.projectBudget.budget : null;
    const remaining = budgetVal !== null ? budgetVal - spent : null;

    return {
        projectId,
        budget: budgetVal,
        spent,
        remaining
    };
};

/**
 * Set or update a project's budget.
 */
const setProjectBudget = async (projectId, budgetAmount, currentUser) => {
    const project = await findProjectById(projectId);
    if (!project) {
        const error = new Error(`Project '${projectId}' not found`);
        error.status = 404;
        error.code = "PROJECT_NOT_FOUND";
        throw error;
    }

    const numericBudget = Number(budgetAmount);

    const projectBudget = await upsertProjectBudgetRecord({
        projectId,
        budget: numericBudget,
        setBy: currentUser?.id && typeof currentUser.id === "number" ? currentUser.id : null,
        companyId: currentUser?.companyId || null
    });

    const expenses = await findExpenses({ projectId, category: null, skip: 0, take: 10000 });
    const spent = expenses.reduce((sum, e) => sum + (e.amount || 0), 0);
    const remaining = projectBudget.budget - spent;

    try {
        await prisma.activityLog.create({
            data: {
                companyId: currentUser?.companyId || null,
                type: "BUDGET_UPDATED",
                message: `Budget updated to ₹${numericBudget} for project ${projectId}`,
                actorId: currentUser?.id && typeof currentUser.id === "number" ? currentUser.id : null,
                actorName: currentUser?.fullName || "Accountant",
                relatedEntityType: "PROJECT",
                relatedEntityId: projectId
            }
        });
    } catch (e) {
        console.error("Failed to log activity for budget update:", e.message);
    }

    return {
        projectId,
        budget: projectBudget.budget,
        spent,
        remaining
    };
};

module.exports = {
    getFinanceSummary,
    getInvoicesList,
    createInvoice,
    recordPayment,
    createExpense,
    getExpensesList,
    getProjectBudgetSummary,
    setProjectBudget
};
