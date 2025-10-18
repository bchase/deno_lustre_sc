// $ gleam build && deno run --allow-net --allow-read ./server.ts

import * as GleamApp from './build/dev/javascript/delete_deno_lustre_sc/delete_deno_lustre_sc.mjs'

// TODO
const port = 8280;

let socket;

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

  return new Response("404 Not Found");
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

  ws.addEventListener("open", () => {
    // TODO
    const id = "TODO";

    socket = GleamApp.init_socket(id, timezone, (msg) => ws.send(msg));
  });

  ws.addEventListener("message", (event) => {
    socket = GleamApp.handle_websocket_message(socket, event.data);
  });

  ws.addEventListener("close", () => {
    // TODO
    console.log("A client disconnected!");
  });

  ws.addEventListener("error", (event) => {
    // TODO
    console.error("WebSocket error:", event);
  });

  return response;
}
