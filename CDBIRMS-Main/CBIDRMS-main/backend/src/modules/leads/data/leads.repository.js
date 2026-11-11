const prisma = require("../../../config/db");

// Find all leads with optional filters
const findLeads = async (where = {}) => {
    return await prisma.lead.findMany({
        where,
        include: {
            assignedTo: {
                select: {
                    id: true,
                    fullName: true,
                    email: true,
                    role: true
                }
            },
            project: {
                select: {
                    id: true,
                    name: true,
                    status: true
                }
            },
            customer: {
                select: {
                    id: true,
                    name: true,
                    email: true,
                    mobile: true
                }
            }
        },
        orderBy: {
            createdAt: "desc"
        }
    });
};

// Find lead by ID
const findLeadById = async (id) => {
    return await prisma.lead.findUnique({
        where: { id },
        include: {
            assignedTo: {
                select: {
                    id: true,
                    fullName: true,
                    email: true,
                    role: true
                }
            },
            project: {
                select: {
                    id: true,
                    name: true,
                    status: true
                }
            },
            customer: {
                select: {
                    id: true,
                    name: true,
                    email: true,
                    mobile: true
                }
            }
        }
    });
};

// Create a new lead
const createLead = async (leadData) => {
    return await prisma.lead.create({
        data: leadData,
        include: {
            assignedTo: {
                select: {
                    id: true,
                    fullName: true,
                    email: true,
                    role: true
                }
            },
            customer: {
                select: {
                    id: true,
                    name: true
                }
            }
        }
    });
};

// Update existing lead
const updateLead = async (id, data) => {
    return await prisma.lead.update({
        where: { id },
        data,
        include: {
            assignedTo: {
                select: {
                    id: true,
                    fullName: true,
                    email: true,
                    role: true
                }
            },
            project: {
                select: {
                    id: true,
                    name: true,
                    status: true
                }
            },
            customer: {
                select: {
                    id: true,
                    name: true
                }
            }
        }
    });
};

// Delete a lead
const deleteLead = async (id) => {
    return await prisma.lead.delete({
        where: { id }
    });
};

// Find the last created lead to get the sequence ID
const findLatestLead = async () => {
    return await prisma.lead.findFirst({
        orderBy: {
            createdAt: "desc"
        }
    });
};

module.exports = {
    findLeads,
    findLeadById,
    createLead,
    updateLead,
    deleteLead,
    findLatestLead
};
