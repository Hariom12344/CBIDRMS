const express = require("express");
const router = express.Router();
const path = require("path");
const fs = require("fs");
const multer = require("multer");
const documentsController = require("./documents.controller");
const { verifyToken, requireRole } = require("../../middlewares/auth.middleware");

const uploadAllowedRoles = ["SUPER_ADMIN", "COMPANY_ADMIN", "PROJECT_MANAGER", "SITE_SUPERVISOR", "DESIGNER", "ADMIN"];
const deleteAllowedRoles = ["SUPER_ADMIN", "COMPANY_ADMIN", "PROJECT_MANAGER", "ADMIN"];

// Ensure uploads/documents directory exists
const uploadDir = path.join(__dirname, "../../../uploads/documents");
if (!fs.existsSync(uploadDir)) {
    fs.mkdirSync(uploadDir, { recursive: true });
}

// Multer Storage Configuration
const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        cb(null, uploadDir);
    },
    filename: (req, file, cb) => {
        const uniqueSuffix = Date.now() + "-" + Math.round(Math.random() * 1e9);
        const ext = path.extname(file.originalname) || ".pdf";
        cb(null, `doc-${uniqueSuffix}${ext}`);
    }
});

const allowedExtensions = /pdf|png|jpg|jpeg|dwg|dxf|docx|xlsx/;

const upload = multer({
    storage,
    limits: { fileSize: 25 * 1024 * 1024 }, // 25MB limit per FC-012 §9
    fileFilter: (req, file, cb) => {
        const ext = path.extname(file.originalname).toLowerCase().replace(".", "");
        if (allowedExtensions.test(ext)) {
            return cb(null, true);
        }
        const err = new Error("UNSUPPORTED_FILE_TYPE: File extension not allowed. Allowed types: pdf, png, jpg, jpeg, dwg, dxf, docx, xlsx");
        err.code = "UNSUPPORTED_FILE_TYPE";
        cb(err);
    }
});

// Middleware wrapper to handle Multer errors gracefully
const handleUpload = (req, res, next) => {
    upload.single("file")(req, res, (err) => {
        if (err) {
            if (err.code === "LIMIT_FILE_SIZE") {
                return res.status(413).json({
                    success: false,
                    message: "File exceeds maximum allowed size of 25MB",
                    data: null,
                    error: "FILE_TOO_LARGE"
                });
            }
            if (err.message && err.message.startsWith("UNSUPPORTED_FILE_TYPE")) {
                return res.status(415).json({
                    success: false,
                    message: "Unsupported file type. Allowed extensions: pdf, png, jpg, jpeg, dwg, dxf, docx, xlsx",
                    data: null,
                    error: "UNSUPPORTED_FILE_TYPE"
                });
            }
            return res.status(400).json({
                success: false,
                message: err.message || "File upload failed",
                data: null,
                error: "VALIDATION_ERROR"
            });
        }
        next();
    });
};

// Document Routes
router.get("/", verifyToken, documentsController.getDocuments);
router.get("/:id", verifyToken, documentsController.getDocument);
router.post("/", verifyToken, requireRole(uploadAllowedRoles), handleUpload, documentsController.createDocumentRoute);
router.get("/:id/download", verifyToken, documentsController.downloadDocument);
router.get("/:id/file", documentsController.serveDocumentFile);
router.delete("/:id", verifyToken, requireRole(deleteAllowedRoles), documentsController.deleteDocumentRoute);

module.exports = router;
