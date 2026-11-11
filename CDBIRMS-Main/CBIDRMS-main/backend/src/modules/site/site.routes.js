const express = require("express");
const router = express.Router();
const path = require("path");
const fs = require("fs");
const multer = require("multer");
const siteController = require("./site.controller");
const { verifyToken } = require("../../middlewares/auth.middleware");

// Ensure upload directory exists
const uploadDir = path.join(__dirname, "../../../uploads/site-photos");
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
        const ext = path.extname(file.originalname) || ".jpg";
        cb(null, `site-${uniqueSuffix}${ext}`);
    }
});

const upload = multer({
    storage,
    limits: { fileSize: 10 * 1024 * 1024 }, // 10MB limit per file
    fileFilter: (req, file, cb) => {
        const allowedTypes = /jpeg|jpg|png|webp/;
        const extname = allowedTypes.test(path.extname(file.originalname).toLowerCase());
        const mimetype = allowedTypes.test(file.mimetype);
        if (extname && mimetype) {
            return cb(null, true);
        }
        cb(new Error("Only images (png, jpg, jpeg, webp) are allowed"));
    }
});

// Site Update Endpoints
router.get("/site-updates", verifyToken, siteController.getSiteUpdates);
router.post("/site-updates", verifyToken, upload.array("photos", 10), siteController.postSiteUpdate);

// Site Task Endpoints
router.get("/site-tasks", verifyToken, siteController.getSiteTasks);
router.post("/site-tasks", verifyToken, siteController.postSiteTask);
router.patch("/site-tasks/:id/status", verifyToken, siteController.updateTaskStatusRoute);

module.exports = router;
