const express = require("express");
const router = express.Router();
const path = require("path");
const multer = require("multer");
const designsController = require("./designs.controller");
const { verifyToken, requireRole } = require("../../../middlewares/auth.middleware");

// Roles per FC-010 §7:
// SUPER_ADMIN, COMPANY_ADMIN, PROJECT_MANAGER: view, upload, revise, approve, download
// DESIGNER: view, upload, revise, download (NO approve)
// SITE_SUPERVISOR: view, download (NO upload, NO approve)
// ACCOUNTANT: NO design access

const viewAllowedRoles = ["SUPER_ADMIN", "COMPANY_ADMIN", "PROJECT_MANAGER", "SITE_SUPERVISOR", "DESIGNER", "ADMIN"];
const uploadAllowedRoles = ["SUPER_ADMIN", "COMPANY_ADMIN", "PROJECT_MANAGER", "DESIGNER", "ADMIN"];
const approveAllowedRoles = ["SUPER_ADMIN", "COMPANY_ADMIN", "PROJECT_MANAGER", "ADMIN"];

// Configure Multer for in-memory / temp upload handling
const storage = multer.memoryStorage();
const allowedExtensions = /pdf|png|jpg|jpeg|dwg|dxf/;

const upload = multer({
    storage,
    limits: { fileSize: 25 * 1024 * 1024 }, // 25 MB max limit per FC-010 §4
    fileFilter: (req, file, cb) => {
        if (!file || !file.originalname) {
            return cb(null, true);
        }
        const ext = path.extname(file.originalname).toLowerCase().replace(".", "");
        if (allowedExtensions.test(ext)) {
            return cb(null, true);
        }
        const err = new Error("UNSUPPORTED_FILE_TYPE: File extension not allowed. Allowed types: pdf, png, jpg, jpeg, dwg, dxf");
        err.code = "UNSUPPORTED_FILE_TYPE";
        cb(err);
    }
});

// Multer error handling wrapper middleware
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
            if (err.code === "UNSUPPORTED_FILE_TYPE" || (err.message && err.message.startsWith("UNSUPPORTED_FILE_TYPE"))) {
                return res.status(415).json({
                    success: false,
                    message: "Unsupported file type. Allowed extensions: pdf, png, jpg, jpeg, dwg, dxf",
                    data: null,
                    error: "UNSUPPORTED_FILE_TYPE"
                });
            }
            return res.status(400).json({
                success: false,
                message: err.message || "File upload validation failed",
                data: null,
                error: "VALIDATION_ERROR"
            });
        }
        next();
    });
};

// Design Routes
router.get("/", verifyToken, requireRole(viewAllowedRoles), designsController.getDesigns);
router.get("/:id", verifyToken, requireRole(viewAllowedRoles), designsController.getDesign);
router.post("/", verifyToken, requireRole(uploadAllowedRoles), handleUpload, designsController.createDesignRoute);
router.post("/:id/revise", verifyToken, requireRole(uploadAllowedRoles), handleUpload, designsController.createRevisionRoute);
router.post("/:id/approve", verifyToken, requireRole(approveAllowedRoles), designsController.approveDesignRoute);
router.get("/:id/download", verifyToken, requireRole(viewAllowedRoles), designsController.downloadDesign);
router.get("/:id/file", designsController.serveDesignFile);

module.exports = router;
