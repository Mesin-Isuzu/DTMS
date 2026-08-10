import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

async function ensureAdmin(callerClient: ReturnType<typeof createClient>, cors: Record<string, string>) {
  const authHeader = (callerClient as unknown as { headers?: Record<string, string> }).headers?.Authorization
    || "";
  if (!authHeader) {
    return new Response(JSON.stringify({ error: "missing Authorization header" }), {
      status: 401, headers: { ...cors, "Content-Type": "application/json" },
    });
  }

  const { data: { user: caller }, error: callerError } = await callerClient.auth.getUser();
  if (callerError || !caller) {
    return new Response(JSON.stringify({ error: "invalid or expired token" }), {
      status: 401, headers: { ...cors, "Content-Type": "application/json" },
    });
  }
  const callerRole = (caller.user_metadata as Record<string, unknown>)?.role;
  if (callerRole !== "Admin Sistem") {
    return new Response(JSON.stringify({ error: "forbidden: admin role required" }), {
      status: 403, headers: { ...cors, "Content-Type": "application/json" },
    });
  }
  return null;
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { action, email, password } = await req.json();

    if (!action) {
      return new Response(JSON.stringify({ error: "action is required" }), {
        status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    if (!["delete", "update-password", "cleanup-orphaned"].includes(action)) {
      return new Response(JSON.stringify({ error: `unknown action: ${action}` }), {
        status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    if (action !== "cleanup-orphaned" && !email) {
      return new Response(JSON.stringify({ error: "email is required for this action" }), {
        status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    if (action === "update-password" && !password) {
      return new Response(JSON.stringify({ error: "password is required for update-password action" }), {
        status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
    const supabaseServiceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

    const authHeader = req.headers.get("Authorization") || "";
    const callerClient = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } },
    });

    const adminErr = await ensureAdmin(callerClient, corsHeaders);
    if (adminErr) return adminErr;

    const adminClient = createClient(supabaseUrl, supabaseServiceRoleKey);

    if (action === "cleanup-orphaned") {
      const { data: { users: authUsers }, error: listError } = await adminClient.auth.admin.listUsers();
      if (listError) {
        return new Response(JSON.stringify({ error: "failed to list auth users", detail: listError.message }), {
          status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      const { data: appUsers, error: appError } = await adminClient
        .from("users")
        .select("email");
      if (appError) {
        return new Response(JSON.stringify({ error: "failed to query public.users", detail: appError.message }), {
          status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      const appEmails = new Set((appUsers || []).map((u: { email: string }) => u.email));
      const orphaned = (authUsers || []).filter(
        (u) => u.email && !appEmails.has(u.email)
      );

      if (orphaned.length === 0) {
        return new Response(JSON.stringify({ cleaned: 0, message: "no orphaned auth users found" }), {
          status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      const deleted: string[] = [];
      const failed: { email: string; error: string }[] = [];
      for (const u of orphaned) {
        const { error: delErr } = await adminClient.auth.admin.deleteUser(u.id);
        if (delErr) {
          failed.push({ email: u.email!, error: delErr.message });
        } else {
          deleted.push(u.email!);
        }
      }

      return new Response(JSON.stringify({ cleaned: deleted.length, deleted, failed }), {
        status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const { data: { users }, error: listError } = await adminClient.auth.admin.listUsers();
    if (listError) {
      return new Response(JSON.stringify({ error: "failed to list users", detail: listError.message }), {
        status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const targetUser = users.find((u) => u.email === email);
    if (!targetUser) {
      return new Response(JSON.stringify({ error: "user not found in auth" }), {
        status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    if (action === "delete") {
      const { error: deleteError } = await adminClient.auth.admin.deleteUser(targetUser.id);
      if (deleteError) {
        return new Response(JSON.stringify({ error: "failed to delete auth user", detail: deleteError.message }), {
          status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }
      return new Response(JSON.stringify({ deleted: true, email }), {
        status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    if (action === "update-password") {
      const { error: updateError } = await adminClient.auth.admin.updateUserById(targetUser.id, {
        password,
      });
      if (updateError) {
        return new Response(JSON.stringify({ error: "failed to update password", detail: updateError.message }), {
          status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }
      return new Response(JSON.stringify({ updated: true, email }), {
        status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }
  } catch (err) {
    return new Response(JSON.stringify({ error: "internal server error", detail: String(err) }), {
      status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
