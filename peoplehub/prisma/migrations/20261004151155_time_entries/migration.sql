-- AlterEnum
ALTER TYPE "ImportFileType" ADD VALUE 'TIME_ENTRY';

-- DropIndex
DROP INDEX "ImportBatch_fileHash_key";

-- CreateTable
CREATE TABLE "TimeEntry" (
    "id" TEXT NOT NULL,
    "odooEmployeeId" TEXT NOT NULL,
    "startAt" TIMESTAMPTZ NOT NULL,
    "endAt" TIMESTAMPTZ NOT NULL,
    "workDate" DATE NOT NULL,
    "shiftId" TEXT,
    "workSchedule" TEXT,
    "payrollPeriod" TEXT NOT NULL,
    "source" "DataSource" NOT NULL DEFAULT 'IMPORT',
    "importBatchId" TEXT,
    "createdAt" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ NOT NULL,

    CONSTRAINT "TimeEntry_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "TimeEntry_payrollPeriod_idx" ON "TimeEntry"("payrollPeriod");

-- CreateIndex
CREATE INDEX "TimeEntry_workDate_idx" ON "TimeEntry"("workDate");

-- CreateIndex
CREATE UNIQUE INDEX "TimeEntry_odooEmployeeId_startAt_key" ON "TimeEntry"("odooEmployeeId", "startAt");

-- AddForeignKey
ALTER TABLE "TimeEntry" ADD CONSTRAINT "TimeEntry_odooEmployeeId_fkey" FOREIGN KEY ("odooEmployeeId") REFERENCES "OdooEmployee"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "TimeEntry" ADD CONSTRAINT "TimeEntry_shiftId_fkey" FOREIGN KEY ("shiftId") REFERENCES "Shift"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "TimeEntry" ADD CONSTRAINT "TimeEntry_importBatchId_fkey" FOREIGN KEY ("importBatchId") REFERENCES "ImportBatch"("id") ON DELETE SET NULL ON UPDATE CASCADE;
