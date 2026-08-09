-- Reset all DTMS tables (use before re-running seed.sql)
TRUNCATE TABLE
  public."auditLogs",
  public."notifications",
  public."productionLogs",
  public."shootLogs",
  public."deliveryLogs",
  public."movementLogs",
  public."supplierTasks",
  public."maintenanceLogs",
  public."toolings",
  public."users"
CASCADE;
