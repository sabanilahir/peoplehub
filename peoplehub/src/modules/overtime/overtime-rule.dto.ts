import { OvertimePayableBasis, WorkWeek } from '@prisma/client';
import { Type } from 'class-transformer';
import { IsArray, IsDateString, IsEnum, IsInt, IsNumber, IsOptional, IsString, Min, ValidateNested } from 'class-validator';

export class MultiplierTierDto {
  @IsInt() @Min(1) fromHour: number;
  @IsInt() @Min(1) toHour: number;
  @IsNumber() @Min(1) multiplier: number;
}

export class MultiplierTiersDto {
  @IsArray() @ValidateNested({ each: true }) @Type(() => MultiplierTierDto) WORKDAY: MultiplierTierDto[];
  @IsArray() @ValidateNested({ each: true }) @Type(() => MultiplierTierDto) OFFDAY_HOLIDAY: MultiplierTierDto[];
}

export class CreateOvertimeRuleDto {
  @IsString() workLocationId: string;
  @IsDateString() effectiveFrom: string;
  @IsEnum(WorkWeek) workWeekPattern: WorkWeek;
  @IsOptional() @IsEnum(OvertimePayableBasis) payableBasis?: OvertimePayableBasis;
  @IsOptional() @IsInt() @Min(0) punchToleranceMinutes?: number;
  @IsOptional() @IsInt() @Min(0) minMinutes?: number;
  @IsOptional() @IsInt() @Min(1) roundingMinutes?: number;
  @IsOptional() @IsInt() @Min(1) maxMinutesPerDay?: number;
  @IsOptional() @IsInt() @Min(1) maxMinutesPerWeek?: number;
  @ValidateNested() @Type(() => MultiplierTiersDto) multiplierTiers: MultiplierTiersDto;
  @IsOptional() @IsArray() @IsString({ each: true }) excludedJobGrades?: string[];
}
