const { PrismaClient } = require("@prisma/client");

// Prisma Database Client instance
const prisma = new PrismaClient();

module.exports = prisma;