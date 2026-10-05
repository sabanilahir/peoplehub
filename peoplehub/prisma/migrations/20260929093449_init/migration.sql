-- CreateEnum
CREATE TYPE "LocationType" AS ENUM ('HO', 'BRANCH');

-- CreateEnum
CREATE TYPE "CalculationMode" AS ENUM ('FLAT', 'PRO_RATA');

-- CreateEnum
CREATE TYPE "OverLimitBehavior" AS ENUM ('USE_HIGHEST_TIER', 'HALF_DAY', 'ALPHA');

-- CreateEnum
CREATE TYPE "ProRataDivisorType" AS ENUM ('ACTUAL_WORKDAYS', 'FIXED_DAYS', 'FIXED_HOURS');

-- CreateEnum
CREATE TYPE "ProRataUnit" AS ENUM ('MINUTE', 'HOUR', 'DAY');

-- CreateEnum
CREATE TYPE "RequestType" AS ENUM ('LEAVE', 'LATE_WAIVER', 'OVERTIME');

-- CreateEnum
CREATE TYPE "RequestStatus" AS ENUM ('PENDING', 'APPROVED', 'REJECTED', 'CANCELLED');

-- CreateEnum
CREATE TYPE "ApproverType" AS ENUM ('ODOO_MANAGER', 'ROLE', 'SPECIFIC_EMPLOYEE');

-- CreateEnum
CREATE TYPE "ApprovalAction" AS ENUM ('APPROVED', 'REJECTED', 'ESCALATED', 'AUTO_ESCALATED', 'CANCELLED');

-- CreateEnum
CREATE TYPE "DataSource" AS ENUM ('PEOPLEHUB', 'IMPORT', 'MANUAL', 'DEFAULT');

-- CreateEnum
CREATE TYPE "ImportFileType" AS ENUM ('SCHEDULE', 'LEAVE', 'CALENDAR', 'OVERTIME_PLAN', 'OVERTIME_REALIZATION');

-- CreateEnum
CREATE TYPE "ImportStatus" AS ENUM ('RECEIVED', 'VALIDATING', 'APPLIED', 'PARTIAL', 'FAILED');

-- CreateEnum
CREATE TYPE "DayType" AS ENUM ('WORKDAY', 'OFFDAY');

-- CreateEnum
CREATE TYPE "CalendarEventType" AS ENUM ('PUBLIC_HOLIDAY', 'COLLECTIVE_LEAVE', 'BUSINESS_TRIP', 'TRAINING', 'COMPANY_EVENT');

-- CreateEnum
CREATE TYPE "EventScope" AS ENUM ('GLOBAL', 'LOCATION', 'EMPLOYEE');

-- CreateEnum
CREATE TYPE "PunchSource" AS ENUM ('FINGERPRINT', 'MANUAL', 'IMPORT');

-- CreateEnum
CREATE TYPE "PunchDirection" AS ENUM ('IN', 'OUT', 'UNKNOWN');

-- CreateEnum
CREATE TYPE "AttendanceStatus" AS ENUM ('PRESENT', 'LATE', 'ABSENT', 'ON_LEAVE', 'OFFDAY', 'HOLIDAY', 'INCOMPLETE');

-- CreateEnum
CREATE TYPE "WorkWeek" AS ENUM ('FIVE_DAY', 'SIX_DAY');

-- CreateEnum
CREATE TYPE "OvertimePayableBasis" AS ENUM ('PLAN_REALIZATION', 'PLAN_REALIZATION_PUNCH');

-- CreateEnum
CREATE TYPE "OtReconStatus" AS ENUM ('PENDING_PLAN', 'MATCHED', 'EXCEEDS_PLAN', 'NO_PLAN', 'PUNCH_MISMATCH', 'CANCELLED');

-- CreateEnum
CREATE TYPE "SimulationTarget" AS ENUM ('OVERTIME', 'ATTENDANCE');

-- CreateEnum
CREATE TYPE "SimulationStatus" AS ENUM ('QUEUED', 'RUNNING', 'DONE', 'FAILED');

-- CreateEnum
CREATE TYPE "OdooSyncStatus" AS ENUM ('PENDING', 'SYNCED', 'FAILED');

-- CreateEnum
CREATE TYPE "PayrollPeriodStatus" AS ENUM ('OPEN', 'FROZEN', 'PUSHED');

-- CreateEnum
CREATE TYPE "LeaveKind" AS ENUM ('ANNUAL', 'SICK', 'UNPAID', 'OTHER');

