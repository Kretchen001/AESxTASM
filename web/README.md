# AES im Browser (js-dos / WebAssembly)

Die DOS-Version laeuft in DOSBox, das per WebAssembly im Browser ausgefuehrt wird (js-dos).
Es muss weder DOSBox noch TASM installiert sein.

## Starten
    python3 web/serve.py [Port]     # oder
    node web/serve.js [Port]        # Standard-Port 8000
Dann http://localhost:8000 oeffnen. (`file://` geht nicht, der Browser darf das Bundle nur ueber HTTP laden.)
Fuer Veroeffentlichung genuegt jeder statische Webserver, z. B. GitHub Pages mit dem Ordner `web/`.
Der Browser laedt js-dos von v8.js-dos.com, dafuer ist eine Internetverbindung noetig.

## Inhalt
- `index.html`  Seite mit dem Emulator
- `aes.jsdos`   ZIP mit `AES.EXE` und `.jsdos/dosbox.conf` (Autostart)
- `tools/build_jsdos.py`  baut `aes.jsdos` neu (JWasm statt TASM, ASM-Quellen bleiben unveraendert)

## Hinweis
`aes.jsdos` enthaelt eine mit JWasm gebaute EXE. Wer die mit `asmaes.bat` (TASM) gebaute `AES.EXE`
verwenden will, ersetzt sie einfach im ZIP.
