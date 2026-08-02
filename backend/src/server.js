require("dotenv").config();

const app = require("./app");
const prisma = require("./config/db");

const PORT = process.env.PORT || 5000;


async function startServer() {
    try {

        // Connect PostgreSQL database using Prisma
        await prisma.$connect();

        console.log("Database Connected Successfully");


        // Start Express server
        app.listen(PORT, () => {
            console.log(`Server running on port ${PORT}`);
        });


    } catch (error) {

        console.error("Database Connection Failed");
        console.error(error);

        process.exit(1);
    }
}


startServer();