const prisma = require("./src/config/db");

async function main() {
    try {
        console.log("\n=== Registered Users in Database ===\n");
        const users = await prisma.user.findMany({
            select: {
                id: true,
                fullName: true,
                email: true,
                role: true,
                isActive: true,
                createdAt: true
            }
        });
        if (users.length === 0) {
            console.log("No users found in database yet.");
        } else {
            console.table(users);
        }
    } catch (error) {
        console.error("Error fetching users:", error.message);
    } finally {
        await prisma.$disconnect();
    }
}

main();
