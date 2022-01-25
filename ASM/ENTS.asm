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
        INC CX
        CMP CX, 4             ; 4 Bloecke durchgegangen?
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

ShiftColumn_1 PROC FAR
        PUSH SI DI CX BP BX AX      ; Sicher ist sicher
        MOV AX, 0             ; AX, vor allem AH 0 setzen
        MOV BX, 0
        MOV CX, 0             ; CX = Nummer des Blocks
        MOV DI, 0             ; DI = Stelle im Text
        MOV SI, 0

ColumnStart_1:

Zeile1:
        MOV AL, TastaturBuffer[DI]
        MOV DL, 0Eh
        MUL DL
        MOV BL, AL

        MOV AL, TastaturBuffer[DI+4]
        MOV DL, 0Bh
        MUL DL
        XOR BL, AL

        MOV AL, TastaturBuffer[DI+8]
        MOV DL, 0Dh
        MUL DL
        XOR BL, AL

        MOV AL, TastaturBuffer[DI+12]
        MOV DL, 09h
        MUL DL
        XOR BL, AL
        MOV TastaturBuffer[SI], BL

        INC DI
        ADD SI, 4
        CMP DI, 4
        JL Zeile1
        SUB DI, 4
        SUB SI, 16
        INC SI

Zeile2:
        MOV AL, TastaturBuffer[DI]
        MOV DL, 09h
        MUL DL
        MOV BL, AL

        MOV AL, TastaturBuffer[DI+4]
        MOV DL, 0Eh
        MUL DL
        XOR BL, AL

        MOV AL, TastaturBuffer[DI+8]
        MOV DL, 0Bh
        MUL DL
        XOR BL, AL

        MOV AL, TastaturBuffer[DI+12]
        MOV DL, 0Dh
        MUL DL
        XOR BL, AL
        MOV TastaturBuffer[SI], BL

        INC DI
        ADD SI, 4
        CMP DI, 4
        JL Zeile2
        SUB DI, 4
        SUB SI, 16
        INC SI

Zeile3:
        MOV AL, TastaturBuffer[DI]
        MOV DL, 0Dh
        MUL DL
        MOV BL, AL

        MOV AL, TastaturBuffer[DI+4]
        MOV DL, 09h
        MUL DL
        XOR BL, AL

        MOV AL, TastaturBuffer[DI+8]
        MOV DL, 0Eh
        MUL DL
        XOR BL, AL

        MOV AL, TastaturBuffer[DI+12]
        MOV DL, 0Bh
        MUL DL
        XOR BL, AL
        MOV TastaturBuffer[SI], BL

        INC DI
        ADD SI, 4
        CMP DI, 4
        JL Zeile3
        SUB DI, 4
        SUB SI, 16
        INC SI


Zeile4:
        MOV AL, TastaturBuffer[DI]
        MOV DL, 0Bh
        MUL DL
        MOV BL, AL

        MOV AL, TastaturBuffer[DI+4]
        MOV DL, 0Dh
        MUL DL
        XOR BL, AL

        MOV AL, TastaturBuffer[DI+8]
        MOV DL, 09h
        MUL DL
        XOR BL, AL

        MOV AL, TastaturBuffer[DI+12]
        MOV DL, 0Eh
        MUL DL
        XOR BL, AL
        MOV TastaturBuffer[SI], BL

        INC DI
        ADD SI, 4
        CMP DI, 4
        JL Zeile4
        SUB DI, 4
        SUB SI, 16
        INC SI

        ADD DI, 16
        ADD SI, 12
        INC CX
        CMP CX, 4
        JL ColumnStart_1

EndBereichShiftColumn_1:
        POP AX BX BP CX DI SI      ; Sicher ist sicher
        RET
ShiftColumn_1 ENDP
