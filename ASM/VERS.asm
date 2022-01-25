;===========================================================================
; Abschlussprogramm fuer das Modul "Assemblerprogrammierung" bei Prof. Krämer
;       - Jahrgang 19-INB1 - Tim M. Kretzschmar & Konstantin Blechschmidt
;===========================================================================
; Prinzip: siehe ueber den PROC's
;===========================================================================
; Inhalt:
;         PROC'S
;         - SchluesselInitialisieren
;         - SchluesselAnwenden
;         - Schluesselexpansion
;         - SBOXSubstitution
;         - ShiftRow
;         - ShiftColumn
;         - MalZweiPROC
;===========================================================================


; Verschiebt den gesamten Inhalt von Rundenschluessel_0 nach Rundenschluessel_Expand, damit dieser bei
; nicht erfolgter Schluesseleingabe nicht leer ist
SchluesselInitialisieren PROC FAR

        MOV AL, Konstante
        MOV Rundekonstante, AL  ; Verschiebt die Konstante in die Rundenkonstante

        MOV SI, 0
ForschleifeMaus:
        MOV AL, Rundenschluessel_0[SI]
        MOV Rundenschluessel_Expand[SI], AL
        INC SI
        CMP SI, 64
        JNE ForschleifeMaus

        RET
SchluesselInitialisieren ENDP

; Diese PROC dient zur Anwendung des (Runden)Schluessels auf das 64stellige Array aus der Eingabe
; (zu finden im TastaturBuffer)
SchluesselAnwenden PROC
        PUSH AX BX DI

        MOV DI, 0             ; DI auf 0 damit im TastaturBuffer vorne begonnen wird
RundenschluesselXOR:
        MOV AL, TastaturBuffer[DI]
        MOV BL, Rundenschluessel_Expand[DI]
        XOR AL, BL            ; Herzstueck der PROC -> Verrechnen von Rundenschluessel und Eintrag
        MOV TastaturBuffer[DI], AL
        INC DI
        CMP DI, 64
        JNE RundenschluesselXOR

        POP DI BX AX
        RET
SchluesselAnwenden ENDP

; Berechnet den aktuellen Rundenschluessel mit folgender Fkt.
;       k i+1,j = k i,j XOR subst(k i,63) XOR Konstante [aus der config.asm]  ; fuer den ersten Wert
;       k i,j+1 = k i,j XOR k i,j-1                                           ; fuer die anderen Werte
Schluesselexpansion PROC FAR
        PUSH AX BX CX DX DI

        MOV AX, @DATA
        MOV DS, AX

        ; Vorbereitung
        MOV DL, Rundekonstante ; Rundenkonstante geholt
        MOV AL, Rundenschluessel_Expand[0]
        XOR AH, AH            ; leeren des oberen Registers (->Sicherheitshalber wegen DataSegment)
        MOV BL, Rundenschluessel_Expand[63]
        XOR BH, BH            ; leeren des oberen Registers (-> Sicherheitshalber)
        MOV DI, BX            ; den Wert des 64. Schluessels in DI schieben
        ; Substitution vom letzten Schluesselwert
        MOV CL, s_0[DI]       ; den Wert des 64. Schluessels substituieren

        ; Erstes Rechnen
        XOR AL, CL            ; Erster Wert mit Subst-Wert
        XOR AL, DL            ; Erster ErgWert mit der Konstanten
        MOV Rundenschluessel_Expand[0], AL ; neu berechneter Schluessel in die Stelle 0 zurueckschreiben

        ; Konstanten fuer die Naechste Runde vorbereiten
        ROL DL, 1             ; Rotieren der Rundenkonstante <- Rotieren, damit keine 1 "wegfaellt"
        MOV Rundekonstante, DL ; Alle Bits in Rundekonstante nach Links verschoben/rotiert fuer die naechste Runde
        ; DX ist wieder frei verwendbar

        ; Das ANDERE Rechnen
        MOV DI, 1             ; DI initialisieren, mit 1 weil der zweite Schluessel der erste in der Schleife ist
