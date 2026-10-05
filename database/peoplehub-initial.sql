--
-- PostgreSQL database dump
--

-- Dumped from database version 16.2
-- Dumped by pg_dump version 16.2

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: AccrualMode; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public."AccrualMode" AS ENUM (
    'NONE',
    'ANNIVERSARY'
);


--
-- Name: AttendanceStatus; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public."AttendanceStatus" AS ENUM (
    'PRESENT',
    'LATE',
    'ABSENT',
    'ON_LEAVE',
    'OFFDAY',
    'HOLIDAY',
    'INCOMPLETE'
);


--
-- Name: CalendarEventType; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public."CalendarEventType" AS ENUM (
    'PUBLIC_HOLIDAY',
    'COLLECTIVE_LEAVE',
    'BUSINESS_TRIP',
    'TRAINING',
    'COMPANY_EVENT'
);


--
-- Name: DataSource; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public."DataSource" AS ENUM (
    'PEOPLEHUB',
    'IMPORT',
    'MANUAL',
    'DEFAULT'
);


--
-- Name: DayType; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public."DayType" AS ENUM (
    'WORKDAY',
    'OFFDAY'
);


--
-- Name: EventScope; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public."EventScope" AS ENUM (
    'GLOBAL',
    'LOCATION',
    'EMPLOYEE'
);


--
-- Name: ImportFileType; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public."ImportFileType" AS ENUM (
    'SCHEDULE',
    'LEAVE',
    'CALENDAR',
    'OVERTIME_PLAN',
    'OVERTIME_REALIZATION',
    'TIME_ENTRY'
);


--
-- Name: ImportStatus; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public."ImportStatus" AS ENUM (
    'RECEIVED',
    'VALIDATING',
    'APPLIED',
    'PARTIAL',
    'FAILED'
);


--
-- Name: LeaveKind; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public."LeaveKind" AS ENUM (
    'ANNUAL',
    'SICK',
    'UNPAID',
    'OTHER'
);


--
-- Name: LocationType; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public."LocationType" AS ENUM (
    'HO',
    'BRANCH'
);


--
-- Name: LogLevel; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public."LogLevel" AS ENUM (
    'INFO',
    'WARN',
    'ERROR'
);


--
-- Name: OdooSyncStatus; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public."OdooSyncStatus" AS ENUM (
    'PENDING',
    'SYNCED',
    'FAILED'
);


--
-- Name: OtReconStatus; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public."OtReconStatus" AS ENUM (
    'PENDING_PLAN',
    'MATCHED',
    'EXCEEDS_PLAN',
    'NO_PLAN',
    'PUNCH_MISMATCH',
    'CANCELLED'
);


--
-- Name: OvertimePayableBasis; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public."OvertimePayableBasis" AS ENUM (
    'PLAN_REALIZATION',
    'PLAN_REALIZATION_PUNCH'
);


--
-- Name: PayrollPeriodStatus; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public."PayrollPeriodStatus" AS ENUM (
    'OPEN',
    'FROZEN',
    'PUSHED'
);


--
-- Name: PunchDirection; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public."PunchDirection" AS ENUM (
    'IN',
    'OUT',
    'UNKNOWN'
);


--
-- Name: PunchSource; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public."PunchSource" AS ENUM (
    'FINGERPRINT',
    'MANUAL',
    'IMPORT'
);


--
-- Name: RequestStatus; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public."RequestStatus" AS ENUM (
    'PENDING',
    'APPROVED',
    'REJECTED',
    'CANCELLED'
);


--
-- Name: SimulationStatus; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public."SimulationStatus" AS ENUM (
    'QUEUED',
    'RUNNING',
    'DONE',
    'FAILED'
);


--
-- Name: SimulationTarget; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public."SimulationTarget" AS ENUM (
    'OVERTIME',
    'ATTENDANCE'
);


--
-- Name: WorkWeek; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public."WorkWeek" AS ENUM (
    'FIVE_DAY',
    'SIX_DAY'
);


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: AttendanceDaily; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."AttendanceDaily" (
    id text NOT NULL,
    "odooEmployeeId" text NOT NULL,
    "workDate" date NOT NULL,
    status public."AttendanceStatus" NOT NULL,
    "clockIn" timestamp with time zone,
    "clockOut" timestamp with time zone,
    "isLate" boolean DEFAULT false NOT NULL,
    "lateMinutes" integer DEFAULT 0 NOT NULL,
    "overtimeDetectedMinutes" integer DEFAULT 0 NOT NULL,
    "overtimeApprovedMinutes" integer DEFAULT 0 NOT NULL,
    "overtimePayableMinutes" integer DEFAULT 0 NOT NULL,
    "appliedRuleId" text,
    "computedAt" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: AttendanceLog; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."AttendanceLog" (
    id text NOT NULL,
    "odooEmployeeId" text NOT NULL,
    "rawPunchId" text NOT NULL,
    "workDate" date NOT NULL,
    direction public."PunchDirection" NOT NULL,
    "punchAt" timestamp with time zone NOT NULL,
    "isValid" boolean DEFAULT true NOT NULL,
    "invalidReason" text,
    "assignedAt" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: AttendanceRawPunch; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."AttendanceRawPunch" (
    id text NOT NULL,
    "odooEmployeeId" text,
    "deviceId" text,
    "enrollId" text,
    "punchAt" timestamp with time zone NOT NULL,
    direction public."PunchDirection" DEFAULT 'UNKNOWN'::public."PunchDirection" NOT NULL,
    source public."PunchSource" DEFAULT 'FINGERPRINT'::public."PunchSource" NOT NULL,
    fingerprint text NOT NULL,
    "payloadJson" jsonb,
    "receivedAt" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: AttendanceRule; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."AttendanceRule" (
    id text NOT NULL,
    "workLocationId" text NOT NULL,
    "effectiveFrom" date NOT NULL,
    "effectiveTo" date,
    "gracePeriodMinutes" integer DEFAULT 0 NOT NULL,
    "preShiftWindowMinutes" integer DEFAULT 240 NOT NULL,
    "postShiftWindowMinutes" integer DEFAULT 360 NOT NULL,
    "updatedBy" text,
    "createdAt" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL
);


--
-- Name: AuditLog; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."AuditLog" (
    id text NOT NULL,
    "actorId" text,
    action text NOT NULL,
    "entityType" text NOT NULL,
    "entityId" text NOT NULL,
    "beforeJson" jsonb,
    "afterJson" jsonb,
    meta jsonb,
    "createdAt" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: CalendarEvent; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."CalendarEvent" (
    id text NOT NULL,
    "externalRef" text,
    "eventType" public."CalendarEventType" NOT NULL,
    scope public."EventScope" NOT NULL,
    "workLocationId" text,
    "odooEmployeeId" text,
    "startDate" date NOT NULL,
    "endDate" date NOT NULL,
    "cancelsWorkday" boolean NOT NULL,
    "skipGeofence" boolean DEFAULT false NOT NULL,
    name text NOT NULL,
    "importBatchId" text
);


--
-- Name: Device; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."Device" (
    id text NOT NULL,
    "serialNumber" text NOT NULL,
    vendor text,
    name text NOT NULL,
    "workLocationId" text NOT NULL,
    "isActive" boolean DEFAULT true NOT NULL
);


--
-- Name: EmployeeDeviceMap; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."EmployeeDeviceMap" (
    id text NOT NULL,
    "deviceId" text NOT NULL,
    "enrollId" text NOT NULL,
    "odooEmployeeId" text NOT NULL
);


--
-- Name: EmployeeSchedule; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."EmployeeSchedule" (
    id text NOT NULL,
    "odooEmployeeId" text NOT NULL,
    "workDate" date NOT NULL,
    "dayType" public."DayType" NOT NULL,
    "shiftId" text,
    "shiftStart" timestamp with time zone,
    "shiftEnd" timestamp with time zone,
    source public."DataSource" NOT NULL,
    "importBatchId" text,
    "updatedAt" timestamp with time zone NOT NULL
);


--
-- Name: ImportBatch; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."ImportBatch" (
    id text NOT NULL,
    "fileType" public."ImportFileType" NOT NULL,
    "fileName" text NOT NULL,
    "fileHash" text NOT NULL,
    status public."ImportStatus" DEFAULT 'RECEIVED'::public."ImportStatus" NOT NULL,
    "totalRows" integer DEFAULT 0 NOT NULL,
    "successRows" integer DEFAULT 0 NOT NULL,
    "errorRows" integer DEFAULT 0 NOT NULL,
    "uploadedBy" text,
    "createdAt" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "finishedAt" timestamp with time zone,
    progress integer DEFAULT 0 NOT NULL,
    "startedAt" timestamp with time zone
);


--
-- Name: ImportRowError; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."ImportRowError" (
    id text NOT NULL,
    "batchId" text NOT NULL,
    "rowNumber" integer NOT NULL,
    "rawLine" text NOT NULL,
    message text NOT NULL
);


--
-- Name: LeaveRequest; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."LeaveRequest" (
    id text NOT NULL,
    "externalRef" text,
    "odooEmployeeId" text NOT NULL,
    kind public."LeaveKind" DEFAULT 'ANNUAL'::public."LeaveKind" NOT NULL,
    "odooLeaveTypeId" integer,
    "startDate" date NOT NULL,
    "endDate" date NOT NULL,
    days numeric(5,2) NOT NULL,
    reason text,
    source public."DataSource" DEFAULT 'PEOPLEHUB'::public."DataSource" NOT NULL,
    "overallStatus" public."RequestStatus" DEFAULT 'PENDING'::public."RequestStatus" NOT NULL,
    "importBatchId" text,
    "createdAt" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL
);


--
-- Name: LeaveRule; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."LeaveRule" (
    id text NOT NULL,
    "leaveKind" public."LeaveKind" NOT NULL,
    "effectiveFrom" date NOT NULL,
    "effectiveTo" date,
    "minTenureMonths" integer DEFAULT 0 NOT NULL,
    "accrualMode" public."AccrualMode" DEFAULT 'NONE'::public."AccrualMode" NOT NULL,
    "entitlementDays" numeric(5,2),
    "firstGrantAnniversary" integer DEFAULT 1 NOT NULL,
    "expiryMonths" integer,
    "updatedBy" text,
    "createdAt" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL
);


--
-- Name: Menu; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."Menu" (
    id text NOT NULL,
    code text NOT NULL,
    label text NOT NULL,
    path text,
    icon text,
    "sortOrder" integer DEFAULT 0 NOT NULL,
    "parentId" text,
    "requiredPermissionId" text,
    "isActive" boolean DEFAULT true NOT NULL
);


--
-- Name: OdooContract; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."OdooContract" (
    id text NOT NULL,
    "odooContractId" integer NOT NULL,
    "odooEmployeeId" text NOT NULL,
    wage numeric(15,2) NOT NULL,
    "dateStart" date NOT NULL,
    "dateEnd" date,
    "isActive" boolean DEFAULT true NOT NULL,
    "syncedAt" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: OdooEmployee; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."OdooEmployee" (
    id text NOT NULL,
    "odooId" integer NOT NULL,
    nik text,
    name text NOT NULL,
    email text,
    "jobTitle" text,
    "jobGrade" text,
    "isActive" boolean DEFAULT true NOT NULL,
    "parentOdooId" integer,
    "workLocationId" text NOT NULL,
    "lastSyncedAt" timestamp with time zone,
    "createdAt" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL,
    "hireDate" date
);


--
-- Name: OvertimeRealization; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."OvertimeRealization" (
    id text NOT NULL,
    "externalRef" text NOT NULL,
    "odooEmployeeId" text NOT NULL,
    "workDate" date NOT NULL,
    "actualStart" timestamp with time zone NOT NULL,
    "actualEnd" timestamp with time zone NOT NULL,
    "planExternalRef" text,
    "overtimeRequestId" text,
    "reconciliationStatus" public."OtReconStatus" DEFAULT 'PENDING_PLAN'::public."OtReconStatus" NOT NULL,
    "payableMinutes" integer,
    "appliedBasis" public."OvertimePayableBasis",
    "appliedRuleId" text,
    "importBatchId" text NOT NULL
);


--
-- Name: OvertimeRequest; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."OvertimeRequest" (
    id text NOT NULL,
    "externalRef" text,
    "odooEmployeeId" text NOT NULL,
    "workDate" date NOT NULL,
    "plannedStart" timestamp with time zone NOT NULL,
    "plannedEnd" timestamp with time zone NOT NULL,
    reason text NOT NULL,
    source public."DataSource" DEFAULT 'PEOPLEHUB'::public."DataSource" NOT NULL,
    "overallStatus" public."RequestStatus" DEFAULT 'PENDING'::public."RequestStatus" NOT NULL,
    "createdAt" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: OvertimeRule; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."OvertimeRule" (
    id text NOT NULL,
    "workLocationId" text NOT NULL,
    "effectiveFrom" date NOT NULL,
    "effectiveTo" date,
    "workWeekPattern" public."WorkWeek" NOT NULL,
    "payableBasis" public."OvertimePayableBasis" DEFAULT 'PLAN_REALIZATION'::public."OvertimePayableBasis" NOT NULL,
    "punchToleranceMinutes" integer DEFAULT 15 NOT NULL,
    "minMinutes" integer DEFAULT 30 NOT NULL,
    "roundingMinutes" integer DEFAULT 30 NOT NULL,
    "maxMinutesPerDay" integer DEFAULT 240 NOT NULL,
    "maxMinutesPerWeek" integer DEFAULT 1080 NOT NULL,
    "multiplierTiersJson" jsonb NOT NULL,
    "excludedJobGrades" text[],
    "updatedBy" text,
    "updatedAt" timestamp with time zone NOT NULL
);


--
-- Name: PayrollPeriod; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."PayrollPeriod" (
    id text NOT NULL,
    code text NOT NULL,
    "startDate" date NOT NULL,
    "endDate" date NOT NULL,
    status public."PayrollPeriodStatus" DEFAULT 'OPEN'::public."PayrollPeriodStatus" NOT NULL,
    "frozenAt" timestamp with time zone,
    "frozenBy" text
);


--
-- Name: PendingAdjustment; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."PendingAdjustment" (
    id text NOT NULL,
    "odooEmployeeId" text NOT NULL,
    "sourcePeriodId" text NOT NULL,
    "workDate" date NOT NULL,
    reason text NOT NULL,
    "deltaLateDeduction" numeric(15,2) DEFAULT 0 NOT NULL,
    "deltaOvertimeMinutes" integer DEFAULT 0 NOT NULL,
    "appliedPeriodId" text,
    "createdAt" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: Permission; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."Permission" (
    id text NOT NULL,
    code text NOT NULL,
    module text NOT NULL,
    description text
);


--
-- Name: PrePayrollResult; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."PrePayrollResult" (
    id text NOT NULL,
    "odooEmployeeId" text NOT NULL,
    "periodId" text NOT NULL,
    "totalLateDeduction" numeric(15,2) DEFAULT 0 NOT NULL,
    "totalUnpaidDeduction" numeric(15,2) DEFAULT 0 NOT NULL,
    "netDeductionAmount" numeric(15,2) DEFAULT 0 NOT NULL,
    "totalOvertimeMinutes" integer DEFAULT 0 NOT NULL,
    "totalOvertimePay" numeric(15,2),
    "overtimeBreakdownJson" jsonb,
    "isFrozen" boolean DEFAULT false NOT NULL,
    "frozenAt" timestamp with time zone,
    "odooSyncStatus" public."OdooSyncStatus" DEFAULT 'PENDING'::public."OdooSyncStatus" NOT NULL,
    "odooSyncError" text,
    "odooPayslipInputIds" jsonb,
    "odooSyncedAt" timestamp with time zone,
    "createdAt" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL
);


--
-- Name: ProcessLog; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."ProcessLog" (
    id text NOT NULL,
    "batchId" text NOT NULL,
    level public."LogLevel" DEFAULT 'INFO'::public."LogLevel" NOT NULL,
    message text NOT NULL,
    "createdAt" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    seq integer NOT NULL
);


--
-- Name: ProcessLog_seq_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public."ProcessLog_seq_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ProcessLog_seq_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public."ProcessLog_seq_seq" OWNED BY public."ProcessLog".seq;


--
-- Name: Role; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."Role" (
    id text NOT NULL,
    code text NOT NULL,
    name text NOT NULL,
    description text,
    "isSystem" boolean DEFAULT false NOT NULL
);


--
-- Name: RolePermission; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."RolePermission" (
    id text NOT NULL,
    "roleId" text NOT NULL,
    "permissionId" text NOT NULL,
    "menuId" text,
    "canCreate" boolean DEFAULT false NOT NULL,
    "canRead" boolean DEFAULT true NOT NULL,
    "canUpdate" boolean DEFAULT false NOT NULL,
    "canDelete" boolean DEFAULT false NOT NULL
);


--
-- Name: RuleSimulation; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."RuleSimulation" (
    id text NOT NULL,
    "ruleType" public."SimulationTarget" NOT NULL,
    "workLocationId" text NOT NULL,
    "periodStart" date NOT NULL,
    "periodEnd" date NOT NULL,
    "baselineRuleId" text NOT NULL,
    "draftRuleJson" jsonb NOT NULL,
    status public."SimulationStatus" DEFAULT 'QUEUED'::public."SimulationStatus" NOT NULL,
    "progressPct" integer DEFAULT 0 NOT NULL,
    "summaryJson" jsonb,
    "errorMessage" text,
    "requestedBy" text NOT NULL,
    "createdAt" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "expiresAt" timestamp with time zone NOT NULL
);


--
-- Name: RuleSimulationDetail; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."RuleSimulationDetail" (
    id text NOT NULL,
    "simulationId" text NOT NULL,
    "odooEmployeeId" text NOT NULL,
    "baselineMinutes" integer NOT NULL,
    "draftMinutes" integer NOT NULL,
    "baselineAmount" numeric(15,2),
    "draftAmount" numeric(15,2),
    "affectedDays" jsonb NOT NULL
);


--
-- Name: Shift; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."Shift" (
    id text NOT NULL,
    code text NOT NULL,
    name text NOT NULL,
    "startTime" text NOT NULL,
    "durationMinutes" integer NOT NULL,
    "breakMinutes" integer DEFAULT 60 NOT NULL,
    "isActive" boolean DEFAULT true NOT NULL
);


--
-- Name: TimeEntry; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."TimeEntry" (
    id text NOT NULL,
    "odooEmployeeId" text NOT NULL,
    "startAt" timestamp with time zone NOT NULL,
    "endAt" timestamp with time zone NOT NULL,
    "workDate" date NOT NULL,
    "shiftId" text,
    "workSchedule" text,
    "payrollPeriod" text NOT NULL,
    source public."DataSource" DEFAULT 'IMPORT'::public."DataSource" NOT NULL,
    "importBatchId" text,
    "createdAt" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL,
    "durationHours" numeric(6,2) DEFAULT 0 NOT NULL
);


--
-- Name: User; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."User" (
    id text NOT NULL,
    email text NOT NULL,
    "passwordHash" text NOT NULL,
    "isActive" boolean DEFAULT true NOT NULL,
    "lastLoginAt" timestamp with time zone,
    "odooEmployeeId" text,
    "createdAt" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL
);


--
-- Name: UserPermissionOverride; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."UserPermissionOverride" (
    id text NOT NULL,
    "userId" text NOT NULL,
    "permissionId" text NOT NULL,
    "isAllowed" boolean NOT NULL,
    reason text,
    "expiresAt" timestamp with time zone,
    "createdBy" text,
    "createdAt" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: UserRole; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."UserRole" (
    "userId" text NOT NULL,
    "roleId" text NOT NULL,
    "assignedAt" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: WorkLocation; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."WorkLocation" (
    id text NOT NULL,
    code text NOT NULL,
    name text NOT NULL,
    type public."LocationType" NOT NULL,
    timezone text DEFAULT 'Asia/Jakarta'::text NOT NULL,
    latitude numeric(9,6),
    longitude numeric(9,6),
    "geofenceRadiusMeters" integer,
    "isActive" boolean DEFAULT true NOT NULL,
    "createdAt" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL
);


--
-- Name: _prisma_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public._prisma_migrations (
    id character varying(36) NOT NULL,
    checksum character varying(64) NOT NULL,
    finished_at timestamp with time zone,
    migration_name character varying(255) NOT NULL,
    logs text,
    rolled_back_at timestamp with time zone,
    started_at timestamp with time zone DEFAULT now() NOT NULL,
    applied_steps_count integer DEFAULT 0 NOT NULL
);


--
-- Name: ProcessLog seq; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."ProcessLog" ALTER COLUMN seq SET DEFAULT nextval('public."ProcessLog_seq_seq"'::regclass);


--
-- Data for Name: AttendanceDaily; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."AttendanceDaily" (id, "odooEmployeeId", "workDate", status, "clockIn", "clockOut", "isLate", "lateMinutes", "overtimeDetectedMinutes", "overtimeApprovedMinutes", "overtimePayableMinutes", "appliedRuleId", "computedAt") FROM stdin;
51d42af2-2c17-42d0-9977-90920524d8b1	6a65b903-7cb2-468b-8245-a607e73baa54	2026-09-05	OFFDAY	\N	\N	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.474+07
242b6977-76ea-4686-af69-959c3be788a9	6a65b903-7cb2-468b-8245-a607e73baa54	2026-09-06	OFFDAY	\N	\N	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.474+07
6a5ada8e-20c3-4351-8668-f00f1a3291b5	6a65b903-7cb2-468b-8245-a607e73baa54	2026-09-07	PRESENT	2026-09-07 07:50:00+07	2026-09-07 16:15:00+07	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.474+07
ac2506e1-fcd2-4c29-9fde-56a699067ebb	6a65b903-7cb2-468b-8245-a607e73baa54	2026-09-08	PRESENT	2026-09-08 07:55:00+07	2026-09-08 16:30:00+07	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.474+07
2cacde82-f2c5-45a9-a138-3fa24195d027	6a65b903-7cb2-468b-8245-a607e73baa54	2026-09-09	PRESENT	2026-09-09 08:00:00+07	2026-09-09 16:00:00+07	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.474+07
efa87f5d-ed99-4515-b321-5377adde61aa	6a65b903-7cb2-468b-8245-a607e73baa54	2026-09-10	PRESENT	2026-09-10 08:05:00+07	2026-09-10 16:15:00+07	f	5	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.474+07
62aa3b6b-59dd-440c-b0a1-3349a3680d4e	6a65b903-7cb2-468b-8245-a607e73baa54	2026-09-11	PRESENT	2026-09-11 07:50:00+07	2026-09-11 16:30:00+07	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.474+07
6e7e7eef-c7c4-4b0b-9dea-fc3dd88557b7	6a65b903-7cb2-468b-8245-a607e73baa54	2026-09-12	OFFDAY	\N	\N	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.474+07
c1dd747a-ca47-40a2-929d-beb84ee55d74	6a65b903-7cb2-468b-8245-a607e73baa54	2026-09-13	OFFDAY	\N	\N	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.474+07
1a7c3417-a1b7-4827-804a-7be1a94febe6	6a65b903-7cb2-468b-8245-a607e73baa54	2026-09-14	PRESENT	2026-09-14 07:55:00+07	2026-09-14 16:00:00+07	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.474+07
e83ed28b-881e-4d8c-9beb-c92c6692ada7	6a65b903-7cb2-468b-8245-a607e73baa54	2026-09-15	PRESENT	2026-09-15 08:00:00+07	2026-09-15 16:15:00+07	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.474+07
50b0d088-877d-48a9-828d-eb68df3f6fc1	6a65b903-7cb2-468b-8245-a607e73baa54	2026-09-16	HOLIDAY	\N	\N	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.474+07
f0e59960-8e87-4ae7-966d-4b00f37a2fea	6a65b903-7cb2-468b-8245-a607e73baa54	2026-09-17	PRESENT	2026-09-17 08:05:00+07	2026-09-17 16:30:00+07	f	5	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.474+07
b5770583-5a53-4ffb-87bc-27feba864912	6a65b903-7cb2-468b-8245-a607e73baa54	2026-09-01	PRESENT	2026-09-01 07:50:00+07	2026-09-01 16:00:00+07	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.474+07
54d88d3e-05bd-4e03-a0d2-24c66aa20968	6a65b903-7cb2-468b-8245-a607e73baa54	2026-09-02	PRESENT	2026-09-02 07:55:00+07	2026-09-02 16:15:00+07	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.474+07
03094766-a118-44f2-bbcd-b28de658de7d	6a65b903-7cb2-468b-8245-a607e73baa54	2026-09-03	PRESENT	2026-09-03 08:00:00+07	2026-09-03 16:30:00+07	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.474+07
e011a17d-947f-4913-86ec-0d921a0bec9b	6a65b903-7cb2-468b-8245-a607e73baa54	2026-09-04	PRESENT	2026-09-04 08:05:00+07	2026-09-04 16:00:00+07	f	5	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.474+07
fcbe1ef1-aa50-4dfa-8231-c09cfd8289f0	6a65b903-7cb2-468b-8245-a607e73baa54	2026-09-22	PRESENT	2026-09-22 08:00:00+07	2026-09-22 16:30:00+07	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.474+07
af91883c-85fe-44dc-83dc-2fee2bab47e5	6a65b903-7cb2-468b-8245-a607e73baa54	2026-09-23	PRESENT	2026-09-23 08:05:00+07	2026-09-23 16:00:00+07	f	5	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.474+07
e70e0974-3774-432a-9f97-d9d240b97f13	6a65b903-7cb2-468b-8245-a607e73baa54	2026-09-24	PRESENT	2026-09-24 07:50:00+07	2026-09-24 16:15:00+07	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.474+07
a7de55b2-f38e-4284-9f63-09ef11d29a76	6a65b903-7cb2-468b-8245-a607e73baa54	2026-09-25	PRESENT	2026-09-25 07:55:00+07	2026-09-25 16:30:00+07	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.474+07
d6d0ecbe-5441-4e7f-ae8d-c748a2bee9e6	6a65b903-7cb2-468b-8245-a607e73baa54	2026-09-26	OFFDAY	\N	\N	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.474+07
c435056d-4fdd-4217-bf9b-b80a701f85f7	6a65b903-7cb2-468b-8245-a607e73baa54	2026-09-27	OFFDAY	\N	\N	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.474+07
a0acabfc-1056-49dd-a0f5-0ecff1454777	6a65b903-7cb2-468b-8245-a607e73baa54	2026-09-28	PRESENT	2026-09-28 08:00:00+07	2026-09-28 16:00:00+07	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.474+07
07e9d3b0-951d-474d-98da-23ec06c50296	6a65b903-7cb2-468b-8245-a607e73baa54	2026-09-29	PRESENT	2026-09-29 08:05:00+07	2026-09-29 16:15:00+07	f	5	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.474+07
e0cf3f63-cf17-4411-8557-f1158a0ff1a1	6a65b903-7cb2-468b-8245-a607e73baa54	2026-09-30	PRESENT	2026-09-30 07:50:00+07	2026-09-30 16:30:00+07	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.474+07
769af353-9539-45f0-836f-4c6925b2f1d9	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	2026-09-01	LATE	2026-09-01 08:40:00+07	2026-09-01 16:30:00+07	t	40	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.554+07
78f3afde-ba8f-41bb-b5b7-e97f57fc77be	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	2026-09-02	PRESENT	2026-09-02 08:05:00+07	2026-09-02 16:30:00+07	f	5	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.554+07
923e7ef5-be0c-4d9c-b950-1df1d32c3765	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	2026-09-03	PRESENT	2026-09-03 08:05:00+07	2026-09-03 16:30:00+07	f	5	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.554+07
43cead80-f032-4fa6-8272-f6910f4d4f1e	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	2026-09-04	LATE	2026-09-04 08:25:00+07	2026-09-04 16:30:00+07	t	25	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.554+07
35c621e0-40ef-4f72-8cbb-2c8c1d284706	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	2026-09-05	OFFDAY	\N	\N	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.554+07
e791faf3-0d0c-4625-9af4-ce56dd492d57	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	2026-09-06	OFFDAY	\N	\N	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.554+07
0e49dc61-680d-43a8-8603-77bd9ddc7385	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	2026-09-07	PRESENT	2026-09-07 08:05:00+07	2026-09-07 16:30:00+07	f	5	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.554+07
93b3dd3c-12cf-4e5a-9749-2fb2402f5be4	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	2026-09-08	LATE	2026-09-08 08:40:00+07	2026-09-08 16:30:00+07	t	40	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.554+07
e834896c-d59d-417d-94aa-568b6d3f4b4a	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	2026-09-09	LATE	2026-09-09 08:25:00+07	2026-09-09 16:30:00+07	t	25	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.554+07
e6540e7f-989e-4bf4-b5be-8a07c37579c7	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	2026-09-10	PRESENT	2026-09-10 08:05:00+07	2026-09-10 16:30:00+07	f	5	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.554+07
f91db39c-de94-4372-bbd9-756d411f0c1e	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	2026-09-11	PRESENT	2026-09-11 08:05:00+07	2026-09-11 16:30:00+07	f	5	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.554+07
9057c182-ef74-4480-9e92-56482d61b61a	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	2026-09-12	OFFDAY	\N	\N	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.554+07
97334511-5ac2-41f8-a656-7f1da2e2003d	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	2026-09-13	OFFDAY	\N	\N	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.554+07
369f10bf-d6c0-4198-a1be-ad2f415e202a	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	2026-09-14	LATE	2026-09-14 08:25:00+07	2026-09-14 16:30:00+07	t	25	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.554+07
36e0d655-86bf-4454-a5df-5ef271e23057	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	2026-09-15	LATE	2026-09-15 08:40:00+07	2026-09-15 16:30:00+07	t	40	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.554+07
ea2859fa-f264-474b-a2b4-81b3042b36ac	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	2026-09-16	HOLIDAY	\N	\N	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.554+07
fc57ce5d-0ca4-40ab-851c-3e004cecefc8	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	2026-09-17	PRESENT	2026-09-17 08:05:00+07	2026-09-17 16:30:00+07	f	5	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.554+07
8f30ec55-ca2c-4637-a2e8-60032a039395	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	2026-09-18	LATE	2026-09-18 08:25:00+07	2026-09-18 16:30:00+07	t	25	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.554+07
b76b0c2f-713e-4c69-af59-d3075885635a	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	2026-09-19	OFFDAY	\N	\N	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.554+07
198f1a6a-ae88-44de-ad5c-2ed8dee77251	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	2026-09-20	OFFDAY	\N	\N	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.554+07
ba94f8ec-2fcb-4633-a895-61ad240aefed	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	2026-09-21	PRESENT	2026-09-21 08:05:00+07	2026-09-21 16:30:00+07	f	5	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.554+07
e2fb1103-1e0d-4ce5-80c5-b4ffa9d7e65a	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	2026-09-22	PRESENT	2026-09-22 08:05:00+07	2026-09-22 16:30:00+07	f	5	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.554+07
5315f673-2052-40e3-b222-dc7c86580177	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	2026-09-23	LATE	2026-09-23 08:40:00+07	2026-09-23 16:30:00+07	t	40	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.554+07
8f4fcf5e-8b2b-43bd-85e3-881980632bfc	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	2026-09-24	PRESENT	2026-09-24 08:05:00+07	2026-09-24 16:30:00+07	f	5	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.554+07
e9ee9c52-6d0f-40d4-b799-326d61d2489a	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	2026-09-25	PRESENT	2026-09-25 08:05:00+07	2026-09-25 16:30:00+07	f	5	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.554+07
670db033-3267-409a-a7aa-8c89d108aaeb	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	2026-09-26	OFFDAY	\N	\N	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.554+07
03409b32-b2cf-4742-8efe-0558228bbea2	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	2026-09-27	OFFDAY	\N	\N	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.554+07
77fda7e6-1ad8-4f3c-8bf4-3e06fce0afcb	6a65b903-7cb2-468b-8245-a607e73baa54	2026-09-19	OFFDAY	\N	\N	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.474+07
b9548b86-924f-4cf2-b630-f50f754a4c30	6a65b903-7cb2-468b-8245-a607e73baa54	2026-09-20	OFFDAY	\N	\N	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.474+07
f9bdd3bf-4768-4048-9258-026be74a7c5c	4478787b-c3e8-4f0d-8b9b-7046fec7f539	2026-09-01	PRESENT	2026-09-01 08:00:00+07	2026-09-01 16:10:00+07	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.634+07
5669a6c3-cc84-47a9-890b-740cc8d28ee3	4478787b-c3e8-4f0d-8b9b-7046fec7f539	2026-09-02	PRESENT	2026-09-02 08:03:00+07	2026-09-02 16:10:00+07	f	3	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.634+07
adbc84f7-86dc-4ad5-9000-37ddec106bc4	4478787b-c3e8-4f0d-8b9b-7046fec7f539	2026-09-04	PRESENT	2026-09-04 08:00:00+07	2026-09-04 16:10:00+07	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.634+07
b666ef2e-1062-45af-8d5b-bf7cc999f6d6	4478787b-c3e8-4f0d-8b9b-7046fec7f539	2026-09-05	OFFDAY	\N	\N	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.634+07
5d34a55d-d71c-446a-a6df-5a0a5e26b50f	4478787b-c3e8-4f0d-8b9b-7046fec7f539	2026-09-06	OFFDAY	\N	\N	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.634+07
82f18d25-86e9-4acb-88c4-cc2722e716bd	4478787b-c3e8-4f0d-8b9b-7046fec7f539	2026-09-07	PRESENT	2026-09-07 08:03:00+07	2026-09-07 16:10:00+07	f	3	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.634+07
43eb412b-be14-4a56-a6a5-f939182f5a5f	4478787b-c3e8-4f0d-8b9b-7046fec7f539	2026-09-08	PRESENT	2026-09-08 08:06:00+07	2026-09-08 16:10:00+07	f	6	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.634+07
74070b02-6342-4948-8233-4ddef029c45c	4478787b-c3e8-4f0d-8b9b-7046fec7f539	2026-09-09	ABSENT	\N	\N	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.634+07
73cf0d8e-fc64-4564-9833-c244085429a3	4478787b-c3e8-4f0d-8b9b-7046fec7f539	2026-09-10	PRESENT	2026-09-10 08:03:00+07	2026-09-10 16:10:00+07	f	3	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.634+07
5ce5d727-5cb3-4887-9578-253d638ba139	4478787b-c3e8-4f0d-8b9b-7046fec7f539	2026-09-11	INCOMPLETE	2026-09-11 08:02:00+07	\N	f	2	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.634+07
b7b16c2f-2bea-4309-bd30-f2ede63d5190	4478787b-c3e8-4f0d-8b9b-7046fec7f539	2026-09-12	OFFDAY	\N	\N	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.634+07
a6203c9c-60b3-48f9-8a20-836b7084b7a7	4478787b-c3e8-4f0d-8b9b-7046fec7f539	2026-09-13	OFFDAY	\N	\N	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.634+07
a0e357a4-1854-4106-a406-f5b340baead2	4478787b-c3e8-4f0d-8b9b-7046fec7f539	2026-09-14	PRESENT	2026-09-14 08:00:00+07	2026-09-14 16:10:00+07	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.634+07
a5d1835a-a84a-4f9d-8be6-634e213071c6	4478787b-c3e8-4f0d-8b9b-7046fec7f539	2026-09-15	PRESENT	2026-09-15 08:03:00+07	2026-09-15 16:10:00+07	f	3	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.634+07
71b05351-5b72-42c3-9ce4-3428100c54ee	4478787b-c3e8-4f0d-8b9b-7046fec7f539	2026-09-16	HOLIDAY	\N	\N	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.634+07
48bdbe20-e4fb-454c-860a-a08c7ee74167	4478787b-c3e8-4f0d-8b9b-7046fec7f539	2026-09-17	PRESENT	2026-09-17 08:06:00+07	2026-09-17 16:10:00+07	f	6	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.634+07
24e8fe1a-0c41-4bd2-a84c-d3e51bfe806d	4478787b-c3e8-4f0d-8b9b-7046fec7f539	2026-09-18	PRESENT	2026-09-18 08:00:00+07	2026-09-18 16:10:00+07	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.634+07
793c1f67-7d25-470d-b0e7-0bc0f83d95dd	4478787b-c3e8-4f0d-8b9b-7046fec7f539	2026-09-19	OFFDAY	\N	\N	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.634+07
77a18489-1bd5-47f1-a046-31c35b6881fb	4478787b-c3e8-4f0d-8b9b-7046fec7f539	2026-09-20	OFFDAY	\N	\N	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.634+07
722ea182-0250-40ca-8b50-30bc80426daa	4478787b-c3e8-4f0d-8b9b-7046fec7f539	2026-09-21	PRESENT	2026-09-21 08:03:00+07	2026-09-21 16:10:00+07	f	3	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.634+07
a6298cab-3479-4953-ba1f-b6590344d6bf	4478787b-c3e8-4f0d-8b9b-7046fec7f539	2026-09-22	PRESENT	2026-09-22 08:06:00+07	2026-09-22 16:10:00+07	f	6	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.634+07
1820d7ad-e534-430d-8097-02431d0b6cb6	4478787b-c3e8-4f0d-8b9b-7046fec7f539	2026-09-23	ABSENT	\N	\N	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.634+07
3d89d246-522e-4261-b520-610a94b29c4a	4478787b-c3e8-4f0d-8b9b-7046fec7f539	2026-09-24	PRESENT	2026-09-24 08:03:00+07	2026-09-24 16:10:00+07	f	3	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.634+07
530288bb-26f7-4b5b-adc0-975af03f6b7e	4478787b-c3e8-4f0d-8b9b-7046fec7f539	2026-09-25	PRESENT	2026-09-25 08:06:00+07	2026-09-25 16:10:00+07	f	6	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.634+07
7bfda0b1-33d6-48a0-9f6e-9b6623542812	4478787b-c3e8-4f0d-8b9b-7046fec7f539	2026-09-26	OFFDAY	\N	\N	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.634+07
3f723d81-e90f-449e-a4ac-ef628284b0f8	4478787b-c3e8-4f0d-8b9b-7046fec7f539	2026-09-27	OFFDAY	\N	\N	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.634+07
bcd3c278-69c4-43ff-b6fd-5fd0c5f1a273	4478787b-c3e8-4f0d-8b9b-7046fec7f539	2026-09-28	INCOMPLETE	2026-09-28 08:02:00+07	\N	f	2	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.634+07
dcb069df-4a21-4b6e-8114-0d7cb2583cac	4478787b-c3e8-4f0d-8b9b-7046fec7f539	2026-09-29	PRESENT	2026-09-29 08:03:00+07	2026-09-29 16:10:00+07	f	3	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.634+07
7be535fa-7c1d-4036-a993-78f96316e240	4478787b-c3e8-4f0d-8b9b-7046fec7f539	2026-09-30	PRESENT	2026-09-30 08:06:00+07	2026-09-30 16:10:00+07	f	6	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.634+07
1583121a-966c-4807-93d0-a646c9287e97	0cd6bde6-3226-4ebb-b135-ca522d42efa4	2026-09-01	PRESENT	2026-09-01 07:55:00+07	2026-09-01 16:05:00+07	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.71+07
9884bbbd-ca95-4b7c-9a9f-417b6f5863ea	0cd6bde6-3226-4ebb-b135-ca522d42efa4	2026-09-02	PRESENT	2026-09-02 07:55:00+07	2026-09-02 16:05:00+07	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.71+07
4cf29eac-01fa-430f-94d5-50acc6dee096	0cd6bde6-3226-4ebb-b135-ca522d42efa4	2026-09-03	PRESENT	2026-09-03 07:55:00+07	2026-09-03 16:05:00+07	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.71+07
5edba564-c0de-4161-b64b-4c0f119dc9b1	0cd6bde6-3226-4ebb-b135-ca522d42efa4	2026-09-04	PRESENT	2026-09-04 07:55:00+07	2026-09-04 16:05:00+07	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.71+07
ddcffa9e-2a22-4aec-bbfb-2233a7240101	0cd6bde6-3226-4ebb-b135-ca522d42efa4	2026-09-05	OFFDAY	\N	\N	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.71+07
5632e836-4a6c-40a7-9476-ef0752bc2377	0cd6bde6-3226-4ebb-b135-ca522d42efa4	2026-09-06	OFFDAY	\N	\N	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.71+07
da48ff86-3583-41cc-9387-3ab07a80bd37	0cd6bde6-3226-4ebb-b135-ca522d42efa4	2026-09-07	PRESENT	2026-09-07 07:55:00+07	2026-09-07 16:05:00+07	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.71+07
1d1f6fef-27d5-4c7e-8daf-3aee663c7b0f	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	2026-09-29	PRESENT	2026-09-29 08:05:00+07	2026-09-29 16:30:00+07	f	5	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.554+07
3577f3a9-2253-4a9a-aa92-a3f6bc753c7d	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	2026-09-30	LATE	2026-09-30 08:40:00+07	2026-09-30 16:30:00+07	t	40	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.554+07
7b9f9f34-3354-4cb3-86f9-9e5e51cafecf	0cd6bde6-3226-4ebb-b135-ca522d42efa4	2026-09-11	PRESENT	2026-09-11 07:55:00+07	2026-09-11 16:05:00+07	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.71+07
7266970b-98da-458f-8a4f-f16a403e10fb	0cd6bde6-3226-4ebb-b135-ca522d42efa4	2026-09-12	OFFDAY	\N	\N	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.71+07
519d3491-fb9b-4fad-9d38-2fd28a117bc0	0cd6bde6-3226-4ebb-b135-ca522d42efa4	2026-09-13	OFFDAY	\N	\N	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.71+07
d8036113-2292-4dfd-a147-74b9dd915ec2	0cd6bde6-3226-4ebb-b135-ca522d42efa4	2026-09-14	PRESENT	2026-09-14 07:55:00+07	2026-09-14 16:05:00+07	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.71+07
c8628fc3-0254-4b7a-aa02-90bc1aa608a7	0cd6bde6-3226-4ebb-b135-ca522d42efa4	2026-09-15	PRESENT	2026-09-15 07:55:00+07	2026-09-15 16:05:00+07	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.71+07
78d07180-0668-4c69-8728-f59d3ce3cd9e	0cd6bde6-3226-4ebb-b135-ca522d42efa4	2026-09-16	HOLIDAY	\N	\N	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.71+07
4fe9bcf1-03d5-4237-9140-6f46b397ddb1	0cd6bde6-3226-4ebb-b135-ca522d42efa4	2026-09-17	PRESENT	2026-09-17 07:55:00+07	2026-09-17 16:05:00+07	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.71+07
3c0f3c0c-dc13-488e-bd05-a47fb82e1788	0cd6bde6-3226-4ebb-b135-ca522d42efa4	2026-09-18	PRESENT	2026-09-18 07:55:00+07	2026-09-18 16:05:00+07	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.71+07
c81b7006-01ab-4809-beb1-af5c272610ad	0cd6bde6-3226-4ebb-b135-ca522d42efa4	2026-09-19	OFFDAY	\N	\N	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.71+07
6d46e222-7ad5-4be8-a397-4ce47a1325e7	0cd6bde6-3226-4ebb-b135-ca522d42efa4	2026-09-20	OFFDAY	\N	\N	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.71+07
5b49831a-dda0-4649-9640-74bf339e7d30	0cd6bde6-3226-4ebb-b135-ca522d42efa4	2026-09-21	ON_LEAVE	\N	\N	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.71+07
342ff001-80e4-42cb-b52e-983d0c4ee60c	0cd6bde6-3226-4ebb-b135-ca522d42efa4	2026-09-23	PRESENT	2026-09-23 07:55:00+07	2026-09-23 16:05:00+07	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.71+07
7b5ff5c6-72db-4309-8d89-360233fe16ac	0cd6bde6-3226-4ebb-b135-ca522d42efa4	2026-09-24	PRESENT	2026-09-24 07:55:00+07	2026-09-24 16:05:00+07	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.71+07
bf9b2ebc-54fd-438d-bc0d-2b0a0735a70a	0cd6bde6-3226-4ebb-b135-ca522d42efa4	2026-09-25	PRESENT	2026-09-25 07:55:00+07	2026-09-25 16:05:00+07	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.71+07
b059c23c-eee5-44a3-a0bc-4f1aeaf4905b	0cd6bde6-3226-4ebb-b135-ca522d42efa4	2026-09-26	OFFDAY	\N	\N	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.71+07
db3dff2e-d741-422c-88ce-31cd5b12955e	0cd6bde6-3226-4ebb-b135-ca522d42efa4	2026-09-27	OFFDAY	\N	\N	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.71+07
46482e67-866d-4d48-be48-d56b84f393f7	0cd6bde6-3226-4ebb-b135-ca522d42efa4	2026-09-28	PRESENT	2026-09-28 07:55:00+07	2026-09-28 16:05:00+07	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.71+07
b8a47c23-cc1d-4862-b3b5-f30647112bd8	0cd6bde6-3226-4ebb-b135-ca522d42efa4	2026-09-29	PRESENT	2026-09-29 07:55:00+07	2026-09-29 16:05:00+07	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.71+07
0db58bfe-ce93-49c4-b58e-c4335d3a4bf6	0cd6bde6-3226-4ebb-b135-ca522d42efa4	2026-09-30	PRESENT	2026-09-30 07:55:00+07	2026-09-30 16:05:00+07	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.71+07
2fd39787-2a48-4298-a2be-b8f906bf0f7c	0c685448-b52e-4e60-89ea-6f7c500a86d5	2026-09-01	PRESENT	2026-09-01 15:50:00+07	2026-09-02 00:05:00+07	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.781+07
6fd075b3-8e7e-4d4f-a362-0eb67b79a9bb	0c685448-b52e-4e60-89ea-6f7c500a86d5	2026-09-02	PRESENT	2026-09-02 15:55:00+07	2026-09-03 00:10:00+07	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.781+07
6abeaf0b-1397-4dc9-a2f0-53818e02d6b2	0c685448-b52e-4e60-89ea-6f7c500a86d5	2026-09-03	PRESENT	2026-09-03 16:00:00+07	2026-09-04 00:15:00+07	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.781+07
ae137499-417b-421a-b351-67bcd0010339	0c685448-b52e-4e60-89ea-6f7c500a86d5	2026-09-04	PRESENT	2026-09-04 15:50:00+07	2026-09-05 00:05:00+07	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.781+07
1ab6d057-a90e-41f7-a8a2-9e8742bc2fbc	0c685448-b52e-4e60-89ea-6f7c500a86d5	2026-09-05	OFFDAY	\N	\N	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.781+07
5bd4e70d-1034-403a-bca7-1f1516a8fffd	0c685448-b52e-4e60-89ea-6f7c500a86d5	2026-09-06	OFFDAY	\N	\N	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.781+07
15030b68-beca-4fbc-9669-b131091fc1d7	0c685448-b52e-4e60-89ea-6f7c500a86d5	2026-09-07	PRESENT	2026-09-07 15:55:00+07	2026-09-08 00:10:00+07	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.781+07
a8a25d3a-7147-4773-a0a3-b9cdbdd4928a	0c685448-b52e-4e60-89ea-6f7c500a86d5	2026-09-08	PRESENT	2026-09-08 16:00:00+07	2026-09-09 00:15:00+07	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.781+07
3ae969b2-187f-4606-a426-2b617ebc3691	0c685448-b52e-4e60-89ea-6f7c500a86d5	2026-09-09	PRESENT	2026-09-09 15:50:00+07	2026-09-10 00:05:00+07	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.781+07
39a4b92f-1ae5-424c-8f79-96abf5e76c07	0c685448-b52e-4e60-89ea-6f7c500a86d5	2026-09-10	PRESENT	2026-09-10 15:55:00+07	2026-09-11 00:10:00+07	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.781+07
78594c63-867d-479d-a540-cc6ff6e9fa9e	0c685448-b52e-4e60-89ea-6f7c500a86d5	2026-09-11	PRESENT	2026-09-11 16:00:00+07	2026-09-12 00:15:00+07	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.781+07
80c01623-f0bc-4dc9-8996-2617ecb50913	0c685448-b52e-4e60-89ea-6f7c500a86d5	2026-09-12	OFFDAY	\N	\N	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.781+07
2b9ef68e-6acf-4ad3-940c-488dd434ffdc	0c685448-b52e-4e60-89ea-6f7c500a86d5	2026-09-13	OFFDAY	\N	\N	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.781+07
2666a1f6-fa2b-4772-88ba-7134fdc0dc32	0c685448-b52e-4e60-89ea-6f7c500a86d5	2026-09-14	LATE	2026-09-14 16:35:00+07	2026-09-15 00:05:00+07	t	35	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.781+07
9e011d8f-2a19-4a43-b2b1-28f9fcab397e	0c685448-b52e-4e60-89ea-6f7c500a86d5	2026-09-15	PRESENT	2026-09-15 15:55:00+07	2026-09-16 00:10:00+07	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.781+07
0487bff7-7757-44ab-a52d-138356f6f59a	0c685448-b52e-4e60-89ea-6f7c500a86d5	2026-09-16	HOLIDAY	\N	\N	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.781+07
2243f024-16ba-4786-b1b4-a31e41416c0e	0c685448-b52e-4e60-89ea-6f7c500a86d5	2026-09-17	PRESENT	2026-09-17 16:00:00+07	2026-09-18 00:15:00+07	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.781+07
3ce35d22-e071-4c1a-a1fb-6d418112d7a6	0cd6bde6-3226-4ebb-b135-ca522d42efa4	2026-09-09	ON_LEAVE	\N	\N	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.71+07
ee5fad00-7f6f-465a-8160-56d2a5cb6c54	0cd6bde6-3226-4ebb-b135-ca522d42efa4	2026-09-10	ON_LEAVE	\N	\N	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.71+07
79be7cf2-cd27-4bae-88bd-442cfc53e242	23230ce1-1ab7-4b49-b9b2-404f149e00ca	2026-09-01	PRESENT	2026-09-01 05:58:00+07	2026-09-01 14:00:00+07	f	0	0	0	0	3a5de69c-b61e-42bd-aea3-f49ff3c5e654	2026-10-04 22:58:59.345+07
33e29ea8-ea3e-43aa-a1f3-e8fa0eaa361d	23230ce1-1ab7-4b49-b9b2-404f149e00ca	2026-09-02	PRESENT	2026-09-02 05:58:00+07	2026-09-02 14:00:00+07	f	0	0	0	0	3a5de69c-b61e-42bd-aea3-f49ff3c5e654	2026-10-04 22:58:59.345+07
f74a330e-49a3-4065-929e-778606244a8c	23230ce1-1ab7-4b49-b9b2-404f149e00ca	2026-09-03	PRESENT	2026-09-03 05:58:00+07	2026-09-03 14:00:00+07	f	0	0	0	0	3a5de69c-b61e-42bd-aea3-f49ff3c5e654	2026-10-04 22:58:59.345+07
e0ffc997-26c4-48f8-8bef-167958118661	23230ce1-1ab7-4b49-b9b2-404f149e00ca	2026-09-04	PRESENT	2026-09-04 06:12:00+07	2026-09-04 14:00:00+07	f	12	0	0	0	3a5de69c-b61e-42bd-aea3-f49ff3c5e654	2026-10-04 22:58:59.345+07
5572c008-8df4-44d9-a4bd-0c2d5558b19f	23230ce1-1ab7-4b49-b9b2-404f149e00ca	2026-09-05	OFFDAY	\N	\N	f	0	0	0	0	3a5de69c-b61e-42bd-aea3-f49ff3c5e654	2026-10-04 22:58:59.345+07
1881f321-f14b-4184-9942-6384975fe22c	23230ce1-1ab7-4b49-b9b2-404f149e00ca	2026-09-06	OFFDAY	\N	\N	f	0	0	0	0	3a5de69c-b61e-42bd-aea3-f49ff3c5e654	2026-10-04 22:58:59.345+07
8c9ca5dc-430a-4dc7-b975-397ce4c840d2	23230ce1-1ab7-4b49-b9b2-404f149e00ca	2026-09-07	PRESENT	2026-09-07 05:58:00+07	2026-09-07 14:00:00+07	f	0	0	0	0	3a5de69c-b61e-42bd-aea3-f49ff3c5e654	2026-10-04 22:58:59.345+07
b394adfd-0be4-468c-b9a4-ffe95045eec7	23230ce1-1ab7-4b49-b9b2-404f149e00ca	2026-09-08	PRESENT	2026-09-08 05:58:00+07	2026-09-08 14:00:00+07	f	0	0	0	0	3a5de69c-b61e-42bd-aea3-f49ff3c5e654	2026-10-04 22:58:59.345+07
96072ccc-d363-479b-b409-c20c18eeb6b9	23230ce1-1ab7-4b49-b9b2-404f149e00ca	2026-09-09	PRESENT	2026-09-09 05:58:00+07	2026-09-09 14:00:00+07	f	0	0	0	0	3a5de69c-b61e-42bd-aea3-f49ff3c5e654	2026-10-04 22:58:59.345+07
17ba7886-f2bb-44a0-93c2-8c60ef178dec	23230ce1-1ab7-4b49-b9b2-404f149e00ca	2026-09-10	LATE	2026-09-10 06:20:00+07	2026-09-10 14:00:00+07	t	20	0	0	0	3a5de69c-b61e-42bd-aea3-f49ff3c5e654	2026-10-04 22:58:59.345+07
c9fdc7a8-3be1-479d-9146-351d2abb377a	23230ce1-1ab7-4b49-b9b2-404f149e00ca	2026-09-11	PRESENT	2026-09-11 05:58:00+07	2026-09-11 14:00:00+07	f	0	0	0	0	3a5de69c-b61e-42bd-aea3-f49ff3c5e654	2026-10-04 22:58:59.345+07
fe8d0ebe-072a-4058-b7fe-4bd387662c1b	23230ce1-1ab7-4b49-b9b2-404f149e00ca	2026-09-12	OFFDAY	\N	\N	f	0	0	0	0	3a5de69c-b61e-42bd-aea3-f49ff3c5e654	2026-10-04 22:58:59.345+07
02592694-37f6-4a92-94f3-0eeffcd46f62	23230ce1-1ab7-4b49-b9b2-404f149e00ca	2026-09-13	OFFDAY	\N	\N	f	0	0	0	0	3a5de69c-b61e-42bd-aea3-f49ff3c5e654	2026-10-04 22:58:59.345+07
7cba6cea-7c3e-4452-a104-732b27595d41	23230ce1-1ab7-4b49-b9b2-404f149e00ca	2026-09-14	PRESENT	2026-09-14 05:58:00+07	2026-09-14 14:00:00+07	f	0	0	0	0	3a5de69c-b61e-42bd-aea3-f49ff3c5e654	2026-10-04 22:58:59.345+07
378d821b-ae66-4f9a-bcad-babcef5f94a4	23230ce1-1ab7-4b49-b9b2-404f149e00ca	2026-09-15	PRESENT	2026-09-15 05:58:00+07	2026-09-15 14:00:00+07	f	0	0	0	0	3a5de69c-b61e-42bd-aea3-f49ff3c5e654	2026-10-04 22:58:59.345+07
5cf9d227-1806-4aad-95ed-fb0b1b2f46fd	0c685448-b52e-4e60-89ea-6f7c500a86d5	2026-09-24	PRESENT	2026-09-24 15:55:00+07	2026-09-25 00:10:00+07	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.781+07
1f369908-3a6a-4766-87bf-ca9e6899f30e	0c685448-b52e-4e60-89ea-6f7c500a86d5	2026-09-25	PRESENT	2026-09-25 16:00:00+07	2026-09-26 00:15:00+07	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.781+07
3765ff95-2a77-4e5d-a142-4e02d96d67de	0c685448-b52e-4e60-89ea-6f7c500a86d5	2026-09-26	OFFDAY	\N	\N	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.781+07
6b6575fc-5652-4f79-902d-3c8c7f5ab3d7	0c685448-b52e-4e60-89ea-6f7c500a86d5	2026-09-18	PRESENT	2026-09-18 15:50:00+07	2026-09-19 00:05:00+07	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.781+07
86cf3ba8-8105-43c6-8852-fa807f3e03c1	0c685448-b52e-4e60-89ea-6f7c500a86d5	2026-09-19	OFFDAY	\N	\N	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.781+07
840f068b-d2fa-457c-aa0f-ae71b07c407d	0c685448-b52e-4e60-89ea-6f7c500a86d5	2026-09-20	OFFDAY	\N	\N	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.781+07
877c40ce-d022-49a9-ac47-d22dd78f2ea7	0c685448-b52e-4e60-89ea-6f7c500a86d5	2026-09-21	PRESENT	2026-09-21 15:55:00+07	2026-09-22 00:10:00+07	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.781+07
735c1ceb-9744-4cda-8dbc-e37ce4dc7748	0c685448-b52e-4e60-89ea-6f7c500a86d5	2026-09-22	PRESENT	2026-09-22 16:00:00+07	2026-09-23 00:15:00+07	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.781+07
b9597c79-2949-4a66-8c71-85bec0f3d02c	0c685448-b52e-4e60-89ea-6f7c500a86d5	2026-09-23	PRESENT	2026-09-23 15:50:00+07	2026-09-24 00:05:00+07	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.781+07
d166e7d3-1b83-41c5-8ff3-e3b89516cb70	0c685448-b52e-4e60-89ea-6f7c500a86d5	2026-09-27	OFFDAY	\N	\N	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.781+07
4ced35aa-2165-4ccd-94de-97656bc9041d	0c685448-b52e-4e60-89ea-6f7c500a86d5	2026-09-28	PRESENT	2026-09-28 15:50:00+07	2026-09-29 00:05:00+07	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.781+07
6802fb47-bf44-4fbf-93c7-2469411d7369	0c685448-b52e-4e60-89ea-6f7c500a86d5	2026-09-29	PRESENT	2026-09-29 15:55:00+07	2026-09-30 00:10:00+07	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.781+07
ea9c0959-8a5b-41eb-b13b-e4b3dedaf70b	0c685448-b52e-4e60-89ea-6f7c500a86d5	2026-09-30	PRESENT	2026-09-30 16:00:00+07	2026-10-01 00:15:00+07	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.781+07
0126f41a-3e99-4f78-89af-c30afce29121	b7291f79-3495-44a5-b039-737465dc2cc0	2026-09-04	PRESENT	2026-09-04 08:00:00+07	2026-09-04 16:00:00+07	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.383+07
e9c4504d-9d5b-4a94-9f81-5548119c94bb	b7291f79-3495-44a5-b039-737465dc2cc0	2026-09-05	OFFDAY	\N	\N	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.383+07
7701a40c-830d-44b8-baee-51ff930de951	b7291f79-3495-44a5-b039-737465dc2cc0	2026-09-06	PRESENT	2026-09-06 10:00:00+07	2026-09-06 14:00:00+07	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.383+07
3697c1c0-135f-4cc0-ba7e-c5aafc77af22	b7291f79-3495-44a5-b039-737465dc2cc0	2026-09-07	PRESENT	2026-09-07 08:00:00+07	2026-09-07 19:30:00+07	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.383+07
17f98c52-111d-4c1f-999b-1d663a01c728	b7291f79-3495-44a5-b039-737465dc2cc0	2026-09-08	PRESENT	2026-09-08 08:00:00+07	2026-09-08 16:00:00+07	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.383+07
2db140f0-b8d0-4ac9-a8b9-ba4d5e84ad0f	b7291f79-3495-44a5-b039-737465dc2cc0	2026-09-09	PRESENT	2026-09-09 08:00:00+07	2026-09-09 16:00:00+07	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.383+07
c41cddd5-adcb-41b1-93e4-d543c0bd920e	b7291f79-3495-44a5-b039-737465dc2cc0	2026-09-10	PRESENT	2026-09-10 08:00:00+07	2026-09-10 16:00:00+07	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.383+07
563b985f-a0f0-4950-b649-587110d80df7	b7291f79-3495-44a5-b039-737465dc2cc0	2026-09-11	PRESENT	2026-09-11 08:00:00+07	2026-09-11 19:30:00+07	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.383+07
44191e33-d6ad-4f56-b249-88c420db82ee	b7291f79-3495-44a5-b039-737465dc2cc0	2026-09-12	OFFDAY	2026-09-12 09:00:00+07	2026-09-12 13:00:00+07	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.383+07
4ff69d41-3677-485e-9e0f-df2195aba34c	b7291f79-3495-44a5-b039-737465dc2cc0	2026-09-13	OFFDAY	\N	\N	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.383+07
c602877f-131b-49c9-830f-b6b9a3e1c85f	b7291f79-3495-44a5-b039-737465dc2cc0	2026-09-14	PRESENT	2026-09-14 08:00:00+07	2026-09-14 16:00:00+07	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.383+07
21d948f6-0c19-495f-8854-aff64e0ab54e	b7291f79-3495-44a5-b039-737465dc2cc0	2026-09-15	PRESENT	2026-09-15 08:00:00+07	2026-09-15 16:00:00+07	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.383+07
3b0bcb51-d813-4e2d-8e2b-771860e137c2	b7291f79-3495-44a5-b039-737465dc2cc0	2026-09-16	HOLIDAY	\N	\N	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.383+07
e2d014dd-c14d-4ef0-9665-5e7a7798f613	b7291f79-3495-44a5-b039-737465dc2cc0	2026-09-17	PRESENT	2026-09-17 08:00:00+07	2026-09-17 16:00:00+07	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.383+07
bf72756f-4bb8-486d-b6c8-5fc0a6cfb94a	b7291f79-3495-44a5-b039-737465dc2cc0	2026-09-18	PRESENT	2026-09-18 08:00:00+07	2026-09-18 19:30:00+07	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.383+07
c1ee8574-e7ee-4ca4-9a8c-09cb2bf15b80	b7291f79-3495-44a5-b039-737465dc2cc0	2026-09-19	OFFDAY	2026-09-19 09:00:00+07	2026-09-19 13:00:00+07	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.383+07
a358a4a4-64c9-486a-bbce-cfb4b1be57ac	b7291f79-3495-44a5-b039-737465dc2cc0	2026-09-20	OFFDAY	\N	\N	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.383+07
874ce850-7e32-4fc7-95c5-631356508b34	b7291f79-3495-44a5-b039-737465dc2cc0	2026-09-21	PRESENT	2026-09-21 08:00:00+07	2026-09-21 16:00:00+07	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.383+07
c8f10dd4-1303-491d-9e31-c6df84bfdcfc	b7291f79-3495-44a5-b039-737465dc2cc0	2026-09-22	PRESENT	2026-09-22 08:00:00+07	2026-09-22 16:00:00+07	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.383+07
f7d9ef77-faa0-47cf-95ed-a6115a4dba4f	b7291f79-3495-44a5-b039-737465dc2cc0	2026-09-23	PRESENT	2026-09-23 08:00:00+07	2026-09-23 16:00:00+07	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.383+07
394357f7-6b6e-459e-b9f5-165c5d40c8ca	b7291f79-3495-44a5-b039-737465dc2cc0	2026-09-24	PRESENT	2026-09-24 08:00:00+07	2026-09-24 19:30:00+07	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.383+07
0e5e31d6-ed99-45d0-9714-a884d3b772e6	b7291f79-3495-44a5-b039-737465dc2cc0	2026-09-26	OFFDAY	\N	\N	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.383+07
c613d55f-4d36-47e4-99b3-c02a8a43e81b	b7291f79-3495-44a5-b039-737465dc2cc0	2026-09-27	OFFDAY	\N	\N	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.383+07
ecf1822f-a570-45d8-a3d3-ec726dddebef	b7291f79-3495-44a5-b039-737465dc2cc0	2026-09-28	PRESENT	2026-09-28 08:00:00+07	2026-09-28 16:00:00+07	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.383+07
1c81bd19-a7af-4ce7-9a72-8088c77ab0c7	b7291f79-3495-44a5-b039-737465dc2cc0	2026-09-29	PRESENT	2026-09-29 08:00:00+07	2026-09-29 16:00:00+07	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.383+07
fe4934ed-4423-48c8-85e5-c4841fb4e2b4	b7291f79-3495-44a5-b039-737465dc2cc0	2026-09-30	PRESENT	2026-09-30 08:00:00+07	2026-09-30 19:30:00+07	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.383+07
a3ebf730-39a1-4000-8433-86924f0031c1	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	2026-09-01	PRESENT	2026-09-01 07:55:00+07	2026-09-01 16:00:00+07	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.861+07
7f390cc9-6824-440d-8f55-98cb4a0f751f	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	2026-09-02	PRESENT	2026-09-02 07:59:00+07	2026-09-02 16:00:00+07	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.861+07
14f1f8bd-416d-4128-a55e-e6531848abc8	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	2026-09-03	PRESENT	2026-09-03 08:03:00+07	2026-09-03 16:00:00+07	f	3	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.861+07
c0d9272e-4362-472f-a13b-41d3bb869ebf	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	2026-09-04	PRESENT	2026-09-04 07:55:00+07	2026-09-04 16:00:00+07	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.861+07
eeb673a5-5542-4f75-b0b5-c1ebcb5c8d9f	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	2026-09-05	OFFDAY	\N	\N	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.861+07
71942d25-38f0-4de0-b323-d6b028728fa3	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	2026-09-06	OFFDAY	\N	\N	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.861+07
889cf002-1e0a-4640-b2e1-65828fcf3b8b	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	2026-09-07	PRESENT	2026-09-07 07:59:00+07	2026-09-07 16:00:00+07	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.861+07
f0845f60-afd3-4e65-8afb-699ed1ba3e20	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	2026-09-08	PRESENT	2026-09-08 08:03:00+07	2026-09-08 16:00:00+07	f	3	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.861+07
4b930888-4a49-4147-bc9f-b120672a42b4	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	2026-09-09	PRESENT	2026-09-09 07:55:00+07	2026-09-09 16:00:00+07	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.861+07
03f7e4ed-e645-4bfe-bd22-40ecb293eccd	b7291f79-3495-44a5-b039-737465dc2cc0	2026-09-02	PRESENT	2026-09-02 08:00:00+07	2026-09-02 16:00:00+07	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.383+07
a2de4ff3-e8fc-4f2f-99f1-909696dfc374	b7291f79-3495-44a5-b039-737465dc2cc0	2026-09-03	PRESENT	2026-09-03 08:00:00+07	2026-09-03 16:00:00+07	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.383+07
1374d332-a6d6-4d86-993d-eb178e82b7d4	3193d9a5-6017-4441-b40c-f22e9ec9b867	2026-09-05	OFFDAY	\N	\N	f	0	0	0	0	a0e0efc8-d1de-4d31-82a1-483eb53530de	2026-10-04 23:23:55.295+07
509aaded-dcf4-47f4-953c-9e5c91d67755	3193d9a5-6017-4441-b40c-f22e9ec9b867	2026-09-06	OFFDAY	\N	\N	f	0	0	0	0	a0e0efc8-d1de-4d31-82a1-483eb53530de	2026-10-04 23:23:55.295+07
1fed3d31-1e3a-4a60-a96f-77822773b353	3193d9a5-6017-4441-b40c-f22e9ec9b867	2026-09-07	PRESENT	2026-09-07 21:00:00+07	2026-09-08 05:05:00+07	f	0	0	0	0	a0e0efc8-d1de-4d31-82a1-483eb53530de	2026-10-04 23:23:55.295+07
081852d6-9242-494a-88a0-401e4ab5683d	3193d9a5-6017-4441-b40c-f22e9ec9b867	2026-09-08	PRESENT	2026-09-08 21:05:00+07	2026-09-09 05:05:00+07	f	5	0	0	0	a0e0efc8-d1de-4d31-82a1-483eb53530de	2026-10-04 23:23:55.295+07
16c836f2-93e9-471a-8de7-1c8439a75168	3193d9a5-6017-4441-b40c-f22e9ec9b867	2026-09-09	PRESENT	2026-09-09 20:55:00+07	2026-09-10 05:05:00+07	f	0	0	0	0	a0e0efc8-d1de-4d31-82a1-483eb53530de	2026-10-04 23:23:55.295+07
660a2475-859e-4347-9f38-be6e0747b45f	3193d9a5-6017-4441-b40c-f22e9ec9b867	2026-09-10	LATE	2026-09-10 21:20:00+07	2026-09-11 05:05:00+07	t	20	0	0	0	a0e0efc8-d1de-4d31-82a1-483eb53530de	2026-10-04 23:23:55.295+07
82d18df0-2b98-47a3-8db1-a0b42da2ccab	3193d9a5-6017-4441-b40c-f22e9ec9b867	2026-09-11	PRESENT	2026-09-11 21:05:00+07	2026-09-12 05:05:00+07	f	5	0	0	0	a0e0efc8-d1de-4d31-82a1-483eb53530de	2026-10-04 23:23:55.295+07
196f4294-9884-4d77-ae36-da6e5bcd3546	3193d9a5-6017-4441-b40c-f22e9ec9b867	2026-09-12	OFFDAY	\N	\N	f	0	0	0	0	a0e0efc8-d1de-4d31-82a1-483eb53530de	2026-10-04 23:23:55.295+07
4cfb9003-c6ab-4755-8fcd-7b4c62e8d420	3193d9a5-6017-4441-b40c-f22e9ec9b867	2026-09-13	OFFDAY	\N	\N	f	0	0	0	0	a0e0efc8-d1de-4d31-82a1-483eb53530de	2026-10-04 23:23:55.295+07
db302e73-4e28-4504-a4dc-6522dbd06ed4	3193d9a5-6017-4441-b40c-f22e9ec9b867	2026-09-14	PRESENT	2026-09-14 20:55:00+07	2026-09-15 05:05:00+07	f	0	0	0	0	a0e0efc8-d1de-4d31-82a1-483eb53530de	2026-10-04 23:23:55.295+07
f0373def-5e72-4666-a889-0f51d402d8d2	3193d9a5-6017-4441-b40c-f22e9ec9b867	2026-09-15	PRESENT	2026-09-15 21:00:00+07	2026-09-16 05:05:00+07	f	0	0	0	0	a0e0efc8-d1de-4d31-82a1-483eb53530de	2026-10-04 23:23:55.295+07
558efac0-4cec-4809-b825-62d6cf75d3e8	3193d9a5-6017-4441-b40c-f22e9ec9b867	2026-09-16	HOLIDAY	\N	\N	f	0	0	0	0	a0e0efc8-d1de-4d31-82a1-483eb53530de	2026-10-04 23:23:55.295+07
e28d1099-2042-40e9-ad4c-5bfe3f5d1b34	3193d9a5-6017-4441-b40c-f22e9ec9b867	2026-09-17	PRESENT	2026-09-17 21:05:00+07	2026-09-18 05:05:00+07	f	5	0	0	0	a0e0efc8-d1de-4d31-82a1-483eb53530de	2026-10-04 23:23:55.295+07
c52e039b-d7c8-4972-9593-c8916d86f085	3193d9a5-6017-4441-b40c-f22e9ec9b867	2026-09-18	PRESENT	2026-09-18 20:55:00+07	2026-09-19 05:05:00+07	f	0	0	0	0	a0e0efc8-d1de-4d31-82a1-483eb53530de	2026-10-04 23:23:55.295+07
fb4df9d8-d42a-4b74-9e77-8825e0035d8c	3193d9a5-6017-4441-b40c-f22e9ec9b867	2026-09-19	OFFDAY	\N	\N	f	0	0	0	0	a0e0efc8-d1de-4d31-82a1-483eb53530de	2026-10-04 23:23:55.295+07
6bd6e795-2645-45b9-a659-11a2d85c256f	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	2026-09-10	PRESENT	2026-09-10 07:59:00+07	2026-09-10 16:00:00+07	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.861+07
75e754c3-3684-4de2-bf64-843fd146d740	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	2026-09-11	PRESENT	2026-09-11 08:03:00+07	2026-09-11 16:00:00+07	f	3	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.861+07
598fc69e-7c8b-437f-851a-c10b7b3b874d	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	2026-09-12	OFFDAY	\N	\N	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.861+07
bc895bfd-391d-4353-bcf3-316320e0132b	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	2026-09-13	OFFDAY	\N	\N	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.861+07
a74d00e1-463f-4410-b8a0-2a24e1eceaa7	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	2026-09-14	PRESENT	2026-09-14 07:55:00+07	2026-09-14 16:00:00+07	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.861+07
d09a8ca9-ff0a-423d-8d8c-d2a11a4a732a	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	2026-09-15	PRESENT	2026-09-15 07:59:00+07	2026-09-15 16:00:00+07	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.861+07
62948157-74bc-4870-911f-8acb283f553b	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	2026-09-16	HOLIDAY	\N	\N	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.861+07
1fd7b2af-793b-4142-95eb-ff3cfabcd750	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	2026-09-17	PRESENT	2026-09-17 08:03:00+07	2026-09-17 16:00:00+07	f	3	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.861+07
6c203373-78dd-4684-9942-f4fefef9fdc2	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	2026-09-18	PRESENT	2026-09-18 07:55:00+07	2026-09-18 16:00:00+07	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.861+07
063684a2-cd8e-4298-8259-06bd9add15c0	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	2026-09-19	OFFDAY	\N	\N	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.861+07
982ccb9f-c530-4c77-81ca-843ce52d82b8	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	2026-09-20	OFFDAY	\N	\N	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.861+07
bc43dfeb-7591-4ca8-96cd-de16c37ca60d	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	2026-09-21	PRESENT	2026-09-21 07:59:00+07	2026-09-21 16:00:00+07	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.861+07
ac49d0c7-f4bd-45e0-811b-552157cc567e	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	2026-09-22	PRESENT	2026-09-22 08:03:00+07	2026-09-22 16:00:00+07	f	3	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.861+07
a4d73f2c-0286-40f5-b2e0-98731ec9d6f5	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	2026-09-23	PRESENT	2026-09-23 07:55:00+07	2026-09-23 16:00:00+07	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.861+07
8e6a811a-d0be-4328-b76f-a4c8d8c2ee25	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	2026-09-24	PRESENT	2026-09-24 07:59:00+07	2026-09-24 16:00:00+07	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.861+07
4baff0ad-b7f9-4b9c-a8f2-4a1e4283e1f2	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	2026-09-25	PRESENT	2026-09-25 08:03:00+07	2026-09-25 16:00:00+07	f	3	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.861+07
342c901d-c794-4222-87ec-e3752f00416f	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	2026-09-26	OFFDAY	\N	\N	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.861+07
80010a75-6d5f-4629-ba8e-056a70b7714b	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	2026-09-27	OFFDAY	\N	\N	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.861+07
8138db12-3b3b-425b-a93a-763e5996eb6f	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	2026-09-28	PRESENT	2026-09-28 07:55:00+07	2026-09-28 16:00:00+07	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.861+07
6f73fcd1-1611-4eca-83b2-184922e6ca10	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	2026-09-29	PRESENT	2026-09-29 07:59:00+07	2026-09-29 16:00:00+07	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.861+07
4364a755-a55b-46e9-9c6e-5399bd144ec0	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	2026-09-30	PRESENT	2026-09-30 08:03:00+07	2026-09-30 16:00:00+07	f	3	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.861+07
f7fa62bf-1674-45f6-90f9-a3b9f7edb05e	3193d9a5-6017-4441-b40c-f22e9ec9b867	2026-09-03	PRESENT	2026-09-03 21:05:00+07	2026-09-04 05:05:00+07	f	5	0	0	0	a0e0efc8-d1de-4d31-82a1-483eb53530de	2026-10-04 23:23:55.295+07
669972ac-7000-4ec7-9d8f-b5d97ec3c2b7	3193d9a5-6017-4441-b40c-f22e9ec9b867	2026-09-04	PRESENT	2026-09-04 20:55:00+07	2026-09-05 05:05:00+07	f	0	0	0	0	a0e0efc8-d1de-4d31-82a1-483eb53530de	2026-10-04 23:23:55.295+07
6dac2cb4-ec81-404a-94e1-7983c2403fc2	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	2026-09-03	PRESENT	2026-09-03 06:58:00+07	2026-09-03 15:02:00+07	f	0	0	0	0	a0e0efc8-d1de-4d31-82a1-483eb53530de	2026-10-04 23:23:55.161+07
9c27b69b-f7f2-4c01-b21f-d5c80d618e7c	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	2026-09-04	PRESENT	2026-09-04 06:58:00+07	2026-09-04 15:02:00+07	f	0	0	0	0	a0e0efc8-d1de-4d31-82a1-483eb53530de	2026-10-04 23:23:55.161+07
875b1f55-9a8b-4e0b-ace0-82ca86feec89	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	2026-09-05	OFFDAY	\N	\N	f	0	0	0	0	a0e0efc8-d1de-4d31-82a1-483eb53530de	2026-10-04 23:23:55.161+07
6e26d43a-9b43-456a-9575-fe3c7d116110	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	2026-09-06	OFFDAY	\N	\N	f	0	0	0	0	a0e0efc8-d1de-4d31-82a1-483eb53530de	2026-10-04 23:23:55.161+07
9619def0-588b-4089-93d8-2916df541735	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	2026-09-07	PRESENT	2026-09-07 06:58:00+07	2026-09-07 15:02:00+07	f	0	0	0	0	a0e0efc8-d1de-4d31-82a1-483eb53530de	2026-10-04 23:23:55.161+07
055ddc9b-ede1-4dee-a2b1-675f4fafb1ee	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	2026-09-08	PRESENT	2026-09-08 06:58:00+07	2026-09-08 15:02:00+07	f	0	0	0	0	a0e0efc8-d1de-4d31-82a1-483eb53530de	2026-10-04 23:23:55.161+07
664bd061-c0d2-4b72-b6b4-51a492e61c26	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	2026-09-09	PRESENT	2026-09-09 06:58:00+07	2026-09-09 15:02:00+07	f	0	0	0	0	a0e0efc8-d1de-4d31-82a1-483eb53530de	2026-10-04 23:23:55.161+07
11695e47-6bd7-4a66-bb9c-61c5f865a6f7	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	2026-09-10	PRESENT	2026-09-10 06:58:00+07	2026-09-10 15:02:00+07	f	0	0	0	0	a0e0efc8-d1de-4d31-82a1-483eb53530de	2026-10-04 23:23:55.161+07
cdb36bee-5a8d-44b6-8eff-b717322500b3	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	2026-09-11	PRESENT	2026-09-11 06:58:00+07	2026-09-11 15:02:00+07	f	0	0	0	0	a0e0efc8-d1de-4d31-82a1-483eb53530de	2026-10-04 23:23:55.161+07
b2c554e2-8e76-473d-b677-2b9197495103	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	2026-09-12	OFFDAY	\N	\N	f	0	0	0	0	a0e0efc8-d1de-4d31-82a1-483eb53530de	2026-10-04 23:23:55.161+07
51021a76-8f52-4ba3-921c-23e2fa4a080b	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	2026-09-13	OFFDAY	\N	\N	f	0	0	0	0	a0e0efc8-d1de-4d31-82a1-483eb53530de	2026-10-04 23:23:55.161+07
f67d1c4f-ca63-44b3-a436-be4d7a373de2	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	2026-09-14	PRESENT	2026-09-14 06:58:00+07	2026-09-14 15:02:00+07	f	0	0	0	0	a0e0efc8-d1de-4d31-82a1-483eb53530de	2026-10-04 23:23:55.161+07
73918648-fa3b-4fc1-a000-96c993e29438	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	2026-09-15	PRESENT	2026-09-15 06:58:00+07	2026-09-15 15:02:00+07	f	0	0	0	0	a0e0efc8-d1de-4d31-82a1-483eb53530de	2026-10-04 23:23:55.161+07
2876438e-f95e-47a4-bf5b-652ba55a8205	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	2026-09-16	HOLIDAY	\N	\N	f	0	0	0	0	a0e0efc8-d1de-4d31-82a1-483eb53530de	2026-10-04 23:23:55.161+07
56a847b5-7154-42b4-91e9-a8147b1fb30d	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	2026-09-17	PRESENT	2026-09-17 06:58:00+07	2026-09-17 15:02:00+07	f	0	0	0	0	a0e0efc8-d1de-4d31-82a1-483eb53530de	2026-10-04 23:23:55.161+07
e72b82e2-40a1-48ef-b78b-6547e2551877	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	2026-09-18	PRESENT	2026-09-18 06:58:00+07	2026-09-18 15:02:00+07	f	0	0	0	0	a0e0efc8-d1de-4d31-82a1-483eb53530de	2026-10-04 23:23:55.161+07
8f776f4b-601b-495a-9285-674d25df368f	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	2026-09-19	OFFDAY	\N	\N	f	0	0	0	0	a0e0efc8-d1de-4d31-82a1-483eb53530de	2026-10-04 23:23:55.161+07
c96f2f9a-864c-41f4-aa17-69b85ceacc09	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	2026-09-20	OFFDAY	\N	\N	f	0	0	0	0	a0e0efc8-d1de-4d31-82a1-483eb53530de	2026-10-04 23:23:55.161+07
b4dda624-0d16-484d-b4dd-d129845d40af	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	2026-09-21	PRESENT	2026-09-21 06:58:00+07	2026-09-21 15:02:00+07	f	0	0	0	0	a0e0efc8-d1de-4d31-82a1-483eb53530de	2026-10-04 23:23:55.161+07
3abb5063-1eb7-4bc0-953e-d6ae794ee45b	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	2026-09-22	HOLIDAY	\N	\N	f	0	0	0	0	a0e0efc8-d1de-4d31-82a1-483eb53530de	2026-10-04 23:23:55.161+07
99b55f59-8501-4675-a2fb-606e789600c1	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	2026-09-23	PRESENT	2026-09-23 06:58:00+07	2026-09-23 15:02:00+07	f	0	0	0	0	a0e0efc8-d1de-4d31-82a1-483eb53530de	2026-10-04 23:23:55.161+07
a8dbba19-44eb-41e9-9ff0-862c9ab42f14	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	2026-09-24	PRESENT	2026-09-24 06:58:00+07	2026-09-24 15:02:00+07	f	0	0	0	0	a0e0efc8-d1de-4d31-82a1-483eb53530de	2026-10-04 23:23:55.161+07
3aa2f6ba-6a72-4137-af71-19eb959acc5b	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	2026-09-25	PRESENT	2026-09-25 06:58:00+07	2026-09-25 15:02:00+07	f	0	0	0	0	a0e0efc8-d1de-4d31-82a1-483eb53530de	2026-10-04 23:23:55.161+07
86b04b78-e56c-4e4a-aee2-28da76b9cfb8	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	2026-09-26	OFFDAY	\N	\N	f	0	0	0	0	a0e0efc8-d1de-4d31-82a1-483eb53530de	2026-10-04 23:23:55.161+07
ed53183f-42ec-43d2-b32a-5efb5057c60c	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	2026-09-27	OFFDAY	\N	\N	f	0	0	0	0	a0e0efc8-d1de-4d31-82a1-483eb53530de	2026-10-04 23:23:55.161+07
f4fa7919-e50e-4165-a148-1fccfa30199a	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	2026-09-28	PRESENT	2026-09-28 06:58:00+07	2026-09-28 15:02:00+07	f	0	0	0	0	a0e0efc8-d1de-4d31-82a1-483eb53530de	2026-10-04 23:23:55.161+07
6f6a2751-a9d0-47bb-944b-f115054ad468	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	2026-09-29	PRESENT	2026-09-29 06:58:00+07	2026-09-29 15:02:00+07	f	0	0	0	0	a0e0efc8-d1de-4d31-82a1-483eb53530de	2026-10-04 23:23:55.161+07
6dac7ae1-e7a1-4a68-a79f-901e13d7fa8d	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	2026-09-30	PRESENT	2026-09-30 06:58:00+07	2026-09-30 15:02:00+07	f	0	0	0	0	a0e0efc8-d1de-4d31-82a1-483eb53530de	2026-10-04 23:23:55.161+07
697c2017-dd74-4e39-b993-f99dfaf12c20	3193d9a5-6017-4441-b40c-f22e9ec9b867	2026-09-01	PRESENT	2026-09-01 20:55:00+07	2026-09-02 05:05:00+07	f	0	0	0	0	a0e0efc8-d1de-4d31-82a1-483eb53530de	2026-10-04 23:23:55.295+07
ec3b299f-7539-4e1f-8362-08fff45bcc5f	3193d9a5-6017-4441-b40c-f22e9ec9b867	2026-09-02	PRESENT	2026-09-02 21:00:00+07	2026-09-03 05:05:00+07	f	0	0	0	0	a0e0efc8-d1de-4d31-82a1-483eb53530de	2026-10-04 23:23:55.295+07
c56ad59a-1a10-42a0-82ef-b868202e71bc	6a65b903-7cb2-468b-8245-a607e73baa54	2026-09-21	PRESENT	2026-09-21 07:55:00+07	2026-09-21 16:15:00+07	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.474+07
ec7b4e94-f90f-46cc-8d5d-4b47549df932	4478787b-c3e8-4f0d-8b9b-7046fec7f539	2026-09-03	PRESENT	2026-09-03 08:06:00+07	2026-09-03 16:10:00+07	f	6	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.634+07
f28a46c2-9e6e-4835-9245-bc8b4d73147b	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	2026-09-02	PRESENT	2026-09-02 06:58:00+07	2026-09-02 15:02:00+07	f	0	0	0	0	a0e0efc8-d1de-4d31-82a1-483eb53530de	2026-10-04 23:23:55.161+07
72dab54b-68fa-4d7e-9304-49bbacddc409	6a65b903-7cb2-468b-8245-a607e73baa54	2026-09-18	PRESENT	2026-09-18 07:50:00+07	2026-09-18 16:00:00+07	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.474+07
33077249-54d0-46d8-b03e-56d734b856d1	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	2026-09-01	PRESENT	2026-09-01 06:58:00+07	2026-09-01 15:02:00+07	f	0	0	0	0	a0e0efc8-d1de-4d31-82a1-483eb53530de	2026-10-04 23:23:55.161+07
f97970ec-c2a3-4822-9ec3-054a56e7e18a	0cd6bde6-3226-4ebb-b135-ca522d42efa4	2026-09-08	ON_LEAVE	\N	\N	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.71+07
e137d0f1-ce5a-4a1e-9400-7a568fd7e172	0cd6bde6-3226-4ebb-b135-ca522d42efa4	2026-09-22	PRESENT	2026-09-22 07:55:00+07	2026-09-22 16:05:00+07	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.71+07
c47dc15d-65a8-436c-9457-3d78c4d037ac	3193d9a5-6017-4441-b40c-f22e9ec9b867	2026-09-20	OFFDAY	\N	\N	f	0	0	0	0	a0e0efc8-d1de-4d31-82a1-483eb53530de	2026-10-04 23:23:55.295+07
f87c2107-5a84-4f89-9df1-251571d0fdd2	3193d9a5-6017-4441-b40c-f22e9ec9b867	2026-09-21	PRESENT	2026-09-21 21:00:00+07	2026-09-22 05:05:00+07	f	0	0	0	0	a0e0efc8-d1de-4d31-82a1-483eb53530de	2026-10-04 23:23:55.295+07
3b1830df-cfbc-4261-869f-523ef2bd02b6	3193d9a5-6017-4441-b40c-f22e9ec9b867	2026-09-22	HOLIDAY	\N	\N	f	0	0	0	0	a0e0efc8-d1de-4d31-82a1-483eb53530de	2026-10-04 23:23:55.295+07
da78d6d3-b8dd-4509-81d8-9bfecd352ee9	3193d9a5-6017-4441-b40c-f22e9ec9b867	2026-09-23	PRESENT	2026-09-23 21:05:00+07	2026-09-24 05:05:00+07	f	5	0	0	0	a0e0efc8-d1de-4d31-82a1-483eb53530de	2026-10-04 23:23:55.295+07
0f29e55c-bdb7-430f-bb75-8c58467ee7f8	3193d9a5-6017-4441-b40c-f22e9ec9b867	2026-09-24	PRESENT	2026-09-24 20:55:00+07	2026-09-25 05:05:00+07	f	0	0	0	0	a0e0efc8-d1de-4d31-82a1-483eb53530de	2026-10-04 23:23:55.295+07
89ebdae2-30fb-4480-a39c-f854f21f47c9	3193d9a5-6017-4441-b40c-f22e9ec9b867	2026-09-25	PRESENT	2026-09-25 21:00:00+07	2026-09-26 05:05:00+07	f	0	0	0	0	a0e0efc8-d1de-4d31-82a1-483eb53530de	2026-10-04 23:23:55.295+07
70734058-2d69-458d-98c4-066776538150	3193d9a5-6017-4441-b40c-f22e9ec9b867	2026-09-26	OFFDAY	\N	\N	f	0	0	0	0	a0e0efc8-d1de-4d31-82a1-483eb53530de	2026-10-04 23:23:55.295+07
00ce4676-f495-429b-bd9b-1dc10a37b3bb	3193d9a5-6017-4441-b40c-f22e9ec9b867	2026-09-27	OFFDAY	\N	\N	f	0	0	0	0	a0e0efc8-d1de-4d31-82a1-483eb53530de	2026-10-04 23:23:55.295+07
b0f5a070-10a3-4ec2-b7b7-115275df3517	3193d9a5-6017-4441-b40c-f22e9ec9b867	2026-09-28	PRESENT	2026-09-28 21:05:00+07	2026-09-29 05:05:00+07	f	5	0	0	0	a0e0efc8-d1de-4d31-82a1-483eb53530de	2026-10-04 23:23:55.295+07
f28d6165-adf2-40e5-acc1-9b3f0190cb1c	3193d9a5-6017-4441-b40c-f22e9ec9b867	2026-09-29	PRESENT	2026-09-29 20:55:00+07	2026-09-30 05:05:00+07	f	0	0	0	0	a0e0efc8-d1de-4d31-82a1-483eb53530de	2026-10-04 23:23:55.295+07
84757a4a-4bbc-4eaa-9b12-c08044be4f0a	3193d9a5-6017-4441-b40c-f22e9ec9b867	2026-09-30	PRESENT	2026-09-30 21:00:00+07	2026-10-01 05:05:00+07	f	0	0	0	0	a0e0efc8-d1de-4d31-82a1-483eb53530de	2026-10-04 23:23:55.295+07
67635b21-5fc9-47eb-834a-223ea599fe43	b7291f79-3495-44a5-b039-737465dc2cc0	2026-09-01	PRESENT	2026-09-01 08:00:00+07	2026-09-01 19:30:00+07	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.383+07
faab3f27-de4b-4551-96c3-f6fe62f1c64b	b7291f79-3495-44a5-b039-737465dc2cc0	2026-09-25	PRESENT	2026-09-25 08:00:00+07	2026-09-25 16:00:00+07	f	0	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.383+07
b22afcd4-709d-4898-abb0-a506d3840a93	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	2026-09-28	LATE	2026-09-28 08:25:00+07	2026-09-28 16:30:00+07	t	25	0	0	0	33e6ae19-66b5-4a25-897a-48d9694631aa	2026-10-04 23:23:55.554+07
\.


--
-- Data for Name: AttendanceLog; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."AttendanceLog" (id, "odooEmployeeId", "rawPunchId", "workDate", direction, "punchAt", "isValid", "invalidReason", "assignedAt") FROM stdin;
47a2a223-3357-4b66-9486-081eace77778	6a65b903-7cb2-468b-8245-a607e73baa54	a0c0933e-1271-4121-810e-d45c6d9fe806	2026-09-01	UNKNOWN	2026-09-01 07:50:00+07	t	\N	2026-10-04 22:58:57.745+07
e20f817a-43e2-4e01-a59e-141315267a33	6a65b903-7cb2-468b-8245-a607e73baa54	0bff6940-61cb-458e-be9e-ce11aa21dde6	2026-09-01	UNKNOWN	2026-09-01 16:00:00+07	t	\N	2026-10-04 22:58:57.756+07
ce7a89e5-7be3-47e1-aa34-7d4e4a5def71	6a65b903-7cb2-468b-8245-a607e73baa54	8c99cf26-6115-463f-970f-efd16076d33f	2026-09-02	UNKNOWN	2026-09-02 07:55:00+07	t	\N	2026-10-04 22:58:57.758+07
6f917d73-3b7c-4351-a6f7-555ccd20272c	6a65b903-7cb2-468b-8245-a607e73baa54	6194413e-30eb-4417-a14d-d46281cd5af3	2026-09-02	UNKNOWN	2026-09-02 16:15:00+07	t	\N	2026-10-04 22:58:57.759+07
5723170c-0934-4579-ad0c-3c3ac5782bb0	6a65b903-7cb2-468b-8245-a607e73baa54	a108d0bb-dcd0-4a90-aa4b-4e3198892f41	2026-09-03	UNKNOWN	2026-09-03 08:00:00+07	t	\N	2026-10-04 22:58:57.761+07
3114fc34-717b-4b4d-877e-597ef0d1ef52	6a65b903-7cb2-468b-8245-a607e73baa54	a4f6e2f0-6155-4a16-b04d-ebe0c6eb3473	2026-09-03	UNKNOWN	2026-09-03 16:30:00+07	t	\N	2026-10-04 22:58:57.763+07
f2daaf9b-6c90-44a5-bf22-5feec495c8bf	6a65b903-7cb2-468b-8245-a607e73baa54	7b47c4e0-2d6e-4910-9eae-ea6365fc11da	2026-09-04	UNKNOWN	2026-09-04 08:05:00+07	t	\N	2026-10-04 22:58:57.765+07
4b72ffa1-10e1-49f3-9090-6a669855538c	6a65b903-7cb2-468b-8245-a607e73baa54	7149906a-9fd0-4440-919a-7b49c395dd4e	2026-09-04	UNKNOWN	2026-09-04 16:00:00+07	t	\N	2026-10-04 22:58:57.766+07
202f2c03-81ad-440b-9447-8fa76e644e21	6a65b903-7cb2-468b-8245-a607e73baa54	4b100591-d483-4545-bca5-023c2393ef92	2026-09-07	UNKNOWN	2026-09-07 07:50:00+07	t	\N	2026-10-04 22:58:57.769+07
1e3d5323-feae-43c8-9064-969416f9f280	6a65b903-7cb2-468b-8245-a607e73baa54	e46208c3-93a1-432f-be1b-9713ee50fb10	2026-09-07	UNKNOWN	2026-09-07 16:15:00+07	t	\N	2026-10-04 22:58:57.771+07
cb00413a-bb2a-4960-8912-fb6a18566258	6a65b903-7cb2-468b-8245-a607e73baa54	f75d230d-07e2-4a70-b4c0-3c8f6f965485	2026-09-08	UNKNOWN	2026-09-08 07:55:00+07	t	\N	2026-10-04 22:58:57.772+07
b7580616-4c8c-4d35-a884-969baf8195bb	6a65b903-7cb2-468b-8245-a607e73baa54	5f6124fb-69b7-4995-a4e1-d09e3848173b	2026-09-08	UNKNOWN	2026-09-08 16:30:00+07	t	\N	2026-10-04 22:58:57.774+07
b93d0d6e-0028-4e7d-903a-5eb7784e9d65	6a65b903-7cb2-468b-8245-a607e73baa54	2cc3b5f4-0c3f-42cb-97bc-89eadd216222	2026-09-09	UNKNOWN	2026-09-09 08:00:00+07	t	\N	2026-10-04 22:58:57.776+07
e7cf2928-d6d2-44d6-8532-d2b9afe66bc4	6a65b903-7cb2-468b-8245-a607e73baa54	28d3848e-6785-4f71-9f73-e49bd6604de8	2026-09-09	UNKNOWN	2026-09-09 16:00:00+07	t	\N	2026-10-04 22:58:57.778+07
38cb54fb-be15-458a-a9c2-279a12de342e	6a65b903-7cb2-468b-8245-a607e73baa54	173bb726-4368-48ca-a339-c9d3b0b98c3b	2026-09-10	UNKNOWN	2026-09-10 08:05:00+07	t	\N	2026-10-04 22:58:57.779+07
ba5e7092-d4d0-460c-a497-2b99ed87f343	6a65b903-7cb2-468b-8245-a607e73baa54	500a33e8-bfb6-4f23-ba7b-832d5889c4a5	2026-09-10	UNKNOWN	2026-09-10 16:15:00+07	t	\N	2026-10-04 22:58:57.781+07
ebdf9843-7aa2-4d40-8a4e-4ac98aa82f88	6a65b903-7cb2-468b-8245-a607e73baa54	38e41c95-389b-491e-96a4-2b7ff75d86ae	2026-09-11	UNKNOWN	2026-09-11 07:50:00+07	t	\N	2026-10-04 22:58:57.782+07
2bfbd30e-48b8-40a5-8ba1-9e66944e99a2	6a65b903-7cb2-468b-8245-a607e73baa54	bfdfb58d-3823-44b0-a951-51657e6b5be1	2026-09-14	UNKNOWN	2026-09-14 07:55:00+07	t	\N	2026-10-04 22:58:57.787+07
99005e34-cb1a-4f0d-9830-1bf3ddf2058d	6a65b903-7cb2-468b-8245-a607e73baa54	76c32a76-6b8a-45ab-8f21-4a01616ef592	2026-09-14	UNKNOWN	2026-09-14 16:00:00+07	t	\N	2026-10-04 22:58:57.789+07
2b9de86d-678b-4bf3-94b3-b1e26f50effd	6a65b903-7cb2-468b-8245-a607e73baa54	fbfe2d02-17f1-4972-8ad1-0cc868f7d7a6	2026-09-15	UNKNOWN	2026-09-15 08:00:00+07	t	\N	2026-10-04 22:58:57.791+07
1703c55b-f03b-4f8b-b4ed-d9553c3ce187	6a65b903-7cb2-468b-8245-a607e73baa54	2f7a66e0-2c78-4f20-a35f-acf69b8c5ebd	2026-09-11	UNKNOWN	2026-09-11 16:30:00+07	t	\N	2026-10-04 22:58:57.785+07
411bee1b-f4e9-40e5-918e-9ef863c51e4b	6a65b903-7cb2-468b-8245-a607e73baa54	cfad1230-815f-42b2-8b5b-00dcff0669b0	2026-09-18	UNKNOWN	2026-09-18 07:50:00+07	t	\N	2026-10-04 22:58:57.799+07
6b6b4900-91d8-4f70-8b15-01f859b03ac2	6a65b903-7cb2-468b-8245-a607e73baa54	5f78b325-9202-42bd-bc59-e720d5863e30	2026-09-18	UNKNOWN	2026-09-18 16:00:00+07	t	\N	2026-10-04 22:58:57.802+07
7aef3b06-261e-42d8-bf42-89f4d613375d	6a65b903-7cb2-468b-8245-a607e73baa54	3ec77c78-f44c-42fe-9c04-7751f9c025a0	2026-09-21	UNKNOWN	2026-09-21 07:55:00+07	t	\N	2026-10-04 22:58:57.804+07
773fad72-1625-425b-8b1c-f48d5e20e658	6a65b903-7cb2-468b-8245-a607e73baa54	10bada50-23b9-4137-bbd0-26e76c9b057a	2026-09-21	UNKNOWN	2026-09-21 16:15:00+07	t	\N	2026-10-04 22:58:57.806+07
664005ba-b02d-420b-bb71-80b434dbd943	6a65b903-7cb2-468b-8245-a607e73baa54	85db05fa-d2bd-4ac0-84ef-cbbbddab5280	2026-09-22	UNKNOWN	2026-09-22 08:00:00+07	t	\N	2026-10-04 22:58:57.809+07
fe41b234-74f3-4cb3-b869-252e34f310b3	6a65b903-7cb2-468b-8245-a607e73baa54	ebdfffbf-1189-4cf7-90bb-71502823c5e7	2026-09-22	UNKNOWN	2026-09-22 16:30:00+07	t	\N	2026-10-04 22:58:57.811+07
ca9184d0-701b-4756-b1fb-485e15c2935f	6a65b903-7cb2-468b-8245-a607e73baa54	bd1a8816-6221-4135-9baf-7158b6efbee6	2026-09-23	UNKNOWN	2026-09-23 08:05:00+07	t	\N	2026-10-04 22:58:57.813+07
0fb616dc-785f-4129-9293-b7eed340d704	6a65b903-7cb2-468b-8245-a607e73baa54	15542e2e-9fdd-4e2c-8f2e-c222de79ba64	2026-09-23	UNKNOWN	2026-09-23 16:00:00+07	t	\N	2026-10-04 22:58:57.814+07
75e5cd8a-61f6-4e42-947c-c92f007d2bf0	6a65b903-7cb2-468b-8245-a607e73baa54	b568e6a9-12be-445c-9b35-e3b9eaf8bc36	2026-09-24	UNKNOWN	2026-09-24 07:50:00+07	t	\N	2026-10-04 22:58:57.817+07
8af685be-bf02-458b-916a-deb7f2a99683	6a65b903-7cb2-468b-8245-a607e73baa54	67f4f40a-b223-4f62-9e10-d9d2b323ef3a	2026-09-24	UNKNOWN	2026-09-24 16:15:00+07	t	\N	2026-10-04 22:58:57.819+07
9a0094c0-b0f4-4342-8f5c-1a0f4c529ebb	6a65b903-7cb2-468b-8245-a607e73baa54	7678eaee-4f1f-4bc0-aa51-30707f2bed12	2026-09-25	UNKNOWN	2026-09-25 07:55:00+07	t	\N	2026-10-04 22:58:57.821+07
b86d2a9b-bbad-4b50-a59e-3874350f6d98	6a65b903-7cb2-468b-8245-a607e73baa54	e1dac3ec-7b34-4463-bad3-44ad36761af9	2026-09-25	UNKNOWN	2026-09-25 16:30:00+07	t	\N	2026-10-04 22:58:57.823+07
c83e76cb-6e1b-467f-97e3-9e4924f51051	6a65b903-7cb2-468b-8245-a607e73baa54	7af2e3a4-3b5a-4b59-b791-4b3f77180dd8	2026-09-28	UNKNOWN	2026-09-28 08:00:00+07	t	\N	2026-10-04 22:58:57.825+07
05c7cf5b-5477-43ac-a790-cead265a017d	6a65b903-7cb2-468b-8245-a607e73baa54	4daf9e79-5de3-487f-9a6a-edd29639f94b	2026-09-28	UNKNOWN	2026-09-28 16:00:00+07	t	\N	2026-10-04 22:58:57.827+07
9d267149-ba8c-4778-91ff-a6558bb4b534	6a65b903-7cb2-468b-8245-a607e73baa54	4c6d283c-0812-4c78-b0dc-245f8068f9ce	2026-09-29	UNKNOWN	2026-09-29 08:05:00+07	t	\N	2026-10-04 22:58:57.829+07
26188d89-4951-48e6-968b-a05fa6b665bc	6a65b903-7cb2-468b-8245-a607e73baa54	fba84ba6-3eb1-4049-b57b-86eb668edee7	2026-09-30	UNKNOWN	2026-09-30 07:50:00+07	t	\N	2026-10-04 22:58:57.831+07
cb211073-9dc5-4c19-9b6f-926e83033d91	6a65b903-7cb2-468b-8245-a607e73baa54	82deb5ba-e49c-451d-be19-9c7f35370f34	2026-09-30	UNKNOWN	2026-09-30 16:30:00+07	t	\N	2026-10-04 22:58:57.834+07
dfcf729a-e8f4-4757-8b5c-2cfede12d682	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	bc977e55-9022-4463-ad83-3e1326159e2c	2026-09-01	UNKNOWN	2026-09-01 08:40:00+07	t	\N	2026-10-04 22:58:57.91+07
f8612029-e984-4e20-b4e8-10d42310952f	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	27e139b5-d4c3-468a-b029-ace21bf8dded	2026-09-01	UNKNOWN	2026-09-01 16:30:00+07	t	\N	2026-10-04 22:58:57.925+07
bf5003b7-d65c-4557-9949-c09ec35bebd2	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	dc95dc26-09b1-4edd-8bc8-709e3e888331	2026-09-02	UNKNOWN	2026-09-02 08:05:00+07	t	\N	2026-10-04 22:58:57.927+07
fc3329c1-f91a-40b2-9fdd-acbfe783a68d	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	4e2d33d0-acf1-4b4a-96f0-455e3195baef	2026-09-02	UNKNOWN	2026-09-02 16:30:00+07	t	\N	2026-10-04 22:58:57.928+07
f45473c5-f600-4ede-8567-622b69f728b8	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	045804eb-e359-445e-a8ba-7e948965c0db	2026-09-03	UNKNOWN	2026-09-03 08:05:00+07	t	\N	2026-10-04 22:58:57.93+07
e7bcc161-1296-467b-a7c6-2671960909ea	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	114e4b44-b675-4b49-ac9e-7f97d0092652	2026-09-03	UNKNOWN	2026-09-03 16:30:00+07	t	\N	2026-10-04 22:58:57.931+07
59fb052b-21c8-404c-b80f-c1a9826b12dc	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	83ea610f-d3a9-474a-9607-18ddd48e5b5b	2026-09-04	UNKNOWN	2026-09-04 08:25:00+07	t	\N	2026-10-04 22:58:57.934+07
6c0089f6-d113-4899-a57b-770abed16db3	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	560452a1-7c7b-4160-899c-c40589bac7f0	2026-09-04	UNKNOWN	2026-09-04 16:30:00+07	t	\N	2026-10-04 22:58:57.936+07
e28e7654-99d3-4d4c-b2de-799ccfcaab11	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	1fab44d1-ac88-4f12-ac08-b0f017914e51	2026-09-07	UNKNOWN	2026-09-07 08:05:00+07	t	\N	2026-10-04 22:58:57.937+07
0a0aa4f1-5d94-493f-8a1c-40d8a0dc1a80	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	1e731377-fdee-45c7-b779-e3934f90c2de	2026-09-07	UNKNOWN	2026-09-07 16:30:00+07	t	\N	2026-10-04 22:58:57.939+07
3235f82a-d307-48f7-8a35-7202555bb139	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	bcf1cdad-002a-4446-99a0-9ab753741ffd	2026-09-08	UNKNOWN	2026-09-08 08:40:00+07	t	\N	2026-10-04 22:58:57.94+07
bf6af7ab-08a0-43ba-ba1d-b39b297e30a6	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	b764b327-4cce-434b-adc7-ee5c3e0f8431	2026-09-08	UNKNOWN	2026-09-08 16:30:00+07	t	\N	2026-10-04 22:58:57.941+07
86944b41-af00-41f8-8d58-bd0a34de5c0f	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	21d6ddcc-c056-4627-abe1-eaa9cfb27426	2026-09-09	UNKNOWN	2026-09-09 08:25:00+07	t	\N	2026-10-04 22:58:57.942+07
81fe31e7-e888-46e5-bd40-90d9d8d8c4a2	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	82349226-f979-44b3-89c4-e6c52531a9ce	2026-09-09	UNKNOWN	2026-09-09 16:30:00+07	t	\N	2026-10-04 22:58:57.944+07
6ebf79de-4e35-47b0-a9a1-cedd53e2668f	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	022596d1-17df-4204-b01b-793041820858	2026-09-10	UNKNOWN	2026-09-10 08:05:00+07	t	\N	2026-10-04 22:58:57.946+07
1d52ebe5-7efd-40c1-ae25-3e28547930cf	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	ca737834-5124-4c97-a510-9f163eec2947	2026-09-10	UNKNOWN	2026-09-10 16:30:00+07	t	\N	2026-10-04 22:58:57.948+07
de8e20dc-3408-48e9-bc5b-7282ae89b26d	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	c89424a4-e878-415a-b16c-8c442d040671	2026-09-11	UNKNOWN	2026-09-11 08:05:00+07	t	\N	2026-10-04 22:58:57.95+07
a65dc787-b9ff-41a6-a1b4-65d4d196caf6	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	76db4ce0-4dd5-4676-a3c5-b8f009c8ab58	2026-09-11	UNKNOWN	2026-09-11 16:30:00+07	t	\N	2026-10-04 22:58:57.952+07
36c31c80-2191-4433-bf25-124c2fb8e667	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	42a4e6a6-b7df-4270-90aa-e05ce8592570	2026-09-14	UNKNOWN	2026-09-14 08:25:00+07	t	\N	2026-10-04 22:58:57.954+07
5eec1931-c5e6-4977-b162-4e1bf3feaf83	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	3dda1347-31b9-4b97-9093-cf5f06e47599	2026-09-14	UNKNOWN	2026-09-14 16:30:00+07	t	\N	2026-10-04 22:58:57.955+07
0e5f9a63-2d41-4853-931d-9f069bc6d203	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	f773354e-c679-4023-8c62-f1639003c8e8	2026-09-15	UNKNOWN	2026-09-15 08:40:00+07	t	\N	2026-10-04 22:58:57.956+07
97e1e115-6c75-480c-8e96-4aa111368279	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	79509075-c2b0-468b-8438-95fb373e72de	2026-09-15	UNKNOWN	2026-09-15 16:30:00+07	t	\N	2026-10-04 22:58:57.957+07
88d6539d-872f-4362-8ef8-c5c4160a684a	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	74b67972-d3fa-45ae-bc9a-af670f5d0fa8	2026-09-17	UNKNOWN	2026-09-17 08:05:00+07	t	\N	2026-10-04 22:58:57.959+07
8f34e8b2-0b38-413a-8fcb-e84970542b3f	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	a4f676bc-b183-4931-b303-54b8ad442fae	2026-09-17	UNKNOWN	2026-09-17 16:30:00+07	t	\N	2026-10-04 22:58:57.96+07
5be5a578-b184-4bca-8de3-088bbc07644e	6a65b903-7cb2-468b-8245-a607e73baa54	7cc8ef5d-ac82-4b85-bf62-7dd9a400160f	2026-09-17	UNKNOWN	2026-09-17 08:05:00+07	t	\N	2026-10-04 22:58:57.795+07
b6a2b581-39cf-4200-989a-04fc242e86fb	6a65b903-7cb2-468b-8245-a607e73baa54	efdd3069-300d-4c98-b5f6-676fee94619d	2026-09-17	UNKNOWN	2026-09-17 16:30:00+07	t	\N	2026-10-04 22:58:57.797+07
660311c7-044a-487b-990e-a76b624b9426	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	64e72d83-baf9-4726-afd0-90e9b2de3975	2026-09-21	UNKNOWN	2026-09-21 16:30:00+07	t	\N	2026-10-04 22:58:57.965+07
18ff6bd3-2144-42ad-a301-29437fd54fb6	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	65096dbf-4e15-4806-8d47-1ff91905964e	2026-09-22	UNKNOWN	2026-09-22 08:05:00+07	t	\N	2026-10-04 22:58:57.967+07
b6c7393b-50a9-40f1-91d6-12fe8b4d0459	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	c543192b-74b4-4410-86d8-8791b24cd6a5	2026-09-22	UNKNOWN	2026-09-22 16:30:00+07	t	\N	2026-10-04 22:58:57.969+07
f0baa567-aab8-4cdd-b893-405f8c37db67	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	4a6fa234-30b3-46c0-babc-901924dc24a6	2026-09-23	UNKNOWN	2026-09-23 08:40:00+07	t	\N	2026-10-04 22:58:57.971+07
487c9c81-300f-41c8-ac99-1249a0fddafe	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	9aecbeb3-3f2d-4188-8e9f-657ed977d616	2026-09-23	UNKNOWN	2026-09-23 16:30:00+07	t	\N	2026-10-04 22:58:57.972+07
d4f0ba6b-6389-4ced-8983-33f9f8dfe9d9	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	0c78c31a-5a6e-4b32-acb5-61564638e7e9	2026-09-24	UNKNOWN	2026-09-24 08:05:00+07	t	\N	2026-10-04 22:58:57.973+07
1aaf9e81-1d93-4b2d-90bc-fa0031428928	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	5958eb9c-232a-436b-b0fb-15f5ebf6d879	2026-09-24	UNKNOWN	2026-09-24 16:30:00+07	t	\N	2026-10-04 22:58:57.975+07
50ffcd06-5e21-4400-86ad-1598f31485c4	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	3ff24478-b250-4e6f-9358-6f9a215f0715	2026-09-25	UNKNOWN	2026-09-25 08:05:00+07	t	\N	2026-10-04 22:58:57.976+07
a8f667c2-4776-4393-a211-77a2d8234f5c	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	53e80844-4efd-45de-8a99-d25a609ddecf	2026-09-25	UNKNOWN	2026-09-25 16:30:00+07	t	\N	2026-10-04 22:58:57.978+07
a2181fc5-21b2-4e9f-b826-e7907496e8e0	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	1bf92315-4bf1-4267-b9e7-658c5e1dce54	2026-09-28	UNKNOWN	2026-09-28 08:25:00+07	t	\N	2026-10-04 22:58:57.979+07
0f5d2b1d-177c-4f3c-9e35-0bcc2b7f024a	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	91e49b89-8de7-4238-903c-91af9db36b8c	2026-09-28	UNKNOWN	2026-09-28 16:30:00+07	t	\N	2026-10-04 22:58:57.981+07
6db4e0f6-0ad1-4c03-88a3-beaa3386462d	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	64112efb-5620-484f-a773-6519c47a34ee	2026-09-29	UNKNOWN	2026-09-29 08:05:00+07	t	\N	2026-10-04 22:58:57.983+07
c7087dd6-9759-4d77-a949-adb37ca6d7e2	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	77e4a75f-c6ef-4820-b7c5-dcc15c2711bc	2026-09-29	UNKNOWN	2026-09-29 16:30:00+07	t	\N	2026-10-04 22:58:57.986+07
172cb172-07fd-42b4-b831-611280efdea2	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	dce820b7-8375-412a-918b-242f0f8e9928	2026-09-30	UNKNOWN	2026-09-30 08:40:00+07	t	\N	2026-10-04 22:58:57.988+07
098fdb0e-29e9-4dd5-9971-b967ca1da439	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	49a76484-6b27-4887-92a7-fa8742ca33e2	2026-09-30	UNKNOWN	2026-09-30 16:30:00+07	t	\N	2026-10-04 22:58:57.99+07
bafdb0bf-392e-4b1c-a653-88ad99cec31d	4478787b-c3e8-4f0d-8b9b-7046fec7f539	aaa49eb4-97db-4a0e-8a6f-fb59421b7a8c	2026-09-01	UNKNOWN	2026-09-01 16:10:00+07	t	\N	2026-10-04 22:58:58.079+07
00ac76f3-af61-4721-a33b-e11e8fda1ae1	4478787b-c3e8-4f0d-8b9b-7046fec7f539	d5d51b3c-9b74-4947-ad48-ddcda948dff2	2026-09-02	UNKNOWN	2026-09-02 08:03:00+07	t	\N	2026-10-04 22:58:58.081+07
c6d4a02b-02bd-4d26-8ad4-f51e70a97e7e	4478787b-c3e8-4f0d-8b9b-7046fec7f539	7477b956-f2ad-439e-8ea7-051d368d5f79	2026-09-02	UNKNOWN	2026-09-02 16:10:00+07	t	\N	2026-10-04 22:58:58.083+07
d063ac15-a65e-4642-b869-75382fe22b94	4478787b-c3e8-4f0d-8b9b-7046fec7f539	0235838f-9769-4ef0-8bb1-036d88b09d9d	2026-09-03	UNKNOWN	2026-09-03 08:06:00+07	t	\N	2026-10-04 22:58:58.086+07
7a9f7c0a-421b-4ec2-a1e6-5b5e9ba96a79	4478787b-c3e8-4f0d-8b9b-7046fec7f539	1296d575-80be-4d36-8d5b-b612b7259479	2026-09-03	UNKNOWN	2026-09-03 16:10:00+07	t	\N	2026-10-04 22:58:58.09+07
e2a0b3f5-a525-4a8c-9543-3882d95a3989	4478787b-c3e8-4f0d-8b9b-7046fec7f539	26c6d3a6-9f25-4955-94dd-59c18207c905	2026-09-04	UNKNOWN	2026-09-04 08:00:00+07	t	\N	2026-10-04 22:58:58.092+07
ebe07cf4-eb62-4d56-b938-995c84306797	4478787b-c3e8-4f0d-8b9b-7046fec7f539	abcf196a-54ee-4115-9612-cecff602a961	2026-09-04	UNKNOWN	2026-09-04 16:10:00+07	t	\N	2026-10-04 22:58:58.094+07
4fe0908a-a80c-44b4-b4b1-c6db2699d612	4478787b-c3e8-4f0d-8b9b-7046fec7f539	fde66805-1b46-4add-b67e-9cee3cff8070	2026-09-07	UNKNOWN	2026-09-07 08:03:00+07	t	\N	2026-10-04 22:58:58.096+07
abe2f426-076d-4f56-88f5-37f932cfa115	4478787b-c3e8-4f0d-8b9b-7046fec7f539	bec43749-3133-493f-b1ee-fe7af4bade03	2026-09-07	UNKNOWN	2026-09-07 16:10:00+07	t	\N	2026-10-04 22:58:58.098+07
d2569748-d450-400c-9fa8-405c83cb7646	4478787b-c3e8-4f0d-8b9b-7046fec7f539	230cd060-a201-4f01-92c2-30e896125414	2026-09-08	UNKNOWN	2026-09-08 08:06:00+07	t	\N	2026-10-04 22:58:58.102+07
f11eb829-078c-4e68-908d-0b8dcf48831c	4478787b-c3e8-4f0d-8b9b-7046fec7f539	cd9a3ac1-5f30-401f-9ea3-033032d4bc71	2026-09-08	UNKNOWN	2026-09-08 16:10:00+07	t	\N	2026-10-04 22:58:58.105+07
1a88a83a-b2c7-4951-ab7b-d641bfbfc48d	4478787b-c3e8-4f0d-8b9b-7046fec7f539	267e8997-bf36-46bc-801a-937c4ad48e64	2026-09-10	UNKNOWN	2026-09-10 08:03:00+07	t	\N	2026-10-04 22:58:58.107+07
6b8f5b4d-0509-47f5-a819-71e3eb953917	4478787b-c3e8-4f0d-8b9b-7046fec7f539	e960d7b1-6565-4153-b136-1d40bbfe9df2	2026-09-10	UNKNOWN	2026-09-10 16:10:00+07	t	\N	2026-10-04 22:58:58.109+07
93f0b4a0-07df-4bad-92f6-1f6678734a2b	4478787b-c3e8-4f0d-8b9b-7046fec7f539	e2745e2e-3cf3-45bd-8e67-cf59b1689627	2026-09-11	UNKNOWN	2026-09-11 08:02:00+07	t	\N	2026-10-04 22:58:58.112+07
ff65178d-edf8-4817-9887-77d4dc1568c6	4478787b-c3e8-4f0d-8b9b-7046fec7f539	8482feec-6a6d-4adb-81c4-93869dd25622	2026-09-14	UNKNOWN	2026-09-14 08:00:00+07	t	\N	2026-10-04 22:58:58.115+07
e6ee8b96-e865-451e-a174-5362896c1d75	4478787b-c3e8-4f0d-8b9b-7046fec7f539	00512062-cd72-4bf2-a680-c3932e9f7efa	2026-09-14	UNKNOWN	2026-09-14 16:10:00+07	t	\N	2026-10-04 22:58:58.118+07
07c81a35-1d8e-44ec-868a-ae3ada9a6c8e	4478787b-c3e8-4f0d-8b9b-7046fec7f539	d9e3a36d-938a-47a1-a859-0c855ff6e2d2	2026-09-15	UNKNOWN	2026-09-15 08:03:00+07	t	\N	2026-10-04 22:58:58.121+07
c2b8c50e-02bb-4918-8c43-f5264d1106d2	4478787b-c3e8-4f0d-8b9b-7046fec7f539	bc9060d5-31ff-4b35-80b0-eb35c50fce05	2026-09-15	UNKNOWN	2026-09-15 16:10:00+07	t	\N	2026-10-04 22:58:58.123+07
3a819183-b60f-4931-97bd-81ff0b8f5538	4478787b-c3e8-4f0d-8b9b-7046fec7f539	ff293ea6-ab4f-491d-809c-d03bce99f390	2026-09-17	UNKNOWN	2026-09-17 08:06:00+07	t	\N	2026-10-04 22:58:58.125+07
4cee7825-8774-4d52-b63f-03b0687ef37a	4478787b-c3e8-4f0d-8b9b-7046fec7f539	94ce74a6-71f0-4f92-923a-28446ac5c7c9	2026-09-17	UNKNOWN	2026-09-17 16:10:00+07	t	\N	2026-10-04 22:58:58.127+07
ac4e23ff-5ee5-4fca-880e-3c9ac3152243	4478787b-c3e8-4f0d-8b9b-7046fec7f539	a5855a5a-6277-47fd-85eb-eda6d67d62cd	2026-09-18	UNKNOWN	2026-09-18 08:00:00+07	t	\N	2026-10-04 22:58:58.129+07
73970fa8-f78f-49ae-8c59-4119ccbf364e	4478787b-c3e8-4f0d-8b9b-7046fec7f539	c6447124-1c0e-443d-837c-c6b8dfcb47ff	2026-09-18	UNKNOWN	2026-09-18 16:10:00+07	t	\N	2026-10-04 22:58:58.131+07
94a88c3d-cd1a-429c-8f4c-6a8dbf356d64	4478787b-c3e8-4f0d-8b9b-7046fec7f539	269021b4-e383-493c-a03a-e6eeae4be8ab	2026-09-21	UNKNOWN	2026-09-21 08:03:00+07	t	\N	2026-10-04 22:58:58.134+07
944c4716-11bd-4c24-9f90-8c6bc89cf04b	4478787b-c3e8-4f0d-8b9b-7046fec7f539	d8ab3697-62c5-42b7-bc68-aa7c102edb3a	2026-09-21	UNKNOWN	2026-09-21 16:10:00+07	t	\N	2026-10-04 22:58:58.136+07
19f7a990-b612-45de-872d-e476016cae6f	4478787b-c3e8-4f0d-8b9b-7046fec7f539	bddfb0c6-e7ab-4e47-bda7-567548c84ffd	2026-09-22	UNKNOWN	2026-09-22 08:06:00+07	t	\N	2026-10-04 22:58:58.138+07
03acee43-0001-4676-ab9c-3d7acc83b543	4478787b-c3e8-4f0d-8b9b-7046fec7f539	028bee96-feb6-4e1f-8cf7-762513bd68cf	2026-09-22	UNKNOWN	2026-09-22 16:10:00+07	t	\N	2026-10-04 22:58:58.139+07
38ec0db4-37ac-42b9-af79-a7c279c0c546	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	7731f036-e64e-4f3b-8c28-5d8a7039ad72	2026-09-18	UNKNOWN	2026-09-18 16:30:00+07	t	\N	2026-10-04 22:58:57.962+07
ff9ef9c2-65f9-438e-a616-06ca4df30719	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	61ff919e-d4c0-4016-9390-53c28cfdf9e4	2026-09-21	UNKNOWN	2026-09-21 08:05:00+07	t	\N	2026-10-04 22:58:57.963+07
4a6b5b3b-9708-4167-925a-e51845607d25	4478787b-c3e8-4f0d-8b9b-7046fec7f539	6058a27f-15a2-4343-9a28-23238e838bf2	2026-09-25	UNKNOWN	2026-09-25 16:10:00+07	t	\N	2026-10-04 22:58:58.145+07
82ec1cd2-b020-4278-bf4c-5f0c971d9a4e	4478787b-c3e8-4f0d-8b9b-7046fec7f539	d4de9dfd-dfc5-496d-849a-acab42b9ec55	2026-09-28	UNKNOWN	2026-09-28 08:02:00+07	t	\N	2026-10-04 22:58:58.146+07
4d12d878-1232-45cf-b41e-2e6b76a4ee94	4478787b-c3e8-4f0d-8b9b-7046fec7f539	2655daed-9b5d-40e2-a446-0dc39559565c	2026-09-29	UNKNOWN	2026-09-29 08:03:00+07	t	\N	2026-10-04 22:58:58.148+07
217458ce-7a02-425e-adf6-1fc180d8affa	4478787b-c3e8-4f0d-8b9b-7046fec7f539	0cd90b86-f946-41a7-8258-c280c7ce34c3	2026-09-29	UNKNOWN	2026-09-29 16:10:00+07	t	\N	2026-10-04 22:58:58.151+07
f2e5a375-79ab-4e62-bc69-5c67c8ebd632	4478787b-c3e8-4f0d-8b9b-7046fec7f539	cc1df6e0-7337-49db-a2b8-31ca6409ca94	2026-09-30	UNKNOWN	2026-09-30 08:06:00+07	t	\N	2026-10-04 22:58:58.154+07
b1b77036-25e9-4434-ae1c-758c3a55a8f1	4478787b-c3e8-4f0d-8b9b-7046fec7f539	871610d2-81df-4fca-8cdf-b8d9c628f0d0	2026-09-30	UNKNOWN	2026-09-30 16:10:00+07	t	\N	2026-10-04 22:58:58.156+07
1c1aa349-3f47-4253-b552-b6bbc62c5f18	0cd6bde6-3226-4ebb-b135-ca522d42efa4	14292214-6f69-4a39-9027-6cd031df7eff	2026-09-01	UNKNOWN	2026-09-01 07:55:00+07	t	\N	2026-10-04 22:58:58.223+07
b451aaf0-39e3-4311-b34f-92846f331393	0cd6bde6-3226-4ebb-b135-ca522d42efa4	a07949cc-20f0-41f7-88fb-d1b0cee5dc15	2026-09-01	UNKNOWN	2026-09-01 16:05:00+07	t	\N	2026-10-04 22:58:58.231+07
70b5adc1-49a9-402f-b60a-0769cfdbd2f8	0cd6bde6-3226-4ebb-b135-ca522d42efa4	36b1f08d-98ab-4ebc-b4b7-6a8979d4ab19	2026-09-02	UNKNOWN	2026-09-02 07:55:00+07	t	\N	2026-10-04 22:58:58.234+07
3749ed21-4e41-4242-bbe7-f76914d343be	0cd6bde6-3226-4ebb-b135-ca522d42efa4	df9cce3a-f946-4e90-97e4-32b0f8788ab0	2026-09-02	UNKNOWN	2026-09-02 16:05:00+07	t	\N	2026-10-04 22:58:58.237+07
b1524740-4cdc-4462-8aac-e51c79d472b7	0cd6bde6-3226-4ebb-b135-ca522d42efa4	8987c0c5-7c1c-4fe5-9d90-5d8033f40830	2026-09-03	UNKNOWN	2026-09-03 07:55:00+07	t	\N	2026-10-04 22:58:58.239+07
c901a96d-a1d5-48b3-95be-cc0b28d7c1da	0cd6bde6-3226-4ebb-b135-ca522d42efa4	16b8cec0-f1c1-4289-accd-a3d7568e9033	2026-09-03	UNKNOWN	2026-09-03 16:05:00+07	t	\N	2026-10-04 22:58:58.24+07
2aacb522-5b95-468d-8dab-bc904dec4df4	0cd6bde6-3226-4ebb-b135-ca522d42efa4	eceb120d-8dc4-4498-a1c0-2fa088e9af24	2026-09-04	UNKNOWN	2026-09-04 07:55:00+07	t	\N	2026-10-04 22:58:58.242+07
eb8f0871-2227-4841-828f-7697e196c566	0cd6bde6-3226-4ebb-b135-ca522d42efa4	111cf5f7-d0d8-49d8-8213-cf3692f95aec	2026-09-04	UNKNOWN	2026-09-04 16:05:00+07	t	\N	2026-10-04 22:58:58.243+07
47c0e61d-77f1-4e62-b642-e51843b00810	0cd6bde6-3226-4ebb-b135-ca522d42efa4	91072f26-694a-41a6-b1c4-93f3ff2b311d	2026-09-07	UNKNOWN	2026-09-07 07:55:00+07	t	\N	2026-10-04 22:58:58.245+07
5ed79d44-3cdb-4411-9210-382270a70df4	0cd6bde6-3226-4ebb-b135-ca522d42efa4	b2154611-d560-41b4-ad37-32f0b6b7367a	2026-09-11	UNKNOWN	2026-09-11 07:55:00+07	t	\N	2026-10-04 22:58:58.247+07
9c4fd8d2-4983-4d37-816f-ee5cd1560916	0cd6bde6-3226-4ebb-b135-ca522d42efa4	1fbdf9e9-6856-44e2-b151-6996b5d065ff	2026-09-11	UNKNOWN	2026-09-11 16:05:00+07	t	\N	2026-10-04 22:58:58.249+07
d7d6742f-3412-402f-8c89-4196c23f78e7	0cd6bde6-3226-4ebb-b135-ca522d42efa4	755dab2a-c97e-4445-a9c8-7d79cd695828	2026-09-14	UNKNOWN	2026-09-14 07:55:00+07	t	\N	2026-10-04 22:58:58.25+07
bf095609-7677-4bf0-aad1-c0b6ed725ab9	0cd6bde6-3226-4ebb-b135-ca522d42efa4	81f69705-188d-421e-beb7-6e8332510b97	2026-09-14	UNKNOWN	2026-09-14 16:05:00+07	t	\N	2026-10-04 22:58:58.252+07
ce553e2b-e510-4d8e-9aa0-dc25f0d21fb0	0cd6bde6-3226-4ebb-b135-ca522d42efa4	38960916-bfb9-4de7-a027-2de215e79104	2026-09-15	UNKNOWN	2026-09-15 07:55:00+07	t	\N	2026-10-04 22:58:58.254+07
6399cab0-8b4e-45d6-bb76-a2cd8c876125	0cd6bde6-3226-4ebb-b135-ca522d42efa4	75813451-da3b-401a-b9c4-353b45c0d48b	2026-09-15	UNKNOWN	2026-09-15 16:05:00+07	t	\N	2026-10-04 22:58:58.256+07
24c3ceee-b82b-4ff6-a768-37105275fc6e	0cd6bde6-3226-4ebb-b135-ca522d42efa4	ee1a965f-96ac-428b-a700-6385bcb191c5	2026-09-17	UNKNOWN	2026-09-17 07:55:00+07	t	\N	2026-10-04 22:58:58.257+07
7459b3ef-04f2-4eda-9788-5d5094e59256	0cd6bde6-3226-4ebb-b135-ca522d42efa4	3bea7fee-aecc-4af3-a2b8-1f215862a0f9	2026-09-17	UNKNOWN	2026-09-17 16:05:00+07	t	\N	2026-10-04 22:58:58.258+07
6b23b4a5-65b9-463c-9c79-a7f9e433cdb8	0cd6bde6-3226-4ebb-b135-ca522d42efa4	5092aee7-4566-4dd6-9040-7b7e4a2876b7	2026-09-18	UNKNOWN	2026-09-18 07:55:00+07	t	\N	2026-10-04 22:58:58.26+07
2783e45d-a868-4acd-8255-156b7432853e	0cd6bde6-3226-4ebb-b135-ca522d42efa4	85ace093-0622-4deb-84fd-f49f28528be6	2026-09-18	UNKNOWN	2026-09-18 16:05:00+07	t	\N	2026-10-04 22:58:58.261+07
d9c16e59-b685-4b7f-beb1-ea45fe213df1	0cd6bde6-3226-4ebb-b135-ca522d42efa4	699bd3c5-066e-4115-8f9d-0286df7bb280	2026-09-22	UNKNOWN	2026-09-22 07:55:00+07	t	\N	2026-10-04 22:58:58.262+07
a5bc305f-01c1-4a95-a675-4b13c7ab6d6d	0cd6bde6-3226-4ebb-b135-ca522d42efa4	390f28ff-cf54-4452-ad8c-4affe7160b0e	2026-09-22	UNKNOWN	2026-09-22 16:05:00+07	t	\N	2026-10-04 22:58:58.264+07
5a3fef76-fde7-4a88-9b3c-bc9d4a7bc717	0cd6bde6-3226-4ebb-b135-ca522d42efa4	4af2c218-5e39-4eb6-9ac6-a26de0316dba	2026-09-23	UNKNOWN	2026-09-23 07:55:00+07	t	\N	2026-10-04 22:58:58.267+07
624108a1-1b11-4909-b18f-60dc78e1e94b	0cd6bde6-3226-4ebb-b135-ca522d42efa4	18378748-aab2-4e70-aac4-6d01216f15a2	2026-09-23	UNKNOWN	2026-09-23 16:05:00+07	t	\N	2026-10-04 22:58:58.269+07
2904f2c2-ef2d-4363-87d6-572d6b63f754	0cd6bde6-3226-4ebb-b135-ca522d42efa4	df3da7e9-e588-49d1-aeb9-5f33278a46af	2026-09-24	UNKNOWN	2026-09-24 07:55:00+07	t	\N	2026-10-04 22:58:58.27+07
8862510c-773b-4b3e-b1a1-7b09ae7acec6	0cd6bde6-3226-4ebb-b135-ca522d42efa4	3b8c6bb5-ac42-4540-8f06-252c7f8d7eb9	2026-09-24	UNKNOWN	2026-09-24 16:05:00+07	t	\N	2026-10-04 22:58:58.272+07
7068a6bc-729b-4dae-972e-161c996f1544	0cd6bde6-3226-4ebb-b135-ca522d42efa4	98230324-9703-4b9f-b1fe-f990843890ae	2026-09-25	UNKNOWN	2026-09-25 07:55:00+07	t	\N	2026-10-04 22:58:58.273+07
c08b2765-75cf-4d70-b7bd-538a2a720db2	0cd6bde6-3226-4ebb-b135-ca522d42efa4	626947f6-e754-42c2-9df2-a8f08c8d52d1	2026-09-25	UNKNOWN	2026-09-25 16:05:00+07	t	\N	2026-10-04 22:58:58.274+07
48b9d305-75d8-41b8-9c62-778196c5f0eb	0cd6bde6-3226-4ebb-b135-ca522d42efa4	6d862dde-dbe2-4f0b-b424-d21d6178ae75	2026-09-28	UNKNOWN	2026-09-28 07:55:00+07	t	\N	2026-10-04 22:58:58.276+07
f95adaf7-41cd-4310-8463-731108879682	0cd6bde6-3226-4ebb-b135-ca522d42efa4	929b92e9-a734-4346-8797-b13ae56a81da	2026-09-28	UNKNOWN	2026-09-28 16:05:00+07	t	\N	2026-10-04 22:58:58.277+07
5fd05485-605b-4a1a-91d5-4e189f7b43a5	0cd6bde6-3226-4ebb-b135-ca522d42efa4	0d986183-45a6-487d-9774-aea13e16c3a7	2026-09-29	UNKNOWN	2026-09-29 07:55:00+07	t	\N	2026-10-04 22:58:58.278+07
acc59e5b-4d0f-49f0-853b-e36e3208709e	0cd6bde6-3226-4ebb-b135-ca522d42efa4	10dda120-9ecd-4685-b525-d83dbd59ab73	2026-09-29	UNKNOWN	2026-09-29 16:05:00+07	t	\N	2026-10-04 22:58:58.279+07
1152677c-3f52-4588-b02f-18b073d22261	0cd6bde6-3226-4ebb-b135-ca522d42efa4	6a762ebc-9f8e-4ef9-ae11-4ac22bc8f8b0	2026-09-30	UNKNOWN	2026-09-30 07:55:00+07	t	\N	2026-10-04 22:58:58.28+07
a58aca96-be10-4ddd-afe0-c3fded69cf8b	0cd6bde6-3226-4ebb-b135-ca522d42efa4	b4cc1c5d-4286-45e4-b612-fb28dbd8d638	2026-09-30	UNKNOWN	2026-09-30 16:05:00+07	t	\N	2026-10-04 22:58:58.282+07
d904efc5-f7a1-4adf-af7d-7f8fb3fa8d6f	0c685448-b52e-4e60-89ea-6f7c500a86d5	2e6776ee-bbad-450c-9b39-488c93f544e3	2026-09-01	UNKNOWN	2026-09-01 15:50:00+07	t	\N	2026-10-04 22:58:58.361+07
a2d72026-9706-4f72-a177-1c10b5ce91fb	0c685448-b52e-4e60-89ea-6f7c500a86d5	16a6e1c0-df6a-4aa5-919c-da6112b465b4	2026-09-01	UNKNOWN	2026-09-02 00:05:00+07	t	\N	2026-10-04 22:58:58.363+07
51cbaba9-0885-4bc2-9bc7-dfa1efd65bf1	4478787b-c3e8-4f0d-8b9b-7046fec7f539	f56c8be3-9876-493c-9084-76f669e792bf	2026-09-24	UNKNOWN	2026-09-24 16:10:00+07	t	\N	2026-10-04 22:58:58.142+07
76f83ce1-82ad-4fe9-bd79-a49df190046d	4478787b-c3e8-4f0d-8b9b-7046fec7f539	f9c44026-283e-4a29-ab91-3c0e95a11a9b	2026-09-25	UNKNOWN	2026-09-25 08:06:00+07	t	\N	2026-10-04 22:58:58.143+07
cb125e52-c3c1-474a-a8ac-ff9e77f094ba	23230ce1-1ab7-4b49-b9b2-404f149e00ca	aacd654e-ae3e-420a-8699-8fdc35de0bda	2026-09-01	UNKNOWN	2026-09-01 05:58:00+07	t	\N	2026-10-04 22:58:59.352+07
5efdc0a6-2aad-47a9-9504-b2062ee3729a	23230ce1-1ab7-4b49-b9b2-404f149e00ca	b1fd95b4-f783-4c08-96a6-e3590586e05e	2026-09-01	UNKNOWN	2026-09-01 14:00:00+07	t	\N	2026-10-04 22:58:59.354+07
4ea0c82b-f744-4c03-94a9-628b750dde6a	23230ce1-1ab7-4b49-b9b2-404f149e00ca	0951eeb2-f2fb-4bd6-9e70-8e6d23af5687	2026-09-02	UNKNOWN	2026-09-02 05:58:00+07	t	\N	2026-10-04 22:58:59.356+07
dcc6830e-5cb3-4905-b042-e29cf7b4a505	23230ce1-1ab7-4b49-b9b2-404f149e00ca	9f47602a-8a07-410f-970a-0710f070adf9	2026-09-02	UNKNOWN	2026-09-02 14:00:00+07	t	\N	2026-10-04 22:58:59.357+07
a77d4027-c69e-4c0e-abd4-8f4cb94e530b	23230ce1-1ab7-4b49-b9b2-404f149e00ca	da22d7dd-db79-438f-9335-7592a406f7f0	2026-09-03	UNKNOWN	2026-09-03 05:58:00+07	t	\N	2026-10-04 22:58:59.358+07
80aaf46e-6681-48cb-9622-6df5a2b105a5	0c685448-b52e-4e60-89ea-6f7c500a86d5	57df6be6-c808-4341-a740-d27912c57945	2026-09-03	UNKNOWN	2026-09-04 00:15:00+07	t	\N	2026-10-04 22:58:58.373+07
d5f5bd51-d3a8-4408-846b-36fa7623475e	0c685448-b52e-4e60-89ea-6f7c500a86d5	dc146fb7-0d82-4a6e-97ea-85c086ecec67	2026-09-04	UNKNOWN	2026-09-04 15:50:00+07	t	\N	2026-10-04 22:58:58.375+07
4b08aac5-bc8e-416f-8ee7-2221229f5eed	0c685448-b52e-4e60-89ea-6f7c500a86d5	57fb3804-5427-41b8-98e8-a84c2bdb780a	2026-09-04	UNKNOWN	2026-09-05 00:05:00+07	t	\N	2026-10-04 22:58:58.377+07
cfc7aadd-ed46-4925-ae14-300788ba7ab8	0c685448-b52e-4e60-89ea-6f7c500a86d5	735ef9e9-4606-4f80-a9de-7061e7b079ee	2026-09-07	UNKNOWN	2026-09-07 15:55:00+07	t	\N	2026-10-04 22:58:58.379+07
048abc4e-bdef-4188-99ff-f6b201666710	0c685448-b52e-4e60-89ea-6f7c500a86d5	1adb38f9-c795-4d3a-a66d-469e21bd3824	2026-09-07	UNKNOWN	2026-09-08 00:10:00+07	t	\N	2026-10-04 22:58:58.381+07
0da60493-6933-40b3-b549-220c6712be8c	0c685448-b52e-4e60-89ea-6f7c500a86d5	901dd607-143e-40bf-867e-eec742a24753	2026-09-08	UNKNOWN	2026-09-08 16:00:00+07	t	\N	2026-10-04 22:58:58.382+07
7258aa33-e124-4b6d-9baa-61c53536dd93	0c685448-b52e-4e60-89ea-6f7c500a86d5	40d009b0-de59-4abe-8b6e-a3758638a1a2	2026-09-08	UNKNOWN	2026-09-09 00:15:00+07	t	\N	2026-10-04 22:58:58.385+07
ccb39424-0823-4019-a10b-cbfaca3956c5	0c685448-b52e-4e60-89ea-6f7c500a86d5	4821e87f-6557-4927-a63d-01477434eed5	2026-09-09	UNKNOWN	2026-09-09 15:50:00+07	t	\N	2026-10-04 22:58:58.387+07
05440fa8-c14c-4254-8d32-30aa200b89d0	0c685448-b52e-4e60-89ea-6f7c500a86d5	dbb6e4d2-826d-4863-8a0f-e4fe09ae5a08	2026-09-09	UNKNOWN	2026-09-10 00:05:00+07	t	\N	2026-10-04 22:58:58.389+07
15e3ae12-9bd6-467f-97be-956537b6f226	0c685448-b52e-4e60-89ea-6f7c500a86d5	bb8a8ce2-bfa8-467e-bf98-494dd6f4811a	2026-09-10	UNKNOWN	2026-09-10 15:55:00+07	t	\N	2026-10-04 22:58:58.39+07
553398f1-2235-4dc1-9418-3e931ffcdc81	0c685448-b52e-4e60-89ea-6f7c500a86d5	e7913ede-4631-4571-8cdf-cd0d3c960f60	2026-09-10	UNKNOWN	2026-09-11 00:10:00+07	t	\N	2026-10-04 22:58:58.391+07
f13a36e1-a530-4c3a-b82f-61e650f4ed4b	0c685448-b52e-4e60-89ea-6f7c500a86d5	fe6b58ce-3639-4c02-a72b-6161bbcf7286	2026-09-11	UNKNOWN	2026-09-11 16:00:00+07	t	\N	2026-10-04 22:58:58.393+07
25016a0e-6294-4d3b-961f-a70c9eb6fcad	0c685448-b52e-4e60-89ea-6f7c500a86d5	176c28a4-4839-4fd7-a146-b06244b52a32	2026-09-11	UNKNOWN	2026-09-12 00:15:00+07	t	\N	2026-10-04 22:58:58.394+07
39e647f5-08f5-48f0-9151-232d528a95c4	0c685448-b52e-4e60-89ea-6f7c500a86d5	4907114e-63c1-4e45-a73e-14f7e2f3e8e8	2026-09-14	UNKNOWN	2026-09-14 16:35:00+07	t	\N	2026-10-04 22:58:58.396+07
00fd76e6-f26b-48a4-817b-d7d02404e42f	0c685448-b52e-4e60-89ea-6f7c500a86d5	bba88a1e-a8be-41d7-a8eb-c85499056fb2	2026-09-14	UNKNOWN	2026-09-15 00:05:00+07	t	\N	2026-10-04 22:58:58.399+07
581ebdbf-e856-4670-8920-322ec9c43399	0c685448-b52e-4e60-89ea-6f7c500a86d5	13e1e062-9a83-4a57-bfee-a8cd30e0a0d3	2026-09-15	UNKNOWN	2026-09-16 00:10:00+07	t	\N	2026-10-04 22:58:58.404+07
4a8e639f-9d08-4bee-9ccf-a1d7ad9f019f	0c685448-b52e-4e60-89ea-6f7c500a86d5	4fcbd60f-b469-436d-9494-96a917ca7594	2026-09-17	UNKNOWN	2026-09-17 16:00:00+07	t	\N	2026-10-04 22:58:58.406+07
6a1cc2e4-1466-43b4-96dd-5923842e26a5	0c685448-b52e-4e60-89ea-6f7c500a86d5	56e8f5ab-4f99-4c3d-973f-e16c05b47842	2026-09-17	UNKNOWN	2026-09-18 00:15:00+07	t	\N	2026-10-04 22:58:58.408+07
3dc2429d-4235-477a-a8bb-1644859d1725	0c685448-b52e-4e60-89ea-6f7c500a86d5	d8d958d5-edd2-4ecc-a819-e00d4f246da0	2026-09-18	UNKNOWN	2026-09-18 15:50:00+07	t	\N	2026-10-04 22:58:58.409+07
c82d5a0e-2d48-49a6-a8a5-4c327d7a9553	0c685448-b52e-4e60-89ea-6f7c500a86d5	bc69ced5-b1b6-42e1-9125-57439d41eb38	2026-09-18	UNKNOWN	2026-09-19 00:05:00+07	t	\N	2026-10-04 22:58:58.41+07
f855372c-2bc4-47c0-a496-2b1e02afd9f4	0c685448-b52e-4e60-89ea-6f7c500a86d5	3b8b426e-5539-4340-a970-a0647b725476	2026-09-21	UNKNOWN	2026-09-21 15:55:00+07	t	\N	2026-10-04 22:58:58.412+07
25068d2f-9237-40b6-ac76-238dff809976	0c685448-b52e-4e60-89ea-6f7c500a86d5	be06c2dd-a7bf-4d6d-8732-1ef56ad4b139	2026-09-21	UNKNOWN	2026-09-22 00:10:00+07	t	\N	2026-10-04 22:58:58.413+07
a8866828-c4d8-455b-bcfd-0b56ad53456a	0c685448-b52e-4e60-89ea-6f7c500a86d5	8c5981da-7df3-4cd9-927a-d650026e7e08	2026-09-22	UNKNOWN	2026-09-22 16:00:00+07	t	\N	2026-10-04 22:58:58.414+07
17d455c3-2b4c-44f7-b5cb-e40e24c84da1	0c685448-b52e-4e60-89ea-6f7c500a86d5	cd10895f-f22a-49d6-9104-0078ea9a3a5c	2026-09-22	UNKNOWN	2026-09-23 00:15:00+07	t	\N	2026-10-04 22:58:58.416+07
27f2938f-f0a2-4421-8f06-94f3b8141bb2	0c685448-b52e-4e60-89ea-6f7c500a86d5	6ac98480-6822-448a-9aa2-35fce5d15dfc	2026-09-23	UNKNOWN	2026-09-23 15:50:00+07	t	\N	2026-10-04 22:58:58.418+07
6cee2fd3-5cfe-4130-ba4b-6e25bc637b90	0c685448-b52e-4e60-89ea-6f7c500a86d5	8a826ec5-e1f8-4578-adde-234d77b772b6	2026-09-23	UNKNOWN	2026-09-24 00:05:00+07	t	\N	2026-10-04 22:58:58.42+07
c8e2ed07-93b5-4102-9270-569ef79c0997	0c685448-b52e-4e60-89ea-6f7c500a86d5	4663f411-9b64-4eba-be71-7829f8b614d6	2026-09-24	UNKNOWN	2026-09-24 15:55:00+07	t	\N	2026-10-04 22:58:58.422+07
dd3c3308-d3bc-4da9-8805-0a35590a73ee	0c685448-b52e-4e60-89ea-6f7c500a86d5	f37bebee-3790-4afd-bf00-86627864f97a	2026-09-24	UNKNOWN	2026-09-25 00:10:00+07	t	\N	2026-10-04 22:58:58.423+07
ef3917da-8c3e-40c0-85f8-2f929b8f76f5	0c685448-b52e-4e60-89ea-6f7c500a86d5	665affbf-0e6d-46b7-a339-f94d22b3fd2d	2026-09-25	UNKNOWN	2026-09-25 16:00:00+07	t	\N	2026-10-04 22:58:58.424+07
089d00e2-06a4-4b5d-b47c-f5ec5626af39	0c685448-b52e-4e60-89ea-6f7c500a86d5	4b23a9c2-f133-4bbf-83a5-a7488180a498	2026-09-25	UNKNOWN	2026-09-26 00:15:00+07	t	\N	2026-10-04 22:58:58.426+07
9cd4710d-fd85-427e-b2d1-37a2493e088f	0c685448-b52e-4e60-89ea-6f7c500a86d5	6af1cb8a-d0ed-4858-be6e-9991b16a93fa	2026-09-28	UNKNOWN	2026-09-28 15:50:00+07	t	\N	2026-10-04 22:58:58.427+07
e87c0a86-22e3-44f3-9868-a330870cb45a	0c685448-b52e-4e60-89ea-6f7c500a86d5	bcf2df49-0e05-47c8-ba05-5e5953af3622	2026-09-28	UNKNOWN	2026-09-29 00:05:00+07	t	\N	2026-10-04 22:58:58.428+07
d382a103-6973-4235-98fe-f74e273cfeac	0c685448-b52e-4e60-89ea-6f7c500a86d5	36a60454-706a-4542-bba6-bdd55a499aa4	2026-09-29	UNKNOWN	2026-09-29 15:55:00+07	t	\N	2026-10-04 22:58:58.429+07
fa2a55ca-05e7-4627-9b1e-9558004cf1b1	0c685448-b52e-4e60-89ea-6f7c500a86d5	21b98600-90a3-4d87-b514-143ab78cb0a4	2026-09-29	UNKNOWN	2026-09-30 00:10:00+07	t	\N	2026-10-04 22:58:58.432+07
c7af763e-eaab-4124-a688-938f3f5184d4	0c685448-b52e-4e60-89ea-6f7c500a86d5	7d1764e3-47e2-4f4a-bf73-a09484bbdbed	2026-09-30	UNKNOWN	2026-09-30 16:00:00+07	t	\N	2026-10-04 22:58:58.434+07
93adfeb2-978e-4dd9-b1eb-c57de2fe5b75	0c685448-b52e-4e60-89ea-6f7c500a86d5	56f9f68b-6443-4d9b-afbf-ff8654a3ca52	2026-09-30	UNKNOWN	2026-10-01 00:15:00+07	t	\N	2026-10-04 22:58:58.436+07
763283cb-377c-476d-b491-c05e324975ee	0c685448-b52e-4e60-89ea-6f7c500a86d5	80e3d41f-f844-4c5d-91ac-14ce171773e5	2026-09-02	UNKNOWN	2026-09-03 00:10:00+07	t	\N	2026-10-04 22:58:58.369+07
2c11a7f9-9792-4213-babf-6ca1f17f2337	0c685448-b52e-4e60-89ea-6f7c500a86d5	19cc4faf-ae28-4e90-b1bb-6a1c4543b7c7	2026-09-03	UNKNOWN	2026-09-03 16:00:00+07	t	\N	2026-10-04 22:58:58.371+07
a2dc0106-58ed-4904-ac4c-0bb5ae4f6f58	b7291f79-3495-44a5-b039-737465dc2cc0	12c6748d-c71b-46d6-86bc-77c14d974334	2026-09-02	UNKNOWN	2026-09-02 16:00:00+07	t	\N	2026-10-04 22:58:58.511+07
aed5a3ef-90bd-4c91-8f15-939b06fba142	b7291f79-3495-44a5-b039-737465dc2cc0	7cb05de4-04a5-427a-ab36-a95125ec93b0	2026-09-03	UNKNOWN	2026-09-03 08:00:00+07	t	\N	2026-10-04 22:58:58.513+07
236ad390-96cc-442a-bb06-611d6f0d0f9b	b7291f79-3495-44a5-b039-737465dc2cc0	922c0108-a274-400b-a63b-1e1359c562fe	2026-09-03	UNKNOWN	2026-09-03 16:00:00+07	t	\N	2026-10-04 22:58:58.514+07
b5bcb7e2-e114-4133-9fda-f43961af0b27	b7291f79-3495-44a5-b039-737465dc2cc0	21029d4c-82ea-4731-a428-f0830296be4a	2026-09-04	UNKNOWN	2026-09-04 16:00:00+07	t	\N	2026-10-04 22:58:58.519+07
82c532ce-e31d-4b0d-8824-0d67a38817d1	b7291f79-3495-44a5-b039-737465dc2cc0	4b3c588f-07d1-40e3-b1fc-d4fc769cd975	2026-09-06	UNKNOWN	2026-09-06 10:00:00+07	t	NO_MATCHING_SHIFT	2026-10-04 22:58:58.521+07
aace057d-f081-4460-b468-3bf541bec058	b7291f79-3495-44a5-b039-737465dc2cc0	9fe16699-3ccb-4bd2-8bcf-78940d108179	2026-09-06	UNKNOWN	2026-09-06 14:00:00+07	t	NO_MATCHING_SHIFT	2026-10-04 22:58:58.523+07
9f48051b-f33a-4896-8b58-c37d5f720579	b7291f79-3495-44a5-b039-737465dc2cc0	57f7e141-3e59-4652-88a6-513fd3b38bf2	2026-09-07	UNKNOWN	2026-09-07 08:00:00+07	t	\N	2026-10-04 22:58:58.524+07
732fb9d5-79b7-429b-9379-004eb9bed86c	b7291f79-3495-44a5-b039-737465dc2cc0	92fd36ff-09b1-4337-aed7-6e1a964fa78e	2026-09-07	UNKNOWN	2026-09-07 19:30:00+07	t	\N	2026-10-04 22:58:58.526+07
65d5977c-e6af-45c6-acec-7f9c67839a31	b7291f79-3495-44a5-b039-737465dc2cc0	f9ccc47f-c578-4965-b7fa-c2884a86e510	2026-09-08	UNKNOWN	2026-09-08 08:00:00+07	t	\N	2026-10-04 22:58:58.529+07
75294ecd-ea7b-4140-b658-1aaaba5f0861	b7291f79-3495-44a5-b039-737465dc2cc0	d7a7e9b8-11f4-4b04-8eab-5dde3c8c15fc	2026-09-08	UNKNOWN	2026-09-08 16:00:00+07	t	\N	2026-10-04 22:58:58.531+07
8e281ec0-cc22-40ae-a350-e2acd5376171	b7291f79-3495-44a5-b039-737465dc2cc0	47cbd118-e7e6-4073-b0cc-6dbac08257a3	2026-09-09	UNKNOWN	2026-09-09 08:00:00+07	t	\N	2026-10-04 22:58:58.534+07
9682be23-84ed-4804-82fe-d9324fd49817	b7291f79-3495-44a5-b039-737465dc2cc0	000673de-5654-4612-9214-3b9067de84de	2026-09-09	UNKNOWN	2026-09-09 16:00:00+07	t	\N	2026-10-04 22:58:58.537+07
e96add16-0cd0-4cd7-9474-289ccaa01c5a	b7291f79-3495-44a5-b039-737465dc2cc0	ba5ec725-3ff7-42c1-89d7-aaa6d1074f17	2026-09-10	UNKNOWN	2026-09-10 08:00:00+07	t	\N	2026-10-04 22:58:58.539+07
b946d8ad-f2b1-48e3-ab9f-e69557d47a69	b7291f79-3495-44a5-b039-737465dc2cc0	c9219bde-c982-4d6b-b537-1cbb3bc9d8d4	2026-09-10	UNKNOWN	2026-09-10 16:00:00+07	t	\N	2026-10-04 22:58:58.541+07
e4543943-bf7f-4d38-b574-ca0bcf9590f1	b7291f79-3495-44a5-b039-737465dc2cc0	a22f67b2-6db7-4dc0-a3aa-71487404b063	2026-09-11	UNKNOWN	2026-09-11 08:00:00+07	t	\N	2026-10-04 22:58:58.543+07
04cd1701-e4bf-48a2-916a-962d856073ca	b7291f79-3495-44a5-b039-737465dc2cc0	2062a6ab-0fe9-45f5-9b6c-e0712261bf17	2026-09-11	UNKNOWN	2026-09-11 19:30:00+07	t	\N	2026-10-04 22:58:58.544+07
a94683f7-01ed-44cf-813b-10427dc940bd	b7291f79-3495-44a5-b039-737465dc2cc0	754ae84d-fdbd-4095-a594-faaf0448075a	2026-09-12	UNKNOWN	2026-09-12 09:00:00+07	t	NO_MATCHING_SHIFT	2026-10-04 22:58:58.546+07
1f17f1af-b6b0-48ff-8c53-109f45ac1a4a	b7291f79-3495-44a5-b039-737465dc2cc0	d111690d-4f14-4f07-aeb0-3cdbd432c75d	2026-09-12	UNKNOWN	2026-09-12 13:00:00+07	t	NO_MATCHING_SHIFT	2026-10-04 22:58:58.548+07
1ef7713c-32f3-4ac0-9cf3-12cebac9823e	b7291f79-3495-44a5-b039-737465dc2cc0	a2953b6b-1adb-499c-943d-6ce6e4fd30ca	2026-09-14	UNKNOWN	2026-09-14 08:00:00+07	t	\N	2026-10-04 22:58:58.551+07
7011b22e-2e6b-4b49-88b3-f145468ef96c	b7291f79-3495-44a5-b039-737465dc2cc0	7285efd7-1338-4772-919b-88e1915b110f	2026-09-14	UNKNOWN	2026-09-14 16:00:00+07	t	\N	2026-10-04 22:58:58.553+07
2d9aca7d-b01e-41e0-bc17-a28f5c0987d8	b7291f79-3495-44a5-b039-737465dc2cc0	4dfc143e-46cb-4eb9-b2f7-724567371fd2	2026-09-15	UNKNOWN	2026-09-15 08:00:00+07	t	\N	2026-10-04 22:58:58.555+07
d4a32b63-c50c-4417-8352-2ff72c04c632	b7291f79-3495-44a5-b039-737465dc2cc0	c78d4a70-4ac3-421c-811f-1e17685468cd	2026-09-15	UNKNOWN	2026-09-15 16:00:00+07	t	\N	2026-10-04 22:58:58.557+07
23c1b199-1c34-4713-a416-13a55645cf74	b7291f79-3495-44a5-b039-737465dc2cc0	dea66232-6466-45d4-9b4d-a3a1608fa87a	2026-09-17	UNKNOWN	2026-09-17 08:00:00+07	t	\N	2026-10-04 22:58:58.559+07
e86c4c84-e61b-4fd3-bc4e-c4c9017b567e	b7291f79-3495-44a5-b039-737465dc2cc0	03321d49-0218-43e1-8a64-b3ad75240a9e	2026-09-17	UNKNOWN	2026-09-17 16:00:00+07	t	\N	2026-10-04 22:58:58.561+07
05215682-7b97-474f-b836-d79e70b3745b	b7291f79-3495-44a5-b039-737465dc2cc0	55ad2e89-c779-45db-8a2c-35acd60b1ac4	2026-09-18	UNKNOWN	2026-09-18 08:00:00+07	t	\N	2026-10-04 22:58:58.563+07
65cce5cd-ffa7-402a-b6b1-961dfc8c5ce1	b7291f79-3495-44a5-b039-737465dc2cc0	e8eb04ee-82f7-4542-9937-2a3d3abc9e28	2026-09-18	UNKNOWN	2026-09-18 19:30:00+07	t	\N	2026-10-04 22:58:58.565+07
2a071fd9-0050-422f-939b-95c923f6c9ae	b7291f79-3495-44a5-b039-737465dc2cc0	32b37a7d-e6b9-4006-93a7-45f22f871e97	2026-09-19	UNKNOWN	2026-09-19 09:00:00+07	t	NO_MATCHING_SHIFT	2026-10-04 22:58:58.568+07
ff37955f-4480-408c-8538-c52aa1dc5359	b7291f79-3495-44a5-b039-737465dc2cc0	8db4b301-6464-4f55-be19-4f61e994afd4	2026-09-19	UNKNOWN	2026-09-19 13:00:00+07	t	NO_MATCHING_SHIFT	2026-10-04 22:58:58.571+07
06782cfc-c410-4afe-9372-7f288208608a	b7291f79-3495-44a5-b039-737465dc2cc0	c4e76cfb-cc12-43d9-8b97-c9a1668db4e1	2026-09-21	UNKNOWN	2026-09-21 08:00:00+07	t	\N	2026-10-04 22:58:58.574+07
54ba325c-f2b4-462b-8fde-58c635d32fe5	b7291f79-3495-44a5-b039-737465dc2cc0	74cf16df-dbc6-42c3-945f-5befb4e3490c	2026-09-21	UNKNOWN	2026-09-21 16:00:00+07	t	\N	2026-10-04 22:58:58.576+07
3e1031d7-b27b-4708-bd8c-38833a744fb5	b7291f79-3495-44a5-b039-737465dc2cc0	8c7f0af2-9953-416a-ac29-b56735bb5e8b	2026-09-22	UNKNOWN	2026-09-22 08:00:00+07	t	\N	2026-10-04 22:58:58.577+07
fbe66e84-dee7-482d-92c0-fc1312d8b502	b7291f79-3495-44a5-b039-737465dc2cc0	0df28c17-b4e0-4b1a-bdb2-33af24423197	2026-09-22	UNKNOWN	2026-09-22 16:00:00+07	t	\N	2026-10-04 22:58:58.578+07
28b76eea-9e75-4c54-ba93-19940caf5802	b7291f79-3495-44a5-b039-737465dc2cc0	775568f4-665f-428c-8265-eb992235300b	2026-09-23	UNKNOWN	2026-09-23 08:00:00+07	t	\N	2026-10-04 22:58:58.58+07
1c5d090d-f20b-4412-bd2b-4eb8b31e1cf8	b7291f79-3495-44a5-b039-737465dc2cc0	9158c9a9-8613-4867-b945-c0845c9f7526	2026-09-23	UNKNOWN	2026-09-23 16:00:00+07	t	\N	2026-10-04 22:58:58.582+07
2e57e063-fbf4-4c42-b3cc-34fbecc33900	b7291f79-3495-44a5-b039-737465dc2cc0	fbae514b-04a6-40c3-bcd3-c0084cbffb2c	2026-09-24	UNKNOWN	2026-09-24 08:00:00+07	t	\N	2026-10-04 22:58:58.585+07
008fb945-73f2-4d00-a7c6-1e0a1cf60b40	b7291f79-3495-44a5-b039-737465dc2cc0	22a6d7ba-633f-464a-af67-67e7e0e5bfb9	2026-09-24	UNKNOWN	2026-09-24 19:30:00+07	t	\N	2026-10-04 22:58:58.587+07
e0c8a047-2320-4a14-8a3f-ae129a971af5	b7291f79-3495-44a5-b039-737465dc2cc0	4bd58806-44d2-43c6-84d7-bae58202f1d2	2026-09-25	UNKNOWN	2026-09-25 08:00:00+07	t	\N	2026-10-04 22:58:58.589+07
9902b1a1-7bf7-4ffc-8ff9-722965411c7a	b7291f79-3495-44a5-b039-737465dc2cc0	cdb84eb4-74d3-48ea-9bc4-be10ecb7b5f7	2026-09-25	UNKNOWN	2026-09-25 16:00:00+07	t	\N	2026-10-04 22:58:58.59+07
4e1293af-2345-45f5-84bf-e3e2b89349a6	b7291f79-3495-44a5-b039-737465dc2cc0	8721aa88-3268-4c02-95ff-1dc6df3ad772	2026-09-28	UNKNOWN	2026-09-28 08:00:00+07	t	\N	2026-10-04 22:58:58.592+07
9105111e-bac1-464b-b4bc-54b153b6e7e6	b7291f79-3495-44a5-b039-737465dc2cc0	380994c2-04b7-4abd-b5c5-4f04a6007893	2026-09-28	UNKNOWN	2026-09-28 16:00:00+07	t	\N	2026-10-04 22:58:58.593+07
088efd5a-be8f-4af6-bb82-9053353ebc2b	b7291f79-3495-44a5-b039-737465dc2cc0	34846053-b12b-42eb-bf43-f431dcb519b0	2026-09-29	UNKNOWN	2026-09-29 08:00:00+07	t	\N	2026-10-04 22:58:58.595+07
00bcba72-e11b-489b-8b31-e0ff7152d94f	b7291f79-3495-44a5-b039-737465dc2cc0	df5382c7-c48b-4371-aac7-f922e9758e5d	2026-09-01	UNKNOWN	2026-09-01 19:30:00+07	t	\N	2026-10-04 22:58:58.506+07
1debe00b-4f6a-4566-803a-ab0839034817	b7291f79-3495-44a5-b039-737465dc2cc0	0700a71f-9066-4764-94dc-c4082b7371d2	2026-09-02	UNKNOWN	2026-09-02 08:00:00+07	t	\N	2026-10-04 22:58:58.51+07
a2edd4ca-ee77-4e11-94fd-f7bf08293edb	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	c4602e91-8562-4154-9d34-b067110578de	2026-09-01	UNKNOWN	2026-09-01 07:55:00+07	t	\N	2026-10-04 22:58:58.662+07
feb6837d-dac4-458d-8f96-0aba48669257	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	f7e6abcb-3c69-4d27-8c79-00eb16a93733	2026-09-01	UNKNOWN	2026-09-01 16:00:00+07	t	\N	2026-10-04 22:58:58.664+07
87e4538a-150b-4b0c-ae41-c35c9c6af89c	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	0db129e7-62b2-4e04-b6b7-5c7f32264581	2026-09-02	UNKNOWN	2026-09-02 07:59:00+07	t	\N	2026-10-04 22:58:58.667+07
afe17578-4100-4d17-a791-355c1b347a8f	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	490589cd-9464-4400-bfd3-196217a457c1	2026-09-02	UNKNOWN	2026-09-02 16:00:00+07	t	\N	2026-10-04 22:58:58.669+07
b99a121a-4bf0-44b0-a76f-d34dbdc7386a	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	39757576-c5ce-40a4-bf29-cee6d31357bc	2026-09-03	UNKNOWN	2026-09-03 08:03:00+07	t	\N	2026-10-04 22:58:58.672+07
c8343130-84a4-4cb3-9cb7-c06bf9572009	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	cb4f9d23-79ba-46cb-ab2b-594b05f0a0e9	2026-09-03	UNKNOWN	2026-09-03 16:00:00+07	t	\N	2026-10-04 22:58:58.673+07
8bd296c3-8654-4296-b826-5504fed284b7	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	5daa54c9-b7d6-4e98-9c5a-262318e33a22	2026-09-04	UNKNOWN	2026-09-04 07:55:00+07	t	\N	2026-10-04 22:58:58.674+07
309f5800-aca8-4e7f-8766-c8b6a4bea114	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	639da52c-056a-4738-a866-cf4d2d89ecb6	2026-09-04	UNKNOWN	2026-09-04 16:00:00+07	t	\N	2026-10-04 22:58:58.676+07
791c5eb4-3295-4618-a6bb-f9c8b1628863	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	282e4f3a-59b0-437b-b4f4-1319538d49b9	2026-09-07	UNKNOWN	2026-09-07 07:59:00+07	t	\N	2026-10-04 22:58:58.677+07
865b4c0f-2811-4b04-a551-342130e025e5	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	6d46735b-aa0d-4b87-8d83-34f64310a959	2026-09-07	UNKNOWN	2026-09-07 16:00:00+07	t	\N	2026-10-04 22:58:58.678+07
29805ff9-62f2-4222-8f6f-b017d4c0f163	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	11e8188d-7bfd-499c-9e83-979de305acea	2026-09-08	UNKNOWN	2026-09-08 08:03:00+07	t	\N	2026-10-04 22:58:58.679+07
14587108-fc80-4745-b3c8-307354e2ee7d	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	086f545c-fc07-4c09-8dde-09a422988204	2026-09-08	UNKNOWN	2026-09-08 16:00:00+07	t	\N	2026-10-04 22:58:58.68+07
9a593be3-bff9-4e63-91b7-9ccbb3a954e8	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	94caa112-382d-487e-80ae-c18ac868ddf8	2026-09-09	UNKNOWN	2026-09-09 07:55:00+07	t	\N	2026-10-04 22:58:58.682+07
930fbf54-23ec-438e-a110-c02132be7955	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	aa867d7e-b7ae-4e23-ad3d-a04e684dfded	2026-09-09	UNKNOWN	2026-09-09 16:00:00+07	t	\N	2026-10-04 22:58:58.684+07
00632101-02cf-4700-a193-c8b74dc6068c	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	a540a367-c255-417b-8780-061f5033c265	2026-09-10	UNKNOWN	2026-09-10 07:59:00+07	t	\N	2026-10-04 22:58:58.686+07
151da1e3-5de1-46c3-aca8-094a428ee628	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	34a78bfb-a6a4-4d24-a306-6f0063e21857	2026-09-11	UNKNOWN	2026-09-11 08:03:00+07	t	\N	2026-10-04 22:58:58.689+07
aaf50032-ebf4-4ce4-9c9a-0037088d4607	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	f0a6cdb2-0a7c-445e-82c6-07eb8e12436c	2026-09-11	UNKNOWN	2026-09-11 16:00:00+07	t	\N	2026-10-04 22:58:58.69+07
efcfad17-57a4-416e-8f30-6be2923c1673	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	abdc3b00-d4c1-4b7c-a26f-e2364dce088c	2026-09-14	UNKNOWN	2026-09-14 07:55:00+07	t	\N	2026-10-04 22:58:58.691+07
ff81dd6f-0a40-4d61-9015-af025f6b8194	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	6d4eb7c9-baed-4241-affa-240ed8c97683	2026-09-14	UNKNOWN	2026-09-14 16:00:00+07	t	\N	2026-10-04 22:58:58.692+07
49797b43-6e9d-4f88-b4e4-580ff81c7c7f	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	38c9e6d8-ece7-4e95-bfe7-8e24a73236cd	2026-09-15	UNKNOWN	2026-09-15 07:59:00+07	t	\N	2026-10-04 22:58:58.694+07
a13552c9-efe1-4431-bee4-ea9a90dd0ad9	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	67746e4b-1467-49d8-a508-2f02cea92fb5	2026-09-15	UNKNOWN	2026-09-15 16:00:00+07	t	\N	2026-10-04 22:58:58.695+07
3cf1d8c1-51bc-4ea4-87d4-a5ad67f5f22e	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	9862d7d3-d54b-4bb5-a73a-dee3c0baf066	2026-09-17	UNKNOWN	2026-09-17 08:03:00+07	t	\N	2026-10-04 22:58:58.696+07
eca20bee-3e99-4712-b727-518fafee0e10	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	bf5bf0a9-62bc-4dfc-8011-eb472702cb6c	2026-09-17	UNKNOWN	2026-09-17 16:00:00+07	t	\N	2026-10-04 22:58:58.697+07
0abc0325-69f6-4ccf-8aab-7cb8cc4eedb3	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	bc1932fe-78e7-496a-a07d-3b051b89edc3	2026-09-18	UNKNOWN	2026-09-18 07:55:00+07	t	\N	2026-10-04 22:58:58.699+07
9c1196b3-4ca2-434c-aa5a-444ef68db569	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	961cad9d-9dcc-4586-9bfc-b008e12eb7ef	2026-09-18	UNKNOWN	2026-09-18 16:00:00+07	t	\N	2026-10-04 22:58:58.7+07
358d5bfe-ef0c-406b-a019-1b02d124fa98	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	ab211968-666b-43af-8477-02eb55b6db54	2026-09-21	UNKNOWN	2026-09-21 07:59:00+07	t	\N	2026-10-04 22:58:58.702+07
26caf1d8-22f0-4abe-b444-0692ccc61659	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	b220f76e-b0f5-4d2b-9c03-1c6b4b7a5e76	2026-09-21	UNKNOWN	2026-09-21 16:00:00+07	t	\N	2026-10-04 22:58:58.704+07
c2b45185-e8f2-485e-a181-d60a5df7491d	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	97b092a3-af00-4e7b-87d2-6ca9144df6dd	2026-09-22	UNKNOWN	2026-09-22 08:03:00+07	t	\N	2026-10-04 22:58:58.705+07
5cf4df85-c9d9-4d33-97fd-b755d3755670	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	a7854247-7f16-401d-8999-197d477efe99	2026-09-22	UNKNOWN	2026-09-22 16:00:00+07	t	\N	2026-10-04 22:58:58.707+07
202c83e5-b60a-492a-a917-c8bc88c3bc20	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	24e00768-8451-49d0-bb13-be35af53f0e9	2026-09-23	UNKNOWN	2026-09-23 07:55:00+07	t	\N	2026-10-04 22:58:58.708+07
9bc7133c-4a9a-4b50-9c9f-336844cff935	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	b0af030e-d506-42a6-a71b-5e58c3788ff0	2026-09-23	UNKNOWN	2026-09-23 16:00:00+07	t	\N	2026-10-04 22:58:58.709+07
4bd90e65-21ee-4981-a3b1-023d44928daf	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	b8bc9c1f-444a-416e-a590-c23f46a0f74c	2026-09-24	UNKNOWN	2026-09-24 07:59:00+07	t	\N	2026-10-04 22:58:58.71+07
de292853-b054-4b78-9360-4ef553a95a86	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	50c2267f-f705-4693-8629-f8076af36225	2026-09-24	UNKNOWN	2026-09-24 16:00:00+07	t	\N	2026-10-04 22:58:58.712+07
6ef1fc81-f449-4d01-b15d-90b18e00cf8a	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	11e154f1-b2e3-4dff-b9f4-92cd643656b1	2026-09-25	UNKNOWN	2026-09-25 08:03:00+07	t	\N	2026-10-04 22:58:58.713+07
d54e18a8-0144-4330-a85e-63e99b31c0a8	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	e7904140-c997-4c14-99dd-b6d03d8f2573	2026-09-25	UNKNOWN	2026-09-25 16:00:00+07	t	\N	2026-10-04 22:58:58.715+07
c3bf9125-3eb2-4bba-adc2-4db6427c3dd5	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	204edcb7-8f8c-4be7-9688-343ba9094eb6	2026-09-28	UNKNOWN	2026-09-28 07:55:00+07	t	\N	2026-10-04 22:58:58.716+07
76526b80-eded-4862-8eb9-e385e140a273	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	5f0a13fa-9576-4cdb-8383-e243bc2adbdf	2026-09-28	UNKNOWN	2026-09-28 16:00:00+07	t	\N	2026-10-04 22:58:58.718+07
cb896b32-06fc-489e-8cc9-3f91fb68dbbf	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	d5d8b79b-b114-4955-be42-30ee1a84a28a	2026-09-29	UNKNOWN	2026-09-29 07:59:00+07	t	\N	2026-10-04 22:58:58.72+07
ba1b1700-59c4-4c3c-b4e0-2e05594c5aa8	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	7ab72382-cb54-4994-a7a4-b1e2998df575	2026-09-29	UNKNOWN	2026-09-29 16:00:00+07	t	\N	2026-10-04 22:58:58.722+07
f5fa74cb-faf6-43aa-a345-77773e779443	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	d5655c51-2b78-4198-a046-241aeea7170c	2026-09-30	UNKNOWN	2026-09-30 08:03:00+07	t	\N	2026-10-04 22:58:58.723+07
81f15d4a-4f83-495b-8025-1cf889a78fc7	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	e40ef38f-8f26-4ab1-b0c2-b40b2261be78	2026-09-30	UNKNOWN	2026-09-30 16:00:00+07	t	\N	2026-10-04 22:58:58.725+07
dc92ed32-6100-4b94-aaf6-3966389d3e6f	b7291f79-3495-44a5-b039-737465dc2cc0	9ab6da9e-73b0-47cf-808b-f7c903d20c6b	2026-09-30	UNKNOWN	2026-09-30 08:00:00+07	t	\N	2026-10-04 22:58:58.599+07
6b688211-eb59-4551-95eb-7784559000e9	b7291f79-3495-44a5-b039-737465dc2cc0	5cd54e58-ece1-4a1e-91bc-5c60efe3d2df	2026-09-30	UNKNOWN	2026-09-30 19:30:00+07	t	\N	2026-10-04 22:58:58.602+07
35c46b1d-8dee-4a4b-8393-9b1f927a048b	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	a1ebfdae-cc23-4312-bc32-6b69bacc30a7	2026-09-02	UNKNOWN	2026-09-02 06:58:00+07	t	\N	2026-10-04 22:58:58.996+07
b11f4aef-3dfc-49b0-9bbf-81a250c80a1d	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	cf92d996-de1a-40e3-9814-8f7a077e4c88	2026-09-02	UNKNOWN	2026-09-02 15:02:00+07	t	\N	2026-10-04 22:58:58.998+07
96ed384c-14ad-4ee4-887d-56d9dccc6731	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	4d8292ef-2eb3-4bea-ae0f-8cc7148ae173	2026-09-03	UNKNOWN	2026-09-03 06:58:00+07	t	\N	2026-10-04 22:58:59+07
8c92fd74-6763-4685-8e5e-1ca38254fcf5	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	bf40a4d5-f2b9-43e3-b4ba-be169abfdef5	2026-09-03	UNKNOWN	2026-09-03 15:02:00+07	t	\N	2026-10-04 22:58:59.002+07
7f81efae-61b1-4b40-a537-f52495fe63c6	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	b932fa85-2c45-4411-8500-c82989d956d4	2026-09-04	UNKNOWN	2026-09-04 06:58:00+07	t	\N	2026-10-04 22:58:59.004+07
e44da331-57a5-4f5b-b464-4717171c1592	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	51e65c59-79e0-41ab-812e-6d146148d8b9	2026-09-04	UNKNOWN	2026-09-04 15:02:00+07	t	\N	2026-10-04 22:58:59.006+07
be55e37f-0da5-43f2-a3e6-ae19b7d27a0c	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	8865d494-80cf-4fb5-aeb3-a5a710e68706	2026-09-07	UNKNOWN	2026-09-07 06:58:00+07	t	\N	2026-10-04 22:58:59.008+07
41f664c7-a850-4487-97a5-3d6d15afb1cc	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	8fccb23f-fad0-4765-98a5-101082e1e329	2026-09-07	UNKNOWN	2026-09-07 15:02:00+07	t	\N	2026-10-04 22:58:59.009+07
e4889098-56c7-4f9e-bc91-4ed531b88f9f	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	1b61c9bb-ea4a-4ac8-90ab-e10bc5471158	2026-09-08	UNKNOWN	2026-09-08 06:58:00+07	t	\N	2026-10-04 22:58:59.011+07
93f0ad74-ec47-43ad-9c83-cde79ff772a8	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	e0a6930f-d6fc-4785-8c66-32f01e63bdce	2026-09-08	UNKNOWN	2026-09-08 15:02:00+07	t	\N	2026-10-04 22:58:59.012+07
c45424c4-8b43-46a1-be0d-fdec37c0884b	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	966477db-a09b-4473-aa6c-cb76a436dead	2026-09-09	UNKNOWN	2026-09-09 06:58:00+07	t	\N	2026-10-04 22:58:59.014+07
14d56e07-83e5-4dcb-89b4-c4b54ed4b01b	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	4d05bc31-3903-4ce1-b874-c9511d901dc9	2026-09-09	UNKNOWN	2026-09-09 15:02:00+07	t	\N	2026-10-04 22:58:59.016+07
6aeece37-6fe6-4bd0-9812-255762d79162	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	99d29340-f7cd-481c-832e-e944e7338b54	2026-09-10	UNKNOWN	2026-09-10 06:58:00+07	t	\N	2026-10-04 22:58:59.019+07
8526e977-0ebe-42f4-8a27-90da8819bc89	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	e80ed7d6-fad7-47b8-8d4e-fcf7407258f2	2026-09-10	UNKNOWN	2026-09-10 15:02:00+07	t	\N	2026-10-04 22:58:59.021+07
5d231133-a1ea-4656-b127-8230f7321b01	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	4d41fc82-587d-488a-9792-f9b17844470c	2026-09-11	UNKNOWN	2026-09-11 06:58:00+07	t	\N	2026-10-04 22:58:59.022+07
529c2c19-92a0-4436-8519-7638c50e623a	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	1f1a7ce6-cd23-46ed-8d97-fc1d17cb120a	2026-09-11	UNKNOWN	2026-09-11 15:02:00+07	t	\N	2026-10-04 22:58:59.024+07
0397b116-a668-4f0b-826f-f45cbf6688e0	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	af362633-96b3-444a-bbdf-d0a819b3fffa	2026-09-14	UNKNOWN	2026-09-14 15:02:00+07	t	\N	2026-10-04 22:58:59.029+07
7ffee4d4-0e43-4ccb-af5a-df1922b6f954	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	6ea6192b-1cb4-4ff0-b186-ae1ee611c8f8	2026-09-15	UNKNOWN	2026-09-15 06:58:00+07	t	\N	2026-10-04 22:58:59.031+07
0a30d786-93dc-4c52-a119-8b1e5ed61ab2	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	24df5cfd-416e-4a57-b7e9-96b3ca4256ab	2026-09-15	UNKNOWN	2026-09-15 15:02:00+07	t	\N	2026-10-04 22:58:59.033+07
7b40ccf0-dea9-4410-b478-3d7bc03fede6	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	487226c2-b62d-4f66-8197-8bf119db0d8c	2026-09-17	UNKNOWN	2026-09-17 06:58:00+07	t	\N	2026-10-04 22:58:59.037+07
256868cb-808b-4b38-a5a1-581d41d5c7f8	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	c557690e-d477-4927-841d-2d8bd3ef3c51	2026-09-17	UNKNOWN	2026-09-17 15:02:00+07	t	\N	2026-10-04 22:58:59.039+07
fd07fb76-b7f8-4c64-9110-adc83c5fe13e	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	0ac65560-471f-43ba-b155-601af40e4cda	2026-09-18	UNKNOWN	2026-09-18 06:58:00+07	t	\N	2026-10-04 22:58:59.041+07
194803a6-316c-4aa9-8563-463ccf8e3fc0	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	7f1f766b-8f15-480f-a6d7-93d5a2ff4e32	2026-09-18	UNKNOWN	2026-09-18 15:02:00+07	t	\N	2026-10-04 22:58:59.043+07
6fc7f62a-184d-4b30-9f7d-89125246f9d9	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	da12899a-fcb4-4d2f-b48a-e56f379ef8a6	2026-09-21	UNKNOWN	2026-09-21 06:58:00+07	t	\N	2026-10-04 22:58:59.044+07
e431aaea-5804-4de5-801d-f3be54bec5b3	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	657244e5-a077-490c-a6be-6d5e89a9388f	2026-09-21	UNKNOWN	2026-09-21 15:02:00+07	t	\N	2026-10-04 22:58:59.046+07
49801725-fc22-49dd-8fb9-14e196d24350	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	33100643-37c9-413a-a7ff-77eb1eb8f9b9	2026-09-23	UNKNOWN	2026-09-23 06:58:00+07	t	\N	2026-10-04 22:58:59.047+07
84f8e26f-600f-4777-a8c7-b9170fef34a2	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	42edfd06-41e5-4790-b519-62f3ae4b1840	2026-09-23	UNKNOWN	2026-09-23 15:02:00+07	t	\N	2026-10-04 22:58:59.048+07
4973a46d-0462-4af9-accf-6202f2bc0e6a	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	00267f4f-9119-4aec-94ec-1b112a27ec3f	2026-09-24	UNKNOWN	2026-09-24 06:58:00+07	t	\N	2026-10-04 22:58:59.051+07
e25fec43-d024-47dc-aa6d-545bdb423e56	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	ccf84167-b103-4a8f-ac6a-3495d3d01978	2026-09-24	UNKNOWN	2026-09-24 15:02:00+07	t	\N	2026-10-04 22:58:59.053+07
0056ffa9-61f9-41b1-9f40-185856adaf7c	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	850975b8-8731-44b5-ac60-8bc9ea78e08e	2026-09-25	UNKNOWN	2026-09-25 06:58:00+07	t	\N	2026-10-04 22:58:59.055+07
7738eaf5-e6ab-4045-89bf-e859dcc49e2d	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	547e42ac-e6aa-4562-b711-9e9359b91d53	2026-09-25	UNKNOWN	2026-09-25 15:02:00+07	t	\N	2026-10-04 22:58:59.057+07
0ce97dba-95bd-4b98-8ced-de72c42cfdfa	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	607180cb-e16a-4613-b787-eb6da524ad3f	2026-09-28	UNKNOWN	2026-09-28 06:58:00+07	t	\N	2026-10-04 22:58:59.059+07
17b8d2f8-d138-47f2-986a-f1e13876bb1d	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	dad209a3-f19f-44ab-996e-8446a963b1d2	2026-09-28	UNKNOWN	2026-09-28 15:02:00+07	t	\N	2026-10-04 22:58:59.061+07
10303a13-4778-49bc-8043-66e08611083f	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	dcdb565b-7bab-471c-9204-7655e663b7c1	2026-09-29	UNKNOWN	2026-09-29 06:58:00+07	t	\N	2026-10-04 22:58:59.063+07
c9d037ed-dbea-43b1-995c-4858f19324d3	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	0a2034f1-86c9-449e-947c-c57bf6323355	2026-09-29	UNKNOWN	2026-09-29 15:02:00+07	t	\N	2026-10-04 22:58:59.064+07
3981ad64-b93e-4357-a308-abba79e18cb6	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	263a0e53-4478-4b38-a490-d9a5ead5afa0	2026-09-30	UNKNOWN	2026-09-30 06:58:00+07	t	\N	2026-10-04 22:58:59.067+07
479e123f-07f0-4c4f-8389-aaf49b123344	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	ab69094c-24ea-4591-a42e-3eed0c508934	2026-09-30	UNKNOWN	2026-09-30 15:02:00+07	t	\N	2026-10-04 22:58:59.07+07
441a712a-6853-41da-9758-b06b6c53b10c	6a65b903-7cb2-468b-8245-a607e73baa54	7806cece-a667-481b-956f-4f48e306de27	2026-09-15	UNKNOWN	2026-09-15 16:15:00+07	t	\N	2026-10-04 22:58:57.792+07
8daf63c8-a223-4ca0-828f-c300e830e3c0	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	f7d3f2e3-fa05-4e9b-8800-727f825bfa46	2026-09-01	UNKNOWN	2026-09-01 06:58:00+07	t	\N	2026-10-04 22:58:58.991+07
1db36330-ca46-4f0c-ba64-f0d978dfa3a4	6a65b903-7cb2-468b-8245-a607e73baa54	f4e3c01c-baf6-40b6-9ac8-12fb96d76024	2026-09-29	UNKNOWN	2026-09-29 16:15:00+07	t	\N	2026-10-04 22:58:57.83+07
3a1be77f-844a-468d-a6d2-873be50ac291	4478787b-c3e8-4f0d-8b9b-7046fec7f539	0f537e3d-559d-40b7-9233-a313d0dd98df	2026-09-01	UNKNOWN	2026-09-01 08:00:00+07	t	\N	2026-10-04 22:58:58.077+07
a8e7efff-5dc4-4b02-a0ee-600e0c4d85ab	4478787b-c3e8-4f0d-8b9b-7046fec7f539	c44f4bcb-8aa7-4562-ac56-e959587d12b4	2026-09-24	UNKNOWN	2026-09-24 08:03:00+07	t	\N	2026-10-04 22:58:58.14+07
892fcf36-6a81-4c58-94da-15984ed9b73b	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	aeec2949-0c89-4aa1-853b-c2c9784fcd46	2026-09-01	UNKNOWN	2026-09-01 15:02:00+07	t	\N	2026-10-04 22:58:58.994+07
9c0ea376-0226-4b82-a60a-212b74fdb033	3193d9a5-6017-4441-b40c-f22e9ec9b867	81608ede-3f5e-4c39-ad5f-6375f6c56eb7	2026-09-02	UNKNOWN	2026-09-02 21:00:00+07	t	\N	2026-10-04 22:58:59.151+07
78814668-be91-4795-9871-c41b20f0b069	3193d9a5-6017-4441-b40c-f22e9ec9b867	8cd4e044-9a8f-489f-a520-ab6d29567b3b	2026-09-02	UNKNOWN	2026-09-03 05:05:00+07	t	\N	2026-10-04 22:58:59.153+07
57f4aecf-c9d0-4652-ac24-65f7d0ef10ae	3193d9a5-6017-4441-b40c-f22e9ec9b867	f4aa0a21-5e25-420f-9831-491a38b155ab	2026-09-03	UNKNOWN	2026-09-03 21:05:00+07	t	\N	2026-10-04 22:58:59.156+07
b1a2af71-ec1f-416b-8bfd-82ab23614e3e	3193d9a5-6017-4441-b40c-f22e9ec9b867	f2a66dc7-044c-4fee-9cb4-85a7dc3e502f	2026-09-03	UNKNOWN	2026-09-04 05:05:00+07	t	\N	2026-10-04 22:58:59.159+07
a314bf0c-1c11-4f2d-ad71-37a7a8525c3a	3193d9a5-6017-4441-b40c-f22e9ec9b867	9516bc9c-330a-48d4-ba5e-8137b48c6e12	2026-09-04	UNKNOWN	2026-09-04 20:55:00+07	t	\N	2026-10-04 22:58:59.16+07
71616336-ba27-496c-bc8f-5edd9da0d53d	3193d9a5-6017-4441-b40c-f22e9ec9b867	f312b8ba-3365-4b44-b843-5d2f8118d7ce	2026-09-04	UNKNOWN	2026-09-05 05:05:00+07	t	\N	2026-10-04 22:58:59.163+07
72bbab6a-7eaf-4c91-8bc0-02dbb2087c15	3193d9a5-6017-4441-b40c-f22e9ec9b867	3e8c8b43-3857-4ed3-8d1d-3527cdd96e38	2026-09-07	UNKNOWN	2026-09-07 21:00:00+07	t	\N	2026-10-04 22:58:59.165+07
c4533aef-5a6b-46b6-97f0-4a2f64f51482	3193d9a5-6017-4441-b40c-f22e9ec9b867	d59dc593-6623-443a-8c37-ef928f1b55c0	2026-09-07	UNKNOWN	2026-09-08 05:05:00+07	t	\N	2026-10-04 22:58:59.167+07
5bc6556f-699c-4b49-9fe3-f23037891b0c	3193d9a5-6017-4441-b40c-f22e9ec9b867	cd188977-95e8-4345-b26c-de91eb48f540	2026-09-08	UNKNOWN	2026-09-08 21:05:00+07	t	\N	2026-10-04 22:58:59.169+07
0baf6795-f7ca-4b16-9b5a-1f097e4d1b78	3193d9a5-6017-4441-b40c-f22e9ec9b867	9f59f28f-b573-44b7-82a7-1470ef843c6c	2026-09-08	UNKNOWN	2026-09-09 05:05:00+07	t	\N	2026-10-04 22:58:59.171+07
b7b91547-3475-4c6c-a1ce-abe7415474b9	3193d9a5-6017-4441-b40c-f22e9ec9b867	509496d3-144f-4576-854e-9e856e7b7767	2026-09-09	UNKNOWN	2026-09-09 20:55:00+07	t	\N	2026-10-04 22:58:59.174+07
6c55d5c9-c5e0-460c-9dd8-da3a4853bbc2	3193d9a5-6017-4441-b40c-f22e9ec9b867	ffc2125f-4795-4f83-848d-f7b9fa8d429b	2026-09-09	UNKNOWN	2026-09-10 05:05:00+07	t	\N	2026-10-04 22:58:59.176+07
3de2bce7-4ef4-419e-8ef4-ef09774db318	3193d9a5-6017-4441-b40c-f22e9ec9b867	f612b2a5-c42a-4efa-b977-5e5f0b68bd23	2026-09-10	UNKNOWN	2026-09-10 21:20:00+07	t	\N	2026-10-04 22:58:59.178+07
e11e04cb-d553-4d75-9b83-7f867a5ccab6	3193d9a5-6017-4441-b40c-f22e9ec9b867	e62e225a-edd1-47a7-bb49-c36a428e3bed	2026-09-10	UNKNOWN	2026-09-11 05:05:00+07	t	\N	2026-10-04 22:58:59.18+07
e0b53c3a-bb32-4994-be51-d6b289f8b3d4	3193d9a5-6017-4441-b40c-f22e9ec9b867	4ad091f2-bd5d-4f73-944f-c545c299c9b8	2026-09-11	UNKNOWN	2026-09-11 21:05:00+07	t	\N	2026-10-04 22:58:59.181+07
3abe04ca-f582-4e81-8ec1-d43910faba4c	3193d9a5-6017-4441-b40c-f22e9ec9b867	e75465c4-1440-472d-b878-2a13f8f491bf	2026-09-11	UNKNOWN	2026-09-12 05:05:00+07	t	\N	2026-10-04 22:58:59.185+07
53e29c92-2bf9-4aea-b573-3bdd318cf2e8	3193d9a5-6017-4441-b40c-f22e9ec9b867	b44ebc4e-05d7-4772-acbd-aa4d40927dd4	2026-09-14	UNKNOWN	2026-09-14 20:55:00+07	t	\N	2026-10-04 22:58:59.187+07
b6b467fa-2a05-4b90-9978-ec93bc2f58a4	3193d9a5-6017-4441-b40c-f22e9ec9b867	c373ba09-68d3-47ab-a722-7292b3d3aafa	2026-09-14	UNKNOWN	2026-09-15 05:05:00+07	t	\N	2026-10-04 22:58:59.189+07
63bc56e2-3a48-4d11-9cfa-4619e5b95cb3	3193d9a5-6017-4441-b40c-f22e9ec9b867	888e029b-6f1f-4523-bb14-d714b3e9930d	2026-09-15	UNKNOWN	2026-09-15 21:00:00+07	t	\N	2026-10-04 22:58:59.191+07
5e90f3f0-7549-493a-881b-22b7e238cccf	3193d9a5-6017-4441-b40c-f22e9ec9b867	8e01f0a2-f70a-47a7-a884-f7bb47d2a49c	2026-09-15	UNKNOWN	2026-09-16 05:05:00+07	t	\N	2026-10-04 22:58:59.193+07
4b1247c3-1129-4d2f-9d03-970908119214	3193d9a5-6017-4441-b40c-f22e9ec9b867	d0178145-b899-418b-a2d6-f66e5bed487b	2026-09-17	UNKNOWN	2026-09-17 21:05:00+07	t	\N	2026-10-04 22:58:59.195+07
7c8bd904-2b80-4b2a-8d1e-4697d834abea	3193d9a5-6017-4441-b40c-f22e9ec9b867	c56d86e4-9f74-4c01-8834-a07c4154380d	2026-09-17	UNKNOWN	2026-09-18 05:05:00+07	t	\N	2026-10-04 22:58:59.196+07
4fdcf1a1-46d1-48c8-90e5-1bf35b76e96c	3193d9a5-6017-4441-b40c-f22e9ec9b867	d491f7b6-965e-4d9b-b926-951f13fbfa69	2026-09-18	UNKNOWN	2026-09-18 20:55:00+07	t	\N	2026-10-04 22:58:59.198+07
ab034809-5d5f-4e3e-89c9-50a2cb2d8bd2	3193d9a5-6017-4441-b40c-f22e9ec9b867	82402976-db57-4917-882e-bb706df0ba50	2026-09-18	UNKNOWN	2026-09-19 05:05:00+07	t	\N	2026-10-04 22:58:59.201+07
e43a49a7-b2cb-485d-b9f5-3765a240f824	3193d9a5-6017-4441-b40c-f22e9ec9b867	b4d4e0b9-9e8a-45e5-8532-770929bd8468	2026-09-21	UNKNOWN	2026-09-21 21:00:00+07	t	\N	2026-10-04 22:58:59.203+07
19eac685-062e-4c55-8e26-bbf7b97b9c0f	3193d9a5-6017-4441-b40c-f22e9ec9b867	f835aa87-02e5-4d9a-8c18-10c3fe0c19de	2026-09-21	UNKNOWN	2026-09-22 05:05:00+07	t	\N	2026-10-04 22:58:59.205+07
470ec720-9d8b-42f0-b808-b3f5fb6c05fb	3193d9a5-6017-4441-b40c-f22e9ec9b867	59c4f423-6585-4a45-8298-e8c4a24aefc1	2026-09-23	UNKNOWN	2026-09-23 21:05:00+07	t	\N	2026-10-04 22:58:59.208+07
b8829b20-3928-4fc4-a766-99bcf466d619	3193d9a5-6017-4441-b40c-f22e9ec9b867	38deeecc-51fc-49c8-bc3e-79d1c342eca0	2026-09-23	UNKNOWN	2026-09-24 05:05:00+07	t	\N	2026-10-04 22:58:59.209+07
7b9758bd-5e89-457e-99b8-de1b410804b0	3193d9a5-6017-4441-b40c-f22e9ec9b867	b90677c1-56a3-41a9-aa6b-b096cb7a1074	2026-09-24	UNKNOWN	2026-09-24 20:55:00+07	t	\N	2026-10-04 22:58:59.212+07
3e5fa7b0-f583-49ee-823a-46e11b7c616c	3193d9a5-6017-4441-b40c-f22e9ec9b867	80f8c0a9-6d31-44d0-acf1-9e59d574aa74	2026-09-24	UNKNOWN	2026-09-25 05:05:00+07	t	\N	2026-10-04 22:58:59.214+07
cec87a4f-f0fa-4b0a-832a-d041dc8576ab	3193d9a5-6017-4441-b40c-f22e9ec9b867	83c5cd67-950f-4f29-bcf9-29776cb9a631	2026-09-25	UNKNOWN	2026-09-25 21:00:00+07	t	\N	2026-10-04 22:58:59.217+07
c0ffb386-db65-420a-b0b3-2015962fa66e	3193d9a5-6017-4441-b40c-f22e9ec9b867	ba91d17b-cebb-42b6-8f80-07c130b9a674	2026-09-25	UNKNOWN	2026-09-26 05:05:00+07	t	\N	2026-10-04 22:58:59.219+07
89ab7784-42b6-46bb-851c-19ec54803c94	3193d9a5-6017-4441-b40c-f22e9ec9b867	3ae56af6-8d07-45fe-81de-60672a8cb235	2026-09-28	UNKNOWN	2026-09-28 21:05:00+07	t	\N	2026-10-04 22:58:59.221+07
2317a191-2d51-4974-ae12-ae42ad9e22bf	3193d9a5-6017-4441-b40c-f22e9ec9b867	60667a5c-d3d1-4dac-80a6-680712eebaa5	2026-09-28	UNKNOWN	2026-09-29 05:05:00+07	t	\N	2026-10-04 22:58:59.222+07
c4ba57bb-36a2-4777-b12f-c0c5b9aa0016	3193d9a5-6017-4441-b40c-f22e9ec9b867	6bd0739a-c489-43e7-941b-d0fe0bae6792	2026-09-29	UNKNOWN	2026-09-29 20:55:00+07	t	\N	2026-10-04 22:58:59.224+07
a95e7bd7-7ba6-4a63-afc8-2adc9154e93a	3193d9a5-6017-4441-b40c-f22e9ec9b867	48daf1ae-4156-4540-81e2-5c59dcdc6f71	2026-09-29	UNKNOWN	2026-09-30 05:05:00+07	t	\N	2026-10-04 22:58:59.226+07
fc632f5f-ce1d-43c8-a8ec-c130c6c74ef4	3193d9a5-6017-4441-b40c-f22e9ec9b867	aa6ddea2-6621-4791-a3d4-f6893f4b6e5c	2026-09-30	UNKNOWN	2026-09-30 21:00:00+07	t	\N	2026-10-04 22:58:59.227+07
9534e0a8-4ea3-44b9-8a84-58c23fd3f5e2	3193d9a5-6017-4441-b40c-f22e9ec9b867	0cd15cd3-16fc-47a1-ae56-2937f8cbc92f	2026-09-30	UNKNOWN	2026-10-01 05:05:00+07	t	\N	2026-10-04 22:58:59.229+07
a131f604-63e2-45f3-8e47-fe85a99b7879	b7291f79-3495-44a5-b039-737465dc2cc0	c9fce9c4-fdec-4531-a440-5a7bb81b3f3f	2026-09-01	UNKNOWN	2026-09-01 08:00:00+07	t	\N	2026-10-04 22:58:58.504+07
6d11ed60-87a3-4eaa-9d02-128c1261d86b	b7291f79-3495-44a5-b039-737465dc2cc0	c95f3fec-4655-49e4-b05f-3ca1970b4a31	2026-09-04	UNKNOWN	2026-09-04 08:00:00+07	t	\N	2026-10-04 22:58:58.516+07
8df6bbbb-57e1-4a66-b328-972723985734	3193d9a5-6017-4441-b40c-f22e9ec9b867	745d1a58-3561-4b44-982a-3732b7b97365	2026-09-01	UNKNOWN	2026-09-02 05:05:00+07	t	\N	2026-10-04 22:58:59.148+07
6392b049-28d2-483b-ab2f-32485a685888	b7291f79-3495-44a5-b039-737465dc2cc0	5d8301d0-9884-4828-b0a7-717ce491ae29	2026-09-29	UNKNOWN	2026-09-29 16:00:00+07	t	\N	2026-10-04 22:58:58.596+07
90b358b5-ae7d-427b-8d80-0f57524cb576	3193d9a5-6017-4441-b40c-f22e9ec9b867	19ecd700-c45c-4c48-85e3-6194f4bd8484	2026-09-01	UNKNOWN	2026-09-01 20:55:00+07	t	\N	2026-10-04 22:58:59.146+07
a693cdef-a117-41e4-b168-4dc73da2d284	23230ce1-1ab7-4b49-b9b2-404f149e00ca	1dffa6e6-e538-4cf7-8ada-fb9c99c2fe07	2026-09-03	UNKNOWN	2026-09-03 14:00:00+07	t	\N	2026-10-04 22:58:59.36+07
8ba85cb9-4236-4b91-89b7-731234708bc7	23230ce1-1ab7-4b49-b9b2-404f149e00ca	3d1a1d73-2f17-4ab9-9b16-d0f932ce468c	2026-09-04	UNKNOWN	2026-09-04 06:12:00+07	t	\N	2026-10-04 22:58:59.361+07
b6798323-0e38-4065-926a-a32609ac4a10	23230ce1-1ab7-4b49-b9b2-404f149e00ca	9ad14fdc-e88e-410c-986f-7b212e74f48f	2026-09-04	UNKNOWN	2026-09-04 14:00:00+07	t	\N	2026-10-04 22:58:59.363+07
ecbdac34-a178-4ef3-a0a1-87f8ad53f23b	23230ce1-1ab7-4b49-b9b2-404f149e00ca	f44efce7-d34e-4f4d-9a24-83e1564398a2	2026-09-07	UNKNOWN	2026-09-07 05:58:00+07	t	\N	2026-10-04 22:58:59.364+07
22a8c2d2-1d8e-464e-a01b-53c7551e1611	23230ce1-1ab7-4b49-b9b2-404f149e00ca	1ed6ca92-f623-4eac-b79d-0c670401785a	2026-09-07	UNKNOWN	2026-09-07 14:00:00+07	t	\N	2026-10-04 22:58:59.367+07
ee53edef-75a6-4e5e-8cf7-7d81a0e055c8	23230ce1-1ab7-4b49-b9b2-404f149e00ca	d6bf347e-7592-4aa7-9a98-360eeec70944	2026-09-08	UNKNOWN	2026-09-08 05:58:00+07	t	\N	2026-10-04 22:58:59.369+07
4fbe59c4-eba1-43d9-8dbf-09068d216435	23230ce1-1ab7-4b49-b9b2-404f149e00ca	627d16a8-2e7b-48a4-8c06-c30bc616ea95	2026-09-08	UNKNOWN	2026-09-08 14:00:00+07	t	\N	2026-10-04 22:58:59.371+07
1166b8b3-8233-46a1-be59-990d633d0bad	23230ce1-1ab7-4b49-b9b2-404f149e00ca	737b3a69-dbb2-4aa2-bec2-2b5f26e545b4	2026-09-09	UNKNOWN	2026-09-09 05:58:00+07	t	\N	2026-10-04 22:58:59.373+07
2f8fc82a-9e7b-46cf-ac25-0be2d245ba48	23230ce1-1ab7-4b49-b9b2-404f149e00ca	7768dae9-7efe-4005-9e7e-163afc5ce577	2026-09-09	UNKNOWN	2026-09-09 14:00:00+07	t	\N	2026-10-04 22:58:59.374+07
a78aaa81-fbd9-49ea-bd49-065d51a366fd	23230ce1-1ab7-4b49-b9b2-404f149e00ca	a94849ab-6860-4570-8be4-9afce5184135	2026-09-10	UNKNOWN	2026-09-10 06:20:00+07	t	\N	2026-10-04 22:58:59.376+07
fc771600-af6b-45ed-b10b-7b41460e9a15	23230ce1-1ab7-4b49-b9b2-404f149e00ca	d76e8df7-3787-4781-943d-b424e62fe1bb	2026-09-10	UNKNOWN	2026-09-10 14:00:00+07	t	\N	2026-10-04 22:58:59.377+07
f4a94d7a-a196-49e3-aca8-193efc5d1b3c	23230ce1-1ab7-4b49-b9b2-404f149e00ca	b34c931e-cf06-4a1b-ab91-d3416642a9ba	2026-09-11	UNKNOWN	2026-09-11 05:58:00+07	t	\N	2026-10-04 22:58:59.378+07
90287d56-31c8-409f-b127-7232812ac241	23230ce1-1ab7-4b49-b9b2-404f149e00ca	a2709366-12e7-4983-b339-052698179491	2026-09-11	UNKNOWN	2026-09-11 14:00:00+07	t	\N	2026-10-04 22:58:59.379+07
6d88d6e5-bbc5-430e-b825-23037398fdbd	23230ce1-1ab7-4b49-b9b2-404f149e00ca	0d9a8b9f-4ea6-4ca9-8c3d-cbc1d15c958e	2026-09-14	UNKNOWN	2026-09-14 05:58:00+07	t	\N	2026-10-04 22:58:59.381+07
9b75eba9-ec0b-4920-ad76-52be5d4a53bc	23230ce1-1ab7-4b49-b9b2-404f149e00ca	769b6b11-76b0-426a-9a92-ebdde6038ead	2026-09-14	UNKNOWN	2026-09-14 14:00:00+07	t	\N	2026-10-04 22:58:59.382+07
b7e39e34-6230-4d3a-a6a4-bff3f3637b5c	23230ce1-1ab7-4b49-b9b2-404f149e00ca	eb4db8dc-8453-4791-8ea6-43c6d2adf382	2026-09-15	UNKNOWN	2026-09-15 05:58:00+07	t	\N	2026-10-04 22:58:59.385+07
0aea9283-26c9-4146-94cf-7b945d37085a	23230ce1-1ab7-4b49-b9b2-404f149e00ca	a9097a9d-0522-431e-a618-47b64968dc30	2026-09-15	UNKNOWN	2026-09-15 14:00:00+07	t	\N	2026-10-04 22:58:59.387+07
b662e62a-67db-416f-912a-dc1005de09bc	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	ec811fef-5780-42a7-a2e2-3d3ad0557899	2026-09-18	UNKNOWN	2026-09-18 08:25:00+07	t	\N	2026-10-04 22:58:57.961+07
7b5e781d-586f-4900-b597-694713f1cc84	0cd6bde6-3226-4ebb-b135-ca522d42efa4	944d5e8b-095d-4bd3-8e49-6511e1c533c3	2026-09-07	UNKNOWN	2026-09-07 16:05:00+07	t	\N	2026-10-04 22:58:58.246+07
7295bf1d-effa-4dc2-876d-c726acb27715	0c685448-b52e-4e60-89ea-6f7c500a86d5	f6ca1b6e-b657-4b71-aac9-8bc000e5db81	2026-09-02	UNKNOWN	2026-09-02 15:55:00+07	t	\N	2026-10-04 22:58:58.365+07
f9ad8183-8b13-44c3-a65f-ac993efd9cf6	0c685448-b52e-4e60-89ea-6f7c500a86d5	7a9e6ba0-e8c2-460b-8dd1-1a6c36a98492	2026-09-15	UNKNOWN	2026-09-15 15:55:00+07	t	\N	2026-10-04 22:58:58.402+07
b2e8bd6a-7cc5-481b-b1cd-2b554afbf5d0	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	650b4163-3211-4f1e-8c59-0d637ca4075d	2026-09-14	UNKNOWN	2026-09-14 06:58:00+07	t	\N	2026-10-04 22:58:59.026+07
8f5df4b2-672a-41b9-8d6f-13b46a1ccbb4	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	47022f00-2792-4243-b365-065757f46dde	2026-09-10	UNKNOWN	2026-09-10 16:00:00+07	t	\N	2026-10-04 22:58:58.688+07
\.


--
-- Data for Name: AttendanceRawPunch; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."AttendanceRawPunch" (id, "odooEmployeeId", "deviceId", "enrollId", "punchAt", direction, source, fingerprint, "payloadJson", "receivedAt") FROM stdin;
a0c0933e-1271-4121-810e-d45c6d9fe806	6a65b903-7cb2-468b-8245-a607e73baa54	8ae41932-c8e7-4d34-9854-4f25e9488942	101	2026-09-01 07:50:00+07	UNKNOWN	FINGERPRINT	160774ebc15f10d8f1428f232e89990089ef3ae2daa441ce272de1843a2d03ed	{"punchAt": "2026-09-01T00:50:00.000Z", "enrollId": "101"}	2026-10-04 22:58:57.293+07
0bff6940-61cb-458e-be9e-ce11aa21dde6	6a65b903-7cb2-468b-8245-a607e73baa54	8ae41932-c8e7-4d34-9854-4f25e9488942	101	2026-09-01 16:00:00+07	UNKNOWN	FINGERPRINT	131e449f5c9e19d79f8da5339d92e0c8649673e79c0c45fd2a6e4e7d3a33b75d	{"punchAt": "2026-09-01T09:00:00.000Z", "enrollId": "101"}	2026-10-04 22:58:57.296+07
8c99cf26-6115-463f-970f-efd16076d33f	6a65b903-7cb2-468b-8245-a607e73baa54	8ae41932-c8e7-4d34-9854-4f25e9488942	101	2026-09-02 07:55:00+07	UNKNOWN	FINGERPRINT	2abc0fe20e8939ef93c1937267c732e89870764f3dcef4bc2a77a8d74d9d0529	{"punchAt": "2026-09-02T00:55:00.000Z", "enrollId": "101"}	2026-10-04 22:58:57.298+07
6194413e-30eb-4417-a14d-d46281cd5af3	6a65b903-7cb2-468b-8245-a607e73baa54	8ae41932-c8e7-4d34-9854-4f25e9488942	101	2026-09-02 16:15:00+07	UNKNOWN	FINGERPRINT	22aad2b29a4bdbe4fb9fcdbef97171dd322f5c180132d7e99eadf55404ee6d28	{"punchAt": "2026-09-02T09:15:00.000Z", "enrollId": "101"}	2026-10-04 22:58:57.3+07
a108d0bb-dcd0-4a90-aa4b-4e3198892f41	6a65b903-7cb2-468b-8245-a607e73baa54	8ae41932-c8e7-4d34-9854-4f25e9488942	101	2026-09-03 08:00:00+07	UNKNOWN	FINGERPRINT	8874cb706f69c2cbc142495a54ce54ebd4c8c2a69cb874e456880256460feb0c	{"punchAt": "2026-09-03T01:00:00.000Z", "enrollId": "101"}	2026-10-04 22:58:57.302+07
a4f6e2f0-6155-4a16-b04d-ebe0c6eb3473	6a65b903-7cb2-468b-8245-a607e73baa54	8ae41932-c8e7-4d34-9854-4f25e9488942	101	2026-09-03 16:30:00+07	UNKNOWN	FINGERPRINT	51769e2e55e6b6706796ab232f668409b386cc1535c1005de2f0065acb765a37	{"punchAt": "2026-09-03T09:30:00.000Z", "enrollId": "101"}	2026-10-04 22:58:57.304+07
7b47c4e0-2d6e-4910-9eae-ea6365fc11da	6a65b903-7cb2-468b-8245-a607e73baa54	8ae41932-c8e7-4d34-9854-4f25e9488942	101	2026-09-04 08:05:00+07	UNKNOWN	FINGERPRINT	d5cee1b463b7b29d9409a1895d91bb47a4f3dc19220c04e3aeaa2de49e9794cc	{"punchAt": "2026-09-04T01:05:00.000Z", "enrollId": "101"}	2026-10-04 22:58:57.305+07
7149906a-9fd0-4440-919a-7b49c395dd4e	6a65b903-7cb2-468b-8245-a607e73baa54	8ae41932-c8e7-4d34-9854-4f25e9488942	101	2026-09-04 16:00:00+07	UNKNOWN	FINGERPRINT	91faefb502d6812b7cb28aa8f2a532cde8d72fed8ae2674b1947ec31cc507ad2	{"punchAt": "2026-09-04T09:00:00.000Z", "enrollId": "101"}	2026-10-04 22:58:57.307+07
4b100591-d483-4545-bca5-023c2393ef92	6a65b903-7cb2-468b-8245-a607e73baa54	8ae41932-c8e7-4d34-9854-4f25e9488942	101	2026-09-07 07:50:00+07	UNKNOWN	FINGERPRINT	970917b0c0a214815f85e1f9f8aa86bf50e6a2d0d8316a13e05d98f51e1cb43e	{"punchAt": "2026-09-07T00:50:00.000Z", "enrollId": "101"}	2026-10-04 22:58:57.308+07
e46208c3-93a1-432f-be1b-9713ee50fb10	6a65b903-7cb2-468b-8245-a607e73baa54	8ae41932-c8e7-4d34-9854-4f25e9488942	101	2026-09-07 16:15:00+07	UNKNOWN	FINGERPRINT	0336b5e43012b688ab70301667e031ceb01900e796cc3cf5e021b4257e904dd1	{"punchAt": "2026-09-07T09:15:00.000Z", "enrollId": "101"}	2026-10-04 22:58:57.31+07
f75d230d-07e2-4a70-b4c0-3c8f6f965485	6a65b903-7cb2-468b-8245-a607e73baa54	8ae41932-c8e7-4d34-9854-4f25e9488942	101	2026-09-08 07:55:00+07	UNKNOWN	FINGERPRINT	414231ad37f1d65462ffca6baef4964b26a12cba6c82cb2e1a2aa1392fd7674b	{"punchAt": "2026-09-08T00:55:00.000Z", "enrollId": "101"}	2026-10-04 22:58:57.311+07
5f6124fb-69b7-4995-a4e1-d09e3848173b	6a65b903-7cb2-468b-8245-a607e73baa54	8ae41932-c8e7-4d34-9854-4f25e9488942	101	2026-09-08 16:30:00+07	UNKNOWN	FINGERPRINT	89b1c919f697f65bd6c6fda30071c0eed8a2c65b09550b24c5253f0cfbbf40a1	{"punchAt": "2026-09-08T09:30:00.000Z", "enrollId": "101"}	2026-10-04 22:58:57.312+07
2cc3b5f4-0c3f-42cb-97bc-89eadd216222	6a65b903-7cb2-468b-8245-a607e73baa54	8ae41932-c8e7-4d34-9854-4f25e9488942	101	2026-09-09 08:00:00+07	UNKNOWN	FINGERPRINT	5b49e44b19642b099e35bb3e82e863d146e2475b7e70d8e1fcdcfbbf0730ce3a	{"punchAt": "2026-09-09T01:00:00.000Z", "enrollId": "101"}	2026-10-04 22:58:57.313+07
28d3848e-6785-4f71-9f73-e49bd6604de8	6a65b903-7cb2-468b-8245-a607e73baa54	8ae41932-c8e7-4d34-9854-4f25e9488942	101	2026-09-09 16:00:00+07	UNKNOWN	FINGERPRINT	cf4a293d7192577e076b0e9f15486ed4162195177d3655a345b1a2a6f350e4d4	{"punchAt": "2026-09-09T09:00:00.000Z", "enrollId": "101"}	2026-10-04 22:58:57.315+07
173bb726-4368-48ca-a339-c9d3b0b98c3b	6a65b903-7cb2-468b-8245-a607e73baa54	8ae41932-c8e7-4d34-9854-4f25e9488942	101	2026-09-10 08:05:00+07	UNKNOWN	FINGERPRINT	171666e31fa1deb0fd0ea179fe6632f22e3fd2fce3d70194b986c9a835fa0937	{"punchAt": "2026-09-10T01:05:00.000Z", "enrollId": "101"}	2026-10-04 22:58:57.317+07
500a33e8-bfb6-4f23-ba7b-832d5889c4a5	6a65b903-7cb2-468b-8245-a607e73baa54	8ae41932-c8e7-4d34-9854-4f25e9488942	101	2026-09-10 16:15:00+07	UNKNOWN	FINGERPRINT	fc91bb5bfece767632f3089ed5ffe28a4ef1894a0ecb108b98e03aa755329009	{"punchAt": "2026-09-10T09:15:00.000Z", "enrollId": "101"}	2026-10-04 22:58:57.319+07
38e41c95-389b-491e-96a4-2b7ff75d86ae	6a65b903-7cb2-468b-8245-a607e73baa54	8ae41932-c8e7-4d34-9854-4f25e9488942	101	2026-09-11 07:50:00+07	UNKNOWN	FINGERPRINT	34bef1099ea901cfd4df0e9bb8f310f10103436e53832284fd678962c352c5c2	{"punchAt": "2026-09-11T00:50:00.000Z", "enrollId": "101"}	2026-10-04 22:58:57.32+07
2f7a66e0-2c78-4f20-a35f-acf69b8c5ebd	6a65b903-7cb2-468b-8245-a607e73baa54	8ae41932-c8e7-4d34-9854-4f25e9488942	101	2026-09-11 16:30:00+07	UNKNOWN	FINGERPRINT	87bcf224817017f264c5cdd4a246174cf01a79d86cfa777601adeba2c9e112e5	{"punchAt": "2026-09-11T09:30:00.000Z", "enrollId": "101"}	2026-10-04 22:58:57.322+07
bfdfb58d-3823-44b0-a951-51657e6b5be1	6a65b903-7cb2-468b-8245-a607e73baa54	8ae41932-c8e7-4d34-9854-4f25e9488942	101	2026-09-14 07:55:00+07	UNKNOWN	FINGERPRINT	9182288979da92509cd303da972ad261bdc3ad711c820d9e3c2fc385fcd814e4	{"punchAt": "2026-09-14T00:55:00.000Z", "enrollId": "101"}	2026-10-04 22:58:57.323+07
76c32a76-6b8a-45ab-8f21-4a01616ef592	6a65b903-7cb2-468b-8245-a607e73baa54	8ae41932-c8e7-4d34-9854-4f25e9488942	101	2026-09-14 16:00:00+07	UNKNOWN	FINGERPRINT	eb8ea8514fa9e4c3ff93fe4a720346e7eb21dfb8a02feddbdb0d4fd32922c481	{"punchAt": "2026-09-14T09:00:00.000Z", "enrollId": "101"}	2026-10-04 22:58:57.325+07
fbfe2d02-17f1-4972-8ad1-0cc868f7d7a6	6a65b903-7cb2-468b-8245-a607e73baa54	8ae41932-c8e7-4d34-9854-4f25e9488942	101	2026-09-15 08:00:00+07	UNKNOWN	FINGERPRINT	62023970a80fae3b281d0cbc800a706b345ab19fc812d5f8208fde6438f227b1	{"punchAt": "2026-09-15T01:00:00.000Z", "enrollId": "101"}	2026-10-04 22:58:57.326+07
7806cece-a667-481b-956f-4f48e306de27	6a65b903-7cb2-468b-8245-a607e73baa54	8ae41932-c8e7-4d34-9854-4f25e9488942	101	2026-09-15 16:15:00+07	UNKNOWN	FINGERPRINT	0fabe9b59ff20b8b398500d79d73cbf11c2f205e379450fe96e18854de07a0ea	{"punchAt": "2026-09-15T09:15:00.000Z", "enrollId": "101"}	2026-10-04 22:58:57.327+07
7cc8ef5d-ac82-4b85-bf62-7dd9a400160f	6a65b903-7cb2-468b-8245-a607e73baa54	8ae41932-c8e7-4d34-9854-4f25e9488942	101	2026-09-17 08:05:00+07	UNKNOWN	FINGERPRINT	f86ed7c17ce1708bcb098f9e060b1160ec1d0ee15d9d664746fd1ce7cd9163e5	{"punchAt": "2026-09-17T01:05:00.000Z", "enrollId": "101"}	2026-10-04 22:58:57.329+07
efdd3069-300d-4c98-b5f6-676fee94619d	6a65b903-7cb2-468b-8245-a607e73baa54	8ae41932-c8e7-4d34-9854-4f25e9488942	101	2026-09-17 16:30:00+07	UNKNOWN	FINGERPRINT	2b49d7167c886d17fe68d89bde7263fa9f6c533330c2f17aebde48acc9da6a35	{"punchAt": "2026-09-17T09:30:00.000Z", "enrollId": "101"}	2026-10-04 22:58:57.33+07
cfad1230-815f-42b2-8b5b-00dcff0669b0	6a65b903-7cb2-468b-8245-a607e73baa54	8ae41932-c8e7-4d34-9854-4f25e9488942	101	2026-09-18 07:50:00+07	UNKNOWN	FINGERPRINT	902054d4ef4f240e39271fe5789df149760222af64e2a1d902fc0e9878b116f8	{"punchAt": "2026-09-18T00:50:00.000Z", "enrollId": "101"}	2026-10-04 22:58:57.331+07
5f78b325-9202-42bd-bc59-e720d5863e30	6a65b903-7cb2-468b-8245-a607e73baa54	8ae41932-c8e7-4d34-9854-4f25e9488942	101	2026-09-18 16:00:00+07	UNKNOWN	FINGERPRINT	575b1142388bd13c255fe696e8853e28096f48239ab4558e60aa53d4bb7e58c2	{"punchAt": "2026-09-18T09:00:00.000Z", "enrollId": "101"}	2026-10-04 22:58:57.334+07
3ec77c78-f44c-42fe-9c04-7751f9c025a0	6a65b903-7cb2-468b-8245-a607e73baa54	8ae41932-c8e7-4d34-9854-4f25e9488942	101	2026-09-21 07:55:00+07	UNKNOWN	FINGERPRINT	8c54cdc3d582ff77c62d1f1959e56e55b2fbf2b51d545528e5426d78f0d16df6	{"punchAt": "2026-09-21T00:55:00.000Z", "enrollId": "101"}	2026-10-04 22:58:57.336+07
10bada50-23b9-4137-bbd0-26e76c9b057a	6a65b903-7cb2-468b-8245-a607e73baa54	8ae41932-c8e7-4d34-9854-4f25e9488942	101	2026-09-21 16:15:00+07	UNKNOWN	FINGERPRINT	a60c874aa1755e5e5a9a6ca1d0b8d2ddf09b9acf2b4ee0b1f43d7c2eba1b242b	{"punchAt": "2026-09-21T09:15:00.000Z", "enrollId": "101"}	2026-10-04 22:58:57.338+07
85db05fa-d2bd-4ac0-84ef-cbbbddab5280	6a65b903-7cb2-468b-8245-a607e73baa54	8ae41932-c8e7-4d34-9854-4f25e9488942	101	2026-09-22 08:00:00+07	UNKNOWN	FINGERPRINT	b8f354312def656fecda2c7b8e748cbdeb6ae2d0951d4b0b8f41d007dc172e21	{"punchAt": "2026-09-22T01:00:00.000Z", "enrollId": "101"}	2026-10-04 22:58:57.34+07
ebdfffbf-1189-4cf7-90bb-71502823c5e7	6a65b903-7cb2-468b-8245-a607e73baa54	8ae41932-c8e7-4d34-9854-4f25e9488942	101	2026-09-22 16:30:00+07	UNKNOWN	FINGERPRINT	50ecb46099cc2326e9df1676987fe912f00a830dca4fd358e4e9b5eee81f2e8c	{"punchAt": "2026-09-22T09:30:00.000Z", "enrollId": "101"}	2026-10-04 22:58:57.342+07
bd1a8816-6221-4135-9baf-7158b6efbee6	6a65b903-7cb2-468b-8245-a607e73baa54	8ae41932-c8e7-4d34-9854-4f25e9488942	101	2026-09-23 08:05:00+07	UNKNOWN	FINGERPRINT	27f62ecb6667a44d70f1666ed042230b74fe1d40f18c512659cd39cd54c048c1	{"punchAt": "2026-09-23T01:05:00.000Z", "enrollId": "101"}	2026-10-04 22:58:57.344+07
15542e2e-9fdd-4e2c-8f2e-c222de79ba64	6a65b903-7cb2-468b-8245-a607e73baa54	8ae41932-c8e7-4d34-9854-4f25e9488942	101	2026-09-23 16:00:00+07	UNKNOWN	FINGERPRINT	c657ed2dd04fe83bef77c80b619cbbeeb5a6302c078382e41ece3aff8a621a91	{"punchAt": "2026-09-23T09:00:00.000Z", "enrollId": "101"}	2026-10-04 22:58:57.345+07
b568e6a9-12be-445c-9b35-e3b9eaf8bc36	6a65b903-7cb2-468b-8245-a607e73baa54	8ae41932-c8e7-4d34-9854-4f25e9488942	101	2026-09-24 07:50:00+07	UNKNOWN	FINGERPRINT	bd5f232839eddbaa5969972a6aceab403df562e5174074090d057f1d1462cc3d	{"punchAt": "2026-09-24T00:50:00.000Z", "enrollId": "101"}	2026-10-04 22:58:57.347+07
67f4f40a-b223-4f62-9e10-d9d2b323ef3a	6a65b903-7cb2-468b-8245-a607e73baa54	8ae41932-c8e7-4d34-9854-4f25e9488942	101	2026-09-24 16:15:00+07	UNKNOWN	FINGERPRINT	8ce8d90eb9c112b4430f6ea49a486419e46018d3cf046a57275e43e4f2f02cc6	{"punchAt": "2026-09-24T09:15:00.000Z", "enrollId": "101"}	2026-10-04 22:58:57.348+07
7678eaee-4f1f-4bc0-aa51-30707f2bed12	6a65b903-7cb2-468b-8245-a607e73baa54	8ae41932-c8e7-4d34-9854-4f25e9488942	101	2026-09-25 07:55:00+07	UNKNOWN	FINGERPRINT	d7595c352abb15b93513da659c2d2c2126e8c678a59e7a72e58ac60f2009e2c3	{"punchAt": "2026-09-25T00:55:00.000Z", "enrollId": "101"}	2026-10-04 22:58:57.35+07
e1dac3ec-7b34-4463-bad3-44ad36761af9	6a65b903-7cb2-468b-8245-a607e73baa54	8ae41932-c8e7-4d34-9854-4f25e9488942	101	2026-09-25 16:30:00+07	UNKNOWN	FINGERPRINT	24c7b3608736c2132e759854628c94fe35afe322785e0b301dc375101d0bbd6a	{"punchAt": "2026-09-25T09:30:00.000Z", "enrollId": "101"}	2026-10-04 22:58:57.352+07
7af2e3a4-3b5a-4b59-b791-4b3f77180dd8	6a65b903-7cb2-468b-8245-a607e73baa54	8ae41932-c8e7-4d34-9854-4f25e9488942	101	2026-09-28 08:00:00+07	UNKNOWN	FINGERPRINT	fd8def7293c9359eabbdfa9f52b957826e1e998fedc5abf16366a8e5eeb077ea	{"punchAt": "2026-09-28T01:00:00.000Z", "enrollId": "101"}	2026-10-04 22:58:57.354+07
4daf9e79-5de3-487f-9a6a-edd29639f94b	6a65b903-7cb2-468b-8245-a607e73baa54	8ae41932-c8e7-4d34-9854-4f25e9488942	101	2026-09-28 16:00:00+07	UNKNOWN	FINGERPRINT	2adb773ccdf5a4e3894716175000ecbefdb8dc2741b74352c2fdb2bb4eb05f6c	{"punchAt": "2026-09-28T09:00:00.000Z", "enrollId": "101"}	2026-10-04 22:58:57.355+07
4c6d283c-0812-4c78-b0dc-245f8068f9ce	6a65b903-7cb2-468b-8245-a607e73baa54	8ae41932-c8e7-4d34-9854-4f25e9488942	101	2026-09-29 08:05:00+07	UNKNOWN	FINGERPRINT	eec5fd8b831d357a2f019cfc9ffe454ddf547651ce9f97f74de0fd70367067b5	{"punchAt": "2026-09-29T01:05:00.000Z", "enrollId": "101"}	2026-10-04 22:58:57.357+07
f4e3c01c-baf6-40b6-9ac8-12fb96d76024	6a65b903-7cb2-468b-8245-a607e73baa54	8ae41932-c8e7-4d34-9854-4f25e9488942	101	2026-09-29 16:15:00+07	UNKNOWN	FINGERPRINT	9dbd6a126f287fede7657edd7e71db9d0b2c5eaf030d3b7f7d48c6de79a2bf9a	{"punchAt": "2026-09-29T09:15:00.000Z", "enrollId": "101"}	2026-10-04 22:58:57.358+07
fba84ba6-3eb1-4049-b57b-86eb668edee7	6a65b903-7cb2-468b-8245-a607e73baa54	8ae41932-c8e7-4d34-9854-4f25e9488942	101	2026-09-30 07:50:00+07	UNKNOWN	FINGERPRINT	8993f24f6caabb41e3a632a4698339f866596ddf4fb01608613ed5785a59899c	{"punchAt": "2026-09-30T00:50:00.000Z", "enrollId": "101"}	2026-10-04 22:58:57.36+07
82deb5ba-e49c-451d-be19-9c7f35370f34	6a65b903-7cb2-468b-8245-a607e73baa54	8ae41932-c8e7-4d34-9854-4f25e9488942	101	2026-09-30 16:30:00+07	UNKNOWN	FINGERPRINT	a4a662e4975c093db604de5353c11da063d89fb247decf8aa23dc8e77bbd672a	{"punchAt": "2026-09-30T09:30:00.000Z", "enrollId": "101"}	2026-10-04 22:58:57.361+07
bc977e55-9022-4463-ad83-3e1326159e2c	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	8ae41932-c8e7-4d34-9854-4f25e9488942	102	2026-09-01 08:40:00+07	UNKNOWN	FINGERPRINT	d4e9495eaa4ffcb9a54c224339007a7d71544ab8e6a94edacf76d189d95593d6	{"punchAt": "2026-09-01T01:40:00.000Z", "enrollId": "102"}	2026-10-04 22:58:57.362+07
27e139b5-d4c3-468a-b029-ace21bf8dded	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	8ae41932-c8e7-4d34-9854-4f25e9488942	102	2026-09-01 16:30:00+07	UNKNOWN	FINGERPRINT	6891f178540a5f37ce5830a1c7536e8ebb10add366066745471cc0ed8bd57ddc	{"punchAt": "2026-09-01T09:30:00.000Z", "enrollId": "102"}	2026-10-04 22:58:57.364+07
dc95dc26-09b1-4edd-8bc8-709e3e888331	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	8ae41932-c8e7-4d34-9854-4f25e9488942	102	2026-09-02 08:05:00+07	UNKNOWN	FINGERPRINT	e5da59dc7dec14b992a81759fc2a913e3956255f96e4114e098e913d4741ebee	{"punchAt": "2026-09-02T01:05:00.000Z", "enrollId": "102"}	2026-10-04 22:58:57.365+07
4e2d33d0-acf1-4b4a-96f0-455e3195baef	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	8ae41932-c8e7-4d34-9854-4f25e9488942	102	2026-09-02 16:30:00+07	UNKNOWN	FINGERPRINT	15de517a6966564c3969640ef77230ac54f732e52a14680ae6be56b4a901e1ee	{"punchAt": "2026-09-02T09:30:00.000Z", "enrollId": "102"}	2026-10-04 22:58:57.366+07
045804eb-e359-445e-a8ba-7e948965c0db	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	8ae41932-c8e7-4d34-9854-4f25e9488942	102	2026-09-03 08:05:00+07	UNKNOWN	FINGERPRINT	2e2e718a8daa873d3acd21e9fdb1572e57ecf9e3fd2c3aba7cb453b37f9b40ed	{"punchAt": "2026-09-03T01:05:00.000Z", "enrollId": "102"}	2026-10-04 22:58:57.368+07
114e4b44-b675-4b49-ac9e-7f97d0092652	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	8ae41932-c8e7-4d34-9854-4f25e9488942	102	2026-09-03 16:30:00+07	UNKNOWN	FINGERPRINT	20b356d05d03b7d9d1cac32963c0f12a75f3d93ba0c264d688cec90ccf26b0cd	{"punchAt": "2026-09-03T09:30:00.000Z", "enrollId": "102"}	2026-10-04 22:58:57.37+07
83ea610f-d3a9-474a-9607-18ddd48e5b5b	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	8ae41932-c8e7-4d34-9854-4f25e9488942	102	2026-09-04 08:25:00+07	UNKNOWN	FINGERPRINT	759dd861d40a974210ca2e3c416aa05494b6f426bd6328515c427fc2fc8c107a	{"punchAt": "2026-09-04T01:25:00.000Z", "enrollId": "102"}	2026-10-04 22:58:57.371+07
560452a1-7c7b-4160-899c-c40589bac7f0	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	8ae41932-c8e7-4d34-9854-4f25e9488942	102	2026-09-04 16:30:00+07	UNKNOWN	FINGERPRINT	6d60be1748fdf834eae777b5e1ec74f288b911ecee72e52e8867288ada8a6d8e	{"punchAt": "2026-09-04T09:30:00.000Z", "enrollId": "102"}	2026-10-04 22:58:57.373+07
1fab44d1-ac88-4f12-ac08-b0f017914e51	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	8ae41932-c8e7-4d34-9854-4f25e9488942	102	2026-09-07 08:05:00+07	UNKNOWN	FINGERPRINT	c30ee3bc2a897b5af9d5b87950e9170562d07fd1247978b471632eea69c523d8	{"punchAt": "2026-09-07T01:05:00.000Z", "enrollId": "102"}	2026-10-04 22:58:57.374+07
1e731377-fdee-45c7-b779-e3934f90c2de	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	8ae41932-c8e7-4d34-9854-4f25e9488942	102	2026-09-07 16:30:00+07	UNKNOWN	FINGERPRINT	49b948c12287cd42be552e40af75a3340bde85a6311b228d32cd8f94e1e1127f	{"punchAt": "2026-09-07T09:30:00.000Z", "enrollId": "102"}	2026-10-04 22:58:57.376+07
bcf1cdad-002a-4446-99a0-9ab753741ffd	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	8ae41932-c8e7-4d34-9854-4f25e9488942	102	2026-09-08 08:40:00+07	UNKNOWN	FINGERPRINT	8f4c9d5b91a07fbb5811a2446d04c8132ff39bbd54c903fa8116a068db97922d	{"punchAt": "2026-09-08T01:40:00.000Z", "enrollId": "102"}	2026-10-04 22:58:57.377+07
b764b327-4cce-434b-adc7-ee5c3e0f8431	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	8ae41932-c8e7-4d34-9854-4f25e9488942	102	2026-09-08 16:30:00+07	UNKNOWN	FINGERPRINT	5409fb00a562f4a40ccdcc81a11d2e9825eddbf5e7f385e7777742f10d3c1653	{"punchAt": "2026-09-08T09:30:00.000Z", "enrollId": "102"}	2026-10-04 22:58:57.379+07
21d6ddcc-c056-4627-abe1-eaa9cfb27426	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	8ae41932-c8e7-4d34-9854-4f25e9488942	102	2026-09-09 08:25:00+07	UNKNOWN	FINGERPRINT	9cee8bfdbb6accc5e33fddeff1156a294fd165d7ef00a5f0c96c6cb45865ae7b	{"punchAt": "2026-09-09T01:25:00.000Z", "enrollId": "102"}	2026-10-04 22:58:57.38+07
82349226-f979-44b3-89c4-e6c52531a9ce	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	8ae41932-c8e7-4d34-9854-4f25e9488942	102	2026-09-09 16:30:00+07	UNKNOWN	FINGERPRINT	976ee4424f726064c1c21cde7aca4a15537b0d9b512d289bb584335f8c651489	{"punchAt": "2026-09-09T09:30:00.000Z", "enrollId": "102"}	2026-10-04 22:58:57.381+07
022596d1-17df-4204-b01b-793041820858	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	8ae41932-c8e7-4d34-9854-4f25e9488942	102	2026-09-10 08:05:00+07	UNKNOWN	FINGERPRINT	e17b30f32e669f065c865e3cb052dc12e820dd7f2333d4c4b6e6ff97c8a7c5c7	{"punchAt": "2026-09-10T01:05:00.000Z", "enrollId": "102"}	2026-10-04 22:58:57.383+07
ca737834-5124-4c97-a510-9f163eec2947	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	8ae41932-c8e7-4d34-9854-4f25e9488942	102	2026-09-10 16:30:00+07	UNKNOWN	FINGERPRINT	bd6dd49f170e25d450158e1e39b01ef999d54823a94bb5f4a41c53a3f634717c	{"punchAt": "2026-09-10T09:30:00.000Z", "enrollId": "102"}	2026-10-04 22:58:57.385+07
c89424a4-e878-415a-b16c-8c442d040671	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	8ae41932-c8e7-4d34-9854-4f25e9488942	102	2026-09-11 08:05:00+07	UNKNOWN	FINGERPRINT	210ed6bd6e66a56cf551f1ad2c3764e7ca11198969543bcfa26999338d95b3e8	{"punchAt": "2026-09-11T01:05:00.000Z", "enrollId": "102"}	2026-10-04 22:58:57.386+07
76db4ce0-4dd5-4676-a3c5-b8f009c8ab58	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	8ae41932-c8e7-4d34-9854-4f25e9488942	102	2026-09-11 16:30:00+07	UNKNOWN	FINGERPRINT	d95b2e211860acdda0c471169185dfaa5a4e0a06f98aef4e7d373978bade32ae	{"punchAt": "2026-09-11T09:30:00.000Z", "enrollId": "102"}	2026-10-04 22:58:57.388+07
42a4e6a6-b7df-4270-90aa-e05ce8592570	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	8ae41932-c8e7-4d34-9854-4f25e9488942	102	2026-09-14 08:25:00+07	UNKNOWN	FINGERPRINT	5c502304bdf8a8de9fad4ed588cdb83a9b9a978c8b223a67eebbf433c6dfe077	{"punchAt": "2026-09-14T01:25:00.000Z", "enrollId": "102"}	2026-10-04 22:58:57.389+07
3dda1347-31b9-4b97-9093-cf5f06e47599	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	8ae41932-c8e7-4d34-9854-4f25e9488942	102	2026-09-14 16:30:00+07	UNKNOWN	FINGERPRINT	5e2c2f78664c6d280f9357c868efe98d6c98148014fbd36e9c06a3614ee1330e	{"punchAt": "2026-09-14T09:30:00.000Z", "enrollId": "102"}	2026-10-04 22:58:57.39+07
f773354e-c679-4023-8c62-f1639003c8e8	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	8ae41932-c8e7-4d34-9854-4f25e9488942	102	2026-09-15 08:40:00+07	UNKNOWN	FINGERPRINT	5b68568dca7a6bfd68c3349c4e8d55570757dc81cd91408268e1fb6362464f45	{"punchAt": "2026-09-15T01:40:00.000Z", "enrollId": "102"}	2026-10-04 22:58:57.392+07
79509075-c2b0-468b-8438-95fb373e72de	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	8ae41932-c8e7-4d34-9854-4f25e9488942	102	2026-09-15 16:30:00+07	UNKNOWN	FINGERPRINT	2f66b88a313077488d07d31dedba75811bf591b4e8fd2949641c7e14290c4666	{"punchAt": "2026-09-15T09:30:00.000Z", "enrollId": "102"}	2026-10-04 22:58:57.393+07
74b67972-d3fa-45ae-bc9a-af670f5d0fa8	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	8ae41932-c8e7-4d34-9854-4f25e9488942	102	2026-09-17 08:05:00+07	UNKNOWN	FINGERPRINT	a8a969ee50ace3f763d99237f1986b0fae1ac42e6dad5f0fbfe6f91cc9b209cf	{"punchAt": "2026-09-17T01:05:00.000Z", "enrollId": "102"}	2026-10-04 22:58:57.394+07
a4f676bc-b183-4931-b303-54b8ad442fae	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	8ae41932-c8e7-4d34-9854-4f25e9488942	102	2026-09-17 16:30:00+07	UNKNOWN	FINGERPRINT	0a85b5a256a08e4d7663072c3ec4d0cc3a66a255c3460d3a891e5693c85d2352	{"punchAt": "2026-09-17T09:30:00.000Z", "enrollId": "102"}	2026-10-04 22:58:57.396+07
ec811fef-5780-42a7-a2e2-3d3ad0557899	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	8ae41932-c8e7-4d34-9854-4f25e9488942	102	2026-09-18 08:25:00+07	UNKNOWN	FINGERPRINT	329835632444fe257944bf6f1035a4d6360cbe541cd39ede00a5948b6fbc36b4	{"punchAt": "2026-09-18T01:25:00.000Z", "enrollId": "102"}	2026-10-04 22:58:57.397+07
7731f036-e64e-4f3b-8c28-5d8a7039ad72	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	8ae41932-c8e7-4d34-9854-4f25e9488942	102	2026-09-18 16:30:00+07	UNKNOWN	FINGERPRINT	7e5d9e41498df1ee66dfebdefdf279fe1f7ff32fdadfe4a507e36bc5726f6223	{"punchAt": "2026-09-18T09:30:00.000Z", "enrollId": "102"}	2026-10-04 22:58:57.398+07
61ff919e-d4c0-4016-9390-53c28cfdf9e4	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	8ae41932-c8e7-4d34-9854-4f25e9488942	102	2026-09-21 08:05:00+07	UNKNOWN	FINGERPRINT	e7fb226a011d242eeeddbeae0fa5a23098fb8b1dcfb1cdb5399f603707bfa0c4	{"punchAt": "2026-09-21T01:05:00.000Z", "enrollId": "102"}	2026-10-04 22:58:57.4+07
64e72d83-baf9-4726-afd0-90e9b2de3975	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	8ae41932-c8e7-4d34-9854-4f25e9488942	102	2026-09-21 16:30:00+07	UNKNOWN	FINGERPRINT	3f2b87df4f572837365d29e6fb1129b660ec2c27e33651648b18edf25fa76a02	{"punchAt": "2026-09-21T09:30:00.000Z", "enrollId": "102"}	2026-10-04 22:58:57.402+07
65096dbf-4e15-4806-8d47-1ff91905964e	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	8ae41932-c8e7-4d34-9854-4f25e9488942	102	2026-09-22 08:05:00+07	UNKNOWN	FINGERPRINT	21f22a7f3f7c9868d03d9d00653c004c710f8c90130faa1d140501f3756e8e7c	{"punchAt": "2026-09-22T01:05:00.000Z", "enrollId": "102"}	2026-10-04 22:58:57.404+07
c543192b-74b4-4410-86d8-8791b24cd6a5	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	8ae41932-c8e7-4d34-9854-4f25e9488942	102	2026-09-22 16:30:00+07	UNKNOWN	FINGERPRINT	37945f8da6de567b6e169a2465d48664a5b3743a0de431962c506d71948b07d8	{"punchAt": "2026-09-22T09:30:00.000Z", "enrollId": "102"}	2026-10-04 22:58:57.405+07
4a6fa234-30b3-46c0-babc-901924dc24a6	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	8ae41932-c8e7-4d34-9854-4f25e9488942	102	2026-09-23 08:40:00+07	UNKNOWN	FINGERPRINT	f7c1a387af9379941c2c678fcd8fe936f64ef89ede0866b205b775a80b8fbd1a	{"punchAt": "2026-09-23T01:40:00.000Z", "enrollId": "102"}	2026-10-04 22:58:57.407+07
9aecbeb3-3f2d-4188-8e9f-657ed977d616	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	8ae41932-c8e7-4d34-9854-4f25e9488942	102	2026-09-23 16:30:00+07	UNKNOWN	FINGERPRINT	bc315c670af122d9b37f3ad61d930580571f090b6b4543921e4a92fd7842ab59	{"punchAt": "2026-09-23T09:30:00.000Z", "enrollId": "102"}	2026-10-04 22:58:57.408+07
0c78c31a-5a6e-4b32-acb5-61564638e7e9	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	8ae41932-c8e7-4d34-9854-4f25e9488942	102	2026-09-24 08:05:00+07	UNKNOWN	FINGERPRINT	11226eabe26b6af07673c85b6c5bec01e3e286ea5cc5cf23d2aaa4e2659459f1	{"punchAt": "2026-09-24T01:05:00.000Z", "enrollId": "102"}	2026-10-04 22:58:57.409+07
5958eb9c-232a-436b-b0fb-15f5ebf6d879	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	8ae41932-c8e7-4d34-9854-4f25e9488942	102	2026-09-24 16:30:00+07	UNKNOWN	FINGERPRINT	8c49768450f1a740908144a99a9ba498673ee926ee45db0bb9c6714dc2a6e23a	{"punchAt": "2026-09-24T09:30:00.000Z", "enrollId": "102"}	2026-10-04 22:58:57.411+07
3ff24478-b250-4e6f-9358-6f9a215f0715	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	8ae41932-c8e7-4d34-9854-4f25e9488942	102	2026-09-25 08:05:00+07	UNKNOWN	FINGERPRINT	17e242d04d12b70a04fc178ed99ae5be90be41388a0fe8ad33d49b823e47bbe2	{"punchAt": "2026-09-25T01:05:00.000Z", "enrollId": "102"}	2026-10-04 22:58:57.412+07
53e80844-4efd-45de-8a99-d25a609ddecf	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	8ae41932-c8e7-4d34-9854-4f25e9488942	102	2026-09-25 16:30:00+07	UNKNOWN	FINGERPRINT	791193b22f3c44d5fdefee8baf08d05e350249308bc67b449cb6afd4cde710ad	{"punchAt": "2026-09-25T09:30:00.000Z", "enrollId": "102"}	2026-10-04 22:58:57.414+07
1bf92315-4bf1-4267-b9e7-658c5e1dce54	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	8ae41932-c8e7-4d34-9854-4f25e9488942	102	2026-09-28 08:25:00+07	UNKNOWN	FINGERPRINT	4988d7f18e8a67251b16c1689d99b683f2be22a1a207734cb3949a85f4a56024	{"punchAt": "2026-09-28T01:25:00.000Z", "enrollId": "102"}	2026-10-04 22:58:57.415+07
91e49b89-8de7-4238-903c-91af9db36b8c	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	8ae41932-c8e7-4d34-9854-4f25e9488942	102	2026-09-28 16:30:00+07	UNKNOWN	FINGERPRINT	d94cbfc54a230e7b76378031922b08caa7dafaa315a4bb4f87446e6f088e66e4	{"punchAt": "2026-09-28T09:30:00.000Z", "enrollId": "102"}	2026-10-04 22:58:57.417+07
64112efb-5620-484f-a773-6519c47a34ee	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	8ae41932-c8e7-4d34-9854-4f25e9488942	102	2026-09-29 08:05:00+07	UNKNOWN	FINGERPRINT	f5003aad5e44ab2784df00a07facbb0429a7abf35672e33bb6d8af12e2629da9	{"punchAt": "2026-09-29T01:05:00.000Z", "enrollId": "102"}	2026-10-04 22:58:57.419+07
77e4a75f-c6ef-4820-b7c5-dcc15c2711bc	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	8ae41932-c8e7-4d34-9854-4f25e9488942	102	2026-09-29 16:30:00+07	UNKNOWN	FINGERPRINT	422865df998b1cdb9968648176508b7883f5ed509105b743408cb13688e69e17	{"punchAt": "2026-09-29T09:30:00.000Z", "enrollId": "102"}	2026-10-04 22:58:57.421+07
dce820b7-8375-412a-918b-242f0f8e9928	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	8ae41932-c8e7-4d34-9854-4f25e9488942	102	2026-09-30 08:40:00+07	UNKNOWN	FINGERPRINT	bedb71f774477ffda858d8b0959d63111da0548b024847343131e5121e53c0c8	{"punchAt": "2026-09-30T01:40:00.000Z", "enrollId": "102"}	2026-10-04 22:58:57.422+07
49a76484-6b27-4887-92a7-fa8742ca33e2	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	8ae41932-c8e7-4d34-9854-4f25e9488942	102	2026-09-30 16:30:00+07	UNKNOWN	FINGERPRINT	ad94a558eb65e3eb466077d63f3f3c238b3d3a89a2b1c724d07d04b59f6bcda1	{"punchAt": "2026-09-30T09:30:00.000Z", "enrollId": "102"}	2026-10-04 22:58:57.424+07
0f537e3d-559d-40b7-9233-a313d0dd98df	4478787b-c3e8-4f0d-8b9b-7046fec7f539	8ae41932-c8e7-4d34-9854-4f25e9488942	103	2026-09-01 08:00:00+07	UNKNOWN	FINGERPRINT	96b39740f1fc387df3e0b57ed4e7b1b89dbdaa73bc4c3200b6ab6aedce067900	{"punchAt": "2026-09-01T01:00:00.000Z", "enrollId": "103"}	2026-10-04 22:58:57.425+07
aaa49eb4-97db-4a0e-8a6f-fb59421b7a8c	4478787b-c3e8-4f0d-8b9b-7046fec7f539	8ae41932-c8e7-4d34-9854-4f25e9488942	103	2026-09-01 16:10:00+07	UNKNOWN	FINGERPRINT	620db6cd6ebcc643ae6d37cdbc1fff773a02fd8606bb7bad892ee1d39b64dc01	{"punchAt": "2026-09-01T09:10:00.000Z", "enrollId": "103"}	2026-10-04 22:58:57.426+07
d5d51b3c-9b74-4947-ad48-ddcda948dff2	4478787b-c3e8-4f0d-8b9b-7046fec7f539	8ae41932-c8e7-4d34-9854-4f25e9488942	103	2026-09-02 08:03:00+07	UNKNOWN	FINGERPRINT	0512b4f6b0f1379d8c99786796aba90df30b5fb291d9f0e828b682ea9b99b4f8	{"punchAt": "2026-09-02T01:03:00.000Z", "enrollId": "103"}	2026-10-04 22:58:57.428+07
7477b956-f2ad-439e-8ea7-051d368d5f79	4478787b-c3e8-4f0d-8b9b-7046fec7f539	8ae41932-c8e7-4d34-9854-4f25e9488942	103	2026-09-02 16:10:00+07	UNKNOWN	FINGERPRINT	b3feee1ba195b5fd3ef4f11b6ea284ecdc30eb1f2f42c40f1a158af72ebe63c2	{"punchAt": "2026-09-02T09:10:00.000Z", "enrollId": "103"}	2026-10-04 22:58:57.429+07
0235838f-9769-4ef0-8bb1-036d88b09d9d	4478787b-c3e8-4f0d-8b9b-7046fec7f539	8ae41932-c8e7-4d34-9854-4f25e9488942	103	2026-09-03 08:06:00+07	UNKNOWN	FINGERPRINT	e9f9866cf2faa2967e92064bc76909b467a36d25714126f1c4132aa425803075	{"punchAt": "2026-09-03T01:06:00.000Z", "enrollId": "103"}	2026-10-04 22:58:57.43+07
1296d575-80be-4d36-8d5b-b612b7259479	4478787b-c3e8-4f0d-8b9b-7046fec7f539	8ae41932-c8e7-4d34-9854-4f25e9488942	103	2026-09-03 16:10:00+07	UNKNOWN	FINGERPRINT	68465c20eb6e873e2f9edb056d5d7461957490be6dd920b9407702c5b0888b74	{"punchAt": "2026-09-03T09:10:00.000Z", "enrollId": "103"}	2026-10-04 22:58:57.432+07
26c6d3a6-9f25-4955-94dd-59c18207c905	4478787b-c3e8-4f0d-8b9b-7046fec7f539	8ae41932-c8e7-4d34-9854-4f25e9488942	103	2026-09-04 08:00:00+07	UNKNOWN	FINGERPRINT	c4b6f6d04d7b972ac5c94539fd95bfa18e8152b110d4239b39f8a18e6e8d0eb6	{"punchAt": "2026-09-04T01:00:00.000Z", "enrollId": "103"}	2026-10-04 22:58:57.433+07
abcf196a-54ee-4115-9612-cecff602a961	4478787b-c3e8-4f0d-8b9b-7046fec7f539	8ae41932-c8e7-4d34-9854-4f25e9488942	103	2026-09-04 16:10:00+07	UNKNOWN	FINGERPRINT	41f5d93f4a07b40a5b6f90794dd542957647e9da0ca79ca4b826728c5db24da1	{"punchAt": "2026-09-04T09:10:00.000Z", "enrollId": "103"}	2026-10-04 22:58:57.435+07
fde66805-1b46-4add-b67e-9cee3cff8070	4478787b-c3e8-4f0d-8b9b-7046fec7f539	8ae41932-c8e7-4d34-9854-4f25e9488942	103	2026-09-07 08:03:00+07	UNKNOWN	FINGERPRINT	c77afc6ac5799851590121f1adfe3ed677ff10c94389b1bca60e51beff8b0e86	{"punchAt": "2026-09-07T01:03:00.000Z", "enrollId": "103"}	2026-10-04 22:58:57.437+07
bec43749-3133-493f-b1ee-fe7af4bade03	4478787b-c3e8-4f0d-8b9b-7046fec7f539	8ae41932-c8e7-4d34-9854-4f25e9488942	103	2026-09-07 16:10:00+07	UNKNOWN	FINGERPRINT	13813e19de8c0dd8a2bd6e74d29baf191977db1f9dc81c94e5961714607e7c66	{"punchAt": "2026-09-07T09:10:00.000Z", "enrollId": "103"}	2026-10-04 22:58:57.438+07
230cd060-a201-4f01-92c2-30e896125414	4478787b-c3e8-4f0d-8b9b-7046fec7f539	8ae41932-c8e7-4d34-9854-4f25e9488942	103	2026-09-08 08:06:00+07	UNKNOWN	FINGERPRINT	f8717bf3231b7b1083fdc7c259603b4d14aabfad6c79c72dda4ef3655631fa63	{"punchAt": "2026-09-08T01:06:00.000Z", "enrollId": "103"}	2026-10-04 22:58:57.44+07
cd9a3ac1-5f30-401f-9ea3-033032d4bc71	4478787b-c3e8-4f0d-8b9b-7046fec7f539	8ae41932-c8e7-4d34-9854-4f25e9488942	103	2026-09-08 16:10:00+07	UNKNOWN	FINGERPRINT	5aa600cc9e47788ac1b643d42052e3ebf9cd5e8d1b801453366e8381b279186d	{"punchAt": "2026-09-08T09:10:00.000Z", "enrollId": "103"}	2026-10-04 22:58:57.441+07
267e8997-bf36-46bc-801a-937c4ad48e64	4478787b-c3e8-4f0d-8b9b-7046fec7f539	8ae41932-c8e7-4d34-9854-4f25e9488942	103	2026-09-10 08:03:00+07	UNKNOWN	FINGERPRINT	db08ce0c782591cd293cfc93976e5e43659cc29bd1354e39e1c25babebf00d0a	{"punchAt": "2026-09-10T01:03:00.000Z", "enrollId": "103"}	2026-10-04 22:58:57.442+07
e960d7b1-6565-4153-b136-1d40bbfe9df2	4478787b-c3e8-4f0d-8b9b-7046fec7f539	8ae41932-c8e7-4d34-9854-4f25e9488942	103	2026-09-10 16:10:00+07	UNKNOWN	FINGERPRINT	c217fa3287c44793c1a8b34f05e1d27d240ba09948d2f1bfc4fbbd5b62c33bb9	{"punchAt": "2026-09-10T09:10:00.000Z", "enrollId": "103"}	2026-10-04 22:58:57.444+07
e2745e2e-3cf3-45bd-8e67-cf59b1689627	4478787b-c3e8-4f0d-8b9b-7046fec7f539	8ae41932-c8e7-4d34-9854-4f25e9488942	103	2026-09-11 08:02:00+07	UNKNOWN	FINGERPRINT	c9466b5f065e6df7090cc0dbdb05c91c2665a664da6de285bbe0519a645a096d	{"punchAt": "2026-09-11T01:02:00.000Z", "enrollId": "103"}	2026-10-04 22:58:57.446+07
8482feec-6a6d-4adb-81c4-93869dd25622	4478787b-c3e8-4f0d-8b9b-7046fec7f539	8ae41932-c8e7-4d34-9854-4f25e9488942	103	2026-09-14 08:00:00+07	UNKNOWN	FINGERPRINT	a37bbf67cdc6d8b2a1e360ab75063c44b41b189216040367ba8b2c9cd696d2f3	{"punchAt": "2026-09-14T01:00:00.000Z", "enrollId": "103"}	2026-10-04 22:58:57.447+07
00512062-cd72-4bf2-a680-c3932e9f7efa	4478787b-c3e8-4f0d-8b9b-7046fec7f539	8ae41932-c8e7-4d34-9854-4f25e9488942	103	2026-09-14 16:10:00+07	UNKNOWN	FINGERPRINT	374815210f1eeec8a895a68c993f762db7466fcdf4b94e35eac9c96c62254d09	{"punchAt": "2026-09-14T09:10:00.000Z", "enrollId": "103"}	2026-10-04 22:58:57.449+07
d9e3a36d-938a-47a1-a859-0c855ff6e2d2	4478787b-c3e8-4f0d-8b9b-7046fec7f539	8ae41932-c8e7-4d34-9854-4f25e9488942	103	2026-09-15 08:03:00+07	UNKNOWN	FINGERPRINT	2daac4b83b562c142ed620ad99253735c2f253874b2d2328bbc3a3c7eb120dab	{"punchAt": "2026-09-15T01:03:00.000Z", "enrollId": "103"}	2026-10-04 22:58:57.451+07
bc9060d5-31ff-4b35-80b0-eb35c50fce05	4478787b-c3e8-4f0d-8b9b-7046fec7f539	8ae41932-c8e7-4d34-9854-4f25e9488942	103	2026-09-15 16:10:00+07	UNKNOWN	FINGERPRINT	97103032826069c3ab6060a675f02136e46a758a044511fb05c92bd8fa9f7a05	{"punchAt": "2026-09-15T09:10:00.000Z", "enrollId": "103"}	2026-10-04 22:58:57.453+07
ff293ea6-ab4f-491d-809c-d03bce99f390	4478787b-c3e8-4f0d-8b9b-7046fec7f539	8ae41932-c8e7-4d34-9854-4f25e9488942	103	2026-09-17 08:06:00+07	UNKNOWN	FINGERPRINT	324e53c0866d8ccb2cd577999e9369fa3a0482fa916cc406af90650121423956	{"punchAt": "2026-09-17T01:06:00.000Z", "enrollId": "103"}	2026-10-04 22:58:57.455+07
94ce74a6-71f0-4f92-923a-28446ac5c7c9	4478787b-c3e8-4f0d-8b9b-7046fec7f539	8ae41932-c8e7-4d34-9854-4f25e9488942	103	2026-09-17 16:10:00+07	UNKNOWN	FINGERPRINT	030574e1a702f198346baa39120c625bcdbaca287608b18b385e404ff39f40aa	{"punchAt": "2026-09-17T09:10:00.000Z", "enrollId": "103"}	2026-10-04 22:58:57.456+07
a5855a5a-6277-47fd-85eb-eda6d67d62cd	4478787b-c3e8-4f0d-8b9b-7046fec7f539	8ae41932-c8e7-4d34-9854-4f25e9488942	103	2026-09-18 08:00:00+07	UNKNOWN	FINGERPRINT	19dad90f08bb051e0453dc5d84e26c38b4e68bd2453908cbbd15158afcec93ac	{"punchAt": "2026-09-18T01:00:00.000Z", "enrollId": "103"}	2026-10-04 22:58:57.458+07
c6447124-1c0e-443d-837c-c6b8dfcb47ff	4478787b-c3e8-4f0d-8b9b-7046fec7f539	8ae41932-c8e7-4d34-9854-4f25e9488942	103	2026-09-18 16:10:00+07	UNKNOWN	FINGERPRINT	df9873fef0440ffbcc29d984c157af27e7ec0d267293d601ea7f703b44afe106	{"punchAt": "2026-09-18T09:10:00.000Z", "enrollId": "103"}	2026-10-04 22:58:57.459+07
269021b4-e383-493c-a03a-e6eeae4be8ab	4478787b-c3e8-4f0d-8b9b-7046fec7f539	8ae41932-c8e7-4d34-9854-4f25e9488942	103	2026-09-21 08:03:00+07	UNKNOWN	FINGERPRINT	6cf34ce0ba4bddc1671164927d1a273b4206061e8e1d9cb89d2a0243623abc22	{"punchAt": "2026-09-21T01:03:00.000Z", "enrollId": "103"}	2026-10-04 22:58:57.461+07
d8ab3697-62c5-42b7-bc68-aa7c102edb3a	4478787b-c3e8-4f0d-8b9b-7046fec7f539	8ae41932-c8e7-4d34-9854-4f25e9488942	103	2026-09-21 16:10:00+07	UNKNOWN	FINGERPRINT	990b8f33e7858f6d8cb49630ccef786c8edc41983ad2823bb01268ed33b810af	{"punchAt": "2026-09-21T09:10:00.000Z", "enrollId": "103"}	2026-10-04 22:58:57.462+07
bddfb0c6-e7ab-4e47-bda7-567548c84ffd	4478787b-c3e8-4f0d-8b9b-7046fec7f539	8ae41932-c8e7-4d34-9854-4f25e9488942	103	2026-09-22 08:06:00+07	UNKNOWN	FINGERPRINT	872d6da0679ceda46fdda84d9e0ec53cede53ae761a64d128e6221201c6e8c84	{"punchAt": "2026-09-22T01:06:00.000Z", "enrollId": "103"}	2026-10-04 22:58:57.465+07
028bee96-feb6-4e1f-8cf7-762513bd68cf	4478787b-c3e8-4f0d-8b9b-7046fec7f539	8ae41932-c8e7-4d34-9854-4f25e9488942	103	2026-09-22 16:10:00+07	UNKNOWN	FINGERPRINT	d910bdf447e8f232085330c43a93b3c1bec9c36bf2c3ed63ca31d66aff1d821c	{"punchAt": "2026-09-22T09:10:00.000Z", "enrollId": "103"}	2026-10-04 22:58:57.468+07
c44f4bcb-8aa7-4562-ac56-e959587d12b4	4478787b-c3e8-4f0d-8b9b-7046fec7f539	8ae41932-c8e7-4d34-9854-4f25e9488942	103	2026-09-24 08:03:00+07	UNKNOWN	FINGERPRINT	9de6021a6ce4aed2771b2a10349d96b498bfa5989b963531527ebb9a66a97e5b	{"punchAt": "2026-09-24T01:03:00.000Z", "enrollId": "103"}	2026-10-04 22:58:57.47+07
f56c8be3-9876-493c-9084-76f669e792bf	4478787b-c3e8-4f0d-8b9b-7046fec7f539	8ae41932-c8e7-4d34-9854-4f25e9488942	103	2026-09-24 16:10:00+07	UNKNOWN	FINGERPRINT	3ab2ddf7e6d86ebfa093c22eaa26c3c927f1cdf6ffa24ac49053e9145302cfef	{"punchAt": "2026-09-24T09:10:00.000Z", "enrollId": "103"}	2026-10-04 22:58:57.472+07
f9c44026-283e-4a29-ab91-3c0e95a11a9b	4478787b-c3e8-4f0d-8b9b-7046fec7f539	8ae41932-c8e7-4d34-9854-4f25e9488942	103	2026-09-25 08:06:00+07	UNKNOWN	FINGERPRINT	e1a2a3dd769ebbecd9810c94c7679f4786076e435c14b4ecbcf2805089c53e25	{"punchAt": "2026-09-25T01:06:00.000Z", "enrollId": "103"}	2026-10-04 22:58:57.473+07
6058a27f-15a2-4343-9a28-23238e838bf2	4478787b-c3e8-4f0d-8b9b-7046fec7f539	8ae41932-c8e7-4d34-9854-4f25e9488942	103	2026-09-25 16:10:00+07	UNKNOWN	FINGERPRINT	ee5f1750411a47f4a84fc3b926ae723857d90cf1d51e9b31df66bbb92ef4aa08	{"punchAt": "2026-09-25T09:10:00.000Z", "enrollId": "103"}	2026-10-04 22:58:57.475+07
d4de9dfd-dfc5-496d-849a-acab42b9ec55	4478787b-c3e8-4f0d-8b9b-7046fec7f539	8ae41932-c8e7-4d34-9854-4f25e9488942	103	2026-09-28 08:02:00+07	UNKNOWN	FINGERPRINT	93f12dd871584118cc4abe6e4582e1d95ad4e47f5c569f332115eeeabf13f25a	{"punchAt": "2026-09-28T01:02:00.000Z", "enrollId": "103"}	2026-10-04 22:58:57.476+07
2655daed-9b5d-40e2-a446-0dc39559565c	4478787b-c3e8-4f0d-8b9b-7046fec7f539	8ae41932-c8e7-4d34-9854-4f25e9488942	103	2026-09-29 08:03:00+07	UNKNOWN	FINGERPRINT	beefbf43aeb162cb5970a87a8e6294f7d2ddcd47e6337c77896da8ee4051f072	{"punchAt": "2026-09-29T01:03:00.000Z", "enrollId": "103"}	2026-10-04 22:58:57.477+07
0cd90b86-f946-41a7-8258-c280c7ce34c3	4478787b-c3e8-4f0d-8b9b-7046fec7f539	8ae41932-c8e7-4d34-9854-4f25e9488942	103	2026-09-29 16:10:00+07	UNKNOWN	FINGERPRINT	9b0383044de9cb2b2137f433955491a763528dfd12583e1f04afb12dda734cc9	{"punchAt": "2026-09-29T09:10:00.000Z", "enrollId": "103"}	2026-10-04 22:58:57.479+07
cc1df6e0-7337-49db-a2b8-31ca6409ca94	4478787b-c3e8-4f0d-8b9b-7046fec7f539	8ae41932-c8e7-4d34-9854-4f25e9488942	103	2026-09-30 08:06:00+07	UNKNOWN	FINGERPRINT	28735602b93eae0da761941bb4a0fba3612691fcdd5cff13a5e227cbb2ed1ad1	{"punchAt": "2026-09-30T01:06:00.000Z", "enrollId": "103"}	2026-10-04 22:58:57.481+07
871610d2-81df-4fca-8cdf-b8d9c628f0d0	4478787b-c3e8-4f0d-8b9b-7046fec7f539	8ae41932-c8e7-4d34-9854-4f25e9488942	103	2026-09-30 16:10:00+07	UNKNOWN	FINGERPRINT	3d7a469d1534b4dc09a9a003e0aa5d9c6c4012b9077adc94bfd88b8f84e0eb47	{"punchAt": "2026-09-30T09:10:00.000Z", "enrollId": "103"}	2026-10-04 22:58:57.482+07
14292214-6f69-4a39-9027-6cd031df7eff	0cd6bde6-3226-4ebb-b135-ca522d42efa4	8ae41932-c8e7-4d34-9854-4f25e9488942	104	2026-09-01 07:55:00+07	UNKNOWN	FINGERPRINT	058890a4e4ac6decf06ff2e257ae8bcc6214a7ef40d17edccdd7264a0321daa4	{"punchAt": "2026-09-01T00:55:00.000Z", "enrollId": "104"}	2026-10-04 22:58:57.485+07
a07949cc-20f0-41f7-88fb-d1b0cee5dc15	0cd6bde6-3226-4ebb-b135-ca522d42efa4	8ae41932-c8e7-4d34-9854-4f25e9488942	104	2026-09-01 16:05:00+07	UNKNOWN	FINGERPRINT	6d10b566c16bfc9a18252b797c3d11639a342dacb775a05ffb6b69ac3fd99d81	{"punchAt": "2026-09-01T09:05:00.000Z", "enrollId": "104"}	2026-10-04 22:58:57.486+07
36b1f08d-98ab-4ebc-b4b7-6a8979d4ab19	0cd6bde6-3226-4ebb-b135-ca522d42efa4	8ae41932-c8e7-4d34-9854-4f25e9488942	104	2026-09-02 07:55:00+07	UNKNOWN	FINGERPRINT	352684f3b739ccaf1cbf35af60e97b9c3f51dbdf56e2b96f4af681ed0ad6ef7d	{"punchAt": "2026-09-02T00:55:00.000Z", "enrollId": "104"}	2026-10-04 22:58:57.488+07
df9cce3a-f946-4e90-97e4-32b0f8788ab0	0cd6bde6-3226-4ebb-b135-ca522d42efa4	8ae41932-c8e7-4d34-9854-4f25e9488942	104	2026-09-02 16:05:00+07	UNKNOWN	FINGERPRINT	ce99b0952cef5be83dc6d5a7bf3956303c8224225fb24e21621ca9c803e7d79e	{"punchAt": "2026-09-02T09:05:00.000Z", "enrollId": "104"}	2026-10-04 22:58:57.489+07
8987c0c5-7c1c-4fe5-9d90-5d8033f40830	0cd6bde6-3226-4ebb-b135-ca522d42efa4	8ae41932-c8e7-4d34-9854-4f25e9488942	104	2026-09-03 07:55:00+07	UNKNOWN	FINGERPRINT	d260bb850c4d5eecb20bb7a6d693e052caa33226b0e1d4062c60c6c7f4b4c8d0	{"punchAt": "2026-09-03T00:55:00.000Z", "enrollId": "104"}	2026-10-04 22:58:57.49+07
16b8cec0-f1c1-4289-accd-a3d7568e9033	0cd6bde6-3226-4ebb-b135-ca522d42efa4	8ae41932-c8e7-4d34-9854-4f25e9488942	104	2026-09-03 16:05:00+07	UNKNOWN	FINGERPRINT	b64a861aad7e1850d4d213e60188a5395549a4c913e0bec6fc40eaa3725a43e3	{"punchAt": "2026-09-03T09:05:00.000Z", "enrollId": "104"}	2026-10-04 22:58:57.491+07
eceb120d-8dc4-4498-a1c0-2fa088e9af24	0cd6bde6-3226-4ebb-b135-ca522d42efa4	8ae41932-c8e7-4d34-9854-4f25e9488942	104	2026-09-04 07:55:00+07	UNKNOWN	FINGERPRINT	3e79b8872e07ec0147fd160c684d51d06933a101ffd5118b6f760a601fea8c98	{"punchAt": "2026-09-04T00:55:00.000Z", "enrollId": "104"}	2026-10-04 22:58:57.493+07
111cf5f7-d0d8-49d8-8213-cf3692f95aec	0cd6bde6-3226-4ebb-b135-ca522d42efa4	8ae41932-c8e7-4d34-9854-4f25e9488942	104	2026-09-04 16:05:00+07	UNKNOWN	FINGERPRINT	32206bbd8ed72ef607c73b85526800dbaa6b7813c2a4010046a23c23db46cd85	{"punchAt": "2026-09-04T09:05:00.000Z", "enrollId": "104"}	2026-10-04 22:58:57.494+07
91072f26-694a-41a6-b1c4-93f3ff2b311d	0cd6bde6-3226-4ebb-b135-ca522d42efa4	8ae41932-c8e7-4d34-9854-4f25e9488942	104	2026-09-07 07:55:00+07	UNKNOWN	FINGERPRINT	318f4c24500f556f3f6d6d843ffb5c3e74669d11ec3e6a793f285e6fb138024c	{"punchAt": "2026-09-07T00:55:00.000Z", "enrollId": "104"}	2026-10-04 22:58:57.495+07
944d5e8b-095d-4bd3-8e49-6511e1c533c3	0cd6bde6-3226-4ebb-b135-ca522d42efa4	8ae41932-c8e7-4d34-9854-4f25e9488942	104	2026-09-07 16:05:00+07	UNKNOWN	FINGERPRINT	668d07638c200974928cddb6dde611a4d98323117d350d9e1737fe424a32cb24	{"punchAt": "2026-09-07T09:05:00.000Z", "enrollId": "104"}	2026-10-04 22:58:57.497+07
b2154611-d560-41b4-ad37-32f0b6b7367a	0cd6bde6-3226-4ebb-b135-ca522d42efa4	8ae41932-c8e7-4d34-9854-4f25e9488942	104	2026-09-11 07:55:00+07	UNKNOWN	FINGERPRINT	f3cffd89ead285072f1be54e99b6ef409eec0f4f0bc9841eb39253716d5fc021	{"punchAt": "2026-09-11T00:55:00.000Z", "enrollId": "104"}	2026-10-04 22:58:57.498+07
1fbdf9e9-6856-44e2-b151-6996b5d065ff	0cd6bde6-3226-4ebb-b135-ca522d42efa4	8ae41932-c8e7-4d34-9854-4f25e9488942	104	2026-09-11 16:05:00+07	UNKNOWN	FINGERPRINT	f781c29b38d305ad158019a9d7c8dc47d8dc2c570b376b3d304c8421cc47599e	{"punchAt": "2026-09-11T09:05:00.000Z", "enrollId": "104"}	2026-10-04 22:58:57.5+07
755dab2a-c97e-4445-a9c8-7d79cd695828	0cd6bde6-3226-4ebb-b135-ca522d42efa4	8ae41932-c8e7-4d34-9854-4f25e9488942	104	2026-09-14 07:55:00+07	UNKNOWN	FINGERPRINT	1ef74c6b0d95803e127c916763bc9075ed8af936caf78aaf5e99fa42f230ff8d	{"punchAt": "2026-09-14T00:55:00.000Z", "enrollId": "104"}	2026-10-04 22:58:57.502+07
81f69705-188d-421e-beb7-6e8332510b97	0cd6bde6-3226-4ebb-b135-ca522d42efa4	8ae41932-c8e7-4d34-9854-4f25e9488942	104	2026-09-14 16:05:00+07	UNKNOWN	FINGERPRINT	35a03bfe1641a84b51ac743605a53ddae67e0eb117da863db1e01631c0eddc4a	{"punchAt": "2026-09-14T09:05:00.000Z", "enrollId": "104"}	2026-10-04 22:58:57.503+07
38960916-bfb9-4de7-a027-2de215e79104	0cd6bde6-3226-4ebb-b135-ca522d42efa4	8ae41932-c8e7-4d34-9854-4f25e9488942	104	2026-09-15 07:55:00+07	UNKNOWN	FINGERPRINT	3772a3c2e2c1a1ff442ff1b0e45268fe4f478ec05e74c31ea60e7b0f36b40c48	{"punchAt": "2026-09-15T00:55:00.000Z", "enrollId": "104"}	2026-10-04 22:58:57.505+07
75813451-da3b-401a-b9c4-353b45c0d48b	0cd6bde6-3226-4ebb-b135-ca522d42efa4	8ae41932-c8e7-4d34-9854-4f25e9488942	104	2026-09-15 16:05:00+07	UNKNOWN	FINGERPRINT	f09a050babcb38aef9462f4be666c1fcf27869c243a7ec4e72c20d16ee2547cc	{"punchAt": "2026-09-15T09:05:00.000Z", "enrollId": "104"}	2026-10-04 22:58:57.507+07
ee1a965f-96ac-428b-a700-6385bcb191c5	0cd6bde6-3226-4ebb-b135-ca522d42efa4	8ae41932-c8e7-4d34-9854-4f25e9488942	104	2026-09-17 07:55:00+07	UNKNOWN	FINGERPRINT	c5303748003018bb2e7b382a56f389c47b19b2c4801082e5a62ca71a4168437e	{"punchAt": "2026-09-17T00:55:00.000Z", "enrollId": "104"}	2026-10-04 22:58:57.508+07
3bea7fee-aecc-4af3-a2b8-1f215862a0f9	0cd6bde6-3226-4ebb-b135-ca522d42efa4	8ae41932-c8e7-4d34-9854-4f25e9488942	104	2026-09-17 16:05:00+07	UNKNOWN	FINGERPRINT	adb0e48cd7113656dc018df1ea0e38c73f92aa05f8a34deb6c383a4f7e6a6c40	{"punchAt": "2026-09-17T09:05:00.000Z", "enrollId": "104"}	2026-10-04 22:58:57.509+07
5092aee7-4566-4dd6-9040-7b7e4a2876b7	0cd6bde6-3226-4ebb-b135-ca522d42efa4	8ae41932-c8e7-4d34-9854-4f25e9488942	104	2026-09-18 07:55:00+07	UNKNOWN	FINGERPRINT	15f145f227bc68e4b9a0fefdd1cbb60b2645b9a7e832a63d17a4f33aecb84c3c	{"punchAt": "2026-09-18T00:55:00.000Z", "enrollId": "104"}	2026-10-04 22:58:57.511+07
85ace093-0622-4deb-84fd-f49f28528be6	0cd6bde6-3226-4ebb-b135-ca522d42efa4	8ae41932-c8e7-4d34-9854-4f25e9488942	104	2026-09-18 16:05:00+07	UNKNOWN	FINGERPRINT	7d4a304ed5aef16e13ac92b9a304f629bcf9c50c82fdf0dd8f9c9823fb4ad047	{"punchAt": "2026-09-18T09:05:00.000Z", "enrollId": "104"}	2026-10-04 22:58:57.512+07
699bd3c5-066e-4115-8f9d-0286df7bb280	0cd6bde6-3226-4ebb-b135-ca522d42efa4	8ae41932-c8e7-4d34-9854-4f25e9488942	104	2026-09-22 07:55:00+07	UNKNOWN	FINGERPRINT	1821f32cb4fa18a4024601a88529cc2ab0b2f1f3050c460754136d1d5e55623c	{"punchAt": "2026-09-22T00:55:00.000Z", "enrollId": "104"}	2026-10-04 22:58:57.514+07
390f28ff-cf54-4452-ad8c-4affe7160b0e	0cd6bde6-3226-4ebb-b135-ca522d42efa4	8ae41932-c8e7-4d34-9854-4f25e9488942	104	2026-09-22 16:05:00+07	UNKNOWN	FINGERPRINT	adb6c9f1622cfd0e925cb0ea1f569bf306ad731aac44538c247460d57c1fb092	{"punchAt": "2026-09-22T09:05:00.000Z", "enrollId": "104"}	2026-10-04 22:58:57.516+07
4af2c218-5e39-4eb6-9ac6-a26de0316dba	0cd6bde6-3226-4ebb-b135-ca522d42efa4	8ae41932-c8e7-4d34-9854-4f25e9488942	104	2026-09-23 07:55:00+07	UNKNOWN	FINGERPRINT	d9a66a46ce7fbf4fb3c37f989765218721b2353b316e60dbad55af097ec27322	{"punchAt": "2026-09-23T00:55:00.000Z", "enrollId": "104"}	2026-10-04 22:58:57.518+07
18378748-aab2-4e70-aac4-6d01216f15a2	0cd6bde6-3226-4ebb-b135-ca522d42efa4	8ae41932-c8e7-4d34-9854-4f25e9488942	104	2026-09-23 16:05:00+07	UNKNOWN	FINGERPRINT	ca1154cf301c0251a362d5c83d77ea24b6da49a89a44a3a0167f6e9fb8412b99	{"punchAt": "2026-09-23T09:05:00.000Z", "enrollId": "104"}	2026-10-04 22:58:57.52+07
df3da7e9-e588-49d1-aeb9-5f33278a46af	0cd6bde6-3226-4ebb-b135-ca522d42efa4	8ae41932-c8e7-4d34-9854-4f25e9488942	104	2026-09-24 07:55:00+07	UNKNOWN	FINGERPRINT	7d620ec2b66441f7e0bd0357d4997ec3b4bfb55b9fce33905bdc77ec717e1cfe	{"punchAt": "2026-09-24T00:55:00.000Z", "enrollId": "104"}	2026-10-04 22:58:57.522+07
3b8c6bb5-ac42-4540-8f06-252c7f8d7eb9	0cd6bde6-3226-4ebb-b135-ca522d42efa4	8ae41932-c8e7-4d34-9854-4f25e9488942	104	2026-09-24 16:05:00+07	UNKNOWN	FINGERPRINT	42d3fe95bb019df7d38120a53be2a210a78f3e9874681bd8a008aee7945f426b	{"punchAt": "2026-09-24T09:05:00.000Z", "enrollId": "104"}	2026-10-04 22:58:57.523+07
98230324-9703-4b9f-b1fe-f990843890ae	0cd6bde6-3226-4ebb-b135-ca522d42efa4	8ae41932-c8e7-4d34-9854-4f25e9488942	104	2026-09-25 07:55:00+07	UNKNOWN	FINGERPRINT	5974143633da779d6690ce5fa1bfef2997d173d81445c7797f4746d82c560b1c	{"punchAt": "2026-09-25T00:55:00.000Z", "enrollId": "104"}	2026-10-04 22:58:57.525+07
626947f6-e754-42c2-9df2-a8f08c8d52d1	0cd6bde6-3226-4ebb-b135-ca522d42efa4	8ae41932-c8e7-4d34-9854-4f25e9488942	104	2026-09-25 16:05:00+07	UNKNOWN	FINGERPRINT	7766797b8744a412065c079800b660f19ac8f3439d3fa9d47997f06437cc7a79	{"punchAt": "2026-09-25T09:05:00.000Z", "enrollId": "104"}	2026-10-04 22:58:57.527+07
6d862dde-dbe2-4f0b-b424-d21d6178ae75	0cd6bde6-3226-4ebb-b135-ca522d42efa4	8ae41932-c8e7-4d34-9854-4f25e9488942	104	2026-09-28 07:55:00+07	UNKNOWN	FINGERPRINT	25fd1d56a396fe6793f0265b180639e000f3fa2f980519ac5faa45793e1c899a	{"punchAt": "2026-09-28T00:55:00.000Z", "enrollId": "104"}	2026-10-04 22:58:57.528+07
929b92e9-a734-4346-8797-b13ae56a81da	0cd6bde6-3226-4ebb-b135-ca522d42efa4	8ae41932-c8e7-4d34-9854-4f25e9488942	104	2026-09-28 16:05:00+07	UNKNOWN	FINGERPRINT	56264c69e914157de33470798ea7ce7e1a8abecbf5c1c7f4b3efb367d6dc7c17	{"punchAt": "2026-09-28T09:05:00.000Z", "enrollId": "104"}	2026-10-04 22:58:57.529+07
0d986183-45a6-487d-9774-aea13e16c3a7	0cd6bde6-3226-4ebb-b135-ca522d42efa4	8ae41932-c8e7-4d34-9854-4f25e9488942	104	2026-09-29 07:55:00+07	UNKNOWN	FINGERPRINT	0e9231d3f0e81881c3a745192e2eb5865248863f57def4e8ec5ef01b70ecc11b	{"punchAt": "2026-09-29T00:55:00.000Z", "enrollId": "104"}	2026-10-04 22:58:57.53+07
10dda120-9ecd-4685-b525-d83dbd59ab73	0cd6bde6-3226-4ebb-b135-ca522d42efa4	8ae41932-c8e7-4d34-9854-4f25e9488942	104	2026-09-29 16:05:00+07	UNKNOWN	FINGERPRINT	69c60839ddbee50a8e582b9d14f01e603f397124dff3388df63de326e7b06f11	{"punchAt": "2026-09-29T09:05:00.000Z", "enrollId": "104"}	2026-10-04 22:58:57.532+07
6a762ebc-9f8e-4ef9-ae11-4ac22bc8f8b0	0cd6bde6-3226-4ebb-b135-ca522d42efa4	8ae41932-c8e7-4d34-9854-4f25e9488942	104	2026-09-30 07:55:00+07	UNKNOWN	FINGERPRINT	b87fed147b1a348fba2130258c9a13f6a946762cc948205c64bff03ad4ebd1b1	{"punchAt": "2026-09-30T00:55:00.000Z", "enrollId": "104"}	2026-10-04 22:58:57.534+07
b4cc1c5d-4286-45e4-b612-fb28dbd8d638	0cd6bde6-3226-4ebb-b135-ca522d42efa4	8ae41932-c8e7-4d34-9854-4f25e9488942	104	2026-09-30 16:05:00+07	UNKNOWN	FINGERPRINT	27d90a05fe312e1b3fbe16de87e52d7dc1e824e5e3adcd75fe9d5e22e7b54467	{"punchAt": "2026-09-30T09:05:00.000Z", "enrollId": "104"}	2026-10-04 22:58:57.535+07
2e6776ee-bbad-450c-9b39-488c93f544e3	0c685448-b52e-4e60-89ea-6f7c500a86d5	8ae41932-c8e7-4d34-9854-4f25e9488942	105	2026-09-01 15:50:00+07	UNKNOWN	FINGERPRINT	c34ff0f59afb8ff11eb8bb3007f11e995d12f74ba33853a53411f0cde14015fb	{"punchAt": "2026-09-01T08:50:00.000Z", "enrollId": "105"}	2026-10-04 22:58:57.537+07
16a6e1c0-df6a-4aa5-919c-da6112b465b4	0c685448-b52e-4e60-89ea-6f7c500a86d5	8ae41932-c8e7-4d34-9854-4f25e9488942	105	2026-09-02 00:05:00+07	UNKNOWN	FINGERPRINT	0702b9271c93a13cf6b076ccc8b10c733049b60573dcb02d45919b8e58830df0	{"punchAt": "2026-09-01T17:05:00.000Z", "enrollId": "105"}	2026-10-04 22:58:57.538+07
f6ca1b6e-b657-4b71-aac9-8bc000e5db81	0c685448-b52e-4e60-89ea-6f7c500a86d5	8ae41932-c8e7-4d34-9854-4f25e9488942	105	2026-09-02 15:55:00+07	UNKNOWN	FINGERPRINT	9b5bc1364d5c16eef66454dcb01cd43baf0bd7d3a41aa9643d0e1744ab73217d	{"punchAt": "2026-09-02T08:55:00.000Z", "enrollId": "105"}	2026-10-04 22:58:57.539+07
80e3d41f-f844-4c5d-91ac-14ce171773e5	0c685448-b52e-4e60-89ea-6f7c500a86d5	8ae41932-c8e7-4d34-9854-4f25e9488942	105	2026-09-03 00:10:00+07	UNKNOWN	FINGERPRINT	88973610e897cbf06f9a3ef171fbcd9707e9ffba313cf144642391c48013b3b4	{"punchAt": "2026-09-02T17:10:00.000Z", "enrollId": "105"}	2026-10-04 22:58:57.541+07
19cc4faf-ae28-4e90-b1bb-6a1c4543b7c7	0c685448-b52e-4e60-89ea-6f7c500a86d5	8ae41932-c8e7-4d34-9854-4f25e9488942	105	2026-09-03 16:00:00+07	UNKNOWN	FINGERPRINT	fe865ca6a0a498908bc9bea623ca84bf63a5ff4bb8cbfbd65674130c42f4fb2a	{"punchAt": "2026-09-03T09:00:00.000Z", "enrollId": "105"}	2026-10-04 22:58:57.542+07
57df6be6-c808-4341-a740-d27912c57945	0c685448-b52e-4e60-89ea-6f7c500a86d5	8ae41932-c8e7-4d34-9854-4f25e9488942	105	2026-09-04 00:15:00+07	UNKNOWN	FINGERPRINT	8cbd38b4e763ac20442795c98ce7b9f19aa0c9a16da076c53dae38127068af60	{"punchAt": "2026-09-03T17:15:00.000Z", "enrollId": "105"}	2026-10-04 22:58:57.544+07
dc146fb7-0d82-4a6e-97ea-85c086ecec67	0c685448-b52e-4e60-89ea-6f7c500a86d5	8ae41932-c8e7-4d34-9854-4f25e9488942	105	2026-09-04 15:50:00+07	UNKNOWN	FINGERPRINT	9ccd57f707442901a34cd5b23fa7bdff35200b46d96e89d9de77109d12ecb247	{"punchAt": "2026-09-04T08:50:00.000Z", "enrollId": "105"}	2026-10-04 22:58:57.545+07
57fb3804-5427-41b8-98e8-a84c2bdb780a	0c685448-b52e-4e60-89ea-6f7c500a86d5	8ae41932-c8e7-4d34-9854-4f25e9488942	105	2026-09-05 00:05:00+07	UNKNOWN	FINGERPRINT	839e0a30a7652e1345ebcad6a0f7bc1350478e27b69521ad6e4a7c2332d984ab	{"punchAt": "2026-09-04T17:05:00.000Z", "enrollId": "105"}	2026-10-04 22:58:57.546+07
735ef9e9-4606-4f80-a9de-7061e7b079ee	0c685448-b52e-4e60-89ea-6f7c500a86d5	8ae41932-c8e7-4d34-9854-4f25e9488942	105	2026-09-07 15:55:00+07	UNKNOWN	FINGERPRINT	c96376f93e7d6762db8fd309a3693ef40a3dce679cada52d2d3eaaeb8578232b	{"punchAt": "2026-09-07T08:55:00.000Z", "enrollId": "105"}	2026-10-04 22:58:57.547+07
1adb38f9-c795-4d3a-a66d-469e21bd3824	0c685448-b52e-4e60-89ea-6f7c500a86d5	8ae41932-c8e7-4d34-9854-4f25e9488942	105	2026-09-08 00:10:00+07	UNKNOWN	FINGERPRINT	9ee4c222da7f132109aad67e7e0ea9fd772635221d56f50ffdd85c74efcef919	{"punchAt": "2026-09-07T17:10:00.000Z", "enrollId": "105"}	2026-10-04 22:58:57.548+07
901dd607-143e-40bf-867e-eec742a24753	0c685448-b52e-4e60-89ea-6f7c500a86d5	8ae41932-c8e7-4d34-9854-4f25e9488942	105	2026-09-08 16:00:00+07	UNKNOWN	FINGERPRINT	418806dda1662673d3c6924ab7253595783e566c8716bc2fddf8c9f95d87d1b5	{"punchAt": "2026-09-08T09:00:00.000Z", "enrollId": "105"}	2026-10-04 22:58:57.55+07
40d009b0-de59-4abe-8b6e-a3758638a1a2	0c685448-b52e-4e60-89ea-6f7c500a86d5	8ae41932-c8e7-4d34-9854-4f25e9488942	105	2026-09-09 00:15:00+07	UNKNOWN	FINGERPRINT	a101cc13cad1e37ec029dd1d4da0503412453855ec55cde07c04d6f0107a1e53	{"punchAt": "2026-09-08T17:15:00.000Z", "enrollId": "105"}	2026-10-04 22:58:57.552+07
4821e87f-6557-4927-a63d-01477434eed5	0c685448-b52e-4e60-89ea-6f7c500a86d5	8ae41932-c8e7-4d34-9854-4f25e9488942	105	2026-09-09 15:50:00+07	UNKNOWN	FINGERPRINT	5f7a98b27efc5850c59df39ba8ebd22bf9e373e08506a7c8e3562bcb1aa506b5	{"punchAt": "2026-09-09T08:50:00.000Z", "enrollId": "105"}	2026-10-04 22:58:57.554+07
dbb6e4d2-826d-4863-8a0f-e4fe09ae5a08	0c685448-b52e-4e60-89ea-6f7c500a86d5	8ae41932-c8e7-4d34-9854-4f25e9488942	105	2026-09-10 00:05:00+07	UNKNOWN	FINGERPRINT	240c37a90f94c36da09efb9f7bde02ca1d5d810e8019be9a5323f63a42ee4fbb	{"punchAt": "2026-09-09T17:05:00.000Z", "enrollId": "105"}	2026-10-04 22:58:57.555+07
bb8a8ce2-bfa8-467e-bf98-494dd6f4811a	0c685448-b52e-4e60-89ea-6f7c500a86d5	8ae41932-c8e7-4d34-9854-4f25e9488942	105	2026-09-10 15:55:00+07	UNKNOWN	FINGERPRINT	7b478a03e9f28d8f9a0c2a8354363134ecd722b4af772a014332b68eb8504e97	{"punchAt": "2026-09-10T08:55:00.000Z", "enrollId": "105"}	2026-10-04 22:58:57.556+07
e7913ede-4631-4571-8cdf-cd0d3c960f60	0c685448-b52e-4e60-89ea-6f7c500a86d5	8ae41932-c8e7-4d34-9854-4f25e9488942	105	2026-09-11 00:10:00+07	UNKNOWN	FINGERPRINT	0d492092339db050adb7bf3ba519707d247013a3111ebb497dae73dc63a2d710	{"punchAt": "2026-09-10T17:10:00.000Z", "enrollId": "105"}	2026-10-04 22:58:57.557+07
fe6b58ce-3639-4c02-a72b-6161bbcf7286	0c685448-b52e-4e60-89ea-6f7c500a86d5	8ae41932-c8e7-4d34-9854-4f25e9488942	105	2026-09-11 16:00:00+07	UNKNOWN	FINGERPRINT	356f3aabfa43da5b2acd6c02678fbc69d0e94bee4b6eeee2bb4ad145b5f87d86	{"punchAt": "2026-09-11T09:00:00.000Z", "enrollId": "105"}	2026-10-04 22:58:57.558+07
176c28a4-4839-4fd7-a146-b06244b52a32	0c685448-b52e-4e60-89ea-6f7c500a86d5	8ae41932-c8e7-4d34-9854-4f25e9488942	105	2026-09-12 00:15:00+07	UNKNOWN	FINGERPRINT	0b388feda5bb56f211d6ef512c663cdad3510b8fd8a7c4f1e1e74b0417052393	{"punchAt": "2026-09-11T17:15:00.000Z", "enrollId": "105"}	2026-10-04 22:58:57.56+07
4907114e-63c1-4e45-a73e-14f7e2f3e8e8	0c685448-b52e-4e60-89ea-6f7c500a86d5	8ae41932-c8e7-4d34-9854-4f25e9488942	105	2026-09-14 16:35:00+07	UNKNOWN	FINGERPRINT	df5abbf0108781ce381e89943855926cac13123cc51bea71dc29ccee7d173045	{"punchAt": "2026-09-14T09:35:00.000Z", "enrollId": "105"}	2026-10-04 22:58:57.561+07
bba88a1e-a8be-41d7-a8eb-c85499056fb2	0c685448-b52e-4e60-89ea-6f7c500a86d5	8ae41932-c8e7-4d34-9854-4f25e9488942	105	2026-09-15 00:05:00+07	UNKNOWN	FINGERPRINT	222ff097ed75b5656c97ffd448a6a38bc184f26e9687ef242d1b6f5af19f9467	{"punchAt": "2026-09-14T17:05:00.000Z", "enrollId": "105"}	2026-10-04 22:58:57.562+07
7a9e6ba0-e8c2-460b-8dd1-1a6c36a98492	0c685448-b52e-4e60-89ea-6f7c500a86d5	8ae41932-c8e7-4d34-9854-4f25e9488942	105	2026-09-15 15:55:00+07	UNKNOWN	FINGERPRINT	31d5b80cd8d22fd4534fa4e2ad3299eef28f027955fed96c07c1e776d835e13d	{"punchAt": "2026-09-15T08:55:00.000Z", "enrollId": "105"}	2026-10-04 22:58:57.564+07
13e1e062-9a83-4a57-bfee-a8cd30e0a0d3	0c685448-b52e-4e60-89ea-6f7c500a86d5	8ae41932-c8e7-4d34-9854-4f25e9488942	105	2026-09-16 00:10:00+07	UNKNOWN	FINGERPRINT	74c2a154a61c1da0127b3a1f35fd44f15a669a30414a194c06593f73d6fdbc6e	{"punchAt": "2026-09-15T17:10:00.000Z", "enrollId": "105"}	2026-10-04 22:58:57.568+07
4fcbd60f-b469-436d-9494-96a917ca7594	0c685448-b52e-4e60-89ea-6f7c500a86d5	8ae41932-c8e7-4d34-9854-4f25e9488942	105	2026-09-17 16:00:00+07	UNKNOWN	FINGERPRINT	5dcdaa688becdb93c4e216ac593fb698b15eb94074dc6175e091d5bd9c1d09b4	{"punchAt": "2026-09-17T09:00:00.000Z", "enrollId": "105"}	2026-10-04 22:58:57.569+07
56e8f5ab-4f99-4c3d-973f-e16c05b47842	0c685448-b52e-4e60-89ea-6f7c500a86d5	8ae41932-c8e7-4d34-9854-4f25e9488942	105	2026-09-18 00:15:00+07	UNKNOWN	FINGERPRINT	d92c8bb0195f74a19f604eda875c97e6956cdc2049456de09b6b80a55cf55313	{"punchAt": "2026-09-17T17:15:00.000Z", "enrollId": "105"}	2026-10-04 22:58:57.571+07
d8d958d5-edd2-4ecc-a819-e00d4f246da0	0c685448-b52e-4e60-89ea-6f7c500a86d5	8ae41932-c8e7-4d34-9854-4f25e9488942	105	2026-09-18 15:50:00+07	UNKNOWN	FINGERPRINT	94ed686f96c7e013da9e9fdf95a43092db5deb5b95b3661f2534dcd2afc92670	{"punchAt": "2026-09-18T08:50:00.000Z", "enrollId": "105"}	2026-10-04 22:58:57.573+07
bc69ced5-b1b6-42e1-9125-57439d41eb38	0c685448-b52e-4e60-89ea-6f7c500a86d5	8ae41932-c8e7-4d34-9854-4f25e9488942	105	2026-09-19 00:05:00+07	UNKNOWN	FINGERPRINT	59c3ac40b162bd7aa7270abf872a2e757e35656c791558c603e8cc7445b75b6d	{"punchAt": "2026-09-18T17:05:00.000Z", "enrollId": "105"}	2026-10-04 22:58:57.574+07
3b8b426e-5539-4340-a970-a0647b725476	0c685448-b52e-4e60-89ea-6f7c500a86d5	8ae41932-c8e7-4d34-9854-4f25e9488942	105	2026-09-21 15:55:00+07	UNKNOWN	FINGERPRINT	8d0f8c0b4b8562deacce1e5287bc9959c45fd89190b3b388666e81f69ec3b723	{"punchAt": "2026-09-21T08:55:00.000Z", "enrollId": "105"}	2026-10-04 22:58:57.576+07
be06c2dd-a7bf-4d6d-8732-1ef56ad4b139	0c685448-b52e-4e60-89ea-6f7c500a86d5	8ae41932-c8e7-4d34-9854-4f25e9488942	105	2026-09-22 00:10:00+07	UNKNOWN	FINGERPRINT	5eff968ef6f62bd9f8148455937f9676101eb0c382e239a1011efbf924f9ea89	{"punchAt": "2026-09-21T17:10:00.000Z", "enrollId": "105"}	2026-10-04 22:58:57.577+07
8c5981da-7df3-4cd9-927a-d650026e7e08	0c685448-b52e-4e60-89ea-6f7c500a86d5	8ae41932-c8e7-4d34-9854-4f25e9488942	105	2026-09-22 16:00:00+07	UNKNOWN	FINGERPRINT	f51cf3315f5dd2430ced48f696089e3b202118c396a41fa6b2e9c164fcc0b3de	{"punchAt": "2026-09-22T09:00:00.000Z", "enrollId": "105"}	2026-10-04 22:58:57.578+07
cd10895f-f22a-49d6-9104-0078ea9a3a5c	0c685448-b52e-4e60-89ea-6f7c500a86d5	8ae41932-c8e7-4d34-9854-4f25e9488942	105	2026-09-23 00:15:00+07	UNKNOWN	FINGERPRINT	bca7e2f1410328f526167009cea7db4c6b493872af716a4973de9995cb9172f5	{"punchAt": "2026-09-22T17:15:00.000Z", "enrollId": "105"}	2026-10-04 22:58:57.58+07
6ac98480-6822-448a-9aa2-35fce5d15dfc	0c685448-b52e-4e60-89ea-6f7c500a86d5	8ae41932-c8e7-4d34-9854-4f25e9488942	105	2026-09-23 15:50:00+07	UNKNOWN	FINGERPRINT	17f1a4bbff1cca7ebc7dbc9c0a171ca67fe870f1d1c96ed59da71ea4baa9051b	{"punchAt": "2026-09-23T08:50:00.000Z", "enrollId": "105"}	2026-10-04 22:58:57.581+07
8a826ec5-e1f8-4578-adde-234d77b772b6	0c685448-b52e-4e60-89ea-6f7c500a86d5	8ae41932-c8e7-4d34-9854-4f25e9488942	105	2026-09-24 00:05:00+07	UNKNOWN	FINGERPRINT	76394c3a583bab0c7bfa5d623113fdee7aff4f6d06670d3aec49f810c7966f3e	{"punchAt": "2026-09-23T17:05:00.000Z", "enrollId": "105"}	2026-10-04 22:58:57.583+07
4663f411-9b64-4eba-be71-7829f8b614d6	0c685448-b52e-4e60-89ea-6f7c500a86d5	8ae41932-c8e7-4d34-9854-4f25e9488942	105	2026-09-24 15:55:00+07	UNKNOWN	FINGERPRINT	71b220a28b586ccaec80c095eb36e4b134d7a053d0559d85c187fab5d8e228e8	{"punchAt": "2026-09-24T08:55:00.000Z", "enrollId": "105"}	2026-10-04 22:58:57.585+07
f37bebee-3790-4afd-bf00-86627864f97a	0c685448-b52e-4e60-89ea-6f7c500a86d5	8ae41932-c8e7-4d34-9854-4f25e9488942	105	2026-09-25 00:10:00+07	UNKNOWN	FINGERPRINT	ca406c7d9b6fd0d5884a840a2dd4132045ecc61fbdb6e99df63ee2093801689f	{"punchAt": "2026-09-24T17:10:00.000Z", "enrollId": "105"}	2026-10-04 22:58:57.586+07
665affbf-0e6d-46b7-a339-f94d22b3fd2d	0c685448-b52e-4e60-89ea-6f7c500a86d5	8ae41932-c8e7-4d34-9854-4f25e9488942	105	2026-09-25 16:00:00+07	UNKNOWN	FINGERPRINT	bf44af3fcec65c5fd403ad0e29e83b061fabda87aa470449bfb4ebbc19a73211	{"punchAt": "2026-09-25T09:00:00.000Z", "enrollId": "105"}	2026-10-04 22:58:57.588+07
4b23a9c2-f133-4bbf-83a5-a7488180a498	0c685448-b52e-4e60-89ea-6f7c500a86d5	8ae41932-c8e7-4d34-9854-4f25e9488942	105	2026-09-26 00:15:00+07	UNKNOWN	FINGERPRINT	4e4fdbd5a66be1615837c1cdf4c0e74ccdd09ca05b37a0e12479a0bd22a96238	{"punchAt": "2026-09-25T17:15:00.000Z", "enrollId": "105"}	2026-10-04 22:58:57.59+07
6af1cb8a-d0ed-4858-be6e-9991b16a93fa	0c685448-b52e-4e60-89ea-6f7c500a86d5	8ae41932-c8e7-4d34-9854-4f25e9488942	105	2026-09-28 15:50:00+07	UNKNOWN	FINGERPRINT	6e0b4d6f43a99d4473405777378c242ce85fa0b88c1fac96a6620c5cc588d1b8	{"punchAt": "2026-09-28T08:50:00.000Z", "enrollId": "105"}	2026-10-04 22:58:57.591+07
bcf2df49-0e05-47c8-ba05-5e5953af3622	0c685448-b52e-4e60-89ea-6f7c500a86d5	8ae41932-c8e7-4d34-9854-4f25e9488942	105	2026-09-29 00:05:00+07	UNKNOWN	FINGERPRINT	43626b86f58a3914be6d2447b621a4a1ee7ee545c80fec9c963bf3974aacadbf	{"punchAt": "2026-09-28T17:05:00.000Z", "enrollId": "105"}	2026-10-04 22:58:57.592+07
36a60454-706a-4542-bba6-bdd55a499aa4	0c685448-b52e-4e60-89ea-6f7c500a86d5	8ae41932-c8e7-4d34-9854-4f25e9488942	105	2026-09-29 15:55:00+07	UNKNOWN	FINGERPRINT	4288ec454e3cb1f85b12369eb34fea5077788fbec480883e2e69365d88fbb614	{"punchAt": "2026-09-29T08:55:00.000Z", "enrollId": "105"}	2026-10-04 22:58:57.594+07
21b98600-90a3-4d87-b514-143ab78cb0a4	0c685448-b52e-4e60-89ea-6f7c500a86d5	8ae41932-c8e7-4d34-9854-4f25e9488942	105	2026-09-30 00:10:00+07	UNKNOWN	FINGERPRINT	45ef03c5256cbf45a6bcd296dc98e84e601b7233b8e1a8fac854c87b1e25d0db	{"punchAt": "2026-09-29T17:10:00.000Z", "enrollId": "105"}	2026-10-04 22:58:57.595+07
7d1764e3-47e2-4f4a-bf73-a09484bbdbed	0c685448-b52e-4e60-89ea-6f7c500a86d5	8ae41932-c8e7-4d34-9854-4f25e9488942	105	2026-09-30 16:00:00+07	UNKNOWN	FINGERPRINT	806f45d607963ce344df56917e64730b36d27c8317edaad5127934b87989dee2	{"punchAt": "2026-09-30T09:00:00.000Z", "enrollId": "105"}	2026-10-04 22:58:57.597+07
56f9f68b-6443-4d9b-afbf-ff8654a3ca52	0c685448-b52e-4e60-89ea-6f7c500a86d5	8ae41932-c8e7-4d34-9854-4f25e9488942	105	2026-10-01 00:15:00+07	UNKNOWN	FINGERPRINT	cf56a13c19f6e756be1cb11a7c2ae3565fc3f37a72c2f10b119ab22fe6ab913a	{"punchAt": "2026-09-30T17:15:00.000Z", "enrollId": "105"}	2026-10-04 22:58:57.598+07
c9fce9c4-fdec-4531-a440-5a7bb81b3f3f	b7291f79-3495-44a5-b039-737465dc2cc0	8ae41932-c8e7-4d34-9854-4f25e9488942	108	2026-09-01 08:00:00+07	UNKNOWN	FINGERPRINT	e483c8b71d8c7a4f44f3b373d233671926116d5665253f0b711a01f55515ada9	{"punchAt": "2026-09-01T01:00:00.000Z", "enrollId": "108"}	2026-10-04 22:58:57.6+07
df5382c7-c48b-4371-aac7-f922e9758e5d	b7291f79-3495-44a5-b039-737465dc2cc0	8ae41932-c8e7-4d34-9854-4f25e9488942	108	2026-09-01 19:30:00+07	UNKNOWN	FINGERPRINT	ec446d6857bbb370e2f5e8a708578ab0798b387393440a55790d2efa384605bf	{"punchAt": "2026-09-01T12:30:00.000Z", "enrollId": "108"}	2026-10-04 22:58:57.602+07
0700a71f-9066-4764-94dc-c4082b7371d2	b7291f79-3495-44a5-b039-737465dc2cc0	8ae41932-c8e7-4d34-9854-4f25e9488942	108	2026-09-02 08:00:00+07	UNKNOWN	FINGERPRINT	c894470691dbbb661827cdf9ed35dbb4c90adaa2acea1b8b09f0acf1796ada59	{"punchAt": "2026-09-02T01:00:00.000Z", "enrollId": "108"}	2026-10-04 22:58:57.603+07
12c6748d-c71b-46d6-86bc-77c14d974334	b7291f79-3495-44a5-b039-737465dc2cc0	8ae41932-c8e7-4d34-9854-4f25e9488942	108	2026-09-02 16:00:00+07	UNKNOWN	FINGERPRINT	e1f2ce1d725b8abf981b406c6d871eac708bbcbbb38979604a7f77a543f641ad	{"punchAt": "2026-09-02T09:00:00.000Z", "enrollId": "108"}	2026-10-04 22:58:57.605+07
7cb05de4-04a5-427a-ab36-a95125ec93b0	b7291f79-3495-44a5-b039-737465dc2cc0	8ae41932-c8e7-4d34-9854-4f25e9488942	108	2026-09-03 08:00:00+07	UNKNOWN	FINGERPRINT	fa8371d580efdbc81dd34f02154004538db4b972dbf39c69dd93f22d091fe4a8	{"punchAt": "2026-09-03T01:00:00.000Z", "enrollId": "108"}	2026-10-04 22:58:57.606+07
922c0108-a274-400b-a63b-1e1359c562fe	b7291f79-3495-44a5-b039-737465dc2cc0	8ae41932-c8e7-4d34-9854-4f25e9488942	108	2026-09-03 16:00:00+07	UNKNOWN	FINGERPRINT	2568d31911efda39eaaa2828ec0e714ff663dcdf39470ccdb887539a453df22b	{"punchAt": "2026-09-03T09:00:00.000Z", "enrollId": "108"}	2026-10-04 22:58:57.607+07
c95f3fec-4655-49e4-b05f-3ca1970b4a31	b7291f79-3495-44a5-b039-737465dc2cc0	8ae41932-c8e7-4d34-9854-4f25e9488942	108	2026-09-04 08:00:00+07	UNKNOWN	FINGERPRINT	4e604c6a34e06184cda09969384405aa708b08886dcc7c27a0d23374aedb5636	{"punchAt": "2026-09-04T01:00:00.000Z", "enrollId": "108"}	2026-10-04 22:58:57.608+07
21029d4c-82ea-4731-a428-f0830296be4a	b7291f79-3495-44a5-b039-737465dc2cc0	8ae41932-c8e7-4d34-9854-4f25e9488942	108	2026-09-04 16:00:00+07	UNKNOWN	FINGERPRINT	bb35c485ade5309fd2f13ecd9e1d2c71896aaf6e89023f1e7462ad49b06cc3df	{"punchAt": "2026-09-04T09:00:00.000Z", "enrollId": "108"}	2026-10-04 22:58:57.61+07
4b3c588f-07d1-40e3-b1fc-d4fc769cd975	b7291f79-3495-44a5-b039-737465dc2cc0	8ae41932-c8e7-4d34-9854-4f25e9488942	108	2026-09-06 10:00:00+07	UNKNOWN	FINGERPRINT	2d4c2c88b26570df058555d4634a301b5b2147064a88a4f12732cdfdc74db5ad	{"punchAt": "2026-09-06T03:00:00.000Z", "enrollId": "108"}	2026-10-04 22:58:57.611+07
9fe16699-3ccb-4bd2-8bcf-78940d108179	b7291f79-3495-44a5-b039-737465dc2cc0	8ae41932-c8e7-4d34-9854-4f25e9488942	108	2026-09-06 14:00:00+07	UNKNOWN	FINGERPRINT	b069a990ee5c09f14cc18b91aac399dafe5dc9bff685c803fb22e42d3f8a33fc	{"punchAt": "2026-09-06T07:00:00.000Z", "enrollId": "108"}	2026-10-04 22:58:57.612+07
57f7e141-3e59-4652-88a6-513fd3b38bf2	b7291f79-3495-44a5-b039-737465dc2cc0	8ae41932-c8e7-4d34-9854-4f25e9488942	108	2026-09-07 08:00:00+07	UNKNOWN	FINGERPRINT	de76193c1a8c073fbefda07cf551db5c1f6ef26f3c9de92c2fbdf78f84f73a14	{"punchAt": "2026-09-07T01:00:00.000Z", "enrollId": "108"}	2026-10-04 22:58:57.613+07
92fd36ff-09b1-4337-aed7-6e1a964fa78e	b7291f79-3495-44a5-b039-737465dc2cc0	8ae41932-c8e7-4d34-9854-4f25e9488942	108	2026-09-07 19:30:00+07	UNKNOWN	FINGERPRINT	9bd0c36157d52214c5d48e35abbecd4b2581bd8756417e452bf9f75086d25e3f	{"punchAt": "2026-09-07T12:30:00.000Z", "enrollId": "108"}	2026-10-04 22:58:57.614+07
f9ccc47f-c578-4965-b7fa-c2884a86e510	b7291f79-3495-44a5-b039-737465dc2cc0	8ae41932-c8e7-4d34-9854-4f25e9488942	108	2026-09-08 08:00:00+07	UNKNOWN	FINGERPRINT	c3f6c0bca4cd8bb05400a2abb91f2c2d76f65fc21b766cecaeb3d266cc8e9962	{"punchAt": "2026-09-08T01:00:00.000Z", "enrollId": "108"}	2026-10-04 22:58:57.616+07
d7a7e9b8-11f4-4b04-8eab-5dde3c8c15fc	b7291f79-3495-44a5-b039-737465dc2cc0	8ae41932-c8e7-4d34-9854-4f25e9488942	108	2026-09-08 16:00:00+07	UNKNOWN	FINGERPRINT	8aed1dccd5ac3161f7d42ec9828b80efa7839e4676a0e685e1d5e429a0cd6cb2	{"punchAt": "2026-09-08T09:00:00.000Z", "enrollId": "108"}	2026-10-04 22:58:57.618+07
47cbd118-e7e6-4073-b0cc-6dbac08257a3	b7291f79-3495-44a5-b039-737465dc2cc0	8ae41932-c8e7-4d34-9854-4f25e9488942	108	2026-09-09 08:00:00+07	UNKNOWN	FINGERPRINT	76c4375dc7b9e9c56e21d6da5009d81a5cc3fb5e97142da58a1bdec01e9dff7c	{"punchAt": "2026-09-09T01:00:00.000Z", "enrollId": "108"}	2026-10-04 22:58:57.619+07
000673de-5654-4612-9214-3b9067de84de	b7291f79-3495-44a5-b039-737465dc2cc0	8ae41932-c8e7-4d34-9854-4f25e9488942	108	2026-09-09 16:00:00+07	UNKNOWN	FINGERPRINT	58b1c846f4dabe989eac9a9e3a11fbcf7a146d1f4fc8bbf57baeb5bfadc190ff	{"punchAt": "2026-09-09T09:00:00.000Z", "enrollId": "108"}	2026-10-04 22:58:57.62+07
ba5ec725-3ff7-42c1-89d7-aaa6d1074f17	b7291f79-3495-44a5-b039-737465dc2cc0	8ae41932-c8e7-4d34-9854-4f25e9488942	108	2026-09-10 08:00:00+07	UNKNOWN	FINGERPRINT	f42e20d7c157a843c0e83086fe6e959f9a96f42dabbd37d83413df30cd5d42ca	{"punchAt": "2026-09-10T01:00:00.000Z", "enrollId": "108"}	2026-10-04 22:58:57.622+07
c9219bde-c982-4d6b-b537-1cbb3bc9d8d4	b7291f79-3495-44a5-b039-737465dc2cc0	8ae41932-c8e7-4d34-9854-4f25e9488942	108	2026-09-10 16:00:00+07	UNKNOWN	FINGERPRINT	f165efc79cdf498a2d912ef7d96e5444800dcbfd5abb1459f1e497975c294ab7	{"punchAt": "2026-09-10T09:00:00.000Z", "enrollId": "108"}	2026-10-04 22:58:57.623+07
a22f67b2-6db7-4dc0-a3aa-71487404b063	b7291f79-3495-44a5-b039-737465dc2cc0	8ae41932-c8e7-4d34-9854-4f25e9488942	108	2026-09-11 08:00:00+07	UNKNOWN	FINGERPRINT	c1b1cc0558d758e7534d72c41a871aa3a40c8b0cf6fc667a2abfca58384bdde9	{"punchAt": "2026-09-11T01:00:00.000Z", "enrollId": "108"}	2026-10-04 22:58:57.625+07
2062a6ab-0fe9-45f5-9b6c-e0712261bf17	b7291f79-3495-44a5-b039-737465dc2cc0	8ae41932-c8e7-4d34-9854-4f25e9488942	108	2026-09-11 19:30:00+07	UNKNOWN	FINGERPRINT	378787c8b0dc45c9a6e4f9b320b454b159145a66b52443b183e807b3512ea9d6	{"punchAt": "2026-09-11T12:30:00.000Z", "enrollId": "108"}	2026-10-04 22:58:57.626+07
754ae84d-fdbd-4095-a594-faaf0448075a	b7291f79-3495-44a5-b039-737465dc2cc0	8ae41932-c8e7-4d34-9854-4f25e9488942	108	2026-09-12 09:00:00+07	UNKNOWN	FINGERPRINT	445ee1e525d21b69899a94fa0f4ffd75f03d8fa0e5d012c40d96c2bee40e8a39	{"punchAt": "2026-09-12T02:00:00.000Z", "enrollId": "108"}	2026-10-04 22:58:57.627+07
d111690d-4f14-4f07-aeb0-3cdbd432c75d	b7291f79-3495-44a5-b039-737465dc2cc0	8ae41932-c8e7-4d34-9854-4f25e9488942	108	2026-09-12 13:00:00+07	UNKNOWN	FINGERPRINT	fff6b8d1eeace639fe6171a4173e72a5c95e810bfa4405485eb71b317eeec8b7	{"punchAt": "2026-09-12T06:00:00.000Z", "enrollId": "108"}	2026-10-04 22:58:57.628+07
a2953b6b-1adb-499c-943d-6ce6e4fd30ca	b7291f79-3495-44a5-b039-737465dc2cc0	8ae41932-c8e7-4d34-9854-4f25e9488942	108	2026-09-14 08:00:00+07	UNKNOWN	FINGERPRINT	169e3fc9ecf59968035fa54c88f4e3dbb63d509ae2df60a9e1fdd9f57dcafa12	{"punchAt": "2026-09-14T01:00:00.000Z", "enrollId": "108"}	2026-10-04 22:58:57.629+07
7285efd7-1338-4772-919b-88e1915b110f	b7291f79-3495-44a5-b039-737465dc2cc0	8ae41932-c8e7-4d34-9854-4f25e9488942	108	2026-09-14 16:00:00+07	UNKNOWN	FINGERPRINT	15935c0ed56f32db41830e6b6c3b177b994e80445ebebe9034f5e9021833cc8b	{"punchAt": "2026-09-14T09:00:00.000Z", "enrollId": "108"}	2026-10-04 22:58:57.631+07
4dfc143e-46cb-4eb9-b2f7-724567371fd2	b7291f79-3495-44a5-b039-737465dc2cc0	8ae41932-c8e7-4d34-9854-4f25e9488942	108	2026-09-15 08:00:00+07	UNKNOWN	FINGERPRINT	9e8d683ca10c7d31df9f7b4e936d7f355d8e6f5068c4a67ee1d5e3022b08a871	{"punchAt": "2026-09-15T01:00:00.000Z", "enrollId": "108"}	2026-10-04 22:58:57.632+07
c78d4a70-4ac3-421c-811f-1e17685468cd	b7291f79-3495-44a5-b039-737465dc2cc0	8ae41932-c8e7-4d34-9854-4f25e9488942	108	2026-09-15 16:00:00+07	UNKNOWN	FINGERPRINT	e071477c6868ea6583fe1f0e05b007ea560e3fd6db0f134fef66101b529879b0	{"punchAt": "2026-09-15T09:00:00.000Z", "enrollId": "108"}	2026-10-04 22:58:57.634+07
dea66232-6466-45d4-9b4d-a3a1608fa87a	b7291f79-3495-44a5-b039-737465dc2cc0	8ae41932-c8e7-4d34-9854-4f25e9488942	108	2026-09-17 08:00:00+07	UNKNOWN	FINGERPRINT	8796c86f5abd0622b0ab5d9a3ffb58efc1a6514dec52e3d8e444c550da67f4e0	{"punchAt": "2026-09-17T01:00:00.000Z", "enrollId": "108"}	2026-10-04 22:58:57.636+07
03321d49-0218-43e1-8a64-b3ad75240a9e	b7291f79-3495-44a5-b039-737465dc2cc0	8ae41932-c8e7-4d34-9854-4f25e9488942	108	2026-09-17 16:00:00+07	UNKNOWN	FINGERPRINT	0162ee08906cefc65623bad1fcc0c4bd71cbd1728d672657968b9fc251015f4f	{"punchAt": "2026-09-17T09:00:00.000Z", "enrollId": "108"}	2026-10-04 22:58:57.637+07
55ad2e89-c779-45db-8a2c-35acd60b1ac4	b7291f79-3495-44a5-b039-737465dc2cc0	8ae41932-c8e7-4d34-9854-4f25e9488942	108	2026-09-18 08:00:00+07	UNKNOWN	FINGERPRINT	56ce1d22e0c62e390a8f061e78873b760967f863d604c630d0a35c1cdeee42f5	{"punchAt": "2026-09-18T01:00:00.000Z", "enrollId": "108"}	2026-10-04 22:58:57.638+07
e8eb04ee-82f7-4542-9937-2a3d3abc9e28	b7291f79-3495-44a5-b039-737465dc2cc0	8ae41932-c8e7-4d34-9854-4f25e9488942	108	2026-09-18 19:30:00+07	UNKNOWN	FINGERPRINT	c0ce516674eac151d0854c9c14f637f80f5acb679454c997191d143be0e38faf	{"punchAt": "2026-09-18T12:30:00.000Z", "enrollId": "108"}	2026-10-04 22:58:57.64+07
32b37a7d-e6b9-4006-93a7-45f22f871e97	b7291f79-3495-44a5-b039-737465dc2cc0	8ae41932-c8e7-4d34-9854-4f25e9488942	108	2026-09-19 09:00:00+07	UNKNOWN	FINGERPRINT	93ead61c1e453a514351f9978203e2af705eaf15808d7320421ec689cb1c3bd1	{"punchAt": "2026-09-19T02:00:00.000Z", "enrollId": "108"}	2026-10-04 22:58:57.641+07
8db4b301-6464-4f55-be19-4f61e994afd4	b7291f79-3495-44a5-b039-737465dc2cc0	8ae41932-c8e7-4d34-9854-4f25e9488942	108	2026-09-19 13:00:00+07	UNKNOWN	FINGERPRINT	b216058ba210d584f5edcf747d45ef1c3fa248ebe341976213709b5d9cc399cd	{"punchAt": "2026-09-19T06:00:00.000Z", "enrollId": "108"}	2026-10-04 22:58:57.642+07
c4e76cfb-cc12-43d9-8b97-c9a1668db4e1	b7291f79-3495-44a5-b039-737465dc2cc0	8ae41932-c8e7-4d34-9854-4f25e9488942	108	2026-09-21 08:00:00+07	UNKNOWN	FINGERPRINT	9a74a20bccff5f320a9a749ac92120ffbfd59a8aa3942fca46f7fd126a76e85c	{"punchAt": "2026-09-21T01:00:00.000Z", "enrollId": "108"}	2026-10-04 22:58:57.644+07
74cf16df-dbc6-42c3-945f-5befb4e3490c	b7291f79-3495-44a5-b039-737465dc2cc0	8ae41932-c8e7-4d34-9854-4f25e9488942	108	2026-09-21 16:00:00+07	UNKNOWN	FINGERPRINT	062a78948a3de1350dd2106d5bc05e64612751e903f4985e0ee7e58835fbdde6	{"punchAt": "2026-09-21T09:00:00.000Z", "enrollId": "108"}	2026-10-04 22:58:57.645+07
8c7f0af2-9953-416a-ac29-b56735bb5e8b	b7291f79-3495-44a5-b039-737465dc2cc0	8ae41932-c8e7-4d34-9854-4f25e9488942	108	2026-09-22 08:00:00+07	UNKNOWN	FINGERPRINT	328dafc3e521f5ed86b8094ca3b8859c11d5cb8d34684fd7ba03b9f4c4cfc247	{"punchAt": "2026-09-22T01:00:00.000Z", "enrollId": "108"}	2026-10-04 22:58:57.646+07
0df28c17-b4e0-4b1a-bdb2-33af24423197	b7291f79-3495-44a5-b039-737465dc2cc0	8ae41932-c8e7-4d34-9854-4f25e9488942	108	2026-09-22 16:00:00+07	UNKNOWN	FINGERPRINT	1a1f3c735ac776c5fb134a8d60e9dc87c8f67f676eeb83650034a01f2f9699c3	{"punchAt": "2026-09-22T09:00:00.000Z", "enrollId": "108"}	2026-10-04 22:58:57.647+07
775568f4-665f-428c-8265-eb992235300b	b7291f79-3495-44a5-b039-737465dc2cc0	8ae41932-c8e7-4d34-9854-4f25e9488942	108	2026-09-23 08:00:00+07	UNKNOWN	FINGERPRINT	9e8c39508d91ef9f28a7d6d153ec7d380000768d72899c7357717d5aec93653f	{"punchAt": "2026-09-23T01:00:00.000Z", "enrollId": "108"}	2026-10-04 22:58:57.649+07
9158c9a9-8613-4867-b945-c0845c9f7526	b7291f79-3495-44a5-b039-737465dc2cc0	8ae41932-c8e7-4d34-9854-4f25e9488942	108	2026-09-23 16:00:00+07	UNKNOWN	FINGERPRINT	d659021814182f3d6853c988c99c333fcc32a75fe9ad5ab0ad1c437146945979	{"punchAt": "2026-09-23T09:00:00.000Z", "enrollId": "108"}	2026-10-04 22:58:57.65+07
fbae514b-04a6-40c3-bcd3-c0084cbffb2c	b7291f79-3495-44a5-b039-737465dc2cc0	8ae41932-c8e7-4d34-9854-4f25e9488942	108	2026-09-24 08:00:00+07	UNKNOWN	FINGERPRINT	6922f9014997c0b6aecc3ff5120c0ff1502036f21d4995c5b9fef1a00bb9c38b	{"punchAt": "2026-09-24T01:00:00.000Z", "enrollId": "108"}	2026-10-04 22:58:57.652+07
22a6d7ba-633f-464a-af67-67e7e0e5bfb9	b7291f79-3495-44a5-b039-737465dc2cc0	8ae41932-c8e7-4d34-9854-4f25e9488942	108	2026-09-24 19:30:00+07	UNKNOWN	FINGERPRINT	83c5f1d3cac3047c4a9f0190f8792ecd08f28912eeb342680ddf77d5ff4a5dbf	{"punchAt": "2026-09-24T12:30:00.000Z", "enrollId": "108"}	2026-10-04 22:58:57.653+07
4bd58806-44d2-43c6-84d7-bae58202f1d2	b7291f79-3495-44a5-b039-737465dc2cc0	8ae41932-c8e7-4d34-9854-4f25e9488942	108	2026-09-25 08:00:00+07	UNKNOWN	FINGERPRINT	f59f5b86e3b96977498e2caaf6e3b9d9b5f7d51300353712aba8bb004c2350a9	{"punchAt": "2026-09-25T01:00:00.000Z", "enrollId": "108"}	2026-10-04 22:58:57.655+07
cdb84eb4-74d3-48ea-9bc4-be10ecb7b5f7	b7291f79-3495-44a5-b039-737465dc2cc0	8ae41932-c8e7-4d34-9854-4f25e9488942	108	2026-09-25 16:00:00+07	UNKNOWN	FINGERPRINT	7a9c10114552dd7c506c865504e384176e088e0a0d66f8d021896fa9ecdb6a9f	{"punchAt": "2026-09-25T09:00:00.000Z", "enrollId": "108"}	2026-10-04 22:58:57.656+07
8721aa88-3268-4c02-95ff-1dc6df3ad772	b7291f79-3495-44a5-b039-737465dc2cc0	8ae41932-c8e7-4d34-9854-4f25e9488942	108	2026-09-28 08:00:00+07	UNKNOWN	FINGERPRINT	c08b0649969b51a1679e546f30be4caa928b910bbac4e5b207e957b3a490dd0c	{"punchAt": "2026-09-28T01:00:00.000Z", "enrollId": "108"}	2026-10-04 22:58:57.657+07
380994c2-04b7-4abd-b5c5-4f04a6007893	b7291f79-3495-44a5-b039-737465dc2cc0	8ae41932-c8e7-4d34-9854-4f25e9488942	108	2026-09-28 16:00:00+07	UNKNOWN	FINGERPRINT	d77eef2f8bc4ed69fbf985cfd2929ec29fdd4df38debc6d195d11e200da0099c	{"punchAt": "2026-09-28T09:00:00.000Z", "enrollId": "108"}	2026-10-04 22:58:57.658+07
34846053-b12b-42eb-bf43-f431dcb519b0	b7291f79-3495-44a5-b039-737465dc2cc0	8ae41932-c8e7-4d34-9854-4f25e9488942	108	2026-09-29 08:00:00+07	UNKNOWN	FINGERPRINT	a086ef42f0b1a99da2f89f0847a998bcb0ea5ea6af5d3565f169e7c0ae2e1429	{"punchAt": "2026-09-29T01:00:00.000Z", "enrollId": "108"}	2026-10-04 22:58:57.659+07
5d8301d0-9884-4828-b0a7-717ce491ae29	b7291f79-3495-44a5-b039-737465dc2cc0	8ae41932-c8e7-4d34-9854-4f25e9488942	108	2026-09-29 16:00:00+07	UNKNOWN	FINGERPRINT	0a5149453121188e445c6ddc4e38c77e2a9ee8c37ac1ba036a0e15de21e0c005	{"punchAt": "2026-09-29T09:00:00.000Z", "enrollId": "108"}	2026-10-04 22:58:57.661+07
9ab6da9e-73b0-47cf-808b-f7c903d20c6b	b7291f79-3495-44a5-b039-737465dc2cc0	8ae41932-c8e7-4d34-9854-4f25e9488942	108	2026-09-30 08:00:00+07	UNKNOWN	FINGERPRINT	8eb41bacecf6ac202a227d054cdfdf7abf9df3b82282c2ef11730c0b14a38e72	{"punchAt": "2026-09-30T01:00:00.000Z", "enrollId": "108"}	2026-10-04 22:58:57.662+07
5cd54e58-ece1-4a1e-91bc-5c60efe3d2df	b7291f79-3495-44a5-b039-737465dc2cc0	8ae41932-c8e7-4d34-9854-4f25e9488942	108	2026-09-30 19:30:00+07	UNKNOWN	FINGERPRINT	30838213f5fbc61b63e3048b3e5199a49853ed16ab8ea4e37997f350d77ae704	{"punchAt": "2026-09-30T12:30:00.000Z", "enrollId": "108"}	2026-10-04 22:58:57.663+07
c4602e91-8562-4154-9d34-b067110578de	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	8ae41932-c8e7-4d34-9854-4f25e9488942	110	2026-09-01 07:55:00+07	UNKNOWN	FINGERPRINT	981bf376d896fe705e2a3a7434ea5d29890b897e6a037e3d5fbbc5c95bbeef55	{"punchAt": "2026-09-01T00:55:00.000Z", "enrollId": "110"}	2026-10-04 22:58:57.665+07
f7e6abcb-3c69-4d27-8c79-00eb16a93733	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	8ae41932-c8e7-4d34-9854-4f25e9488942	110	2026-09-01 16:00:00+07	UNKNOWN	FINGERPRINT	49e6df8139ba92f060c3f64d84aa2e47966cfd9404b66abfe64134c1d96dbccd	{"punchAt": "2026-09-01T09:00:00.000Z", "enrollId": "110"}	2026-10-04 22:58:57.666+07
0db129e7-62b2-4e04-b6b7-5c7f32264581	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	8ae41932-c8e7-4d34-9854-4f25e9488942	110	2026-09-02 07:59:00+07	UNKNOWN	FINGERPRINT	e6bf264ae084a0bc38e87effc87a7f5bc22b7aa6c7a1ea4c1c488d37d9705ff2	{"punchAt": "2026-09-02T00:59:00.000Z", "enrollId": "110"}	2026-10-04 22:58:57.668+07
490589cd-9464-4400-bfd3-196217a457c1	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	8ae41932-c8e7-4d34-9854-4f25e9488942	110	2026-09-02 16:00:00+07	UNKNOWN	FINGERPRINT	166bd306e124a2172e0d996a5d12c744b34f96c234d3c471c5d72d9a2341a06a	{"punchAt": "2026-09-02T09:00:00.000Z", "enrollId": "110"}	2026-10-04 22:58:57.669+07
39757576-c5ce-40a4-bf29-cee6d31357bc	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	8ae41932-c8e7-4d34-9854-4f25e9488942	110	2026-09-03 08:03:00+07	UNKNOWN	FINGERPRINT	35068bd73d50e55d72277f1a6b83511f041d2577b01c5170dda91840634e599b	{"punchAt": "2026-09-03T01:03:00.000Z", "enrollId": "110"}	2026-10-04 22:58:57.67+07
cb4f9d23-79ba-46cb-ab2b-594b05f0a0e9	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	8ae41932-c8e7-4d34-9854-4f25e9488942	110	2026-09-03 16:00:00+07	UNKNOWN	FINGERPRINT	5ac372fe712625bb8cf609e53695a79666154232a08b5f0fb651228164896295	{"punchAt": "2026-09-03T09:00:00.000Z", "enrollId": "110"}	2026-10-04 22:58:57.672+07
5daa54c9-b7d6-4e98-9c5a-262318e33a22	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	8ae41932-c8e7-4d34-9854-4f25e9488942	110	2026-09-04 07:55:00+07	UNKNOWN	FINGERPRINT	71e8070d647947da07d5dd679474c54d8186603d1bd638bb6fead96f75599cec	{"punchAt": "2026-09-04T00:55:00.000Z", "enrollId": "110"}	2026-10-04 22:58:57.673+07
639da52c-056a-4738-a866-cf4d2d89ecb6	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	8ae41932-c8e7-4d34-9854-4f25e9488942	110	2026-09-04 16:00:00+07	UNKNOWN	FINGERPRINT	ac8667c94cc5f86578cf2d26afe795df2de6d42272c00b2b8bfc527466cf93ce	{"punchAt": "2026-09-04T09:00:00.000Z", "enrollId": "110"}	2026-10-04 22:58:57.674+07
282e4f3a-59b0-437b-b4f4-1319538d49b9	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	8ae41932-c8e7-4d34-9854-4f25e9488942	110	2026-09-07 07:59:00+07	UNKNOWN	FINGERPRINT	0fc31647bcadeaa117607a31bf2a712d2405b3c7041722ecf7243842d7b2b517	{"punchAt": "2026-09-07T00:59:00.000Z", "enrollId": "110"}	2026-10-04 22:58:57.675+07
6d46735b-aa0d-4b87-8d83-34f64310a959	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	8ae41932-c8e7-4d34-9854-4f25e9488942	110	2026-09-07 16:00:00+07	UNKNOWN	FINGERPRINT	c9ca1646e3c216081b09a49c807176a25693fbcbe06bb8df0840d123c9bcbbf6	{"punchAt": "2026-09-07T09:00:00.000Z", "enrollId": "110"}	2026-10-04 22:58:57.677+07
11e8188d-7bfd-499c-9e83-979de305acea	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	8ae41932-c8e7-4d34-9854-4f25e9488942	110	2026-09-08 08:03:00+07	UNKNOWN	FINGERPRINT	d1e1664cec455a5c71291407b3726f50d1593437cdfda5c6c503810cd3c27d94	{"punchAt": "2026-09-08T01:03:00.000Z", "enrollId": "110"}	2026-10-04 22:58:57.678+07
086f545c-fc07-4c09-8dde-09a422988204	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	8ae41932-c8e7-4d34-9854-4f25e9488942	110	2026-09-08 16:00:00+07	UNKNOWN	FINGERPRINT	793d99203a0aeb76e99b712d7616b459ffeca82e3486c6d705533321d9d3dd37	{"punchAt": "2026-09-08T09:00:00.000Z", "enrollId": "110"}	2026-10-04 22:58:57.679+07
94caa112-382d-487e-80ae-c18ac868ddf8	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	8ae41932-c8e7-4d34-9854-4f25e9488942	110	2026-09-09 07:55:00+07	UNKNOWN	FINGERPRINT	74f75518d0dc44f0d3cf022a0bbbfed1092d67396c567278d120a84d8ea6add8	{"punchAt": "2026-09-09T00:55:00.000Z", "enrollId": "110"}	2026-10-04 22:58:57.68+07
aa867d7e-b7ae-4e23-ad3d-a04e684dfded	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	8ae41932-c8e7-4d34-9854-4f25e9488942	110	2026-09-09 16:00:00+07	UNKNOWN	FINGERPRINT	b4c49d9aa20e283317e1d2530325bc45eabd2290e448c3f667df70a2d04b07d3	{"punchAt": "2026-09-09T09:00:00.000Z", "enrollId": "110"}	2026-10-04 22:58:57.681+07
a540a367-c255-417b-8780-061f5033c265	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	8ae41932-c8e7-4d34-9854-4f25e9488942	110	2026-09-10 07:59:00+07	UNKNOWN	FINGERPRINT	492a8253fad2b6cf05d466f683cb1e14f69fa5f401aab70678db449e6ebcda5c	{"punchAt": "2026-09-10T00:59:00.000Z", "enrollId": "110"}	2026-10-04 22:58:57.682+07
47022f00-2792-4243-b365-065757f46dde	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	8ae41932-c8e7-4d34-9854-4f25e9488942	110	2026-09-10 16:00:00+07	UNKNOWN	FINGERPRINT	28e93d2c683f33b3ef278979455f00b594926f89da36524729bc195a2decc5e3	{"punchAt": "2026-09-10T09:00:00.000Z", "enrollId": "110"}	2026-10-04 22:58:57.684+07
34a78bfb-a6a4-4d24-a306-6f0063e21857	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	8ae41932-c8e7-4d34-9854-4f25e9488942	110	2026-09-11 08:03:00+07	UNKNOWN	FINGERPRINT	ad71afde8b3a0b6d46ee7a80694c9af404b6ac787e0f1071fa3a73064c85ed47	{"punchAt": "2026-09-11T01:03:00.000Z", "enrollId": "110"}	2026-10-04 22:58:57.686+07
f0a6cdb2-0a7c-445e-82c6-07eb8e12436c	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	8ae41932-c8e7-4d34-9854-4f25e9488942	110	2026-09-11 16:00:00+07	UNKNOWN	FINGERPRINT	bbc7fa42229c8ea9850a5e647271238085b268a53038fd6adac628c78f560568	{"punchAt": "2026-09-11T09:00:00.000Z", "enrollId": "110"}	2026-10-04 22:58:57.687+07
abdc3b00-d4c1-4b7c-a26f-e2364dce088c	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	8ae41932-c8e7-4d34-9854-4f25e9488942	110	2026-09-14 07:55:00+07	UNKNOWN	FINGERPRINT	6dada02450858f743b4bbed028f133ffc38100d5af76c724a76e76c360bb218b	{"punchAt": "2026-09-14T00:55:00.000Z", "enrollId": "110"}	2026-10-04 22:58:57.689+07
6d4eb7c9-baed-4241-affa-240ed8c97683	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	8ae41932-c8e7-4d34-9854-4f25e9488942	110	2026-09-14 16:00:00+07	UNKNOWN	FINGERPRINT	606f371d3b997120f7c32161eb098616389c8a1435f3e4e27d71b919491fd8af	{"punchAt": "2026-09-14T09:00:00.000Z", "enrollId": "110"}	2026-10-04 22:58:57.69+07
38c9e6d8-ece7-4e95-bfe7-8e24a73236cd	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	8ae41932-c8e7-4d34-9854-4f25e9488942	110	2026-09-15 07:59:00+07	UNKNOWN	FINGERPRINT	539e1737eda7d0ac9c16dfb1ed9c59991984d67854f0e357e7cc97fe108727cd	{"punchAt": "2026-09-15T00:59:00.000Z", "enrollId": "110"}	2026-10-04 22:58:57.691+07
67746e4b-1467-49d8-a508-2f02cea92fb5	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	8ae41932-c8e7-4d34-9854-4f25e9488942	110	2026-09-15 16:00:00+07	UNKNOWN	FINGERPRINT	e5329cc365f96bc40fa26eb00abfb41eb61aa5c8b7835769499eb4d99cf1e992	{"punchAt": "2026-09-15T09:00:00.000Z", "enrollId": "110"}	2026-10-04 22:58:57.692+07
9862d7d3-d54b-4bb5-a73a-dee3c0baf066	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	8ae41932-c8e7-4d34-9854-4f25e9488942	110	2026-09-17 08:03:00+07	UNKNOWN	FINGERPRINT	323d9df1c545cdfdc61af8ded0eb39df555f117b42c23559125f3fb0d1211289	{"punchAt": "2026-09-17T01:03:00.000Z", "enrollId": "110"}	2026-10-04 22:58:57.694+07
bf5bf0a9-62bc-4dfc-8011-eb472702cb6c	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	8ae41932-c8e7-4d34-9854-4f25e9488942	110	2026-09-17 16:00:00+07	UNKNOWN	FINGERPRINT	a388394e76270d2d57fb76bfdf94999e6c4311e2ff1968cab11db790b76402a3	{"punchAt": "2026-09-17T09:00:00.000Z", "enrollId": "110"}	2026-10-04 22:58:57.695+07
bc1932fe-78e7-496a-a07d-3b051b89edc3	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	8ae41932-c8e7-4d34-9854-4f25e9488942	110	2026-09-18 07:55:00+07	UNKNOWN	FINGERPRINT	d5335b29fa095457f359b526b33de0f140aac00e589886a2c2eac8fcfbecfa08	{"punchAt": "2026-09-18T00:55:00.000Z", "enrollId": "110"}	2026-10-04 22:58:57.697+07
961cad9d-9dcc-4586-9bfc-b008e12eb7ef	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	8ae41932-c8e7-4d34-9854-4f25e9488942	110	2026-09-18 16:00:00+07	UNKNOWN	FINGERPRINT	2004412e62d6ebbc1341e4ea64ec924e398c99eaffbc139a3a5e62f2cfda1291	{"punchAt": "2026-09-18T09:00:00.000Z", "enrollId": "110"}	2026-10-04 22:58:57.698+07
ab211968-666b-43af-8477-02eb55b6db54	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	8ae41932-c8e7-4d34-9854-4f25e9488942	110	2026-09-21 07:59:00+07	UNKNOWN	FINGERPRINT	00a693f102e794c7748cd8ba9384c64a321206c2b9e7e7b1149c3cd6261487bd	{"punchAt": "2026-09-21T00:59:00.000Z", "enrollId": "110"}	2026-10-04 22:58:57.701+07
b220f76e-b0f5-4d2b-9c03-1c6b4b7a5e76	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	8ae41932-c8e7-4d34-9854-4f25e9488942	110	2026-09-21 16:00:00+07	UNKNOWN	FINGERPRINT	93fcaca41c42e1a42479647087a194dd6bc4903bdc9941a0964511a2dca02d13	{"punchAt": "2026-09-21T09:00:00.000Z", "enrollId": "110"}	2026-10-04 22:58:57.703+07
97b092a3-af00-4e7b-87d2-6ca9144df6dd	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	8ae41932-c8e7-4d34-9854-4f25e9488942	110	2026-09-22 08:03:00+07	UNKNOWN	FINGERPRINT	227bb18148376ad20dce8d3ab60485056fe78c1f61e954d38de3cf83124475cd	{"punchAt": "2026-09-22T01:03:00.000Z", "enrollId": "110"}	2026-10-04 22:58:57.704+07
a7854247-7f16-401d-8999-197d477efe99	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	8ae41932-c8e7-4d34-9854-4f25e9488942	110	2026-09-22 16:00:00+07	UNKNOWN	FINGERPRINT	2dd4971a4ff108201c797c4cc2e503876bd0c5b739db89d9701970a8898fe613	{"punchAt": "2026-09-22T09:00:00.000Z", "enrollId": "110"}	2026-10-04 22:58:57.706+07
24e00768-8451-49d0-bb13-be35af53f0e9	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	8ae41932-c8e7-4d34-9854-4f25e9488942	110	2026-09-23 07:55:00+07	UNKNOWN	FINGERPRINT	5b374a0bd982d0cd08d66b3e6e0ce622e29f8220070ba20d680d4887d93e44a4	{"punchAt": "2026-09-23T00:55:00.000Z", "enrollId": "110"}	2026-10-04 22:58:57.707+07
b0af030e-d506-42a6-a71b-5e58c3788ff0	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	8ae41932-c8e7-4d34-9854-4f25e9488942	110	2026-09-23 16:00:00+07	UNKNOWN	FINGERPRINT	7a52b99a8b0ee97923643e2b1a0299cd51268e6cbb85f359785d71587c1527ad	{"punchAt": "2026-09-23T09:00:00.000Z", "enrollId": "110"}	2026-10-04 22:58:57.708+07
b8bc9c1f-444a-416e-a590-c23f46a0f74c	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	8ae41932-c8e7-4d34-9854-4f25e9488942	110	2026-09-24 07:59:00+07	UNKNOWN	FINGERPRINT	824f6a24dcf012f9316a76ed7b13b5d85277aee673e9ae6e69350870b25a3b09	{"punchAt": "2026-09-24T00:59:00.000Z", "enrollId": "110"}	2026-10-04 22:58:57.71+07
50c2267f-f705-4693-8629-f8076af36225	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	8ae41932-c8e7-4d34-9854-4f25e9488942	110	2026-09-24 16:00:00+07	UNKNOWN	FINGERPRINT	9d563783cdefc60ab22f922251f56e6689c16876f469a12840e6460dde25cc8f	{"punchAt": "2026-09-24T09:00:00.000Z", "enrollId": "110"}	2026-10-04 22:58:57.711+07
11e154f1-b2e3-4dff-b9f4-92cd643656b1	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	8ae41932-c8e7-4d34-9854-4f25e9488942	110	2026-09-25 08:03:00+07	UNKNOWN	FINGERPRINT	b923514c05bb1c0e9c41e979b086676855f6a2c42c60b6f1d67e0a4601189636	{"punchAt": "2026-09-25T01:03:00.000Z", "enrollId": "110"}	2026-10-04 22:58:57.713+07
e7904140-c997-4c14-99dd-b6d03d8f2573	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	8ae41932-c8e7-4d34-9854-4f25e9488942	110	2026-09-25 16:00:00+07	UNKNOWN	FINGERPRINT	34e144cde36dd5d79c8a86a8df76b9bde08bf3c531bf999e33503a4d3f117428	{"punchAt": "2026-09-25T09:00:00.000Z", "enrollId": "110"}	2026-10-04 22:58:57.715+07
204edcb7-8f8c-4be7-9688-343ba9094eb6	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	8ae41932-c8e7-4d34-9854-4f25e9488942	110	2026-09-28 07:55:00+07	UNKNOWN	FINGERPRINT	a03e841f091e0d49d66248531e54003308887f9bc30db8d14796052a339806d9	{"punchAt": "2026-09-28T00:55:00.000Z", "enrollId": "110"}	2026-10-04 22:58:57.716+07
5f0a13fa-9576-4cdb-8383-e243bc2adbdf	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	8ae41932-c8e7-4d34-9854-4f25e9488942	110	2026-09-28 16:00:00+07	UNKNOWN	FINGERPRINT	2522b750a4b22ab8199c4d56b23f510adc87d0f503b030f0d3475480654022fe	{"punchAt": "2026-09-28T09:00:00.000Z", "enrollId": "110"}	2026-10-04 22:58:57.718+07
d5d8b79b-b114-4955-be42-30ee1a84a28a	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	8ae41932-c8e7-4d34-9854-4f25e9488942	110	2026-09-29 07:59:00+07	UNKNOWN	FINGERPRINT	b975efee75fc687b47c5e1fc39022ddf18624ff73f42c27ac35939fe89341821	{"punchAt": "2026-09-29T00:59:00.000Z", "enrollId": "110"}	2026-10-04 22:58:57.72+07
7ab72382-cb54-4994-a7a4-b1e2998df575	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	8ae41932-c8e7-4d34-9854-4f25e9488942	110	2026-09-29 16:00:00+07	UNKNOWN	FINGERPRINT	9ac00d313aff4fee6f4271851faac7131db75a1211bd4269036f80c135b9200d	{"punchAt": "2026-09-29T09:00:00.000Z", "enrollId": "110"}	2026-10-04 22:58:57.722+07
d5655c51-2b78-4198-a046-241aeea7170c	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	8ae41932-c8e7-4d34-9854-4f25e9488942	110	2026-09-30 08:03:00+07	UNKNOWN	FINGERPRINT	36994916a62558b56dfa3fc14f61899d5e41ead5e4036a4472af6eb0fe74bafd	{"punchAt": "2026-09-30T01:03:00.000Z", "enrollId": "110"}	2026-10-04 22:58:57.724+07
e40ef38f-8f26-4ab1-b0c2-b40b2261be78	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	8ae41932-c8e7-4d34-9854-4f25e9488942	110	2026-09-30 16:00:00+07	UNKNOWN	FINGERPRINT	f8874fb1a592b3d3ed8a566556a64ab3fc4c46a6dd1f984283da3a44d8155565	{"punchAt": "2026-09-30T09:00:00.000Z", "enrollId": "110"}	2026-10-04 22:58:57.725+07
f7d3f2e3-fa05-4e9b-8800-727f825bfa46	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	59a0c680-ed08-46ba-b1f2-9cabea164b84	106	2026-09-01 06:58:00+07	UNKNOWN	FINGERPRINT	f398c6df02d28d354844d60b5506b95179f60b0d16807c825f0fa06e4053589a	{"punchAt": "2026-08-31T23:58:00.000Z", "enrollId": "106"}	2026-10-04 22:58:58.806+07
aeec2949-0c89-4aa1-853b-c2c9784fcd46	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	59a0c680-ed08-46ba-b1f2-9cabea164b84	106	2026-09-01 15:02:00+07	UNKNOWN	FINGERPRINT	20a5d579bff9a041abf3d1dcf77c19746458172277e585a1d316bb8f5c3737d9	{"punchAt": "2026-09-01T08:02:00.000Z", "enrollId": "106"}	2026-10-04 22:58:58.819+07
a1ebfdae-cc23-4312-bc32-6b69bacc30a7	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	59a0c680-ed08-46ba-b1f2-9cabea164b84	106	2026-09-02 06:58:00+07	UNKNOWN	FINGERPRINT	a9ee42d8c7e9a2f393eaca7849609c8e05ccff6e1b47980d3c163da7f63f4034	{"punchAt": "2026-09-01T23:58:00.000Z", "enrollId": "106"}	2026-10-04 22:58:58.821+07
cf92d996-de1a-40e3-9814-8f7a077e4c88	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	59a0c680-ed08-46ba-b1f2-9cabea164b84	106	2026-09-02 15:02:00+07	UNKNOWN	FINGERPRINT	45a8cd17782f1b27c923ad2ff148189f8387f4cb145a0c002afc1ce74718d3d9	{"punchAt": "2026-09-02T08:02:00.000Z", "enrollId": "106"}	2026-10-04 22:58:58.823+07
4d8292ef-2eb3-4bea-ae0f-8cc7148ae173	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	59a0c680-ed08-46ba-b1f2-9cabea164b84	106	2026-09-03 06:58:00+07	UNKNOWN	FINGERPRINT	2de09026c90ddc5af16fe1d232e6123498bede1e174fce44837c52dce6dacbb2	{"punchAt": "2026-09-02T23:58:00.000Z", "enrollId": "106"}	2026-10-04 22:58:58.826+07
bf40a4d5-f2b9-43e3-b4ba-be169abfdef5	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	59a0c680-ed08-46ba-b1f2-9cabea164b84	106	2026-09-03 15:02:00+07	UNKNOWN	FINGERPRINT	94d70b43f087bc8a0368831c679afecc6bb15f35e2022da72ee8c6d26f0a724d	{"punchAt": "2026-09-03T08:02:00.000Z", "enrollId": "106"}	2026-10-04 22:58:58.828+07
b932fa85-2c45-4411-8500-c82989d956d4	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	59a0c680-ed08-46ba-b1f2-9cabea164b84	106	2026-09-04 06:58:00+07	UNKNOWN	FINGERPRINT	7bcd12af630b9f2f8e0f603f504989d515fbf374c10b0b62d347d146cb17a35e	{"punchAt": "2026-09-03T23:58:00.000Z", "enrollId": "106"}	2026-10-04 22:58:58.831+07
51e65c59-79e0-41ab-812e-6d146148d8b9	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	59a0c680-ed08-46ba-b1f2-9cabea164b84	106	2026-09-04 15:02:00+07	UNKNOWN	FINGERPRINT	ba19cbc9f5a0cfe328492a911046dc8924a80f3dc5d3ded41a413fff29d09179	{"punchAt": "2026-09-04T08:02:00.000Z", "enrollId": "106"}	2026-10-04 22:58:58.833+07
8865d494-80cf-4fb5-aeb3-a5a710e68706	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	59a0c680-ed08-46ba-b1f2-9cabea164b84	106	2026-09-07 06:58:00+07	UNKNOWN	FINGERPRINT	e71c7849cce3afa8bd1a43df82a1a3b6ed996406eb515d5dfe25f22bff7235c3	{"punchAt": "2026-09-06T23:58:00.000Z", "enrollId": "106"}	2026-10-04 22:58:58.835+07
8fccb23f-fad0-4765-98a5-101082e1e329	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	59a0c680-ed08-46ba-b1f2-9cabea164b84	106	2026-09-07 15:02:00+07	UNKNOWN	FINGERPRINT	cd5b9db1b1078e96bd78c4d29ab5b5fee89ea84965397b75014fffec4a61930e	{"punchAt": "2026-09-07T08:02:00.000Z", "enrollId": "106"}	2026-10-04 22:58:58.837+07
1b61c9bb-ea4a-4ac8-90ab-e10bc5471158	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	59a0c680-ed08-46ba-b1f2-9cabea164b84	106	2026-09-08 06:58:00+07	UNKNOWN	FINGERPRINT	d5741549ce2a55118bd646055775574a5c85f67727356937bfce8d58a80963fa	{"punchAt": "2026-09-07T23:58:00.000Z", "enrollId": "106"}	2026-10-04 22:58:58.84+07
e0a6930f-d6fc-4785-8c66-32f01e63bdce	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	59a0c680-ed08-46ba-b1f2-9cabea164b84	106	2026-09-08 15:02:00+07	UNKNOWN	FINGERPRINT	330acbcc9c4672bf72965a7ff5384275208a78896fa7bc9208ebed2010c488e8	{"punchAt": "2026-09-08T08:02:00.000Z", "enrollId": "106"}	2026-10-04 22:58:58.841+07
966477db-a09b-4473-aa6c-cb76a436dead	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	59a0c680-ed08-46ba-b1f2-9cabea164b84	106	2026-09-09 06:58:00+07	UNKNOWN	FINGERPRINT	8fa05368e907995dc9a51365dcc66c95e89df6d03c77486cf52baff2231282df	{"punchAt": "2026-09-08T23:58:00.000Z", "enrollId": "106"}	2026-10-04 22:58:58.843+07
4d05bc31-3903-4ce1-b874-c9511d901dc9	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	59a0c680-ed08-46ba-b1f2-9cabea164b84	106	2026-09-09 15:02:00+07	UNKNOWN	FINGERPRINT	957fbe3b3568dc32f51907cfa143b930a991f2c8cde6a51aa05e83e44ae9d8db	{"punchAt": "2026-09-09T08:02:00.000Z", "enrollId": "106"}	2026-10-04 22:58:58.844+07
99d29340-f7cd-481c-832e-e944e7338b54	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	59a0c680-ed08-46ba-b1f2-9cabea164b84	106	2026-09-10 06:58:00+07	UNKNOWN	FINGERPRINT	2e33c9e16753bf8f64287f26f5f4975328344aebbfa9211755470bdd416c4c71	{"punchAt": "2026-09-09T23:58:00.000Z", "enrollId": "106"}	2026-10-04 22:58:58.846+07
e80ed7d6-fad7-47b8-8d4e-fcf7407258f2	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	59a0c680-ed08-46ba-b1f2-9cabea164b84	106	2026-09-10 15:02:00+07	UNKNOWN	FINGERPRINT	7584074149317ead843039a7d9467d04fb75f7c70cfb66b1da2cf60089ba76ae	{"punchAt": "2026-09-10T08:02:00.000Z", "enrollId": "106"}	2026-10-04 22:58:58.847+07
4d41fc82-587d-488a-9792-f9b17844470c	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	59a0c680-ed08-46ba-b1f2-9cabea164b84	106	2026-09-11 06:58:00+07	UNKNOWN	FINGERPRINT	8b8eae398495adf20969a6a54c40b53aa75596c058a77519b38d52b838075150	{"punchAt": "2026-09-10T23:58:00.000Z", "enrollId": "106"}	2026-10-04 22:58:58.849+07
1f1a7ce6-cd23-46ed-8d97-fc1d17cb120a	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	59a0c680-ed08-46ba-b1f2-9cabea164b84	106	2026-09-11 15:02:00+07	UNKNOWN	FINGERPRINT	c4585d301df25a73a98e9a5bc33ba6ec224026ba869170c724a1210eed5256b7	{"punchAt": "2026-09-11T08:02:00.000Z", "enrollId": "106"}	2026-10-04 22:58:58.853+07
650b4163-3211-4f1e-8c59-0d637ca4075d	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	59a0c680-ed08-46ba-b1f2-9cabea164b84	106	2026-09-14 06:58:00+07	UNKNOWN	FINGERPRINT	5dafd5f62b10175486b968687a250559904865cc74caab88235b988616cb3f3f	{"punchAt": "2026-09-13T23:58:00.000Z", "enrollId": "106"}	2026-10-04 22:58:58.855+07
af362633-96b3-444a-bbdf-d0a819b3fffa	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	59a0c680-ed08-46ba-b1f2-9cabea164b84	106	2026-09-14 15:02:00+07	UNKNOWN	FINGERPRINT	0faf41ae2c75827d0d7cbbb8316ead036e09eb278bf746e9ef4df6971d554c5f	{"punchAt": "2026-09-14T08:02:00.000Z", "enrollId": "106"}	2026-10-04 22:58:58.858+07
6ea6192b-1cb4-4ff0-b186-ae1ee611c8f8	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	59a0c680-ed08-46ba-b1f2-9cabea164b84	106	2026-09-15 06:58:00+07	UNKNOWN	FINGERPRINT	28ab1dff19d3fb989a7e2055531d97491dbee5472e9c81f39164b2eac80a3043	{"punchAt": "2026-09-14T23:58:00.000Z", "enrollId": "106"}	2026-10-04 22:58:58.86+07
24df5cfd-416e-4a57-b7e9-96b3ca4256ab	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	59a0c680-ed08-46ba-b1f2-9cabea164b84	106	2026-09-15 15:02:00+07	UNKNOWN	FINGERPRINT	dfb1d22c11455f73bc38e24973be8eb0d7680efb1a1c482394afa902063d628c	{"punchAt": "2026-09-15T08:02:00.000Z", "enrollId": "106"}	2026-10-04 22:58:58.865+07
487226c2-b62d-4f66-8197-8bf119db0d8c	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	59a0c680-ed08-46ba-b1f2-9cabea164b84	106	2026-09-17 06:58:00+07	UNKNOWN	FINGERPRINT	ffe79b8531e1991a18948b752e950d50b2d83b0d004e2f3ef1ac966fc81dd170	{"punchAt": "2026-09-16T23:58:00.000Z", "enrollId": "106"}	2026-10-04 22:58:58.87+07
c557690e-d477-4927-841d-2d8bd3ef3c51	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	59a0c680-ed08-46ba-b1f2-9cabea164b84	106	2026-09-17 15:02:00+07	UNKNOWN	FINGERPRINT	efdb7c72d4ab8ca02c0db29a02d73c1cf5d120b7fd36f9911e3d257e1f99a8ac	{"punchAt": "2026-09-17T08:02:00.000Z", "enrollId": "106"}	2026-10-04 22:58:58.871+07
0ac65560-471f-43ba-b155-601af40e4cda	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	59a0c680-ed08-46ba-b1f2-9cabea164b84	106	2026-09-18 06:58:00+07	UNKNOWN	FINGERPRINT	c433ae0ba9a4363332b88a37d3ec25a21a66bb05ef510c68da66510bd8d7a094	{"punchAt": "2026-09-17T23:58:00.000Z", "enrollId": "106"}	2026-10-04 22:58:58.873+07
7f1f766b-8f15-480f-a6d7-93d5a2ff4e32	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	59a0c680-ed08-46ba-b1f2-9cabea164b84	106	2026-09-18 15:02:00+07	UNKNOWN	FINGERPRINT	896385210a115da26cc7a51fd511b4f3451b2c62dd5e587585d671190132f7d2	{"punchAt": "2026-09-18T08:02:00.000Z", "enrollId": "106"}	2026-10-04 22:58:58.875+07
da12899a-fcb4-4d2f-b48a-e56f379ef8a6	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	59a0c680-ed08-46ba-b1f2-9cabea164b84	106	2026-09-21 06:58:00+07	UNKNOWN	FINGERPRINT	6be2a2ebed83ba6ee32b8d7f56706074b5e406a947776e6df6cd17bfcffc6f03	{"punchAt": "2026-09-20T23:58:00.000Z", "enrollId": "106"}	2026-10-04 22:58:58.877+07
657244e5-a077-490c-a6be-6d5e89a9388f	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	59a0c680-ed08-46ba-b1f2-9cabea164b84	106	2026-09-21 15:02:00+07	UNKNOWN	FINGERPRINT	64c8ce7222a54180f3a75353a1b7c2c311357faa1af1e326a26836dab5336671	{"punchAt": "2026-09-21T08:02:00.000Z", "enrollId": "106"}	2026-10-04 22:58:58.878+07
33100643-37c9-413a-a7ff-77eb1eb8f9b9	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	59a0c680-ed08-46ba-b1f2-9cabea164b84	106	2026-09-23 06:58:00+07	UNKNOWN	FINGERPRINT	f4465fedbc4f152964c6c7feac18470fe7f2aebbf45a8c13005f4902c75dfad4	{"punchAt": "2026-09-22T23:58:00.000Z", "enrollId": "106"}	2026-10-04 22:58:58.88+07
42edfd06-41e5-4790-b519-62f3ae4b1840	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	59a0c680-ed08-46ba-b1f2-9cabea164b84	106	2026-09-23 15:02:00+07	UNKNOWN	FINGERPRINT	aa4938ea32c3d03432e8d9de2df416d7561a087ce566a9d28c6906b9c14f2b98	{"punchAt": "2026-09-23T08:02:00.000Z", "enrollId": "106"}	2026-10-04 22:58:58.881+07
00267f4f-9119-4aec-94ec-1b112a27ec3f	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	59a0c680-ed08-46ba-b1f2-9cabea164b84	106	2026-09-24 06:58:00+07	UNKNOWN	FINGERPRINT	fb331ba4a90bb13d4c56e7c7f8e62ebde7236e680caa218a43e9d9b29592c052	{"punchAt": "2026-09-23T23:58:00.000Z", "enrollId": "106"}	2026-10-04 22:58:58.884+07
ccf84167-b103-4a8f-ac6a-3495d3d01978	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	59a0c680-ed08-46ba-b1f2-9cabea164b84	106	2026-09-24 15:02:00+07	UNKNOWN	FINGERPRINT	111bc013afef505fdd9e47a616daece41e9aee636090d404b0d766579c381b58	{"punchAt": "2026-09-24T08:02:00.000Z", "enrollId": "106"}	2026-10-04 22:58:58.887+07
850975b8-8731-44b5-ac60-8bc9ea78e08e	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	59a0c680-ed08-46ba-b1f2-9cabea164b84	106	2026-09-25 06:58:00+07	UNKNOWN	FINGERPRINT	d72d0363cb33095969284b82d30489a3c766d2fe4c5c9524f7d27d680891cc52	{"punchAt": "2026-09-24T23:58:00.000Z", "enrollId": "106"}	2026-10-04 22:58:58.888+07
547e42ac-e6aa-4562-b711-9e9359b91d53	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	59a0c680-ed08-46ba-b1f2-9cabea164b84	106	2026-09-25 15:02:00+07	UNKNOWN	FINGERPRINT	de2c8a146ea577a91a1535f595d920823aa8cc9e43760d49513d38643d0f2fea	{"punchAt": "2026-09-25T08:02:00.000Z", "enrollId": "106"}	2026-10-04 22:58:58.89+07
607180cb-e16a-4613-b787-eb6da524ad3f	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	59a0c680-ed08-46ba-b1f2-9cabea164b84	106	2026-09-28 06:58:00+07	UNKNOWN	FINGERPRINT	c905dc839e1e1e407b0313b4ea992f8827547adfcec5d86146812df186674d54	{"punchAt": "2026-09-27T23:58:00.000Z", "enrollId": "106"}	2026-10-04 22:58:58.892+07
dad209a3-f19f-44ab-996e-8446a963b1d2	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	59a0c680-ed08-46ba-b1f2-9cabea164b84	106	2026-09-28 15:02:00+07	UNKNOWN	FINGERPRINT	6d68bf45356955a4572be6fdc5f7c72e87ecf0a0ee0eb721c55d94ece1dd0d2c	{"punchAt": "2026-09-28T08:02:00.000Z", "enrollId": "106"}	2026-10-04 22:58:58.895+07
dcdb565b-7bab-471c-9204-7655e663b7c1	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	59a0c680-ed08-46ba-b1f2-9cabea164b84	106	2026-09-29 06:58:00+07	UNKNOWN	FINGERPRINT	d676c845a1f2d5fd0fac08ae8b2921391a6d854082ed91d6b5998b16e682ce7d	{"punchAt": "2026-09-28T23:58:00.000Z", "enrollId": "106"}	2026-10-04 22:58:58.898+07
0a2034f1-86c9-449e-947c-c57bf6323355	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	59a0c680-ed08-46ba-b1f2-9cabea164b84	106	2026-09-29 15:02:00+07	UNKNOWN	FINGERPRINT	c7bc108afb5f79736e4fee413d5a18006cf3a3007534a25432194ca567726979	{"punchAt": "2026-09-29T08:02:00.000Z", "enrollId": "106"}	2026-10-04 22:58:58.901+07
263a0e53-4478-4b38-a490-d9a5ead5afa0	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	59a0c680-ed08-46ba-b1f2-9cabea164b84	106	2026-09-30 06:58:00+07	UNKNOWN	FINGERPRINT	ea98fe66f4764d053d8faa31e5d4d452a3f7505db2e353ac3d19ad47438c9780	{"punchAt": "2026-09-29T23:58:00.000Z", "enrollId": "106"}	2026-10-04 22:58:58.903+07
ab69094c-24ea-4591-a42e-3eed0c508934	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	59a0c680-ed08-46ba-b1f2-9cabea164b84	106	2026-09-30 15:02:00+07	UNKNOWN	FINGERPRINT	914af7684e0937ff6ef28bc04c63633928ae556f199affb6f2ec55b79a3820e3	{"punchAt": "2026-09-30T08:02:00.000Z", "enrollId": "106"}	2026-10-04 22:58:58.904+07
19ecd700-c45c-4c48-85e3-6194f4bd8484	3193d9a5-6017-4441-b40c-f22e9ec9b867	59a0c680-ed08-46ba-b1f2-9cabea164b84	107	2026-09-01 20:55:00+07	UNKNOWN	FINGERPRINT	e8617fdd1a62a453108b42c5369558c9aec01bad90758f459ab25f3566e62321	{"punchAt": "2026-09-01T13:55:00.000Z", "enrollId": "107"}	2026-10-04 22:58:58.906+07
745d1a58-3561-4b44-982a-3732b7b97365	3193d9a5-6017-4441-b40c-f22e9ec9b867	59a0c680-ed08-46ba-b1f2-9cabea164b84	107	2026-09-02 05:05:00+07	UNKNOWN	FINGERPRINT	366be97e0be31a1cfc6abc3091b750d014cbb631966396154727eefc0c860070	{"punchAt": "2026-09-01T22:05:00.000Z", "enrollId": "107"}	2026-10-04 22:58:58.907+07
81608ede-3f5e-4c39-ad5f-6375f6c56eb7	3193d9a5-6017-4441-b40c-f22e9ec9b867	59a0c680-ed08-46ba-b1f2-9cabea164b84	107	2026-09-02 21:00:00+07	UNKNOWN	FINGERPRINT	b863d63388a10e9b4a287950eda9876721336f906af44314a344cfa114cb7675	{"punchAt": "2026-09-02T14:00:00.000Z", "enrollId": "107"}	2026-10-04 22:58:58.909+07
8cd4e044-9a8f-489f-a520-ab6d29567b3b	3193d9a5-6017-4441-b40c-f22e9ec9b867	59a0c680-ed08-46ba-b1f2-9cabea164b84	107	2026-09-03 05:05:00+07	UNKNOWN	FINGERPRINT	b771a32601891d8a8abb773a6e6dea8bfb86b68a6c86c892eda4e0c6f65cebd9	{"punchAt": "2026-09-02T22:05:00.000Z", "enrollId": "107"}	2026-10-04 22:58:58.91+07
f4aa0a21-5e25-420f-9831-491a38b155ab	3193d9a5-6017-4441-b40c-f22e9ec9b867	59a0c680-ed08-46ba-b1f2-9cabea164b84	107	2026-09-03 21:05:00+07	UNKNOWN	FINGERPRINT	05ba8b28e64f0da2dd69827e8ed7e820715af6a67ae3e1ceae26cc8b5a7475b8	{"punchAt": "2026-09-03T14:05:00.000Z", "enrollId": "107"}	2026-10-04 22:58:58.912+07
f2a66dc7-044c-4fee-9cb4-85a7dc3e502f	3193d9a5-6017-4441-b40c-f22e9ec9b867	59a0c680-ed08-46ba-b1f2-9cabea164b84	107	2026-09-04 05:05:00+07	UNKNOWN	FINGERPRINT	5e9b6df2cacff2186eadff4e17e317204b667b97569373d46c511f3798ec537b	{"punchAt": "2026-09-03T22:05:00.000Z", "enrollId": "107"}	2026-10-04 22:58:58.914+07
9516bc9c-330a-48d4-ba5e-8137b48c6e12	3193d9a5-6017-4441-b40c-f22e9ec9b867	59a0c680-ed08-46ba-b1f2-9cabea164b84	107	2026-09-04 20:55:00+07	UNKNOWN	FINGERPRINT	1bbbc26a8a2f605f77d27393debcbfd28d4f1bb23e92b9022e48b644d6cc4eb7	{"punchAt": "2026-09-04T13:55:00.000Z", "enrollId": "107"}	2026-10-04 22:58:58.916+07
f312b8ba-3365-4b44-b843-5d2f8118d7ce	3193d9a5-6017-4441-b40c-f22e9ec9b867	59a0c680-ed08-46ba-b1f2-9cabea164b84	107	2026-09-05 05:05:00+07	UNKNOWN	FINGERPRINT	ce2d2bd0fc9a98d3c00b3fb5b378a9bac065a6fde70244a13531f67e5256a2cd	{"punchAt": "2026-09-04T22:05:00.000Z", "enrollId": "107"}	2026-10-04 22:58:58.919+07
3e8c8b43-3857-4ed3-8d1d-3527cdd96e38	3193d9a5-6017-4441-b40c-f22e9ec9b867	59a0c680-ed08-46ba-b1f2-9cabea164b84	107	2026-09-07 21:00:00+07	UNKNOWN	FINGERPRINT	1a5bcd977d051023e65feaf9a016a377c92dd4065c9c226ad3f1a25cc72dc4ca	{"punchAt": "2026-09-07T14:00:00.000Z", "enrollId": "107"}	2026-10-04 22:58:58.921+07
d59dc593-6623-443a-8c37-ef928f1b55c0	3193d9a5-6017-4441-b40c-f22e9ec9b867	59a0c680-ed08-46ba-b1f2-9cabea164b84	107	2026-09-08 05:05:00+07	UNKNOWN	FINGERPRINT	0b9ab11745fe690c4a9a4c933d3d3d970e3d5bb30055dd2818d19da24d20e75c	{"punchAt": "2026-09-07T22:05:00.000Z", "enrollId": "107"}	2026-10-04 22:58:58.922+07
cd188977-95e8-4345-b26c-de91eb48f540	3193d9a5-6017-4441-b40c-f22e9ec9b867	59a0c680-ed08-46ba-b1f2-9cabea164b84	107	2026-09-08 21:05:00+07	UNKNOWN	FINGERPRINT	28753f0de63148adb1ebdfbbdfc8ff33daf4eeddcab46640148dc3460af937cd	{"punchAt": "2026-09-08T14:05:00.000Z", "enrollId": "107"}	2026-10-04 22:58:58.924+07
9f59f28f-b573-44b7-82a7-1470ef843c6c	3193d9a5-6017-4441-b40c-f22e9ec9b867	59a0c680-ed08-46ba-b1f2-9cabea164b84	107	2026-09-09 05:05:00+07	UNKNOWN	FINGERPRINT	2fcfe67a2415e2112af7ff25ac3ca4877672883774ea6f1f13d75324b8943120	{"punchAt": "2026-09-08T22:05:00.000Z", "enrollId": "107"}	2026-10-04 22:58:58.925+07
509496d3-144f-4576-854e-9e856e7b7767	3193d9a5-6017-4441-b40c-f22e9ec9b867	59a0c680-ed08-46ba-b1f2-9cabea164b84	107	2026-09-09 20:55:00+07	UNKNOWN	FINGERPRINT	21bbb742bdfa53ac2921ff223e61352e9b21f697e7aaf1b0d3fba9c80156da12	{"punchAt": "2026-09-09T13:55:00.000Z", "enrollId": "107"}	2026-10-04 22:58:58.927+07
ffc2125f-4795-4f83-848d-f7b9fa8d429b	3193d9a5-6017-4441-b40c-f22e9ec9b867	59a0c680-ed08-46ba-b1f2-9cabea164b84	107	2026-09-10 05:05:00+07	UNKNOWN	FINGERPRINT	decd88ae8b7191c9b79d24a6da1f4b70175e2c0382dcf33240ee50b667b38e9f	{"punchAt": "2026-09-09T22:05:00.000Z", "enrollId": "107"}	2026-10-04 22:58:58.928+07
f612b2a5-c42a-4efa-b977-5e5f0b68bd23	3193d9a5-6017-4441-b40c-f22e9ec9b867	59a0c680-ed08-46ba-b1f2-9cabea164b84	107	2026-09-10 21:20:00+07	UNKNOWN	FINGERPRINT	e68aabadfdc88412e1fced350d1eb19ba303adad3bfc3e45a2ed24aec6d0d946	{"punchAt": "2026-09-10T14:20:00.000Z", "enrollId": "107"}	2026-10-04 22:58:58.93+07
e62e225a-edd1-47a7-bb49-c36a428e3bed	3193d9a5-6017-4441-b40c-f22e9ec9b867	59a0c680-ed08-46ba-b1f2-9cabea164b84	107	2026-09-11 05:05:00+07	UNKNOWN	FINGERPRINT	78b3652cbd97ab28bde57820594e58e4fb81bbc4a6be2c1c690fa3a3ff77e0fe	{"punchAt": "2026-09-10T22:05:00.000Z", "enrollId": "107"}	2026-10-04 22:58:58.932+07
4ad091f2-bd5d-4f73-944f-c545c299c9b8	3193d9a5-6017-4441-b40c-f22e9ec9b867	59a0c680-ed08-46ba-b1f2-9cabea164b84	107	2026-09-11 21:05:00+07	UNKNOWN	FINGERPRINT	f5469c73976a51e3aa5d01c7768663dbbed62ad033b9b7718ba554a730f7725d	{"punchAt": "2026-09-11T14:05:00.000Z", "enrollId": "107"}	2026-10-04 22:58:58.935+07
e75465c4-1440-472d-b878-2a13f8f491bf	3193d9a5-6017-4441-b40c-f22e9ec9b867	59a0c680-ed08-46ba-b1f2-9cabea164b84	107	2026-09-12 05:05:00+07	UNKNOWN	FINGERPRINT	18b53717f2e677047ec27dfae4363e1b0b168d49c71933ca480bb0ca8297a287	{"punchAt": "2026-09-11T22:05:00.000Z", "enrollId": "107"}	2026-10-04 22:58:58.938+07
b44ebc4e-05d7-4772-acbd-aa4d40927dd4	3193d9a5-6017-4441-b40c-f22e9ec9b867	59a0c680-ed08-46ba-b1f2-9cabea164b84	107	2026-09-14 20:55:00+07	UNKNOWN	FINGERPRINT	8fad7258180985f3ad82dd5b2594dd03d4acc65fab682345a0e2b5960009297b	{"punchAt": "2026-09-14T13:55:00.000Z", "enrollId": "107"}	2026-10-04 22:58:58.939+07
c373ba09-68d3-47ab-a722-7292b3d3aafa	3193d9a5-6017-4441-b40c-f22e9ec9b867	59a0c680-ed08-46ba-b1f2-9cabea164b84	107	2026-09-15 05:05:00+07	UNKNOWN	FINGERPRINT	4cc1bd4e9943f71b6c4c1f3cf9e59c11e11990d21c0072f22ff4181cfdfb3f30	{"punchAt": "2026-09-14T22:05:00.000Z", "enrollId": "107"}	2026-10-04 22:58:58.942+07
888e029b-6f1f-4523-bb14-d714b3e9930d	3193d9a5-6017-4441-b40c-f22e9ec9b867	59a0c680-ed08-46ba-b1f2-9cabea164b84	107	2026-09-15 21:00:00+07	UNKNOWN	FINGERPRINT	aa96c82077f3d3bb033326f6e2756dd2dac07efa90052b53291c812c1ddecacc	{"punchAt": "2026-09-15T14:00:00.000Z", "enrollId": "107"}	2026-10-04 22:58:58.944+07
8e01f0a2-f70a-47a7-a884-f7bb47d2a49c	3193d9a5-6017-4441-b40c-f22e9ec9b867	59a0c680-ed08-46ba-b1f2-9cabea164b84	107	2026-09-16 05:05:00+07	UNKNOWN	FINGERPRINT	9a5f02ecfe58a5eaa6898f879aa7197f8d1e9d967142865ce23cd290f9cadfbf	{"punchAt": "2026-09-15T22:05:00.000Z", "enrollId": "107"}	2026-10-04 22:58:58.945+07
d0178145-b899-418b-a2d6-f66e5bed487b	3193d9a5-6017-4441-b40c-f22e9ec9b867	59a0c680-ed08-46ba-b1f2-9cabea164b84	107	2026-09-17 21:05:00+07	UNKNOWN	FINGERPRINT	5a58a7c344953ad6efe023f91b03391c5293869ab83b043a38ee899905d36c9d	{"punchAt": "2026-09-17T14:05:00.000Z", "enrollId": "107"}	2026-10-04 22:58:58.947+07
c56d86e4-9f74-4c01-8834-a07c4154380d	3193d9a5-6017-4441-b40c-f22e9ec9b867	59a0c680-ed08-46ba-b1f2-9cabea164b84	107	2026-09-18 05:05:00+07	UNKNOWN	FINGERPRINT	9273ed43628a6f1a8bf98c892d6282c4f9ffa1f9840a1a37f9fd3350c93b924f	{"punchAt": "2026-09-17T22:05:00.000Z", "enrollId": "107"}	2026-10-04 22:58:58.949+07
d491f7b6-965e-4d9b-b926-951f13fbfa69	3193d9a5-6017-4441-b40c-f22e9ec9b867	59a0c680-ed08-46ba-b1f2-9cabea164b84	107	2026-09-18 20:55:00+07	UNKNOWN	FINGERPRINT	338c7960f04e2e17eabbb20c8a0aad9ace0120ffc399b5de1d6fdc0f3532289c	{"punchAt": "2026-09-18T13:55:00.000Z", "enrollId": "107"}	2026-10-04 22:58:58.952+07
82402976-db57-4917-882e-bb706df0ba50	3193d9a5-6017-4441-b40c-f22e9ec9b867	59a0c680-ed08-46ba-b1f2-9cabea164b84	107	2026-09-19 05:05:00+07	UNKNOWN	FINGERPRINT	80ce17f078fdeaf244a17c8622b4ca4848573f4ee5b6a478e92ecabe301a6c7c	{"punchAt": "2026-09-18T22:05:00.000Z", "enrollId": "107"}	2026-10-04 22:58:58.954+07
b4d4e0b9-9e8a-45e5-8532-770929bd8468	3193d9a5-6017-4441-b40c-f22e9ec9b867	59a0c680-ed08-46ba-b1f2-9cabea164b84	107	2026-09-21 21:00:00+07	UNKNOWN	FINGERPRINT	6390cdc37a42340f681ca91b3f49d264cc3faf8b7fe8f0b0593279b39cc6f962	{"punchAt": "2026-09-21T14:00:00.000Z", "enrollId": "107"}	2026-10-04 22:58:58.956+07
f835aa87-02e5-4d9a-8c18-10c3fe0c19de	3193d9a5-6017-4441-b40c-f22e9ec9b867	59a0c680-ed08-46ba-b1f2-9cabea164b84	107	2026-09-22 05:05:00+07	UNKNOWN	FINGERPRINT	640aaa54354130d09f0e0cea467349ad4ce1365067c617eb056f183b4343017e	{"punchAt": "2026-09-21T22:05:00.000Z", "enrollId": "107"}	2026-10-04 22:58:58.959+07
59c4f423-6585-4a45-8298-e8c4a24aefc1	3193d9a5-6017-4441-b40c-f22e9ec9b867	59a0c680-ed08-46ba-b1f2-9cabea164b84	107	2026-09-23 21:05:00+07	UNKNOWN	FINGERPRINT	d0ac247cc4e2a3f24e66e5c7b2189b03970c241f92f5039dc789bcda68fd0c3d	{"punchAt": "2026-09-23T14:05:00.000Z", "enrollId": "107"}	2026-10-04 22:58:58.961+07
38deeecc-51fc-49c8-bc3e-79d1c342eca0	3193d9a5-6017-4441-b40c-f22e9ec9b867	59a0c680-ed08-46ba-b1f2-9cabea164b84	107	2026-09-24 05:05:00+07	UNKNOWN	FINGERPRINT	45319ad6b68e924595de97de131028440a656b867dfa101e20c1ce2e8104ce95	{"punchAt": "2026-09-23T22:05:00.000Z", "enrollId": "107"}	2026-10-04 22:58:58.963+07
b90677c1-56a3-41a9-aa6b-b096cb7a1074	3193d9a5-6017-4441-b40c-f22e9ec9b867	59a0c680-ed08-46ba-b1f2-9cabea164b84	107	2026-09-24 20:55:00+07	UNKNOWN	FINGERPRINT	3af0dc0a313e82cfc621186d6e7bd5b7e9b96ab0f399c1e8bf226041382bbdd4	{"punchAt": "2026-09-24T13:55:00.000Z", "enrollId": "107"}	2026-10-04 22:58:58.965+07
80f8c0a9-6d31-44d0-acf1-9e59d574aa74	3193d9a5-6017-4441-b40c-f22e9ec9b867	59a0c680-ed08-46ba-b1f2-9cabea164b84	107	2026-09-25 05:05:00+07	UNKNOWN	FINGERPRINT	d424c47f5c5d5e7fd83b39fa9b7518151ea2f9914265cf581d05e5a6414659d7	{"punchAt": "2026-09-24T22:05:00.000Z", "enrollId": "107"}	2026-10-04 22:58:58.968+07
83c5cd67-950f-4f29-bcf9-29776cb9a631	3193d9a5-6017-4441-b40c-f22e9ec9b867	59a0c680-ed08-46ba-b1f2-9cabea164b84	107	2026-09-25 21:00:00+07	UNKNOWN	FINGERPRINT	29f8a3aff7b06940e8bc9e24449fce5813f3b9d4aad663e6a51299db212a2893	{"punchAt": "2026-09-25T14:00:00.000Z", "enrollId": "107"}	2026-10-04 22:58:58.97+07
ba91d17b-cebb-42b6-8f80-07c130b9a674	3193d9a5-6017-4441-b40c-f22e9ec9b867	59a0c680-ed08-46ba-b1f2-9cabea164b84	107	2026-09-26 05:05:00+07	UNKNOWN	FINGERPRINT	92845107f7d12f8bdfe9e96f2971f8146a2d8bdff391455e859eaf1261538b0a	{"punchAt": "2026-09-25T22:05:00.000Z", "enrollId": "107"}	2026-10-04 22:58:58.971+07
3ae56af6-8d07-45fe-81de-60672a8cb235	3193d9a5-6017-4441-b40c-f22e9ec9b867	59a0c680-ed08-46ba-b1f2-9cabea164b84	107	2026-09-28 21:05:00+07	UNKNOWN	FINGERPRINT	f9281c007a2ebcf33a591b3b7b2e2fa65c4cbcfe88464771f02a7da85cdfc434	{"punchAt": "2026-09-28T14:05:00.000Z", "enrollId": "107"}	2026-10-04 22:58:58.973+07
60667a5c-d3d1-4dac-80a6-680712eebaa5	3193d9a5-6017-4441-b40c-f22e9ec9b867	59a0c680-ed08-46ba-b1f2-9cabea164b84	107	2026-09-29 05:05:00+07	UNKNOWN	FINGERPRINT	c6e8b2b6788ccc652c1bd6e54f7740291cd844efa8aa5170397b3cd880404aee	{"punchAt": "2026-09-28T22:05:00.000Z", "enrollId": "107"}	2026-10-04 22:58:58.974+07
6bd0739a-c489-43e7-941b-d0fe0bae6792	3193d9a5-6017-4441-b40c-f22e9ec9b867	59a0c680-ed08-46ba-b1f2-9cabea164b84	107	2026-09-29 20:55:00+07	UNKNOWN	FINGERPRINT	6d463c7dca2e5294ba5765bd8bc745908776c6dddbee4c4b65ecc2c88daaabab	{"punchAt": "2026-09-29T13:55:00.000Z", "enrollId": "107"}	2026-10-04 22:58:58.976+07
48daf1ae-4156-4540-81e2-5c59dcdc6f71	3193d9a5-6017-4441-b40c-f22e9ec9b867	59a0c680-ed08-46ba-b1f2-9cabea164b84	107	2026-09-30 05:05:00+07	UNKNOWN	FINGERPRINT	7a546fcd613a8d7a36335559f874105f2842c8060156c671a5db842eff98b018	{"punchAt": "2026-09-29T22:05:00.000Z", "enrollId": "107"}	2026-10-04 22:58:58.977+07
aa6ddea2-6621-4791-a3d4-f6893f4b6e5c	3193d9a5-6017-4441-b40c-f22e9ec9b867	59a0c680-ed08-46ba-b1f2-9cabea164b84	107	2026-09-30 21:00:00+07	UNKNOWN	FINGERPRINT	b0c02a9fe9d5f44902402a31b0511f4c4d5a819685573529bd9eb02e1b491498	{"punchAt": "2026-09-30T14:00:00.000Z", "enrollId": "107"}	2026-10-04 22:58:58.979+07
0cd15cd3-16fc-47a1-ae56-2937f8cbc92f	3193d9a5-6017-4441-b40c-f22e9ec9b867	59a0c680-ed08-46ba-b1f2-9cabea164b84	107	2026-10-01 05:05:00+07	UNKNOWN	FINGERPRINT	13bd11031d5953617f1605793c42fb5db30911da4a87bb0a6af57ec517d57203	{"punchAt": "2026-09-30T22:05:00.000Z", "enrollId": "107"}	2026-10-04 22:58:58.981+07
aacd654e-ae3e-420a-8699-8fdc35de0bda	23230ce1-1ab7-4b49-b9b2-404f149e00ca	6efdad93-a931-46e2-b5f0-acf2a805843b	109	2026-09-01 05:58:00+07	UNKNOWN	FINGERPRINT	74741c672cc949bfdecca2ad6d8043a3ccd52c3f4e34d869376d9b92bb0440d9	{"punchAt": "2026-08-31T22:58:00.000Z", "enrollId": "109"}	2026-10-04 22:58:59.303+07
b1fd95b4-f783-4c08-96a6-e3590586e05e	23230ce1-1ab7-4b49-b9b2-404f149e00ca	6efdad93-a931-46e2-b5f0-acf2a805843b	109	2026-09-01 14:00:00+07	UNKNOWN	FINGERPRINT	416ef89aceb59f0560248f938e0fcb9a01a8bdb048496fa999ff1e89d8721d26	{"punchAt": "2026-09-01T07:00:00.000Z", "enrollId": "109"}	2026-10-04 22:58:59.305+07
0951eeb2-f2fb-4bd6-9e70-8e6d23af5687	23230ce1-1ab7-4b49-b9b2-404f149e00ca	6efdad93-a931-46e2-b5f0-acf2a805843b	109	2026-09-02 05:58:00+07	UNKNOWN	FINGERPRINT	81ba396b6e8cfe7486dbb604622c7ddb77d9c1d183368dcd71ffa5de499dfb0f	{"punchAt": "2026-09-01T22:58:00.000Z", "enrollId": "109"}	2026-10-04 22:58:59.307+07
9f47602a-8a07-410f-970a-0710f070adf9	23230ce1-1ab7-4b49-b9b2-404f149e00ca	6efdad93-a931-46e2-b5f0-acf2a805843b	109	2026-09-02 14:00:00+07	UNKNOWN	FINGERPRINT	1448c49c9b9091a20db28e98ea1126d77b6c8e0f747f2a4405204ba2debab2fd	{"punchAt": "2026-09-02T07:00:00.000Z", "enrollId": "109"}	2026-10-04 22:58:59.309+07
da22d7dd-db79-438f-9335-7592a406f7f0	23230ce1-1ab7-4b49-b9b2-404f149e00ca	6efdad93-a931-46e2-b5f0-acf2a805843b	109	2026-09-03 05:58:00+07	UNKNOWN	FINGERPRINT	345987ba91c11f24aadb6e37b9a4169873537f2ceec57fab7a280ff1ac02ae2f	{"punchAt": "2026-09-02T22:58:00.000Z", "enrollId": "109"}	2026-10-04 22:58:59.311+07
1dffa6e6-e538-4cf7-8ada-fb9c99c2fe07	23230ce1-1ab7-4b49-b9b2-404f149e00ca	6efdad93-a931-46e2-b5f0-acf2a805843b	109	2026-09-03 14:00:00+07	UNKNOWN	FINGERPRINT	bf9f7daf295816d375677e8b1e3f6ffd55cf786ad9309d5454a24a2236f4af75	{"punchAt": "2026-09-03T07:00:00.000Z", "enrollId": "109"}	2026-10-04 22:58:59.313+07
3d1a1d73-2f17-4ab9-9b16-d0f932ce468c	23230ce1-1ab7-4b49-b9b2-404f149e00ca	6efdad93-a931-46e2-b5f0-acf2a805843b	109	2026-09-04 06:12:00+07	UNKNOWN	FINGERPRINT	9c0d8832df8a7543945c08b037df9e414597faa73383ed36f003e2a29896d1ce	{"punchAt": "2026-09-03T23:12:00.000Z", "enrollId": "109"}	2026-10-04 22:58:59.315+07
9ad14fdc-e88e-410c-986f-7b212e74f48f	23230ce1-1ab7-4b49-b9b2-404f149e00ca	6efdad93-a931-46e2-b5f0-acf2a805843b	109	2026-09-04 14:00:00+07	UNKNOWN	FINGERPRINT	534568c3abeb1ee1405c711da947f191137d0923318957f29a72e5c5b5b96ec7	{"punchAt": "2026-09-04T07:00:00.000Z", "enrollId": "109"}	2026-10-04 22:58:59.317+07
f44efce7-d34e-4f4d-9a24-83e1564398a2	23230ce1-1ab7-4b49-b9b2-404f149e00ca	6efdad93-a931-46e2-b5f0-acf2a805843b	109	2026-09-07 05:58:00+07	UNKNOWN	FINGERPRINT	4fc7d04c6fc926f4d536cf5f27b4a76438f33bb1c188550e894e7ee9f05878cd	{"punchAt": "2026-09-06T22:58:00.000Z", "enrollId": "109"}	2026-10-04 22:58:59.319+07
1ed6ca92-f623-4eac-b79d-0c670401785a	23230ce1-1ab7-4b49-b9b2-404f149e00ca	6efdad93-a931-46e2-b5f0-acf2a805843b	109	2026-09-07 14:00:00+07	UNKNOWN	FINGERPRINT	5b01712b0060411b0486b1067336aedf9c20b467bc1498b1ab38c0c8d1ccb1b9	{"punchAt": "2026-09-07T07:00:00.000Z", "enrollId": "109"}	2026-10-04 22:58:59.321+07
d6bf347e-7592-4aa7-9a98-360eeec70944	23230ce1-1ab7-4b49-b9b2-404f149e00ca	6efdad93-a931-46e2-b5f0-acf2a805843b	109	2026-09-08 05:58:00+07	UNKNOWN	FINGERPRINT	29207e7a9dbd81efedb64b18c3b8f5e1157fc9fb4b3ae6e9612d09d1a7bff047	{"punchAt": "2026-09-07T22:58:00.000Z", "enrollId": "109"}	2026-10-04 22:58:59.323+07
627d16a8-2e7b-48a4-8c06-c30bc616ea95	23230ce1-1ab7-4b49-b9b2-404f149e00ca	6efdad93-a931-46e2-b5f0-acf2a805843b	109	2026-09-08 14:00:00+07	UNKNOWN	FINGERPRINT	e600811efcef1d673c6d161ff0ca2706b2bcade02e22314459f4efd4930d852d	{"punchAt": "2026-09-08T07:00:00.000Z", "enrollId": "109"}	2026-10-04 22:58:59.324+07
737b3a69-dbb2-4aa2-bec2-2b5f26e545b4	23230ce1-1ab7-4b49-b9b2-404f149e00ca	6efdad93-a931-46e2-b5f0-acf2a805843b	109	2026-09-09 05:58:00+07	UNKNOWN	FINGERPRINT	eda8ab6c9de9476a92729bd3dfbea57a65bebc9341abb604849b6b806d041551	{"punchAt": "2026-09-08T22:58:00.000Z", "enrollId": "109"}	2026-10-04 22:58:59.326+07
7768dae9-7efe-4005-9e7e-163afc5ce577	23230ce1-1ab7-4b49-b9b2-404f149e00ca	6efdad93-a931-46e2-b5f0-acf2a805843b	109	2026-09-09 14:00:00+07	UNKNOWN	FINGERPRINT	fbaaa743013d4583082be17b9e082b75da82c1eb6c9ff562fc72301387ae8379	{"punchAt": "2026-09-09T07:00:00.000Z", "enrollId": "109"}	2026-10-04 22:58:59.328+07
a94849ab-6860-4570-8be4-9afce5184135	23230ce1-1ab7-4b49-b9b2-404f149e00ca	6efdad93-a931-46e2-b5f0-acf2a805843b	109	2026-09-10 06:20:00+07	UNKNOWN	FINGERPRINT	bf4db8a56bf524cfd58521b3fb6dacc8e8525abd2999983f809cf93c22e7d160	{"punchAt": "2026-09-09T23:20:00.000Z", "enrollId": "109"}	2026-10-04 22:58:59.33+07
d76e8df7-3787-4781-943d-b424e62fe1bb	23230ce1-1ab7-4b49-b9b2-404f149e00ca	6efdad93-a931-46e2-b5f0-acf2a805843b	109	2026-09-10 14:00:00+07	UNKNOWN	FINGERPRINT	3251a1b9488bd32a92219a94e08d6be49e1d3277d079df7744cfec85ae20e68b	{"punchAt": "2026-09-10T07:00:00.000Z", "enrollId": "109"}	2026-10-04 22:58:59.332+07
b34c931e-cf06-4a1b-ab91-d3416642a9ba	23230ce1-1ab7-4b49-b9b2-404f149e00ca	6efdad93-a931-46e2-b5f0-acf2a805843b	109	2026-09-11 05:58:00+07	UNKNOWN	FINGERPRINT	43cf66ea031ae8800a2a5fb51835df84e3a45a497c56120e624c9ea3ccdd203c	{"punchAt": "2026-09-10T22:58:00.000Z", "enrollId": "109"}	2026-10-04 22:58:59.334+07
a2709366-12e7-4983-b339-052698179491	23230ce1-1ab7-4b49-b9b2-404f149e00ca	6efdad93-a931-46e2-b5f0-acf2a805843b	109	2026-09-11 14:00:00+07	UNKNOWN	FINGERPRINT	a8ab6aa45ea495187146878c03f61ed681de7b3ef210d46c5d7c972739d216fc	{"punchAt": "2026-09-11T07:00:00.000Z", "enrollId": "109"}	2026-10-04 22:58:59.338+07
0d9a8b9f-4ea6-4ca9-8c3d-cbc1d15c958e	23230ce1-1ab7-4b49-b9b2-404f149e00ca	6efdad93-a931-46e2-b5f0-acf2a805843b	109	2026-09-14 05:58:00+07	UNKNOWN	FINGERPRINT	594192bb6b95cb6b4df01a446fa1634abf241f8d886a03b2b5c59297a47189ad	{"punchAt": "2026-09-13T22:58:00.000Z", "enrollId": "109"}	2026-10-04 22:58:59.34+07
769b6b11-76b0-426a-9a92-ebdde6038ead	23230ce1-1ab7-4b49-b9b2-404f149e00ca	6efdad93-a931-46e2-b5f0-acf2a805843b	109	2026-09-14 14:00:00+07	UNKNOWN	FINGERPRINT	b4b53bc5649f277b7293d70333ec4dfa49cc3904904e1f7b07b75b6aad992d93	{"punchAt": "2026-09-14T07:00:00.000Z", "enrollId": "109"}	2026-10-04 22:58:59.342+07
eb4db8dc-8453-4791-8ea6-43c6d2adf382	23230ce1-1ab7-4b49-b9b2-404f149e00ca	6efdad93-a931-46e2-b5f0-acf2a805843b	109	2026-09-15 05:58:00+07	UNKNOWN	FINGERPRINT	917c0e7edfe8f78fc65eab79534fc49b22fcee8fe58b6fff429004b8d55c3aac	{"punchAt": "2026-09-14T22:58:00.000Z", "enrollId": "109"}	2026-10-04 22:58:59.343+07
a9097a9d-0522-431e-a618-47b64968dc30	23230ce1-1ab7-4b49-b9b2-404f149e00ca	6efdad93-a931-46e2-b5f0-acf2a805843b	109	2026-09-15 14:00:00+07	UNKNOWN	FINGERPRINT	3fb2d0da0c992cea74ac1ce41d64c7dc5bc51225b3aa257e3adf5caf8fb42d66	{"punchAt": "2026-09-15T07:00:00.000Z", "enrollId": "109"}	2026-10-04 22:58:59.345+07
\.


--
-- Data for Name: AttendanceRule; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."AttendanceRule" (id, "workLocationId", "effectiveFrom", "effectiveTo", "gracePeriodMinutes", "preShiftWindowMinutes", "postShiftWindowMinutes", "updatedBy", "createdAt", "updatedAt") FROM stdin;
33e6ae19-66b5-4a25-897a-48d9694631aa	a071e3d8-e61e-4671-8600-55d42d5a890c	2026-01-01	\N	10	240	360	ca415e8f-13cd-46c3-860b-e9510e36b9ca	2026-10-04 22:58:55.644+07	2026-10-04 22:58:55.644+07
a0e0efc8-d1de-4d31-82a1-483eb53530de	6d7af890-a7b5-4313-83ed-f6fa76d0a7c6	2026-01-01	\N	5	240	360	ca415e8f-13cd-46c3-860b-e9510e36b9ca	2026-10-04 22:58:55.665+07	2026-10-04 22:58:55.665+07
3a5de69c-b61e-42bd-aea3-f49ff3c5e654	02d1e070-925a-4bbf-a321-e8542610aea7	2026-01-01	\N	15	240	360	ca415e8f-13cd-46c3-860b-e9510e36b9ca	2026-10-04 22:58:55.679+07	2026-10-04 22:58:55.679+07
\.


--
-- Data for Name: AuditLog; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."AuditLog" (id, "actorId", action, "entityType", "entityId", "beforeJson", "afterJson", meta, "createdAt") FROM stdin;
17b075e1-cc38-41e3-8c88-f8c8ac0f278e	ca415e8f-13cd-46c3-860b-e9510e36b9ca	ATTENDANCE_RULE_VERSION_CREATED	AttendanceRule	33e6ae19-66b5-4a25-897a-48d9694631aa	\N	{"id": "33e6ae19-66b5-4a25-897a-48d9694631aa", "createdAt": "2026-10-04T15:58:55.644Z", "updatedAt": "2026-10-04T15:58:55.644Z", "updatedBy": "ca415e8f-13cd-46c3-860b-e9510e36b9ca", "effectiveTo": null, "effectiveFrom": "2026-01-01T00:00:00.000Z", "workLocationId": "a071e3d8-e61e-4671-8600-55d42d5a890c", "gracePeriodMinutes": 10, "preShiftWindowMinutes": 240, "postShiftWindowMinutes": 360}	\N	2026-10-04 22:58:55.646+07
43d0f76b-550b-4a00-b7ed-b21c5979c683	ca415e8f-13cd-46c3-860b-e9510e36b9ca	ATTENDANCE_RULE_VERSION_CREATED	AttendanceRule	a0e0efc8-d1de-4d31-82a1-483eb53530de	\N	{"id": "a0e0efc8-d1de-4d31-82a1-483eb53530de", "createdAt": "2026-10-04T15:58:55.665Z", "updatedAt": "2026-10-04T15:58:55.665Z", "updatedBy": "ca415e8f-13cd-46c3-860b-e9510e36b9ca", "effectiveTo": null, "effectiveFrom": "2026-01-01T00:00:00.000Z", "workLocationId": "6d7af890-a7b5-4313-83ed-f6fa76d0a7c6", "gracePeriodMinutes": 5, "preShiftWindowMinutes": 240, "postShiftWindowMinutes": 360}	\N	2026-10-04 22:58:55.668+07
393bafb8-ea26-44ee-ba57-6f6e091f5aba	ca415e8f-13cd-46c3-860b-e9510e36b9ca	ATTENDANCE_RULE_VERSION_CREATED	AttendanceRule	3a5de69c-b61e-42bd-aea3-f49ff3c5e654	\N	{"id": "3a5de69c-b61e-42bd-aea3-f49ff3c5e654", "createdAt": "2026-10-04T15:58:55.679Z", "updatedAt": "2026-10-04T15:58:55.679Z", "updatedBy": "ca415e8f-13cd-46c3-860b-e9510e36b9ca", "effectiveTo": null, "effectiveFrom": "2026-01-01T00:00:00.000Z", "workLocationId": "02d1e070-925a-4bbf-a321-e8542610aea7", "gracePeriodMinutes": 15, "preShiftWindowMinutes": 240, "postShiftWindowMinutes": 360}	\N	2026-10-04 22:58:55.68+07
b7610e60-4010-402e-be4f-69d9fe4da545	ca415e8f-13cd-46c3-860b-e9510e36b9ca	LEAVE_RULE_VERSION_CREATED	LeaveRule	9db0823d-9314-426d-bfb8-201371d7fd1a	\N	{"id": "9db0823d-9314-426d-bfb8-201371d7fd1a", "createdAt": "2026-10-04T16:23:54.582Z", "leaveKind": "ANNUAL", "updatedAt": "2026-10-04T16:23:54.582Z", "updatedBy": "ca415e8f-13cd-46c3-860b-e9510e36b9ca", "accrualMode": "ANNIVERSARY", "effectiveTo": null, "expiryMonths": 12, "effectiveFrom": "2026-01-01T00:00:00.000Z", "entitlementDays": 12, "minTenureMonths": 12, "firstGrantAnniversary": 1}	\N	2026-10-04 23:23:54.583+07
\.


--
-- Data for Name: CalendarEvent; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."CalendarEvent" (id, "externalRef", "eventType", scope, "workLocationId", "odooEmployeeId", "startDate", "endDate", "cancelsWorkday", "skipGeofence", name, "importBatchId") FROM stdin;
a71b89a6-7b7b-43b0-8135-c0c4bf869b8d	\N	COMPANY_EVENT	GLOBAL	\N	\N	2026-09-16	2026-09-16	t	f	DEMO Libur Perusahaan	\N
0dc71cd0-7f51-4ce7-bb98-fca779a51a6d	\N	COLLECTIVE_LEAVE	LOCATION	6d7af890-a7b5-4313-83ed-f6fa76d0a7c6	\N	2026-09-22	2026-09-22	t	f	DEMO Cuti Bersama Makassar	\N
91517c3b-e705-41a4-9e8f-cc2957416ce7	\N	TRAINING	GLOBAL	\N	\N	2026-09-24	2026-09-24	f	f	DEMO Pelatihan K3	\N
\.


--
-- Data for Name: Device; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."Device" (id, "serialNumber", vendor, name, "workLocationId", "isActive") FROM stdin;
8ae41932-c8e7-4d34-9854-4f25e9488942	DEMO-SN-JKT	ZKTeco	DEMO Mesin JKT	a071e3d8-e61e-4671-8600-55d42d5a890c	t
59a0c680-ed08-46ba-b1f2-9cabea164b84	DEMO-SN-MKS	ZKTeco	DEMO Mesin MKS	6d7af890-a7b5-4313-83ed-f6fa76d0a7c6	t
6efdad93-a931-46e2-b5f0-acf2a805843b	DEMO-SN-JYP	ZKTeco	DEMO Mesin JYP	02d1e070-925a-4bbf-a321-e8542610aea7	t
\.


--
-- Data for Name: EmployeeDeviceMap; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."EmployeeDeviceMap" (id, "deviceId", "enrollId", "odooEmployeeId") FROM stdin;
f6cd8ce9-aa3a-44b2-ac1e-f3bf0847ce63	8ae41932-c8e7-4d34-9854-4f25e9488942	101	6a65b903-7cb2-468b-8245-a607e73baa54
65b2586c-96da-4272-add1-11beda9b3b39	8ae41932-c8e7-4d34-9854-4f25e9488942	102	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc
031b55f9-2671-47fc-b589-5d1edbfc5689	8ae41932-c8e7-4d34-9854-4f25e9488942	103	4478787b-c3e8-4f0d-8b9b-7046fec7f539
9e3cc662-aeaa-4d90-8ab7-eeb19f80d6f9	8ae41932-c8e7-4d34-9854-4f25e9488942	104	0cd6bde6-3226-4ebb-b135-ca522d42efa4
5e0ed2e9-b909-4ce9-a0ee-e12e76a3b20f	8ae41932-c8e7-4d34-9854-4f25e9488942	105	0c685448-b52e-4e60-89ea-6f7c500a86d5
38aab34f-4620-4224-aba8-4e52e4bfbbeb	8ae41932-c8e7-4d34-9854-4f25e9488942	108	b7291f79-3495-44a5-b039-737465dc2cc0
3cd43a9a-0cd6-4b34-a95f-34f53be32627	8ae41932-c8e7-4d34-9854-4f25e9488942	110	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51
a8a82c1c-a49d-4b52-8030-3cdf4a981855	59a0c680-ed08-46ba-b1f2-9cabea164b84	106	0b9e23c5-0b7c-43d4-b66e-9193e1c24804
9438daef-d568-4349-9fb7-b5b127c1ed93	59a0c680-ed08-46ba-b1f2-9cabea164b84	107	3193d9a5-6017-4441-b40c-f22e9ec9b867
22cf6ff0-709f-4be6-95d5-f1ce05737181	6efdad93-a931-46e2-b5f0-acf2a805843b	109	23230ce1-1ab7-4b49-b9b2-404f149e00ca
\.


--
-- Data for Name: EmployeeSchedule; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."EmployeeSchedule" (id, "odooEmployeeId", "workDate", "dayType", "shiftId", "shiftStart", "shiftEnd", source, "importBatchId", "updatedAt") FROM stdin;
37441b8f-23cb-460d-8c88-063d079bfdcb	6a65b903-7cb2-468b-8245-a607e73baa54	2026-09-03	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-03 08:00:00+07	2026-09-03 16:00:00+07	MANUAL	\N	2026-10-04 23:23:53.647+07
bd06a812-a57f-4397-a08a-b51746e92dfd	6a65b903-7cb2-468b-8245-a607e73baa54	2026-09-04	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-04 08:00:00+07	2026-09-04 16:00:00+07	MANUAL	\N	2026-10-04 23:23:53.65+07
034808e4-fd95-4ade-9d63-3f107f876ec5	6a65b903-7cb2-468b-8245-a607e73baa54	2026-09-14	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-14 08:00:00+07	2026-09-14 16:00:00+07	MANUAL	\N	2026-10-04 23:23:53.679+07
f8e64f58-f71b-4304-8568-481c4fe2d51c	6a65b903-7cb2-468b-8245-a607e73baa54	2026-09-15	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-15 08:00:00+07	2026-09-15 16:00:00+07	MANUAL	\N	2026-10-04 23:23:53.682+07
12eef6ab-faab-4598-9eaf-eabc32c092a0	6a65b903-7cb2-468b-8245-a607e73baa54	2026-09-16	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-16 08:00:00+07	2026-09-16 16:00:00+07	MANUAL	\N	2026-10-04 23:23:53.686+07
0a200337-2516-4347-bc3d-7a61f2e773df	6a65b903-7cb2-468b-8245-a607e73baa54	2026-09-17	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-17 08:00:00+07	2026-09-17 16:00:00+07	MANUAL	\N	2026-10-04 23:23:53.689+07
34193255-d38b-42ec-b949-a7a7f39c93b0	6a65b903-7cb2-468b-8245-a607e73baa54	2026-09-18	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-18 08:00:00+07	2026-09-18 16:00:00+07	MANUAL	\N	2026-10-04 23:23:53.692+07
6bbc0d03-8039-4b00-998b-06900c1b3735	6a65b903-7cb2-468b-8245-a607e73baa54	2026-09-19	OFFDAY	\N	\N	\N	MANUAL	\N	2026-10-04 23:23:53.694+07
4507f4d0-6ed4-499a-a453-0611e4ed2ccb	6a65b903-7cb2-468b-8245-a607e73baa54	2026-09-20	OFFDAY	\N	\N	\N	MANUAL	\N	2026-10-04 23:23:53.697+07
f5a6e18b-346d-4a36-a96b-f06b995f9305	6a65b903-7cb2-468b-8245-a607e73baa54	2026-09-21	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-21 08:00:00+07	2026-09-21 16:00:00+07	MANUAL	\N	2026-10-04 23:23:53.699+07
f513c309-b4a1-43f2-8b22-fcf7bef4329a	6a65b903-7cb2-468b-8245-a607e73baa54	2026-09-22	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-22 08:00:00+07	2026-09-22 16:00:00+07	MANUAL	\N	2026-10-04 23:23:53.703+07
eb26a880-3df4-4974-ac55-d8493f9e7eb7	6a65b903-7cb2-468b-8245-a607e73baa54	2026-09-23	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-23 08:00:00+07	2026-09-23 16:00:00+07	MANUAL	\N	2026-10-04 23:23:53.707+07
67c897cf-d188-4610-bfac-f8e0f637b632	6a65b903-7cb2-468b-8245-a607e73baa54	2026-09-24	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-24 08:00:00+07	2026-09-24 16:00:00+07	MANUAL	\N	2026-10-04 23:23:53.71+07
f16152f1-e4ae-40f7-b04e-f2fc548d7c55	6a65b903-7cb2-468b-8245-a607e73baa54	2026-09-25	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-25 08:00:00+07	2026-09-25 16:00:00+07	MANUAL	\N	2026-10-04 23:23:53.713+07
e79f0b42-2722-4d32-bc33-2aa86307e2b7	6a65b903-7cb2-468b-8245-a607e73baa54	2026-09-26	OFFDAY	\N	\N	\N	MANUAL	\N	2026-10-04 23:23:53.715+07
7d21e68a-ee16-4723-8ebb-2b5af8179e9c	6a65b903-7cb2-468b-8245-a607e73baa54	2026-09-27	OFFDAY	\N	\N	\N	MANUAL	\N	2026-10-04 23:23:53.717+07
adf6a716-0400-48a6-94e0-47618179c9ae	6a65b903-7cb2-468b-8245-a607e73baa54	2026-09-28	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-28 08:00:00+07	2026-09-28 16:00:00+07	MANUAL	\N	2026-10-04 23:23:53.721+07
44fd042a-aadb-4d4a-af49-5335e257920c	6a65b903-7cb2-468b-8245-a607e73baa54	2026-09-29	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-29 08:00:00+07	2026-09-29 16:00:00+07	MANUAL	\N	2026-10-04 23:23:53.724+07
8bb3a331-d38e-4cb3-8b99-99a8b4359f97	6a65b903-7cb2-468b-8245-a607e73baa54	2026-09-30	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-30 08:00:00+07	2026-09-30 16:00:00+07	MANUAL	\N	2026-10-04 23:23:53.727+07
3fd13c4a-0967-43cd-8aa8-ea9a3b3bd1ac	6a65b903-7cb2-468b-8245-a607e73baa54	2026-09-01	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-01 08:00:00+07	2026-09-01 16:00:00+07	MANUAL	\N	2026-10-04 23:23:53.638+07
7157c4e9-e6f2-444c-b0b7-13892cd25942	6a65b903-7cb2-468b-8245-a607e73baa54	2026-09-02	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-02 08:00:00+07	2026-09-02 16:00:00+07	MANUAL	\N	2026-10-04 23:23:53.644+07
5fad96a6-e182-4181-8c9d-2a2eb8c61503	6a65b903-7cb2-468b-8245-a607e73baa54	2026-09-05	OFFDAY	\N	\N	\N	MANUAL	\N	2026-10-04 23:23:53.653+07
a6b8d7be-1648-4c9b-8cc5-69a403f426ad	6a65b903-7cb2-468b-8245-a607e73baa54	2026-09-06	OFFDAY	\N	\N	\N	MANUAL	\N	2026-10-04 23:23:53.656+07
0a85383d-ff6d-47df-9a2d-c15defc31ebd	6a65b903-7cb2-468b-8245-a607e73baa54	2026-09-07	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-07 08:00:00+07	2026-09-07 16:00:00+07	MANUAL	\N	2026-10-04 23:23:53.659+07
4faf65f1-bd5c-4321-a75b-17b58d631e11	6a65b903-7cb2-468b-8245-a607e73baa54	2026-09-08	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-08 08:00:00+07	2026-09-08 16:00:00+07	MANUAL	\N	2026-10-04 23:23:53.662+07
cc916e81-6531-4c1e-83a3-4a38b41ed2c6	6a65b903-7cb2-468b-8245-a607e73baa54	2026-09-09	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-09 08:00:00+07	2026-09-09 16:00:00+07	MANUAL	\N	2026-10-04 23:23:53.665+07
c2985a0b-692e-49c6-9532-402fac80bd5b	6a65b903-7cb2-468b-8245-a607e73baa54	2026-09-10	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-10 08:00:00+07	2026-09-10 16:00:00+07	MANUAL	\N	2026-10-04 23:23:53.668+07
8c0a433d-b0fe-452e-8fac-49e331239a33	6a65b903-7cb2-468b-8245-a607e73baa54	2026-09-11	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-11 08:00:00+07	2026-09-11 16:00:00+07	MANUAL	\N	2026-10-04 23:23:53.672+07
69249885-f4a7-4787-89e0-256a4c1d7ac5	6a65b903-7cb2-468b-8245-a607e73baa54	2026-09-12	OFFDAY	\N	\N	\N	MANUAL	\N	2026-10-04 23:23:53.674+07
910fe7e3-3248-4f18-aae9-38b4f3d76536	6a65b903-7cb2-468b-8245-a607e73baa54	2026-09-13	OFFDAY	\N	\N	\N	MANUAL	\N	2026-10-04 23:23:53.676+07
8b822f67-18c5-4744-a279-aca9963df501	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	2026-09-03	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-03 08:00:00+07	2026-09-03 16:00:00+07	MANUAL	\N	2026-10-04 23:23:53.738+07
0917d82e-9ea4-40c9-9c87-29636bcf9fe3	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	2026-09-04	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-04 08:00:00+07	2026-09-04 16:00:00+07	MANUAL	\N	2026-10-04 23:23:53.742+07
ba199316-d58e-4cc1-b0d6-37538cabbe54	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	2026-09-05	OFFDAY	\N	\N	\N	MANUAL	\N	2026-10-04 23:23:53.744+07
ebce64e5-3204-494e-b261-cf98d44c5288	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	2026-09-06	OFFDAY	\N	\N	\N	MANUAL	\N	2026-10-04 23:23:53.746+07
7684fafa-87ae-4ecd-a754-ee078cc6bd51	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	2026-09-07	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-07 08:00:00+07	2026-09-07 16:00:00+07	MANUAL	\N	2026-10-04 23:23:53.749+07
41214557-d2c3-45d3-b8a6-463ede4b1dab	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	2026-09-08	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-08 08:00:00+07	2026-09-08 16:00:00+07	MANUAL	\N	2026-10-04 23:23:53.752+07
1698a7a6-9b72-4408-9d09-665e171cae40	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	2026-09-09	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-09 08:00:00+07	2026-09-09 16:00:00+07	MANUAL	\N	2026-10-04 23:23:53.756+07
bd1a3b1c-9b85-4147-bde9-e51a1511feb1	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	2026-09-10	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-10 08:00:00+07	2026-09-10 16:00:00+07	MANUAL	\N	2026-10-04 23:23:53.76+07
6390e7ae-66fc-4fc1-96d9-7ee214a73579	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	2026-09-11	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-11 08:00:00+07	2026-09-11 16:00:00+07	MANUAL	\N	2026-10-04 23:23:53.763+07
88863ebc-c5ee-484d-9a67-71fbbde09ad5	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	2026-09-12	OFFDAY	\N	\N	\N	MANUAL	\N	2026-10-04 23:23:53.765+07
a3e507f4-9b5f-4b5e-b39c-85cbc36b6de4	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	2026-09-13	OFFDAY	\N	\N	\N	MANUAL	\N	2026-10-04 23:23:53.767+07
87aacdb0-8c53-412b-b1b0-5a52ccf64ce7	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	2026-09-14	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-14 08:00:00+07	2026-09-14 16:00:00+07	MANUAL	\N	2026-10-04 23:23:53.771+07
6deadbe3-74b4-4851-9f67-0760058c2e2a	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	2026-09-15	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-15 08:00:00+07	2026-09-15 16:00:00+07	MANUAL	\N	2026-10-04 23:23:53.774+07
b491f853-138d-411a-959b-3ff05f62b260	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	2026-09-16	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-16 08:00:00+07	2026-09-16 16:00:00+07	MANUAL	\N	2026-10-04 23:23:53.777+07
120cfe71-ae65-4b7e-b2a7-7d38d8b8fb87	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	2026-09-17	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-17 08:00:00+07	2026-09-17 16:00:00+07	MANUAL	\N	2026-10-04 23:23:53.78+07
eb8da9e4-4c7a-4855-a2d8-f056461f83f7	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	2026-09-18	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-18 08:00:00+07	2026-09-18 16:00:00+07	MANUAL	\N	2026-10-04 23:23:53.783+07
17c9cd5a-53eb-4807-b803-aa2cc32e2743	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	2026-09-19	OFFDAY	\N	\N	\N	MANUAL	\N	2026-10-04 23:23:53.786+07
3270b2d6-3765-4316-9ce0-a1562a978d23	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	2026-09-20	OFFDAY	\N	\N	\N	MANUAL	\N	2026-10-04 23:23:53.788+07
38f13078-3333-4d0d-afc8-41478afe5037	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	2026-09-21	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-21 08:00:00+07	2026-09-21 16:00:00+07	MANUAL	\N	2026-10-04 23:23:53.791+07
2b3f2482-89d4-4b02-90d8-5efc4758c8b7	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	2026-09-22	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-22 08:00:00+07	2026-09-22 16:00:00+07	MANUAL	\N	2026-10-04 23:23:53.794+07
a7b86739-5a6d-481b-a41b-1e964e885878	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	2026-09-23	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-23 08:00:00+07	2026-09-23 16:00:00+07	MANUAL	\N	2026-10-04 23:23:53.797+07
888f76d6-0db6-4c93-8723-a08052f70a97	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	2026-09-24	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-24 08:00:00+07	2026-09-24 16:00:00+07	MANUAL	\N	2026-10-04 23:23:53.801+07
9ac8b86a-b77a-40db-8c17-99ffcde0d119	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	2026-09-25	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-25 08:00:00+07	2026-09-25 16:00:00+07	MANUAL	\N	2026-10-04 23:23:53.804+07
ece5937b-083f-4c3f-8e27-60755c8ea78e	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	2026-09-26	OFFDAY	\N	\N	\N	MANUAL	\N	2026-10-04 23:23:53.807+07
537361df-274c-43e1-a733-2d26b1ba0037	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	2026-09-27	OFFDAY	\N	\N	\N	MANUAL	\N	2026-10-04 23:23:53.809+07
4c9f1e93-c974-4caa-a2ae-abc6a6e4d43d	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	2026-09-28	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-28 08:00:00+07	2026-09-28 16:00:00+07	MANUAL	\N	2026-10-04 23:23:53.811+07
7d514fb5-3dab-4862-b870-b5548e3980a4	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	2026-09-29	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-29 08:00:00+07	2026-09-29 16:00:00+07	MANUAL	\N	2026-10-04 23:23:53.815+07
e051a994-0d2a-42b2-9fbc-4890d579d68b	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	2026-09-30	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-30 08:00:00+07	2026-09-30 16:00:00+07	MANUAL	\N	2026-10-04 23:23:53.818+07
8f81055a-4351-4d3e-b70d-1e09969e2202	4478787b-c3e8-4f0d-8b9b-7046fec7f539	2026-09-02	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-02 08:00:00+07	2026-09-02 16:00:00+07	MANUAL	\N	2026-10-04 23:23:53.825+07
f1ed1c11-a4cf-40bf-ae44-b1f6dd89681b	4478787b-c3e8-4f0d-8b9b-7046fec7f539	2026-09-03	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-03 08:00:00+07	2026-09-03 16:00:00+07	MANUAL	\N	2026-10-04 23:23:53.828+07
c91f4b3a-fb1b-42da-ad15-e33bfe3c6ee4	4478787b-c3e8-4f0d-8b9b-7046fec7f539	2026-09-04	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-04 08:00:00+07	2026-09-04 16:00:00+07	MANUAL	\N	2026-10-04 23:23:53.831+07
b0a8888d-2121-4243-bca3-1ad918ccea92	4478787b-c3e8-4f0d-8b9b-7046fec7f539	2026-09-05	OFFDAY	\N	\N	\N	MANUAL	\N	2026-10-04 23:23:53.834+07
6090d225-e27d-4ead-b05b-54bdcc3a566f	4478787b-c3e8-4f0d-8b9b-7046fec7f539	2026-09-06	OFFDAY	\N	\N	\N	MANUAL	\N	2026-10-04 23:23:53.836+07
42dbc843-d7ff-47ce-905c-c19517cf1c52	4478787b-c3e8-4f0d-8b9b-7046fec7f539	2026-09-07	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-07 08:00:00+07	2026-09-07 16:00:00+07	MANUAL	\N	2026-10-04 23:23:53.84+07
e75317fb-0e38-4b3d-b19a-f126a7b90bff	4478787b-c3e8-4f0d-8b9b-7046fec7f539	2026-09-08	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-08 08:00:00+07	2026-09-08 16:00:00+07	MANUAL	\N	2026-10-04 23:23:53.843+07
09017fe1-4aca-4146-985f-a50cbbb1ea22	4478787b-c3e8-4f0d-8b9b-7046fec7f539	2026-09-09	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-09 08:00:00+07	2026-09-09 16:00:00+07	MANUAL	\N	2026-10-04 23:23:53.853+07
2d89e618-d42b-448c-9697-fe8ad7e9bb6b	4478787b-c3e8-4f0d-8b9b-7046fec7f539	2026-09-10	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-10 08:00:00+07	2026-09-10 16:00:00+07	MANUAL	\N	2026-10-04 23:23:53.858+07
b35719a7-b4c4-4447-8ceb-f2350a56be98	4478787b-c3e8-4f0d-8b9b-7046fec7f539	2026-09-11	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-11 08:00:00+07	2026-09-11 16:00:00+07	MANUAL	\N	2026-10-04 23:23:53.863+07
180809b3-ba82-4214-9066-49a5b2016a1d	4478787b-c3e8-4f0d-8b9b-7046fec7f539	2026-09-12	OFFDAY	\N	\N	\N	MANUAL	\N	2026-10-04 23:23:53.869+07
a01536b5-9a07-414b-b3fe-d3fad4c71273	4478787b-c3e8-4f0d-8b9b-7046fec7f539	2026-09-13	OFFDAY	\N	\N	\N	MANUAL	\N	2026-10-04 23:23:53.871+07
2ef5c24b-cfbd-4d72-a36c-d883385a602b	4478787b-c3e8-4f0d-8b9b-7046fec7f539	2026-09-14	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-14 08:00:00+07	2026-09-14 16:00:00+07	MANUAL	\N	2026-10-04 23:23:53.875+07
c8a3edb0-e210-462a-863d-4b9487305761	4478787b-c3e8-4f0d-8b9b-7046fec7f539	2026-09-15	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-15 08:00:00+07	2026-09-15 16:00:00+07	MANUAL	\N	2026-10-04 23:23:53.878+07
f27fa633-8bf7-48ee-8790-da5a57eacf1e	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	2026-09-02	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-02 08:00:00+07	2026-09-02 16:00:00+07	MANUAL	\N	2026-10-04 23:23:53.734+07
5d5f47f0-2f39-43e7-904d-f3099e9842fe	4478787b-c3e8-4f0d-8b9b-7046fec7f539	2026-09-18	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-18 08:00:00+07	2026-09-18 16:00:00+07	MANUAL	\N	2026-10-04 23:23:53.888+07
f5595eff-f99c-4d6c-9be8-c56497d0f22d	4478787b-c3e8-4f0d-8b9b-7046fec7f539	2026-09-19	OFFDAY	\N	\N	\N	MANUAL	\N	2026-10-04 23:23:53.891+07
01b8b2a3-9205-4198-a4b8-30754e931a29	4478787b-c3e8-4f0d-8b9b-7046fec7f539	2026-09-20	OFFDAY	\N	\N	\N	MANUAL	\N	2026-10-04 23:23:53.893+07
0694bb9a-39c6-44cc-839a-04e5104646a4	4478787b-c3e8-4f0d-8b9b-7046fec7f539	2026-09-21	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-21 08:00:00+07	2026-09-21 16:00:00+07	MANUAL	\N	2026-10-04 23:23:53.896+07
df3d188d-0c65-4889-a8df-9878022da0d8	4478787b-c3e8-4f0d-8b9b-7046fec7f539	2026-09-22	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-22 08:00:00+07	2026-09-22 16:00:00+07	MANUAL	\N	2026-10-04 23:23:53.899+07
6584ae8a-decf-405d-bb9b-d5a1a24e8768	4478787b-c3e8-4f0d-8b9b-7046fec7f539	2026-09-23	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-23 08:00:00+07	2026-09-23 16:00:00+07	MANUAL	\N	2026-10-04 23:23:53.903+07
e12d10ba-94a5-4d7f-b6cd-1eea29b371e3	4478787b-c3e8-4f0d-8b9b-7046fec7f539	2026-09-24	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-24 08:00:00+07	2026-09-24 16:00:00+07	MANUAL	\N	2026-10-04 23:23:53.907+07
7d49aad8-8d02-418f-bb5d-6cf9cc30b958	4478787b-c3e8-4f0d-8b9b-7046fec7f539	2026-09-25	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-25 08:00:00+07	2026-09-25 16:00:00+07	MANUAL	\N	2026-10-04 23:23:53.91+07
b1a821cf-710f-41ea-8fce-0ae5eeaa9ef0	4478787b-c3e8-4f0d-8b9b-7046fec7f539	2026-09-26	OFFDAY	\N	\N	\N	MANUAL	\N	2026-10-04 23:23:53.912+07
fa7152b1-d452-4ef4-92f9-b427dc3da44b	4478787b-c3e8-4f0d-8b9b-7046fec7f539	2026-09-27	OFFDAY	\N	\N	\N	MANUAL	\N	2026-10-04 23:23:53.914+07
46475f48-04d7-48ff-ab0a-c576c43c1c95	4478787b-c3e8-4f0d-8b9b-7046fec7f539	2026-09-28	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-28 08:00:00+07	2026-09-28 16:00:00+07	MANUAL	\N	2026-10-04 23:23:53.918+07
a557d4d2-a143-4e19-b387-ef40d7980a3f	4478787b-c3e8-4f0d-8b9b-7046fec7f539	2026-09-29	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-29 08:00:00+07	2026-09-29 16:00:00+07	MANUAL	\N	2026-10-04 23:23:53.921+07
fb596159-2074-494f-b849-dd500837c40c	4478787b-c3e8-4f0d-8b9b-7046fec7f539	2026-09-30	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-30 08:00:00+07	2026-09-30 16:00:00+07	MANUAL	\N	2026-10-04 23:23:53.924+07
b3445093-7dd9-4302-8975-677fc3083e63	0cd6bde6-3226-4ebb-b135-ca522d42efa4	2026-09-01	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-01 08:00:00+07	2026-09-01 16:00:00+07	MANUAL	\N	2026-10-04 23:23:53.927+07
3fd72a23-a2b3-4e35-8288-f4f8f8960149	0cd6bde6-3226-4ebb-b135-ca522d42efa4	2026-09-02	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-02 08:00:00+07	2026-09-02 16:00:00+07	MANUAL	\N	2026-10-04 23:23:53.93+07
d29fd595-0226-40c9-84e4-cc0c02c4a0c5	0cd6bde6-3226-4ebb-b135-ca522d42efa4	2026-09-03	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-03 08:00:00+07	2026-09-03 16:00:00+07	MANUAL	\N	2026-10-04 23:23:53.934+07
5027c6a4-b309-4bea-ac65-7c32b4319ebe	0cd6bde6-3226-4ebb-b135-ca522d42efa4	2026-09-04	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-04 08:00:00+07	2026-09-04 16:00:00+07	MANUAL	\N	2026-10-04 23:23:53.937+07
5d401f08-4f17-4fe5-828b-e965ef24e924	0cd6bde6-3226-4ebb-b135-ca522d42efa4	2026-09-05	OFFDAY	\N	\N	\N	MANUAL	\N	2026-10-04 23:23:53.939+07
26aa7938-2c65-4941-9878-b9deae34db3c	0cd6bde6-3226-4ebb-b135-ca522d42efa4	2026-09-06	OFFDAY	\N	\N	\N	MANUAL	\N	2026-10-04 23:23:53.942+07
74434e40-8229-4660-abc0-64ceea1a0897	0cd6bde6-3226-4ebb-b135-ca522d42efa4	2026-09-07	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-07 08:00:00+07	2026-09-07 16:00:00+07	MANUAL	\N	2026-10-04 23:23:53.944+07
58e493fe-145e-45a5-bae1-5afb85d9b224	0cd6bde6-3226-4ebb-b135-ca522d42efa4	2026-09-08	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-08 08:00:00+07	2026-09-08 16:00:00+07	MANUAL	\N	2026-10-04 23:23:53.948+07
346c1466-8847-41a7-98a2-2a1b23250c9e	0cd6bde6-3226-4ebb-b135-ca522d42efa4	2026-09-09	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-09 08:00:00+07	2026-09-09 16:00:00+07	MANUAL	\N	2026-10-04 23:23:53.951+07
e806d1fa-d53d-4b1d-af04-8379092c2544	0cd6bde6-3226-4ebb-b135-ca522d42efa4	2026-09-10	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-10 08:00:00+07	2026-09-10 16:00:00+07	MANUAL	\N	2026-10-04 23:23:53.955+07
3f4990f7-53b5-4913-b849-dab3aaef7012	0cd6bde6-3226-4ebb-b135-ca522d42efa4	2026-09-11	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-11 08:00:00+07	2026-09-11 16:00:00+07	MANUAL	\N	2026-10-04 23:23:53.958+07
9f6dfb09-f645-4dc4-910e-4e5695c65a4e	0cd6bde6-3226-4ebb-b135-ca522d42efa4	2026-09-12	OFFDAY	\N	\N	\N	MANUAL	\N	2026-10-04 23:23:53.96+07
d10bb270-f547-447b-b5ac-04fb3d55011e	0cd6bde6-3226-4ebb-b135-ca522d42efa4	2026-09-13	OFFDAY	\N	\N	\N	MANUAL	\N	2026-10-04 23:23:53.962+07
b216766c-eb6c-41bf-ab3c-d1d00cf733b7	0cd6bde6-3226-4ebb-b135-ca522d42efa4	2026-09-14	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-14 08:00:00+07	2026-09-14 16:00:00+07	MANUAL	\N	2026-10-04 23:23:53.965+07
fdd1d352-7f3d-4e63-bfca-d3b7af7ffbac	0cd6bde6-3226-4ebb-b135-ca522d42efa4	2026-09-15	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-15 08:00:00+07	2026-09-15 16:00:00+07	MANUAL	\N	2026-10-04 23:23:53.969+07
698aecbb-8031-49fe-ae72-9115b03eff24	0cd6bde6-3226-4ebb-b135-ca522d42efa4	2026-09-17	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-17 08:00:00+07	2026-09-17 16:00:00+07	MANUAL	\N	2026-10-04 23:23:53.976+07
197281e9-1ef7-4100-8100-aea9c366e172	0cd6bde6-3226-4ebb-b135-ca522d42efa4	2026-09-18	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-18 08:00:00+07	2026-09-18 16:00:00+07	MANUAL	\N	2026-10-04 23:23:53.979+07
5479367b-6f2d-414c-8fe7-ea4de81f754f	0cd6bde6-3226-4ebb-b135-ca522d42efa4	2026-09-19	OFFDAY	\N	\N	\N	MANUAL	\N	2026-10-04 23:23:53.981+07
c17840b9-7c9a-4153-b3a2-9629aac39cdb	0cd6bde6-3226-4ebb-b135-ca522d42efa4	2026-09-20	OFFDAY	\N	\N	\N	MANUAL	\N	2026-10-04 23:23:53.983+07
bfb17aee-a09b-4edb-aa22-8e7f50a40df9	0cd6bde6-3226-4ebb-b135-ca522d42efa4	2026-09-21	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-21 08:00:00+07	2026-09-21 16:00:00+07	MANUAL	\N	2026-10-04 23:23:53.987+07
40320fa1-e07f-4540-bca2-a6f7531bf0ed	0cd6bde6-3226-4ebb-b135-ca522d42efa4	2026-09-22	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-22 08:00:00+07	2026-09-22 16:00:00+07	MANUAL	\N	2026-10-04 23:23:53.99+07
94727c52-c6b1-4d7a-9ce6-268b7addf587	0cd6bde6-3226-4ebb-b135-ca522d42efa4	2026-09-23	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-23 08:00:00+07	2026-09-23 16:00:00+07	MANUAL	\N	2026-10-04 23:23:53.993+07
fc0e3e35-0660-4061-bc96-7cc2edae96dc	0cd6bde6-3226-4ebb-b135-ca522d42efa4	2026-09-24	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-24 08:00:00+07	2026-09-24 16:00:00+07	MANUAL	\N	2026-10-04 23:23:53.996+07
0bc113ad-383e-4503-9f78-8b5bdfc9766e	0cd6bde6-3226-4ebb-b135-ca522d42efa4	2026-09-25	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-25 08:00:00+07	2026-09-25 16:00:00+07	MANUAL	\N	2026-10-04 23:23:53.999+07
1db2a5ce-9e45-48bb-ac7b-bb997a9ff7af	0cd6bde6-3226-4ebb-b135-ca522d42efa4	2026-09-26	OFFDAY	\N	\N	\N	MANUAL	\N	2026-10-04 23:23:54.001+07
e2000b82-1c28-4596-9a57-091b80ef2bb5	0cd6bde6-3226-4ebb-b135-ca522d42efa4	2026-09-27	OFFDAY	\N	\N	\N	MANUAL	\N	2026-10-04 23:23:54.004+07
2058592a-03b0-4cd8-bf4e-ea0f1686b571	0cd6bde6-3226-4ebb-b135-ca522d42efa4	2026-09-28	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-28 08:00:00+07	2026-09-28 16:00:00+07	MANUAL	\N	2026-10-04 23:23:54.007+07
78379bca-133b-4a88-bf31-2041f85fa083	0cd6bde6-3226-4ebb-b135-ca522d42efa4	2026-09-29	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-29 08:00:00+07	2026-09-29 16:00:00+07	MANUAL	\N	2026-10-04 23:23:54.01+07
55c33d75-7d9d-4121-944c-27fcce1258f3	0cd6bde6-3226-4ebb-b135-ca522d42efa4	2026-09-30	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-30 08:00:00+07	2026-09-30 16:00:00+07	MANUAL	\N	2026-10-04 23:23:54.012+07
f50203e6-c152-43ea-b45b-b91f634cfe38	4478787b-c3e8-4f0d-8b9b-7046fec7f539	2026-09-17	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-17 08:00:00+07	2026-09-17 16:00:00+07	MANUAL	\N	2026-10-04 23:23:53.884+07
4daaf231-57a8-436e-b9d7-d25f02091365	0c685448-b52e-4e60-89ea-6f7c500a86d5	2026-09-03	WORKDAY	800c181b-ae0f-4ed1-876b-a7469ce4e922	2026-09-03 16:00:00+07	2026-09-04 00:00:00+07	MANUAL	\N	2026-10-04 23:23:54.022+07
9d266c58-742f-4022-b1cf-97e0ac859cf4	0c685448-b52e-4e60-89ea-6f7c500a86d5	2026-09-04	WORKDAY	800c181b-ae0f-4ed1-876b-a7469ce4e922	2026-09-04 16:00:00+07	2026-09-05 00:00:00+07	MANUAL	\N	2026-10-04 23:23:54.025+07
a67e63a3-9ac0-4798-a0a6-660ec72af842	0c685448-b52e-4e60-89ea-6f7c500a86d5	2026-09-05	OFFDAY	\N	\N	\N	MANUAL	\N	2026-10-04 23:23:54.027+07
888c0b18-9105-4cbc-b878-1381732d9e7a	0c685448-b52e-4e60-89ea-6f7c500a86d5	2026-09-06	OFFDAY	\N	\N	\N	MANUAL	\N	2026-10-04 23:23:54.029+07
ede2a82c-f0e1-4ed0-99af-c1124877aca8	0c685448-b52e-4e60-89ea-6f7c500a86d5	2026-09-07	WORKDAY	800c181b-ae0f-4ed1-876b-a7469ce4e922	2026-09-07 16:00:00+07	2026-09-08 00:00:00+07	MANUAL	\N	2026-10-04 23:23:54.032+07
7ed53a2b-af2d-42f2-bdd0-73479ec4a5dd	0c685448-b52e-4e60-89ea-6f7c500a86d5	2026-09-08	WORKDAY	800c181b-ae0f-4ed1-876b-a7469ce4e922	2026-09-08 16:00:00+07	2026-09-09 00:00:00+07	MANUAL	\N	2026-10-04 23:23:54.036+07
cba291c9-ceaf-4525-8c56-0f4a2b0ed140	0c685448-b52e-4e60-89ea-6f7c500a86d5	2026-09-09	WORKDAY	800c181b-ae0f-4ed1-876b-a7469ce4e922	2026-09-09 16:00:00+07	2026-09-10 00:00:00+07	MANUAL	\N	2026-10-04 23:23:54.039+07
56188485-176d-41c1-94ce-d4adbca856e3	0c685448-b52e-4e60-89ea-6f7c500a86d5	2026-09-10	WORKDAY	800c181b-ae0f-4ed1-876b-a7469ce4e922	2026-09-10 16:00:00+07	2026-09-11 00:00:00+07	MANUAL	\N	2026-10-04 23:23:54.042+07
f8ea5411-44a2-4cf4-b16e-abbb8abdc277	0c685448-b52e-4e60-89ea-6f7c500a86d5	2026-09-11	WORKDAY	800c181b-ae0f-4ed1-876b-a7469ce4e922	2026-09-11 16:00:00+07	2026-09-12 00:00:00+07	MANUAL	\N	2026-10-04 23:23:54.045+07
23fd2dff-8ffa-454b-a85f-63390e53d513	0c685448-b52e-4e60-89ea-6f7c500a86d5	2026-09-12	OFFDAY	\N	\N	\N	MANUAL	\N	2026-10-04 23:23:54.047+07
146c12fb-dea1-45cd-9d80-0fd9ea0350f9	0c685448-b52e-4e60-89ea-6f7c500a86d5	2026-09-13	OFFDAY	\N	\N	\N	MANUAL	\N	2026-10-04 23:23:54.049+07
56324069-0c08-41e1-81d4-3aec1aa3e03b	0c685448-b52e-4e60-89ea-6f7c500a86d5	2026-09-14	WORKDAY	800c181b-ae0f-4ed1-876b-a7469ce4e922	2026-09-14 16:00:00+07	2026-09-15 00:00:00+07	MANUAL	\N	2026-10-04 23:23:54.053+07
3b79141a-018b-4020-b324-e5f7bc89e3e2	0c685448-b52e-4e60-89ea-6f7c500a86d5	2026-09-15	WORKDAY	800c181b-ae0f-4ed1-876b-a7469ce4e922	2026-09-15 16:00:00+07	2026-09-16 00:00:00+07	MANUAL	\N	2026-10-04 23:23:54.057+07
e4631c8d-3a64-4be3-9527-73b4c3e75db0	0c685448-b52e-4e60-89ea-6f7c500a86d5	2026-09-16	WORKDAY	800c181b-ae0f-4ed1-876b-a7469ce4e922	2026-09-16 16:00:00+07	2026-09-17 00:00:00+07	MANUAL	\N	2026-10-04 23:23:54.06+07
fa9ed3cd-0148-4b21-bd7a-9329102e983c	0c685448-b52e-4e60-89ea-6f7c500a86d5	2026-09-17	WORKDAY	800c181b-ae0f-4ed1-876b-a7469ce4e922	2026-09-17 16:00:00+07	2026-09-18 00:00:00+07	MANUAL	\N	2026-10-04 23:23:54.064+07
35fb1cb8-5832-4118-85f1-c0c0fa078507	0c685448-b52e-4e60-89ea-6f7c500a86d5	2026-09-18	WORKDAY	800c181b-ae0f-4ed1-876b-a7469ce4e922	2026-09-18 16:00:00+07	2026-09-19 00:00:00+07	MANUAL	\N	2026-10-04 23:23:54.067+07
e7c80c50-06bc-45b4-825b-c373569d65b1	0c685448-b52e-4e60-89ea-6f7c500a86d5	2026-09-19	OFFDAY	\N	\N	\N	MANUAL	\N	2026-10-04 23:23:54.07+07
5b62653d-350b-4b95-b831-eec6368cdb6d	0c685448-b52e-4e60-89ea-6f7c500a86d5	2026-09-20	OFFDAY	\N	\N	\N	MANUAL	\N	2026-10-04 23:23:54.072+07
3d056fce-4734-4acc-906b-dbeb0a81a925	0c685448-b52e-4e60-89ea-6f7c500a86d5	2026-09-21	WORKDAY	800c181b-ae0f-4ed1-876b-a7469ce4e922	2026-09-21 16:00:00+07	2026-09-22 00:00:00+07	MANUAL	\N	2026-10-04 23:23:54.075+07
572a4e84-f252-4914-88c8-6ff6338dea18	0c685448-b52e-4e60-89ea-6f7c500a86d5	2026-09-22	WORKDAY	800c181b-ae0f-4ed1-876b-a7469ce4e922	2026-09-22 16:00:00+07	2026-09-23 00:00:00+07	MANUAL	\N	2026-10-04 23:23:54.078+07
c40ad11c-c3ac-49f5-afe9-cf3643d3c448	0c685448-b52e-4e60-89ea-6f7c500a86d5	2026-09-23	WORKDAY	800c181b-ae0f-4ed1-876b-a7469ce4e922	2026-09-23 16:00:00+07	2026-09-24 00:00:00+07	MANUAL	\N	2026-10-04 23:23:54.081+07
9d6ac409-648b-445d-a7b6-1a3ddac3f7a4	0c685448-b52e-4e60-89ea-6f7c500a86d5	2026-09-24	WORKDAY	800c181b-ae0f-4ed1-876b-a7469ce4e922	2026-09-24 16:00:00+07	2026-09-25 00:00:00+07	MANUAL	\N	2026-10-04 23:23:54.084+07
b6a3af3c-bd40-406c-b010-cb6150ec8529	0c685448-b52e-4e60-89ea-6f7c500a86d5	2026-09-25	WORKDAY	800c181b-ae0f-4ed1-876b-a7469ce4e922	2026-09-25 16:00:00+07	2026-09-26 00:00:00+07	MANUAL	\N	2026-10-04 23:23:54.088+07
baf2c3fb-bfbc-46d9-b9bf-0f11ec69fe34	0c685448-b52e-4e60-89ea-6f7c500a86d5	2026-09-26	OFFDAY	\N	\N	\N	MANUAL	\N	2026-10-04 23:23:54.09+07
0226be33-ad36-4fbc-a5d2-3b26cdb840d4	0c685448-b52e-4e60-89ea-6f7c500a86d5	2026-09-27	OFFDAY	\N	\N	\N	MANUAL	\N	2026-10-04 23:23:54.092+07
4b8e7577-024a-43d7-85b3-918e32a3ed08	0c685448-b52e-4e60-89ea-6f7c500a86d5	2026-09-28	WORKDAY	800c181b-ae0f-4ed1-876b-a7469ce4e922	2026-09-28 16:00:00+07	2026-09-29 00:00:00+07	MANUAL	\N	2026-10-04 23:23:54.095+07
13f791af-be74-45f9-945a-94d043f453c6	0c685448-b52e-4e60-89ea-6f7c500a86d5	2026-09-29	WORKDAY	800c181b-ae0f-4ed1-876b-a7469ce4e922	2026-09-29 16:00:00+07	2026-09-30 00:00:00+07	MANUAL	\N	2026-10-04 23:23:54.098+07
26a88fc0-3e81-4e3f-9cd4-9f063bf66343	0c685448-b52e-4e60-89ea-6f7c500a86d5	2026-09-30	WORKDAY	800c181b-ae0f-4ed1-876b-a7469ce4e922	2026-09-30 16:00:00+07	2026-10-01 00:00:00+07	MANUAL	\N	2026-10-04 23:23:54.101+07
770e7350-986c-45f1-aa5e-8178847756ab	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	2026-09-02	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-02 07:00:00+07	2026-09-02 15:00:00+07	MANUAL	\N	2026-10-04 23:23:54.108+07
b2ef4fd2-3a82-4197-8739-810166ec204e	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	2026-09-03	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-03 07:00:00+07	2026-09-03 15:00:00+07	MANUAL	\N	2026-10-04 23:23:54.111+07
f1e4df60-55f7-447f-a2d3-78b567e9c0ed	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	2026-09-04	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-04 07:00:00+07	2026-09-04 15:00:00+07	MANUAL	\N	2026-10-04 23:23:54.113+07
1d2a625c-d442-4fc0-b9a0-abe5182feb2c	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	2026-09-05	OFFDAY	\N	\N	\N	MANUAL	\N	2026-10-04 23:23:54.115+07
f9739d9e-7dfb-4fb8-8bca-57046b5ff7e1	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	2026-09-06	OFFDAY	\N	\N	\N	MANUAL	\N	2026-10-04 23:23:54.118+07
1f0f90a4-1934-40ed-845f-bd4a6ccad772	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	2026-09-07	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-07 07:00:00+07	2026-09-07 15:00:00+07	MANUAL	\N	2026-10-04 23:23:54.122+07
443c5d0a-6aee-43ab-b489-79c3d881148d	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	2026-09-08	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-08 07:00:00+07	2026-09-08 15:00:00+07	MANUAL	\N	2026-10-04 23:23:54.126+07
ed43b97c-b5b7-4a94-97b3-1f2ab4f4f425	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	2026-09-09	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-09 07:00:00+07	2026-09-09 15:00:00+07	MANUAL	\N	2026-10-04 23:23:54.13+07
4b9ad3d2-9757-4146-bbec-dfb882f4ec36	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	2026-09-10	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-10 07:00:00+07	2026-09-10 15:00:00+07	MANUAL	\N	2026-10-04 23:23:54.134+07
5fbe5209-2383-4d65-b9fe-e5f3bfd9fcbe	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	2026-09-11	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-11 07:00:00+07	2026-09-11 15:00:00+07	MANUAL	\N	2026-10-04 23:23:54.138+07
3a953954-351d-4e64-8787-3ae35b3f33a2	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	2026-09-12	OFFDAY	\N	\N	\N	MANUAL	\N	2026-10-04 23:23:54.141+07
f100b369-ba6d-4354-874c-6168f8263159	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	2026-09-13	OFFDAY	\N	\N	\N	MANUAL	\N	2026-10-04 23:23:54.144+07
b398f633-6097-4bbc-b4f5-1bb262db1049	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	2026-09-14	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-14 07:00:00+07	2026-09-14 15:00:00+07	MANUAL	\N	2026-10-04 23:23:54.147+07
36e70c78-ce5a-4a45-877c-27b47d473d0a	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	2026-09-15	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-15 07:00:00+07	2026-09-15 15:00:00+07	MANUAL	\N	2026-10-04 23:23:54.15+07
cd09d668-6cbe-478e-a1b4-a591a647e7c2	0c685448-b52e-4e60-89ea-6f7c500a86d5	2026-09-02	WORKDAY	800c181b-ae0f-4ed1-876b-a7469ce4e922	2026-09-02 16:00:00+07	2026-09-03 00:00:00+07	MANUAL	\N	2026-10-04 23:23:54.019+07
a98233e8-ef1d-449e-945f-b62ed1dec2f9	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	2026-09-18	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-18 07:00:00+07	2026-09-18 15:00:00+07	MANUAL	\N	2026-10-04 23:23:54.163+07
87f88249-b054-491b-b463-fb4c94d8c43c	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	2026-09-19	OFFDAY	\N	\N	\N	MANUAL	\N	2026-10-04 23:23:54.166+07
8254dc5d-6e8b-4410-b0e7-d1a67be78644	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	2026-09-20	OFFDAY	\N	\N	\N	MANUAL	\N	2026-10-04 23:23:54.169+07
91389623-6285-4dc3-8ae9-6d69b677491b	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	2026-09-21	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-21 07:00:00+07	2026-09-21 15:00:00+07	MANUAL	\N	2026-10-04 23:23:54.173+07
9dce120c-26c0-43a1-9f74-35cbe8773845	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	2026-09-22	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-22 07:00:00+07	2026-09-22 15:00:00+07	MANUAL	\N	2026-10-04 23:23:54.177+07
53b808c9-0802-4579-a200-33003ad7e586	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	2026-09-23	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-23 07:00:00+07	2026-09-23 15:00:00+07	MANUAL	\N	2026-10-04 23:23:54.181+07
3af87593-35af-4fb7-9c44-d3cd4f165580	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	2026-09-24	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-24 07:00:00+07	2026-09-24 15:00:00+07	MANUAL	\N	2026-10-04 23:23:54.186+07
a517642c-1514-444a-8234-fccb0a56cd3e	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	2026-09-25	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-25 07:00:00+07	2026-09-25 15:00:00+07	MANUAL	\N	2026-10-04 23:23:54.192+07
7b9806dd-ecb2-4e3d-aab9-7ab8ebc125fc	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	2026-09-26	OFFDAY	\N	\N	\N	MANUAL	\N	2026-10-04 23:23:54.195+07
9b0069b2-fcb8-443e-8d21-5fd60cffb523	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	2026-09-27	OFFDAY	\N	\N	\N	MANUAL	\N	2026-10-04 23:23:54.198+07
dd3e0a05-e9c9-41ed-88d1-179de0c57160	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	2026-09-28	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-28 07:00:00+07	2026-09-28 15:00:00+07	MANUAL	\N	2026-10-04 23:23:54.202+07
a4880fc6-8358-48aa-ace5-cafed082afc1	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	2026-09-29	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-29 07:00:00+07	2026-09-29 15:00:00+07	MANUAL	\N	2026-10-04 23:23:54.206+07
3fc49db8-1185-4d3d-8e1e-ae194e2bdeea	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	2026-09-30	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-30 07:00:00+07	2026-09-30 15:00:00+07	MANUAL	\N	2026-10-04 23:23:54.21+07
1dcdd685-44bd-4de6-8267-ef71623f92a2	3193d9a5-6017-4441-b40c-f22e9ec9b867	2026-09-01	WORKDAY	100b29e1-4d05-4a8b-90c5-0d51284ed21e	2026-09-01 21:00:00+07	2026-09-02 05:00:00+07	MANUAL	\N	2026-10-04 23:23:54.214+07
5889ac00-a34c-42d2-9b8e-b8d17dcabb21	3193d9a5-6017-4441-b40c-f22e9ec9b867	2026-09-02	WORKDAY	100b29e1-4d05-4a8b-90c5-0d51284ed21e	2026-09-02 21:00:00+07	2026-09-03 05:00:00+07	MANUAL	\N	2026-10-04 23:23:54.218+07
f468e97d-67d6-4d22-8173-c549c18708ab	3193d9a5-6017-4441-b40c-f22e9ec9b867	2026-09-03	WORKDAY	100b29e1-4d05-4a8b-90c5-0d51284ed21e	2026-09-03 21:00:00+07	2026-09-04 05:00:00+07	MANUAL	\N	2026-10-04 23:23:54.222+07
d9d7baed-85ae-4b37-a880-83673f46bcad	3193d9a5-6017-4441-b40c-f22e9ec9b867	2026-09-04	WORKDAY	100b29e1-4d05-4a8b-90c5-0d51284ed21e	2026-09-04 21:00:00+07	2026-09-05 05:00:00+07	MANUAL	\N	2026-10-04 23:23:54.226+07
90c7cbbb-4083-4c87-93e9-5673d0a06e74	3193d9a5-6017-4441-b40c-f22e9ec9b867	2026-09-05	OFFDAY	\N	\N	\N	MANUAL	\N	2026-10-04 23:23:54.229+07
0c6d44da-06de-45dd-afae-001de1306657	3193d9a5-6017-4441-b40c-f22e9ec9b867	2026-09-06	OFFDAY	\N	\N	\N	MANUAL	\N	2026-10-04 23:23:54.231+07
ede65b17-fc0d-4046-b0e9-eb042a251256	3193d9a5-6017-4441-b40c-f22e9ec9b867	2026-09-07	WORKDAY	100b29e1-4d05-4a8b-90c5-0d51284ed21e	2026-09-07 21:00:00+07	2026-09-08 05:00:00+07	MANUAL	\N	2026-10-04 23:23:54.235+07
312b48c4-75ea-495b-8057-ccf1f259fc09	3193d9a5-6017-4441-b40c-f22e9ec9b867	2026-09-08	WORKDAY	100b29e1-4d05-4a8b-90c5-0d51284ed21e	2026-09-08 21:00:00+07	2026-09-09 05:00:00+07	MANUAL	\N	2026-10-04 23:23:54.239+07
5f5283e0-f025-4e09-a591-551c9d512f6f	3193d9a5-6017-4441-b40c-f22e9ec9b867	2026-09-09	WORKDAY	100b29e1-4d05-4a8b-90c5-0d51284ed21e	2026-09-09 21:00:00+07	2026-09-10 05:00:00+07	MANUAL	\N	2026-10-04 23:23:54.243+07
f7dd410f-bf74-462b-ab18-a36774ac01b9	3193d9a5-6017-4441-b40c-f22e9ec9b867	2026-09-10	WORKDAY	100b29e1-4d05-4a8b-90c5-0d51284ed21e	2026-09-10 21:00:00+07	2026-09-11 05:00:00+07	MANUAL	\N	2026-10-04 23:23:54.246+07
f28092ab-3205-422e-921f-977ea479f336	3193d9a5-6017-4441-b40c-f22e9ec9b867	2026-09-11	WORKDAY	100b29e1-4d05-4a8b-90c5-0d51284ed21e	2026-09-11 21:00:00+07	2026-09-12 05:00:00+07	MANUAL	\N	2026-10-04 23:23:54.25+07
191d77c4-9995-42ed-b1cc-98234bda85dd	3193d9a5-6017-4441-b40c-f22e9ec9b867	2026-09-12	OFFDAY	\N	\N	\N	MANUAL	\N	2026-10-04 23:23:54.254+07
d1f30947-a287-40ae-bef3-5358500296d8	3193d9a5-6017-4441-b40c-f22e9ec9b867	2026-09-13	OFFDAY	\N	\N	\N	MANUAL	\N	2026-10-04 23:23:54.257+07
83490c07-62dc-46c0-a792-d26211e50e1d	3193d9a5-6017-4441-b40c-f22e9ec9b867	2026-09-14	WORKDAY	100b29e1-4d05-4a8b-90c5-0d51284ed21e	2026-09-14 21:00:00+07	2026-09-15 05:00:00+07	MANUAL	\N	2026-10-04 23:23:54.261+07
1206e0ae-1ab7-4304-96c3-5a131eed57bc	3193d9a5-6017-4441-b40c-f22e9ec9b867	2026-09-15	WORKDAY	100b29e1-4d05-4a8b-90c5-0d51284ed21e	2026-09-15 21:00:00+07	2026-09-16 05:00:00+07	MANUAL	\N	2026-10-04 23:23:54.264+07
cc0f4773-7e7a-4e11-b2ab-6a47a8a3e520	3193d9a5-6017-4441-b40c-f22e9ec9b867	2026-09-17	WORKDAY	100b29e1-4d05-4a8b-90c5-0d51284ed21e	2026-09-17 21:00:00+07	2026-09-18 05:00:00+07	MANUAL	\N	2026-10-04 23:23:54.272+07
5743b8d8-4d99-42d7-8f4f-3ddc262566d5	3193d9a5-6017-4441-b40c-f22e9ec9b867	2026-09-18	WORKDAY	100b29e1-4d05-4a8b-90c5-0d51284ed21e	2026-09-18 21:00:00+07	2026-09-19 05:00:00+07	MANUAL	\N	2026-10-04 23:23:54.276+07
2280e699-0d62-47c7-8f85-8dff7b68b660	3193d9a5-6017-4441-b40c-f22e9ec9b867	2026-09-19	OFFDAY	\N	\N	\N	MANUAL	\N	2026-10-04 23:23:54.279+07
28deea8c-c0e3-497a-9490-a12909c008e0	3193d9a5-6017-4441-b40c-f22e9ec9b867	2026-09-20	OFFDAY	\N	\N	\N	MANUAL	\N	2026-10-04 23:23:54.281+07
9c1d6e58-9093-455e-bf0b-63e7c42503b9	3193d9a5-6017-4441-b40c-f22e9ec9b867	2026-09-21	WORKDAY	100b29e1-4d05-4a8b-90c5-0d51284ed21e	2026-09-21 21:00:00+07	2026-09-22 05:00:00+07	MANUAL	\N	2026-10-04 23:23:54.285+07
904133e9-6a04-44e5-b181-a9f5730644b4	3193d9a5-6017-4441-b40c-f22e9ec9b867	2026-09-22	WORKDAY	100b29e1-4d05-4a8b-90c5-0d51284ed21e	2026-09-22 21:00:00+07	2026-09-23 05:00:00+07	MANUAL	\N	2026-10-04 23:23:54.29+07
8d466c04-2234-4e46-b459-d2f22f2b21de	3193d9a5-6017-4441-b40c-f22e9ec9b867	2026-09-23	WORKDAY	100b29e1-4d05-4a8b-90c5-0d51284ed21e	2026-09-23 21:00:00+07	2026-09-24 05:00:00+07	MANUAL	\N	2026-10-04 23:23:54.293+07
6c951860-da2f-41f6-b3e4-375f98e800c4	3193d9a5-6017-4441-b40c-f22e9ec9b867	2026-09-24	WORKDAY	100b29e1-4d05-4a8b-90c5-0d51284ed21e	2026-09-24 21:00:00+07	2026-09-25 05:00:00+07	MANUAL	\N	2026-10-04 23:23:54.296+07
7908f9d6-8b9c-49dc-b8a4-177b0a373bad	3193d9a5-6017-4441-b40c-f22e9ec9b867	2026-09-25	WORKDAY	100b29e1-4d05-4a8b-90c5-0d51284ed21e	2026-09-25 21:00:00+07	2026-09-26 05:00:00+07	MANUAL	\N	2026-10-04 23:23:54.3+07
d24700dc-ef8c-44e5-b2e8-b4ac771dffbf	3193d9a5-6017-4441-b40c-f22e9ec9b867	2026-09-26	OFFDAY	\N	\N	\N	MANUAL	\N	2026-10-04 23:23:54.304+07
955574c3-497d-49ed-a03d-c6196b4df193	3193d9a5-6017-4441-b40c-f22e9ec9b867	2026-09-27	OFFDAY	\N	\N	\N	MANUAL	\N	2026-10-04 23:23:54.306+07
673940d7-e0fd-47d9-adea-584c65635431	3193d9a5-6017-4441-b40c-f22e9ec9b867	2026-09-28	WORKDAY	100b29e1-4d05-4a8b-90c5-0d51284ed21e	2026-09-28 21:00:00+07	2026-09-29 05:00:00+07	MANUAL	\N	2026-10-04 23:23:54.31+07
b2880453-8d27-4c2f-ba23-42b6cabea3c9	3193d9a5-6017-4441-b40c-f22e9ec9b867	2026-09-29	WORKDAY	100b29e1-4d05-4a8b-90c5-0d51284ed21e	2026-09-29 21:00:00+07	2026-09-30 05:00:00+07	MANUAL	\N	2026-10-04 23:23:54.314+07
a8f2f05e-3afc-4580-9e06-4555c549064f	3193d9a5-6017-4441-b40c-f22e9ec9b867	2026-09-30	WORKDAY	100b29e1-4d05-4a8b-90c5-0d51284ed21e	2026-09-30 21:00:00+07	2026-10-01 05:00:00+07	MANUAL	\N	2026-10-04 23:23:54.317+07
8331b805-1bf6-41dd-8c19-b35c4f016717	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	2026-09-17	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-17 07:00:00+07	2026-09-17 15:00:00+07	MANUAL	\N	2026-10-04 23:23:54.159+07
942924a4-bfd5-4eca-afa1-e23526ad946a	b7291f79-3495-44a5-b039-737465dc2cc0	2026-09-03	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-03 08:00:00+07	2026-09-03 16:00:00+07	MANUAL	\N	2026-10-04 23:23:54.328+07
e867c716-4393-4fea-b613-24b9bc0e3f42	b7291f79-3495-44a5-b039-737465dc2cc0	2026-09-04	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-04 08:00:00+07	2026-09-04 16:00:00+07	MANUAL	\N	2026-10-04 23:23:54.331+07
e568c6e1-1c9b-4ec0-9fa1-155f355badf9	b7291f79-3495-44a5-b039-737465dc2cc0	2026-09-05	OFFDAY	\N	\N	\N	MANUAL	\N	2026-10-04 23:23:54.334+07
05bf2276-7f7b-4b64-b510-95e99774e7be	b7291f79-3495-44a5-b039-737465dc2cc0	2026-09-07	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-07 08:00:00+07	2026-09-07 16:00:00+07	MANUAL	\N	2026-10-04 23:23:54.34+07
09bba67d-f3c4-4676-a4ea-2903b4744f66	b7291f79-3495-44a5-b039-737465dc2cc0	2026-09-08	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-08 08:00:00+07	2026-09-08 16:00:00+07	MANUAL	\N	2026-10-04 23:23:54.346+07
def8f9ff-f6e0-40ae-9db1-7700008e3382	b7291f79-3495-44a5-b039-737465dc2cc0	2026-09-09	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-09 08:00:00+07	2026-09-09 16:00:00+07	MANUAL	\N	2026-10-04 23:23:54.35+07
a11629af-8c3f-47f8-a20b-9ebaf4d37ab4	b7291f79-3495-44a5-b039-737465dc2cc0	2026-09-10	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-10 08:00:00+07	2026-09-10 16:00:00+07	MANUAL	\N	2026-10-04 23:23:54.354+07
44750f36-d124-432b-a940-70ec5c58b17a	b7291f79-3495-44a5-b039-737465dc2cc0	2026-09-11	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-11 08:00:00+07	2026-09-11 16:00:00+07	MANUAL	\N	2026-10-04 23:23:54.359+07
5376c741-395a-4f04-ba6b-a38ec12a5f34	b7291f79-3495-44a5-b039-737465dc2cc0	2026-09-12	OFFDAY	\N	\N	\N	MANUAL	\N	2026-10-04 23:23:54.362+07
d861d3f7-0712-4c1e-8ef0-a262cf6a92c5	b7291f79-3495-44a5-b039-737465dc2cc0	2026-09-13	OFFDAY	\N	\N	\N	MANUAL	\N	2026-10-04 23:23:54.365+07
263f964f-a27a-4e44-9dd4-976a7749f78a	b7291f79-3495-44a5-b039-737465dc2cc0	2026-09-14	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-14 08:00:00+07	2026-09-14 16:00:00+07	MANUAL	\N	2026-10-04 23:23:54.37+07
5206ccfc-97cc-4291-accb-35c55a64a8bf	b7291f79-3495-44a5-b039-737465dc2cc0	2026-09-15	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-15 08:00:00+07	2026-09-15 16:00:00+07	MANUAL	\N	2026-10-04 23:23:54.374+07
2a16ce3a-1ade-4230-9272-934ad8001951	b7291f79-3495-44a5-b039-737465dc2cc0	2026-09-17	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-17 08:00:00+07	2026-09-17 16:00:00+07	MANUAL	\N	2026-10-04 23:23:54.381+07
bf9f1339-9156-4166-bc0a-41cbc5dd729e	b7291f79-3495-44a5-b039-737465dc2cc0	2026-09-18	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-18 08:00:00+07	2026-09-18 16:00:00+07	MANUAL	\N	2026-10-04 23:23:54.384+07
4d20e98d-5854-49b8-a1ca-96cb1ee76faf	b7291f79-3495-44a5-b039-737465dc2cc0	2026-09-19	OFFDAY	\N	\N	\N	MANUAL	\N	2026-10-04 23:23:54.387+07
fb5cc597-d0c9-4397-8048-bb6905caec50	b7291f79-3495-44a5-b039-737465dc2cc0	2026-09-20	OFFDAY	\N	\N	\N	MANUAL	\N	2026-10-04 23:23:54.39+07
347f3bfa-986d-47a6-95da-9550a489c230	b7291f79-3495-44a5-b039-737465dc2cc0	2026-09-21	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-21 08:00:00+07	2026-09-21 16:00:00+07	MANUAL	\N	2026-10-04 23:23:54.393+07
24cd476d-b95e-4682-871c-059eccfc3c50	b7291f79-3495-44a5-b039-737465dc2cc0	2026-09-22	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-22 08:00:00+07	2026-09-22 16:00:00+07	MANUAL	\N	2026-10-04 23:23:54.396+07
7f03bfc1-8716-4ad5-b770-613d9137825a	b7291f79-3495-44a5-b039-737465dc2cc0	2026-09-23	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-23 08:00:00+07	2026-09-23 16:00:00+07	MANUAL	\N	2026-10-04 23:23:54.4+07
49fb9023-7835-464d-b426-da962569287b	b7291f79-3495-44a5-b039-737465dc2cc0	2026-09-24	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-24 08:00:00+07	2026-09-24 16:00:00+07	MANUAL	\N	2026-10-04 23:23:54.404+07
814273b9-ab54-4b46-9084-4642cbb989f7	b7291f79-3495-44a5-b039-737465dc2cc0	2026-09-25	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-25 08:00:00+07	2026-09-25 16:00:00+07	MANUAL	\N	2026-10-04 23:23:54.407+07
ee3c9ba8-de8b-40e0-a35a-217b326c7bd9	b7291f79-3495-44a5-b039-737465dc2cc0	2026-09-26	OFFDAY	\N	\N	\N	MANUAL	\N	2026-10-04 23:23:54.41+07
83763480-4216-4b50-b33f-4517a73091bc	b7291f79-3495-44a5-b039-737465dc2cc0	2026-09-27	OFFDAY	\N	\N	\N	MANUAL	\N	2026-10-04 23:23:54.412+07
6cf12386-999c-4790-99c1-777122b57e5e	b7291f79-3495-44a5-b039-737465dc2cc0	2026-09-28	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-28 08:00:00+07	2026-09-28 16:00:00+07	MANUAL	\N	2026-10-04 23:23:54.415+07
3ca79ed4-0611-46d6-b9c3-f4b9a13fbdaa	b7291f79-3495-44a5-b039-737465dc2cc0	2026-09-29	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-29 08:00:00+07	2026-09-29 16:00:00+07	MANUAL	\N	2026-10-04 23:23:54.419+07
e22f78fb-e85b-4b35-87fc-6260c3f4254d	b7291f79-3495-44a5-b039-737465dc2cc0	2026-09-30	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-30 08:00:00+07	2026-09-30 16:00:00+07	MANUAL	\N	2026-10-04 23:23:54.423+07
236230f7-4dfb-48c1-8dee-504843973d4a	23230ce1-1ab7-4b49-b9b2-404f149e00ca	2026-09-01	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-01 06:00:00+07	2026-09-01 14:00:00+07	MANUAL	\N	2026-10-04 23:23:54.426+07
f819f74e-c019-4226-b11a-8827eb7c9a8a	23230ce1-1ab7-4b49-b9b2-404f149e00ca	2026-09-02	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-02 06:00:00+07	2026-09-02 14:00:00+07	MANUAL	\N	2026-10-04 23:23:54.429+07
df6a6290-f1c2-4a00-88b2-d104f5e00b6d	23230ce1-1ab7-4b49-b9b2-404f149e00ca	2026-09-03	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-03 06:00:00+07	2026-09-03 14:00:00+07	MANUAL	\N	2026-10-04 23:23:54.432+07
365e8ad0-c666-4c99-a2e4-5455349c9179	23230ce1-1ab7-4b49-b9b2-404f149e00ca	2026-09-04	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-04 06:00:00+07	2026-09-04 14:00:00+07	MANUAL	\N	2026-10-04 23:23:54.436+07
91dc1c2c-c775-45a6-af06-7c3aa0f3702f	23230ce1-1ab7-4b49-b9b2-404f149e00ca	2026-09-05	OFFDAY	\N	\N	\N	MANUAL	\N	2026-10-04 23:23:54.438+07
a8b35df5-c356-487b-b386-00d27ef9f541	23230ce1-1ab7-4b49-b9b2-404f149e00ca	2026-09-06	OFFDAY	\N	\N	\N	MANUAL	\N	2026-10-04 23:23:54.441+07
1eff43ce-a1ee-4a73-affc-362160a8b05b	23230ce1-1ab7-4b49-b9b2-404f149e00ca	2026-09-07	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-07 06:00:00+07	2026-09-07 14:00:00+07	MANUAL	\N	2026-10-04 23:23:54.445+07
a137163c-9fac-4cda-bc3a-a48251bbabb8	23230ce1-1ab7-4b49-b9b2-404f149e00ca	2026-09-08	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-08 06:00:00+07	2026-09-08 14:00:00+07	MANUAL	\N	2026-10-04 23:23:54.448+07
6764c45d-0509-477d-acc9-e8cbf97c723d	23230ce1-1ab7-4b49-b9b2-404f149e00ca	2026-09-09	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-09 06:00:00+07	2026-09-09 14:00:00+07	MANUAL	\N	2026-10-04 23:23:54.452+07
30ae6274-88c2-4934-ae9c-69fe25298839	23230ce1-1ab7-4b49-b9b2-404f149e00ca	2026-09-10	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-10 06:00:00+07	2026-09-10 14:00:00+07	MANUAL	\N	2026-10-04 23:23:54.456+07
c8e79ce8-7a88-4d77-8b71-95892bc3e5e4	23230ce1-1ab7-4b49-b9b2-404f149e00ca	2026-09-11	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-11 06:00:00+07	2026-09-11 14:00:00+07	MANUAL	\N	2026-10-04 23:23:54.459+07
02349674-3b42-48c6-af9f-d6e0e21198ce	23230ce1-1ab7-4b49-b9b2-404f149e00ca	2026-09-12	OFFDAY	\N	\N	\N	MANUAL	\N	2026-10-04 23:23:54.461+07
8cdef7bd-814b-4744-be5f-393527887493	23230ce1-1ab7-4b49-b9b2-404f149e00ca	2026-09-13	OFFDAY	\N	\N	\N	MANUAL	\N	2026-10-04 23:23:54.463+07
58e14e48-2b7a-4058-bc3b-488228e0666c	23230ce1-1ab7-4b49-b9b2-404f149e00ca	2026-09-14	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-14 06:00:00+07	2026-09-14 14:00:00+07	MANUAL	\N	2026-10-04 23:23:54.466+07
26b4ceda-063b-42f5-ba9f-de65cef42866	23230ce1-1ab7-4b49-b9b2-404f149e00ca	2026-09-15	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-15 06:00:00+07	2026-09-15 14:00:00+07	MANUAL	\N	2026-10-04 23:23:54.471+07
dd0ffeaa-de1c-4741-bc8f-a7b4595e9c63	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	2026-09-01	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-01 08:00:00+07	2026-09-01 16:00:00+07	MANUAL	\N	2026-10-04 23:23:54.474+07
30d2e832-c65c-404a-9e39-f44cdec3b9a7	b7291f79-3495-44a5-b039-737465dc2cc0	2026-09-02	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-02 08:00:00+07	2026-09-02 16:00:00+07	MANUAL	\N	2026-10-04 23:23:54.325+07
9e62ac65-110a-4884-bdca-b5a7e0668ef0	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	2026-09-03	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-03 08:00:00+07	2026-09-03 16:00:00+07	MANUAL	\N	2026-10-04 23:23:54.48+07
fed9db93-d2a4-4243-85a4-fc959ddf8543	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	2026-09-04	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-04 08:00:00+07	2026-09-04 16:00:00+07	MANUAL	\N	2026-10-04 23:23:54.484+07
c573eaca-bff8-432b-966d-0490fe008f97	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	2026-09-05	OFFDAY	\N	\N	\N	MANUAL	\N	2026-10-04 23:23:54.487+07
04c078ba-258b-4e89-b6ad-1fb14fdcd2cc	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	2026-09-06	OFFDAY	\N	\N	\N	MANUAL	\N	2026-10-04 23:23:54.489+07
10921b16-d7bf-48f4-90a6-0ec51c435759	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	2026-09-07	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-07 08:00:00+07	2026-09-07 16:00:00+07	MANUAL	\N	2026-10-04 23:23:54.492+07
c5335f18-3feb-47e3-a1b2-8032f9504f6a	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	2026-09-08	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-08 08:00:00+07	2026-09-08 16:00:00+07	MANUAL	\N	2026-10-04 23:23:54.496+07
0076978a-ecc2-4b5e-884b-fe92bc452383	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	2026-09-09	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-09 08:00:00+07	2026-09-09 16:00:00+07	MANUAL	\N	2026-10-04 23:23:54.5+07
b6e854d3-3151-4706-bc05-b29eb34fed7e	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	2026-09-10	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-10 08:00:00+07	2026-09-10 16:00:00+07	MANUAL	\N	2026-10-04 23:23:54.504+07
669f99d8-c1e5-4c91-b660-d05a215d1bf3	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	2026-09-11	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-11 08:00:00+07	2026-09-11 16:00:00+07	MANUAL	\N	2026-10-04 23:23:54.507+07
34d68fe1-048f-4cbe-bed6-0d370db664db	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	2026-09-12	OFFDAY	\N	\N	\N	MANUAL	\N	2026-10-04 23:23:54.509+07
b2b6e182-71a4-44b5-baca-a6c5a13735a9	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	2026-09-13	OFFDAY	\N	\N	\N	MANUAL	\N	2026-10-04 23:23:54.511+07
3099d327-67a8-4b7d-a195-96a3260bdc88	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	2026-09-14	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-14 08:00:00+07	2026-09-14 16:00:00+07	MANUAL	\N	2026-10-04 23:23:54.514+07
642e6a78-8cbb-4696-9323-b725458f83f5	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	2026-09-15	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-15 08:00:00+07	2026-09-15 16:00:00+07	MANUAL	\N	2026-10-04 23:23:54.517+07
f9b432a2-602a-491b-a04e-aeb9d29d8ce4	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	2026-09-16	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-16 08:00:00+07	2026-09-16 16:00:00+07	MANUAL	\N	2026-10-04 23:23:54.521+07
21a8ac01-40aa-4c18-802c-824c01df55b3	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	2026-09-17	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-17 08:00:00+07	2026-09-17 16:00:00+07	MANUAL	\N	2026-10-04 23:23:54.524+07
480b1ef9-1b28-4bf4-ad47-aa4d6990ae35	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	2026-09-18	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-18 08:00:00+07	2026-09-18 16:00:00+07	MANUAL	\N	2026-10-04 23:23:54.528+07
711a4e75-30fc-4cad-8b70-cdcb45f88af1	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	2026-09-19	OFFDAY	\N	\N	\N	MANUAL	\N	2026-10-04 23:23:54.53+07
25d799ee-1470-4af9-ad13-33eacc3bdbba	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	2026-09-20	OFFDAY	\N	\N	\N	MANUAL	\N	2026-10-04 23:23:54.532+07
b277fc6b-2401-450b-8eb1-c2df14b67a9c	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	2026-09-21	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-21 08:00:00+07	2026-09-21 16:00:00+07	MANUAL	\N	2026-10-04 23:23:54.536+07
dd227164-276d-4816-badf-73227aa8ebb9	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	2026-09-22	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-22 08:00:00+07	2026-09-22 16:00:00+07	MANUAL	\N	2026-10-04 23:23:54.54+07
f1cc5c79-4597-4096-88a2-fe7b396da7f3	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	2026-09-23	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-23 08:00:00+07	2026-09-23 16:00:00+07	MANUAL	\N	2026-10-04 23:23:54.543+07
94448b04-a47b-4012-ae49-0e5003707336	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	2026-09-24	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-24 08:00:00+07	2026-09-24 16:00:00+07	MANUAL	\N	2026-10-04 23:23:54.546+07
c6616787-ade1-47d1-a85d-1030fe009298	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	2026-09-25	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-25 08:00:00+07	2026-09-25 16:00:00+07	MANUAL	\N	2026-10-04 23:23:54.55+07
ee1c3a85-0b8d-4ad8-a9f8-ae426c325b89	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	2026-09-26	OFFDAY	\N	\N	\N	MANUAL	\N	2026-10-04 23:23:54.554+07
9d70b376-e93b-444a-8f1b-1b179b689ae1	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	2026-09-27	OFFDAY	\N	\N	\N	MANUAL	\N	2026-10-04 23:23:54.557+07
86d835a9-3402-4b60-be98-8023386ae39b	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	2026-09-28	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-28 08:00:00+07	2026-09-28 16:00:00+07	MANUAL	\N	2026-10-04 23:23:54.56+07
d33a26fe-d4c7-4f52-a201-d850f50d1902	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	2026-09-29	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-29 08:00:00+07	2026-09-29 16:00:00+07	MANUAL	\N	2026-10-04 23:23:54.564+07
e8e75aae-d13d-4b56-984f-7422e027bfbb	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	2026-09-30	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-30 08:00:00+07	2026-09-30 16:00:00+07	MANUAL	\N	2026-10-04 23:23:54.57+07
fb61e63e-c5b2-4572-8c24-8af824c04ecf	a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	2026-09-01	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-01 08:00:00+07	2026-09-01 16:00:00+07	MANUAL	\N	2026-10-04 23:23:53.73+07
71b0ab30-0916-4a0b-9e64-82dbe425bcd8	4478787b-c3e8-4f0d-8b9b-7046fec7f539	2026-09-01	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-01 08:00:00+07	2026-09-01 16:00:00+07	MANUAL	\N	2026-10-04 23:23:53.822+07
5ecee194-4c6e-4e5d-843b-74886c1f10ac	4478787b-c3e8-4f0d-8b9b-7046fec7f539	2026-09-16	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-16 08:00:00+07	2026-09-16 16:00:00+07	MANUAL	\N	2026-10-04 23:23:53.881+07
acd1747d-5239-45cd-bf85-c6b9bff98589	0cd6bde6-3226-4ebb-b135-ca522d42efa4	2026-09-16	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-16 08:00:00+07	2026-09-16 16:00:00+07	MANUAL	\N	2026-10-04 23:23:53.973+07
252e29df-2fcc-410a-b516-c88c5338e13b	0c685448-b52e-4e60-89ea-6f7c500a86d5	2026-09-01	WORKDAY	800c181b-ae0f-4ed1-876b-a7469ce4e922	2026-09-01 16:00:00+07	2026-09-02 00:00:00+07	MANUAL	\N	2026-10-04 23:23:54.015+07
4aa5521f-52b9-402b-863e-2bb66e2d8512	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	2026-09-01	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-01 07:00:00+07	2026-09-01 15:00:00+07	MANUAL	\N	2026-10-04 23:23:54.105+07
78a505b3-dac5-47c8-af6d-5075ddbaf79f	0b9e23c5-0b7c-43d4-b66e-9193e1c24804	2026-09-16	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-16 07:00:00+07	2026-09-16 15:00:00+07	MANUAL	\N	2026-10-04 23:23:54.156+07
e663a08a-7e0d-4e5e-ad93-9d0132c77fd9	3193d9a5-6017-4441-b40c-f22e9ec9b867	2026-09-16	WORKDAY	100b29e1-4d05-4a8b-90c5-0d51284ed21e	2026-09-16 21:00:00+07	2026-09-17 05:00:00+07	MANUAL	\N	2026-10-04 23:23:54.268+07
13d2c7c3-21ce-4941-9520-c47acbbd96e6	b7291f79-3495-44a5-b039-737465dc2cc0	2026-09-01	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-01 08:00:00+07	2026-09-01 16:00:00+07	MANUAL	\N	2026-10-04 23:23:54.322+07
6f00cba0-6164-4387-92d2-6c5cee7c1657	b7291f79-3495-44a5-b039-737465dc2cc0	2026-09-16	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-16 08:00:00+07	2026-09-16 16:00:00+07	MANUAL	\N	2026-10-04 23:23:54.378+07
510a3d9d-0d64-4988-a013-ce237382c075	bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	2026-09-02	WORKDAY	03514fa5-e208-44a3-a0df-f4d39ea10e8e	2026-09-02 08:00:00+07	2026-09-02 16:00:00+07	MANUAL	\N	2026-10-04 23:23:54.477+07
\.


--
-- Data for Name: ImportBatch; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."ImportBatch" (id, "fileType", "fileName", "fileHash", status, "totalRows", "successRows", "errorRows", "uploadedBy", "createdAt", "finishedAt", progress, "startedAt") FROM stdin;
\.


--
-- Data for Name: ImportRowError; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."ImportRowError" (id, "batchId", "rowNumber", "rawLine", message) FROM stdin;
\.


--
-- Data for Name: LeaveRequest; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."LeaveRequest" (id, "externalRef", "odooEmployeeId", kind, "odooLeaveTypeId", "startDate", "endDate", days, reason, source, "overallStatus", "importBatchId", "createdAt", "updatedAt") FROM stdin;
2e6932a5-642d-4a45-b623-ad4b0d1a5589	DEMO-LV-001	0cd6bde6-3226-4ebb-b135-ca522d42efa4	ANNUAL	\N	2026-09-08	2026-09-10	3.00	Cuti tahunan (contoh)	IMPORT	APPROVED	\N	2026-10-04 22:58:57.148+07	2026-10-04 23:23:54.597+07
b88dabac-244a-4739-aa79-dac5f9476477	DEMO-LV-002	0cd6bde6-3226-4ebb-b135-ca522d42efa4	SICK	\N	2026-09-21	2026-09-21	0.50	Sakit (contoh)	IMPORT	APPROVED	\N	2026-10-04 22:58:57.156+07	2026-10-04 23:23:54.604+07
\.


--
-- Data for Name: LeaveRule; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."LeaveRule" (id, "leaveKind", "effectiveFrom", "effectiveTo", "minTenureMonths", "accrualMode", "entitlementDays", "firstGrantAnniversary", "expiryMonths", "updatedBy", "createdAt", "updatedAt") FROM stdin;
9db0823d-9314-426d-bfb8-201371d7fd1a	ANNUAL	2026-01-01	\N	12	ANNIVERSARY	12.00	1	12	ca415e8f-13cd-46c3-860b-e9510e36b9ca	2026-10-04 23:23:54.582+07	2026-10-04 23:23:54.582+07
\.


--
-- Data for Name: Menu; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."Menu" (id, code, label, path, icon, "sortOrder", "parentId", "requiredPermissionId", "isActive") FROM stdin;
20f4a14b-0ef8-4baa-ac4d-640a6a040d46	master	Master Data	\N	database	10	\N	\N	t
43f1b82a-5653-4526-b4cc-97b00b5d3c57	master.locations	Lokasi Kerja	/master/locations	map-pin	1	20f4a14b-0ef8-4baa-ac4d-640a6a040d46	f6371fdf-f487-468b-a580-ded522332743	t
1dce8c14-e740-4aab-9b45-c960b9f85056	master.employees	Karyawan	/master/employees	users	2	20f4a14b-0ef8-4baa-ac4d-640a6a040d46	bb3a0bee-bc4b-4e81-a3f5-900e2cc0bcd9	t
746bd37f-32db-48a2-97d1-02913e9dcd71	schedule	Jadwal	\N	calendar	15	\N	\N	t
890deecf-37f7-4ddb-b0b4-73fcd68afd85	schedule.shifts	Shift	/schedule/shifts	clock	1	746bd37f-32db-48a2-97d1-02913e9dcd71	c5164194-80de-4d7c-9172-1ce19a0d3d40	t
6e3908a0-588c-4e7d-b9b2-a25754a2bfd0	schedule.roster	Jadwal Karyawan	/schedule/roster	calendar-days	2	746bd37f-32db-48a2-97d1-02913e9dcd71	ab72fa00-deb5-4f43-abff-b01e8241fb91	t
0c562a67-0b53-43d6-bf15-a6d1a4e542f3	schedule.calendar	Kalender	/schedule/calendar	calendar	3	746bd37f-32db-48a2-97d1-02913e9dcd71	cb7c7f82-a9ed-44a8-9270-d48ce55fb452	t
cc7fd3d8-8c01-4d18-93e3-016679a1244f	attendance.daily	Rekap Absensi	/attendance/daily	clipboard-check	12	\N	0cb6f5ff-7184-49af-a759-d11e09cb71c0	t
b081e8d8-f06f-4f5c-ae02-54659f870539	attendance.devices	Mesin Fingerprint	/attendance/devices	fingerprint	13	\N	2a493958-7552-48fc-9df2-1c62c61458b8	t
35b64ff0-bf3f-443f-ac78-a298a7bd4626	time.entries	Time Entries	/time-entries	file-spreadsheet	14	\N	f10a4471-9fc1-497e-9a63-41304348e265	t
47040538-f9f0-44fb-b314-d11db2065a99	process.monitor	Process Monitor	/process-monitor	activity	15	\N	1ee81da7-f78f-4803-9a7c-187898547616	t
1da11d2f-3117-4508-89d2-3b8886b999cc	requests	Pengajuan	\N	inbox	16	\N	\N	t
d2befb39-c930-4d83-b2a9-a01269856a82	requests.leave	Cuti	/requests/leave	plane	1	1da11d2f-3117-4508-89d2-3b8886b999cc	6edb54f2-596a-47eb-b075-3a4b9d743832	t
7f3da660-916d-4549-bcec-e695e226352d	requests.overtime	Lembur	/requests/overtime	moon	3	1da11d2f-3117-4508-89d2-3b8886b999cc	3f3ab41a-ba9c-48ad-9bcd-f5ccecf1c571	t
be55b7b7-fe48-440f-8408-8caaa312d3d5	config	Konfigurasi Aturan	\N	settings	18	\N	\N	t
f349f3d2-6c8f-4c30-9bce-eadd0c22c1f1	config.attendance	Absensi & Keterlambatan	/config/attendance	alarm-clock	1	be55b7b7-fe48-440f-8408-8caaa312d3d5	ea3c3b41-9365-4a30-84a2-f8a4d1976d77	t
43d6c32e-9ca0-4359-b313-55de70cbd86d	config.leave	Aturan Cuti	/config/leave	plane	3	be55b7b7-fe48-440f-8408-8caaa312d3d5	4ea091b7-12f1-4e01-ade8-ae904d30771b	t
14ddd639-ef1c-4a4b-97ea-bbcbc2a72f50	config.overtime	Lembur	/config/overtime	moon	2	be55b7b7-fe48-440f-8408-8caaa312d3d5	677a5795-22a0-44b2-8a28-79e8bea2ba62	t
ff8b52c0-9bd9-4a9c-8400-62eb11f2ff83	import	Impor Data	/import	upload	20	\N	6e13a3e2-353c-4a1e-ae51-9a80aff1781b	t
\.


--
-- Data for Name: OdooContract; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."OdooContract" (id, "odooContractId", "odooEmployeeId", wage, "dateStart", "dateEnd", "isActive", "syncedAt") FROM stdin;
\.


--
-- Data for Name: OdooEmployee; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."OdooEmployee" (id, "odooId", nik, name, email, "jobTitle", "jobGrade", "isActive", "parentOdooId", "workLocationId", "lastSyncedAt", "createdAt", "updatedAt", "hireDate") FROM stdin;
0b9e23c5-0b7c-43d4-b66e-9193e1c24804	9106	DEMO-006	Maria Magdalena	maria.magdalena@contoh.co.id	Kepala Cabang	M1	t	9101	6d7af890-a7b5-4313-83ed-f6fa76d0a7c6	\N	2026-10-04 22:58:55.737+07	2026-10-04 23:23:53.577+07	2019-07-01
3193d9a5-6017-4441-b40c-f22e9ec9b867	9107	DEMO-007	Yohanes Tampubolon	yohanes.tampubolon@contoh.co.id	Satpam	S1	t	9106	6d7af890-a7b5-4313-83ed-f6fa76d0a7c6	\N	2026-10-04 22:58:55.744+07	2026-10-04 23:23:53.583+07	2023-02-20
b7291f79-3495-44a5-b039-737465dc2cc0	9108	DEMO-008	Siti Aminah	siti.aminah@contoh.co.id	Staf Produksi	S2	t	9101	a071e3d8-e61e-4671-8600-55d42d5a890c	\N	2026-10-04 22:58:55.75+07	2026-10-04 23:23:53.589+07	2021-08-09
6a65b903-7cb2-468b-8245-a607e73baa54	9101	DEMO-001	Budi Santoso	budi.santoso@contoh.co.id	Manajer Operasional	M2	t	\N	a071e3d8-e61e-4671-8600-55d42d5a890c	\N	2026-10-04 22:58:55.7+07	2026-10-04 23:23:53.542+07	2018-03-01
a0c1b3cc-6bfd-4bac-a06c-67d388d330dc	9102	DEMO-002	Sari Wulandari	sari.wulandari@contoh.co.id	Staf Administrasi	S1	t	9101	a071e3d8-e61e-4671-8600-55d42d5a890c	\N	2026-10-04 22:58:55.712+07	2026-10-04 23:23:53.551+07	2022-05-16
4478787b-c3e8-4f0d-8b9b-7046fec7f539	9103	DEMO-003	Agus Pratama	agus.pratama@contoh.co.id	Staf Gudang	S1	t	9101	a071e3d8-e61e-4671-8600-55d42d5a890c	\N	2026-10-04 22:58:55.719+07	2026-10-04 23:23:53.558+07	2024-01-10
0cd6bde6-3226-4ebb-b135-ca522d42efa4	9104	DEMO-004	Dewi Lestari	dewi.lestari@contoh.co.id	Staf Keuangan	S2	t	9101	a071e3d8-e61e-4671-8600-55d42d5a890c	\N	2026-10-04 22:58:55.725+07	2026-10-04 23:23:53.564+07	2025-09-08
0c685448-b52e-4e60-89ea-6f7c500a86d5	9105	DEMO-005	Rizky Ramadhan	rizky.ramadhan@contoh.co.id	Operator Produksi	S1	t	9101	a071e3d8-e61e-4671-8600-55d42d5a890c	\N	2026-10-04 22:58:55.731+07	2026-10-04 23:23:53.571+07	2025-11-03
bd0ffea8-d9c1-4dbc-bb01-76eb4cb91c51	9110	\N	Kevin Anggara	kevin.anggara@contoh.co.id	Staf IT	S2	t	9101	a071e3d8-e61e-4671-8600-55d42d5a890c	\N	2026-10-04 22:58:55.762+07	2026-10-04 23:23:53.6+07	2026-03-15
23230ce1-1ab7-4b49-b9b2-404f149e00ca	9109	DEMO-009	Hendra Wijaya	hendra.wijaya@contoh.co.id	Staf Lapangan	S1	f	9106	02d1e070-925a-4bbf-a321-e8542610aea7	\N	2026-10-04 22:58:55.757+07	2026-10-04 23:23:55.149+07	2024-06-17
\.


--
-- Data for Name: OvertimeRealization; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."OvertimeRealization" (id, "externalRef", "odooEmployeeId", "workDate", "actualStart", "actualEnd", "planExternalRef", "overtimeRequestId", "reconciliationStatus", "payableMinutes", "appliedBasis", "appliedRuleId", "importBatchId") FROM stdin;
\.


--
-- Data for Name: OvertimeRequest; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."OvertimeRequest" (id, "externalRef", "odooEmployeeId", "workDate", "plannedStart", "plannedEnd", reason, source, "overallStatus", "createdAt") FROM stdin;
\.


--
-- Data for Name: OvertimeRule; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."OvertimeRule" (id, "workLocationId", "effectiveFrom", "effectiveTo", "workWeekPattern", "payableBasis", "punchToleranceMinutes", "minMinutes", "roundingMinutes", "maxMinutesPerDay", "maxMinutesPerWeek", "multiplierTiersJson", "excludedJobGrades", "updatedBy", "updatedAt") FROM stdin;
\.


--
-- Data for Name: PayrollPeriod; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."PayrollPeriod" (id, code, "startDate", "endDate", status, "frozenAt", "frozenBy") FROM stdin;
\.


--
-- Data for Name: PendingAdjustment; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."PendingAdjustment" (id, "odooEmployeeId", "sourcePeriodId", "workDate", reason, "deltaLateDeduction", "deltaOvertimeMinutes", "appliedPeriodId", "createdAt") FROM stdin;
\.


--
-- Data for Name: Permission; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."Permission" (id, code, module, description) FROM stdin;
f6371fdf-f487-468b-a580-ded522332743	master.location.read	master	Lihat lokasi kerja
d8de0772-fbe5-496b-8163-19a90d895ae5	rbac.role.read	rbac	Lihat role
8b681ce6-513f-412a-a014-12c3823495c4	rbac.role.edit	rbac	Kelola role dan permission
74c86e6a-5159-4aab-a6c7-cb6199070429	master.location.edit	master	Kelola lokasi kerja
bb3a0bee-bc4b-4e81-a3f5-900e2cc0bcd9	master.employee.read	master	Lihat karyawan
40457fd3-13c7-441d-b6c7-08003571ff62	master.employee.edit	master	Kelola karyawan
ea3c3b41-9365-4a30-84a2-f8a4d1976d77	config.attendance.read	config	Lihat aturan absensi
d57cc44b-1ee7-4a8e-b0ef-fe3b6c06607f	config.attendance.edit	config	Ubah aturan absensi
c0a1bec8-95fe-4e6d-bced-ed6ac4bd2bf7	config.attendance.simulate	config	Simulasi aturan absensi
677a5795-22a0-44b2-8a28-79e8bea2ba62	config.overtime.read	config	Lihat aturan lembur
53bf262e-367d-46aa-afa0-bc7ee81db47c	config.overtime.edit	config	Ubah aturan lembur
456a64d9-7262-4f5b-85b0-c0adfc5bbef9	config.overtime.simulate	config	Simulasi aturan lembur
c5164194-80de-4d7c-9172-1ce19a0d3d40	schedule.shift.read	schedule	Lihat shift
82e6b560-11b7-4f02-b517-853f4dd66387	schedule.shift.edit	schedule	Kelola shift
ab72fa00-deb5-4f43-abff-b01e8241fb91	schedule.roster.read	schedule	Lihat jadwal karyawan
30614282-e6db-48ab-9ccd-cf08160a94df	schedule.roster.edit	schedule	Kelola jadwal karyawan
cb7c7f82-a9ed-44a8-9270-d48ce55fb452	schedule.calendar.read	schedule	Lihat calendar event
3a8b7530-74e2-442a-9498-bc07f1ae2200	schedule.calendar.edit	schedule	Kelola calendar event
6edb54f2-596a-47eb-b075-3a4b9d743832	leave.request.read	leave	Lihat pengajuan cuti
f10a4471-9fc1-497e-9a63-41304348e265	time.entry.read	time	Lihat dan unduh time entries
4ea091b7-12f1-4e01-ade8-ae904d30771b	leave.rule.read	leave	Lihat aturan cuti dan saldo
f60ef3d5-8900-4791-b823-7a3c36a49c44	leave.rule.edit	leave	Ubah aturan cuti
1ee81da7-f78f-4803-9a7c-187898547616	process.monitor.read	process	Lihat Process Monitor
1303e2c0-4796-4a77-b1e2-87ef0c9a7714	inbound.time.create	inbound	Unggah time entries (CSV)
5c777bb7-d320-4194-a044-2a84df3946e6	inbound.leave.create	inbound	Kirim data cuti (inbound)
3f3ab41a-ba9c-48ad-9bcd-f5ccecf1c571	overtime.request.read	overtime	Lihat pengajuan lembur
2a493958-7552-48fc-9df2-1c62c61458b8	attendance.device.read	attendance	Lihat mesin fingerprint
d11bbc63-3789-4c54-a0d0-bc41e1b9eba8	attendance.device.edit	attendance	Kelola mesin dan mapping PIN
0cb6f5ff-7184-49af-a759-d11e09cb71c0	attendance.log.read	attendance	Lihat absensi
27b79ff2-48d8-4708-ba9b-37a95900e37d	attendance.log.edit	attendance	Koreksi absensi
6e13a3e2-353c-4a1e-ae51-9a80aff1781b	import.batch.read	import	Lihat riwayat impor
4105e675-be5f-4578-8d68-e197231a9fb2	import.batch.create	import	Unggah file impor
\.


--
-- Data for Name: PrePayrollResult; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."PrePayrollResult" (id, "odooEmployeeId", "periodId", "totalLateDeduction", "totalUnpaidDeduction", "netDeductionAmount", "totalOvertimeMinutes", "totalOvertimePay", "overtimeBreakdownJson", "isFrozen", "frozenAt", "odooSyncStatus", "odooSyncError", "odooPayslipInputIds", "odooSyncedAt", "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: ProcessLog; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."ProcessLog" (id, "batchId", level, message, "createdAt", seq) FROM stdin;
\.


--
-- Data for Name: Role; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."Role" (id, code, name, description, "isSystem") FROM stdin;
483817a7-ac37-427f-863a-e82ad88bce37	SUPER_ADMIN	Super Admin	\N	t
\.


--
-- Data for Name: RolePermission; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."RolePermission" (id, "roleId", "permissionId", "menuId", "canCreate", "canRead", "canUpdate", "canDelete") FROM stdin;
\.


--
-- Data for Name: RuleSimulation; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."RuleSimulation" (id, "ruleType", "workLocationId", "periodStart", "periodEnd", "baselineRuleId", "draftRuleJson", status, "progressPct", "summaryJson", "errorMessage", "requestedBy", "createdAt", "expiresAt") FROM stdin;
\.


--
-- Data for Name: RuleSimulationDetail; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."RuleSimulationDetail" (id, "simulationId", "odooEmployeeId", "baselineMinutes", "draftMinutes", "baselineAmount", "draftAmount", "affectedDays") FROM stdin;
\.


--
-- Data for Name: Shift; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."Shift" (id, code, name, "startTime", "durationMinutes", "breakMinutes", "isActive") FROM stdin;
03514fa5-e208-44a3-a0df-f4d39ea10e8e	DEMO-PAGI	DEMO Shift Pagi	08:00	480	60	t
800c181b-ae0f-4ed1-876b-a7469ce4e922	DEMO-SORE	DEMO Shift Sore	16:00	480	60	t
100b29e1-4d05-4a8b-90c5-0d51284ed21e	DEMO-MALAM	DEMO Shift Malam	22:00	480	60	t
\.


--
-- Data for Name: TimeEntry; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."TimeEntry" (id, "odooEmployeeId", "startAt", "endAt", "workDate", "shiftId", "workSchedule", "payrollPeriod", source, "importBatchId", "createdAt", "updatedAt", "durationHours") FROM stdin;
\.


--
-- Data for Name: User; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."User" (id, email, "passwordHash", "isActive", "lastLoginAt", "odooEmployeeId", "createdAt", "updatedAt") FROM stdin;
ca415e8f-13cd-46c3-860b-e9510e36b9ca	admin	$2b$10$9YWmc7mQOjPB5.wOHzAMturjK0CuVYEErnc4xcEXGrTwVTM.8xrNK	t	2026-10-04 23:23:53.479+07	\N	2026-09-29 16:34:59.963+07	2026-10-04 23:23:53.48+07
\.


--
-- Data for Name: UserPermissionOverride; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."UserPermissionOverride" (id, "userId", "permissionId", "isAllowed", reason, "expiresAt", "createdBy", "createdAt") FROM stdin;
\.


--
-- Data for Name: UserRole; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."UserRole" ("userId", "roleId", "assignedAt") FROM stdin;
ca415e8f-13cd-46c3-860b-e9510e36b9ca	483817a7-ac37-427f-863a-e82ad88bce37	2026-09-29 16:34:59.968+07
\.


--
-- Data for Name: WorkLocation; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."WorkLocation" (id, code, name, type, timezone, latitude, longitude, "geofenceRadiusMeters", "isActive", "createdAt", "updatedAt") FROM stdin;
a071e3d8-e61e-4671-8600-55d42d5a890c	DEMO-JKT	DEMO Kantor Pusat Jakarta	HO	Asia/Jakarta	\N	\N	\N	t	2026-10-04 22:58:55.576+07	2026-10-04 22:58:55.576+07
6d7af890-a7b5-4313-83ed-f6fa76d0a7c6	DEMO-MKS	DEMO Cabang Makassar	BRANCH	Asia/Makassar	\N	\N	\N	t	2026-10-04 22:58:55.582+07	2026-10-04 22:58:55.582+07
02d1e070-925a-4bbf-a321-e8542610aea7	DEMO-JYP	DEMO Cabang Jayapura	BRANCH	Asia/Jayapura	\N	\N	\N	t	2026-10-04 22:58:55.589+07	2026-10-04 22:58:55.589+07
\.


--
-- Data for Name: _prisma_migrations; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public._prisma_migrations (id, checksum, finished_at, migration_name, logs, rolled_back_at, started_at, applied_steps_count) FROM stdin;
fc2f65b5-6183-4862-816d-810887e28096	82163c7a0346850dc1928e4cd4c9444d9b3acd2561e1a61422f16377bc3d4e3a	2026-09-29 16:34:49.559449+07	20260929093449_init	\N	\N	2026-09-29 16:34:49.323495+07	1
5cfcb7b7-cccf-45b3-b787-440f5ca1b899	14e171c685fc22017fec7c092453a7639a7e91574cba6e25f5084af6400bc57d	2026-09-29 17:01:16.326642+07	20260929100116_remove_approval_engine	\N	\N	2026-09-29 17:01:16.295959+07	1
8257a208-819d-4110-9237-127262d9a0c8	ab0d072243cb27e2717ddc2afb8aa166f8324a2fca7142c7dd06bc2181ca1bae	2026-09-29 17:07:16.088401+07	20260929100716_remove_waiver	\N	\N	2026-09-29 17:07:16.073599+07	1
9b7e5a67-c4d6-4fd1-be9a-202c02517d6c	d3c7a741572caa9b735050bf159e292e5d032dfeb99b2e3c3391a50fee850217	2026-09-29 17:09:50.872907+07	20260929100950_late_tracking_only	\N	\N	2026-09-29 17:09:50.868164+07	1
7da8c5f6-95d4-48f2-b4f0-7582ccffe4f1	a71fafd66e27878bf59b6da8c355e25d3972a93eaf53570eb640497caa1e955b	2026-10-04 22:11:55.724445+07	20261004151155_time_entries	\N	\N	2026-10-04 22:11:55.603654+07	1
615e6131-e6ed-46c8-a6d9-7c8d55969fa8	9c1c7db0acd8ba187f809ace57b9e81aafb664e5742b6f826ca749667b5b37b0	2026-10-04 22:37:43.644006+07	20261004153743_process_monitor_and_duration	\N	\N	2026-10-04 22:37:43.464899+07	1
a66984d4-d283-4a48-9871-2c4ac6b32ac7	a9166e94405e99ff28a27bacee600dedecf0e709d4003e6297afc2492305a5a3	2026-10-04 22:42:33.194108+07	20261004154233_process_log_seq	\N	\N	2026-10-04 22:42:33.124216+07	1
71dac343-c949-47f6-858e-a5b0ca387414	31f8120d8261415b269bba125791a73ceb6b14aa68b7ea3d159b1aa826ce419a	2026-10-04 23:15:03.145972+07	20261004161503_leave_rules_and_hire_date	\N	\N	2026-10-04 23:15:03.101908+07	1
\.


--
-- Name: ProcessLog_seq_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public."ProcessLog_seq_seq"', 109, true);


--
-- Name: AttendanceDaily AttendanceDaily_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."AttendanceDaily"
    ADD CONSTRAINT "AttendanceDaily_pkey" PRIMARY KEY (id);


--
-- Name: AttendanceLog AttendanceLog_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."AttendanceLog"
    ADD CONSTRAINT "AttendanceLog_pkey" PRIMARY KEY (id);


--
-- Name: AttendanceRawPunch AttendanceRawPunch_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."AttendanceRawPunch"
    ADD CONSTRAINT "AttendanceRawPunch_pkey" PRIMARY KEY (id);


--
-- Name: AttendanceRule AttendanceRule_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."AttendanceRule"
    ADD CONSTRAINT "AttendanceRule_pkey" PRIMARY KEY (id);


--
-- Name: AuditLog AuditLog_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."AuditLog"
    ADD CONSTRAINT "AuditLog_pkey" PRIMARY KEY (id);


--
-- Name: CalendarEvent CalendarEvent_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."CalendarEvent"
    ADD CONSTRAINT "CalendarEvent_pkey" PRIMARY KEY (id);


--
-- Name: Device Device_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Device"
    ADD CONSTRAINT "Device_pkey" PRIMARY KEY (id);


--
-- Name: EmployeeDeviceMap EmployeeDeviceMap_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."EmployeeDeviceMap"
    ADD CONSTRAINT "EmployeeDeviceMap_pkey" PRIMARY KEY (id);


--
-- Name: EmployeeSchedule EmployeeSchedule_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."EmployeeSchedule"
    ADD CONSTRAINT "EmployeeSchedule_pkey" PRIMARY KEY (id);


--
-- Name: ImportBatch ImportBatch_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."ImportBatch"
    ADD CONSTRAINT "ImportBatch_pkey" PRIMARY KEY (id);


--
-- Name: ImportRowError ImportRowError_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."ImportRowError"
    ADD CONSTRAINT "ImportRowError_pkey" PRIMARY KEY (id);


--
-- Name: LeaveRequest LeaveRequest_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."LeaveRequest"
    ADD CONSTRAINT "LeaveRequest_pkey" PRIMARY KEY (id);


--
-- Name: LeaveRule LeaveRule_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."LeaveRule"
    ADD CONSTRAINT "LeaveRule_pkey" PRIMARY KEY (id);


--
-- Name: Menu Menu_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Menu"
    ADD CONSTRAINT "Menu_pkey" PRIMARY KEY (id);


--
-- Name: OdooContract OdooContract_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."OdooContract"
    ADD CONSTRAINT "OdooContract_pkey" PRIMARY KEY (id);


--
-- Name: OdooEmployee OdooEmployee_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."OdooEmployee"
    ADD CONSTRAINT "OdooEmployee_pkey" PRIMARY KEY (id);


--
-- Name: OvertimeRealization OvertimeRealization_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."OvertimeRealization"
    ADD CONSTRAINT "OvertimeRealization_pkey" PRIMARY KEY (id);


--
-- Name: OvertimeRequest OvertimeRequest_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."OvertimeRequest"
    ADD CONSTRAINT "OvertimeRequest_pkey" PRIMARY KEY (id);


--
-- Name: OvertimeRule OvertimeRule_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."OvertimeRule"
    ADD CONSTRAINT "OvertimeRule_pkey" PRIMARY KEY (id);


--
-- Name: PayrollPeriod PayrollPeriod_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."PayrollPeriod"
    ADD CONSTRAINT "PayrollPeriod_pkey" PRIMARY KEY (id);


--
-- Name: PendingAdjustment PendingAdjustment_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."PendingAdjustment"
    ADD CONSTRAINT "PendingAdjustment_pkey" PRIMARY KEY (id);


--
-- Name: Permission Permission_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Permission"
    ADD CONSTRAINT "Permission_pkey" PRIMARY KEY (id);


--
-- Name: PrePayrollResult PrePayrollResult_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."PrePayrollResult"
    ADD CONSTRAINT "PrePayrollResult_pkey" PRIMARY KEY (id);


--
-- Name: ProcessLog ProcessLog_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."ProcessLog"
    ADD CONSTRAINT "ProcessLog_pkey" PRIMARY KEY (id);


--
-- Name: RolePermission RolePermission_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."RolePermission"
    ADD CONSTRAINT "RolePermission_pkey" PRIMARY KEY (id);


--
-- Name: Role Role_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Role"
    ADD CONSTRAINT "Role_pkey" PRIMARY KEY (id);


--
-- Name: RuleSimulationDetail RuleSimulationDetail_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."RuleSimulationDetail"
    ADD CONSTRAINT "RuleSimulationDetail_pkey" PRIMARY KEY (id);


--
-- Name: RuleSimulation RuleSimulation_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."RuleSimulation"
    ADD CONSTRAINT "RuleSimulation_pkey" PRIMARY KEY (id);


--
-- Name: Shift Shift_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Shift"
    ADD CONSTRAINT "Shift_pkey" PRIMARY KEY (id);


--
-- Name: TimeEntry TimeEntry_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."TimeEntry"
    ADD CONSTRAINT "TimeEntry_pkey" PRIMARY KEY (id);


--
-- Name: UserPermissionOverride UserPermissionOverride_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."UserPermissionOverride"
    ADD CONSTRAINT "UserPermissionOverride_pkey" PRIMARY KEY (id);


--
-- Name: UserRole UserRole_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."UserRole"
    ADD CONSTRAINT "UserRole_pkey" PRIMARY KEY ("userId", "roleId");


--
-- Name: User User_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."User"
    ADD CONSTRAINT "User_pkey" PRIMARY KEY (id);


--
-- Name: WorkLocation WorkLocation_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."WorkLocation"
    ADD CONSTRAINT "WorkLocation_pkey" PRIMARY KEY (id);


--
-- Name: _prisma_migrations _prisma_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._prisma_migrations
    ADD CONSTRAINT _prisma_migrations_pkey PRIMARY KEY (id);


--
-- Name: AttendanceDaily_odooEmployeeId_workDate_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "AttendanceDaily_odooEmployeeId_workDate_key" ON public."AttendanceDaily" USING btree ("odooEmployeeId", "workDate");


--
-- Name: AttendanceDaily_workDate_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "AttendanceDaily_workDate_idx" ON public."AttendanceDaily" USING btree ("workDate");


--
-- Name: AttendanceLog_odooEmployeeId_workDate_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "AttendanceLog_odooEmployeeId_workDate_idx" ON public."AttendanceLog" USING btree ("odooEmployeeId", "workDate");


--
-- Name: AttendanceLog_rawPunchId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "AttendanceLog_rawPunchId_key" ON public."AttendanceLog" USING btree ("rawPunchId");


--
-- Name: AttendanceRawPunch_fingerprint_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "AttendanceRawPunch_fingerprint_key" ON public."AttendanceRawPunch" USING btree (fingerprint);


--
-- Name: AttendanceRawPunch_odooEmployeeId_punchAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "AttendanceRawPunch_odooEmployeeId_punchAt_idx" ON public."AttendanceRawPunch" USING btree ("odooEmployeeId", "punchAt");


--
-- Name: AttendanceRule_workLocationId_effectiveFrom_effectiveTo_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "AttendanceRule_workLocationId_effectiveFrom_effectiveTo_idx" ON public."AttendanceRule" USING btree ("workLocationId", "effectiveFrom", "effectiveTo");


--
-- Name: AttendanceRule_workLocationId_effectiveFrom_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "AttendanceRule_workLocationId_effectiveFrom_key" ON public."AttendanceRule" USING btree ("workLocationId", "effectiveFrom");


--
-- Name: AuditLog_createdAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "AuditLog_createdAt_idx" ON public."AuditLog" USING btree ("createdAt");


--
-- Name: AuditLog_entityType_entityId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "AuditLog_entityType_entityId_idx" ON public."AuditLog" USING btree ("entityType", "entityId");


--
-- Name: CalendarEvent_externalRef_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "CalendarEvent_externalRef_key" ON public."CalendarEvent" USING btree ("externalRef");


--
-- Name: CalendarEvent_startDate_endDate_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "CalendarEvent_startDate_endDate_idx" ON public."CalendarEvent" USING btree ("startDate", "endDate");


--
-- Name: Device_serialNumber_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "Device_serialNumber_key" ON public."Device" USING btree ("serialNumber");


--
-- Name: EmployeeDeviceMap_deviceId_enrollId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "EmployeeDeviceMap_deviceId_enrollId_key" ON public."EmployeeDeviceMap" USING btree ("deviceId", "enrollId");


--
-- Name: EmployeeSchedule_odooEmployeeId_workDate_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "EmployeeSchedule_odooEmployeeId_workDate_key" ON public."EmployeeSchedule" USING btree ("odooEmployeeId", "workDate");


--
-- Name: EmployeeSchedule_workDate_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "EmployeeSchedule_workDate_idx" ON public."EmployeeSchedule" USING btree ("workDate");


--
-- Name: ImportRowError_batchId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "ImportRowError_batchId_idx" ON public."ImportRowError" USING btree ("batchId");


--
-- Name: LeaveRequest_externalRef_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "LeaveRequest_externalRef_key" ON public."LeaveRequest" USING btree ("externalRef");


--
-- Name: LeaveRequest_odooEmployeeId_startDate_endDate_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "LeaveRequest_odooEmployeeId_startDate_endDate_idx" ON public."LeaveRequest" USING btree ("odooEmployeeId", "startDate", "endDate");


--
-- Name: LeaveRequest_overallStatus_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "LeaveRequest_overallStatus_idx" ON public."LeaveRequest" USING btree ("overallStatus");


--
-- Name: LeaveRule_leaveKind_effectiveFrom_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "LeaveRule_leaveKind_effectiveFrom_key" ON public."LeaveRule" USING btree ("leaveKind", "effectiveFrom");


--
-- Name: Menu_code_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "Menu_code_key" ON public."Menu" USING btree (code);


--
-- Name: OdooContract_odooContractId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "OdooContract_odooContractId_key" ON public."OdooContract" USING btree ("odooContractId");


--
-- Name: OdooContract_odooEmployeeId_dateStart_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "OdooContract_odooEmployeeId_dateStart_idx" ON public."OdooContract" USING btree ("odooEmployeeId", "dateStart");


--
-- Name: OdooEmployee_nik_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "OdooEmployee_nik_key" ON public."OdooEmployee" USING btree (nik);


--
-- Name: OdooEmployee_odooId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "OdooEmployee_odooId_key" ON public."OdooEmployee" USING btree ("odooId");


--
-- Name: OdooEmployee_workLocationId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "OdooEmployee_workLocationId_idx" ON public."OdooEmployee" USING btree ("workLocationId");


--
-- Name: OvertimeRealization_externalRef_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "OvertimeRealization_externalRef_key" ON public."OvertimeRealization" USING btree ("externalRef");


--
-- Name: OvertimeRealization_odooEmployeeId_workDate_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "OvertimeRealization_odooEmployeeId_workDate_idx" ON public."OvertimeRealization" USING btree ("odooEmployeeId", "workDate");


--
-- Name: OvertimeRealization_reconciliationStatus_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "OvertimeRealization_reconciliationStatus_idx" ON public."OvertimeRealization" USING btree ("reconciliationStatus");


--
-- Name: OvertimeRequest_externalRef_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "OvertimeRequest_externalRef_key" ON public."OvertimeRequest" USING btree ("externalRef");


--
-- Name: OvertimeRequest_odooEmployeeId_workDate_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "OvertimeRequest_odooEmployeeId_workDate_idx" ON public."OvertimeRequest" USING btree ("odooEmployeeId", "workDate");


--
-- Name: OvertimeRule_workLocationId_effectiveFrom_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "OvertimeRule_workLocationId_effectiveFrom_key" ON public."OvertimeRule" USING btree ("workLocationId", "effectiveFrom");


--
-- Name: PayrollPeriod_code_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "PayrollPeriod_code_key" ON public."PayrollPeriod" USING btree (code);


--
-- Name: PendingAdjustment_appliedPeriodId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "PendingAdjustment_appliedPeriodId_idx" ON public."PendingAdjustment" USING btree ("appliedPeriodId");


--
-- Name: Permission_code_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "Permission_code_key" ON public."Permission" USING btree (code);


--
-- Name: Permission_module_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "Permission_module_idx" ON public."Permission" USING btree (module);


--
-- Name: PrePayrollResult_odooEmployeeId_periodId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "PrePayrollResult_odooEmployeeId_periodId_key" ON public."PrePayrollResult" USING btree ("odooEmployeeId", "periodId");


--
-- Name: PrePayrollResult_periodId_isFrozen_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "PrePayrollResult_periodId_isFrozen_idx" ON public."PrePayrollResult" USING btree ("periodId", "isFrozen");


--
-- Name: ProcessLog_batchId_createdAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "ProcessLog_batchId_createdAt_idx" ON public."ProcessLog" USING btree ("batchId", "createdAt");


--
-- Name: RolePermission_permissionId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "RolePermission_permissionId_idx" ON public."RolePermission" USING btree ("permissionId");


--
-- Name: RolePermission_roleId_permissionId_menuId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "RolePermission_roleId_permissionId_menuId_key" ON public."RolePermission" USING btree ("roleId", "permissionId", "menuId");


--
-- Name: Role_code_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "Role_code_key" ON public."Role" USING btree (code);


--
-- Name: RuleSimulationDetail_simulationId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "RuleSimulationDetail_simulationId_idx" ON public."RuleSimulationDetail" USING btree ("simulationId");


--
-- Name: RuleSimulation_expiresAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "RuleSimulation_expiresAt_idx" ON public."RuleSimulation" USING btree ("expiresAt");


--
-- Name: Shift_code_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "Shift_code_key" ON public."Shift" USING btree (code);


--
-- Name: TimeEntry_odooEmployeeId_startAt_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "TimeEntry_odooEmployeeId_startAt_key" ON public."TimeEntry" USING btree ("odooEmployeeId", "startAt");


--
-- Name: TimeEntry_payrollPeriod_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "TimeEntry_payrollPeriod_idx" ON public."TimeEntry" USING btree ("payrollPeriod");


--
-- Name: TimeEntry_workDate_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "TimeEntry_workDate_idx" ON public."TimeEntry" USING btree ("workDate");


--
-- Name: UserPermissionOverride_userId_permissionId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "UserPermissionOverride_userId_permissionId_key" ON public."UserPermissionOverride" USING btree ("userId", "permissionId");


--
-- Name: User_email_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "User_email_key" ON public."User" USING btree (email);


--
-- Name: User_odooEmployeeId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "User_odooEmployeeId_key" ON public."User" USING btree ("odooEmployeeId");


--
-- Name: WorkLocation_code_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "WorkLocation_code_key" ON public."WorkLocation" USING btree (code);


--
-- Name: AttendanceDaily AttendanceDaily_odooEmployeeId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."AttendanceDaily"
    ADD CONSTRAINT "AttendanceDaily_odooEmployeeId_fkey" FOREIGN KEY ("odooEmployeeId") REFERENCES public."OdooEmployee"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: AttendanceLog AttendanceLog_odooEmployeeId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."AttendanceLog"
    ADD CONSTRAINT "AttendanceLog_odooEmployeeId_fkey" FOREIGN KEY ("odooEmployeeId") REFERENCES public."OdooEmployee"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: AttendanceLog AttendanceLog_rawPunchId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."AttendanceLog"
    ADD CONSTRAINT "AttendanceLog_rawPunchId_fkey" FOREIGN KEY ("rawPunchId") REFERENCES public."AttendanceRawPunch"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: AttendanceRawPunch AttendanceRawPunch_deviceId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."AttendanceRawPunch"
    ADD CONSTRAINT "AttendanceRawPunch_deviceId_fkey" FOREIGN KEY ("deviceId") REFERENCES public."Device"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: AttendanceRawPunch AttendanceRawPunch_odooEmployeeId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."AttendanceRawPunch"
    ADD CONSTRAINT "AttendanceRawPunch_odooEmployeeId_fkey" FOREIGN KEY ("odooEmployeeId") REFERENCES public."OdooEmployee"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: AttendanceRule AttendanceRule_workLocationId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."AttendanceRule"
    ADD CONSTRAINT "AttendanceRule_workLocationId_fkey" FOREIGN KEY ("workLocationId") REFERENCES public."WorkLocation"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: AuditLog AuditLog_actorId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."AuditLog"
    ADD CONSTRAINT "AuditLog_actorId_fkey" FOREIGN KEY ("actorId") REFERENCES public."User"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: CalendarEvent CalendarEvent_importBatchId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."CalendarEvent"
    ADD CONSTRAINT "CalendarEvent_importBatchId_fkey" FOREIGN KEY ("importBatchId") REFERENCES public."ImportBatch"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: CalendarEvent CalendarEvent_workLocationId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."CalendarEvent"
    ADD CONSTRAINT "CalendarEvent_workLocationId_fkey" FOREIGN KEY ("workLocationId") REFERENCES public."WorkLocation"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: Device Device_workLocationId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Device"
    ADD CONSTRAINT "Device_workLocationId_fkey" FOREIGN KEY ("workLocationId") REFERENCES public."WorkLocation"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: EmployeeDeviceMap EmployeeDeviceMap_deviceId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."EmployeeDeviceMap"
    ADD CONSTRAINT "EmployeeDeviceMap_deviceId_fkey" FOREIGN KEY ("deviceId") REFERENCES public."Device"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: EmployeeDeviceMap EmployeeDeviceMap_odooEmployeeId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."EmployeeDeviceMap"
    ADD CONSTRAINT "EmployeeDeviceMap_odooEmployeeId_fkey" FOREIGN KEY ("odooEmployeeId") REFERENCES public."OdooEmployee"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: EmployeeSchedule EmployeeSchedule_importBatchId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."EmployeeSchedule"
    ADD CONSTRAINT "EmployeeSchedule_importBatchId_fkey" FOREIGN KEY ("importBatchId") REFERENCES public."ImportBatch"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: EmployeeSchedule EmployeeSchedule_odooEmployeeId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."EmployeeSchedule"
    ADD CONSTRAINT "EmployeeSchedule_odooEmployeeId_fkey" FOREIGN KEY ("odooEmployeeId") REFERENCES public."OdooEmployee"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: EmployeeSchedule EmployeeSchedule_shiftId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."EmployeeSchedule"
    ADD CONSTRAINT "EmployeeSchedule_shiftId_fkey" FOREIGN KEY ("shiftId") REFERENCES public."Shift"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: ImportRowError ImportRowError_batchId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."ImportRowError"
    ADD CONSTRAINT "ImportRowError_batchId_fkey" FOREIGN KEY ("batchId") REFERENCES public."ImportBatch"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: LeaveRequest LeaveRequest_importBatchId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."LeaveRequest"
    ADD CONSTRAINT "LeaveRequest_importBatchId_fkey" FOREIGN KEY ("importBatchId") REFERENCES public."ImportBatch"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: LeaveRequest LeaveRequest_odooEmployeeId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."LeaveRequest"
    ADD CONSTRAINT "LeaveRequest_odooEmployeeId_fkey" FOREIGN KEY ("odooEmployeeId") REFERENCES public."OdooEmployee"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: Menu Menu_parentId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Menu"
    ADD CONSTRAINT "Menu_parentId_fkey" FOREIGN KEY ("parentId") REFERENCES public."Menu"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: Menu Menu_requiredPermissionId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Menu"
    ADD CONSTRAINT "Menu_requiredPermissionId_fkey" FOREIGN KEY ("requiredPermissionId") REFERENCES public."Permission"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: OdooContract OdooContract_odooEmployeeId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."OdooContract"
    ADD CONSTRAINT "OdooContract_odooEmployeeId_fkey" FOREIGN KEY ("odooEmployeeId") REFERENCES public."OdooEmployee"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: OdooEmployee OdooEmployee_parentOdooId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."OdooEmployee"
    ADD CONSTRAINT "OdooEmployee_parentOdooId_fkey" FOREIGN KEY ("parentOdooId") REFERENCES public."OdooEmployee"("odooId") ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: OdooEmployee OdooEmployee_workLocationId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."OdooEmployee"
    ADD CONSTRAINT "OdooEmployee_workLocationId_fkey" FOREIGN KEY ("workLocationId") REFERENCES public."WorkLocation"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: OvertimeRealization OvertimeRealization_importBatchId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."OvertimeRealization"
    ADD CONSTRAINT "OvertimeRealization_importBatchId_fkey" FOREIGN KEY ("importBatchId") REFERENCES public."ImportBatch"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: OvertimeRealization OvertimeRealization_odooEmployeeId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."OvertimeRealization"
    ADD CONSTRAINT "OvertimeRealization_odooEmployeeId_fkey" FOREIGN KEY ("odooEmployeeId") REFERENCES public."OdooEmployee"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: OvertimeRealization OvertimeRealization_overtimeRequestId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."OvertimeRealization"
    ADD CONSTRAINT "OvertimeRealization_overtimeRequestId_fkey" FOREIGN KEY ("overtimeRequestId") REFERENCES public."OvertimeRequest"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: OvertimeRequest OvertimeRequest_odooEmployeeId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."OvertimeRequest"
    ADD CONSTRAINT "OvertimeRequest_odooEmployeeId_fkey" FOREIGN KEY ("odooEmployeeId") REFERENCES public."OdooEmployee"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: OvertimeRule OvertimeRule_workLocationId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."OvertimeRule"
    ADD CONSTRAINT "OvertimeRule_workLocationId_fkey" FOREIGN KEY ("workLocationId") REFERENCES public."WorkLocation"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: PendingAdjustment PendingAdjustment_odooEmployeeId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."PendingAdjustment"
    ADD CONSTRAINT "PendingAdjustment_odooEmployeeId_fkey" FOREIGN KEY ("odooEmployeeId") REFERENCES public."OdooEmployee"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: PendingAdjustment PendingAdjustment_sourcePeriodId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."PendingAdjustment"
    ADD CONSTRAINT "PendingAdjustment_sourcePeriodId_fkey" FOREIGN KEY ("sourcePeriodId") REFERENCES public."PayrollPeriod"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: PrePayrollResult PrePayrollResult_odooEmployeeId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."PrePayrollResult"
    ADD CONSTRAINT "PrePayrollResult_odooEmployeeId_fkey" FOREIGN KEY ("odooEmployeeId") REFERENCES public."OdooEmployee"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: PrePayrollResult PrePayrollResult_periodId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."PrePayrollResult"
    ADD CONSTRAINT "PrePayrollResult_periodId_fkey" FOREIGN KEY ("periodId") REFERENCES public."PayrollPeriod"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: ProcessLog ProcessLog_batchId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."ProcessLog"
    ADD CONSTRAINT "ProcessLog_batchId_fkey" FOREIGN KEY ("batchId") REFERENCES public."ImportBatch"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: RolePermission RolePermission_menuId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."RolePermission"
    ADD CONSTRAINT "RolePermission_menuId_fkey" FOREIGN KEY ("menuId") REFERENCES public."Menu"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: RolePermission RolePermission_permissionId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."RolePermission"
    ADD CONSTRAINT "RolePermission_permissionId_fkey" FOREIGN KEY ("permissionId") REFERENCES public."Permission"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: RolePermission RolePermission_roleId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."RolePermission"
    ADD CONSTRAINT "RolePermission_roleId_fkey" FOREIGN KEY ("roleId") REFERENCES public."Role"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: RuleSimulationDetail RuleSimulationDetail_simulationId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."RuleSimulationDetail"
    ADD CONSTRAINT "RuleSimulationDetail_simulationId_fkey" FOREIGN KEY ("simulationId") REFERENCES public."RuleSimulation"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: TimeEntry TimeEntry_importBatchId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."TimeEntry"
    ADD CONSTRAINT "TimeEntry_importBatchId_fkey" FOREIGN KEY ("importBatchId") REFERENCES public."ImportBatch"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: TimeEntry TimeEntry_odooEmployeeId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."TimeEntry"
    ADD CONSTRAINT "TimeEntry_odooEmployeeId_fkey" FOREIGN KEY ("odooEmployeeId") REFERENCES public."OdooEmployee"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: TimeEntry TimeEntry_shiftId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."TimeEntry"
    ADD CONSTRAINT "TimeEntry_shiftId_fkey" FOREIGN KEY ("shiftId") REFERENCES public."Shift"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: UserPermissionOverride UserPermissionOverride_permissionId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."UserPermissionOverride"
    ADD CONSTRAINT "UserPermissionOverride_permissionId_fkey" FOREIGN KEY ("permissionId") REFERENCES public."Permission"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: UserPermissionOverride UserPermissionOverride_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."UserPermissionOverride"
    ADD CONSTRAINT "UserPermissionOverride_userId_fkey" FOREIGN KEY ("userId") REFERENCES public."User"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: UserRole UserRole_roleId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."UserRole"
    ADD CONSTRAINT "UserRole_roleId_fkey" FOREIGN KEY ("roleId") REFERENCES public."Role"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: UserRole UserRole_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."UserRole"
    ADD CONSTRAINT "UserRole_userId_fkey" FOREIGN KEY ("userId") REFERENCES public."User"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: User User_odooEmployeeId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."User"
    ADD CONSTRAINT "User_odooEmployeeId_fkey" FOREIGN KEY ("odooEmployeeId") REFERENCES public."OdooEmployee"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- PostgreSQL database dump complete
--

