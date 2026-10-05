// Hapus semua data contoh PeopleHub (berprefiks DEMO-). Data lain tidak disentuh.
//   npm run sample:reset
const fs = require('node:fs');
const path = require('node:path');

for (const line of fs.readFileSync(path.join(__dirname, '..', '.env'), 'utf8').split(/\r?\n/)) {
  const m = /^([A-Z_]+)="?([^"]*)"?$/.exec(line.trim());
  if (m && !process.env[m[1]]) process.env[m[1]] = m[2];
}
const { PrismaClient } = require('@prisma/client');
const p = new PrismaClient();

(async () => {
  const locs = (await p.workLocation.findMany({ where: { code: { startsWith: 'DEMO-' } }, select: { id: true } })).map((x) => x.id);
  const emps = (await p.odooEmployee.findMany({ where: { OR: [{ odooId: { gte: 9101, lte: 9110 } }, { nik: { startsWith: 'DEMO-' } }] }, select: { id: true } })).map((x) => x.id);
  const devs = (await p.device.findMany({ where: { serialNumber: { startsWith: 'DEMO-' } }, select: { id: true } })).map((x) => x.id);
  const rules = (await p.attendanceRule.findMany({ where: { workLocationId: { in: locs } }, select: { id: true } })).map((x) => x.id);

  const out = {};
  out.entriWaktu = (await p.timeEntry.deleteMany({ where: { odooEmployeeId: { in: emps } } })).count;
  out.rekapHarian = (await p.attendanceDaily.deleteMany({ where: { odooEmployeeId: { in: emps } } })).count;
  out.logAbsensi = (await p.attendanceLog.deleteMany({ where: { odooEmployeeId: { in: emps } } })).count;
  out.punch = (await p.attendanceRawPunch.deleteMany({ where: { OR: [{ odooEmployeeId: { in: emps } }, { deviceId: { in: devs } }] } })).count;
  out.pemetaanPin = (await p.employeeDeviceMap.deleteMany({ where: { deviceId: { in: devs } } })).count;
  out.mesin = (await p.device.deleteMany({ where: { id: { in: devs } } })).count;
  out.jadwal = (await p.employeeSchedule.deleteMany({ where: { odooEmployeeId: { in: emps } } })).count;
  out.cuti = (await p.leaveRequest.deleteMany({ where: { OR: [{ odooEmployeeId: { in: emps } }, { externalRef: { startsWith: 'DEMO-' } }] } })).count;
  out.kalender = (await p.calendarEvent.deleteMany({ where: { name: { startsWith: 'DEMO' } } })).count;
  out.audit = (await p.auditLog.deleteMany({ where: { entityId: { in: rules } } })).count;
  out.aturan = (await p.attendanceRule.deleteMany({ where: { workLocationId: { in: locs } } })).count;
  out.karyawan = (await p.odooEmployee.deleteMany({ where: { id: { in: emps } } })).count;
  out.lokasi = (await p.workLocation.deleteMany({ where: { id: { in: locs } } })).count;
  out.shift = (await p.shift.deleteMany({ where: { code: { startsWith: 'DEMO-' } } })).count;
  // Proses impor dari file contoh (log ikut terhapus)
  out.prosesImpor = (await p.importBatch.deleteMany({ where: { fileName: 'time-entries-sample.csv' } })).count;

  console.log('Data contoh dihapus:', JSON.stringify(out));
  console.log('Catatan: aturan cuti (konfigurasi global) tidak dihapus; ubah lewat halaman Aturan Cuti.');
  await p.$disconnect();
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