SchluesselExpansionDurchlaufSchleife:
        MOV AL, Rundenschluessel_Expand[DI-1]
        MOV DL, Rundenschluessel_Expand[DI]
        XOR AL, DL
        MOV Rundenschluessel_Expand[DI], AL
        INC DI                ; erhoeht DI fuer den naechsten Schluessel
        CMP DI, 64            ; 64 ist der letzte Eintrag, hat aber die Indexstelle 63
        JNE SchluesselExpansionDurchlaufSchleife

        POP DI DX CX BX AX
        RET
Schluesselexpansion ENDP

; Substitution mit der S-Box
SBOXSubstitution PROC FAR
        PUSH AX DI SI

        ; Eingabe substituieren mit der SBOX [aus der SBOX.asm]
        MOV SI, 0                 ; Zaehler initialisieren
WiedereinstiegspunktSBOX:
        XOR AH, AH
        MOV AL, TastaturBuffer[SI]  ; ASCII Wert des jeweiligen Zeichens
        MOV DI, AX                  ; verschieben aus AX in DI, weil ein IndexRegister benoetigt wird
        MOV AL, s_0[DI]             ; Schieben den Substitutionswert in AL, welcher durch den ASCII Wert bestimmt wird
        MOV TastaturBuffer[SI], AL  ; Erneuern des Eintrags (vorher ASCII) im TastaturBuffer durch den Substitutionswert
        ; Zaehlererhoehung
        INC SI
        CMP SI, 64
        JNE WiedereinstiegspunktSBOX

        POP SI DI AX
        RET
SBOXSubstitution ENDP

; Datensatz Muster (schon mit Zeilen, eigentlich eine lange Liste)
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
; a04 a05 a06 a07   -\  a05 a06 a07 a04
; a10 a11 a12 a13   -/  a12 a13 a10 a11
; a14 a15 a16 a17       a17 a14 a15 a16

; Fuer die zweiten 16 hier dargestellt
; a20 a21 a22 a23       a20 a21 a22 a23
; a24 a25 a26 a27   -\  a25 a26 a27 a24
; a30 a31 a32 a33   -/  a32 a33 a30 a31
; a34 a35 a36 a37       a37 a34 a35 a36

; Fuer die dritten 16 hier dargestellt
; a40 a41 a42 a43       a40 a41 a42 a43
; a44 a45 a46 a47   -\  a45 a46 a47 a44
; a50 a51 a52 a53   -/  a52 a53 a50 a51
; a54 a55 a56 a57       a57 a54 a55 a56

; Fuer die letzten vier 16 hier dargestellt
; a60 a61 a62 a63       a60 a61 622 a63
; a64 a65 a66 a67   -\  a65 a66 627 a64
; a70 a71 a72 a73   -/  a72 a73 a70 a71
; a74 a75 a76 a77       a77 a74 a75 a76

ShiftRow PROC FAR
        PUSH  AX BX CX DI SI BP

; Block 1 - a00 bis a17

        ; Shift Row Zeile 0 kann entfallen, weil kein SHR (SHR 0)
        ; Stellen 0, 1, 2, 3 (bzw. 1, 2, 3, 4)

        MOV BX, 4             ; Zaeler zum minus rechnen für den Zwischenspeicher
        MOV CX, 0             ; Anzahl der durchgegangenen Bloecke
        MOV SI, 4             ; Index fuer die einzelnen Einträge (analog der Verschluesselung)

ChangeBlock_1:
        MOV DI, 0             ; Zähler für die gerade zu bearbeitende Zeile des Blockes
        INC CX
        CMP CX, 4             ; 4 Bloecke durchgegangen?
        JE EndeShiftRow_1

