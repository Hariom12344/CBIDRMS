const express = require("express");
const router = express.Router();
const authController = require("./auth.controller");
const { verifyToken } = require("../../../middlewares/auth.middleware");

router.post("/register", authController.register);
router.post("/login", authController.login);
router.post("/logout", authController.logout);
router.post("/refresh-token", authController.refreshToken);
router.post("/forgot-password", authController.forgotPassword);
router.post("/reset-password", authController.resetPassword);
router.put("/reset-password", authController.resetPassword);

// Authenticated route
router.put("/change-password", verifyToken, authController.changePassword);

module.exports = router;