-- CreateTable
CREATE TABLE "WorkLocation" (
    "id" TEXT NOT NULL,
    "code" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "type" "LocationType" NOT NULL,
    "timezone" TEXT NOT NULL DEFAULT 'Asia/Jakarta',
    "latitude" DECIMAL(9,6),
    "longitude" DECIMAL(9,6),
    "geofenceRadiusMeters" INTEGER,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ NOT NULL,

    CONSTRAINT "WorkLocation_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "OdooEmployee" (
    "id" TEXT NOT NULL,
    "odooId" INTEGER NOT NULL,
    "nik" TEXT,
    "name" TEXT NOT NULL,
    "email" TEXT,
    "jobTitle" TEXT,
    "jobGrade" TEXT,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "parentOdooId" INTEGER,
    "workLocationId" TEXT NOT NULL,
    "lastSyncedAt" TIMESTAMPTZ,
    "createdAt" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ NOT NULL,

    CONSTRAINT "OdooEmployee_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "OdooContract" (
    "id" TEXT NOT NULL,
    "odooContractId" INTEGER NOT NULL,
    "odooEmployeeId" TEXT NOT NULL,
    "wage" DECIMAL(15,2) NOT NULL,
    "dateStart" DATE NOT NULL,
    "dateEnd" DATE,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "syncedAt" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "OdooContract_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "User" (
    "id" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "passwordHash" TEXT NOT NULL,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "lastLoginAt" TIMESTAMPTZ,
    "odooEmployeeId" TEXT,
    "createdAt" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ NOT NULL,

    CONSTRAINT "User_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Role" (
    "id" TEXT NOT NULL,
    "code" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT,
    "isSystem" BOOLEAN NOT NULL DEFAULT false,

    CONSTRAINT "Role_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Menu" (
    "id" TEXT NOT NULL,
    "code" TEXT NOT NULL,
    "label" TEXT NOT NULL,
    "path" TEXT,
    "icon" TEXT,
    "sortOrder" INTEGER NOT NULL DEFAULT 0,
    "parentId" TEXT,
    "requiredPermissionId" TEXT,
    "isActive" BOOLEAN NOT NULL DEFAULT true,

    CONSTRAINT "Menu_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Permission" (
    "id" TEXT NOT NULL,
    "code" TEXT NOT NULL,
    "module" TEXT NOT NULL,
    "description" TEXT,

    CONSTRAINT "Permission_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "UserRole" (
    "userId" TEXT NOT NULL,
    "roleId" TEXT NOT NULL,
    "assignedAt" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "UserRole_pkey" PRIMARY KEY ("userId","roleId")
);

-- CreateTable
CREATE TABLE "RolePermission" (
    "id" TEXT NOT NULL,
    "roleId" TEXT NOT NULL,
    "permissionId" TEXT NOT NULL,
    "menuId" TEXT,
    "canCreate" BOOLEAN NOT NULL DEFAULT false,
    "canRead" BOOLEAN NOT NULL DEFAULT true,
    "canUpdate" BOOLEAN NOT NULL DEFAULT false,
    "canDelete" BOOLEAN NOT NULL DEFAULT false,

    CONSTRAINT "RolePermission_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "UserPermissionOverride" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "permissionId" TEXT NOT NULL,
    "isAllowed" BOOLEAN NOT NULL,
    "reason" TEXT,
    "expiresAt" TIMESTAMPTZ,
    "createdBy" TEXT,
    "createdAt" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "UserPermissionOverride_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "AuditLog" (
    "id" TEXT NOT NULL,
    "actorId" TEXT,
    "action" TEXT NOT NULL,
    "entityType" TEXT NOT NULL,
    "entityId" TEXT NOT NULL,
    "beforeJson" JSONB,
    "afterJson" JSONB,
    "meta" JSONB,
    "createdAt" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "AuditLog_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "AttendanceRule" (
    "id" TEXT NOT NULL,
    "workLocationId" TEXT NOT NULL,
    "effectiveFrom" DATE NOT NULL,
    "effectiveTo" DATE,
    "gracePeriodMinutes" INTEGER NOT NULL DEFAULT 0,
    "calculationMode" "CalculationMode" NOT NULL DEFAULT 'FLAT',
    "penaltyTiersJson" JSONB NOT NULL DEFAULT '[]',
    "overLimitBehavior" "OverLimitBehavior" NOT NULL DEFAULT 'USE_HIGHEST_TIER',
    "maxWaiverPerMonth" INTEGER NOT NULL DEFAULT 0,
    "proRataDivisorType" "ProRataDivisorType",
    "proRataDivisorValue" DECIMAL(8,2),
    "proRataUnit" "ProRataUnit",
    "preShiftWindowMinutes" INTEGER NOT NULL DEFAULT 240,
    "postShiftWindowMinutes" INTEGER NOT NULL DEFAULT 360,
    "updatedBy" TEXT,
    "createdAt" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ NOT NULL,

    CONSTRAINT "AttendanceRule_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Shift" (
    "id" TEXT NOT NULL,
    "code" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "startTime" TEXT NOT NULL,
    "durationMinutes" INTEGER NOT NULL,
    "breakMinutes" INTEGER NOT NULL DEFAULT 60,
    "isActive" BOOLEAN NOT NULL DEFAULT true,

    CONSTRAINT "Shift_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "EmployeeSchedule" (
    "id" TEXT NOT NULL,
    "odooEmployeeId" TEXT NOT NULL,
    "workDate" DATE NOT NULL,
    "dayType" "DayType" NOT NULL,
    "shiftId" TEXT,
    "shiftStart" TIMESTAMPTZ,
    "shiftEnd" TIMESTAMPTZ,
    "source" "DataSource" NOT NULL,
    "importBatchId" TEXT,
    "updatedAt" TIMESTAMPTZ NOT NULL,

    CONSTRAINT "EmployeeSchedule_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "CalendarEvent" (
    "id" TEXT NOT NULL,
    "externalRef" TEXT,
    "eventType" "CalendarEventType" NOT NULL,
    "scope" "EventScope" NOT NULL,
    "workLocationId" TEXT,
    "odooEmployeeId" TEXT,
    "startDate" DATE NOT NULL,
    "endDate" DATE NOT NULL,
    "cancelsWorkday" BOOLEAN NOT NULL,
    "skipGeofence" BOOLEAN NOT NULL DEFAULT false,
    "name" TEXT NOT NULL,
    "importBatchId" TEXT,

    CONSTRAINT "CalendarEvent_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ImportBatch" (
    "id" TEXT NOT NULL,
    "fileType" "ImportFileType" NOT NULL,
    "fileName" TEXT NOT NULL,
    "fileHash" TEXT NOT NULL,
    "status" "ImportStatus" NOT NULL DEFAULT 'RECEIVED',
    "totalRows" INTEGER NOT NULL DEFAULT 0,
    "successRows" INTEGER NOT NULL DEFAULT 0,
    "errorRows" INTEGER NOT NULL DEFAULT 0,
    "uploadedBy" TEXT,
    "createdAt" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "finishedAt" TIMESTAMPTZ,

    CONSTRAINT "ImportBatch_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ImportRowError" (
    "id" TEXT NOT NULL,
    "batchId" TEXT NOT NULL,
    "rowNumber" INTEGER NOT NULL,
    "rawLine" TEXT NOT NULL,
    "message" TEXT NOT NULL,

    CONSTRAINT "ImportRowError_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Device" (
    "id" TEXT NOT NULL,
    "serialNumber" TEXT NOT NULL,
    "vendor" TEXT,
    "name" TEXT NOT NULL,
    "workLocationId" TEXT NOT NULL,
    "isActive" BOOLEAN NOT NULL DEFAULT true,

    CONSTRAINT "Device_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "EmployeeDeviceMap" (
    "id" TEXT NOT NULL,
    "deviceId" TEXT NOT NULL,
    "enrollId" TEXT NOT NULL,
    "odooEmployeeId" TEXT NOT NULL,

    CONSTRAINT "EmployeeDeviceMap_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "AttendanceRawPunch" (
    "id" TEXT NOT NULL,
    "odooEmployeeId" TEXT,
    "deviceId" TEXT,
    "enrollId" TEXT,
    "punchAt" TIMESTAMPTZ NOT NULL,
    "direction" "PunchDirection" NOT NULL DEFAULT 'UNKNOWN',
    "source" "PunchSource" NOT NULL DEFAULT 'FINGERPRINT',
    "fingerprint" TEXT NOT NULL,
    "payloadJson" JSONB,
    "receivedAt" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "AttendanceRawPunch_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "AttendanceLog" (
    "id" TEXT NOT NULL,
    "odooEmployeeId" TEXT NOT NULL,
    "rawPunchId" TEXT NOT NULL,
    "workDate" DATE NOT NULL,
    "direction" "PunchDirection" NOT NULL,
    "punchAt" TIMESTAMPTZ NOT NULL,
    "isValid" BOOLEAN NOT NULL DEFAULT true,
    "invalidReason" TEXT,
    "assignedAt" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "AttendanceLog_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "AttendanceDaily" (
    "id" TEXT NOT NULL,
    "odooEmployeeId" TEXT NOT NULL,
    "workDate" DATE NOT NULL,
    "status" "AttendanceStatus" NOT NULL,
    "clockIn" TIMESTAMPTZ,
    "clockOut" TIMESTAMPTZ,
    "isLate" BOOLEAN NOT NULL DEFAULT false,
    "lateMinutes" INTEGER NOT NULL DEFAULT 0,
    "lateDeduction" DECIMAL(15,2) NOT NULL DEFAULT 0,
    "waiverId" TEXT,
    "overtimeDetectedMinutes" INTEGER NOT NULL DEFAULT 0,
    "overtimeApprovedMinutes" INTEGER NOT NULL DEFAULT 0,
    "overtimePayableMinutes" INTEGER NOT NULL DEFAULT 0,
    "appliedRuleId" TEXT,
    "computedAt" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "AttendanceDaily_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ApprovalChain" (
    "id" TEXT NOT NULL,
    "workLocationId" TEXT NOT NULL,
    "requestType" "RequestType" NOT NULL,
    "stepOrder" INTEGER NOT NULL,
    "approverType" "ApproverType" NOT NULL,
    "roleId" TEXT,
    "approverEmployeeId" TEXT,
    "autoEscalateDays" INTEGER,
    "isActive" BOOLEAN NOT NULL DEFAULT true,

    CONSTRAINT "ApprovalChain_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ApprovalHistory" (
    "id" TEXT NOT NULL,
    "requestType" "RequestType" NOT NULL,
    "requestId" TEXT NOT NULL,
    "stepOrder" INTEGER NOT NULL,
    "action" "ApprovalAction" NOT NULL,
    "actorId" TEXT,
    "note" TEXT,
    "escalatedFromId" TEXT,
    "createdAt" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ApprovalHistory_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "LeaveRequest" (
    "id" TEXT NOT NULL,
    "externalRef" TEXT,
    "odooEmployeeId" TEXT NOT NULL,
    "kind" "LeaveKind" NOT NULL DEFAULT 'ANNUAL',
    "odooLeaveTypeId" INTEGER,
    "startDate" DATE NOT NULL,
    "endDate" DATE NOT NULL,
    "days" DECIMAL(5,2) NOT NULL,
    "reason" TEXT,
    "source" "DataSource" NOT NULL DEFAULT 'PEOPLEHUB',
    "overallStatus" "RequestStatus" NOT NULL DEFAULT 'PENDING',
    "currentStep" INTEGER NOT NULL DEFAULT 1,
    "importBatchId" TEXT,
    "createdAt" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ NOT NULL,

    CONSTRAINT "LeaveRequest_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "LateWaiverRequest" (
    "id" TEXT NOT NULL,
    "odooEmployeeId" TEXT NOT NULL,
    "workDate" DATE NOT NULL,
    "reason" TEXT NOT NULL,
    "overallStatus" "RequestStatus" NOT NULL DEFAULT 'PENDING',
    "currentStep" INTEGER NOT NULL DEFAULT 1,
    "createdAt" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ NOT NULL,

    CONSTRAINT "LateWaiverRequest_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "OvertimeRequest" (
    "id" TEXT NOT NULL,
    "externalRef" TEXT,
    "odooEmployeeId" TEXT NOT NULL,
    "workDate" DATE NOT NULL,
    "plannedStart" TIMESTAMPTZ NOT NULL,
    "plannedEnd" TIMESTAMPTZ NOT NULL,
    "reason" TEXT NOT NULL,
    "source" "DataSource" NOT NULL DEFAULT 'PEOPLEHUB',
    "overallStatus" "RequestStatus" NOT NULL DEFAULT 'PENDING',
    "currentStep" INTEGER NOT NULL DEFAULT 1,
    "createdAt" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "OvertimeRequest_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "OvertimeRealization" (
    "id" TEXT NOT NULL,
    "externalRef" TEXT NOT NULL,
    "odooEmployeeId" TEXT NOT NULL,
    "workDate" DATE NOT NULL,
    "actualStart" TIMESTAMPTZ NOT NULL,
    "actualEnd" TIMESTAMPTZ NOT NULL,
    "planExternalRef" TEXT,
    "overtimeRequestId" TEXT,
    "reconciliationStatus" "OtReconStatus" NOT NULL DEFAULT 'PENDING_PLAN',
    "payableMinutes" INTEGER,
    "appliedBasis" "OvertimePayableBasis",
    "appliedRuleId" TEXT,
    "importBatchId" TEXT NOT NULL,

    CONSTRAINT "OvertimeRealization_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "OvertimeRule" (
    "id" TEXT NOT NULL,
    "workLocationId" TEXT NOT NULL,
    "effectiveFrom" DATE NOT NULL,
    "effectiveTo" DATE,
    "workWeekPattern" "WorkWeek" NOT NULL,
    "payableBasis" "OvertimePayableBasis" NOT NULL DEFAULT 'PLAN_REALIZATION',
    "punchToleranceMinutes" INTEGER NOT NULL DEFAULT 15,
    "minMinutes" INTEGER NOT NULL DEFAULT 30,
    "roundingMinutes" INTEGER NOT NULL DEFAULT 30,
    "maxMinutesPerDay" INTEGER NOT NULL DEFAULT 240,
    "maxMinutesPerWeek" INTEGER NOT NULL DEFAULT 1080,
    "multiplierTiersJson" JSONB NOT NULL,
    "excludedJobGrades" TEXT[],
    "updatedBy" TEXT,
    "updatedAt" TIMESTAMPTZ NOT NULL,

    CONSTRAINT "OvertimeRule_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "RuleSimulation" (
    "id" TEXT NOT NULL,
    "ruleType" "SimulationTarget" NOT NULL,
    "workLocationId" TEXT NOT NULL,
    "periodStart" DATE NOT NULL,
    "periodEnd" DATE NOT NULL,
    "baselineRuleId" TEXT NOT NULL,
    "draftRuleJson" JSONB NOT NULL,
    "status" "SimulationStatus" NOT NULL DEFAULT 'QUEUED',
    "progressPct" INTEGER NOT NULL DEFAULT 0,
    "summaryJson" JSONB,
    "errorMessage" TEXT,
    "requestedBy" TEXT NOT NULL,
    "createdAt" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "expiresAt" TIMESTAMPTZ NOT NULL,

    CONSTRAINT "RuleSimulation_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "RuleSimulationDetail" (
    "id" TEXT NOT NULL,
    "simulationId" TEXT NOT NULL,
    "odooEmployeeId" TEXT NOT NULL,
    "baselineMinutes" INTEGER NOT NULL,
    "draftMinutes" INTEGER NOT NULL,
    "baselineAmount" DECIMAL(15,2),
    "draftAmount" DECIMAL(15,2),
    "affectedDays" JSONB NOT NULL,

    CONSTRAINT "RuleSimulationDetail_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "PayrollPeriod" (
    "id" TEXT NOT NULL,
    "code" TEXT NOT NULL,
    "startDate" DATE NOT NULL,
    "endDate" DATE NOT NULL,
    "status" "PayrollPeriodStatus" NOT NULL DEFAULT 'OPEN',
    "frozenAt" TIMESTAMPTZ,
    "frozenBy" TEXT,

    CONSTRAINT "PayrollPeriod_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "PrePayrollResult" (
    "id" TEXT NOT NULL,
    "odooEmployeeId" TEXT NOT NULL,
    "periodId" TEXT NOT NULL,
    "totalLateDeduction" DECIMAL(15,2) NOT NULL DEFAULT 0,
    "totalUnpaidDeduction" DECIMAL(15,2) NOT NULL DEFAULT 0,
    "netDeductionAmount" DECIMAL(15,2) NOT NULL DEFAULT 0,
    "totalOvertimeMinutes" INTEGER NOT NULL DEFAULT 0,
    "totalOvertimePay" DECIMAL(15,2),
    "overtimeBreakdownJson" JSONB,
    "isFrozen" BOOLEAN NOT NULL DEFAULT false,
    "frozenAt" TIMESTAMPTZ,
    "odooSyncStatus" "OdooSyncStatus" NOT NULL DEFAULT 'PENDING',
    "odooSyncError" TEXT,
    "odooPayslipInputIds" JSONB,
    "odooSyncedAt" TIMESTAMPTZ,
    "createdAt" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ NOT NULL,

    CONSTRAINT "PrePayrollResult_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "PendingAdjustment" (
    "id" TEXT NOT NULL,
    "odooEmployeeId" TEXT NOT NULL,
    "sourcePeriodId" TEXT NOT NULL,
    "workDate" DATE NOT NULL,
    "reason" TEXT NOT NULL,
    "deltaLateDeduction" DECIMAL(15,2) NOT NULL DEFAULT 0,
    "deltaOvertimeMinutes" INTEGER NOT NULL DEFAULT 0,
    "appliedPeriodId" TEXT,
    "createdAt" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "PendingAdjustment_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "WorkLocation_code_key" ON "WorkLocation"("code");

-- CreateIndex
CREATE UNIQUE INDEX "OdooEmployee_odooId_key" ON "OdooEmployee"("odooId");

-- CreateIndex
CREATE UNIQUE INDEX "OdooEmployee_nik_key" ON "OdooEmployee"("nik");

-- CreateIndex
CREATE INDEX "OdooEmployee_workLocationId_idx" ON "OdooEmployee"("workLocationId");

-- CreateIndex
CREATE UNIQUE INDEX "OdooContract_odooContractId_key" ON "OdooContract"("odooContractId");

-- CreateIndex
CREATE INDEX "OdooContract_odooEmployeeId_dateStart_idx" ON "OdooContract"("odooEmployeeId", "dateStart");

-- CreateIndex
CREATE UNIQUE INDEX "User_email_key" ON "User"("email");

-- CreateIndex
CREATE UNIQUE INDEX "User_odooEmployeeId_key" ON "User"("odooEmployeeId");

-- CreateIndex
CREATE UNIQUE INDEX "Role_code_key" ON "Role"("code");

-- CreateIndex
CREATE UNIQUE INDEX "Menu_code_key" ON "Menu"("code");

-- CreateIndex
CREATE UNIQUE INDEX "Permission_code_key" ON "Permission"("code");

-- CreateIndex
CREATE INDEX "Permission_module_idx" ON "Permission"("module");

-- CreateIndex
CREATE INDEX "RolePermission_permissionId_idx" ON "RolePermission"("permissionId");

-- CreateIndex
CREATE UNIQUE INDEX "RolePermission_roleId_permissionId_menuId_key" ON "RolePermission"("roleId", "permissionId", "menuId");

-- CreateIndex
CREATE UNIQUE INDEX "UserPermissionOverride_userId_permissionId_key" ON "UserPermissionOverride"("userId", "permissionId");

-- CreateIndex
CREATE INDEX "AuditLog_entityType_entityId_idx" ON "AuditLog"("entityType", "entityId");

-- CreateIndex
CREATE INDEX "AuditLog_createdAt_idx" ON "AuditLog"("createdAt");

-- CreateIndex
CREATE INDEX "AttendanceRule_workLocationId_effectiveFrom_effectiveTo_idx" ON "AttendanceRule"("workLocationId", "effectiveFrom", "effectiveTo");

-- CreateIndex
CREATE UNIQUE INDEX "AttendanceRule_workLocationId_effectiveFrom_key" ON "AttendanceRule"("workLocationId", "effectiveFrom");

-- CreateIndex
CREATE UNIQUE INDEX "Shift_code_key" ON "Shift"("code");

-- CreateIndex
CREATE INDEX "EmployeeSchedule_workDate_idx" ON "EmployeeSchedule"("workDate");

-- CreateIndex
CREATE UNIQUE INDEX "EmployeeSchedule_odooEmployeeId_workDate_key" ON "EmployeeSchedule"("odooEmployeeId", "workDate");

-- CreateIndex
CREATE UNIQUE INDEX "CalendarEvent_externalRef_key" ON "CalendarEvent"("externalRef");

-- CreateIndex
CREATE INDEX "CalendarEvent_startDate_endDate_idx" ON "CalendarEvent"("startDate", "endDate");

-- CreateIndex
CREATE UNIQUE INDEX "ImportBatch_fileHash_key" ON "ImportBatch"("fileHash");

-- CreateIndex
CREATE INDEX "ImportRowError_batchId_idx" ON "ImportRowError"("batchId");

-- CreateIndex
CREATE UNIQUE INDEX "Device_serialNumber_key" ON "Device"("serialNumber");

-- CreateIndex
CREATE UNIQUE INDEX "EmployeeDeviceMap_deviceId_enrollId_key" ON "EmployeeDeviceMap"("deviceId", "enrollId");

-- CreateIndex
CREATE UNIQUE INDEX "AttendanceRawPunch_fingerprint_key" ON "AttendanceRawPunch"("fingerprint");

-- CreateIndex
CREATE INDEX "AttendanceRawPunch_odooEmployeeId_punchAt_idx" ON "AttendanceRawPunch"("odooEmployeeId", "punchAt");

-- CreateIndex
CREATE UNIQUE INDEX "AttendanceLog_rawPunchId_key" ON "AttendanceLog"("rawPunchId");

-- CreateIndex
CREATE INDEX "AttendanceLog_odooEmployeeId_workDate_idx" ON "AttendanceLog"("odooEmployeeId", "workDate");

-- CreateIndex
CREATE INDEX "AttendanceDaily_workDate_idx" ON "AttendanceDaily"("workDate");

-- CreateIndex
CREATE UNIQUE INDEX "AttendanceDaily_odooEmployeeId_workDate_key" ON "AttendanceDaily"("odooEmployeeId", "workDate");

-- CreateIndex
CREATE UNIQUE INDEX "ApprovalChain_workLocationId_requestType_stepOrder_key" ON "ApprovalChain"("workLocationId", "requestType", "stepOrder");

-- CreateIndex
CREATE INDEX "ApprovalHistory_requestType_requestId_idx" ON "ApprovalHistory"("requestType", "requestId");

-- CreateIndex
CREATE UNIQUE INDEX "LeaveRequest_externalRef_key" ON "LeaveRequest"("externalRef");

-- CreateIndex
CREATE INDEX "LeaveRequest_odooEmployeeId_startDate_endDate_idx" ON "LeaveRequest"("odooEmployeeId", "startDate", "endDate");

-- CreateIndex
CREATE INDEX "LeaveRequest_overallStatus_idx" ON "LeaveRequest"("overallStatus");

-- CreateIndex
CREATE UNIQUE INDEX "LateWaiverRequest_odooEmployeeId_workDate_key" ON "LateWaiverRequest"("odooEmployeeId", "workDate");

-- CreateIndex
CREATE UNIQUE INDEX "OvertimeRequest_externalRef_key" ON "OvertimeRequest"("externalRef");

-- CreateIndex
CREATE INDEX "OvertimeRequest_odooEmployeeId_workDate_idx" ON "OvertimeRequest"("odooEmployeeId", "workDate");

-- CreateIndex
CREATE UNIQUE INDEX "OvertimeRealization_externalRef_key" ON "OvertimeRealization"("externalRef");

-- CreateIndex
CREATE INDEX "OvertimeRealization_odooEmployeeId_workDate_idx" ON "OvertimeRealization"("odooEmployeeId", "workDate");

-- CreateIndex
CREATE INDEX "OvertimeRealization_reconciliationStatus_idx" ON "OvertimeRealization"("reconciliationStatus");

-- CreateIndex
CREATE UNIQUE INDEX "OvertimeRule_workLocationId_effectiveFrom_key" ON "OvertimeRule"("workLocationId", "effectiveFrom");

-- CreateIndex
CREATE INDEX "RuleSimulation_expiresAt_idx" ON "RuleSimulation"("expiresAt");

-- CreateIndex
CREATE INDEX "RuleSimulationDetail_simulationId_idx" ON "RuleSimulationDetail"("simulationId");

-- CreateIndex
CREATE UNIQUE INDEX "PayrollPeriod_code_key" ON "PayrollPeriod"("code");

-- CreateIndex
CREATE INDEX "PrePayrollResult_periodId_isFrozen_idx" ON "PrePayrollResult"("periodId", "isFrozen");

-- CreateIndex
CREATE UNIQUE INDEX "PrePayrollResult_odooEmployeeId_periodId_key" ON "PrePayrollResult"("odooEmployeeId", "periodId");

-- CreateIndex
CREATE INDEX "PendingAdjustment_appliedPeriodId_idx" ON "PendingAdjustment"("appliedPeriodId");

-- AddForeignKey
ALTER TABLE "OdooEmployee" ADD CONSTRAINT "OdooEmployee_parentOdooId_fkey" FOREIGN KEY ("parentOdooId") REFERENCES "OdooEmployee"("odooId") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "OdooEmployee" ADD CONSTRAINT "OdooEmployee_workLocationId_fkey" FOREIGN KEY ("workLocationId") REFERENCES "WorkLocation"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "OdooContract" ADD CONSTRAINT "OdooContract_odooEmployeeId_fkey" FOREIGN KEY ("odooEmployeeId") REFERENCES "OdooEmployee"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "User" ADD CONSTRAINT "User_odooEmployeeId_fkey" FOREIGN KEY ("odooEmployeeId") REFERENCES "OdooEmployee"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Menu" ADD CONSTRAINT "Menu_parentId_fkey" FOREIGN KEY ("parentId") REFERENCES "Menu"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Menu" ADD CONSTRAINT "Menu_requiredPermissionId_fkey" FOREIGN KEY ("requiredPermissionId") REFERENCES "Permission"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "UserRole" ADD CONSTRAINT "UserRole_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "UserRole" ADD CONSTRAINT "UserRole_roleId_fkey" FOREIGN KEY ("roleId") REFERENCES "Role"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "RolePermission" ADD CONSTRAINT "RolePermission_roleId_fkey" FOREIGN KEY ("roleId") REFERENCES "Role"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "RolePermission" ADD CONSTRAINT "RolePermission_permissionId_fkey" FOREIGN KEY ("permissionId") REFERENCES "Permission"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "RolePermission" ADD CONSTRAINT "RolePermission_menuId_fkey" FOREIGN KEY ("menuId") REFERENCES "Menu"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "UserPermissionOverride" ADD CONSTRAINT "UserPermissionOverride_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "UserPermissionOverride" ADD CONSTRAINT "UserPermissionOverride_permissionId_fkey" FOREIGN KEY ("permissionId") REFERENCES "Permission"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AuditLog" ADD CONSTRAINT "AuditLog_actorId_fkey" FOREIGN KEY ("actorId") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AttendanceRule" ADD CONSTRAINT "AttendanceRule_workLocationId_fkey" FOREIGN KEY ("workLocationId") REFERENCES "WorkLocation"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "EmployeeSchedule" ADD CONSTRAINT "EmployeeSchedule_odooEmployeeId_fkey" FOREIGN KEY ("odooEmployeeId") REFERENCES "OdooEmployee"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "EmployeeSchedule" ADD CONSTRAINT "EmployeeSchedule_shiftId_fkey" FOREIGN KEY ("shiftId") REFERENCES "Shift"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "EmployeeSchedule" ADD CONSTRAINT "EmployeeSchedule_importBatchId_fkey" FOREIGN KEY ("importBatchId") REFERENCES "ImportBatch"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "CalendarEvent" ADD CONSTRAINT "CalendarEvent_workLocationId_fkey" FOREIGN KEY ("workLocationId") REFERENCES "WorkLocation"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "CalendarEvent" ADD CONSTRAINT "CalendarEvent_importBatchId_fkey" FOREIGN KEY ("importBatchId") REFERENCES "ImportBatch"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ImportRowError" ADD CONSTRAINT "ImportRowError_batchId_fkey" FOREIGN KEY ("batchId") REFERENCES "ImportBatch"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Device" ADD CONSTRAINT "Device_workLocationId_fkey" FOREIGN KEY ("workLocationId") REFERENCES "WorkLocation"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "EmployeeDeviceMap" ADD CONSTRAINT "EmployeeDeviceMap_deviceId_fkey" FOREIGN KEY ("deviceId") REFERENCES "Device"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "EmployeeDeviceMap" ADD CONSTRAINT "EmployeeDeviceMap_odooEmployeeId_fkey" FOREIGN KEY ("odooEmployeeId") REFERENCES "OdooEmployee"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AttendanceRawPunch" ADD CONSTRAINT "AttendanceRawPunch_odooEmployeeId_fkey" FOREIGN KEY ("odooEmployeeId") REFERENCES "OdooEmployee"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AttendanceRawPunch" ADD CONSTRAINT "AttendanceRawPunch_deviceId_fkey" FOREIGN KEY ("deviceId") REFERENCES "Device"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AttendanceLog" ADD CONSTRAINT "AttendanceLog_odooEmployeeId_fkey" FOREIGN KEY ("odooEmployeeId") REFERENCES "OdooEmployee"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AttendanceLog" ADD CONSTRAINT "AttendanceLog_rawPunchId_fkey" FOREIGN KEY ("rawPunchId") REFERENCES "AttendanceRawPunch"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AttendanceDaily" ADD CONSTRAINT "AttendanceDaily_odooEmployeeId_fkey" FOREIGN KEY ("odooEmployeeId") REFERENCES "OdooEmployee"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ApprovalChain" ADD CONSTRAINT "ApprovalChain_workLocationId_fkey" FOREIGN KEY ("workLocationId") REFERENCES "WorkLocation"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ApprovalChain" ADD CONSTRAINT "ApprovalChain_roleId_fkey" FOREIGN KEY ("roleId") REFERENCES "Role"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ApprovalChain" ADD CONSTRAINT "ApprovalChain_approverEmployeeId_fkey" FOREIGN KEY ("approverEmployeeId") REFERENCES "OdooEmployee"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ApprovalHistory" ADD CONSTRAINT "ApprovalHistory_actorId_fkey" FOREIGN KEY ("actorId") REFERENCES "OdooEmployee"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "LeaveRequest" ADD CONSTRAINT "LeaveRequest_odooEmployeeId_fkey" FOREIGN KEY ("odooEmployeeId") REFERENCES "OdooEmployee"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "LeaveRequest" ADD CONSTRAINT "LeaveRequest_importBatchId_fkey" FOREIGN KEY ("importBatchId") REFERENCES "ImportBatch"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "LateWaiverRequest" ADD CONSTRAINT "LateWaiverRequest_odooEmployeeId_fkey" FOREIGN KEY ("odooEmployeeId") REFERENCES "OdooEmployee"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "OvertimeRequest" ADD CONSTRAINT "OvertimeRequest_odooEmployeeId_fkey" FOREIGN KEY ("odooEmployeeId") REFERENCES "OdooEmployee"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "OvertimeRealization" ADD CONSTRAINT "OvertimeRealization_odooEmployeeId_fkey" FOREIGN KEY ("odooEmployeeId") REFERENCES "OdooEmployee"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "OvertimeRealization" ADD CONSTRAINT "OvertimeRealization_overtimeRequestId_fkey" FOREIGN KEY ("overtimeRequestId") REFERENCES "OvertimeRequest"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "OvertimeRealization" ADD CONSTRAINT "OvertimeRealization_importBatchId_fkey" FOREIGN KEY ("importBatchId") REFERENCES "ImportBatch"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "OvertimeRule" ADD CONSTRAINT "OvertimeRule_workLocationId_fkey" FOREIGN KEY ("workLocationId") REFERENCES "WorkLocation"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "RuleSimulationDetail" ADD CONSTRAINT "RuleSimulationDetail_simulationId_fkey" FOREIGN KEY ("simulationId") REFERENCES "RuleSimulation"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PrePayrollResult" ADD CONSTRAINT "PrePayrollResult_odooEmployeeId_fkey" FOREIGN KEY ("odooEmployeeId") REFERENCES "OdooEmployee"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PrePayrollResult" ADD CONSTRAINT "PrePayrollResult_periodId_fkey" FOREIGN KEY ("periodId") REFERENCES "PayrollPeriod"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PendingAdjustment" ADD CONSTRAINT "PendingAdjustment_odooEmployeeId_fkey" FOREIGN KEY ("odooEmployeeId") REFERENCES "OdooEmployee"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PendingAdjustment" ADD CONSTRAINT "PendingAdjustment_sourcePeriodId_fkey" FOREIGN KEY ("sourcePeriodId") REFERENCES "PayrollPeriod"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
