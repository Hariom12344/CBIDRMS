const express = require("express");

const router = express.Router();

const authController = require("./auth.controller");


router.post("/register", authController.register);

router.post("/login", authController.login);

router.post("/logout", authController.logout);

router.post("/refresh-token", authController.refreshToken);

router.post("/forgot-password", authController.forgotPassword);

router.put("/reset-password", authController.resetPassword);


module.exports = router;