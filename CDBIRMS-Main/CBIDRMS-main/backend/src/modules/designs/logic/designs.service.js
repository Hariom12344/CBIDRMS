const path = require("path");
const fs = require("fs");
const {
    findDesigns,
    countDesigns,
    findDesignById,
    findRevisionChain,
    createDesignRecord,
    updateDesignStatus,
    createApprovalLog,
    findProjectById,
    findProjectAssignment,
    findProjectManagers,
    findUserById
} = require("../data/designs.repository");
const { uploadDesignFile, getSignedDownloadUrl } = require("../../../utils/storage.service");
const { sendDesignNotificationEmail } = require("../../../utils/email.service");

/**
 * Format raw file size in bytes to human-readable string (e.g., 2.5 MB)
 */
const formatFileSize = (bytes) => {
    if (!bytes || bytes === 0) return "0 KB";
    const k = 1024;
    const sizes = ["Bytes", "KB", "MB", "GB"];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + " " + sizes[i];
};

/**
 * Extract canonical file extension/type
 */
const getFileCanonicalType = (fileName) => {
    if (!fileName) return "PDF";
    const ext = path.extname(fileName).toLowerCase().replace(".", "");
    if (ext === "pdf") return "PDF";
    if (["png", "jpg", "jpeg"].includes(ext)) return "IMAGE";
    if (["dwg", "dxf"].includes(ext)) return "CAD";
    return ext.toUpperCase();
};

/**
 * Verify project assignment for DESIGNER role per FC-010 §8
 */
const verifyProjectAssignment = async (projectId, currentUser) => {
    if (currentUser?.role === "ACCOUNTANT") {
        const err = new Error("Accountant role is not authorized to access design management");
        err.status = 403;
        err.code = "FORBIDDEN";
        throw err;
    }

    const project = await findProjectById(projectId);
    if (!project) {
        const err = new Error(`Project '${projectId}' not found`);
        err.status = 404;
        err.code = "PROJECT_NOT_FOUND";
        throw err;
    }

    if (currentUser?.role === "DESIGNER" && currentUser?.id) {
        const assignment = await findProjectAssignment(projectId, currentUser.id);
        if (!assignment) {
            const err = new Error(`Access denied. Designer is not assigned to project '${projectId}'`);
            err.status = 403;
            err.code = "FORBIDDEN";
            throw err;
        }
    }

    return project;
};

/**
 * Get list of designs with optional filtering
 */
const getDesignsList = async ({ projectId, category, search, page = 1, limit = 50, currentUser }) => {
    if (currentUser?.role === "ACCOUNTANT") {
        const err = new Error("Accountant role is not authorized to access design management");
        err.status = 403;
        err.code = "FORBIDDEN";
        throw err;
    }

    if (projectId) {
        const project = await findProjectById(projectId);
        if (!project) {
            const err = new Error(`Project '${projectId}' not found`);
            err.status = 404;
            err.code = "PROJECT_NOT_FOUND";
            throw err;
        }
    }

    const skip = (Math.max(1, page) - 1) * limit;

    const [designs, total] = await Promise.all([
        findDesigns({ projectId, category, search, skip, take: limit }),
        countDesigns({ projectId, category, search })
    ]);

    return {
        designs,
        total,
        page: Number(page),
        limit: Number(limit)
    };
};

/**
 * Get details of a single design by ID along with approval history and revision chain
 */
const getDesignById = async (id, currentUser) => {
    if (currentUser?.role === "ACCOUNTANT") {
        const err = new Error("Accountant role is not authorized to access design management");
        err.status = 403;
        err.code = "FORBIDDEN";
        throw err;
    }

    const design = await findDesignById(id);
    if (!design) {
        const error = new Error(`Design with ID '${id}' not found`);
        error.status = 404;
        error.code = "DESIGN_NOT_FOUND";
        throw error;
    }

    let revisions = [];
    const rootId = design.rootDesignId || design.id;
    if (rootId) {
        revisions = await findRevisionChain(rootId);
    }

    return {
        design,
        approvalHistory: design.approvalLogs,
        revisions
    };
};

/**
 * Create initial design record (v1.0, PENDING)
 */
