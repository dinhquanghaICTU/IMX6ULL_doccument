#!/usr/bin/env python3
import cgi
import html
import json
import os
import socket
import subprocess
import threading
from datetime import datetime
from http.server import BaseHTTPRequestHandler, SimpleHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs

HOST       = "0.0.0.0"
PORT       = 8080
FILE_PORT  = 8888
OTA_DIR    = "/tmp/ota_files"

MQTT_HOST  = "192.168.1.244"
MQTT_PORT  = "1883"
MQTT_TOPIC = "test/topic"

os.makedirs(OTA_DIR, exist_ok=True)
history = []

COMMANDS = [
    ("led on", "LED ON"),
    ("led off", "LED OFF"),
    ("led toggle", "Toggle"),
    ("led blink", "Blink"),
    ("status", "Status"),
]

OTA_TYPES = [
    ("app", "📦", "App"),
    ("kernel", "🐧", "Kernel"),
    ("rootfs", "💾", "RootFS"),
    ("config", "⚙️", "Config"),
]


def get_host_ip():
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except Exception:
        return MQTT_HOST


HOST_IP = get_host_ip()


class OTAFileHandler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=OTA_DIR, **kwargs)

    def log_message(self, fmt, *args):
        pass


threading.Thread(
    target=lambda: ThreadingHTTPServer(("0.0.0.0", FILE_PORT), OTAFileHandler).serve_forever(),
    daemon=True,
).start()


def publish_mqtt(message):
    cmd = [
        "mosquitto_pub",
        "-h", MQTT_HOST,
        "-p", MQTT_PORT,
        "-t", MQTT_TOPIC,
        "-m", message,
    ]
    result = subprocess.run(cmd, text=True, capture_output=True, timeout=10)
    if result.returncode != 0:
        raise RuntimeError(result.stderr.strip() or result.stdout.strip() or "mosquitto_pub failed")


def add_history(message, state):
    history.append({
        "time": datetime.now().strftime("%H:%M:%S"),
        "topic": MQTT_TOPIC,
        "message": message,
        "state": state,
    })


