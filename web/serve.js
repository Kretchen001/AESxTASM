// Startet einen lokalen Webserver fuer die Browserversion (nur Node.js, keine Pakete).
// Aufruf:  node web/serve.js [Port]      (Standard 8000)  ->  http://localhost:8000
const http = require("http"), fs = require("fs"), path = require("path");
const port = parseInt(process.argv[2] || "8000", 10);
const root = __dirname;
const types = { ".html": "text/html; charset=utf-8", ".js": "text/javascript", ".css": "text/css",
                ".jsdos": "application/octet-stream" };
http.createServer((req, res) => {
  let p = decodeURIComponent(req.url.split("?")[0]);
  if (p.endsWith("/")) p += "index.html";
  const file = path.normalize(path.join(root, p));
  if (!file.startsWith(root + path.sep)) { res.writeHead(403); return res.end("403"); }
  fs.readFile(file, (err, data) => {
    if (err) { res.writeHead(404); return res.end("404"); }
    res.writeHead(200, { "Content-Type": types[path.extname(file)] || "application/octet-stream" });
    res.end(data);
  });
}).listen(port, "127.0.0.1", () => console.log(`AES im Browser: http://localhost:${port}   (Beenden mit Strg+C)`));
