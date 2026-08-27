// Generate supabase/seed.sql from js/data.js
// Run: node scripts/generate_seed_sql.js

const fs = require('fs');
const path = require('path');

const dataPath = path.join(__dirname, '..', 'js', 'data.js');
const code = fs.readFileSync(dataPath, 'utf8');
const window = {};
eval(code);
const d = window.dtmsData;

const out = [];
out.push('-- ============================================================');
out.push('-- Seed data for DTMS');
out.push('-- Generated from js/data.js');
out.push('-- Run this in Supabase SQL Editor AFTER schema.sql');
out.push('-- ============================================================');
out.push('');

function esc(v) {
  if (v === null || v === undefined) return 'null';
  if (typeof v === 'boolean') return v ? 'true' : 'false';
  if (typeof v === 'number') return String(v);
  return "'" + String(v).replace(/'/g, "''") + "'";
}

function rowSql(table, obj, columns) {
  const vals = columns.map(c => esc(obj[c]));
  return `insert into public."${table}" (${columns.map(c => '"' + c + '"').join(', ')}) values (${vals.join(', ')}) on conflict do nothing;`;
}

// Supplier mapping
const supplierMap = {
  'PT Auto Parts': 'SUP001',
  'PT Plasticindo': 'SUP002',
  'PT Metalindo': 'SUP003'
};

function supplierId(name) {
  return supplierMap[name] || null;
}

// Users
const userEmail = {
  admin: 'admin@dtms.mail',
  purchasing: 'purchasing@dtms.mail',
  supplier1: 'supplier1@dtms.mail',
  supplier2: 'supplier2@dtms.mail',
  supplier3: 'supplier3@dtms.mail'
};

out.push('-- users');
d.users.forEach(u => {
  const email = userEmail[u.username] || `${u.username}@dtms.local`;
  const obj = {
    id: u.id,
    username: u.username,
    email: email,
    role: u.role,
    name: u.name,
    company: u.company || null,
    supplierId: u.supplierId || null
  };
  out.push(rowSql('users', obj, ['id', 'username', 'email', 'role', 'name', 'company', 'supplierId']));
});
out.push('');

// Toolings
out.push('-- toolings');
d.toolings.forEach(t => {
  const obj = { ...t, supplierId: supplierId(t.supplier) || null };
  // Replace base64 data fields with paths (null in seed)
  obj.paDocumentPath = null;
  obj.drawingDiesPath = null;
  const cols = Object.keys(d.toolings[0]).concat('supplierId', 'createdAt', 'updatedAt');
  // Use the original keys + supplierId
  const finalCols = [
    'id', 'name', 'type', 'partNumber', 'partName', 'model', 'supplier', 'supplierId',
    'supplierAddress', 'status', 'condition', 'owner', 'lifetime', 'maxShoot',
    'lastMaintenance', 'maker', 'weight', 'tonnage', 'dimensions', 'toolImage',
    'toolImage2', 'partImage', 'material', 'depreciationType', 'depreciationValue',
    'qtyDepreciation', 'paNumber', 'paDocumentName', 'paDocumentPath', 'drawingDiesName',
    'drawingDiesPath', 'price', 'notes', 'pic', 'picEmail', 'picPhone', 'qtyPerTooling', 'mapUrl'
  ];
  out.push(rowSql('toolings', obj, finalCols));
});
out.push('');

// Maintenance logs
out.push('-- maintenanceLogs');
d.maintenanceLogs.forEach(m => {
  const obj = { ...m, evidence: m.evidence || null, evidencePath: null };
  delete obj.evidenceData;
  out.push(rowSql('maintenanceLogs', obj, ['id', 'toolId', 'toolName', 'dateStart', 'dateEnd', 'type', 'description', 'status', 'evidence', 'evidencePath', 'requestedBy', 'cost']));
});
out.push('');

// Supplier tasks
out.push('-- supplierTasks');
d.supplierTasks.forEach(t => {
  const obj = { ...t, supplierId: supplierId(t.supplier) || null, evidence: t.evidence || null, evidencePath: null };
  delete obj.evidenceData;
  out.push(rowSql('supplierTasks', obj, ['id', 'toolId', 'toolName', 'supplier', 'supplierId', 'type', 'description', 'assignedDate', 'dueDate', 'status', 'priority', 'completedDate', 'evidence', 'evidencePath']));
});
out.push('');

// Shoot logs
out.push('-- shootLogs');
d.shootLogs.forEach(s => {
  out.push(rowSql('shootLogs', s, ['id', 'toolId', 'month', 'inputDate', 'shootCount']));
});
out.push('');

// Production logs
out.push('-- productionLogs');
if (d.productionLogs && d.productionLogs.length) {
  d.productionLogs.forEach(p => {
    out.push(rowSql('productionLogs', p, ['id', 'toolId', 'shootLogId', 'actualPartOk']));
  });
}
out.push('');

// Delivery logs
out.push('-- deliveryLogs');
d.deliveryLogs.forEach(x => {
  out.push(rowSql('deliveryLogs', x, ['id', 'toolId', 'month', 'inputDate', 'qtyDelivered', 'qtyOk']));
});
out.push('');

// Movement logs
out.push('-- movementLogs');
d.movementLogs.forEach(m => {
  out.push(rowSql('movementLogs', m, ['id', 'toolId', 'toolName', 'fromLocation', 'toLocation', 'date', 'reason', 'status', 'requestedBy']));
});
out.push('');

// Notifications
out.push('-- notifications');
d.notifications.forEach(n => {
  const username = n.username || null;
  const userIdExpr = username ? `(select "id" from public."users" where "username" = ${esc(username)} limit 1)` : 'null';
  out.push(`insert into public."notifications" ("userId", "message", "time", "read", "type", "route") values (${userIdExpr}, ${esc(n.message)}, ${esc(n.time)}, ${n.read ? 'true' : 'false'}, ${esc(n.type || null)}, ${esc(n.route || null)}) on conflict do nothing;`);
});
out.push('');

// Audit logs
out.push('-- auditLogs');
d.auditLogs.forEach(a => {
  const userName = esc(a.user);
  const userIdExpr = `(select "id" from public."users" where "name" = ${userName} limit 1)`;
  out.push(`insert into public."auditLogs" ("time", "userId", "userName", "action", "icon", "color") values (${esc(a.time)}, ${userIdExpr}, ${userName}, ${esc(a.action)}, ${esc(a.icon)}, ${esc(a.color)}) on conflict do nothing;`);
});
out.push('');

// Die types
out.push('-- dieTypes');
(d.dieTypes || []).forEach(x => {
  out.push(rowSql('dieTypes', x, ['id', 'name']));
});
out.push('');

// Product models
out.push('-- productModels');
(d.productModels || []).forEach(x => {
  out.push(rowSql('productModels', x, ['id', 'name']));
});
out.push('');

out.push('-- Reset sequences after explicit inserts');
out.push('select setval(pg_get_serial_sequence(\'public."users"\', \'id\'), (select max("id") from public."users"));');
out.push('select setval(pg_get_serial_sequence(\'public."notifications"\', \'id\'), (select max("id") from public."notifications"));');
out.push('select setval(pg_get_serial_sequence(\'public."dieTypes"\', \'id\'), (select max("id") from public."dieTypes"));');
out.push('select setval(pg_get_serial_sequence(\'public."productModels"\', \'id\'), (select max("id") from public."productModels"));');
out.push('');

const outPath = path.join(__dirname, '..', 'supabase', 'seed.sql');
fs.writeFileSync(outPath, out.join('\n'));
console.log('Generated', outPath);
