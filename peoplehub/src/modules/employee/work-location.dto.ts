import { LocationType } from '@prisma/client';
import { IsBoolean, IsEnum, IsInt, IsLatitude, IsLongitude, IsOptional, IsString, Min } from 'class-validator';

export class CreateWorkLocationDto {
  @IsString() code: string;
  @IsString() name: string;
  @IsEnum(LocationType) type: LocationType;
  @IsOptional() @IsString() timezone?: string;
  @IsOptional() @IsLatitude() latitude?: number;
  @IsOptional() @IsLongitude() longitude?: number;
  @IsOptional() @IsInt() @Min(0) geofenceRadiusMeters?: number;
  @IsOptional() @IsBoolean() isActive?: boolean;
}

export class UpdateWorkLocationDto {
  @IsOptional() @IsString() name?: string;
  @IsOptional() @IsEnum(LocationType) type?: LocationType;
  @IsOptional() @IsString() timezone?: string;
  @IsOptional() @IsLatitude() latitude?: number;
  @IsOptional() @IsLongitude() longitude?: number;
  @IsOptional() @IsInt() @Min(0) geofenceRadiusMeters?: number;
  @IsOptional() @IsBoolean() isActive?: boolean;
}
