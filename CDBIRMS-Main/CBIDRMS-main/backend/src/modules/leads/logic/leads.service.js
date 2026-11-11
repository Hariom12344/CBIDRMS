const prisma = require("../../../config/db");
const leadsRepository = require("../data/leads.repository");
const projectsRepository = require("../../projects/data/projects.repository");

// Helper to generate sequential Lead ID: LD-<n>
const generateNextLeadId = async () => {
    const latest = await leadsRepository.findLatestLead();
    let nextNum = 101;
    if (latest && latest.id) {
        const match = latest.id.match(/^LD-(\d+)$/);
        if (match) {
            nextNum = parseInt(match[1], 10) + 1;
        }
    }
    return `LD-${nextNum}`;
};

// Helper to generate sequential Project ID: PRJ-<n>
const generateNextProjectId = async () => {
    const latest = await projectsRepository.findLatestProject();
    let nextNum = 101;
    if (latest && latest.id) {
        const match = latest.id.match(/^PRJ-(\d+)$/);
        if (match) {
            nextNum = parseInt(match[1], 10) + 1;
        }
    }
    return `PRJ-${nextNum}`;
};

// Helper to log audit actions
const logAuditAction = async (userId, action, leadId, oldValue = null, newValue = null) => {
    try {
        await prisma.auditLog.create({
            data: {
                userId,
                action,
                leadId,
                oldValue: oldValue ? String(oldValue) : null,
                newValue: newValue ? String(newValue) : null
            }
        });
    } catch (err) {
        console.error("Failed to write audit log:", err);
    }
};

// Get list of leads based on role constraints
const getLeadsList = async (user, query) => {
    const where = {};

    // Multi-tenant company isolation
    if (user.companyId) {
        where.companyId = user.companyId;
    }

    // Filter by status if provided
    if (query.status && query.status !== "All") {
        where.status = query.status;
    }

    // Role-based restrictions
    const isAdmin = ["SUPER_ADMIN", "COMPANY_ADMIN", "ADMIN"].includes(user.role);
    if (!isAdmin && user.role === "PROJECT_MANAGER") {
        // Project Manager: Filter to assigned or created leads
        if (query.assignedTo) {
            where.assignedToId = parseInt(query.assignedTo, 10);
        }
    } else if (isAdmin && query.assignedTo) {
        where.assignedToId = parseInt(query.assignedTo, 10);
    }

    const leads = await leadsRepository.findLeads(where);
    
    // Map assigned user object to a flat "assignedTo" string name for the frontend
    return leads.map(lead => ({
        ...lead,
        assignedTo: lead.assignedTo ? lead.assignedTo.fullName : "Unassigned"
    }));
};

// Get single lead details
const getLeadById = async (user, id) => {
    const lead = await leadsRepository.findLeadById(id);
    if (!lead) {
        const err = new Error("Lead not found");
        err.statusCode = 404;
        err.errorCode = "LEAD_NOT_FOUND";
        throw err;
    }

    // Company scoping check
    if (user.companyId && lead.companyId && lead.companyId !== user.companyId) {
        const err = new Error("You do not have access to this lead");
        err.statusCode = 403;
        err.errorCode = "FORBIDDEN";
        throw err;
    }

    return {
        ...lead,
        assignedTo: lead.assignedTo ? lead.assignedTo.fullName : "Unassigned"
    };
};

