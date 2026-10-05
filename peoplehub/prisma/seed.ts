import { PrismaClient } from '@prisma/client';
import * as bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

const PERMISSIONS: [code: string, module: string, description: string][] = [
  ['master.location.read', 'master', 'Lihat lokasi kerja'],
  ['master.location.edit', 'master', 'Kelola lokasi kerja'],
  ['master.employee.read', 'master', 'Lihat karyawan'],
  ['master.employee.edit', 'master', 'Kelola karyawan'],
  ['config.attendance.read', 'config', 'Lihat aturan absensi'],
  ['config.attendance.edit', 'config', 'Ubah aturan absensi'],
  ['config.attendance.simulate', 'config', 'Simulasi aturan absensi'],
  ['config.overtime.read', 'config', 'Lihat aturan lembur'],
  ['config.overtime.edit', 'config', 'Ubah aturan lembur'],
  ['config.overtime.simulate', 'config', 'Simulasi aturan lembur'],
  ['schedule.shift.read', 'schedule', 'Lihat shift'],
  ['schedule.shift.edit', 'schedule', 'Kelola shift'],
  ['schedule.roster.read', 'schedule', 'Lihat jadwal karyawan'],
  ['schedule.roster.edit', 'schedule', 'Kelola jadwal karyawan'],
  ['schedule.calendar.read', 'schedule', 'Lihat calendar event'],
  ['schedule.calendar.edit', 'schedule', 'Kelola calendar event'],
  ['leave.request.read', 'leave', 'Lihat pengajuan cuti'],
  ['time.entry.read', 'time', 'Lihat dan unduh time entries'],
  ['leave.rule.read', 'leave', 'Lihat aturan cuti dan saldo'],
  ['leave.rule.edit', 'leave', 'Ubah aturan cuti'],
  ['process.monitor.read', 'process', 'Lihat Process Monitor'],
  ['inbound.time.create', 'inbound', 'Unggah time entries (CSV)'],
  ['inbound.leave.create', 'inbound', 'Kirim data cuti (inbound)'],
  ['overtime.request.read', 'overtime', 'Lihat pengajuan lembur'],
  ['attendance.device.read', 'attendance', 'Lihat mesin fingerprint'],
  ['attendance.device.edit', 'attendance', 'Kelola mesin dan mapping PIN'],
  ['attendance.log.read', 'attendance', 'Lihat absensi'],
  ['attendance.log.edit', 'attendance', 'Koreksi absensi'],
  ['import.batch.read', 'import', 'Lihat riwayat impor'],
  ['import.batch.create', 'import', 'Unggah file impor'],
  ['rbac.role.read', 'rbac', 'Lihat role'],
  ['rbac.role.edit', 'rbac', 'Kelola role dan permission'],
];

async function main() {
  const perms = new Map<string, string>();
  for (const [code, module, description] of PERMISSIONS) {
    const p = await prisma.permission.upsert({
      where: { code },
      update: { module, description },
      create: { code, module, description },
    });
    perms.set(code, p.id);
  }

  const superAdmin = await prisma.role.upsert({
    where: { code: 'SUPER_ADMIN' },
    update: {},
    create: { code: 'SUPER_ADMIN', name: 'Super Admin', isSystem: true },
  });

  // Menu: [code, label, path, icon, sortOrder, parentCode, requiredPermission]
  const MENUS: [string, string, string | null, string, number, string | null, string | null][] = [
    ['master', 'Master Data', null, 'database', 10, null, null],
    ['master.locations', 'Lokasi Kerja', '/master/locations', 'map-pin', 1, 'master', 'master.location.read'],
    ['master.employees', 'Karyawan', '/master/employees', 'users', 2, 'master', 'master.employee.read'],
    ['schedule', 'Jadwal', null, 'calendar', 15, null, null],
    ['schedule.shifts', 'Shift', '/schedule/shifts', 'clock', 1, 'schedule', 'schedule.shift.read'],
    ['schedule.roster', 'Jadwal Karyawan', '/schedule/roster', 'calendar-days', 2, 'schedule', 'schedule.roster.read'],
    ['schedule.calendar', 'Kalender', '/schedule/calendar', 'calendar', 3, 'schedule', 'schedule.calendar.read'],
    ['attendance.daily', 'Rekap Absensi', '/attendance/daily', 'clipboard-check', 12, null, 'attendance.log.read'],
    ['attendance.devices', 'Mesin Fingerprint', '/attendance/devices', 'fingerprint', 13, null, 'attendance.device.read'],
    ['time.entries', 'Time Entries', '/time-entries', 'file-spreadsheet', 14, null, 'time.entry.read'],
    ['process.monitor', 'Process Monitor', '/process-monitor', 'activity', 15, null, 'process.monitor.read'],
    ['requests', 'Pengajuan', null, 'inbox', 16, null, null],
    ['requests.leave', 'Cuti', '/requests/leave', 'plane', 1, 'requests', 'leave.request.read'],
    ['requests.overtime', 'Lembur', '/requests/overtime', 'moon', 3, 'requests', 'overtime.request.read'],
    ['config', 'Konfigurasi Aturan', null, 'settings', 18, null, null],
    ['config.attendance', 'Absensi & Keterlambatan', '/config/attendance', 'alarm-clock', 1, 'config', 'config.attendance.read'],
    ['config.leave', 'Aturan Cuti', '/config/leave', 'plane', 3, 'config', 'leave.rule.read'],
    ['config.overtime', 'Lembur', '/config/overtime', 'moon', 2, 'config', 'config.overtime.read'],
    ['import', 'Impor Data', '/import', 'upload', 20, null, 'import.batch.read'],
  ];
  const menuIds = new Map<string, string>();
  for (const [code, label, path, icon, sortOrder, parentCode, perm] of MENUS) {
    const data = {
      label,
      path,
      icon,
      sortOrder,
      parentId: parentCode ? menuIds.get(parentCode)! : null,
      requiredPermissionId: perm ? perms.get(perm)! : null,
    };
    const m = await prisma.menu.upsert({ where: { code }, update: data, create: { code, ...data } });
    menuIds.set(code, m.id);
  }

  const email = process.env.SEED_ADMIN_EMAIL;
  const password = process.env.SEED_ADMIN_PASSWORD;
  if (email && password) {
    const user = await prisma.user.upsert({
      where: { email },
      update: {},
      create: { email, passwordHash: await bcrypt.hash(password, 10) },
    });
    await prisma.userRole.upsert({
      where: { userId_roleId: { userId: user.id, roleId: superAdmin.id } },
      update: {},
      create: { userId: user.id, roleId: superAdmin.id },
    });
    console.log(`Admin user siap: ${email}`);
  } else {
    console.log('SEED_ADMIN_EMAIL/SEED_ADMIN_PASSWORD tidak diisi: user admin tidak dibuat.');
  }
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
