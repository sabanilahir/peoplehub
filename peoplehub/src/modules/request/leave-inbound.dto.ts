import { LeaveKind, RequestStatus } from '@prisma/client';
import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  ArrayNotEmpty,
  IsArray,
  IsDateString,
  IsEnum,
  IsInt,
  IsNumber,
  IsOptional,
  IsString,
  Min,
  ValidateNested,
} from 'class-validator';

export class InboundLeaveItemDto {
  /** ID stabil dari sistem asal (Odoo hr.leave / file). Kunci upsert. */
  @IsString() externalRef: string;

  // Identifikasi karyawan: salah satu wajib. Urutan pencarian: odooId, lalu NIK.
  @IsOptional() @IsInt() odooId?: number;
  @IsOptional() @IsString() nik?: string;

  @IsDateString() startDate: string;
  @IsDateString() endDate: string;
  @IsOptional() @IsNumber({ maxDecimalPlaces: 2 }) @Min(0.5) days?: number;
  @IsOptional() @IsEnum(LeaveKind) kind?: LeaveKind;
  @IsOptional() @IsInt() odooLeaveTypeId?: number;
  @IsOptional() @IsString() reason?: string;

  // Default APPROVED. CANCELLED/REJECTED dipakai bila sistem asal membatalkan cuti yang sudah dikirim.
  @IsOptional() @IsEnum(RequestStatus) status?: RequestStatus;
}

export class InboundLeaveDto {
  @IsArray() @ArrayNotEmpty() @ArrayMaxSize(5000) @ValidateNested({ each: true }) @Type(() => InboundLeaveItemDto)
  items: InboundLeaveItemDto[];
}
