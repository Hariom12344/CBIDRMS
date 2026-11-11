const prisma = require("../../../config/db");

const buildWhereClause = (companyId, search) => {
    const where = {};

    if (companyId) {
        where.companyId = companyId;
    }

    if (search && search.trim() !== "") {
        const query = search.trim();
        where.OR = [
            { name: { contains: query } },
            { email: { contains: query } },
            { mobile: { contains: query } },
            { companyName: { contains: query } }
        ];
    }

    return where;
};

const findCustomers = async ({ companyId, search, skip = 0, take = 20 }) => {
    const where = buildWhereClause(companyId, search);

    return await prisma.customer.findMany({
        where,
        skip,
        take,
        orderBy: { createdAt: "desc" },
        include: {
            projects: {
                select: { id: true, name: true, budget: true }
            }
        }
    });
};

const countCustomers = async ({ companyId, search }) => {
    const where = buildWhereClause(companyId, search);
    return await prisma.customer.count({ where });
};

const findCustomerById = async (id, companyId) => {
    const parsedId = typeof id === "string" && id.startsWith("CUST-")
        ? parseInt(id.replace("CUST-", ""), 10)
        : parseInt(id, 10);

    const where = { id: parsedId };
    if (companyId) {
        where.companyId = companyId;
    }

    return await prisma.customer.findFirst({
        where,
        include: {
            projects: {
                select: { id: true, name: true, budget: true, status: true }
            },
            quotations: {
                select: { id: true, quotationNumber: true, grandTotal: true, status: true }
            }
        }
    });
};

const createCustomer = async (data) => {
    return await prisma.customer.create({
        data
    });
};

const updateCustomer = async (id, data) => {
    return await prisma.customer.update({
        where: { id: parseInt(id, 10) },
        data
    });
};

module.exports = {
    findCustomers,
    countCustomers,
    findCustomerById,
    createCustomer,
    updateCustomer
};
