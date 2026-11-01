;===========================================================================
; Abschlussprogramm fuer das Modul "Assemblerprogrammierung" bei Prof. Krämer
;       - Jahrgang 19-INB1 - Tim M. Kretzschmar & Konstantin Blechschmidt
;===========================================================================
; Prinzip: siehe ueber den PROC's
;===========================================================================
; Inhalt:
;         - SBOXSubstitution_1 (PROC)
;         - ShiftRow_1         (PROC)
;         - ShiftColumn_1      (PROC)
;===========================================================================


; HEXwert eingeben

;Schluesselexpansion siehe VERS.asm

; Substituiert den TastaturBuffer mit der inversen SBOX (siehe SBOX.asm)
; Substitutionsprinzip -> Kommentare und nicht inverse SBOXSubstitution (siehe VERS.asm)
SBOXSubstitution_1 PROC FAR
        PUSH AX DI SI

        ; Eingabe substituieren mit der invertierten SBOX [aus der SBOX.asm]
        MOV SI, 0                 ; Zaehler initialisieren
WiedereinstiegspunktSBOX_1:
        XOR AH, AH
        MOV AL, TastaturBuffer[SI]  ; ASCII Wert des jeweiligen Zeichens
        MOV DI, AX
        MOV AL, s_1_0[DI]           ; Schieben den Substitutionswert in AX, welcher durch den ASCII Wert bestimmt wird
        MOV TastaturBuffer[SI], AL  ; Erneuern des Eintrags (vorher ASCII) im TastaturBuffer durch den Substitutionswert
        ; Zaehlererhoehung
        INC SI
        CMP SI, 64
        JNE WiedereinstiegspunktSBOX_1

        POP SI DI AX
        RET
SBOXSubstitution_1 ENDP


; Datensatz Muster
; a00 a01 a02 a03 a04 a05 a06 a07
; a10 a11 a12 a13 a14 a15 a16 a17
; a20 a21 a22 a23 a24 a25 a26 a27
; a30 a31 a32 a33 a34 a35 a36 a37
; a40 a41 a42 a43 a44 a45 a46 a47
; a50 a51 a52 a53 a54 a55 a56 a57
; a60 a61 a62 a63 a64 a65 a66 a67
; a70 a71 a72 a73 a74 a75 a76 a77

; Fuer die ersten 16 hier dargestellt
; a00 a01 a02 a03       a00 a01 a02 a03
; a04 a05 a06 a07   -\  a07 a04 a05 a06
; a10 a11 a12 a13   -/  a12 a13 a10 a11
; a14 a15 a16 a17       a15 a16 a17 a14

; Fuer die zweiten 16 hier dargestellt
; a20 a21 a22 a23       a20 a21 a22 a23
; a24 a25 a26 a27   -\  a27 a24 a25 a26
; a30 a31 a32 a33   -/  a32 a33 a30 a31
; a34 a35 a36 a37       a35 a36 a37 a34

; Fuer die dritten 16 hier dargestellt
; a40 a41 a42 a43       a40 a41 a42 a43
; a44 a45 a46 a47   -\  a47 a44 a45 a46
; a50 a51 a52 a53   -/  a52 a53 a50 a51
; a54 a55 a56 a57       a55 a56 a57 a54

; Fuer die letzten vier 16 hier dargestellt
; a60 a61 a62 a63       a60 a61 a62 a63
; a64 a65 a66 a67   -\  a67 a64 a65 a66
; a70 a71 a72 a73   -/  a72 a73 a70 a71
; a74 a75 a76 a77       a75 a76 a77 a74

ShiftRow_1 PROC FAR
        PUSH AX BX CX DI SI BP

; Block 1 - a00 bis a17

        ; Shift Row Zeile 0 kann entfallen, weil kein SHR (SHR 0)
        ; Stellen 0, 1, 2, 3 (bzw. 1, 2, 3, 4)

        MOV BX, 4             ; Zaeler zum minus rechnen für den Zwischenspeicher
        MOV CX, 0             ; Anzahl der durchgegangenen Bloecke
        MOV SI, 4             ; Index fuer die einzelnen Einträge

