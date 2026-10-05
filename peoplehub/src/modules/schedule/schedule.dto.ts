import { CalendarEventType, DayType, EventScope } from '@prisma/client';
import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  ArrayNotEmpty,
  IsArray,
  IsBoolean,
  IsDateString,
  IsEnum,
  IsInt,
  IsOptional,
  IsString,
  Matches,
  Max,
  Min,
  ValidateNested,
} from 'class-validator';

const HHMM = /^([01]\d|2[0-3]):[0-5]\d$/;

export class CreateShiftDto {
  @IsString() code: string;
  @IsString() name: string;
  @Matches(HHMM, { message: 'startTime harus HH:mm (00:00 - 23:59)' }) startTime: string;
  @IsInt() @Min(1) @Max(1440) durationMinutes: number;
  @IsOptional() @IsInt() @Min(0) breakMinutes?: number;
}

export class UpdateShiftDto {
  @IsOptional() @IsString() name?: string;
  @IsOptional() @Matches(HHMM) startTime?: string;
  @IsOptional() @IsInt() @Min(1) @Max(1440) durationMinutes?: number;
  @IsOptional() @IsInt() @Min(0) breakMinutes?: number;
  @IsOptional() @IsBoolean() isActive?: boolean;
}

export class UpsertScheduleDto {
  @IsString() odooEmployeeId: string;
  @IsDateString() workDate: string;
  @IsEnum(DayType) dayType: DayType;
  @IsOptional() @IsString() shiftId?: string;
}

export class BulkScheduleDto {
  @IsArray() @ArrayNotEmpty() @ArrayMaxSize(1000) @ValidateNested({ each: true }) @Type(() => UpsertScheduleDto)
  items: UpsertScheduleDto[];
}

export class ListScheduleQuery {
  @IsOptional() @IsString() odooEmployeeId?: string;
  @IsOptional() @IsString() workLocationId?: string;
  @IsDateString() from: string;
  @IsDateString() to: string;
}

export class CreateCalendarEventDto {
  @IsOptional() @IsString() externalRef?: string;
  @IsEnum(CalendarEventType) eventType: CalendarEventType;
  @IsEnum(EventScope) scope: EventScope;
  @IsOptional() @IsString() workLocationId?: string;
  @IsOptional() @IsString() odooEmployeeId?: string;
  @IsDateString() startDate: string;
  @IsDateString() endDate: string;
  @IsBoolean() cancelsWorkday: boolean;
  @IsOptional() @IsBoolean() skipGeofence?: boolean;
  @IsString() name: string;
}

export class ListCalendarQuery {
  @IsDateString() from: string;
  @IsDateString() to: string;
  @IsOptional() @IsString() workLocationId?: string;
}
