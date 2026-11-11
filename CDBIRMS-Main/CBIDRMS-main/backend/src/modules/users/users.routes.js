const express = require("express");
const usersController = require("./users.controller");
const { verifyToken, requireRole } = require("../../middlewares/auth.middleware");

const router = express.Router();

// All routes require valid JWT and SUPER_ADMIN or COMPANY_ADMIN role
router.use(verifyToken);
router.use(requireRole(["SUPER_ADMIN", "COMPANY_ADMIN"]));

router.get("/", usersController.getUsers);
router.get("/:id", usersController.getUserById);
router.post("/", usersController.createUser);
router.put("/:id", usersController.updateUser);
router.patch("/:id/status", usersController.updateUserStatus);
router.delete("/:id", usersController.deleteUser);

module.exports = router;