// Create a new lead
const createNewLead = async (user, data) => {
    const nextId = await generateNextLeadId();

    const leadData = {
        id: nextId,
        clientName: data.clientName.trim(),
        email: data.email || null,
        phone: data.phone || null,
        propertyType: data.propertyType || null,
        estimatedBudget: data.estimatedBudget !== undefined ? parseFloat(data.estimatedBudget) : null,
        status: "New",
        companyId: user.companyId || null,
        createdBy: user.id
    };

    // Handle assignment
    if (data.assignedTo) {
        const assignedToId = parseInt(data.assignedTo, 10);
        if (!isNaN(assignedToId)) {
            const assignedUser = await prisma.user.findUnique({
                where: { id: assignedToId }
            });
            if (!assignedUser) {
                const err = new Error("Assigned user not found");
                err.statusCode = 400;
                err.errorCode = "VALIDATION_ERROR";
                throw err;
            }
            leadData.assignedToId = assignedToId;
        }
    }

    const createdLead = await leadsRepository.createLead(leadData);
    
    // Audit log creation
    await logAuditAction(user.id, "CREATE", createdLead.id, null, createdLead.status);

    return {
        ...createdLead,
        assignedTo: createdLead.assignedTo ? createdLead.assignedTo.fullName : "Unassigned"
    };
};

// Update an existing lead
const updateExistingLead = async (user, id, data) => {
    const lead = await leadsRepository.findLeadById(id);
    if (!lead) {
        const err = new Error("Lead not found");
        err.statusCode = 404;
        err.errorCode = "LEAD_NOT_FOUND";
        throw err;
    }

    // Company scoping check
    if (user.companyId && lead.companyId && lead.companyId !== user.companyId) {
        const err = new Error("You do not have permission to update this lead");
        err.statusCode = 403;
        err.errorCode = "FORBIDDEN";
        throw err;
    }

    // Converted leads become read-only
    if (lead.status === "Won" || lead.project) {
        const err = new Error("Converted leads become read-only and cannot be updated");
        err.statusCode = 409;
        err.errorCode = "LEAD_ALREADY_CONVERTED";
        throw err;
    }

    // Block manual transitions to Won (must convert via endpoint)
    if (data.status === "Won") {
        const err = new Error("Lead can only be set to Won by converting to a project");
        err.statusCode = 400;
        err.errorCode = "INVALID_STATUS_TRANSITION";
        throw err;
    }

    const updateData = {};
    if (data.clientName) updateData.clientName = data.clientName.trim();
    if (data.email !== undefined) updateData.email = data.email || null;
    if (data.phone !== undefined) updateData.phone = data.phone || null;
    if (data.propertyType !== undefined) updateData.propertyType = data.propertyType || null;
    if (data.estimatedBudget !== undefined) updateData.estimatedBudget = data.estimatedBudget !== null ? parseFloat(data.estimatedBudget) : null;
    if (data.status) updateData.status = data.status;

    // Handle assignment updates
    if (data.assignedTo !== undefined) {
        if (data.assignedTo === null || data.assignedTo === "" || data.assignedTo === "Unassigned") {
            updateData.assignedToId = null;
        } else {
            const assignedToId = parseInt(data.assignedTo, 10);
            if (!isNaN(assignedToId)) {
                const assignedUser = await prisma.user.findUnique({
                    where: { id: assignedToId }
                });
                if (!assignedUser) {
                    const err = new Error("Assigned user not found");
                    err.statusCode = 400;
                    err.errorCode = "VALIDATION_ERROR";
                    throw err;
                }
                updateData.assignedToId = assignedToId;
            }
        }
    }

    const updatedLead = await leadsRepository.updateLead(id, updateData);

    // Audit log update
    await logAuditAction(user.id, "UPDATE", lead.id, lead.status, updatedLead.status);

    return {
        ...updatedLead,
        assignedTo: updatedLead.assignedTo ? updatedLead.assignedTo.fullName : "Unassigned"
    };
};

