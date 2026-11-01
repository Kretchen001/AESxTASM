#!/usr/bin/env python3
"""Startet einen lokalen Webserver fuer die Browserversion.
Aufruf:  python3 web/serve.py [Port]      (Standard 8000)  ->  http://localhost:8000
"""
import functools, http.server, os, sys

port = int(sys.argv[1]) if len(sys.argv) > 1 else 8000
root = os.path.dirname(os.path.abspath(__file__))
handler = functools.partial(http.server.SimpleHTTPRequestHandler, directory=root)
handler.extensions_map = {**http.server.SimpleHTTPRequestHandler.extensions_map, ".jsdos": "application/octet-stream"}
with http.server.ThreadingHTTPServer(("127.0.0.1", port), handler) as srv:
    print(f"AES im Browser: http://localhost:{port}   (Beenden mit Strg+C)")
    try:
        srv.serve_forever()
    except KeyboardInterrupt:
        pass
