#!/usr/bin/env python3
"""Receiver for tools/studio_sync/ExportSnapshot.lua (Mac / Linux; receive_snapshot.ps1 is the Windows one).

Listens on localhost:8767 and writes every POST /save?path=<rel> body to <root>/<rel>. Run it, then run
ExportSnapshot.lua in Studio (Edit mode). Stop it with Ctrl+C when the export prints that it's done.

    python3 tools/studio_sync/receive_snapshot.py            # writes into studio/
    python3 tools/studio_sync/receive_snapshot.py --fresh    # empties studio/ first (keeps README.md), so scripts
                                                             # deleted in Studio don't linger

Only paths inside the root are accepted (no "..", no absolute paths).
"""
import argparse
import http.server
import os
import shutil
import sys
import urllib.parse

PORT = 8767


def main():
    here = os.path.dirname(os.path.abspath(__file__))
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", default=os.path.join(here, "..", "..", "studio"))
    ap.add_argument("--fresh", action="store_true", help="empty the root first")
    ap.add_argument("--port", type=int, default=PORT, help="if 8767 is taken; set the same PORT in ExportSnapshot.lua")
    args = ap.parse_args()
    count = {"n": 0}
    root = os.path.realpath(args.root)

    class Handler(http.server.BaseHTTPRequestHandler):
        def do_POST(self):
            url = urllib.parse.urlparse(self.path)
            rel = urllib.parse.parse_qs(url.query).get("path", [""])[0]
            target = os.path.realpath(os.path.join(root, rel))
            if url.path != "/save" or not rel or os.path.isabs(rel) or not target.startswith(root + os.sep):
                self.send_response(400)
                self.end_headers()
                return
            body = self.rfile.read(int(self.headers.get("Content-Length", 0)))
            os.makedirs(os.path.dirname(target), exist_ok=True)
            with open(target, "wb") as f:
                f.write(body)
            count["n"] += 1
            self.send_response(200)
            self.end_headers()
            self.wfile.write(b"ok")

        def do_GET(self):  # ExportSnapshot.lua calls /done at the end
            if self.path.startswith("/done"):
                print(f"export done: {count['n']} files", flush=True)
            self.send_response(200)
            self.end_headers()

        def log_message(self, *a):
            pass

    server = http.server.HTTPServer(("127.0.0.1", args.port), Handler)  # bind first: a busy port fails before --fresh
    if args.fresh and os.path.isdir(root):
        for name in os.listdir(root):  # everything but the folder's README
            if name != "README.md":
                path = os.path.join(root, name)
                shutil.rmtree(path) if os.path.isdir(path) else os.remove(path)
    os.makedirs(root, exist_ok=True)
    print(f"receiving into {root} on :{args.port}", flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    print(f"wrote {count['n']} files", flush=True)


if __name__ == "__main__":
    sys.exit(main())
