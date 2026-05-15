#!/usr/bin/env python3
import html
import json
import subprocess
from datetime import datetime
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs


HOST = "0.0.0.0"
PORT = 8080

MQTT_HOST = "192.168.0.100"
MQTT_PORT = "1883"
MQTT_TOPIC = "test/topic"

COMMANDS = [
    ("hello board", "Hello"),
    ("led on", "LED ON"),
    ("led off", "LED OFF"),
    ("led toggle", "Toggle"),
    ("led blink", "Blink"),
    ("status", "Status"),
]

history = []


def publish_mqtt(message):
    cmd = [
        "mosquitto_pub",
        "-h",
        MQTT_HOST,
        "-p",
        MQTT_PORT,
        "-t",
        MQTT_TOPIC,
        "-m",
        message,
    ]

    result = subprocess.run(cmd, text=True, capture_output=True, timeout=5)
    if result.returncode != 0:
        err = result.stderr.strip() or result.stdout.strip() or "mosquitto_pub failed"
        raise RuntimeError(err)


def page(status="", error=""):
    rows = "\n".join(
        f"""
        <tr>
          <td>{html.escape(item["time"])}</td>
          <td><code>{html.escape(item["topic"])}</code></td>
          <td>{html.escape(item["message"])}</td>
          <td class="{html.escape(item["state"])}">{html.escape(item["state"])}</td>
        </tr>
        """
        for item in reversed(history[-20:])
    )

    buttons = "\n".join(
        f"""
        <button type="submit" name="message" value="{html.escape(value)}">
          {html.escape(label)}
        </button>
        """
        for value, label in COMMANDS
    )

    return f"""<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>IMX6ULL MQTT Control</title>
  <style>
    :root {{
      color-scheme: light;
      --bg: #f4f7fb;
      --panel: #ffffff;
      --text: #172033;
      --muted: #667085;
      --line: #d9e1ec;
      --accent: #0b6bcb;
      --accent-dark: #084f96;
      --danger: #b42318;
      --ok: #067647;
    }}

    * {{
      box-sizing: border-box;
    }}

    body {{
      margin: 0;
      min-height: 100vh;
      font-family: Arial, sans-serif;
      background: var(--bg);
      color: var(--text);
    }}

    main {{
      width: min(980px, calc(100% - 32px));
      margin: 0 auto;
      padding: 28px 0;
    }}

    header {{
      display: flex;
      justify-content: space-between;
      align-items: flex-end;
      gap: 16px;
      margin-bottom: 18px;
    }}

    h1 {{
      margin: 0;
      font-size: 28px;
      line-height: 1.2;
    }}

    .meta {{
      color: var(--muted);
      font-size: 14px;
      text-align: right;
      line-height: 1.5;
    }}

    section {{
      background: var(--panel);
      border: 1px solid var(--line);
      border-radius: 8px;
      padding: 18px;
      margin-bottom: 16px;
    }}

    h2 {{
      margin: 0 0 14px;
      font-size: 18px;
    }}

    .quick {{
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(130px, 1fr));
      gap: 10px;
      margin-bottom: 16px;
    }}

    button {{
      min-height: 42px;
      border: 0;
      border-radius: 6px;
      background: var(--accent);
      color: #fff;
      font-weight: 700;
      cursor: pointer;
    }}

    button:hover {{
      background: var(--accent-dark);
    }}

    .custom {{
      display: flex;
      gap: 10px;
    }}

    input {{
      flex: 1;
      min-width: 0;
      min-height: 42px;
      border: 1px solid var(--line);
      border-radius: 6px;
      padding: 0 12px;
      font-size: 15px;
    }}

    .notice {{
      margin-bottom: 16px;
      padding: 12px 14px;
      border-radius: 6px;
      background: #eaf4ff;
      color: #084f96;
    }}

    .error {{
      margin-bottom: 16px;
      padding: 12px 14px;
      border-radius: 6px;
      background: #fff1f0;
      color: var(--danger);
    }}

    table {{
      width: 100%;
      border-collapse: collapse;
      font-size: 14px;
    }}

    th,
    td {{
      padding: 10px 8px;
      border-bottom: 1px solid var(--line);
      text-align: left;
      vertical-align: top;
    }}

    th {{
      color: var(--muted);
      font-weight: 700;
    }}

    code {{
      background: #eef2f7;
      padding: 2px 5px;
      border-radius: 4px;
    }}

    .sent {{
      color: var(--ok);
      font-weight: 700;
    }}

    .failed {{
      color: var(--danger);
      font-weight: 700;
    }}

    @media (max-width: 640px) {{
      header,
      .custom {{
        display: block;
      }}

      .meta {{
        text-align: left;
        margin-top: 8px;
      }}

      .custom button {{
        width: 100%;
        margin-top: 10px;
      }}
    }}
  </style>
</head>
<body>
  <main>
    <header>
      <div>
        <h1>IMX6ULL MQTT Control</h1>
      </div>
      <div class="meta">
        Broker: <code>{html.escape(MQTT_HOST)}:{html.escape(MQTT_PORT)}</code><br>
        Topic: <code>{html.escape(MQTT_TOPIC)}</code>
      </div>
    </header>

    {f'<div class="notice">{html.escape(status)}</div>' if status else ''}
    {f'<div class="error">{html.escape(error)}</div>' if error else ''}

    <section>
      <h2>Quick Commands</h2>
      <form method="post">
        <div class="quick">
          {buttons}
        </div>
      </form>

      <form class="custom" method="post">
        <input name="message" placeholder="Type command payload" autocomplete="off" required>
        <button type="submit">Send</button>
      </form>
    </section>

    <section>
      <h2>Send History</h2>
      <table>
        <thead>
          <tr>
            <th>Time</th>
            <th>Topic</th>
            <th>Message</th>
            <th>State</th>
          </tr>
        </thead>
        <tbody>
          {rows or '<tr><td colspan="4">No commands sent yet.</td></tr>'}
        </tbody>
      </table>
    </section>
  </main>
</body>
</html>"""


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        self._send_html(page())

    def do_POST(self):
        length = int(self.headers.get("Content-Length", "0"))
        body = self.rfile.read(length).decode("utf-8", errors="replace")
        data = parse_qs(body)
        message = data.get("message", [""])[0].strip()

        if not message:
            self._send_html(page(error="Message is empty"), status=400)
            return

        item = {
            "time": datetime.now().strftime("%H:%M:%S"),
            "topic": MQTT_TOPIC,
            "message": message,
            "state": "sent",
        }

        try:
            publish_mqtt(message)
            history.append(item)
            self._send_html(page(status=f"Sent: {message}"))
        except Exception as exc:
            item["state"] = "failed"
            history.append(item)
            self._send_html(page(error=str(exc)), status=500)

    def do_GET_api_history(self):
        self._send_json(history[-20:])

    def log_message(self, fmt, *args):
        print("%s - %s" % (self.address_string(), fmt % args))

    def _send_html(self, content, status=200):
        data = content.encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def _send_json(self, payload, status=200):
        data = json.dumps(payload).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)


def main():
    server = ThreadingHTTPServer((HOST, PORT), Handler)
    print(f"Web MQTT control: http://127.0.0.1:{PORT}")
    print(f"Publish to mqtt://{MQTT_HOST}:{MQTT_PORT}, topic {MQTT_TOPIC}")
    server.serve_forever()


if __name__ == "__main__":
    main()
