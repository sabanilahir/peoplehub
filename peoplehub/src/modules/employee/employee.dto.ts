import { Type } from 'class-transformer';
import { IsBoolean, IsDateString, IsEmail, IsInt, IsOptional, IsString, Max, Min } from 'class-validator';

export class CreateEmployeeDto {
  /** Tanggal mulai kerja (YYYY-MM-DD): dasar masa kerja dan saldo cuti. */
  @IsOptional() @IsDateString() hireDate?: string;
  @IsInt() odooId: number;
  @IsOptional() @IsString() nik?: string;
  @IsString() name: string;
  @IsOptional() @IsEmail() email?: string;
  @IsOptional() @IsString() jobTitle?: string;
  @IsOptional() @IsString() jobGrade?: string;
  @IsOptional() @IsInt() parentOdooId?: number;
  @IsString() workLocationId: string;
}

export class UpdateEmployeeDto {
  /** null = kosongkan. */
  @IsOptional() @IsDateString() hireDate?: string | null;
  @IsOptional() @IsString() nik?: string;
  @IsOptional() @IsString() name?: string;
  @IsOptional() @IsEmail() email?: string;
  @IsOptional() @IsString() jobTitle?: string;
  @IsOptional() @IsString() jobGrade?: string;
  @IsOptional() @IsInt() parentOdooId?: number;
  @IsOptional() @IsString() workLocationId?: string;
  @IsOptional() @IsBoolean() isActive?: boolean;
}

export class ListEmployeeQuery {
  @IsOptional() @IsString() q?: string;
  @IsOptional() @IsString() workLocationId?: string;
  @IsOptional() @Type(() => Number) @IsInt() @Min(1) page?: number;
  @IsOptional() @Type(() => Number) @IsInt() @Min(1) @Max(200) pageSize?: number;
}