ChangeBlock:
        MOV DI, 0             ; Zähler für die gerade zu bearbeitende Zeile des Blockes
        INC CX                ; CX zaehlt ab 1 -> der 1. Block wird mit CX = 1 bearbeitet
        CMP CX, 5             ; Erst bei CX = 5 sind alle 4 Bloecke (CX = 1..4) durchgegangen
                              ; (frueher CMP CX, 4 -> nur 3 Bloecke, Bytes 48..63 blieben unverschoben)
        JE EndeShiftRow

TastaturBufferInit:
        MOV AL, TastaturBuffer[SI] ; Zu verschiebende Stellen zwischenspeichern
        SUB SI, BX            ; Subtrahiere BX von SI, damit die Stellenverschiebung hinhaut
        MOV ShiftZwSpeicher[SI], AL ; ShiftZwSpeicher[SI-BX]
        ADD SI, BX            ; Rueckgaengig machen, damit die Indizierung wieder stimmt

        INC SI
        MOV ShiftBXZwSpeicher, BX
        ADD ShiftBXZwSpeicher, 4
        CMP SI, ShiftBXZwSpeicher
        JNE TastaturBufferInit ; 4 Stellen des TastaturBuffer's gesichert
        CMP DI, 1
        JE Shift_Zeile3
        CMP DI, 2
        JE Shift_Zeile4

Shift_Zeile2:
        MOV AL, ShiftZwSpeicher[0]
        MOV TastaturBuffer[SI-3], AL
        MOV AL, ShiftZwSpeicher[1]
        MOV TastaturBuffer[SI-2], AL
        MOV AL, ShiftZwSpeicher[2]
        MOV TastaturBuffer[SI-1], AL
        MOV AL, ShiftZwSpeicher[3]
        MOV TastaturBuffer[SI-4], AL

        INC DI
        ADD BX, 4
        JMP TastaturBufferInit

Shift_Zeile3:
        MOV AL, ShiftZwSpeicher[0]
        MOV TastaturBuffer[SI-2], AL
        MOV AL, ShiftZwSpeicher[1]
        MOV TastaturBuffer[SI-1], AL
        MOV AL, ShiftZwSpeicher[2]
        MOV TastaturBuffer[SI-4], AL
        MOV AL, ShiftZwSpeicher[3]
        MOV TastaturBuffer[SI-3], AL

        INC DI
        ADD BX, 4
        JMP TastaturBufferInit

Shift_Zeile4:
        MOV AL, ShiftZwSpeicher[0]
        MOV TastaturBuffer[SI-1], AL
        MOV AL, ShiftZwSpeicher[1]
        MOV TastaturBuffer[SI-4], AL
        MOV AL, ShiftZwSpeicher[2]
        MOV TastaturBuffer[SI-3], AL
        MOV AL, ShiftZwSpeicher[3]
        MOV TastaturBuffer[SI-2], AL

        ADD SI, 4
        ADD BX, 8
        JMP ChangeBlock

EndeShiftRow:

        POP BP SI DI CX BX AX
        RET
ShiftRow_1 ENDP

; Datensatz Muster
; a00 a01 a02 a03 a04 a05 a06 a07
; a10 a11 a12 a13 a14 a15 a16 a17
; a20 a21 a22 a23 a24 a25 a26 a27
; a30 a31 a32 a33 a34 a35 a36 a37
; a40 a41 a42 a43 a44 a45 a46 a47
; a50 a51 a52 a53 a54 a55 a56 a57
; a60 a61 a62 a63 a64 a65 a66 a67
; a70 a71 a72 a73 a74 a75 a76 a77

; Fuer die ersten 16 hier dargestellt
; a00 a01 a02 a03
; a04 a05 a06 a07
; a10 a11 a12 a13
; a14 a15 a16 a17

; Fuer die zweiten 16 hier dargestellt
; a20 a21 a22 a23
; a24 a25 a26 a27
; a30 a31 a32 a33
; a34 a35 a36 a37

; Fuer die dritten 16 hier dargestellt
; a40 a41 a42 a43
; a44 a45 a46 a47
; a50 a51 a52 a53
; a54 a55 a56 a57

; Fuer die letzten vier 16 hier dargestellt
; a60 a61 a62 a63
; a64 a65 a66 a67
; a70 a71 a72 a73
; a74 a75 a76 a77

