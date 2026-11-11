const path = require("path");
const fs = require("fs");
const prisma = require("../../config/db");

/**
 * Get list of documents with optional filtering by projectId, search, and category.
 */
const getDocumentsList = async ({ projectId, search, category, page = 1, limit = 50 }) => {
    const where = {};

    if (projectId) {
        where.projectId = projectId;
    }

    if (category && category !== "ALL") {
        where.category = category;
    }

    if (search && search.trim() !== "") {
        where.title = {
            contains: search.trim()
        };
    }

    const skip = (Math.max(1, page) - 1) * limit;

    const [documents, total] = await Promise.all([
        prisma.document.findMany({
            where,
            orderBy: { createdAt: "desc" },
            skip,
            take: Number(limit)
        }),
        prisma.document.count({ where })
    ]);

    return {
        documents,
        total,
        page: Number(page),
        limit: Number(limit)
    };
};

/**
 * Get details of a single document by ID.
 */
const getDocumentById = async (id) => {
    const document = await prisma.document.findUnique({
        where: { id }
    });

    if (!document) {
        const error = new Error(`Document with ID '${id}' not found`);
        error.status = 404;
        error.code = "DOCUMENT_NOT_FOUND";
        throw error;
    }

    return document;
};

/**
 * Create a new document metadata record.
 */
const createDocument = async (data, currentUser) => {
    const { title, projectId, category, fileType, fileSize, fileUrl } = data;

    // Validate project existence
    const project = await prisma.project.findUnique({
        where: { id: projectId }
    });

    if (!project) {
        const error = new Error(`Project '${projectId}' not found`);
        error.status = 404;
        error.code = "PROJECT_NOT_FOUND";
        throw error;
    }

    const document = await prisma.document.create({
        data: {
            title: title.trim(),
            projectId,
            category: category || "OTHER",
            fileType: fileType || "PDF",
            fileSize: fileSize || "0 KB",
            fileUrl: fileUrl || `https://storage.idpms.app/documents/${projectId}/${Date.now()}_${encodeURIComponent(title)}`,
            uploadedBy: currentUser?.id && typeof currentUser.id === "number" ? currentUser.id : null,
            companyId: currentUser?.companyId || null
        }
    });

    return document;
};

/**
 * Delete a document record and clean up underlying file.
 */
const deleteDocument = async (id) => {
    const existing = await prisma.document.findUnique({
        where: { id }
    });

    if (!existing) {
        const error = new Error(`Document with ID '${id}' not found`);
        error.status = 404;
        error.code = "DOCUMENT_NOT_FOUND";
        throw error;
    }

    // Delete local file if it exists
    if (existing.fileUrl && existing.fileUrl.includes("/uploads/documents/")) {
        const filename = path.basename(existing.fileUrl);
        const filePath = path.join(__dirname, "../../../uploads/documents", filename);
        if (fs.existsSync(filePath)) {
            try {
                fs.unlinkSync(filePath);
            } catch (e) {
                console.error("Failed to delete document file:", e.message);
            }
        }
    }

    await prisma.document.delete({
        where: { id }
    });

    return { id };
};

module.exports = {
    getDocumentsList,
    getDocumentById,
    createDocument,
    deleteDocument
};
