// Saika realtime relay — Deno Deploy version of server/bin/server.dart.
// Paste this whole file into a Deno Deploy Playground and deploy — no
// GitHub connection, Docker, or card needed for the free tier.

const clients = new Map<WebSocket, string>();
const activeRequests: Record<string, unknown>[] = [];
const activeSos: Record<string, unknown>[] = [];
const registrations: Record<string, unknown>[] = [];
// Offers (ride_countered) made on each request, kept alongside it so a rider
// whose socket drops and reconnects mid-flow — a brief mobile network blip
// is enough — doesn't permanently lose an offer a driver sent while they
// were disconnected. state_snapshot replays these on every (re)connect.
const offersByRequest = new Map<string, Record<string, unknown>[]>();

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, GET, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type",
};

function broadcast(type: string, payload: unknown) {
  const msg = JSON.stringify({ type, payload });
  for (const ws of clients.keys()) {
    if (ws.readyState === WebSocket.OPEN) ws.send(msg);
  }
}

function broadcastPresence() {
  const counts: Record<string, number> = {};
  for (const role of clients.values()) {
    counts[role] = (counts[role] ?? 0) + 1;
  }
  broadcast("presence", { onlineCount: clients.size, byRole: counts });
}

Deno.serve(async (req) => {
  const url = new URL(req.url);

  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  if (url.pathname === "/register" && req.method === "POST") {
    try {
      const body = await req.json();
      const entry = {
        name: String(body.name ?? "").trim(),
        phone: String(body.phone ?? "").trim(),
        role: body.role === "driver" ? "driver" : "rider",
        registeredAt: new Date().toISOString(),
      };
      if (!entry.name || !entry.phone) {
        return new Response(JSON.stringify({ error: "name and phone required" }), {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }
      registrations.push(entry);
      broadcast("user_registered", entry);
      return new Response(JSON.stringify({ ok: true }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    } catch (_e) {
      return new Response(JSON.stringify({ error: "invalid body" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }
  }

  if (url.pathname === "/registrations" && req.method === "GET") {
    return new Response(JSON.stringify(registrations), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  if (req.headers.get("upgrade") !== "websocket") {
    return new Response(
      "Saika realtime relay is running. Connect via WebSocket at /ws.",
      { headers: corsHeaders },
    );
  }

  const { socket, response } = Deno.upgradeWebSocket(req);

  socket.onopen = () => {
    clients.set(socket, "unknown");
    socket.send(JSON.stringify({
      type: "state_snapshot",
      payload: {
        activeRequests,
        activeSos,
        offers: Object.fromEntries(offersByRequest),
        onlineCount: clients.size,
      },
    }));
    broadcastPresence();
  };

  socket.onmessage = (event) => {
    try {
      const msg = JSON.parse(event.data as string);
      const type: string = msg.type ?? "";
      const payload: Record<string, unknown> = msg.payload ?? {};

      switch (type) {
        case "hello":
          clients.set(socket, (payload.role as string) ?? "unknown");
          broadcastPresence();
          return;
        case "ride_request":
          activeRequests.push(payload);
          break;
        case "ride_countered": {
          const requestId = payload.requestId as string | undefined;
          if (requestId) {
            const list = offersByRequest.get(requestId) ?? [];
            const driverId = payload.driverId;
            const i = list.findIndex((o) => o.driverId === driverId);
            if (i === -1) list.push(payload);
            else list[i] = payload;
            offersByRequest.set(requestId, list);
          }
          break;
        }
        case "ride_accepted": {
          const i = activeRequests.findIndex(
            (r) => r.id === payload.requestId,
          );
          if (i !== -1) activeRequests.splice(i, 1);
          offersByRequest.delete(payload.requestId as string);
          break;
        }
        case "ride_cancelled": {
          const i = activeRequests.findIndex(
            (r) => r.id === payload.requestId,
          );
          if (i !== -1) activeRequests.splice(i, 1);
          offersByRequest.delete(payload.requestId as string);
          break;
        }
        case "sos_triggered":
          activeSos.push(payload);
          break;
        case "sos_resolved": {
          const i = activeSos.findIndex((s) => s.id === payload.id);
          if (i !== -1) activeSos.splice(i, 1);
          break;
        }
      }

      broadcast(type, payload);
    } catch (_e) {
      // Ignore malformed frames rather than crashing the relay.
    }
  };

  socket.onclose = () => {
    clients.delete(socket);
    broadcastPresence();
  };

  return response;
});