const createDesign = async (data, currentUser) => {
    const { title, projectId, category, file, fileUrl, fileType, fileSize } = data;

    const project = await verifyProjectAssignment(projectId, currentUser);

    const tempDesignId = `dsg-${Date.now()}-${Math.round(Math.random() * 1000)}`;
    const originalFileName = file ? file.originalname : `${title.trim()}.pdf`;

    let uploadedUrl = fileUrl;
    let computedSize = fileSize || "1.0 MB";
    let computedType = fileType || getFileCanonicalType(originalFileName);

    if (file) {
        computedSize = formatFileSize(file.size);
        computedType = getFileCanonicalType(file.originalname);

        const storageRes = await uploadDesignFile({
            projectId,
            designId: tempDesignId,
            version: "v1.0",
            fileName: file.originalname,
            buffer: file.buffer,
            contentType: file.mimetype
        });
        uploadedUrl = storageRes.fileUrl;
    }

    if (!uploadedUrl) {
        uploadedUrl = `https://storage.idpms.app/designs/${projectId}/${tempDesignId}/v1.0-${encodeURIComponent(originalFileName)}`;
    }

    const design = await createDesignRecord({
        title: title.trim(),
        projectId,
        category: category || "THREE_D_RENDER",
        fileType: computedType,
        fileSize: computedSize,
        fileUrl: uploadedUrl,
        version: "v1.0",
        approvalStatus: "PENDING",
        uploadedBy: currentUser?.id ? Number(currentUser.id) : null,
        companyId: currentUser?.companyId ? Number(currentUser.companyId) : null
    });

    // Notify Project Managers per FC-010 §15
    try {
        const pmMembers = await findProjectManagers(projectId);
        for (const member of pmMembers) {
            if (member.user && member.user.email) {
                await sendDesignNotificationEmail({
                    toEmail: member.user.email,
                    subject: `New Design Uploaded: ${design.title} (v1.0)`,
                    title: design.title,
                    projectName: project.name,
                    action: "UPLOAD",
                    version: "v1.0"
                });
            }
        }
    } catch (notifErr) {
        console.warn("[DESIGN SERVICE] Notification warning:", notifErr.message);
    }

    return design;
};

/**
 * Create a new revision against an existing design (v1.1 or v2.0)
 */
const createRevision = async (parentDesignId, data, currentUser) => {
    const parent = await findDesignById(parentDesignId);
    if (!parent) {
        const error = new Error(`Parent design '${parentDesignId}' not found`);
        error.status = 404;
        error.code = "DESIGN_NOT_FOUND";
        throw error;
    }

    const project = await verifyProjectAssignment(parent.projectId, currentUser);

    const rootId = parent.rootDesignId || parent.id;
    const isMajor = Boolean(data.isMajorVersion);

    let newVersion = "v1.1";
    if (parent.version && parent.version.startsWith("v")) {
        const parts = parent.version.substring(1).split(".");
        let major = parseInt(parts[0], 10) || 1;
        let minor = parseInt(parts[1], 10) || 0;

        if (isMajor) {
            major += 1;
            minor = 0;
        } else {
            minor += 1;
        }
        newVersion = `v${major}.${minor}`;
    }

    const file = data.file;
    const tempDesignId = `dsg-${Date.now()}-${Math.round(Math.random() * 1000)}`;
    const originalFileName = file ? file.originalname : `${(data.title || parent.title).trim()}.pdf`;

    let uploadedUrl = data.fileUrl;
    let computedSize = data.fileSize || parent.fileSize;
    let computedType = data.fileType || getFileCanonicalType(originalFileName);

    if (file) {
        computedSize = formatFileSize(file.size);
        computedType = getFileCanonicalType(file.originalname);

        const storageRes = await uploadDesignFile({
            projectId: parent.projectId,
            designId: tempDesignId,
            version: newVersion,
            fileName: file.originalname,
            buffer: file.buffer,
            contentType: file.mimetype
        });
        uploadedUrl = storageRes.fileUrl;
    }

    if (!uploadedUrl) {
        uploadedUrl = `https://storage.idpms.app/designs/${parent.projectId}/${tempDesignId}/${newVersion}-${encodeURIComponent(originalFileName)}`;
    }

    const newRevision = await createDesignRecord({
        title: data.title ? data.title.trim() : parent.title,
        projectId: parent.projectId,
        category: data.category || parent.category,
        fileType: computedType,
        fileSize: computedSize,
        fileUrl: uploadedUrl,
        version: newVersion,
        rootDesignId: rootId,
        approvalStatus: "PENDING",
        uploadedBy: currentUser?.id ? Number(currentUser.id) : null,
        companyId: currentUser?.companyId ? Number(currentUser.companyId) : null
    });

    // Notify Project Managers per FC-010 §15
    try {
        const pmMembers = await findProjectManagers(parent.projectId);
        for (const member of pmMembers) {
            if (member.user && member.user.email) {
                await sendDesignNotificationEmail({
                    toEmail: member.user.email,
                    subject: `Design Revision Uploaded: ${newRevision.title} (${newVersion})`,
                    title: newRevision.title,
                    projectName: project.name,
                    action: "REVISION",
                    version: newVersion
                });
            }
        }
    } catch (notifErr) {
        console.warn("[DESIGN SERVICE] Revision notification warning:", notifErr.message);
    }

    return newRevision;
};

