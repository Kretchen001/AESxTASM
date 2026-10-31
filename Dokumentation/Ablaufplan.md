# AES in TASM – Ablaufplan und Rechenbeispiel

Stand: Branch `v2.0.0`. Dieses Dokument beschreibt, **was das Programm in welcher Reihenfolge tut**, **welches Register dabei welche Aufgabe hat**, **welcher Befehl das erledigt** und **warum**. Am Ende jedes größeren Abschnitts steht ein Zahlenbeispiel, das durchgängig mit dem Klartext `Hallo` und dem eingebauten Standardschlüssel gerechnet ist.

**Lesehilfe**

- Zahlen mit `h` oder in Großbuchstaben ohne Zusatz (`4D`) sind hexadezimal, Zahlen ohne Zusatz in Rechnungen mit Bildschirmadressen sind dezimal (`1936`).
- `Pos n` meint das n-te Byte des 64-Byte-Zustands (`TastaturBuffer[n]`, Zählung ab 0).
- Dateinamen beziehen sich auf den Ordner `ASM/`.
- Die Beispielwerte wurden mit einem Python-Nachbau der Routinen berechnet (Registerlogik, Sprungbedingungen und Speicherlayout nachgebildet). Der Nachbau und der Assembler-Code liefern dasselbe Chiffrat; die Werte wurden aber **nicht** in der DOS-Box nachgemessen.

---

## Inhaltsverzeichnis

