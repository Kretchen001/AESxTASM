# AES in TASM

**Deutsch** · [English](#english)

Abschlussprojekt im Modul „Assemblerprogrammierung“ von Konstantin Blechschmidt und Tim M. Kretzschmar. Ein AES-ähnliches Verfahren in 16-Bit-Assembler (TASM, Real Mode) mit Mausbedienung im DOS-Textmodus. Aktuelle Version: **2.0.0**.

> **Hinweis:** Das Verfahren ist *AES-ähnlich*, aber **kein** AES und **nicht** zum Schutz echter Daten geeignet (zwei Runden, ohne MixColumns im aktiven Ablauf, 64-Byte-Schlüssel). Es ist ein Lernprojekt. Details im Kapitel „Bekannte Einschränkungen“ der Dokumentation.

## Inhalt

- [Funktionen](#funktionen)
- [Schnellstart](#schnellstart)
- [Bedienung](#bedienung)
- [Browserversion ohne DOS-Box](#browserversion-ohne-dos-box)
- [Projektstruktur](#projektstruktur)
- [Dokumentation](#dokumentation)
- [Stand der Prüfung](#stand-der-prüfung)
- [Version 2.0.0](#version-200)

## Funktionen

- Ver- und Entschlüsseln von bis zu 64 Zeichen. Der Chiffretext ist immer 64 Bytes lang (Nullbytes als Auffüllung werden mitverschlüsselt).
- Verfahrensbausteine: S-Box und inverse S-Box, ShiftRow, Rundenschlüssel-Erzeugung, Multiplikation im Körper GF(2⁸) mit dem Polynom 11Bh. Der Zustand besteht aus 64 Bytes, also vier unabhängigen 4×4-Blöcken.
- Eingabe eines eigenen Schlüssels (hexadezimal, bis zu 64 Bytes) oder Verwendung des eingebauten Standardschlüssels.
- Bedienung per Maus (Hauptbildschirm) und Tastatur, Ausgabe über direkten Zugriff auf den Bildschirmspeicher.
- Eigene Interrupt-Routine (ISR) als Demonstration, Maus über INT 33h.

## Schnellstart

Voraussetzung: DOS-Box mit Borland TASM und TLINK. Alternativ die [Browserversion](#browserversion-ohne-dos-box).

In der DOS-Box im Projektordner:

| Befehl | Wirkung |
| --- | --- |
| `start.bat` | assembliert, linkt und startet das Programm |
| `aes.bat` | startet die bereits gebaute `AES.EXE` |
| `asmaes.bat` | nur assemblieren und linken (gut, um Fehler und Warnungen zu sehen) |
| `tdaes.bat` | assembliert und startet den Turbo Debugger |

Von Hand entspricht das, im Ordner `ASM`:

```
tasm AES.asm
tlink AES.obj
AES.exe
```

Bitte nur in der DOS-Box-Umgebung starten.

## Bedienung

1. Auf dem Hauptbildschirm *Verschlüsseln* oder *Entschlüsseln* mit der Maus anklicken.
2. Text eingeben und mit `Enter` bestätigen. Beim Verschlüsseln ist das der Klartext (bis 64 Zeichen), beim Entschlüsseln der Chiffretext in Hexadezimalziffern (128 Ziffern in zwei Zeilen).
3. Optional einen Schlüssel eingeben (Hexadezimal, Ziffern `0`–`9` und `A`–`F` in Großbuchstaben). Mit `Enter` ohne Eingabe gilt der Standardschlüssel.
4. Mit dem zweiten `Enter` beginnt die Rechnung, das Ergebnis erscheint auf dem Bildschirm.
5. `ESC` führt zurück zum Hauptbildschirm. `ESC` dort beendet das Programm.

Zum Entschlüsseln muss derselbe Schlüssel wie beim Verschlüsseln verwendet werden.

## Browserversion ohne DOS-Box

Der Ordner [`web/`](web/) enthält eine Fassung, die in jedem aktuellen Browser läuft. Sie nutzt [js-dos](https://js-dos.com), eine DOS-Box, die per WebAssembly im Browser ausgeführt wird.

```
python3 web/serve.py      # oder: node web/serve.js
```

Danach `http://localhost:8000` öffnen (anderer Port als Argument möglich). Für die Veröffentlichung genügt jeder statische Webserver, zum Beispiel GitHub Pages mit dem Ordner `web/`. Die Seite lädt js-dos aus dem Netz, es ist also eine Internetverbindung nötig.

Die darin enthaltene `AES.EXE` wird mit dem freien Assembler JWasm gebaut (`python3 web/tools/build_jsdos.py`), nicht mit TASM. Die Quelltexte bleiben dabei unverändert. Mehr dazu in [`web/README.md`](web/README.md).

## Projektstruktur

```
AES.bat, start.bat, asmaes.bat, tdaes.bat   Start- und Build-Skripte für die DOS-Box
ASM/                 Quelltexte
  AES.asm            Hauptdatei, bindet alle anderen per INCLUDE ein
  SBOX.asm           S-Box und inverse S-Box
  config.asm         Bildschirme, Variablen, Rundenschlüssel
  ISR.asm, MAUS.asm  Interrupt-Routine und Mausabfrage
  BildPROC.asm       Zeichnen der Bildschirme
  VERS.asm, ENTS.asm Rechen-PROCs für Verschlüsseln und Entschlüsseln
  Ver_Code.asm, Ent_Code.asm   Eingabe und Ablaufsteuerung
  Ablauf_V.asm, Ablauf_E.asm   Reihenfolge der Rechenschritte
Dokumentation/
  LaTeX/             Dokumentation zur Version 2.0.0 (pdflatex + biber)
  Ablaufplan.md      Rechenbeispiel: welches Register, wohin, welcher Befehl
  Modelltest/        Python-Nachbau der Rechen-PROCs mit Prüfungen
  PAPs/              Programmablaufpläne
Planung/             Skizzen und Entwürfe
web/                 Browserversion (js-dos), Webserver, Bauskript
```

## Dokumentation

- **LaTeX-Dokumentation** in `Dokumentation/LaTeX/` (Einleitung, Grundlagen, ASM-Dateien, Beispiel „Hallo“, Batch-Dateien, Anleitung, Funktionalität, Einschränkungen, Änderungen, Entwurf, Tests, Browserversion, Erklärung). Übersetzen mit `pdflatex` und `biber`, siehe Kopf von `main.tex`.
- **Ablaufplan** in `Dokumentation/Ablaufplan.md`.
- **Modelltest**: `python3 Dokumentation/Modelltest/modelltest.py` prüft die Rechenroutinen im Python-Nachbau gegen unabhängige Referenzen (11 Prüfungen).

## Stand der Prüfung

| Bereich | Stand |
| --- | --- |
| Rechenlogik im Python-Modell | geprüft (M1–M11 bestanden) |
| Übersetzen mit TASM, Lauf in der DOS-Box | steht aus (Testplan D1–D7 im Kapitel „Tests“) |
| Browserversion (JWasm-EXE in js-dos) | gebaut, im Emulator noch nicht geprüft |

Erwartete Werte für die Prüfung in der DOS-Box oder im Browser (Standardschlüssel):

| Eingabe | Chiffretext beginnt mit |
| --- | --- |
| `Hallo` | `E159BDA8 8E0FB958` |

Weitere Erwartungswerte stehen im Kapitel „Tests“.

## Version 2.0.0

Behoben: inverse S-Box (Index 70h), ShiftRow (alle vier Blöcke), eigene Schlüsseleingabe, MixColumns (`ShiftColumn`) und neu geschriebene inverse MixColumns (`ShiftColumn_1`). Der aktive Ablauf (`Ablauf_V`, `Ablauf_E`) ist unverändert zweirundig und ruft MixColumns nicht auf. Mit Version 1.0 erzeugte Chiffretexte lassen sich mit 2.0.0 nicht mehr vollständig entschlüsseln. Einzelheiten: Kapitel „Änderungen“ und „Bekannte Einschränkungen“.

---

<a id="english"></a>

# AES in TASM

[Deutsch](#aes-in-tasm) · **English**

Final project of the module “Assembly Programming” by Konstantin Blechschmidt and Tim M. Kretzschmar. An AES-like cipher written in 16-bit assembly (TASM, real mode) with mouse control in DOS text mode. Current version: **2.0.0**.

> **Note:** The cipher is *AES-like*, **not** AES, and **not** suitable for protecting real data (two rounds, no MixColumns in the active flow, 64-byte key). It is a learning project. See the chapter “Known limitations” of the documentation (written in German).

## Contents

- [Features](#features)
- [Quick start](#quick-start)
- [Usage](#usage)
- [Browser version without DOSBox](#browser-version-without-dosbox)
- [Project layout](#project-layout)
- [Documentation](#documentation-1)
- [Verification status](#verification-status)
- [Version 2.0.0](#version-200-1)

## Features

- Encrypts and decrypts up to 64 characters. The ciphertext is always 64 bytes long (zero padding is encrypted as well).
- Building blocks: S-box and inverse S-box, ShiftRow, round key generation, multiplication in GF(2⁸) with the polynomial 11Bh. The state is 64 bytes, i.e. four independent 4×4 blocks.
- Custom key input (hexadecimal, up to 64 bytes) or the built-in default key.
- Mouse control (main screen) and keyboard, output by writing directly to video memory.
- A custom interrupt service routine (ISR) as a demonstration, mouse via INT 33h.

## Quick start

Requirements: DOSBox with Borland TASM and TLINK. Alternatively use the [browser version](#browser-version-without-dosbox).

In DOSBox, in the project folder:

| Command | Effect |
| --- | --- |
| `start.bat` | assembles, links and starts the program |
| `aes.bat` | starts the already built `AES.EXE` |
| `asmaes.bat` | assemble and link only (useful to see errors and warnings) |
| `tdaes.bat` | assembles and starts Turbo Debugger |

By hand, in the folder `ASM`:

```
tasm AES.asm
tlink AES.obj
AES.exe
```

Run it in a DOSBox environment only.

## Usage

1. On the main screen, click *Encrypt* (“Verschluesseln”) or *Decrypt* (“Entschluesseln”) with the mouse.
2. Type the text and confirm with `Enter`. For encryption this is the plaintext (up to 64 characters); for decryption it is the ciphertext as hexadecimal digits (128 digits on two lines).
3. Optionally enter a key (hexadecimal, digits `0`–`9` and uppercase `A`–`F`). Pressing `Enter` without input uses the default key.
4. The second `Enter` starts the computation and the result is shown on screen.
5. `ESC` returns to the main screen; `ESC` there quits the program.

Decryption needs the same key that was used for encryption.

## Browser version without DOSBox

The folder [`web/`](web/) contains a version that runs in any current browser. It uses [js-dos](https://js-dos.com), a DOSBox compiled to WebAssembly.

```
python3 web/serve.py      # or: node web/serve.js
```

Then open `http://localhost:8000` (another port can be passed as an argument). To publish it, any static web server will do, for example GitHub Pages with the folder `web/`. The page loads js-dos from the network, so an internet connection is required.

The bundled `AES.EXE` is built with the free assembler JWasm (`python3 web/tools/build_jsdos.py`), not with TASM. The sources stay untouched. More in [`web/README.md`](web/README.md).

## Project layout

```
AES.bat, start.bat, asmaes.bat, tdaes.bat   start and build scripts for DOSBox
ASM/                 source code
  AES.asm            main file, includes all others via INCLUDE
  SBOX.asm           S-box and inverse S-box
  config.asm         screens, variables, round keys
  ISR.asm, MAUS.asm  interrupt routine and mouse handling
  BildPROC.asm       screen drawing
  VERS.asm, ENTS.asm computation PROCs for encryption and decryption
  Ver_Code.asm, Ent_Code.asm   input and flow control
  Ablauf_V.asm, Ablauf_E.asm   order of the computation steps
Dokumentation/
  LaTeX/             documentation for version 2.0.0 (pdflatex + biber)
  Ablaufplan.md      worked example: which register, where to, which instruction
  Modelltest/        Python port of the computation PROCs with checks
  PAPs/              flowcharts
Planung/             sketches and drafts
web/                 browser version (js-dos), web servers, build script
```

## Documentation

- **LaTeX documentation** in `Dokumentation/LaTeX/` (German): introduction, basics, ASM files, example “Hallo”, batch files, user guide, functionality, limitations, changes, design, tests, browser version, declaration. Build with `pdflatex` and `biber`; see the header of `main.tex`.
- **Flow plan** in `Dokumentation/Ablaufplan.md` (German).
- **Model test**: `python3 Dokumentation/Modelltest/modelltest.py` checks the computation routines in a Python port against independent references (11 checks).

## Verification status

| Area | Status |
| --- | --- |
| Computation logic in the Python model | verified (M1–M11 pass) |
| Assembling with TASM, run in DOSBox | pending (test plan D1–D7, chapter “Tests”) |
| Browser version (JWasm EXE in js-dos) | built, not yet checked in the emulator |

Expected values for checking in DOSBox or in the browser (default key):

| Input | Ciphertext starts with |
| --- | --- |
| `Hallo` | `E159BDA8 8E0FB958` |

More expected values are listed in the chapter “Tests”.

## Version 2.0.0

Fixed: inverse S-box (index 70h), ShiftRow (all four blocks), custom key input, MixColumns (`ShiftColumn`), and a newly written inverse MixColumns (`ShiftColumn_1`). The active flow (`Ablauf_V`, `Ablauf_E`) is still two rounds and does not call MixColumns. Ciphertexts made with version 1.0 can no longer be fully decrypted with 2.0.0. Details: chapters “Changes” and “Known limitations”.
