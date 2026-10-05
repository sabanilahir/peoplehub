/*
  Warnings:

  - You are about to drop the column `currentStep` on the `LateWaiverRequest` table. All the data in the column will be lost.
  - You are about to drop the column `currentStep` on the `LeaveRequest` table. All the data in the column will be lost.
  - You are about to drop the column `currentStep` on the `OvertimeRequest` table. All the data in the column will be lost.
  - You are about to drop the `ApprovalChain` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `ApprovalHistory` table. If the table is not empty, all the data it contains will be lost.

*/
-- DropForeignKey
ALTER TABLE "ApprovalChain" DROP CONSTRAINT "ApprovalChain_approverEmployeeId_fkey";

-- DropForeignKey
ALTER TABLE "ApprovalChain" DROP CONSTRAINT "ApprovalChain_roleId_fkey";

-- DropForeignKey
ALTER TABLE "ApprovalChain" DROP CONSTRAINT "ApprovalChain_workLocationId_fkey";

-- DropForeignKey
ALTER TABLE "ApprovalHistory" DROP CONSTRAINT "ApprovalHistory_actorId_fkey";

-- AlterTable
ALTER TABLE "LateWaiverRequest" DROP COLUMN "currentStep";

-- AlterTable
ALTER TABLE "LeaveRequest" DROP COLUMN "currentStep";

-- AlterTable
ALTER TABLE "OvertimeRequest" DROP COLUMN "currentStep";

-- DropTable
DROP TABLE "ApprovalChain";

-- DropTable
DROP TABLE "ApprovalHistory";

-- DropEnum
DROP TYPE "ApprovalAction";

-- DropEnum
DROP TYPE "ApproverType";

-- DropEnum
DROP TYPE "RequestType";
