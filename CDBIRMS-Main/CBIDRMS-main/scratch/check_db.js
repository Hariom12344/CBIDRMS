const path = require("path");
const { PrismaClient } = require(path.join(__dirname, "../backend/node_modules/@prisma/client"));
const prisma = new PrismaClient();

async function check() {
    try {
        const users = await prisma.user.findMany({
            select: { id: true, email: true, role: true, fullName: true }
        });
        console.log("Existing Users:", users);
    } catch (e) {
        console.error("DB Check error:", e.message);
    } finally {
        await prisma.$disconnect();
    }
}

check();
