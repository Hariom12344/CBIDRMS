require("dotenv").config();

const app = require("./app");
const prisma = require("./config/db");

const PORT = process.env.PORT || 5000;

async function startServer() {
    try {
        await prisma.$connect();
        console.log("Database Connected Successfully");

        const server = app.listen(PORT, "0.0.0.0", () => {
            console.log(`Server running on port ${PORT}`);
        });

        server.on("error", (err) => {
            console.error("Server Listener Error:", err);
        });
    } catch (error) {
        console.error("Database Connection Failed", error);
        process.exit(1);
    }
}

process.on("unhandledRejection", (reason) => {
    console.error("Unhandled Rejection:", reason);
});

startServer();