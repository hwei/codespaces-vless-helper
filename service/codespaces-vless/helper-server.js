#!/usr/bin/env node
'use strict';

const http = require('http');
const os = require('os');
const fs = require('fs');

const env = process.env;
const port = Number(env.CODESPACES_VLESS_HELPER_PORT || 18080);
const vlessPort = Number(env.CODESPACES_VLESS_PORT || 10086);
const nodeName = env.CODESPACES_VLESS_NODE_NAME || 'codespace-vless';
const wsPath = env.CODESPACES_VLESS_WS_PATH || '/vless';
const uuidFile = env.CODESPACES_VLESS_UUID_FILE || `${process.cwd()}/.local/codespaces-vless/state/vless.uuid`;

function text(value) {
  return String(value ?? '').replace(/[&<>"']/g, (ch) => ({
    '&': '&amp;',
    '<': '&lt;',
    '>': '&gt;',
    '"': '&quot;',
    "'": '&#39;',
  }[ch]));
}

function readUuid() {
  try {
    return fs.readFileSync(uuidFile, 'utf8').trim();
  } catch {
    return 'UUID_NOT_GENERATED_RUN_SETUP';
  }
}

function internalIPv4() {
  const interfaces = os.networkInterfaces();
  const candidates = [];

  for (const [name, addrs] of Object.entries(interfaces)) {
    for (const addr of addrs || []) {
      if (addr.family === 'IPv4' && !addr.internal) {
        candidates.push({ name, address: addr.address });
      }
    }
  }

  const preferred = candidates.find((item) => /^eth|^en/.test(item.name));
  return (preferred || candidates[0] || { address: 'unavailable' }).address;
}

