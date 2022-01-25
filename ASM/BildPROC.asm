;===========================================================================
; Abschlussprogramm fuer das Modul "Assemblerprogrammierung" bei Prof. Krämer
;       - Jahrgang 19-INB1 - Tim M. Kretzschmar & Konstantin Blechschmidt
;===========================================================================
; Prinzip:
;         Hier werden die zwei optischen Herzstuecke definiert. Das Zeichnen
;         der Bildschirme laeuft dabei immer nach dem selben Muster ab. So
;         wird als Erstes das Videosegment in ES geladen, dann der Videomodus3
;         eingestellt und dann der Zeichenstart (Block/ Zeile,Spalte) einge-
;         stellt. Nachdem die Curserform definiert wurde, wird in DX der
;         OFFSET des zu zeichnenden Array`s geschoben und mit INT 21h Unter-
;         funktion 09h das Zeichnen ausgefuehrt.
;         Naeheres in den Kommentaren.
;===========================================================================
; Inhalt:
;         - HauptbildschirmProc (PROC)
;         - BildschirmProcX     (PROC)
;===========================================================================

; Diese PROC zeichnet immer den Hauptbildschirm bei Aufruf.
HauptbildschirmProc PROC

        ; Ausgabe des Hauptbildschirm`s
        MOV AX, video_seg
        MOV ES, AX

        ; Videomodus3 aktivieren
        MOV AL, 03h           ; in 80x25 Blöcken
        MOV AH, 00h           ; Videomodus3 -> 640x200 Pixel mit 16 Farben
        INT 10h               ; Zeichenbildschirm einstellen

        MOV AH, 02h
        MOV DL, 00h           ; DH = row , DL = column
        MOV DH, 01h           ; Position 0,1 (DL = x, DH = y)
        MOV BH, 00h           ; BH = page number
        INT 10h               ; Cursor setzen
        MOV AH, 01h           ; Cursorform einstellen
        MOV CX, 2607h         ; CX=2607h heißt unsichtbarer Cursor
        INT 10h

        MOV AH, 09h
        MOV DX, OFFSET Hauptbildschirm ; siehe config.asm
        INT 21h

        ; Mauszeiger an
        MOV AX, 1
        INT 33h

        MOV bool_Ent_Ver, 3   ; Damit das wieder auf dem NOP steht

        RET

ENDP HauptbildschirmProc

; In dieser PROC wird aufgrund des Inhaltes von BildschirmVar entschieden,
; welcher Unterbildschirm zu zeichenen ist.
BildschirmProcX PROC

        MOV AX, video_seg
        MOV ES, AX

        ; Videomodus3 aktivieren
        MOV AL, 03h           ; in 80x25 Blöcken
        MOV AH, 00h           ; Videomodus3 -> 640x200 Pixel mit 16 Farben
        INT 10h               ; Zeichenbildschirm einstellen

        MOV AH, 02h
        MOV DL, 00h           ; DH = row , DL = column
        MOV DH, 01h           ; Position 0,0 (DL = x, DH = y)
        MOV BH, 00h           ; BH = page number
        INT 10h               ; Cursor setzen
        MOV AH, 01h           ; Cursorform einstellen
        MOV CX, 2607h         ; CX=2607h heißt unsichtbarer Cursor
        INT 10h

        CMP BildschirmVar, 2
        JE Hauptbildschirm2Zeichnen

        CMP BildschirmVar, 3
        JE Hauptbildschirm3Zeichnen

        CMP BildschirmVar, 4
        JE Hauptbildschirm4Zeichnen

        CMP BildschirmVar, 5
        JE Hauptbildschirm5Zeichnen

        JMP BildschirmEnde

Hauptbildschirm2Zeichnen:
        MOV AH, 09h
        MOV DX, OFFSET Hauptbildschirm2 ; siehe config.asm
        INT 21h

        JMP BildschirmEnde

Hauptbildschirm3Zeichnen:
        MOV AH, 09h
        MOV DX, OFFSET Hauptbildschirm3 ; siehe config.asm
        INT 21h

        JMP BildschirmEnde

Hauptbildschirm4Zeichnen:
        MOV AH, 09h
        MOV DX, OFFSET Hauptbildschirm4_Ergebnis ; siehe config.asm
        INT 21h

        JMP BildschirmEnde

Hauptbildschirm5Zeichnen:
        MOV AH, 09h
        MOV DX, OFFSET Hauptbildschirm5_Ergebnis ; siehe config.asm
        INT 21h

        ;JMP BildschirmEnde   ; laeuft eh dahin

BildschirmEnde:
        RET

BildschirmProcX ENDP