def page(status="", error=""):
    buttons = "\n".join(
        f'<button type="submit" name="message" value="{html.escape(v)}">{html.escape(label)}</button>'
        for v, label in COMMANDS
    )

    type_cards = "\n".join(
        f'<label class="type-card"><input type="radio" name="ota_type" value="{v}" {"checked" if v == "kernel" else ""}><span class="type-icon">{icon}</span><span class="type-name">{html.escape(label)}</span></label>'
        for v, icon, label in OTA_TYPES
    )

    rows = "\n".join(
        f'<tr><td>{html.escape(item["time"])}</td><td><code>{html.escape(item["topic"])}</code></td><td>{html.escape(item["message"])}</td><td class="state-{html.escape(item["state"])}">{html.escape(item["state"])}</td></tr>'
        for item in reversed(history[-30:])
    )

    uploaded_files = sorted(os.listdir(OTA_DIR)) if os.path.isdir(OTA_DIR) else []
    chips = "".join(f'<span class="file-chip">{html.escape(name)}</span>' for name in uploaded_files)
    file_list = f'''
    <div class="file-list">
      <div class="file-list-title">Files server: <code>http://{html.escape(HOST_IP)}:{FILE_PORT}/</code></div>
      {chips or '<span class="muted">No uploaded files yet</span>'}
    </div>
    '''

    return f'''<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>IMX6ULL OTA Control</title>
<style>
:root{{--bg:#f4f7fb;--panel:#fff;--text:#172033;--muted:#667085;--line:#d9e1ec;--accent:#0b6bcb;--accent-dark:#084f96;--danger:#b42318;--ok:#067647;--purple:#7c3aed;}}
*{{box-sizing:border-box}}
body{{margin:0;font-family:Arial,sans-serif;background:var(--bg);color:var(--text)}}
main{{width:min(980px,calc(100% - 32px));margin:0 auto;padding:28px 0}}
header{{display:flex;justify-content:space-between;align-items:flex-end;gap:16px;margin-bottom:18px}}
h1{{margin:0;font-size:28px}}
.meta{{color:var(--muted);font-size:14px;text-align:right;line-height:1.6}}
section{{background:var(--panel);border:1px solid var(--line);border-radius:10px;padding:18px;margin-bottom:16px}}
h2{{margin:0 0 14px;font-size:18px}}
button{{min-height:42px;border:0;border-radius:6px;background:var(--accent);color:#fff;font-weight:700;cursor:pointer;font-size:14px}}
button:hover{{background:var(--accent-dark)}}
.quick{{display:grid;grid-template-columns:repeat(auto-fit,minmax(130px,1fr));gap:10px;margin-bottom:14px}}
.custom{{display:flex;gap:10px}}
input[type=text]{{flex:1;min-height:42px;border:1px solid var(--line);border-radius:6px;padding:0 12px;font-size:15px;width:100%}}
.notice{{margin-bottom:16px;padding:12px 14px;border-radius:6px;background:#eaf4ff;color:#084f96}}
.error{{margin-bottom:16px;padding:12px 14px;border-radius:6px;background:#fff1f0;color:var(--danger)}}
.type-cards{{display:grid;grid-template-columns:repeat(4,1fr);gap:10px;margin-bottom:16px}}
.type-card{{border:2px solid var(--line);border-radius:8px;padding:12px 8px;cursor:pointer;text-align:center;background:#fafafa}}
.type-card:has(input:checked){{border-color:var(--purple);background:#faf5ff}}
.type-card input{{display:none}}
.type-icon{{display:block;font-size:26px;margin-bottom:4px}}
.type-name{{display:block;font-weight:700}}
.upload-zone{{border:2px dashed var(--purple);border-radius:8px;padding:28px;text-align:center;cursor:pointer;background:#faf5ff;margin-bottom:12px}}
.upload-zone:hover{{background:#f3e8ff}}
.upload-zone input{{display:none}}
.fname{{color:var(--purple);font-weight:700;font-size:15px;margin-top:8px}}
.field-group{{display:flex;flex-direction:column;gap:5px;margin-bottom:12px}}
.field-group label{{font-size:13px;font-weight:700;color:var(--muted);text-transform:uppercase;letter-spacing:.05em}}
.btn-ota{{background:var(--purple);min-height:48px;font-size:15px;width:100%;margin-top:4px}}
.btn-ota:hover{{background:#5b21b6}}
.warn{{background:#fffbeb;border:1px solid #f59e0b;border-radius:6px;padding:10px 14px;margin-bottom:12px;color:#92400e;font-size:13px}}
.file-list{{margin:12px 0}}
.file-list-title{{font-size:13px;font-weight:700;color:var(--muted);margin-bottom:6px}}
.file-chip{{display:inline-block;background:#f3e8ff;color:var(--purple);border:1px solid #e9d5ff;border-radius:20px;padding:3px 10px;font-size:13px;margin:3px}}
.muted{{color:var(--muted)}}
table{{width:100%;border-collapse:collapse;font-size:14px}}
th,td{{padding:10px 8px;border-bottom:1px solid var(--line);text-align:left;vertical-align:top}}
th{{color:var(--muted);font-weight:700}}
code{{background:#eef2f7;padding:2px 5px;border-radius:4px}}
.state-sent,.state-ota-sent{{color:var(--ok);font-weight:700}}
.state-failed{{color:var(--danger);font-weight:700}}
@media(max-width:640px){{.type-cards{{grid-template-columns:repeat(2,1fr)}}header,.custom{{display:block}}.meta{{text-align:left;margin-top:8px}}}}
</style>
</head>
<body>
<main>
<header>
  <div><h1>IMX6ULL OTA Control</h1></div>
  <div class="meta">
    Broker: <code>{html.escape(MQTT_HOST)}:{html.escape(MQTT_PORT)}</code><br>
    Topic: <code>{html.escape(MQTT_TOPIC)}</code><br>
    File server: <code>{html.escape(HOST_IP)}:{FILE_PORT}</code>
  </div>
</header>

{f'<div class="notice">{html.escape(status)}</div>' if status else ''}
{f'<div class="error">{html.escape(error)}</div>' if error else ''}

<section>
  <h2>Quick Commands</h2>
  <form method="post"><div class="quick">{buttons}</div></form>
  <form class="custom" method="post">
    <input type="text" name="message" placeholder="Type command payload" autocomplete="off" required>
    <button type="submit">Send</button>
  </form>
</section>

<section>
  <h2>Upload OTA</h2>
  <div class="warn">Chọn type, chọn file, bấm upload. Web sẽ lưu file vào <code>{html.escape(OTA_DIR)}</code>, tạo URL, rồi publish MQTT OTA luôn.</div>
  <form method="post" enctype="multipart/form-data">
    <div class="type-cards">{type_cards}</div>

    <div class="field-group">
      <label>Version</label>
      <input type="text" name="ota_version" value="1.0.0" required>
    </div>

    <div class="upload-zone" onclick="document.getElementById('file-input').click()">
      <input type="file" name="ota_file" id="file-input" onchange="onFileSelect(this)" required>
      <div style="font-size:36px">📁</div>
      <div>Click để chọn file OTA</div>
      <div class="muted">zImage, mqtt_led_app, rootfs.tar.gz...</div>
      <div class="fname" id="fname-label"></div>
    </div>

    {file_list}

    <button type="submit" class="btn-ota" name="ota_upload" value="1">🚀 Upload & Send OTA</button>
  </form>
</section>

<section>
  <h2>Send History</h2>
  <table>
    <thead><tr><th>Time</th><th>Topic</th><th>Message</th><th>State</th></tr></thead>
    <tbody>{rows or '<tr><td colspan="4">No commands sent yet.</td></tr>'}</tbody>
  </table>
</section>
</main>

<script>
function onFileSelect(input) {{
  const label = document.getElementById('fname-label');
  label.textContent = input.files[0] ? '✅ ' + input.files[0].name : '';
}}
</script>
</body>
</html>'''


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        self._send_html(page())

    def do_POST(self):
        ct = self.headers.get("Content-Type", "")

        if "multipart/form-data" in ct:
            form = cgi.FieldStorage(
                fp=self.rfile,
                headers=self.headers,
                environ={"REQUEST_METHOD": "POST", "CONTENT_TYPE": ct},
            )

            if "ota_upload" not in form:
                self._send_html(page(error="No upload action"), status=400)
                return

            ota_file = form["ota_file"]
            ota_type = form.getvalue("ota_type", "kernel").strip()
            ota_version = form.getvalue("ota_version", "1.0.0").strip()

            if not ota_file.filename:
                self._send_html(page(error="No file selected"), status=400)
                return

            fname = os.path.basename(ota_file.filename)
            save_path = os.path.join(OTA_DIR, fname)

            with open(save_path, "wb") as f:
                f.write(ota_file.file.read())
            os.chmod(save_path, 0o755)

            file_url = f"http://{HOST_IP}:{FILE_PORT}/{fname}"
            payload = json.dumps({
                "cmd": "ota",
                "type": ota_type,
                "version": ota_version,
                "url": file_url,
            }, separators=(",", ":"))

            try:
                publish_mqtt(payload)
                add_history(f"[OTA-{ota_type.upper()}] {fname} v{ota_version} -> {file_url}", "ota-sent")
                self._send_html(page(status=f"✅ Uploaded & sent OTA {ota_type}: {fname} v{ota_version} → {file_url}"))
            except Exception as exc:
                add_history(f"[OTA-{ota_type.upper()}] {fname} v{ota_version}", "failed")
                self._send_html(page(error=str(exc)), status=500)
            return

        length = int(self.headers.get("Content-Length", "0"))
        body = self.rfile.read(length).decode("utf-8", errors="replace")
        data = parse_qs(body)

        message = data.get("message", [""])[0].strip()
        if not message:
            self._send_html(page(error="Message is empty"), status=400)
            return

        try:
            publish_mqtt(message)
            add_history(message, "sent")
            self._send_html(page(status=f"Sent: {message}"))
        except Exception as exc:
            add_history(message, "failed")
            self._send_html(page(error=str(exc)), status=500)

    def log_message(self, fmt, *args):
        print("%s - %s" % (self.address_string(), fmt % args))

    def _send_html(self, content, status=200):
        data = content.encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)


def main():
    server = ThreadingHTTPServer((HOST, PORT), Handler)
    print(f"Web MQTT control : http://127.0.0.1:{PORT}")
    print(f"OTA file server  : http://{HOST_IP}:{FILE_PORT}/")
    print(f"MQTT broker      : {MQTT_HOST}:{MQTT_PORT} → {MQTT_TOPIC}")
    print(f"OTA dir          : {OTA_DIR}")
    server.serve_forever()


if __name__ == "__main__":
    main()