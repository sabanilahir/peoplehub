// Sample data PeopleHub: 10 karyawan dengan beragam skenario absensi (September 2026).
//   npm run sample:load    -> muat data lewat API (API harus berjalan)
//   npm run sample:reset   -> hapus semua data contoh (berprefiks DEMO-)
// Idempoten: aman dijalankan berulang. Memakai kode jalur sebenarnya (login, webhook punch, inbound cuti).

import { readFileSync, mkdirSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..');

// ---------------------------------------------------------------- konfigurasi
const env = {};
for (const line of readFileSync(join(ROOT, '.env'), 'utf8').split(/\r?\n/)) {
  const m = /^([A-Z_]+)="?([^"]*)"?$/.exec(line.trim());
  if (m) env[m[1]] = m[2];
}
const API = process.env.API_URL ?? `http://localhost:${env.PORT ?? 3100}/api`;

async function call(method, path, body, headers = {}) {
  const res = await fetch(`${API}${path}`, {
    method,
    headers: { 'content-type': 'application/json', ...headers },
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  const text = await res.text();
  const data = text ? JSON.parse(text) : null;
  if (!res.ok) throw new Error(`${method} ${path} -> ${res.status} ${text.slice(0, 300)}`);
  return data;
}

const login = await call('POST', '/auth/login', { email: env.SEED_ADMIN_EMAIL, password: env.SEED_ADMIN_PASSWORD });
const auth = { Authorization: `Bearer ${login.accessToken}` };
const get = (p) => call('GET', p, undefined, auth);
const post = (p, b) => call('POST', p, b, auth);
const put = (p, b) => call('PUT', p, b, auth);
const patch = (p, b) => call('PATCH', p, b, auth);

// ---------------------------------------------------------------- waktu
const OFFSET = { JKT: 7, MKS: 8, JYP: 9 }; // jam di timur UTC (WIB, WITA, WIT)
const pad = (n) => String(n).padStart(2, '0');
const hm = (mins) => `${pad(Math.floor(mins / 60))}:${pad(mins % 60)}`;
const toMin = (t) => Number(t.slice(0, 2)) * 60 + Number(t.slice(3, 5));
/** Waktu lokal lokasi -> ISO UTC. dayShift=1 berarti tanggal berikutnya (shift lintas hari). */
const utc = (loc, date, time, dayShift = 0) => {
  const [y, m, d] = date.split('-').map(Number);
  return new Date(Date.UTC(y, m - 1, d + dayShift, Number(time.slice(0, 2)) - OFFSET[loc], Number(time.slice(3, 5)))).toISOString();
};
const YEAR = 2026;
const MONTH = 9;
const dates = Array.from({ length: 30 }, (_, i) => {
  const d = i + 1;
  return { d, date: `${YEAR}-${pad(MONTH)}-${pad(d)}`, dow: new Date(Date.UTC(YEAR, MONTH - 1, d)).getUTCDay() };
});
const isWeekend = (x) => x.dow === 0 || x.dow === 6;
const HOLIDAY = 16; // libur perusahaan (semua lokasi)
const MKS_HOLIDAY = 22; // cuti bersama khusus Makassar

// ---------------------------------------------------------------- master
const LOC = [
  { key: 'JKT', code: 'DEMO-JKT', name: 'DEMO Kantor Pusat Jakarta', type: 'HO', timezone: 'Asia/Jakarta', grace: 10 },
  { key: 'MKS', code: 'DEMO-MKS', name: 'DEMO Cabang Makassar', type: 'BRANCH', timezone: 'Asia/Makassar', grace: 5 },
  { key: 'JYP', code: 'DEMO-JYP', name: 'DEMO Cabang Jayapura', type: 'BRANCH', timezone: 'Asia/Jayapura', grace: 15 },
];
const SHIFT = [
  { code: 'DEMO-PAGI', name: 'DEMO Shift Pagi', startTime: '08:00', durationMinutes: 480, breakMinutes: 60 },
  { code: 'DEMO-SORE', name: 'DEMO Shift Sore', startTime: '16:00', durationMinutes: 480, breakMinutes: 60 },
  { code: 'DEMO-MALAM', name: 'DEMO Shift Malam', startTime: '22:00', durationMinutes: 480, breakMinutes: 60 },
];
const SHIFT_START = { 'DEMO-PAGI': '08:00', 'DEMO-SORE': '16:00', 'DEMO-MALAM': '22:00' };

/**
 * Setiap karyawan: skenario + fungsi yang memutuskan kejadian tiap hari kerja.
 * Hasil `day(ctx)`: { kind: 'normal', in, out, outShift? } | { kind: 'absent' | 'incomplete' | 'leave', in? }
 * ctx: { d, i } (tanggal & urutan hari kerja yang benar-benar masuk).
 */
const EMP = [
  {
    n: 1, hire: '2018-03-01', loc: 'JKT', shift: 'DEMO-PAGI', name: 'Budi Santoso', job: 'Manajer Operasional', grade: 'M2', manager: null,
    scenario: 'Selalu tepat waktu (datang 07:50-08:05, masih dalam toleransi)',
    day: ({ i }) => ({ kind: 'normal', in: hm(470 + (i % 4) * 5), out: hm(960 + (i % 3) * 15) }),
  },
  {
    n: 2, hire: '2022-05-16', loc: 'JKT', shift: 'DEMO-PAGI', name: 'Sari Wulandari', job: 'Staf Administrasi', grade: 'S1', manager: 1,
    scenario: 'Sering terlambat (08:25 dan 08:40) di atas toleransi 10 menit',
    day: ({ i }) => ({ kind: 'normal', in: i % 5 === 0 ? '08:40' : i % 3 === 0 ? '08:25' : '08:05', out: '16:30' }),
  },
  {
    n: 3, hire: '2024-01-10', loc: 'JKT', shift: 'DEMO-PAGI', name: 'Agus Pratama', job: 'Staf Gudang', grade: 'S1', manager: 1,
    scenario: 'Alpa (9 & 23 Sep) dan lupa absen pulang (11 & 28 Sep)',
    day: ({ d, i }) =>
      d === 9 || d === 23 ? { kind: 'absent' } : d === 11 || d === 28 ? { kind: 'incomplete', in: '08:02' } : { kind: 'normal', in: hm(480 + (i % 3) * 3), out: '16:10' },
  },
  {
    n: 4, hire: '2025-09-08', loc: 'JKT', shift: 'DEMO-PAGI', name: 'Dewi Lestari', job: 'Staf Keuangan', grade: 'S2', manager: 1,
    scenario: 'Cuti tahunan 8-10 Sep (TEPAT 1 tahun masa kerja pada 8 Sep, lolos syarat) dan cuti sakit setengah hari 21 Sep (via inbound)',
    day: ({ d }) => ([8, 9, 10, 21].includes(d) ? { kind: 'leave' } : { kind: 'normal', in: '07:55', out: '16:05' }),
  },
  {
    n: 5, hire: '2025-11-03', loc: 'JKT', shift: 'DEMO-SORE', name: 'Rizky Ramadhan', job: 'Operator Produksi', grade: 'S1', manager: 1,
    scenario: 'Shift sore 16:00-00:00 (pulang lewat tengah malam), terlambat 14 Sep; shift 30 Sep selesai 1 Okt tetap milik September',
    day: ({ d, i }) => ({ kind: 'normal', in: d === 14 ? '16:35' : hm(950 + (i % 3) * 5), out: hm(5 + (i % 3) * 5), outShift: 1 }),
  },
  {
    n: 6, hire: '2019-07-01', loc: 'MKS', shift: 'DEMO-PAGI', name: 'Maria Magdalena', job: 'Kepala Cabang', grade: 'M1', manager: 1,
    scenario: 'Cabang Makassar (WITA), tepat waktu; 22 Sep libur cuti bersama khusus Makassar',
    day: () => ({ kind: 'normal', in: '07:58', out: '16:02' }),
  },
  {
    n: 7, hire: '2023-02-20', loc: 'MKS', shift: 'DEMO-MALAM', name: 'Yohanes Tampubolon', job: 'Satpam', grade: 'S1', manager: 6,
    scenario: 'Shift malam 22:00-06:00 (WITA), terlambat 20 menit pada 10 Sep (toleransi cabang 5 menit)',
    day: ({ d, i }) => ({ kind: 'normal', in: d === 10 ? '22:20' : hm(1315 + (i % 3) * 5), out: '06:05', outShift: 1 }),
  },
  {
    n: 8, hire: '2021-08-09', loc: 'JKT', shift: 'DEMO-PAGI', name: 'Siti Aminah', job: 'Staf Produksi', grade: 'S2', manager: 1,
    scenario: 'Sering lembur (pulang 19:30), masuk Sabtu 12 & 19 Sep (jadwal libur) dan Minggu 6 Sep tanpa jadwal',
    day: ({ i }) => ({ kind: 'normal', in: '08:00', out: i % 4 === 0 ? '19:30' : '16:00' }),
    extra: [
      { date: '2026-09-12', in: '09:00', out: '13:00' },
      { date: '2026-09-19', in: '09:00', out: '13:00' },
      { date: '2026-09-06', in: '10:00', out: '14:00', unscheduled: true },
    ],
  },
  {
    n: 9, hire: '2024-06-17', loc: 'JYP', shift: 'DEMO-PAGI', name: 'Hendra Wijaya', job: 'Staf Lapangan', grade: 'S1', manager: 6, until: 15, inactive: true,
    scenario: 'Cabang Jayapura (WIT), resign 15 Sep (nonaktif); 8:12 masih dalam toleransi 15 menit, 8:20 terlambat',
    day: ({ d }) => ({ kind: 'normal', in: d === 4 ? '08:12' : d === 10 ? '08:20' : '07:58', out: '16:00' }),
  },
  {
    n: 10, hire: '2026-03-15', loc: 'JKT', shift: 'DEMO-PAGI', name: 'Kevin Anggara', job: 'Staf IT', grade: 'S2', manager: 1, noNik: true,
    scenario: 'Hadir normal, TANPA NIK (dilewati impor/ekspor time entries); masa kerja baru 6 bulan sehingga annual leave ditolak',
    day: ({ i }) => ({ kind: 'normal', in: hm(475 + (i % 3) * 4), out: '16:00' }),
  },
];
const odooId = (n) => 9100 + n;
const nik = (e) => (e.noNik ? undefined : `DEMO-${pad(e.n).padStart(3, '0')}`);
const pin = (e) => String(100 + e.n);

// ---------------------------------------------------------------- 1. master data
console.log('1/7 Master data…');
const locations = await get('/work-locations');
const locId = {};
for (const l of LOC) {
  const found = locations.find((x) => x.code === l.code);
  locId[l.key] = (found ?? (await post('/work-locations', { code: l.code, name: l.name, type: l.type, timezone: l.timezone }))).id;
}

const shifts = await get('/shifts');
const shiftId = {};
for (const s of SHIFT) {
  shiftId[s.code] = (shifts.find((x) => x.code === s.code) ?? (await post('/shifts', s))).id;
}

for (const l of LOC) {
  const rules = await get(`/attendance-rules?workLocationId=${locId[l.key]}`);
  if (rules.length === 0) await post('/attendance-rules', { workLocationId: locId[l.key], effectiveFrom: '2026-01-01', gracePeriodMinutes: l.grace });
}

const existing = (await get('/employees?q=DEMO&pageSize=200')).items;
const existingAll = (await get('/employees?pageSize=200')).items.filter((e) => e.odooId >= 9101 && e.odooId <= 9110);
const empId = {};
for (const e of EMP) {
  const found = [...existing, ...existingAll].find((x) => x.odooId === odooId(e.n));
  const body = {
    odooId: odooId(e.n),
    nik: nik(e),
    name: e.name,
    email: `${e.name.toLowerCase().replace(/\s+/g, '.')}@contoh.co.id`,
    jobTitle: e.job,
    jobGrade: e.grade,
    hireDate: e.hire,
    parentOdooId: e.manager ? odooId(e.manager) : undefined,
    workLocationId: locId[e.loc],
  };
  const row = found ?? (await post('/employees', body));
  if (found && (found.hireDate ?? '').slice(0, 10) !== e.hire) await patch(`/employees/${found.id}`, { hireDate: e.hire });
  empId[e.n] = row.id;
}

// ---------------------------------------------------------------- 2. kalender
console.log('2/7 Kalender…');
const events = await get(`/calendar-events?from=${YEAR}-01-01&to=${YEAR}-12-31`);
const wantEvents = [
  { name: 'DEMO Libur Perusahaan', eventType: 'COMPANY_EVENT', scope: 'GLOBAL', date: `2026-09-${HOLIDAY}`, cancelsWorkday: true },
  { name: 'DEMO Cuti Bersama Makassar', eventType: 'COLLECTIVE_LEAVE', scope: 'LOCATION', workLocationId: locId.MKS, date: `2026-09-${MKS_HOLIDAY}`, cancelsWorkday: true },
  { name: 'DEMO Pelatihan K3', eventType: 'TRAINING', scope: 'GLOBAL', date: '2026-09-24', cancelsWorkday: false },
];
for (const ev of wantEvents) {
  if (events.some((x) => x.name === ev.name)) continue;
  const { date, ...rest } = ev;
  await post('/calendar-events', { ...rest, startDate: date, endDate: date });
}

// ---------------------------------------------------------------- 3. jadwal
console.log('3/7 Jadwal…');
const scheduleItems = [];
const plan = {}; // `${n}|${date}` -> ekspektasi
for (const e of EMP) {
  const last = e.until ?? 30;
  for (const x of dates.filter((y) => y.d <= last)) {
    const key = `${e.n}|${x.date}`;
    const unscheduled = e.extra?.find((s) => s.date === x.date && s.unscheduled);
    if (unscheduled) continue; // sengaja tanpa jadwal
    if (isWeekend(x)) {
      scheduleItems.push({ odooEmployeeId: empId[e.n], workDate: x.date, dayType: 'OFFDAY' });
      plan[key] = { status: 'OFFDAY' };
    } else {
      scheduleItems.push({ odooEmployeeId: empId[e.n], workDate: x.date, dayType: 'WORKDAY', shiftId: shiftId[e.shift] });
    }
  }
}
for (let i = 0; i < scheduleItems.length; i += 500) {
  const r = await post('/schedules/bulk', { items: scheduleItems.slice(i, i + 500) });
  if (r.failed > 0) throw new Error(`Jadwal gagal: ${JSON.stringify(r.errors.slice(0, 3))}`);
}

// ---------------------------------------------------------------- 4. aturan cuti + cuti (inbound)
console.log('4/7 Aturan cuti & cuti (inbound)…');
const annualRules = await get('/leave-rules?leaveKind=ANNUAL');
if (annualRules.length === 0) {
  await post('/leave-rules', { leaveKind: 'ANNUAL', effectiveFrom: '2026-01-01', minTenureMonths: 12, accrualMode: 'ANNIVERSARY', entitlementDays: 12, firstGrantAnniversary: 1, expiryMonths: 12 });
}
const leave = await post('/inbound/leave-requests', {
  items: [
    { externalRef: 'DEMO-LV-001', nik: 'DEMO-004', startDate: '2026-09-08', endDate: '2026-09-10', kind: 'ANNUAL', reason: 'Cuti tahunan (contoh)' },
    { externalRef: 'DEMO-LV-002', nik: 'DEMO-004', startDate: '2026-09-21', endDate: '2026-09-21', days: 0.5, kind: 'SICK', reason: 'Sakit (contoh)' },
  ],
});
if (leave.failed > 0) throw new Error(`Cuti gagal: ${JSON.stringify(leave.errors)}`);

// Demonstrasi validasi masa kerja: dua pengajuan annual leave ini HARUS ditolak
const rejected = await post('/inbound/leave-requests', {
  items: [
    { externalRef: 'DEMO-LV-X1', nik: 'DEMO-005', startDate: '2026-09-22', endDate: '2026-09-23', kind: 'ANNUAL' },
    { externalRef: 'DEMO-LV-X2', odooId: odooId(10), startDate: '2026-09-22', endDate: '2026-09-22', kind: 'ANNUAL' },
  ],
});
console.log(`     validasi masa kerja: ${rejected.failed}/2 annual leave ditolak (diharapkan 2)`);
rejected.errors.forEach((x) => console.log(`       - ${x.externalRef}: ${x.message}`));
if (rejected.failed !== 2) throw new Error('Validasi masa kerja tidak menolak annual leave yang seharusnya ditolak.');
const dewi = await get(`/leave-rules/check?employeeId=${empId[4]}&leaveKind=ANNUAL&startDate=2026-09-30`);
console.log(`     saldo Dewi per 30 Sep: aktif ${dewi.balance.grantedActive}, terpakai ${dewi.balance.used}, sisa ${dewi.balance.remaining} hari; anniversary berikutnya ${dewi.balance.nextAnniversary?.date}`);

// ---------------------------------------------------------------- 5. mesin & PIN
console.log('5/7 Mesin fingerprint…');
const devices = await get('/devices');
const deviceSerial = { JKT: 'DEMO-SN-JKT', MKS: 'DEMO-SN-MKS', JYP: 'DEMO-SN-JYP' };
const deviceId = {};
for (const l of LOC) {
  const found = devices.find((d) => d.serialNumber === deviceSerial[l.key]);
  deviceId[l.key] = (found ?? (await post('/devices', { serialNumber: deviceSerial[l.key], name: `DEMO Mesin ${l.key}`, vendor: 'ZKTeco', workLocationId: locId[l.key] }))).id;
}
for (const l of LOC) {
  const maps = await get(`/devices/${deviceId[l.key]}/mappings`);
  for (const e of EMP.filter((x) => x.loc === l.key)) {
    if (!maps.some((m) => m.enrollId === pin(e))) await post(`/devices/${deviceId[l.key]}/mappings`, { enrollId: pin(e), odooEmployeeId: empId[e.n] });
  }
}

// ---------------------------------------------------------------- 6. punch (webhook)
console.log('6/7 Punch fingerprint (webhook)…');
const punchesByLoc = { JKT: [], MKS: [], JYP: [] };
const leaveDays = new Set([8, 9, 10, 21]);

for (const e of EMP) {
  const startMin = toMin(SHIFT.find((s) => s.code === e.shift).startTime);
  const grace = LOC.find((l) => l.key === e.loc).grace;
  const push = (date, time, dayShift = 0) => punchesByLoc[e.loc].push({ enrollId: pin(e), punchAt: utc(e.loc, date, time, dayShift) });

  let i = 0;
  for (const x of dates.filter((y) => y.d <= (e.until ?? 30))) {
    if (isWeekend(x)) {
      const extra = e.extra?.find((s) => s.date === x.date);
      if (extra) {
        push(x.date, extra.in);
        push(x.date, extra.out);
        plan[`${e.n}|${x.date}`] = { status: extra.unscheduled ? 'PRESENT' : 'OFFDAY', late: 0 };
      }
      continue;
    }
    const key = `${e.n}|${x.date}`;
    if (x.d === HOLIDAY || (e.loc === 'MKS' && x.d === MKS_HOLIDAY)) {
      plan[key] = { status: 'HOLIDAY' };
      continue;
    }
    const ev = e.day({ d: x.d, i });
    i++;
    if (ev.kind === 'leave') { plan[key] = { status: 'ON_LEAVE' }; continue; }
    if (ev.kind === 'absent') { plan[key] = { status: 'ABSENT' }; continue; }
    if (ev.kind === 'incomplete') { push(x.date, ev.in); plan[key] = { status: 'INCOMPLETE' }; continue; }
    push(x.date, ev.in);
    push(x.date, ev.out, ev.outShift ?? 0);
    const late = Math.max(0, toMin(ev.in) - startMin);
    plan[key] = { status: late > grace ? 'LATE' : 'PRESENT', late };
  }
}

let sent = 0;
let dup = 0;
for (const l of LOC) {
  const list = punchesByLoc[l.key];
  for (let i = 0; i < list.length; i += 1000) {
    const r = await call('POST', '/inbound/punches', { deviceSerial: deviceSerial[l.key], punches: list.slice(i, i + 1000) }, { 'x-api-key': env.PUNCH_API_KEY });
    sent += r.inserted;
    dup += r.duplicates;
  }
}
console.log(`     punch baru: ${sent}, sudah ada: ${dup}`);

// Nonaktifkan karyawan yang resign (setelah datanya terisi)
for (const e of EMP.filter((x) => x.inactive)) await patch(`/employees/${empId[e.n]}`, { isActive: false });

// ---------------------------------------------------------------- 7. hitung ulang + verifikasi
console.log('7/7 Hitung ulang absensi dan verifikasi…');
const rc = await post('/attendance/recompute', { from: '2026-09-01', to: '2026-09-30' });
console.log(`     dihitung ulang: ${rc.employees} karyawan, ${rc.days} hari`);

const daily = (await get('/attendance/daily?from=2026-09-01&to=2026-09-30&pageSize=500')).items;
const byEmp = new Map();
for (const row of daily) {
  const e = EMP.find((x) => x.name === row.employee.name);
  if (!e) continue;
  const k = `${e.n}|${row.workDate.slice(0, 10)}`;
  byEmp.set(k, row);
}

const STATUSES = ['PRESENT', 'LATE', 'ABSENT', 'ON_LEAVE', 'OFFDAY', 'HOLIDAY', 'INCOMPLETE'];
const short = { PRESENT: 'Hadir', LATE: 'Telat', ABSENT: 'Alpa', ON_LEAVE: 'Cuti', OFFDAY: 'Libur', HOLIDAY: 'HariLibur', INCOMPLETE: 'TdkLkp' };
let mismatches = 0;
console.log('\n' + ['#', 'Karyawan'.padEnd(20), ...STATUSES.map((s) => short[s].padStart(9))].join(' '));
for (const e of EMP) {
  const counts = Object.fromEntries(STATUSES.map((s) => [s, 0]));
  for (const x of dates) {
    const exp = plan[`${e.n}|${x.date}`];
    const got = byEmp.get(`${e.n}|${x.date}`);
    if (got) counts[got.status]++;
    if (exp && (!got || got.status !== exp.status || (exp.late !== undefined && got.lateMinutes !== exp.late))) {
      mismatches++;
      console.log(`  ! ${e.name} ${x.date}: harapan ${exp.status}${exp.late !== undefined ? '/' + exp.late : ''}, hasil ${got ? got.status + '/' + got.lateMinutes : 'tidak ada'}`);
    }
  }
  console.log([String(e.n).padStart(2), e.name.padEnd(20), ...STATUSES.map((s) => String(counts[s]).padStart(9))].join(' '));
}
console.log(mismatches === 0 ? '\nVerifikasi: semua hari sesuai skenario.' : `\nVerifikasi: ${mismatches} hari TIDAK sesuai skenario.`);

// ---------------------------------------------------------------- file CSV contoh time entries
const rows = ['employee_number,start_datetime,end_datetime,work_schedule,payroll_period,duration'];
const octDays = [1, 2, 5, 6, 7, 8, 9].map((d) => `2026-10-${pad(d)}`);
const next = (date) => { const [y, m, d] = date.split('-').map(Number); const n = new Date(Date.UTC(y, m - 1, d + 1)); return `${n.getUTCFullYear()}-${pad(n.getUTCMonth() + 1)}-${pad(n.getUTCDate())}`; };
octDays.forEach((date, i) => {
  const withOffset = i % 2 === 0; // selang-seling: ber-offset +07:00 dan waktu lokal tanpa zona
  const f = (dt, t) => (withOffset ? `${dt}T${t}:00+07:00` : `${dt} ${t}`);
  for (const n of [1, 2, 3]) rows.push(`DEMO-00${n},${f(date, '08:00')},${f(date, '16:00')},DEMO-PAGI,2026-10,8`);
  rows.push(`DEMO-008,${f(date, '08:00')},${f(date, '19:00')},DEMO-PAGI,2026-10,10`); // 11 jam dikurangi istirahat 1 jam
  rows.push(`DEMO-005,${f(date, '16:00')},${f(next(date), '00:00')},DEMO-SORE,2026-10,8`);
  if (date <= '2026-10-02') rows.push(`DEMO-004,${f(date, '08:00')},${f(date, '16:00')},DEMO-PAGI,,8`);
});
// Baris yang sengaja salah, untuk melihat pelaporan error di Process Monitor
rows.push('DEMO-999,2026-10-01 08:00,2026-10-01 16:00,DEMO-PAGI,2026-10,8'); //            NIK tidak ada
rows.push('DEMO-001,2026-10-12 08:00,2026-10-12 16:00,DEMO-PAGI,2026-10,delapan'); //     durasi bukan angka
rows.push('DEMO-002,2026-10-12 16:00,2026-10-12 08:00,DEMO-PAGI,2026-10,8'); //           selesai sebelum mulai
rows.push('DEMO-003,2026-10-12 08:00,2026-10-12 16:00,DEMO-XXXX,2026-10,8'); //           kode shift tidak dikenal
rows.push('DEMO-001,2026-10-13 08:00,2026-10-13 16:00,DEMO-PAGI,2026-10-1,8'); //         periode salah format
const csvPath = join(ROOT, 'samples', 'time-entries-sample.csv');
mkdirSync(dirname(csvPath), { recursive: true });
writeFileSync(csvPath, rows.join('\r\n') + '\r\n');
console.log(`\nFile CSV contoh: ${csvPath} (${rows.length - 1} baris, 5 di antaranya sengaja salah)`);
process.exit(mismatches === 0 ? 0 : 1);
