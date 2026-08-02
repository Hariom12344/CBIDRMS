const express = require("express");
const cors = require("cors");
const cookieParser = require("cookie-parser");

const authRoutes = require("./modules/auth/api/auth.routes");

const app = express();

app.use(cors());
app.use(express.json());
app.use(cookieParser());

app.get("/", (req, res) => {
    res.json({ status: "success", message: "IDPMS Backend API is running" });
});

app.get("/api", (req, res) => {
    res.json({ status: "success", message: "IDPMS API Health Check OK" });
});

app.use("/api/auth", authRoutes);

module.exports = app;