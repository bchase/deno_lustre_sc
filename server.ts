// $ gleam build && deno run --allow-net --allow-read ./server.ts

import * as GleamApp from './build/dev/javascript/delete_deno_lustre_sc/delete_deno_lustre_sc.mjs'

// TODO
const port = 8280;

global.sockets = {};

Deno.serve({port}, async (req: Request) => {
  const url = new URL(req.url);

  if (url.pathname === "/ws") {
    return connectLustreServerComponentToWebSocket(req, url);
  }

  if (url.pathname === "/lustre-server-component.min.mjs") {
    return renderFile('./build/dev/javascript/lustre/priv/static/lustre-server-component.min.mjs', 'application/javascript');

  }

  if (url.pathname === "/") {
    return renderFile('./priv/index.html', 'text/html');
  }

  return new Response("404 Not Found", { status: 404 });
});

async function renderFile(rel_path, content_type) {
  try {
    const file = await Deno.open(rel_path);

    return new Response(file.readable, {
      headers: {
        "content-type": content_type,
      },
    });
  } catch (error) {
    return new Response("File not found", { status: 404 });
  }
}

function connectLustreServerComponentToWebSocket(req, url) {
  const timezone = url.searchParams.get('timezone') || 'Etc/UTC';

  const { socket: ws, response } = Deno.upgradeWebSocket(req);

  const id = mkId();

  let deregister;

  ws.addEventListener("open", () => {
    const [socket, dereg_func] = GleamApp.init_socket(id, timezone, (msg) => ws.send(msg));
    deregister = dereg_func;
    sockets[id] = socket;
  });

  ws.addEventListener("message", (event) => {
    sockets[id] = GleamApp.handle_websocket_message(sockets[id], event.data);
  });

  ws.addEventListener("close", () => {
    deregister();
  });

  ws.addEventListener("error", (event) => {
    // TODO
    console.error("WebSocket error:", event);
  });

  return response;
}

function mkId() {
  return btoa(Date.now().toString() + performance.now().toString().replace('.', ''));
}
