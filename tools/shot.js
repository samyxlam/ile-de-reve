// Capture d'un écran d'un build Godot web via le protocole DevTools.
// Usage: node shot.js <url> <sortie.png> <attente_ms> <largeur> <hauteur> ["x1,y1;x2,y2"]
const http = require('http');
const fs = require('fs');

function getJSON(path) {
  return new Promise((res, rej) => {
    http.get({ host: '127.0.0.1', port: 9222, path }, (r) => {
      let d = '';
      r.on('data', (c) => (d += c));
      r.on('end', () => res(JSON.parse(d)));
    }).on('error', rej);
  });
}

(async () => {
  const url = process.argv[2];
  const out = process.argv[3];
  const wait = parseInt(process.argv[4] || '20000', 10);
  const w = parseInt(process.argv[5] || '460', 10);
  const h = parseInt(process.argv[6] || '900', 10);
  const clicks = (process.argv[7] || '').split(';').filter(Boolean);

  const list = await getJSON('/json/list');
  const page = list.find((t) => t.type === 'page');
  const ws = new WebSocket(page.webSocketDebuggerUrl);
  let id = 0;
  const pending = new Map();
  const logs = [];
  const send = (method, params = {}) =>
    new Promise((res) => {
      const i = ++id;
      pending.set(i, res);
      ws.send(JSON.stringify({ id: i, method, params }));
    });

  await new Promise((r) => (ws.onopen = r));
  ws.onmessage = (ev) => {
    const m = JSON.parse(ev.data);
    if (m.id && pending.has(m.id)) {
      pending.get(m.id)(m.result);
      pending.delete(m.id);
    } else if (m.method === 'Runtime.consoleAPICalled') {
      logs.push(m.params.args.map((a) => a.value ?? a.description).join(' '));
    } else if (m.method === 'Runtime.exceptionThrown') {
      logs.push('EXC ' + JSON.stringify(m.params.exceptionDetails.text));
    }
  };

  await send('Page.enable');
  await send('Runtime.enable');
  await send('Emulation.setDeviceMetricsOverride', { width: w, height: h, deviceScaleFactor: 1, mobile: false });
  await send('Page.navigate', { url });
  await new Promise((r) => setTimeout(r, wait));

  for (const c of clicks) {
    const [x, y] = c.split(',').map(Number);
    await send('Input.dispatchMouseEvent', { type: 'mouseMoved', x, y, button: 'none' });
    await send('Input.dispatchMouseEvent', { type: 'mousePressed', x, y, button: 'left', clickCount: 1 });
    await new Promise((r) => setTimeout(r, 80));
    await send('Input.dispatchMouseEvent', { type: 'mouseReleased', x, y, button: 'left', clickCount: 1 });
    await new Promise((r) => setTimeout(r, 900));
  }

  const shot = await send('Page.captureScreenshot', { format: 'png' });
  fs.writeFileSync(out, Buffer.from(shot.data, 'base64'));
  if (logs.length) console.log('CONSOLE:\n' + logs.slice(-40).join('\n'));
  console.log('OK ' + out);
  ws.close();
  process.exit(0);
})().catch((e) => {
  console.error('FAIL', e.message);
  process.exit(1);
});
