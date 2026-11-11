const {
    findCustomers,
    countCustomers,
    findCustomerById,
    createCustomer,
    updateCustomer
} = require("../data/customers.repository");

const formatCustomer = (customer) => {
    const projectHistory = customer.projects ? customer.projects.map((p) => p.name) : [];
    
    // Calculate total spent from linked projects budget
    const totalSpent = customer.projects
        ? customer.projects.reduce((sum, p) => sum + (p.budget || 0), 0)
        : 0;

    return {
        id: `CUST-${String(customer.id).padStart(3, "0")}`,
        rawId: customer.id,
        name: customer.name,
        email: customer.email || "",
        phone: customer.mobile || "",
        address: customer.address || "",
        companyName: customer.companyName || "",
        gstin: customer.gstin || "",
        contactPerson: customer.contactPerson || "",
        projectHistory,
        totalSpent,
        createdAt: customer.createdAt,
        updatedAt: customer.updatedAt
    };
};

const getCustomersList = async ({ companyId, search, page = 1, limit = 20 }) => {
    const pageNum = Math.max(1, parseInt(page, 10) || 1);
    const limitNum = Math.max(1, parseInt(limit, 10) || 20);
    const skip = (pageNum - 1) * limitNum;

    const [customers, total] = await Promise.all([
        findCustomers({ companyId, search, skip, take: limitNum }),
        countCustomers({ companyId, search })
    ]);

    const formattedCustomers = customers.map(formatCustomer);

    return {
        customers: formattedCustomers,
        total,
        page: pageNum,
        limit: limitNum,
        totalPages: Math.ceil(total / limitNum)
    };
};

const getCustomerDetails = async (id, companyId) => {
    // Strip "CUST-" prefix if passed as string ID
    const numericId = typeof id === "string" && id.startsWith("CUST-")
        ? parseInt(id.replace("CUST-", ""), 10)
        : parseInt(id, 10);

    if (isNaN(numericId)) {
        const error = new Error("Invalid customer ID format");
        error.code = "VALIDATION_ERROR";
        error.status = 400;
        throw error;
    }

    const customer = await findCustomerById(numericId, companyId);
    if (!customer) {
        const error = new Error("Customer not found");
        error.code = "CUSTOMER_NOT_FOUND";
        error.status = 404;
        throw error;
    }

    return formatCustomer(customer);
};

const addCustomer = async (data, user) => {
    const createData = {
        name: data.name.trim(),
        email: data.email.trim().toLowerCase(),
        mobile: data.phone.trim(),
        address: data.address.trim(),
        companyName: data.companyName ? data.companyName.trim() : null,
        gstin: data.gstin ? data.gstin.trim() : null,
        contactPerson: data.contactPerson ? data.contactPerson.trim() : null,
        companyId: user?.companyId || null,
        createdBy: user?.id || null
    };

    const newCustomer = await createCustomer(createData);
    return formatCustomer(newCustomer);
};

const editCustomer = async (id, data, companyId) => {
    const numericId = typeof id === "string" && id.startsWith("CUST-")
        ? parseInt(id.replace("CUST-", ""), 10)
        : parseInt(id, 10);

    if (isNaN(numericId)) {
        const error = new Error("Invalid customer ID format");
        error.code = "VALIDATION_ERROR";
        error.status = 400;
        throw error;
    }

    const existing = await findCustomerById(numericId, companyId);
    if (!existing) {
        const error = new Error("Customer not found");
        error.code = "CUSTOMER_NOT_FOUND";
        error.status = 404;
        throw error;
    }

    const updateData = {};
    if (data.name) updateData.name = data.name.trim();
    if (data.email) updateData.email = data.email.trim().toLowerCase();
    if (data.phone) updateData.mobile = data.phone.trim();
    if (data.address) updateData.address = data.address.trim();
    if (data.companyName !== undefined) updateData.companyName = data.companyName ? data.companyName.trim() : null;
    if (data.gstin !== undefined) updateData.gstin = data.gstin ? data.gstin.trim() : null;
    if (data.contactPerson !== undefined) updateData.contactPerson = data.contactPerson ? data.contactPerson.trim() : null;

    const updated = await updateCustomer(numericId, updateData);
    return formatCustomer(updated);
};

module.exports = {
    getCustomersList,
    getCustomerDetails,
    addCustomer,
    editCustomer
};