TastaturBufferInit_1:
        MOV AL, TastaturBuffer[SI] ; Zu verschiebende Stellen zwischenspeichern
        SUB SI, BX            ; Subtrahiere BX von SI, damit die Stellenverschiebung hinhaut
        MOV ShiftZwSpeicher[SI], AL ; ShiftZwSpeicher[SI-BX]
        ADD SI, BX            ; Rueckgaengig machen, damit die Indizierung wieder stimmt

        INC SI
        MOV ShiftBXZwSpeicher, BX
        ADD ShiftBXZwSpeicher, 4
        CMP SI, ShiftBXZwSpeicher
        JNE TastaturBufferInit_1 ; 4 Stellen des TastaturBuffer's gesichert
        CMP DI, 1
        JE Shift_1_Zeile3
        CMP DI, 2
        JE Shift_1_Zeile4

Shift_1_Zeile2:
        MOV AL, ShiftZwSpeicher[0]
        MOV TastaturBuffer[SI-1], AL
        MOV AL, ShiftZwSpeicher[1]
        MOV TastaturBuffer[SI-4], AL
        MOV AL, ShiftZwSpeicher[2]
        MOV TastaturBuffer[SI-3], AL
        MOV AL, ShiftZwSpeicher[3]
        MOV TastaturBuffer[SI-2], AL

        INC DI
        ADD BX, 4
        JMP TastaturBufferInit_1

Shift_1_Zeile3:
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
        JMP TastaturBufferInit_1

Shift_1_Zeile4:
        MOV AL, ShiftZwSpeicher[0]
        MOV TastaturBuffer[SI-3], AL
        MOV AL, ShiftZwSpeicher[1]
        MOV TastaturBuffer[SI-2], AL
        MOV AL, ShiftZwSpeicher[2]
        MOV TastaturBuffer[SI-1], AL
        MOV AL, ShiftZwSpeicher[3]
        MOV TastaturBuffer[SI-4], AL

        ADD SI, 4
        ADD BX, 8
        JMP ChangeBlock_1

EndeShiftRow_1:

        POP BP SI DI CX BX AX
        RET
ShiftRow ENDP


; Mix-Column
; C Matrix            Fallunterscheidung
;  2  3  1  1
;  1  2  3  1         a * 1 = a
;  1  1  2  3         a * 2 = 2*a [bei a<2^7] oder 2*a XOR 283
;  3  1  1  2         a * 3 = (a*2) XOR a

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

ShiftColumn PROC FAR
        PUSH AX BX CX DX DI BP   ; Sicher ist sicher
        MOV AX, 0             ; AX, vor allem AH 0 setzen
        MOV BX, 4             ; vergleichswert für DI
        MOV CX, 0             ; CX = Nummer des Blocks
        MOV DI, 0             ; DI = Stelle im Text

ColumnStart:

; 0  - Zeile 1 in der x-ten Spalte
; Rechnung: 2 3 1 1
        MOV AL, TastaturBuffer[DI] ; fuer das *2
        CALL MalZweiPROC      ; Rechnet AL um, wie es AES verlangt
        MOV ShiftColumnZW, AL ; sichere das Zwischenergebnis

        MOV AL, TastaturBuffer[DI+4] ; fuer das *3
        MOV AH, AL            ; Vorbereitung fuer das XOR sich selbst
        CALL MalZweiPROC
        XOR AL, AH            ; XOR sich selbst
        MOV AH, ShiftColumnZW ; Wiederholen vom des Zwischenergebnisses
        XOR AL, AH            ; AL (Erg *3) XOR AH (Erg *2)

        MOV AH, TastaturBuffer[DI+8] ; holt das erste Element der naechsten (3.) Zeile
        XOR AH, AL            ; AH*1 kann entfallen, somit direkt XOR dem vorherigen Zwischenergebnis

        MOV AL, TastaturBuffer[DI+12]; holt das erste Element der naechsten (4.) Zeile
        XOR AH, AL            ; verrechne den TastaturBuffer[DI+12] mit dem bisherigen Zwischenergebnis

        MOV ShiftColumnZW2[0], AH ; schiebe das Ergebnis der ersten Zeile, Erste Spalte an die entsprechende Stelle


