export interface CsvRecord {
  /** Nomor baris fisik di file (1 = header). */
  line: number;
  cells: string[];
}

export interface ParsedCsv {
  headers: string[];
  records: CsvRecord[];
  delimiter: string;
}

/** Deteksi pemisah dari baris pertama: koma, titik koma (Excel regional Indonesia), atau tab. */
function detectDelimiter(text: string): string {
  const firstLine = text.split(/\r?\n/, 1)[0] ?? '';
  const counts = [',', ';', '\t'].map((d) => [d, firstLine.split(d).length - 1] as const);
  counts.sort((a, b) => b[1] - a[1]);
  return counts[0][1] > 0 ? counts[0][0] : ',';
}

/** Parser CSV RFC 4180: kutip ganda, koma di dalam kutip, baris baru di dalam kutip, BOM, CRLF/LF. */
export function parseCsv(input: string): ParsedCsv {
  const text = input.replace(/^﻿/, '');
  const delimiter = detectDelimiter(text);

  const rows: CsvRecord[] = [];
  let cells: string[] = [];
  let cell = '';
  let inQuotes = false;
  let line = 1;
  let recordLine = 1;

  const endCell = () => {
    cells.push(cell);
    cell = '';
  };
  const endRecord = () => {
    endCell();
    // Lewati baris kosong total
    if (!(cells.length === 1 && cells[0].trim() === '')) rows.push({ line: recordLine, cells });
    cells = [];
  };

  for (let i = 0; i < text.length; i++) {
    const ch = text[i];
    if (inQuotes) {
      if (ch === '"') {
        if (text[i + 1] === '"') {
          cell += '"';
          i++;
        } else {
          inQuotes = false;
        }
      } else {
        if (ch === '\n') line++;
        cell += ch;
      }
      continue;
    }
    if (ch === '"' && cell === '') {
      inQuotes = true;
    } else if (ch === delimiter) {
      endCell();
    } else if (ch === '\r') {
      // diabaikan; \n yang menutup baris
    } else if (ch === '\n') {
      endRecord();
      line++;
      recordLine = line;
    } else {
      cell += ch;
    }
  }
  if (inQuotes) throw new Error('File CSV tidak valid: tanda kutip tidak ditutup.');
  if (cell !== '' || cells.length > 0) endRecord();

  const [head, ...records] = rows;
  return {
    headers: (head?.cells ?? []).map((h) => h.trim().toLowerCase()),
    records,
    delimiter,
  };
}

function escapeCell(v: string): string {
  return /[",\r\n]/.test(v) ? `"${v.replace(/"/g, '""')}"` : v;
}

/** Tulis CSV (pemisah koma, akhir baris CRLF agar aman di Excel). */
export function toCsv(rows: (string | number | null | undefined)[][]): string {
  return rows.map((r) => r.map((c) => escapeCell(c === null || c === undefined ? '' : String(c))).join(',')).join('\r\n') + '\r\n';
}
