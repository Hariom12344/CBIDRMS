const prisma = require("../../../config/db");

const getTodayFormatted = () => {
    return new Date().toISOString().split("T")[0];
};

const findAllInvoices = async () => {
    return await prisma.invoice.findMany();
};

const findAllPayments = async () => {
    return await prisma.payment.findMany();
};

const buildInvoicesWhere = ({ projectId, status }) => {
    const where = {};
    const today = getTodayFormatted();

    if (projectId) {
        where.projectId = projectId;
    }

    if (status && status !== "ALL") {
        if (status === "OVERDUE") {
            where.pendingAmount = { gt: 0 };
            where.dueDate = { lt: today };
        } else if (status === "PAID") {
            where.pendingAmount = 0;
        } else if (status === "PENDING") {
            where.pendingAmount = { gt: 0 };
            where.dueDate = { gte: today };
        } else {
            where.status = status;
        }
    }

    return where;
};

const findInvoices = async ({ projectId, status, skip = 0, take = 50 }) => {
    const where = buildInvoicesWhere({ projectId, status });

    return await prisma.invoice.findMany({
        where,
        include: {
            payments: {
                orderBy: { createdAt: "desc" }
            }
        },
        orderBy: { createdAt: "desc" },
        skip,
        take: Number(take)
    });
};

const countInvoices = async ({ projectId, status }) => {
    const where = buildInvoicesWhere({ projectId, status });
    return await prisma.invoice.count({ where });
};

const findInvoiceById = async (id) => {
    return await prisma.invoice.findUnique({
        where: { id },
        include: { payments: true }
    });
};

const createInvoiceRecord = async (data) => {
    return await prisma.invoice.create({
        data
    });
};

const countInvoicesTotal = async () => {
    return await prisma.invoice.count();
};

const recordPaymentTransaction = async (invoiceId, paymentData, newPending, newStatus) => {
    return await prisma.$transaction(async (tx) => {
        const payment = await tx.payment.create({
            data: {
                invoiceId,
                amount: paymentData.amount,
                date: paymentData.date,
                method: paymentData.method,
                note: paymentData.note,
                recordedBy: paymentData.recordedBy
            }
        });

        const invoice = await tx.invoice.update({
            where: { id: invoiceId },
            data: {
                pendingAmount: newPending,
                status: newStatus
            },
            include: {
                payments: {
                    orderBy: { createdAt: "desc" }
                }
            }
        });

        return { payment, invoice };
    });
};

const createExpenseRecord = async (data) => {
    return await prisma.expense.create({
        data
    });
};

const buildExpensesWhere = ({ projectId, category }) => {
    const where = {};
    if (projectId) {
        where.projectId = projectId;
    }
    if (category && category !== "ALL") {
        where.category = category;
    }
    return where;
};

const findExpenses = async ({ projectId, category, skip = 0, take = 50 }) => {
    const where = buildExpensesWhere({ projectId, category });

    return await prisma.expense.findMany({
        where,
        orderBy: { createdAt: "desc" },
        skip,
        take: Number(take)
    });
};

const countExpenses = async ({ projectId, category }) => {
    const where = buildExpensesWhere({ projectId, category });
    return await prisma.expense.count({ where });
};

const findProjectWithBudgetAndExpenses = async (projectId) => {
    return await prisma.project.findUnique({
        where: { id: projectId },
        include: {
            projectBudget: true,
            expenses: true
        }
    });
};

const upsertProjectBudgetRecord = async ({ projectId, budget, setBy, companyId }) => {
    return await prisma.projectBudget.upsert({
        where: { projectId },
        update: {
            budget,
            setBy
        },
        create: {
            projectId,
            budget,
            companyId,
            setBy
        }
    });
};

const findProjectById = async (id) => {
    return await prisma.project.findUnique({
        where: { id }
    });
};

module.exports = {
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
};
