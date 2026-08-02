-- AlterTable
ALTER TABLE "User" ADD COLUMN     "refreshToken" TEXT,
ADD COLUMN     "resetToken" TEXT,
ADD COLUMN     "resetTokenExpiry" TIMESTAMP(3);