// Convert Lead to Project & Customer (Atomic Database Transaction)
const convertLeadToProject = async (user, id) => {
    const lead = await leadsRepository.findLeadById(id);
    if (!lead) {
        const err = new Error("Lead not found");
        err.statusCode = 404;
        err.errorCode = "LEAD_NOT_FOUND";
        throw err;
    }

    // Company scoping check
    if (user.companyId && lead.companyId && lead.companyId !== user.companyId) {
        const err = new Error("You do not have permission to convert this lead");
        err.statusCode = 403;
        err.errorCode = "FORBIDDEN";
        throw err;
    }

    // Idempotency check
    if (lead.status === "Won" || lead.project) {
        const err = new Error("Lead has already been converted to a project");
        err.statusCode = 409;
        err.errorCode = "LEAD_ALREADY_CONVERTED";
        throw err;
    }

    // 1. Find or Create Customer
    let customer = null;
    if (lead.email) {
        customer = await prisma.customer.findFirst({
            where: {
                email: lead.email,
                ...(user.companyId ? { companyId: user.companyId } : {})
            }
        });
    }
    if (!customer && lead.phone) {
        customer = await prisma.customer.findFirst({
            where: {
                mobile: lead.phone,
                ...(user.companyId ? { companyId: user.companyId } : {})
            }
        });
    }

    if (!customer) {
        customer = await prisma.customer.create({
            data: {
                name: lead.clientName,
                email: lead.email || null,
                mobile: lead.phone || "0000000000",
                address: lead.propertyType ? `${lead.propertyType} Address` : "Address Pending",
                companyId: user.companyId || null,
                createdBy: user.id
            }
        });
    }

    // 2. Prepare Project payload
    const nextProjectId = await generateNextProjectId();
    const todayStr = new Date().toISOString().split("T")[0];
    
    const sixMonthsLater = new Date();
    sixMonthsLater.setMonth(sixMonthsLater.getMonth() + 6);
    const endDateStr = sixMonthsLater.toISOString().split("T")[0];

    const projectData = {
        id: nextProjectId,
        name: lead.propertyType ? `${lead.clientName} - ${lead.propertyType}` : `${lead.clientName} Project`,
        clientName: lead.clientName,
        designerName: lead.assignedTo ? lead.assignedTo.fullName : "Unassigned",
        startDate: todayStr,
        endDate: endDateStr,
        budget: lead.estimatedBudget || 0.0,
        status: "PLANNING",
        progress: 0.0,
        leadId: lead.id,
        customerId: customer.id
    };

    // 3. Execute atomic transaction
    const [updatedLead, createdProject] = await prisma.$transaction([
        prisma.lead.update({
            where: { id: lead.id },
            data: {
                status: "Won",
                customerId: customer.id
            },
            include: {
                assignedTo: {
                    select: { fullName: true }
                },
                customer: {
                    select: { id: true, name: true }
                }
            }
        }),
        prisma.project.create({
            data: projectData
        })
    ]);

    // Audit log conversion
    await logAuditAction(user.id, "CONVERT", lead.id, lead.status, "Won");

    return {
        lead: {
            ...updatedLead,
            assignedTo: updatedLead.assignedTo ? updatedLead.assignedTo.fullName : "Unassigned"
        },
        project: createdProject,
        customer
    };
};

// Delete a lead
const deleteLead = async (user, id) => {
    const isAdmin = ["SUPER_ADMIN", "COMPANY_ADMIN", "ADMIN"].includes(user.role);
    if (!isAdmin) {
        const err = new Error("Only admins can delete leads");
        err.statusCode = 403;
        err.errorCode = "FORBIDDEN";
        throw err;
    }

    const lead = await leadsRepository.findLeadById(id);
    if (!lead) {
        const err = new Error("Lead not found");
        err.statusCode = 404;
        err.errorCode = "LEAD_NOT_FOUND";
        throw err;
    }

    // Safeguard: Block deletion of converted leads
    if (lead.status === "Won" || lead.project) {
        const err = new Error("Cannot delete a lead that has already been converted to a project");
        err.statusCode = 409;
        err.errorCode = "LEAD_HAS_LINKED_PROJECT";
        throw err;
    }

    await leadsRepository.deleteLead(id);

    // Audit log deletion
    await logAuditAction(user.id, "DELETE", lead.id, lead.status, null);

    return {
        message: "Lead deleted successfully"
    };
};

module.exports = {
    getLeadsList,
    getLeadById,
    createNewLead,
    updateExistingLead,
    convertLeadToProject,
    deleteLead
};