function stripProtocol(host) {
  return String(host || '').replace(/^https?:\/\//, '').replace(/\/.*$/, '');
}

function observedHost(req) {
  return stripProtocol(req.headers['x-forwarded-host'] || req.headers.host || '');
}

function deriveForwardedHost(req) {
  const observed = observedHost(req);
  const domain = env.GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN || 'app.github.dev';

  if (observed.includes(`-${port}.`)) {
    return observed.replace(`-${port}.`, `-${vlessPort}.`);
  }

  if (observed.includes(`-${port}-${domain}`)) {
    return observed.replace(`-${port}-${domain}`, `-${vlessPort}-${domain}`);
  }

  if (env.CODESPACE_NAME) {
    return `${env.CODESPACE_NAME}-${vlessPort}.${domain}`;
  }

  return '';
}

function yamlQuote(value) {
  return JSON.stringify(String(value));
}

function buildOutputs(req) {
  const uuid = readUuid();
  const ip = internalIPv4();
  const helperHost = observedHost(req);
  const host = deriveForwardedHost(req);
  const externalPort = 443;
  const encodedPath = encodeURIComponent(wsPath);
  const encodedName = encodeURIComponent(nodeName);
  const vlessUrl = host
    ? `vless://${uuid}@${host}:${externalPort}?encryption=none&security=tls&type=ws&host=${encodeURIComponent(host)}&sni=${encodeURIComponent(host)}&path=${encodedPath}#${encodedName}`
    : 'Forward/open the VLESS service port first, then replace HOST with that forwarded host.';

  const clashYaml = host ? `- name: ${yamlQuote(nodeName)}
  type: vless
  server: ${host}
  port: ${externalPort}
  uuid: ${uuid}
  network: ws
  tls: true
  udp: true
  servername: ${host}
  ws-opts:
    path: ${yamlQuote(wsPath)}
    headers:
      Host: ${host}` : 'Forward/open the VLESS service port first, then reload this page.';

  const xrayClient = host ? JSON.stringify({
    protocol: 'vless',
    tag: nodeName,
    settings: {
      vnext: [{
        address: host,
        port: externalPort,
        users: [{ id: uuid, encryption: 'none' }],
      }],
    },
    streamSettings: {
      network: 'ws',
      security: 'tls',
      tlsSettings: { serverName: host },
      wsSettings: { path: wsPath, headers: { Host: host } },
    },
  }, null, 2) : 'Forward/open the VLESS service port first, then reload this page.';

  return { uuid, ip, helperHost, host, vlessUrl, clashYaml, xrayClient };
}

function render(req) {
  const data = buildOutputs(req);
  const routingRule = data.ip === 'unavailable'
    ? `IP-CIDR,<internal-ip>/32,${nodeName}`
    : `IP-CIDR,${data.ip}/32,${nodeName}`;
  const endpoint = data.host ? `${data.host}:443` : 'unknown until the forwarded VLESS host is available';

  return `<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>${text(nodeName)} connection helper</title>
  <style>
    :root { color-scheme: light dark; --bg: #f7f7f4; --fg: #171717; --muted: #5c635c; --line: #d8d8d0; --accent: #0f766e; --panel: #ffffff; --code: #101418; }
    @media (prefers-color-scheme: dark) { :root { --bg: #161814; --fg: #eeeeea; --muted: #aeb5aa; --line: #34382f; --panel: #20231d; --code: #0b0e10; } }
    * { box-sizing: border-box; }
    body { margin: 0; font-family: ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; background: var(--bg); color: var(--fg); line-height: 1.45; }
    main { max-width: 1120px; margin: 0 auto; padding: 32px 20px 56px; }
    header { border-bottom: 1px solid var(--line); padding-bottom: 20px; margin-bottom: 24px; }
    h1 { margin: 0 0 8px; font-size: 32px; letter-spacing: 0; }
    h2 { margin: 0 0 12px; font-size: 18px; letter-spacing: 0; }
    p { margin: 0 0 12px; color: var(--muted); }
    .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(260px, 1fr)); gap: 12px; margin-bottom: 20px; }
    .fact, section { background: var(--panel); border: 1px solid var(--line); border-radius: 8px; padding: 16px; }
    .label { color: var(--muted); font-size: 13px; margin-bottom: 4px; }
    .value { font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace; overflow-wrap: anywhere; }
    section { margin: 16px 0; }
    pre { margin: 0; padding: 14px; overflow-x: auto; white-space: pre-wrap; overflow-wrap: anywhere; background: var(--code); color: #e8f3ef; border-radius: 6px; font-size: 13px; }
    button { border: 1px solid var(--line); border-radius: 6px; padding: 8px 10px; background: transparent; color: var(--fg); cursor: pointer; }
    .section-head { display: flex; justify-content: space-between; gap: 12px; align-items: center; margin-bottom: 10px; }
    .warn { border-color: #b45309; }
    .warn strong { color: #b45309; }
  </style>
</head>
<body>
  <main>
    <header>
      <h1>${text(nodeName)}</h1>
      <p>VLESS over WebSocket for this Codespace. External clients use TLS to GitHub's HTTPS forwarding endpoint; Xray receives plain HTTP WebSocket internally.</p>
    </header>

    <div class="grid">
      <div class="fact"><div class="label">Internal IPv4</div><div class="value">${text(data.ip)}</div></div>
      <div class="fact"><div class="label">Observed helper host</div><div class="value">${text(data.helperHost || 'local request')}</div></div>
      <div class="fact"><div class="label">VLESS endpoint</div><div class="value">${text(endpoint)}</div></div>
      <div class="fact"><div class="label">WebSocket path</div><div class="value">${text(wsPath)}</div></div>
      <div class="fact"><div class="label">UUID</div><div class="value">${text(data.uuid)}</div></div>
      <div class="fact"><div class="label">TLS expectation</div><div class="value">client TLS on :443, Xray inbound security: none</div></div>
    </div>

    ${data.host ? '' : `<section class="warn"><h2>Forwarded VLESS Host</h2><p>Open or forward port ${vlessPort}, set it to Public, then reload this helper from the forwarded helper URL. If needed, replace HOST in the snippets with the forwarded host for port ${vlessPort}.</p></section>`}

    <section>
      <div class="section-head"><h2>VLESS URL</h2><button data-copy="vless-url">Copy</button></div>
      <pre id="vless-url">${text(data.vlessUrl)}</pre>
    </section>

    <section>
      <div class="section-head"><h2>Clash Verge / Mihomo Node</h2><button data-copy="clash-yaml">Copy</button></div>
      <pre id="clash-yaml">${text(data.clashYaml)}</pre>
    </section>

    <section>
      <div class="section-head"><h2>Xray Client Outbound</h2><button data-copy="xray-json">Copy</button></div>
      <pre id="xray-json">${text(data.xrayClient)}</pre>
    </section>

    <section>
      <div class="section-head"><h2>Routing Rule</h2><button data-copy="routing-rule">Copy</button></div>
      <pre id="routing-rule">${text(routingRule)}</pre>
    </section>

    <section class="warn">
      <h2>Security Notes</h2>
      <p><strong>Treat this page and every UUID-bearing snippet as sensitive.</strong> Public forwarded URLs can be reached by anyone with the URL, and the UUID is the client credential. Do not share these snippets publicly or commit generated runtime files.</p>
      <p>UUID rotation is intentionally manual because it invalidates existing clients. Delete the UUID file and rerun setup only when you are ready to update every client configuration.</p>
    </section>
  </main>
  <script>
    for (const button of document.querySelectorAll('button[data-copy]')) {
      button.addEventListener('click', async () => {
        const node = document.getElementById(button.dataset.copy);
        await navigator.clipboard.writeText(node.textContent);
        button.textContent = 'Copied';
        setTimeout(() => { button.textContent = 'Copy'; }, 1200);
      });
    }
  </script>
</body>
</html>`;
}

const server = http.createServer((req, res) => {
  if (req.url === '/healthz') {
    res.writeHead(200, { 'content-type': 'text/plain; charset=utf-8' });
    res.end('ok\n');
    return;
  }

  res.writeHead(200, {
    'content-type': 'text/html; charset=utf-8',
    'cache-control': 'no-store',
  });
  res.end(render(req));
});

server.listen(port, '0.0.0.0', () => {
  console.log(`codespaces-vless helper listening on ${port}`);
});
