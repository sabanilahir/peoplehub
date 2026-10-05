import { PROCESS_STATUS_LABEL } from "@/lib/labels";
import type { ProcessStatus } from "@/lib/types";
import { Badge } from "./ui";

const TONE = { RECEIVED: "gray", VALIDATING: "blue", APPLIED: "green", PARTIAL: "amber", FAILED: "red" } as const;

export function isActive(status: ProcessStatus) {
  return status === "RECEIVED" || status === "VALIDATING";
}

export function StatusBadge({ status }: { status: ProcessStatus }) {
  return <Badge tone={TONE[status]}>{PROCESS_STATUS_LABEL[status]}</Badge>;
}

export function ProgressBar({ value, status }: { value: number; status: ProcessStatus }) {
  const color = status === "FAILED" ? "bg-red-500" : status === "PARTIAL" ? "bg-amber-500" : status === "APPLIED" ? "bg-emerald-500" : "bg-accent";
  return (
    <div className="flex items-center gap-2">
      <div
        role="progressbar"
        aria-valuenow={value}
        aria-valuemin={0}
        aria-valuemax={100}
        aria-label="Kemajuan proses"
        className="h-2 w-28 overflow-hidden rounded-full bg-border"
      >
        <div className={`h-full ${color} transition-all`} style={{ width: `${value}%` }} />
      </div>
      <span className="w-9 text-xs tabular-nums text-muted">{value}%</span>
    </div>
  );
}