1. [Überblick: Dateien und Einbindung](#1-überblick-dateien-und-einbindung)
2. [Datensegment: wichtige Variablen und Speicherlayout](#2-datensegment-wichtige-variablen-und-speicherlayout)
3. [Register im Überblick](#3-register-im-überblick)
4. [Programmstart und Hauptbildschirm](#4-programmstart-und-hauptbildschirm)
5. [Mausklick: von Pixel zu Schaltfläche](#5-mausklick-von-pixel-zu-schaltfläche)
6. [Verschlüsseln: Eingabe](#6-verschlüsseln-eingabe)
7. [Der Verschlüsselungsablauf (Ablauf_V)](#7-der-verschlüsselungsablauf-ablauf_v)
8. [Verschlüsseln: Ausgabe als Hexwerte](#8-verschlüsseln-ausgabe-als-hexwerte)
9. [Entschlüsseln](#9-entschlüsseln)
10. [MixColumns (ShiftColumn) und Inverse](#10-mixcolumns-shiftcolumn-und-inverse)
11. [Gesamtübersicht der Abläufe](#11-gesamtübersicht-der-abläufe)
12. [Änderungen in v2.0.0](#12-änderungen-in-v200)
13. [Bekannte Einschränkungen](#13-bekannte-einschränkungen)

---

## 1. Überblick: Dateien und Einbindung

Das Programm besteht aus **einem** Assemblerprogramm, das über `INCLUDE` aus mehreren Dateien zusammengesetzt wird. Die Dateien sind keine getrennt übersetzten Module; TASM setzt sie beim Übersetzen von `AES.asm` an der Stelle des `INCLUDE` ein. Daraus folgt: **Alle Labels sind global**, Variablen liegen in einem gemeinsamen Datensegment, und Code, der per `INCLUDE` mitten in einen Ablauf eingebunden wird (`Ver_Code.asm`, `Ent_Code.asm`, `Ablauf_V.asm`, `Ablauf_E.asm`), läuft einfach „durch“ – er ist kein Unterprogramm.

| Datei | Inhalt | eingebunden in |
|---|---|---|
| `AES.asm` | Hauptdatei: `.MODEL SMALL`, `.486`, `.STACK 100h`; Programmstart, Endlosschleife, Verzweigung Ver-/Entschlüsseln, Programmende | – |
| `SBOX.asm` | S-Box `s_0` und inverse S-Box `s_1_0` (je 256 Bytes) | `AES.asm`, im `.DATA`-Teil |
| `config.asm` | Alle Variablen, Konstanten, Bildschirmtexte, Standardschlüssel, Mausbereiche, `InvMixMatrix` | `AES.asm`, im `.DATA`-Teil |
| `ISR.asm` | Beispiel für eine eigene Interruptroutine (Demo, im Ablauf nicht aktiv) | `AES.asm`, `.CODE` |
| `BildPROC.asm` | `HauptbildschirmProc`, `BildschirmProcX` (Bildschirme zeichnen) | `AES.asm`, `.CODE` |
| `MAUS.asm` | `MausPosiProc` (Mausklick auswerten) | `AES.asm`, `.CODE` |
| `VERS.asm` | Rechen-PROCs der Verschlüsselung: `SchluesselInitialisieren`, `SchluesselAnwenden`, `Schluesselexpansion`, `SBOXSubstitution`, `ShiftRow`, `ShiftColumn`, `MalZweiPROC`, `GFMulPROC` | `AES.asm`, `.CODE` |
| `ENTS.asm` | Rechen-PROCs der Entschlüsselung: `SBOXSubstitution_1`, `ShiftRow_1`, `ShiftColumn_1` | `AES.asm`, `.CODE` |
| `Ver_Code.asm` | Tastatureingabe, Aufruf und Ausgabe der Verschlüsselung | `AES.asm`, bei `VerschluesselungBeginn` |
| `Ent_Code.asm` | Tastatureingabe, Aufruf und Ausgabe der Entschlüsselung | `AES.asm`, bei `EntschluesselungBeginn` |
| `Ablauf_V.asm` | Reihenfolge der Rundenschritte beim Verschlüsseln | `Ver_Code.asm`, bei `AufrufenVerAusASM` |
| `Ablauf_E.asm` | Reihenfolge der Rundenschritte beim Entschlüsseln | `Ent_Code.asm`, bei `AufrufenEntAusASM` |

**Warum stehen die PROCs vor `Beginn:`?** Die PROC-Definitionen (`INCLUDE VERS.asm` usw.) stehen im Codesegment vor `Beginn:`, damit der Assembler sie schon kennt, wenn sie aufgerufen werden. Der Prozessor läuft trotzdem nicht „versehentlich“ in sie hinein: Die Zeile `END Beginn` am Dateiende legt das Label `Beginn:` als Einsprungadresse des Programms fest, die Ausführung beginnt also direkt dort.

**Warum `PROC FAR`?** `SchluesselInitialisieren`, `Schluesselexpansion`, `SBOXSubstitution`, `ShiftRow`, `ShiftColumn` und die `_1`-Gegenstücke sind `FAR` deklariert. TASM erzeugt für `CALL` auf eine `FAR`-PROC im selben Segment einen Far-Call (legt `CS` und `IP` auf den Stapel) und für `RET` ein `RETF`. Das funktioniert, ist aber nicht nötig; nur `MausPosiProc` **muss** `FAR` sein, weil der Maustreiber sie per Far-Call aufruft. `MalZweiPROC`, `GFMulPROC` und die Bildschirm-PROCs sind `NEAR`.

---

## 2. Datensegment: wichtige Variablen und Speicherlayout

| Name | Größe | Bedeutung |
|---|---|---|
| `TastaturBuffer` | 65 Bytes | **Arbeitsspeicher der Ver-/Entschlüsselung** (der „Zustand“). Index 0..63 sind die 64 Nutzbytes, Byte 64 ist ein Reserve-Byte. Beim Verschlüsseln stehen am Anfang die ASCII-Werte des Klartextes, danach der Zustand nach jedem Rundenschritt, am Ende das Chiffrat. Nicht eingegebene Stellen bleiben `00h`. |
| `TastaturBufferOrg` | 65 Bytes | Sicherung der Originaleingabe, nur für die Anzeige im Ergebnisbildschirm. |
| `Rundenschluessel_0` | 64 Bytes | **Der Schlüssel** (Standardwert aus `config.asm`; wird von einer Schlüsseleingabe überschrieben). |
| `Rundenschluessel_Expand` | 64 Bytes | **Der aktuelle Rundenschlüssel.** Liegt im Speicher **unmittelbar hinter** `Rundenschluessel_0` (beide sind `DB`-Reihen ohne Lücke). Mit jeder `Schluesselexpansion` wird er auf den nächsten Rundenschlüssel weitergerechnet. |
| `Konstante` | 1 Byte | Startwert der Rundenkonstante, `5Fh` (`01011111b`). |
| `Rundekonstante` | 1 Byte | Aktuelle Rundenkonstante; wird nach jeder Expansion um 1 Bit nach links rotiert. |
| `ShiftZwSpeicher` | 4 Bytes | Zwischenspeicher für eine Zeile in `ShiftRow` / `ShiftRow_1`. |
| `ShiftBXZwSpeicher` | 1 Wort | Zwischenspeicher für „BX + 4“ in `ShiftRow` (Schleifenende-Vergleichswert). |
| `ShiftColumnZW`, `ShiftColumnZW2` | 1 Byte / 4 Bytes | Zwischenspeicher in `ShiftColumn` und `ShiftColumn_1`. |
| `InvMixMatrix` | 16 Bytes | Inverse Matrix für `ShiftColumn_1` (neu in v2.0.0). |
| `bool_Ent_Ver` | 1 Byte | Zustandsmerker: `1` = Entschlüsseln gewählt, `2` = Verschlüsseln gewählt, `3` = nichts zu tun. Wird von der Maus-PROC gesetzt und von der Endlosschleife gelesen. |
| `BildschirmVar` | 1 Byte | Welcher Bildschirm gezeichnet werden soll: `2` Entschlüsseln-Eingabe, `3` Verschlüsseln-Eingabe, `4` Verschlüsseln-Ergebnis, `5` Entschlüsseln-Ergebnis. |
| `EntR1_L … VerR3_R` | je 1 Wort | Grenzen der sechs Schaltflächenzeilen als Offset im Videospeicher. |
| `Hauptbildschirm`, `…2`, `…3`, `…4_Ergebnis`, `…5_Ergebnis` | je 22 Zeilen à 80 Zeichen | Bildschirmtexte, mit `$` abgeschlossen (für `INT 21h`, Funktion 09h). |

**Wichtig für das Verständnis der Schlüsselbehandlung:** `Rundenschluessel_0` (Quelle) und `Rundenschluessel_Expand` (wird verändert) sind zwei getrennte Arrays. Die PROC `SchluesselInitialisieren` kopiert 64 Bytes von `_0` nach `_Expand` und setzt `Rundekonstante := Konstante`. Beim Entschlüsseln wird sie mitten im Ablauf noch einmal aufgerufen, um wieder beim Ausgangsschlüssel zu beginnen (Abschnitt 9).

---

## 3. Register im Überblick

Die 16-Bit-Register haben in diesem Programm je nach Programmteil feste Rollen. Die folgende Tabelle ist die Kurzfassung; die Begründung steht in den jeweiligen Abschnitten.

| Register | Rolle | wo |
|---|---|---|
| `DS` | Zeigt auf das Datensegment (`@DATA`), damit alle Variablen mit `Name[Index]` ansprechbar sind. | `Beginn`, `Schluesselexpansion` |
| `ES` | Zeigt auf den Videospeicher `0B800h` (Textmodus 3). Alle `MOV WORD PTR ES:[DI], AX` schreiben **direkt auf den Bildschirm**. In `Beginn` kurz `CS` für die Maus-Handleradresse. | Bildschirm, Eingabe, Ausgabe |
| `DI` | **Bildschirmposition** (Byte-Offset im Videospeicher) bei Ein-/Ausgabe; **Tabellenindex** bei der S-Box-Suche und Schlüsselexpansion. | Ein-/Ausgabe, `SBOXSubstitution`, `Schluesselexpansion` |
| `SI` | **Zeiger in den `TastaturBuffer` / Schlüssel** (Zählt Zeichen oder Bytes); Schleifenzähler in `SBOXSubstitution` und `SchluesselInitialisieren`. | überall |
| `AX` / `AL` / `AH` | `AL` = Zeichen/Byte, das gerade bearbeitet wird. `AH` = Farbattribut (`0Fh`, weiß auf schwarz), wenn `AX` auf den Bildschirm geschrieben wird; in der Rechnung auf `0` gesetzt, damit `AX` als Index taugt. | überall |
| `BX` | Differenz/Schrittweite in `ShiftRow` (`BX` = „Anfang der Zeile“); Matrixspalte in `ShiftColumn_1`; Hilfsbyte in `GFMulPROC`; `BL` = letztes Schlüsselbyte in `Schluesselexpansion`. | Rechen-PROCs |
| `CX` / `CL` | **Zähler:** Blocknummer in `ShiftRow`; Nibble-Zähler (1. oder 2. Hexziffer) bei der Hexeingabe/-ausgabe; Schleifenzähler in `GFMulPROC` (`LOOP`). Bei der Maus-Einrichtung außerdem Eingabemaske. | siehe Abschnitte |
| `DX` / `DL` | **Zwischenspeicher:** 1. Nibble bei der Hexeingabe; Originalbyte bei der Hexausgabe; `DL` = Rundenkonstante in `Schluesselexpansion`; `DX` = Textadresse für `INT 21h` Funktion 09h. | siehe Abschnitte |
| `BP` | Nur in `ShiftColumn_1` als Spaltenzähler; sonst als „Sicher ist sicher“ gesichert. | `ShiftColumn_1` |

---

## 4. Programmstart und Hauptbildschirm

### 4.1 `Beginn:` (AES.asm)

| Befehl | Register/Wirkung | Warum |
|---|---|---|
| `MOV AX, @DATA` / `MOV DS, AX` | `DS` zeigt auf das Datensegment | Ein Segmentregister kann nicht direkt mit einer Konstanten geladen werden, daher über `AX`. Ohne das greift jeder `MOV AL, Variable` ins Leere. |
| `MOV CX, 00000110b` | Eingabemaske für die Maus: Bit 1 = linke Taste gedrückt, Bit 2 = linke Taste losgelassen | Der Handler soll genau bei diesen beiden Ereignissen aufgerufen werden |
| `PUSH CS` / `POP ES` | `ES := CS` | Funktion 0Ch erwartet die Handleradresse in `ES:DX`. Der Handler `MausPosiProc` liegt im Codesegment, also muss `ES` dessen Segment haben. |
| `MOV DX, OFFSET MausPosiProc` | `DX` = Offset des Handlers | Zweiter Teil der Adresse |
| `MOV AX, 0Ch` / `INT 33h` | Maustreiber, Funktion 0Ch: „Eigene Unterroutine und Ereignismaske setzen“ | Ab jetzt ruft der Treiber bei jedem Klick `MausPosiProc` auf. |
| `CALL HauptbildschirmProc` | siehe 4.2 | Startbildschirm zeichnen |

### 4.2 `HauptbildschirmProc` (BildPROC.asm)

1. `MOV AX, video_seg` / `MOV ES, AX` – `video_seg = 0B800h`. `ES` zeigt jetzt auf den Videospeicher des Textmodus. Jedes Zeichen belegt dort **2 Bytes**: erst das ASCII-Zeichen, dann das Farbattribut. Das Wort `0F48h` (`AL=48h` = `'H'`, `AH=0Fh` = weiß auf schwarz) wird also als `'H'` in Weiß angezeigt, weil Intel die niederwertige Hälfte (`AL`) zuerst im Speicher ablegt.
2. `MOV AL, 03h` / `MOV AH, 00h` / `INT 10h` – BIOS-Funktion 00h: Videomodus 3 (Text 80×25, 16 Farben). Das löscht nebenbei den Bildschirm.
3. `MOV AH, 02h` / `MOV DL, 00h` / `MOV DH, 01h` / `MOV BH, 00h` / `INT 10h` – Cursor auf Spalte 0, Zeile 1 setzen. Die Zeile 0 bleibt leer (deshalb steht in `config.asm` jeweils „leere obere Zeile“).
4. `MOV AH, 01h` / `MOV CX, 2607h` / `INT 10h` – Cursorform. Ein Startwert größer als das Ende (`26h` > `07h`) macht den Cursor unsichtbar.
5. `MOV AH, 09h` / `MOV DX, OFFSET Hauptbildschirm` / `INT 21h` – DOS gibt den Text bis zum `$` aus. Jede Bildschirmzeile ist **genau 80 Zeichen** lang; es gibt keine Zeilenumbruch-Zeichen, die Zeile bricht von allein um.
6. `MOV AX, 1` / `INT 33h` – Mauszeiger einschalten.
7. `MOV bool_Ent_Ver, 3` – Zustand „nichts zu tun“.

**Umrechnung Bildschirmposition → Offset im Videospeicher:** `Offset = (Zeile × 80 + Spalte) × 2 = Zeile × 160 + Spalte × 2`.
Beispiel: Zeile 12, Spalte 8 → `12 × 160 + 8 × 2 = 1936`. Das ist der Startpunkt des Eingabefeldes (`DI = 1936`).

### 4.3 Endlosschleife (`Endlosschleife:` in AES.asm)

```
Endlosschleife:
    MOV AH, 01h        ; BIOS-Tastatur, Fkt. 1: Taste vorhanden? (entnimmt NICHT)
    INT 16h
    CMP AL, ESC_Code   ; ESC (1Bh)?
    JE  ESCEnde
    CMP bool_Ent_Ver, 1 → EntschluesselungBeginn
    CMP bool_Ent_Ver, 2 → VerschluesselungBeginn
    JNE Endlosschleife
```

Die Schleife wartet („pollt“), bis die Maus-PROC `bool_Ent_Ver` auf `1` oder `2` gesetzt hat. `ESC` beendet das Programm, wenn `bool_Ent_Ver = 3` ist (`ESCEnde` → `Ende` mit `INT 10h` Modus 3 zum Löschen und `INT 21h` Funktion 4Ch zum Beenden), sonst geht es zurück zum Hauptbildschirm.

---

## 5. Mausklick: von Pixel zu Schaltfläche

Der Maustreiber ruft `MausPosiProc` (MAUS.asm) auf und übergibt die Position in `CX` (X) und `DX` (Y). Im Textmodus sind die Koordinaten „virtuelle Pixel“ im Bereich 0..639 und 0..199; **8 Einheiten entsprechen einer Zeichenzelle**.

| Befehl | Rechnung | Warum |
|---|---|---|
| `SHR DX, 3` | Y / 8 = Textzeile | Eine Zeichenzeile = 8 Einheiten |
| `IMUL DX, 160` | Zeile × 160 | Eine Bildschirmzeile = 80 Zeichen × 2 Bytes = 160 Bytes |
| `SHR CX, 2` | X / 4 ≈ Spalte × 2 | Spalte = X / 8; ein Zeichen = 2 Bytes, also X / 8 × 2 = X / 4 |
| `ADD CX, DX` | `CX` = Offset im Videospeicher | Ein einziger Vergleichswert statt zwei Koordinaten |

Die Schaltflächen sind in `config.asm` als Bereiche dieses Offsets angegeben:

| Zeile der Schaltfläche | Entschlüsseln | Verschlüsseln |
|---|---|---|
| obere Rahmenlinie (Zeile 3) | 499 … 535 | 581 … 617 |
| Textzeile (Zeile 4) | 659 … 695 | 741 … 777 |
| untere Rahmenlinie (Zeile 5) | 819 … 855 | 901 … 937 |

### Beispiel: Klick auf „Verschluesseln“

Maus bei X = 444, Y = 36 (Spalte 55, Zeile 4):

- `DX = 36 SHR 3 = 4`, `DX = 4 × 160 = 640`
- `CX = 444 SHR 2 = 111`, `CX = 111 + 640 = 751`

Die Prüfkette (`JNG` = „nicht größer“ = kein Treffer; `JG` = „weiter zur nächsten Gruppe“):

1. `Runde1`: `751 > EntR1_L (499)` → weiter; `751 > EntR1_R (535)` → `JG Runde4`
2. `Runde4`: `751 > VerR1_L (581)` → weiter; `751 > VerR1_R (617)` → `JG Runde2`
3. `Runde2`: `751 > EntR2_L (659)` → weiter; `751 > EntR2_R (695)` → `JG Runde5`
4. `Runde5`: `751 > VerR2_L (741)` → weiter; `751 ≤ VerR2_R (777)` → `JNG PosiVer`

`PosiVer` setzt `bool_Ent_Ver := 2` und `BildschirmVar := 3` und ruft `BildschirmProcX` auf. Diese PROC zeichnet wie `HauptbildschirmProc` (Modus 3, Cursor, `INT 21h`/09h), aber den Text, den `BildschirmVar` auswählt. Die Endlosschleife sieht danach `bool_Ent_Ver = 2` und springt zu `VerschluesselungBeginn`.

*Hinweis zur Maus-PROC:* Der Handler benutzt die Variablen des Datensegments, ohne `DS` selbst zu setzen. Das funktioniert, solange der Treiber `DS` nicht verändert (in der DOS-Box der Fall). Die Spezifikation garantiert das nicht (siehe Abschnitt 13).

---

## 6. Verschlüsseln: Eingabe

`VerschluesselungBeginn:` ruft zuerst `CALL SchluesselInitialisieren` (Voreinstellung: Standardschlüssel) und bindet dann `Ver_Code.asm` ein.

### 6.1 Klartext

| Befehl | Register | Warum |
|---|---|---|
| `MOV AX, 0` / `INT 33h` | Maus zurücksetzen (aus) | Während der Eingabe darf kein Klick den Zustand ändern; setzt auch den Handler zurück (er wird beim Rücksprung in den Hauptbildschirm neu eingetragen). |
| `MOV DI, 1936` | `DI` = Bildschirmoffset der ersten Eingabestelle (Zeile 12, Spalte 8) | |
| `MOV SI, 0` | `SI` = Zähler der eingegebenen Zeichen = Index in `TastaturBuffer` | |
| `XOR AX, AX` / `INT 16h` | BIOS-Tastatur, Fkt. 0: wartet auf eine Taste. `AL` = ASCII-Code, `AH` = Scancode | `XOR AX,AX` ist kürzer als `MOV AX,0` und setzt `AH = 0` (Funktion 0). |
| `CMP AL, ESC_Code` / `JE ReturnVersch` | `1Bh` = ESC → abbrechen | |
| `CMP AL, Entertaste_Code` / `JE …Schluessel` | `0Dh` = Enter → Klartext fertig | |
| `CMP DI, 2062` / `JG …` | Ende des Feldes: 64 Zeichen von `1936` bis `2062` | `(2062 − 1936) / 2 + 1 = 64` |
| `MOV AH, 0Fh` / `MOV WORD PTR ES:[DI], AX` | Zeichen **und** Farbe auf den Bildschirm schreiben | Direkter Videospeicherzugriff, kein `INT 21h` nötig |
| `XOR AH, AH` | `AH := 0` | Damit `AL` später sauber als Byte weiterverwendet wird |
| `MOV TastaturBuffer[SI], AL` / `MOV TastaturBufferOrg[SI], AL` | Zeichen im Zustand und in der Sicherung ablegen | Die Sicherung wird später für die Anzeige gebraucht, weil `TastaturBuffer` in der Rechnung überschrieben wird. |
| `INC SI` / `ADD DI, 2` | nächste Stelle im Puffer / auf dem Bildschirm | Pro Zeichen **ein** Pufferbyte, aber **zwei** Bildschirmbytes |

**Beispiel „Hallo“:**

| Taste | `AL` | Bildschirmwort `AX` | `DI` | `SI` danach | Puffer |
|---|---|---|---|---|---|
| `H` | `48h` | `0F48h` | 1936 | 1 | `[0] = 48h` |
| `a` | `61h` | `0F61h` | 1938 | 2 | `[1] = 61h` |
| `l` | `6Ch` | `0F6Ch` | 1940 | 3 | `[2] = 6Ch` |
| `l` | `6Ch` | `0F6Ch` | 1942 | 4 | `[3] = 6Ch` |
| `o` | `6Fh` | `0F6Fh` | 1944 | 5 | `[4] = 6Fh` |
| Enter | `0Dh` | – | – | 5 | `[5..63] = 00h` (aus der Initialisierung) |

Der Puffer ist damit: `48 61 6C 6C 6F 00 00 00 …` – 5 Textbytes und 59 Nullbytes.

### 6.2 Schlüssel (optional)

Nach dem ersten Enter beginnt die Schlüsseleingabe, in zwei Zeilen zu je 64 Hexziffern (= 32 Bytes), zusammen also 64 Schlüsselbytes. Wer sofort wieder Enter drückt, verwendet den Standardschlüssel.

| Befehl | Warum |
|---|---|
| `MOV DI, 2576` | Bildschirmposition des Schlüsselfeldes, 1. Zeile (Zeile 16, Spalte 8) |
| `MOV SI, 0` | **Schlüsselbyte-Zähler neu beginnen.** (Vor v2.0.0 fehlte das: `SI` zählte weiter vom Text her.) |
| `MOV CL, 0` / `MOV DL, 0` | `CL` = Nibble-Zähler (welche Hexziffer?), `DL` = Zwischenspeicher der 1. Ziffer – beides leer starten |

Jedes Zeichen wird so verarbeitet:

1. Muss ein Zeichen aus `0`…`9` oder `A`…`F` sein (Großbuchstaben). Alles andere wird ignoriert, es erscheint nichts auf dem Bildschirm.
2. `INC CL` – zählt, ob es die 1. oder 2. Ziffer ist.
3. ASCII → Wert: `SUB AL, 7` bei Buchstaben (zwischen `'9'` und `'A'` liegen 7 Zeichen), dann `SUB AL, 48` (`'0' = 48`). So wird `'A'` (65) → 58 → 10, `'F'` (70) → 63 → 15.
4. 1. Ziffer (`CL = 1`): in `DL` merken. 2. Ziffer: `SHL DL, 4` (1. Ziffer an die obere Halbbyte-Position), `ADD AL, DL` (beide zusammensetzen), Ergebnis in `Rundenschluessel_0[SI]`, `INC SI`, `DL := 0`, `CL := 0`.

**Beispiel: Eingabe `5F`**

| Taste | `AL` roh | nach `SUB 7` / `SUB 48` | `CL` | Aktion |
|---|---|---|---|---|
| `5` | `35h` (53) | `05h` | 1 | `DL := 05h` |
| `F` | `46h` (70) | `46h − 7 = 3Fh`, `3Fh − 48 = 0Fh` | 2 | `SHL DL,4` → `50h`; `ADD AL,DL` → `0Fh + 50h = 5Fh`; `Rundenschluessel_0[0] := 5Fh`; `SI = 1` |

Nach der ersten Zeile (`DI > 2702`) springt die Eingabe an `DI = 2736` (Zeile 17) und setzt `CL := 0`. In der zweiten Zeile gilt dieselbe Umrechnung (vor v2.0.0 fehlte dort das `SUB AL, 48`).

Mit Enter (`AufrufenVerAusASM`) geht es weiter. **Erst jetzt** wird `CALL SchluesselInitialisieren` ausgeführt (neu in v2.0.0), damit ein eingegebener Schlüssel auch in `Rundenschluessel_Expand` ankommt.

### 6.3 `SchluesselInitialisieren` (VERS.asm)

| Befehl | Wirkung |
|---|---|
| `MOV AL, Konstante` / `MOV Rundekonstante, AL` | Rundenkonstante auf den Startwert `5Fh` zurück |
| `MOV SI, 0` … `MOV AL, Rundenschluessel_0[SI]` / `MOV Rundenschluessel_Expand[SI], AL` / `INC SI` / `CMP SI, 64` / `JNE` | Kopiert alle 64 Schlüsselbytes von `_0` nach `_Expand` |

---

## 7. Der Verschlüsselungsablauf (Ablauf_V)

`Ablauf_V.asm` ruft die Rechen-PROCs in dieser Reihenfolge auf (der „AES-ähnliche“ Ablauf, 2 Runden):

| # | Aufruf | Zweck |
|---|---|---|
| 1 | `SBOXSubstitution` | Jedes Byte durch die S-Box ersetzen |
| 2 | `Schluesselexpansion` | Rundenschlüssel 1 berechnen (`k1`) |
| 3 | `SchluesselAnwenden` | Zustand XOR `k1` |
| 4 | `ShiftRow` | Zeilen in jedem 4×4-Block verschieben |
| 5 | `SBOXSubstitution` | |
| 6 | `Schluesselexpansion` | Rundenschlüssel 2 (`k2`) |
| 7 | `SchluesselAnwenden` | Zustand XOR `k2` |
| 8 | `ShiftRow` | |
| 9 | `SBOXSubstitution` | |

Eine auskommentierte Variante „nach AES-Standard“ (10 Runden, mit MixColumns) steht darunter; sie ist noch nicht aktiviert (Abschnitt 13).

### 7.1 Der 64-Byte-Zustand als vier 4×4-Blöcke

Der Zustand ist **kein** einzelner AES-Block, sondern vier Blöcke zu je 16 Bytes, die unabhängig voneinander verschoben werden. Jeder Block wird **zeilenweise** gelesen:

```
Block 0 (Pos  0..15)      Block 1 (Pos 16..31)      Block 2 (32..47)    Block 3 (48..63)
 Z0:  0  1  2  3           16 17 18 19                32 33 34 35         48 49 50 51
 Z1:  4  5  6  7           20 21 22 23                36 37 38 39         52 53 54 55
 Z2:  8  9 10 11           24 25 26 27                40 41 42 43         56 57 58 59
 Z3: 12 13 14 15           28 29 30 31                44 45 46 47         60 61 62 63
```

`ShiftRow` rotiert in jedem Block Zeile 1 um 1, Zeile 2 um 2 und Zeile 3 um 3 Stellen nach links. Zeile 0 bleibt. In einer Spalte stehen die Bytes `n`, `n+4`, `n+8`, `n+12` (das braucht `ShiftColumn`).

### 7.2 `SBOXSubstitution` (VERS.asm)

| Befehl | Register | Warum |
|---|---|---|
| `PUSH AX DI SI` | | Aufrufer-Register sichern |
| `MOV SI, 0` | `SI` = laufender Index im Zustand | |
| `XOR AH, AH` | `AH := 0` | `AX` wird gleich als 16-Bit-Index gebraucht, dazu muss die obere Hälfte 0 sein |
| `MOV AL, TastaturBuffer[SI]` | `AL` = aktuelles Byte | |
| `MOV DI, AX` | `DI` = Byte als Tabellenindex | **Nur `BX`, `SI`, `DI`, `BP` dürfen in eckigen Klammern als Index stehen**, nicht `AX`. Deshalb der Umweg über `DI`. |
| `MOV AL, s_0[DI]` | `AL` = Ersatzwert aus der Tabelle | die S-Box ist ein Array mit 256 Einträgen, das Byte selbst ist der Index |
| `MOV TastaturBuffer[SI], AL` | Wert zurückschreiben | |
| `INC SI` / `CMP SI, 64` / `JNE` | alle 64 Bytes | |

Beispiel: `48h` (`'H'`) → `s_0[48h] = 52h`; `61h` → `EFh`; `6Ch` → `50h`; `6Fh` → `A8h`; `00h` → `63h` (alle 59 Nullbytes werden zu `63h`).

Zustand nach Schritt 1: `52 EF 50 50 A8 63 63 63 …`

### 7.3 `Schluesselexpansion` (VERS.asm)

Aus dem Schlüssel `k` wird der nächste Rundenschlüssel `k'` berechnet:

```
k'[0] = k[0]  XOR  S-Box(k[63])  XOR  Rundenkonstante
k'[j] = k'[j-1]  XOR  k[j]                    für j = 1 … 63
```

| Befehl | Register | Warum |
|---|---|---|
| `PUSH AX BX CX DX DI` | | Sichern |
| `MOV AX, @DATA` / `MOV DS, AX` | | Datensegment sicherstellen |
| `MOV DL, Rundekonstante` | `DL` = Rundenkonstante | |
| `MOV AL, Rundenschluessel_Expand[0]` / `XOR AH, AH` | `AL` = `k[0]` | |
| `MOV BL, Rundenschluessel_Expand[63]` / `XOR BH, BH` | `BX` = `k[63]` als 16-Bit-Wert | |
| `MOV DI, BX` | `DI` = `k[63]` als Index | wie oben: Index braucht ein Indexregister |
| `MOV CL, s_0[DI]` | `CL` = S-Box(`k[63]`) | |
| `XOR AL, CL` / `XOR AL, DL` | `AL = k[0] XOR S(k[63]) XOR Konstante` | |
| `MOV Rundenschluessel_Expand[0], AL` | `k'[0]` ablegen | |
| `ROL DL, 1` / `MOV Rundekonstante, DL` | Konstante für die nächste Expansion | `ROL` (Rotation) statt `SHL`, damit kein Bit verloren geht |
| `MOV DI, 1` … Schleife: `AL := Expand[DI-1]` (**schon neu**), `DL := Expand[DI]` (**noch alt**), `XOR AL, DL`, `Expand[DI] := AL`, `INC DI`, `CMP DI, 64` | | Jedes Byte wird mit seinem **neuen** Vorgänger verknüpft. Das macht die Rechnung kumulativ (Präfix-XOR). |

**Beispiel (Standardschlüssel):**

- `k0[0] = 51h`, `k0[63] = 05h` → `S-Box(05h) = 6Bh`, Konstante `5Fh`.
- `k1[0] = 51h XOR 6Bh XOR 5Fh = 65h`
- Konstante danach: `5Fh = 0101 1111b`, `ROL` um 1 → `1011 1110b = BEh`.
- Schleife: `k0[1..7] = DB AD CF 83 9F BD 27`
  - `k1[1] = 65h XOR DBh = BEh`
  - `k1[2] = BEh XOR ADh = 13h`
  - `k1[3] = 13h XOR CFh = DCh`
  - `k1[4] = DCh XOR 83h = 5Fh`
  - `k1[5] = 5Fh XOR 9Fh = C0h`, `k1[6] = C0h XOR BDh = 7Dh`, `k1[7] = 7Dh XOR 27h = 5Ah`
- Ergebnis `k1[0..7] = 65 BE 13 DC 5F C0 7D 5A`, `k1[63] = F1h`.

Zweite Expansion (Schritt 6): `S-Box(F1h) = A1h`, Konstante `BEh` → `k2[0] = 65h XOR A1h XOR BEh = 7Ah`; `k2[1] = 7Ah XOR BEh = C4h`; … `k2[0..7] = 7A C4 D7 0B 54 94 E9 B3`. (Konstante danach `7Dh`.)

### 7.4 `SchluesselAnwenden` (VERS.asm)

`MOV DI, 0` … `MOV AL, TastaturBuffer[DI]` / `MOV BL, Rundenschluessel_Expand[DI]` / `XOR AL, BL` / `MOV TastaturBuffer[DI], AL` / `INC DI` / `CMP DI, 64` / `JNE`.
`BL` ist nur das Byte, das mit `AL` verknüpft wird (zwei Speicheroperanden lässt `XOR` nicht zu, also über ein Register). `AX BX DI` werden gesichert.

Beispiel Schritt 3: `Pos 0: 52h XOR 65h = 37h`, `Pos 1: EFh XOR BEh = 51h`, `Pos 2: 50h XOR 13h = 43h`, `Pos 3: 50h XOR DCh = 8Ch`, `Pos 4: A8h XOR 5Fh = F7h`, `Pos 5: 63h XOR C0h = A3h`, `Pos 6: 63h XOR 7Dh = 1Eh`, `Pos 7: 63h XOR 5Ah = 39h`.
Zustand: `37 51 43 8C F7 A3 1E 39 …`

### 7.5 `ShiftRow` (VERS.asm)

Aufgabe: In jedem Block Zeile 1 um 1, Zeile 2 um 2, Zeile 3 um 3 Stellen nach links rotieren. Dazu wird jede Zeile in `ShiftZwSpeicher` kopiert und an neuer Stelle zurückgeschrieben.

Register in dieser PROC:

| Register | Bedeutung |
|---|---|
| `SI` | Index im Zustand: zeigt beim Kopieren auf die zu lesende Stelle; nach dem Kopieren hinter das Ende der Zeile |
| `BX` | Anfang der gerade bearbeiteten Zeile (`4`, `8`, `12`, danach `20`, `24`, …). `SI − BX` ist damit 0..3, der Index in `ShiftZwSpeicher`. |
| `CX` | Blocknummer (**ab 1**; die Schleife endet bei `CX = 5`, siehe unten) |
| `DI` | Welche Zeile im Block gerade dran ist (0 = „Zeile 1“, 1 = „Zeile 2“, 2 = „Zeile 3“) |
| `AL` | Transportbyte beim Kopieren |
| `ShiftBXZwSpeicher` | `BX + 4` – Wert, bei dem das Kopieren der Zeile endet |

Ablauf pro Zeile:

1. **Kopieren** (`TastaturBufferInit_1`): `AL := TastaturBuffer[SI]`, `SI := SI − BX`, `ShiftZwSpeicher[SI] := AL`, `SI := SI + BX`, `INC SI`; wiederholen bis `SI = BX + 4`.
2. **Zurückschreiben**: je nach `DI` (`CMP DI,1` / `CMP DI,2`) in `Shift_1_Zeile2`, `…Zeile3` oder `…Zeile4`. `SI` zeigt dort auf das erste Byte **hinter** der Zeile, die Zielstellen sind daher `SI-4`, `SI-3`, `SI-2`, `SI-1`.
3. `INC DI`, `ADD BX, 4` → nächste Zeile; nach der dritten Zeile: `ADD SI, 4` (Zeile 0 des nächsten Blocks überspringen), `ADD BX, 8`, und weiter bei `ChangeBlock_1`.

**Beispiel – Block 0, Zeile 1** (Eingabe `Pos 4..7 = F7 A3 1E 39`):

| Schritt | `SI` | `BX` | `CX` | `DI` | Wirkung |
|---|---|---|---|---|---|
| Start | 4 | 4 | – | – | |
| `ChangeBlock_1`: `DI := 0`, `INC CX` | 4 | 4 | 1 | 0 | `CMP CX,5` → weiter |
| Kopieren | 4→8 | 4 | 1 | 0 | `ShiftZwSpeicher = F7 A3 1E 39`, `SI` endet bei 8 (= `BX + 4`) |
| `Shift_1_Zeile2` | 8 | 4 | 1 | 0 | `[SI-1]=[7] := ZW[0] = F7`; `[SI-4]=[4] := ZW[1] = A3`; `[5] := ZW[2] = 1E`; `[6] := ZW[3] = 39` |
| `INC DI`, `ADD BX,4` | 8 | 8 | 1 | 1 | |

Ergebnis Zeile 1: `A3 1E 39 F7` – alles um eine Stelle nach links, `F7` (das `o`!) wandert von `Pos 4` nach `Pos 7`.

Zeile 2 des Blocks (Pos 8..11): zwei Stellen nach links (`8E 71 54 DE` → `54 DE 8E 71`), Zeile 3 (Pos 12..15): drei nach links (`C1 67 D4 45` → `45 C1 67 D4`).

**Warum `CMP CX, 5`?** `CX` wird *vor* dem Vergleich erhöht. Die vier Blöcke laufen also mit `CX = 1, 2, 3, 4`; erst beim fünften Eintritt ist Schluss. Vor v2.0.0 stand dort `CMP CX, 4`, sodass der vierte Block (`Pos 48..63`) nie verschoben wurde.

Zustand nach Schritt 4 (nur Pos 0..7): `37 51 43 8C A3 1E 39 F7`.

### 7.6 Schritte 5 bis 9 (Beispiel Pos 0 und das „o“)

Das `o` begann an `Pos 4`. Der Weg durch die Schritte:

| Schritt | `Pos 0` (`H`) | das `o` |
|---|---|---|
| Klartext | `48h` | `Pos 4`: `6Fh` |
| 1 S-Box | `52h` | `A8h` |
| 3 XOR `k1` | `52 XOR 65 = 37h` | `A8 XOR k1[4]=5F = F7h` |
| 4 ShiftRow | bleibt `Pos 0` = `37h` | wandert nach `Pos 7` = `F7h` |
| 5 S-Box | `S(37h) = 9Ah` | `S(F7h) = 68h` |
| 7 XOR `k2` | `9A XOR k2[0]=7A = E0h` | `68 XOR k2[7]=B3 = DBh` |
| 8 ShiftRow | bleibt `Pos 0` = `E0h` | wandert nach `Pos 6` = `DBh` |
| 9 S-Box | `S(E0h) = E1h` | `S(DBh) = B9h` |

Das **Chiffrat** der ersten Bytes ist `E1 59 BD A8 8E 0F B9 58 …` – das `o` steht jetzt an `Pos 6` (`B9h`).

Vollständiges Chiffrat von `Hallo` (64 Bytes, 128 Hexziffern):

```
E159BDA88E0FB958AA4DF3D15667AD0013BB19720FE93893BD6D3C6F4F5F5F55
6C6F54B35C31772729100D090EA23AA57A1DB20902CD8E80311DA85033765168
```

Die Nullbytes (`Pos 5..63`) werden also **mitverschlüsselt** und erscheinen als scheinbar zufällige Bytes. Das Chiffrat hat deshalb immer 64 Bytes, unabhängig von der Textlänge.

---

## 8. Verschlüsseln: Ausgabe als Hexwerte

`ErgebnisAusgabeVer` (Ver_Code.asm):

1. `MOV BildschirmVar, 4` / `CALL BildschirmProcX` – Ergebnisbildschirm zeichnen.
2. Originaleingabe ausgeben: `SI := 0`, `DI := 1936`, `AL := TastaturBufferOrg[SI]`, `AH := 0Fh`, `MOV ES:[DI], AX`, `INC SI`, `ADD DI, 2` bis `DI = 2064`. (Unbenutzte Stellen enthalten `00h` und erscheinen als Leerzeichen.)
3. Chiffrat ausgeben: Jedes Byte wird als **zwei Hexziffern** ausgegeben, zuerst die obere, dann die untere.

Register: `SI` = Index im Puffer, `DI` = Bildschirmposition (Start `2576`), `CL` = „welche Ziffer ist dran“ (0 = obere, 1 = untere), `DL` = Zwischenspeicher des Bytes.

Ablauf für ein Byte, Beispiel `E1h`:

| Schritt | Befehl | `AL` | Ergebnis |
|---|---|---|---|
| Byte holen | `MOV AL, TastaturBuffer[SI]` | `E1h` | |
| `CL = 0` → obere Ziffer | `MOV DL, AL` | `E1h` | `DL = E1h` gemerkt |
| | `INC CL` (→ 1) | | |
| | `SHR AL, 4` | `0Eh` | obere Halbbyte-Position nach unten geschoben |
| | `CMP AL, 9` / `JG` → `ADD AL, 7` | `15h` | Lücke zwischen `'9'` und `'A'` überbrücken |
| | `ADD AL, 48` | `45h` = `'E'` | Ziffer → ASCII |
| | `MOV AH, 0Fh` / `MOV ES:[DI], AX` / `ADD DI, 2` | | `E` erscheint |
| nächster Durchlauf (`CL = 1`) → untere Ziffer | `MOV AL, DL` | `E1h` | |
| | `SHR DL, 4` / `SHL DL, 4` | `DL = E0h` | untere Halbbyte-Position auf 0 gesetzt |
| | `SUB AL, DL` | `01h` | nur die untere Ziffer bleibt übrig |
| | `CMP AL, 9` / `JNG` → überspringen | | `01h ≤ 9` |
| | `ADD AL, 48` | `31h` = `'1'` | |
| | `MOV ES:[DI], AX`, `INC SI`, `ADD DI, 2`, `CL := 0` | | `1` erscheint |

Ist die untere Ziffer größer als 9 (z. B. `0Eh`), addiert das Programm zuerst 7 (`0Eh + 7 = 15h`) und dann 48 (`15h + 48 = 45h = 'E'`). Die dahinter stehende Vergleichskette mit 72/79/86/93/100 wird nie erreicht (`AL` ist dort höchstens `15h`).

**Zeilenumbruch:** Nach 32 Bytes ist `DI = 2704 > 2700`, das Programm springt in die zweite Zeile (`DI := 2736`, `CL := 0`) und wiederholt dasselbe für die letzten 32 Bytes (bis `DI > 2862`).

Danach `WarteschleifeVer` (wartet auf ESC), `ReturnVersch` (beide Puffer mit `00h` füllen, `MOV AX, 1` / `INT 33h` = Mauszeiger an) und in `AES.asm`: `bool_Ent_Ver := 3`, `JMP HauptbildschirmDarstellen` (Handler neu eintragen, Hauptbildschirm).

---

## 9. Entschlüsseln

### 9.1 Eingabe (Ent_Code.asm)

Es werden **Hexziffern** statt Zeichen eingegeben. Zwei Ziffern ergeben ein Byte; 64 Bytes brauchen 128 Ziffern in zwei Zeilen zu je 64 (`DI = 1936…2062`, dann `2096…2222`).

Beispiel: Ziffernpaar `E` und `1` (aus `E1`):

| Taste | `AL` roh | Befehle | `CL` | Ergebnis |
|---|---|---|---|---|
| `E` | `45h` (69) | `CMP AL,64` `JG` → Buchstabenzweig: Zeichen anzeigen, `SUB AL, 7` | 1 | `AL = 3Eh`; `JE ErstesZeichen…`: `MOV DL, AL` → `DL = 3Eh` |
| `1` | `31h` (49) | Ziffernzweig: Zeichen anzeigen | 2 | `AbInDenTastaturbuffer`: `SHL DL, 4` → `E0h` (das Bit-Muster `3Eh = 0011 1110b`, nach links um 4 geschoben: `1110 0000b`, die `3` fällt heraus); `SHL AL, 4` → `10h`; `SHR AL, 4` → `01h` (untere Ziffer isoliert); `ADD AL, DL` → `E1h` |

`XOR AH, AH` (Farbattribut entfernen), `MOV TastaturBuffer[SI], AL`, `MOV TastaturBufferOrg[SI], AL`, `INC SI`, `MOV CL, 0`. Das Verfahren braucht kein `SUB AL, 48`, weil die Verschiebungen die oberen Bits (die `3` der ASCII-Ziffern) ohnehin abschneiden.

**Zeilenwechsel:** Ist die erste Zeile voll (`DI = 2064`), springt die Ziffernverarbeitung (`DIUmstellen`) auf `DI := 2096` (zweite Zeile).

Die **Schlüsseleingabe** geschieht wie beim Verschlüsseln (Abschnitt 6.2, `MOV SI, 0`, `MOV CL, 0`, `MOV DL, 0`; Anzeigepositionen `2736` und `2896`). Danach `AufrufenEntAusASM:` mit `CALL SchluesselInitialisieren` (neu in v2.0.0).

### 9.2 Der Entschlüsselungsablauf (Ablauf_E)

Die Entschlüsselung läuft **in umgekehrter Reihenfolge** und mit den inversen Schritten:

| # | Aufruf | Zweck |
|---|---|---|
| 1 | `SBOXSubstitution_1` | Inverse S-Box (macht Schritt 9 der Verschlüsselung rückgängig) |
| 2 | `ShiftRow_1` | Zeilen zurück nach rechts (macht Schritt 8 rückgängig) |
| 3 | `Schluesselexpansion` | `k1` berechnen |
| 4 | `Schluesselexpansion` | `k2` berechnen |
| 5 | `SchluesselAnwenden` | Zustand XOR `k2` (macht Schritt 7 rückgängig) |
| 6 | `SBOXSubstitution_1` | macht Schritt 5 rückgängig |
| 7 | `ShiftRow_1` | macht Schritt 4 rückgängig |
| 8 | `SchluesselInitialisieren` | **Schlüssel auf `k0` und Konstante auf `5Fh` zurücksetzen** |
| 9 | `Schluesselexpansion` | `k1` neu berechnen |
| 10 | `SchluesselAnwenden` | Zustand XOR `k1` (macht Schritt 3 rückgängig) |
| 11 | `SBOXSubstitution_1` | macht Schritt 1 rückgängig |

**Warum zweimal `Schluesselexpansion` in Schritt 3 und 4?** Der Schlüssel muss in der Reihenfolge `k2` → `k1` angewendet werden, die Expansion kann aber nur vorwärts (`k0 → k1 → k2`) rechnen. Deshalb rechnet das Programm zuerst zweimal vorwärts bis `k2`, wendet es an und fängt dann mit Schritt 8 von vorn an, um `k1` zu bekommen.
**Warum die Konstante mit zurückgesetzt wird:** Die zweite Expansion benutzt die Rundenkonstante `BEh`, die erste `5Fh`. Würde man nur `Rundenschluessel_Expand` zurückkopieren, würde `k1` mit der falschen Konstante berechnet. `SchluesselInitialisieren` setzt deshalb beides zurück.

### 9.3 Beispiel: Rückrechnung

Eingabe: das Chiffrat von oben. Der Weg der Bytes `Pos 0` und `Pos 6` (das `o`):

| Schritt | `Pos 0` | `Pos 6` |
|---|---|---|
| Chiffrat | `E1h` | `B9h` |
| 1 inverse S-Box | `s_1_0[E1h] = E0h` | `s_1_0[B9h] = DBh` |
| 2 `ShiftRow_1` | bleibt `E0h` | `DBh` wandert von `Pos 6` nach `Pos 7` |
| 5 XOR `k2` | `E0 XOR 7A = 9Ah` | `Pos 7`: `DB XOR k2[7]=B3 = 68h` |
| 6 inverse S-Box | `s_1_0[9Ah] = 37h` | `s_1_0[68h] = F7h` |
| 7 `ShiftRow_1` | bleibt `37h` | `F7h` wandert von `Pos 7` nach `Pos 4` |
| 10 XOR `k1` | `37 XOR 65 = 52h` | `Pos 4`: `F7 XOR 5F = A8h` |
| 11 inverse S-Box | `s_1_0[52h] = 48h` = `'H'` | `s_1_0[A8h] = 6Fh` = `'o'` |

Die Nullbytes kommen als `00h` zurück. Die Ausgabe (`BildschirmVar := 5`) schreibt `TastaturBuffer[0..63]` als Zeichen ab `DI = 1936`; `00h` erscheint als Leerzeichen.

*Voraussetzung:* `s_1_0` muss die exakte Umkehrung von `s_0` sein. Vor v2.0.0 stimmte der Eintrag `s_1_0[70h]` nicht (siehe Abschnitt 12).

---

## 10. MixColumns (ShiftColumn) und Inverse

`ShiftColumn` und `ShiftColumn_1` sind **im aktuellen Ablauf nicht aufgerufen**, aber lauffähig. Sie betreffen die **Spalten** der vier 4×4-Blöcke: Die Bytes `n, n+4, n+8, n+12` (z. B. `Pos 0, 4, 8, 12`) bilden eine Spalte und werden mit einer festen Matrix multipliziert.

### 10.1 Rechnen im Körper GF(2⁸)

- **Addition** ist `XOR`.
- **Multiplikation mit 2** (`MalZweiPROC`): `SHL AL, 1`. War das oberste Bit gesetzt (Carry-Flag nach dem Schieben), dann zusätzlich `XOR AL, 1Bh` (Rest des Polynoms `x⁸+x⁴+x³+x+1`, `11Bh`, ohne das bereits herausgefallene Bit 8).
- **Multiplikation mit 3:** `a × 3 = (a × 2) XOR a`.
- **Beliebige Multiplikation** (`GFMulPROC`, für 9, 0Bh, 0Dh, 0Eh): Schiebe-und-Addiere über die 8 Bits des Multiplikators.

Register in `GFMulPROC` (Eingabe `AL` = a, `DL` = b; Ausgabe `AL` = a·b):

| Register | Rolle |
|---|---|
| `BL` | laufender Faktor a (a, 2a, 4a, …) |
| `BH` | Multiplikator b; pro Schritt um 1 Bit nach rechts geschoben |
| `AL` | Ergebnis (startet bei 0) |
| `CX` | Schleifenzähler (8), mit `LOOP` heruntergezählt |

Je Schritt: `TEST BH,1` / `JZ` (Bit 0 von b gesetzt? dann `XOR AL, BL`); `SHL BL,1` / `JNC` (bei Überlauf `XOR BL, 1Bh`); `SHR BH,1`; `LOOP`.

**Beispiel: `4Dh × 0Bh`** (der zweite Summand der Inversen unten, `AL = 4Dh`, `DL = 0Bh`):

| Schritt | `BH` (b) | Bit 0 | `AL` danach | `BL` (a) vor dem Schieben | `BL` danach | Überlauf |
|---|---|---|---|---|---|---|
| 0 | `0B` | 1 | `4D` | `4D` | `9A` | nein |
| 1 | `05` | 1 | `D7` | `9A` | `2F` | ja (`34h XOR 1Bh`) |
| 2 | `02` | 0 | `D7` | `2F` | `5E` | nein |
| 3 | `01` | 1 | `89` | `5E` | `BC` | nein |
| 4–7 | `00` | 0 | `89` | – | – | – |

Ergebnis `4Dh × 0Bh = 89h`.

### 10.2 `ShiftColumn` (Vorwärts)

Matrix (Zeilen · Spalte):

```
 2 3 1 1       neu[0]  = 2·s0 ^ 3·s1 ^ 1·s2 ^ 1·s3
 1 2 3 1       neu[4]  = 1·s0 ^ 2·s1 ^ 3·s2 ^ 1·s3
 1 1 2 3       neu[8]  = 1·s0 ^ 1·s1 ^ 2·s2 ^ 3·s3
 3 1 1 2       neu[12] = 3·s0 ^ 1·s1 ^ 1·s2 ^ 2·s3
```

(`s0 … s3` = die vier Bytes der Spalte, `^` = XOR.)

**Beispiel – Spalte `DB 13 53 45`** (Standard-Testvektor aus FIPS-197, Anhang B):

- `2 · DBh`: `DBh SHL 1 = B6h` mit Überlauf → `B6h XOR 1Bh = ADh`
- `3 · 13h = (13h·2) XOR 13h = 26h XOR 13h = 35h`
- `neu[0] = ADh XOR 35h XOR 53h XOR 45h = 8Eh`

Die ganze Spalte wird `8E 4D A1 BC`.

### 10.3 `ShiftColumn_1` (Inverse, neu geschrieben in v2.0.0)

Inverse Matrix (`InvMixMatrix` in `config.asm`):

```
 0E 0B 0D 09
 09 0E 0B 0D
 0D 09 0E 0B
 0B 0D 09 0E
```

Register: `BP` = Spaltennummer 0..15 (4 Blöcke × 4 Spalten), `DI` = Index der ersten Zeile der Spalte (`(BP / 4) · 16 + BP mod 4`, über `SHR AX,2` / `SHL AX,4` / `AND DI,3`), `SI` = 4 · Matrixzeile, `BX` = Matrixspalte, `CH` = XOR-Summe, `AL`/`DL` = Faktoren für `GFMulPROC`.

Vorgehen je Spalte: 4 Eingabewerte nach `ShiftColumnZW2` sichern → für jede Matrixzeile die vier Produkte bilden und mit `XOR CH, AL` aufsummieren → Ergebnis an `DI + SI` zurückschreiben. Das Sichern der Eingaben verhindert, dass ein Ergebnis eine Eingabe einer späteren Zeile überschreibt.

**Beispiel – Zeile 1 der Spalte `8E 4D A1 BC`:**

`0E·8E = 15h`, `0B·4D = 89h`, `0D·A1 = 6Ch`, `09·BC = 2Bh`; `15h XOR 89h XOR 6Ch XOR 2Bh = DBh` – das ist wieder das erste Byte der Ausgangsspalte `DB 13 53 45`.

---

## 11. Gesamtübersicht der Abläufe

```
Programmstart (Beginn)
  DS := @DATA;  Maus-Handler eintragen (INT 33h/0Ch);  Hauptbildschirm zeichnen
        |
        v
Endlosschleife  <-----------------------------------------------+
  Taste?  ESC -> Ende (wenn Hauptbildschirm)                     |
  bool_Ent_Ver = 1 -> Entschluesseln     = 2 -> Verschluesseln   |
        |                                       |                |
        v                                       v                |
  Ent_Code                                  Ver_Code             |
   Hexziffern lesen (128)                   Zeichen lesen (<=64) |
   Schluessel lesen (optional)              Schluessel lesen     |
   SchluesselInitialisieren                 SchluesselInitialis. |
   Ablauf_E: 11 Schritte                    Ablauf_V: 9 Schritte |
   Ausgabe Klartext (Zeichen)               Ausgabe Hex (2 Zeil.)|
   ESC -> Puffer leeren, Maus an            ESC -> Puffer leeren |
        |                                       |                |
        +---------------------------------------+----------------+
```

**Ver-/Entschlüsselung im Überblick (je Byteposition):**

```
Klartext -> S-Box -> XOR k1 -> ShiftRow -> S-Box -> XOR k2 -> ShiftRow -> S-Box -> Chiffrat
Chiffrat -> S^-1 -> ShiftRow^-1 -> XOR k2 -> S^-1 -> ShiftRow^-1 -> XOR k1 -> S^-1 -> Klartext
```

---

## 12. Änderungen in v2.0.0

Alle Änderungen sind einzelne Commits mit ausführlicher Begründung (`git log v2.0.0`).

| Bereich | Änderung | Datei(en) |
|---|---|---|
| Inverse S-Box | `s_1_0[70h]` war `0Dh`, richtig ist `0D0h`. Entschlüsseln lieferte dort falsche Zeichen. | `SBOX.asm` |
| ShiftRow | Schleife endete nach 3 statt 4 Blöcken (`CMP CX, 4` → `CMP CX, 5`). Bytes 48..63 wurden nie verschoben. | `VERS.asm`, `ENTS.asm` |
| Schlüsseleingabe | `SI` wurde nicht zurückgesetzt; `SUB AL, 48` fehlte in der 2. Zeile; `CL`/`DL` waren in `Ver_Code` uninitialisiert; `SchluesselInitialisieren` lief zu früh. Eigene Schlüssel funktionieren jetzt. | `Ver_Code.asm`, `Ent_Code.asm` |
| MixColumns | `MalZweiPROC`: signed Vergleich (`JNG`) behoben, Reduktion nach dem Schieben. `GFMulPROC` neu. `ShiftColumn_1` neu geschrieben. `InvMixMatrix` neu. | `VERS.asm`, `ENTS.asm`, `config.asm` |
| Dokumentation | Dieses Dokument. | `Dokumentation/Ablaufplan.md` |

Folge für die Verwendung: Chiffrate, die mit v1 erzeugt wurden, lassen sich mit v2 nicht mehr (vollständig) entschlüsseln, weil sich der Block `Pos 48..63` ändert und die Entschlüsselung die korrigierte S-Box nutzt.

---

## 13. Bekannte Einschränkungen

**Sicherheit.** Das Verfahren ist **AES-ähnlich, nicht AES** und nicht für den Schutz echter Daten geeignet: Es gibt nur 2 Runden, keine MixColumns im aktiven Ablauf und damit **keine Diffusion** – ein Klartextbyte beeinflusst genau ein Chiffrebyte. Das Verfahren ist im Kern eine positionsabhängige Byte-Substitution. Der Standardschlüssel steht im Quelltext, und die Auffüllbytes (`00h`) verraten die Textlänge.

**Nicht aktivierter Standard-Ablauf.** Die auskommentierte 10-Runden-Variante in `Ablauf_V.asm` / `Ablauf_E.asm` ist noch nicht freigeschaltet. Sie braucht über die jetzt verfügbaren `ShiftColumn`-PROCs hinaus Anpassungen (Reihenfolge von Schlüsselanwendung und Runden, Rundenschleife); eine Umstellung ändert das Chiffrat vollständig.

**Eingabe.**
- Kein Backspace; Sondertasten (z. B. Pfeiltasten, `AL = 0`) werden im Klartext als `00h` aufgenommen.
- Bei der Entschlüsselung hat der Buchstabenzweig (`A`…`F`) keine Zeilenumbruch- und keine Längenprüfung. Wer Ziffern und Buchstaben mischt, kann am Zeilenende über den Rahmen schreiben und mit mehr als 128 Ziffern den 65-Byte-`TastaturBuffer` überlaufen lassen.
- Kleinbuchstaben `a`…`f` werden bei Hexeingaben nicht akzeptiert (nur Großbuchstaben).
- `INT 16h` Funktion 1 prüft nur, entnimmt aber keine Taste, und das Zero-Flag wird in der Endlosschleife nicht ausgewertet: Eine Taste, die im Hauptbildschirm gedrückt wird, taucht später als erstes Zeichen der nächsten Eingabe auf.

**Schlüssel.** Ein eingegebener Schlüssel überschreibt `Rundenschluessel_0` bis zum Programmende; der Standardschlüssel wird nicht gesichert. Wer wieder den Standard braucht, muss das Programm neu starten.

**Maus-Handler.** `MausPosiProc` verwendet das Datensegment, ohne `DS` zu setzen. In der DOS-Box funktioniert das; bei anderen Treibern kann `DS` auf das Treibersegment zeigen. Eine robuste Fassung beginnt mit `PUSH DS` / `MOV AX, @DATA` / `MOV DS, AX` und endet mit `POP DS`.

**Kleinere Auffälligkeiten.** Im Schlüsselteil von `Ent_Code.asm` springt ESC nach `ReturnVersch` statt `ReturnEntsch` (beide Labels räumen gleich auf, daher ohne Folgen). `Rundenanzahl` (Wert 10) wird im aktiven Ablauf nicht benutzt. `ISR.asm` ist nur ein Beispiel.

**Stand der Prüfung.** Die Algorithmen (S-Box, Schlüsselexpansion, ShiftRow, MixColumns und Inverse, Roundtrip mit Standard- und eigenem Schlüssel) wurden an einem Python-Nachbau mit der AES-Referenz und untereinander geprüft. Das Übersetzen mit TASM und der Lauf in der DOS-Box (`start.bat`) sind noch von Hand zu bestätigen.
