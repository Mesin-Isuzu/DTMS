// ============================================================
// DTMS Database Layer — Supabase integration
// ============================================================

const DTMS = (function () {
  const isPlaceholder =
    !window.DTMS_SUPABASE_URL ||
    window.DTMS_SUPABASE_URL.includes('your-project') ||
    !window.DTMS_SUPABASE_ANON_KEY ||
    window.DTMS_SUPABASE_ANON_KEY.includes('your-anon-key');

  let client = null;
  if (!isPlaceholder && window.supabase && window.supabase.createClient) {
    client = window.supabase.createClient(
      window.DTMS_SUPABASE_URL,
      window.DTMS_SUPABASE_ANON_KEY,
      {
        auth: {
          autoRefreshToken: true,
          persistSession: true,
          detectSessionInUrl: true
        }
      }
    );
  }

  function enabled() {
    return !!client;
  }

  function handleError(err) {
    console.error('Supabase error:', err);
    if (err && err.message) {
      // Don't alert on every error; callers can decide
    }
    return null;
  }

  // Convert a File/Blob to ArrayBuffer for Supabase Storage upload
  function readFile(file) {
    return new Promise((resolve, reject) => {
      const reader = new FileReader();
      reader.onload = () => resolve(reader.result);
      reader.onerror = reject;
      reader.readAsArrayBuffer(file);
    });
  }

  // ----------------------------
  // Auth
  // ----------------------------
  async function getSession() {
    if (!client) return { data: { session: null }, error: null };
    return client.auth.getSession();
  }

  async function getCurrentUser() {
    if (!client) return null;
    const { data: { user } } = await client.auth.getUser();
    return user || null;
  }

  async function login(email, password) {
    if (!client) return { user: null, error: new Error('Supabase not configured') };
    const { data, error } = await client.auth.signInWithPassword({ email, password });
    if (error) return { user: null, error };
    return { user: data.user, error: null };
  }

  async function logout() {
    if (!client) return { error: null };
    return client.auth.signOut();
  }

  async function signUp(email, password, metadata) {
    if (!client) return { user: null, error: new Error('Supabase not configured') };
    const { data, error } = await client.auth.signUp({
      email,
      password,
      options: { data: metadata }
    });
    return { user: data.user, error };
  }

  async function updateUserMetadata(metadata) {
    if (!client) return { error: new Error('Supabase not configured') };
    return client.auth.updateUser({ data: metadata });
  }

  // ----------------------------
  // Load all collections
  // ----------------------------
  async function loadAll() {
    if (!client) return null;
    try {
      const [
        { data: users, error: e1 },
        { data: toolings, error: e2 },
        { data: maintenanceLogs, error: e3 },
        { data: supplierTasks, error: e4 },
        { data: shootLogs, error: e5 },
        { data: productionLogs, error: e6 },
        { data: deliveryLogs, error: e7 },
        { data: movementLogs, error: e8 },
        { data: notifications, error: e9 },
        { data: auditLogs, error: e10 },
        { data: kpiRow, error: e11 }
      ] = await Promise.all([
        client.from('users').select('*'),
        client.from('toolings').select('*'),
        client.from('maintenanceLogs').select('*'),
        client.from('supplierTasks').select('*'),
        client.from('shootLogs').select('*'),
        client.from('productionLogs').select('*'),
        client.from('deliveryLogs').select('*'),
        client.from('movementLogs').select('*'),
        client.from('notifications').select('*'),
        client.from('auditLogs').select('*'),
        client.from('kpis').select('*').single()
      ]);

      const errors = [e1, e2, e3, e4, e5, e6, e7, e8, e9, e10, e11].filter(Boolean);
      if (errors.length) {
        console.warn('Partial load errors:', errors);
      }

      return {
        users: users || [],
        toolings: toolings || [],
        maintenanceLogs: maintenanceLogs || [],
        supplierTasks: supplierTasks || [],
        shootLogs: shootLogs || [],
        productionLogs: productionLogs || [],
        deliveryLogs: deliveryLogs || [],
        movementLogs: movementLogs || [],
        notifications: notifications || [],
        auditLogs: auditLogs || [],
        kpis: kpiRow || {
          totalActive: 0,
          openRepairs: 0,
          pendingApprovals: 0,
          overdueTasks: 0
        }
      };
    } catch (err) {
      return handleError(err);
    }
  }

  async function getKpis() {
    if (!client) return null;
    const { data, error } = await client.from('kpis').select('*').single();
    if (error) return handleError(error);
    return data;
  }

  // ----------------------------
  // Generic CRUD helpers
  // ----------------------------
  async function list(table) {
    if (!client) return [];
    const { data, error } = await client.from(table).select('*').order('createdAt', { ascending: false });
    if (error) return handleError(error) || [];
    return data || [];
  }

  async function get(table, id) {
    if (!client) return null;
    const { data, error } = await client.from(table).select('*').eq('id', id).single();
    if (error) return handleError(error);
    return data;
  }

  async function insert(table, obj) {
    if (!client) return null;
    const { data, error } = await client.from(table).insert([obj]).select().single();
    if (error) { handleError(error); throw error; }
    return data;
  }

  async function update(table, id, obj) {
    if (!client) return null;
    const { data, error } = await client.from(table).update(obj).eq('id', id).select().single();
    if (error) { handleError(error); throw error; }
    return data;
  }

  async function remove(table, id) {
    if (!client) return false;
    const { error } = await client.from(table).delete().eq('id', id);
    if (error) { handleError(error); throw error; }
    return true;
  }

  // ----------------------------
  // Convenience methods used by app.js
  // ----------------------------
  async function insertTooling(obj) { return insert('toolings', obj); }
  async function updateTooling(id, obj) { return update('toolings', id, obj); }
  async function deleteTooling(id) { return remove('toolings', id); }

  async function insertMaintenanceLog(obj) { return insert('maintenanceLogs', obj); }
  async function updateMaintenanceLog(id, obj) { return update('maintenanceLogs', id, obj); }
  async function deleteMaintenanceLog(id) { return remove('maintenanceLogs', id); }

  async function insertSupplierTask(obj) { return insert('supplierTasks', obj); }
  async function updateSupplierTask(id, obj) { return update('supplierTasks', id, obj); }
  async function deleteSupplierTask(id) { return remove('supplierTasks', id); }

  async function insertShootLog(obj) { return insert('shootLogs', obj); }
  async function updateShootLog(id, obj) { return update('shootLogs', id, obj); }
  async function deleteShootLog(id) { return remove('shootLogs', id); }

  async function insertProductionLog(obj) { return insert('productionLogs', obj); }
  async function updateProductionLog(id, obj) { return update('productionLogs', id, obj); }
  async function deleteProductionLog(id) { return remove('productionLogs', id); }

  async function insertDeliveryLog(obj) { return insert('deliveryLogs', obj); }
  async function updateDeliveryLog(id, obj) { return update('deliveryLogs', id, obj); }
  async function deleteDeliveryLog(id) { return remove('deliveryLogs', id); }

  async function insertMovementLog(obj) { return insert('movementLogs', obj); }
  async function updateMovementLog(id, obj) { return update('movementLogs', id, obj); }
  async function deleteMovementLog(id) { return remove('movementLogs', id); }

  async function insertNotification(obj) { return insert('notifications', obj); }
  async function updateNotification(id, obj) { return update('notifications', id, obj); }
  async function deleteNotification(id) { return remove('notifications', id); }

  async function insertAuditLog(obj) { return insert('auditLogs', obj); }

  async function insertUser(obj) { return insert('users', obj); }
  async function updateUser(id, obj) { return update('users', id, obj); }
  async function deleteUser(id) { return remove('users', id); }

  // ----------------------------
  // Auth Admin (via Edge Function)
  // ----------------------------
  function generatePassword() {
    const chars = 'abcdefghijkmnpqrstuvwxyz23456789';
    let pw = '';
    for (let i = 0; i < 8; i++) pw += chars[Math.floor(Math.random() * chars.length)];
    return pw;
  }

  async function _callAdminFunction(action, email, extra = {}) {
    if (!client) return { error: new Error('Supabase not configured') };
    const { data: { session } } = await client.auth.getSession();
    if (!session || !session.access_token) {
      return { error: new Error('No active session — please log in again') };
    }
    try {
      const res = await fetch(`${window.DTMS_SUPABASE_URL}/functions/v1/admin-user`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${session.access_token}`,
          'Content-Type': 'application/json',
          'apikey': window.DTMS_SUPABASE_ANON_KEY
        },
        body: JSON.stringify({ action, email, ...extra })
      });
      const data = await res.json();
      if (!res.ok) {
        return { error: new Error(data.error || data.detail || `HTTP ${res.status}`) };
      }
      return { error: null, data };
    } catch (e) {
      console.error(`_callAdminFunction ${action} error:`, e);
      return { error: e };
    }
  }

  async function deleteAuthUser(email) {
    return _callAdminFunction('delete', email);
  }

  async function updateAuthPassword(email, newPassword) {
    return _callAdminFunction('update-password', email, { password: newPassword });
  }

  // ----------------------------
  // Storage
  // ----------------------------
  async function uploadFile(bucket, file, path) {
    if (!client) return { path: null, publicUrl: null, error: new Error('Supabase not configured') };
    try {
      const arrayBuffer = await readFile(file);
      const { data, error } = await client.storage
        .from(bucket)
        .upload(path, arrayBuffer, {
          contentType: file.type || 'application/octet-stream',
          upsert: true
        });
      if (error) throw error;
      const { data: urlData } = client.storage.from(bucket).getPublicUrl(data.path);
      return { path: data.path, publicUrl: urlData.publicUrl, error: null };
    } catch (error) {
      console.error('Upload error:', error);
      return { path: null, publicUrl: null, error };
    }
  }

  async function removeFile(bucket, path) {
    if (!client) return { error: null };
    return client.storage.from(bucket).remove([path]);
  }

  function getPublicUrl(bucket, path) {
    if (!client) return null;
    const { data } = client.storage.from(bucket).getPublicUrl(path);
    return data.publicUrl;
  }

  // ----------------------------
  // Build a storage path
  // ----------------------------
  function makePath(table, recordId, fileName) {
    const safeName = fileName.replace(/[^a-zA-Z0-9._-]/g, '_');
    return `${table}/${recordId}/${Date.now()}_${safeName}`;
  }

  return {
    enabled,
    isPlaceholder,
    client,
    getSession,
    getCurrentUser,
    login,
    logout,
    signUp,
    updateUserMetadata,
    loadAll,
    getKpis,
    list,
    get,
    insert,
    update,
    remove,
    insertTooling,
    updateTooling,
    deleteTooling,
    insertMaintenanceLog,
    updateMaintenanceLog,
    deleteMaintenanceLog,
    insertSupplierTask,
    updateSupplierTask,
    deleteSupplierTask,
    insertShootLog,
    updateShootLog,
    deleteShootLog,
    insertProductionLog,
    updateProductionLog,
    deleteProductionLog,
    insertDeliveryLog,
    updateDeliveryLog,
    deleteDeliveryLog,
    insertMovementLog,
    updateMovementLog,
    deleteMovementLog,
    insertNotification,
    updateNotification,
    deleteNotification,
    insertAuditLog,
    insertUser,
    updateUser,
    deleteUser,
    generatePassword,
    deleteAuthUser,
    updateAuthPassword,
    uploadFile,
    removeFile,
    getPublicUrl,
    makePath
  };
})();

window.DTMS = DTMS;