; 4  - Zeile 2 in der x-ten Spalte
; Rechnung: 1 2 3 1
        MOV AH, TastaturBuffer[DI]

        MOV AL, TastaturBuffer[DI+4]
        CALL MalZweiPROC
        XOR AL, AH
        MOV ShiftColumnZW, AL


        MOV AL, TastaturBuffer[DI+8]
        MOV AH, AL
        CALL MalZweiPROC
        XOR AL, AH
        MOV AH, ShiftColumnZW
        XOR AL, AH

        MOV AH, TastaturBuffer[DI+12]
        XOR AL, AH

        MOV ShiftColumnZW2[1], AL


; 8  - Zeile 3 in der x-ten Spalte
; Rechnung: 1 1 2 3
        MOV AH, TastaturBuffer[DI]

        MOV AL, TastaturBuffer[DI+4]
        XOR AH, AL

        MOV AL, TastaturBuffer[DI+8]
        CALL MalZweiPROC
        XOR AL, AH
        MOV ShiftColumnZW, AL

        MOV AL, TastaturBuffer[DI+12]
        MOV AH, AL
        CALL MalZweiPROC
        XOR AL, AH
        MOV AH, ShiftColumnZW
        XOR AL, AH

        MOV ShiftColumnZW2[2], AL

; 12  - Zeile 4 in der x-ten Spalte
; Rechnung: 3 1 1 2
        MOV AL, TastaturBuffer[DI]
        MOV AH, AL
        CALL MalZweiPROC
        XOR AL, AH

        MOV AH, TastaturBuffer[DI+4]
        XOR AL, AH

        MOV AH, TastaturBuffer[DI+8]
        XOR AL, AH

        MOV AH, AL

        MOV AL, TastaturBuffer[DI+12]
        CALL MalZweiPROC
        XOR AL, AH

        MOV ShiftColumnZW2[3], AL

; Ab in den TastaturBuffer
        MOV AL, ShiftColumnZW2[0]
        MOV AH, ShiftColumnZW2[1]
        MOV TastaturBuffer[DI], AL
        MOV TastaturBuffer[DI+4], AH
        MOV AL, ShiftColumnZW2[2]
        MOV AH, ShiftColumnZW2[3]
        MOV TastaturBuffer[DI+8], AL
        MOV TastaturBuffer[DI+12], AH

;Rechnungsende
        INC DI
        CMP DI, BX
        JL ColumnStart

ChangeBlockCloumn:
        INC CX
        ADD DI, 12
        ADD BX, 16
        CMP CX, 4
        JL ColumnStart

EndBereichShiftColumn:
        POP BP DI DX CX BX AX       ; Sicher ist sicher
        RET
ShiftColumn ENDP


; Diese PROC dient einerseits fuer die bessere Lesbarkeit im Code der ShiftColumn und
; ShiftColumn_1 PROC`s, andererseits erleichtert es evtl Aenderungen, sollten Fehler oder
; Anpassungen (wie die XOR 283 z.B.) erforderlich/gewuenscht sein.

; Rueckgabe erfolgt ueber AL
MalZweiPROC PROC
        PUSH BP               ; Sicher ist sicher
        CMP AL, 127           ; Vergleicht den Wert aus dem TastaturBuffer (steht in AL) mit 127
        JNG NichtZuGross      ; falls kleiner, direkt zum *2, sonst
        XOR AX, 283           ; erstmal noch mit 283(dez) XOR verrechnen

NichtZuGross:
        SHL AL, 1             ; *2

EndeMalZweiPROC:
        POP BP                ; Sicher ist sicher
        RET
MalZweiPROC ENDP
