export interface WorkLocation {
  id: string;
  code: string;
  name: string;
  type: "HO" | "BRANCH";
  timezone: string;
  latitude: string | null;
  longitude: string | null;
  geofenceRadiusMeters: number | null;
  isActive: boolean;
}

export interface Employee {
  id: string;
  odooId: number;
  nik: string | null;
  name: string;
  email: string | null;
  jobTitle: string | null;
  jobGrade: string | null;
  hireDate: string | null;
  isActive: boolean;
  parentOdooId: number | null;
  workLocationId: string;
  workLocation?: { id: string; code: string; name: string };
}

export interface Paged<T> {
  items: T[];
  total: number;
  page: number;
  pageSize: number;
}

export interface Shift {
  id: string;
  code: string;
  name: string;
  startTime: string;
  durationMinutes: number;
  breakMinutes: number;
  isActive: boolean;
}

export interface Schedule {
  id: string;
  odooEmployeeId: string;
  workDate: string;
  dayType: "WORKDAY" | "OFFDAY";
  shiftId: string | null;
  shift?: { code: string; name: string } | null;
}

export interface AttendanceRule {
  id: string;
  workLocationId: string;
  effectiveFrom: string;
  effectiveTo: string | null;
  gracePeriodMinutes: number;
  preShiftWindowMinutes: number;
  postShiftWindowMinutes: number;
}

export type AttendanceStatus =
  | "PRESENT"
  | "LATE"
  | "ABSENT"
  | "ON_LEAVE"
  | "OFFDAY"
  | "HOLIDAY"
  | "INCOMPLETE";

export interface DailyItem {
  id: string;
  workDate: string;
  status: AttendanceStatus;
  clockIn: string | null;
  clockOut: string | null;
  isLate: boolean;
  lateMinutes: number;
  employee: {
    id: string;
    name: string;
    nik: string | null;
    workLocation: { id: string; name: string; timezone: string };
  };
}

export interface Device {
  id: string;
  serialNumber: string;
  vendor: string | null;
  name: string;
  workLocationId: string;
  isActive: boolean;
  _count?: { mappings: number };
}

export interface DeviceMapping {
  id: string;
  enrollId: string;
  odooEmployeeId: string;
  employee: { id: string; name: string; nik: string | null };
}

export type CalendarEventType = "PUBLIC_HOLIDAY" | "COLLECTIVE_LEAVE" | "BUSINESS_TRIP" | "TRAINING" | "COMPANY_EVENT";
export type EventScope = "GLOBAL" | "LOCATION" | "EMPLOYEE";

export interface CalendarEvent {
  id: string;
  externalRef: string | null;
  eventType: CalendarEventType;
  scope: EventScope;
  workLocationId: string | null;
  odooEmployeeId: string | null;
  startDate: string;
  endDate: string;
  cancelsWorkday: boolean;
  skipGeofence: boolean;
  name: string;
  workLocation: { id: string; name: string } | null;
}

export type RequestStatus = "PENDING" | "APPROVED" | "REJECTED" | "CANCELLED";

export interface LeaveItem {
  id: string;
  externalRef: string | null;
  kind: "ANNUAL" | "SICK" | "UNPAID" | "OTHER";
  startDate: string;
  endDate: string;
  days: string;
  reason: string | null;
  source: "PEOPLEHUB" | "IMPORT" | "MANUAL" | "DEFAULT";
  overallStatus: RequestStatus;
  employee: { id: string; name: string; nik: string | null };
}

export interface TimeEntryItem {
  id: string;
  startAt: string;
  endAt: string;
  workDate: string;
  workSchedule: string | null;
  payrollPeriod: string;
  /** Durasi dalam JAM (Decimal dari API dikirim sebagai string). */
  durationHours: string;
  source: "PEOPLEHUB" | "IMPORT" | "MANUAL" | "DEFAULT";
  employee: { id: string; name: string; nik: string | null; workLocation: { timezone: string } };
  shift: { code: string } | null;
}

export type ProcessStatus = "RECEIVED" | "VALIDATING" | "APPLIED" | "PARTIAL" | "FAILED";

export interface ProcessItem {
  id: string;
  fileType: string;
  fileName: string;
  status: ProcessStatus;
  progress: number;
  totalRows: number;
  successRows: number;
  errorRows: number;
  uploadedBy: string | null;
  createdAt: string;
  startedAt: string | null;
  finishedAt: string | null;
  durationSeconds: number | null;
}

export interface ProcessLogItem {
  id: string;
  level: "INFO" | "WARN" | "ERROR";
  message: string;
  createdAt: string;
}

export interface ProcessDetail extends ProcessItem {
  logs: ProcessLogItem[];
}

export interface ProcessRowError {
  rowNumber: number;
  rawLine: string;
  message: string;
}

export type LeaveKindCode = "ANNUAL" | "SICK" | "UNPAID" | "OTHER";

export interface LeaveRuleItem {
  id: string;
  leaveKind: LeaveKindCode;
  effectiveFrom: string;
  effectiveTo: string | null;
  minTenureMonths: number;
  accrualMode: "NONE" | "ANNIVERSARY";
  entitlementDays: string | null;
  firstGrantAnniversary: number;
  expiryMonths: number | null;
}

export interface LeaveGrant {
  anniversary: number;
  date: string;
  days: number;
  expiresAt: string | null;
  expired: boolean;
}

export interface LeaveCheck {
  employee: { id: string; name: string; nik: string | null; hireDate: string | null };
  leaveKind: LeaveKindCode;
  startDate: string;
  rule: LeaveRuleItem | null;
  eligible: boolean;
  reasons: string[];
  tenureMonths: number | null;
  eligibleFrom: string | null;
  minTenureMonths: number;
  balance: {
    asOf: string;
    grants: LeaveGrant[];
    grantedActive: number;
    used: number;
    remaining: number;
    nextAnniversary: { date: string; days: number | null } | null;
  };
}
