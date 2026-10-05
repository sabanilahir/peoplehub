import { IsDateString, IsInt, IsOptional, IsString, Min } from 'class-validator';

export class CreateAttendanceRuleDto {
  @IsString() workLocationId: string;
  @IsDateString() effectiveFrom: string;

  /** Masuk setelah shiftStart + grace dianggap terlambat. */
  @IsInt() @Min(0) gracePeriodMinutes: number;

  /** Jendela penerimaan punch relatif terhadap shift (default 240 / 360 menit). */
  @IsOptional() @IsInt() @Min(0) preShiftWindowMinutes?: number;
  @IsOptional() @IsInt() @Min(0) postShiftWindowMinutes?: number;
}
