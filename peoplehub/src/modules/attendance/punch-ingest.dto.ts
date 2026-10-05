import { PunchDirection } from '@prisma/client';
import { Type } from 'class-transformer';
import { ArrayMaxSize, ArrayNotEmpty, IsArray, IsDateString, IsEnum, IsOptional, IsString, ValidateNested } from 'class-validator';

export class PunchItemDto {
  /** PIN / enroll ID karyawan di mesin. */
  @IsString() enrollId: string;
  /** Waktu punch (ISO 8601). Wajib menyertakan offset/Z agar tidak ambigu. */
  @IsDateString() punchAt: string;
  @IsOptional() @IsEnum(PunchDirection) direction?: PunchDirection;
}

export class PunchBatchDto {
  /** Serial number mesin; mesin harus sudah terdaftar. */
  @IsString() deviceSerial: string;
  @IsArray() @ArrayNotEmpty() @ArrayMaxSize(5000) @ValidateNested({ each: true }) @Type(() => PunchItemDto)
  punches: PunchItemDto[];
}
