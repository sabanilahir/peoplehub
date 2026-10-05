/*
  Warnings:

  - You are about to drop the column `waiverId` on the `AttendanceDaily` table. All the data in the column will be lost.
  - You are about to drop the column `maxWaiverPerMonth` on the `AttendanceRule` table. All the data in the column will be lost.
  - You are about to drop the `LateWaiverRequest` table. If the table is not empty, all the data it contains will be lost.

*/
-- DropForeignKey
ALTER TABLE "LateWaiverRequest" DROP CONSTRAINT "LateWaiverRequest_odooEmployeeId_fkey";

-- AlterTable
ALTER TABLE "AttendanceDaily" DROP COLUMN "waiverId";

-- AlterTable
ALTER TABLE "AttendanceRule" DROP COLUMN "maxWaiverPerMonth";

-- DropTable
DROP TABLE "LateWaiverRequest";
