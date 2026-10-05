-- CreateEnum
CREATE TYPE "LogLevel" AS ENUM ('INFO', 'WARN', 'ERROR');

-- AlterTable
ALTER TABLE "ImportBatch" ADD COLUMN     "progress" INTEGER NOT NULL DEFAULT 0,
ADD COLUMN     "startedAt" TIMESTAMPTZ;

-- AlterTable
ALTER TABLE "TimeEntry" ADD COLUMN     "durationHours" DECIMAL(6,2) NOT NULL DEFAULT 0;

-- CreateTable
CREATE TABLE "ProcessLog" (
    "id" TEXT NOT NULL,
    "batchId" TEXT NOT NULL,
    "level" "LogLevel" NOT NULL DEFAULT 'INFO',
    "message" TEXT NOT NULL,
    "createdAt" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ProcessLog_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "ProcessLog_batchId_createdAt_idx" ON "ProcessLog"("batchId", "createdAt");

-- AddForeignKey
ALTER TABLE "ProcessLog" ADD CONSTRAINT "ProcessLog_batchId_fkey" FOREIGN KEY ("batchId") REFERENCES "ImportBatch"("id") ON DELETE CASCADE ON UPDATE CASCADE;