; Inverse C-Matrix
; 0Eh 0Bh 0Dh 09h
; 09h 0Eh 0Bh 0Dh
; 0Dh 09h 0Eh 0Bh
; 0Bh 0Dh 09h 0Eh

; Arbeitsweise (pro Spalte, 4 Bloecke * 4 Spalten = 16 Spalten):
;   1. Die 4 Eingabewerte der Spalte (Index DI, DI+4, DI+8, DI+12) werden nach ShiftColumnZW2 gesichert.
;   2. Fuer jede der 4 Zeilen der inversen C-Matrix wird ein Ausgabewert als XOR der 4 Produkte
;      Eingabe[c] * Matrix[Zeile][c] berechnet - die Produkte im Koerper GF(2^8) (GFMulPROC aus VERS.asm).
;   3. Das Ergebnis wird sofort an die Stelle der Zeile zurueckgeschrieben. Weil die Eingaben gesichert sind,
;      kann nichts ueberschrieben werden, was noch gebraucht wird.
; Frueher gescheitert (siehe Entwurfsskizze): MUL ist eine normale Ganzzahl-Multiplikation (kein GF(2^8)),
; die Ergebnisse wurden an SI = 4*Spalte + Zeile (transponiert) geschrieben, und die Zeile-1-Ergebnisse
; ueberschrieben noch benoetigte Eingaben der Zeilen 2..4.
; Register:  BP = Spaltennummer 0..15,  DI = Index der 1. Zeile der Spalte im TastaturBuffer,
;            SI = 4 * Matrixzeile (0,4,8,12; zugleich Zeilenversatz im TastaturBuffer),
;            BX = Matrixspalte 0..3,  CH = XOR-Summe,  AL/DL = Faktoren fuer GFMulPROC
ShiftColumn_1 PROC FAR
        PUSH AX BX CX DX SI DI BP   ; Sicher ist sicher

        MOV BP, 0             ; BP = laufende Spaltennummer ueber alle 4 Bloecke (0..15)

InvSpalteStart:
        ; Index der ersten Zeile dieser Spalte: Blockanfang (BP / 4 * 16) + Spalte im Block (BP mod 4)
        MOV AX, BP
        SHR AX, 2             ; Blocknummer 0..3
        SHL AX, 4             ; * 16 -> Blockanfang im TastaturBuffer
        MOV DI, BP
        AND DI, 3             ; Spalte innerhalb des Blocks
        ADD DI, AX            ; DI = Index von Zeile 1 dieser Spalte

        ; Eingabespalte sichern, damit sie beim Zurueckschreiben nicht ueberschrieben wird
        MOV AL, TastaturBuffer[DI]
        MOV ShiftColumnZW2[0], AL
        MOV AL, TastaturBuffer[DI+4]
        MOV ShiftColumnZW2[1], AL
        MOV AL, TastaturBuffer[DI+8]
        MOV ShiftColumnZW2[2], AL
        MOV AL, TastaturBuffer[DI+12]
        MOV ShiftColumnZW2[3], AL

        MOV SI, 0             ; SI = 4 * Matrixzeile

InvZeileStart:
        MOV BX, 0             ; BX = Matrixspalte
        MOV CH, 0             ; CH = XOR-Summe der vier Produkte

InvProduktStart:
        MOV AL, ShiftColumnZW2[BX]   ; Eingabewert der Matrixspalte BX
        MOV DL, InvMixMatrix[SI+BX]  ; zugehoeriger Faktor 09h/0Bh/0Dh/0Eh (config.asm)
        CALL GFMulPROC        ; AL = AL * DL in GF(2^8)
        XOR CH, AL            ; Produkte aufsummieren (Addition in GF(2^8) = XOR)
        INC BX
        CMP BX, 4
        JL InvProduktStart

        ADD DI, SI            ; Zielindex = Spaltenanfang + 4 * Zeile
        MOV TastaturBuffer[DI], CH
        SUB DI, SI            ; zurueck auf den Spaltenanfang

        ADD SI, 4             ; naechste Matrixzeile
        CMP SI, 16
        JL InvZeileStart

        INC BP                ; naechste Spalte
        CMP BP, 16
        JL InvSpalteStart

EndBereichShiftColumn_1:
        POP BP DI SI DX CX BX AX    ; Sicher ist sicher
        RET
ShiftColumn_1 ENDP
