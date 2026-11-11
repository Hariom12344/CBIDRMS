const express = require("express");
const router = express.Router();
const controller = require("./purchase_orders.controller");
const { verifyToken } = require("../../middlewares/auth.middleware");

router.use(verifyToken);

router.get("/", controller.getPurchaseOrders);
router.get("/:id", controller.getPurchaseOrderById);
router.post("/", controller.createPurchaseOrder);
router.put("/:id", controller.updatePurchaseOrderItems);
router.patch("/:id/status", controller.updatePurchaseOrderStatus);
router.delete("/:id", controller.deletePurchaseOrder);

module.exports = router;
