const {
    findVendors,
    findVendorById,
    createVendorRecord,
    updateVendorRecord
} = require("../data/vendors.repository");

const safeParseJsonArray = (str) => {
    if (!str) return [];
    try {
        const parsed = JSON.parse(str);
        return Array.isArray(parsed) ? parsed : [];
    } catch {
        return [];
    }
};

const formatVendorOutput = (vendor) => {
    if (!vendor) return null;
    return {
        id: String(vendor.id),
        companyName: vendor.companyName,
        contactPerson: vendor.contactPerson,
        email: vendor.email,
        phone: vendor.phone,
        materialsSupplied: safeParseJsonArray(vendor.materialsSupplied),
        companyId: vendor.companyId,
        createdBy: vendor.createdBy,
        createdAt: vendor.createdAt,
        updatedAt: vendor.updatedAt
    };
};

const getVendorsList = async ({ companyId, search, page = 1, limit = 20 }) => {
    const skip = (page - 1) * limit;
    const { vendors, total } = await findVendors({
        companyId,
        search,
        skip,
        take: limit
    });

    return {
        vendors: vendors.map(formatVendorOutput),
        total,
        page,
        limit
    };
};

const getVendorDetails = async (id, companyId) => {
    const vendor = await findVendorById(id, companyId);
    if (!vendor) {
        const error = new Error("Vendor not found");
        error.status = 404;
        error.code = "VENDOR_NOT_FOUND";
        throw error;
    }

    return {
        vendor: formatVendorOutput(vendor),
        purchaseOrders: [] // Empty state until FC-009 Purchase Orders module is connected
    };
};

const addVendor = async (data, user) => {
    const materialsJson = JSON.stringify(data.materialsSupplied || []);

    const vendor = await createVendorRecord({
        companyName: data.companyName,
        contactPerson: data.contactPerson,
        email: data.email,
        phone: data.phone,
        materialsSupplied: materialsJson,
        companyId: user?.companyId || null,
        createdBy: user?.id || null
    });

    return formatVendorOutput(vendor);
};

const editVendor = async (id, data, companyId) => {
    const existing = await findVendorById(id, companyId);
    if (!existing) {
        const error = new Error("Vendor not found");
        error.status = 404;
        error.code = "VENDOR_NOT_FOUND";
        throw error;
    }

    const updateData = {};
    if (data.companyName !== undefined) updateData.companyName = data.companyName;
    if (data.contactPerson !== undefined) updateData.contactPerson = data.contactPerson;
    if (data.email !== undefined) updateData.email = data.email;
    if (data.phone !== undefined) updateData.phone = data.phone;
    if (data.materialsSupplied !== undefined) {
        updateData.materialsSupplied = JSON.stringify(data.materialsSupplied);
    }

    const updated = await updateVendorRecord(id, updateData);
    return formatVendorOutput(updated);
};

module.exports = {
    getVendorsList,
    getVendorDetails,
    addVendor,
    editVendor
};
