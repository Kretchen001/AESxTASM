#!/usr/bin/env python3
"""Baut web/aes.jsdos aus ASM/*.asm ohne TASM (nur mit JWasm).

Die Quelltexte im Repo bleiben unveraendert. In einer temporaeren Kopie werden
TASM-Eigenheiten MASM-tauglich gemacht:
  PUSH DS AX BX   ->  PUSH DS / PUSH AX / PUSH BX   (POP analog, Reihenfolge wie im Quelltext)
  ENDP Name       ->  Name ENDP
  X DB ""         ->  X LABEL BYTE                  (leerer String, gleiche Wirkung)
  INCLUDE-Namen   ->  Gross-/Kleinschreibung an die echte Datei angepasst (Linux)
Aufruf:  python3 web/tools/build_jsdos.py [--jwasm PFAD]
JWasm: https://github.com/Baron-von-Riedesel/JWasm (Linux: make -f GccUnix.mak)
"""
import argparse, glob, os, re, shutil, subprocess, sys, tempfile, zipfile

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
CONF = "[sdl]\nautolock=false\n[cpu]\ncore=auto\ncycles=max\n[autoexec]\n@echo off\nmount c .\nc:\nAES.EXE\n"

def convert(text, names):
    out = []
    for line in text.replace("\r", "").split("\n"):
        code = line.partition(";")[0]
        m = re.match(r"^(\s*)(PUSH|POP)\s+([A-Za-z]{2}(?:\s+[A-Za-z]{2})+)\s*$", code, re.I)
        if m:
            ind, op, regs = m.groups()
            out += [f"{ind}{op} {r}" for r in regs.split()]
            continue
        m = re.match(r"^(\s*)ENDP\s+(\w+)\s*$", code, re.I)
        if m:
            out.append(f"{m.group(1)}{m.group(2)} ENDP"); continue
        m = re.match(r'^(\w+)\s+DB\s+""\s*$', code)
        if m:
            out.append(f"{m.group(1)} LABEL BYTE"); continue
        m = re.match(r"^(\s*INCLUDE\s+)(\S+)(.*)$", line, re.I)
        if m and m.group(2).lower() in names:
            line = m.group(1) + names[m.group(2).lower()] + m.group(3)
        out.append(line)
    return "\n".join(out)

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--jwasm", default=shutil.which("jwasm") or "jwasm")
    a = ap.parse_args()
    files = glob.glob(os.path.join(ROOT, "ASM", "*.asm"))
    names = {os.path.basename(f).lower(): os.path.basename(f) for f in files}
    with tempfile.TemporaryDirectory() as tmp:
        for f in files:
            txt = open(f, encoding="latin-1").read()
            with open(os.path.join(tmp, os.path.basename(f)), "w", encoding="latin-1", newline="\n") as o:
                o.write(convert(txt, names))
        r = subprocess.run([shutil.which(a.jwasm) or os.path.abspath(a.jwasm), "-mz", "-Fo", "AES.EXE", "AES.asm"], cwd=tmp)
        exe = os.path.join(tmp, "AES.EXE")
        if r.returncode or not os.path.getsize(exe):
            sys.exit("JWasm-Build fehlgeschlagen")
        dst = os.path.join(ROOT, "web", "aes.jsdos")
        with zipfile.ZipFile(dst, "w", zipfile.ZIP_DEFLATED) as z:
            z.writestr(".jsdos/dosbox.conf", CONF)
            z.write(exe, "AES.EXE")
        print("geschrieben:", dst, os.path.getsize(exe), "Byte EXE")

if __name__ == "__main__":
    main()
