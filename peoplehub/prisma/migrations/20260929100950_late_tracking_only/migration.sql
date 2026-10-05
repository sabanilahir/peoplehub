/*
  Warnings:

  - You are about to drop the column `lateDeduction` on the `AttendanceDaily` table. All the data in the column will be lost.
  - You are about to drop the column `calculationMode` on the `AttendanceRule` table. All the data in the column will be lost.
  - You are about to drop the column `overLimitBehavior` on the `AttendanceRule` table. All the data in the column will be lost.
  - You are about to drop the column `penaltyTiersJson` on the `AttendanceRule` table. All the data in the column will be lost.
  - You are about to drop the column `proRataDivisorType` on the `AttendanceRule` table. All the data in the column will be lost.
  - You are about to drop the column `proRataDivisorValue` on the `AttendanceRule` table. All the data in the column will be lost.
  - You are about to drop the column `proRataUnit` on the `AttendanceRule` table. All the data in the column will be lost.

*/
-- AlterTable
ALTER TABLE "AttendanceDaily" DROP COLUMN "lateDeduction";

-- AlterTable
ALTER TABLE "AttendanceRule" DROP COLUMN "calculationMode",
DROP COLUMN "overLimitBehavior",
DROP COLUMN "penaltyTiersJson",
DROP COLUMN "proRataDivisorType",
DROP COLUMN "proRataDivisorValue",
DROP COLUMN "proRataUnit";

-- DropEnum
DROP TYPE "CalculationMode";

-- DropEnum
DROP TYPE "OverLimitBehavior";

-- DropEnum
DROP TYPE "ProRataDivisorType";

-- DropEnum
DROP TYPE "ProRataUnit";
