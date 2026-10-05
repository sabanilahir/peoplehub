-- CreateEnum
CREATE TYPE "AccrualMode" AS ENUM ('NONE', 'ANNIVERSARY');

-- AlterTable
ALTER TABLE "OdooEmployee" ADD COLUMN     "hireDate" DATE;

-- CreateTable
CREATE TABLE "LeaveRule" (
    "id" TEXT NOT NULL,
    "leaveKind" "LeaveKind" NOT NULL,
    "effectiveFrom" DATE NOT NULL,
    "effectiveTo" DATE,
    "minTenureMonths" INTEGER NOT NULL DEFAULT 0,
    "accrualMode" "AccrualMode" NOT NULL DEFAULT 'NONE',
    "entitlementDays" DECIMAL(5,2),
    "firstGrantAnniversary" INTEGER NOT NULL DEFAULT 1,
    "expiryMonths" INTEGER,
    "updatedBy" TEXT,
    "createdAt" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ NOT NULL,

    CONSTRAINT "LeaveRule_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "LeaveRule_leaveKind_effectiveFrom_key" ON "LeaveRule"("leaveKind", "effectiveFrom");
