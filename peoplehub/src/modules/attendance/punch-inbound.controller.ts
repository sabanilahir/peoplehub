import { Body, Controller, HttpCode, Post, UseGuards } from '@nestjs/common';
import { Public } from '../../common/decorators/public.decorator';
import { PunchApiKeyGuard } from '../../common/guards/api-key.guard';
import { PunchBatchDto } from './punch-ingest.dto';
import { PunchIngestService } from './punch-ingest.service';

@Controller('inbound/punches')
export class PunchInboundController {
  constructor(private readonly ingest: PunchIngestService) {}

  /** Webhook punch fingerprint. Autentikasi: header x-api-key (bukan JWT). */
  @Public()
  @UseGuards(PunchApiKeyGuard)
  @HttpCode(200)
  @Post()
  receive(@Body() dto: PunchBatchDto) {
    return this.ingest.ingest(dto);
  }
}
