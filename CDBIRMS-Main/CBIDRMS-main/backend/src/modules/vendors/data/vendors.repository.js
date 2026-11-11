const prisma = require("../../../config/db");

const findVendors = async ({ companyId, search, skip, take }) => {
    const where = {};

    if (companyId) {
        where.companyId = companyId;
    }

    if (search && search.trim() !== "") {
        const query = search.trim();
        where.OR = [
            { companyName: { contains: query } },
            { contactPerson: { contains: query } },
            { materialsSupplied: { contains: query } }
        ];
    }

    const [vendors, total] = await Promise.all([
        prisma.vendor.findMany({
            where,
            skip,
            take,
            orderBy: { createdAt: "desc" }
        }),
        prisma.vendor.count({ where })
    ]);

    return { vendors, total };
};

const findVendorById = async (id, companyId) => {
    const where = { id: parseInt(id, 10) };
    if (companyId) {
        where.companyId = companyId;
    }
    return prisma.vendor.findFirst({ where });
};

const createVendorRecord = async (data) => {
    return prisma.vendor.create({
        data
    });
};

const updateVendorRecord = async (id, data) => {
    return prisma.vendor.update({
        where: { id: parseInt(id, 10) },
        data
    });
};

module.exports = {
    findVendors,
    findVendorById,
    createVendorRecord,
    updateVendorRecord
};
