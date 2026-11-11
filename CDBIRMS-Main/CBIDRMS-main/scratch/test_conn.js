const prisma = require('../backend/src/config/db');

async function checkConnection() {
    console.log("--- Connection Diagnostic Check ---");
    try {
        await prisma.$connect();
        console.log("1. Database Connection: SUCCESS (Connected to SQLite via Prisma)");

        const users = await prisma.user.count();
        const leads = await prisma.lead.count();
        const projects = await prisma.project.count();
        const customers = await prisma.customer.count();
        const quotations = await prisma.quotation.count();

        console.log(`2. Database Tables & Records check:`);
        console.log(`   - Users: ${users}`);
        console.log(`   - Leads: ${leads}`);
        console.log(`   - Projects: ${projects}`);
        console.log(`   - Customers: ${customers}`);
        console.log(`   - Quotations: ${quotations}`);
    } catch (err) {
        console.error("1. Database Connection: FAILED", err.message);
    } finally {
        await prisma.$disconnect();
    }
}

checkConnection();