/**
 * Approve or request revision for a design with audit logging
 */
const approveOrRejectDesign = async (id, { action, note }, currentUser) => {
    if (["SITE_SUPERVISOR", "DESIGNER", "ACCOUNTANT"].includes(currentUser?.role)) {
        const err = new Error(`Role '${currentUser.role}' is not authorized to approve or request revisions for designs`);
        err.status = 403;
        err.code = "FORBIDDEN";
        throw err;
    }

    const design = await findDesignById(id);
    if (!design) {
        const error = new Error(`Design with ID '${id}' not found`);
        error.status = 404;
        error.code = "DESIGN_NOT_FOUND";
        throw error;
    }

    const newStatus = action === "APPROVE" ? "APPROVED" : "REVISION_REQUESTED";

    await createApprovalLog({
        designId: id,
        action,
        actorId: currentUser?.id ? Number(currentUser.id) : null,
        actorName: currentUser?.fullName || currentUser?.email || "System User",
        note: note || (action === "APPROVE" ? "Approved design" : "Revision requested")
    });

    const updatedDesign = await updateDesignStatus(id, newStatus);

    if (design.uploadedBy) {
        try {
            const uploader = await findUserById(design.uploadedBy);
            if (uploader && uploader.email) {
                await sendDesignNotificationEmail({
                    toEmail: uploader.email,
                    subject: `Design ${action === "APPROVE" ? "Approved" : "Revision Requested"}: ${design.title} (${design.version})`,
                    title: design.title,
                    projectName: design.project?.name || "Project",
                    action,
                    version: design.version,
                    note
                });
            }
        } catch (notifErr) {
            console.warn("[DESIGN SERVICE] Approval notification warning:", notifErr.message);
        }
    }

    return updatedDesign;
};

/**
 * Get signed download link for a design
 */
const getDownloadLink = async (id, currentUser) => {
    if (currentUser?.role === "ACCOUNTANT") {
        const err = new Error("Accountant role is not authorized to download designs");
        err.status = 403;
        err.code = "FORBIDDEN";
        throw err;
    }

    const design = await findDesignById(id);
    if (!design) {
        const error = new Error(`Design with ID '${id}' not found`);
        error.status = 404;
        error.code = "DESIGN_NOT_FOUND";
        throw error;
    }

    return await getSignedDownloadUrl(design);
};

/**
 * Serve local design file if hosted locally
 */
const serveFile = async (id, res) => {
    const design = await findDesignById(id);
    if (!design) {
        const error = new Error(`Design with ID '${id}' not found`);
        error.status = 404;
        error.code = "DESIGN_NOT_FOUND";
        throw error;
    }

    if (design.fileUrl && fs.existsSync(design.fileUrl)) {
        return res.sendFile(path.resolve(design.fileUrl));
    }

    const safeTitle = (design.title || "Design Drawing").replace(/[\(\)\\]/g, "");
    const pdfContent = `%PDF-1.4
1 0 obj
<< /Type /Catalog /Pages 2 0 R >>
endobj
2 0 obj
<< /Type /Pages /Kinds /Page /Count 1 /Kids [ 3 0 R ] >>
endobj
3 0 obj
<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Contents 4 0 R /Resources << /Font << /F1 5 0 R >> >> >>
endobj
4 0 obj
<< /Length 95 >>
stream
BT
/F1 20 Tf
50 700 Td
(CIDRMS Design Drawing: ${safeTitle} (${design.version})) Tj
ET
endstream
endobj
5 0 obj
<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>
endobj
xref
0 6
0000000000 65535 f 
0000000009 00000 n 
0000000058 00000 n 
0000000125 00000 n 
0000000257 00000 n 
0000000402 00000 n 
trailer
<< /Size 6 /Root 1 0 R >>
startxref
475
%%EOF`;
    const pdfBuffer = Buffer.from(pdfContent, "utf-8");
    const fileName = `${design.title.endsWith(".pdf") ? design.title : `${design.title}.pdf`}`;

    res.setHeader("Content-Type", "application/pdf");
    res.setHeader("Content-Disposition", `inline; filename="${encodeURIComponent(fileName)}"`);
    res.setHeader("Content-Length", pdfBuffer.length);
    return res.send(pdfBuffer);
};

module.exports = {
    getDesignsList,
    getDesignById,
    createDesign,
    createRevision,
    approveOrRejectDesign,
    getDownloadLink,
    serveFile
};
