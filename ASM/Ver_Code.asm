;===========================================================================
; Abschlussprogramm fuer das Modul "Assemblerprogrammierung" bei Prof. Krämer
;       - Jahrgang 19-INB1 - Tim M. Kretzschmar & Konstantin Blechschmidt
;===========================================================================
; Inhalt:
;         Code, welcher die Tastaturabfragen fuer die Verschluesselung ueber-
;         nimmt. Dabei wird ebenfalls das Verschluesseln an sich ebenfalls
;         aufgerufen. Dies geschieht in der inkludierten ABLAUF_V.asm (naeheres
;         dazu in der entsprechenden Datei).
;===========================================================================

        ; Maus ausschalten
        MOV AX, 0h
        INT 33h

        MOV DI, 1936          ; Stelle Anfang
        MOV SI, 0             ; IndexCounter fuer den TastaturBuffer

TastaturabfrageVer:

; ------------------------Inhalt-----------------------------------------
        XOR AX, AX
        INT 16h
        CMP AL, ESC_Code
        JE ReturnVersch

        CMP AL, Entertaste_Code
        JE TastaturabfrageVerSchluessel

        CMP DI, 2062
        JG TastaturabfrageVer    ; Maximale Anzahl an Zeichen erreicht?

WenigerAlsZuVerschluesselendeZeichen:
        ; weder ESC, noch Enter
        MOV AH, 0Fh           ; Farbcode für die Ausgabe
        MOV WORD PTR ES:[DI], AX

        ; Leeren des oberen Bereiches von AX (AH)
        XOR AH, AH

        MOV TastaturBuffer[SI], AL
        MOV TastaturBufferOrg[SI], AL ; Speicher der Originaleingabe

        INC SI                ; naechste Stelle im TastaturBuffer
        ADD DI, 2

        JMP TastaturabfrageVer

; ------------------------Schluessel-------------------------------------
TastaturabfrageVerSchluessel:

        ; bei sofortigem Enter einfach den Standardschluessel nehmen (config.asm)
        ; Jeder eingetragene Wert ueberschreibt also den Eintrag im Standardschluessel.

        MOV DI, 2576

TastaturabfrageVerSchluesselDieZweite:

        XOR AX, AX
        INT 16h
        CMP AL, ESC_Code
        JE ReturnVersch

        CMP AL, Entertaste_Code
        JE AufrufenVerAusASM

        CMP AL, 'F'
        JG TastaturabfrageVerSchluesselDieZweite

        CMP AL, 47            ; 48 = '0'
        JNG TastaturabfrageVerSchluesselDieZweite

        CMP AL, 57            ; 57 = '9'
        JNG Ver_SchluessellaengeNichtErreicht

        CMP AL, 64            ; 65 = 'A'
        JG BuchstabeDecVerSchluessel1

        JMP TastaturabfrageVerSchluesselDieZweite

BuchstabeDecVerSchluessel1:
        ; weder ESC, noch Enter
        MOV AH, 0Fh           ; Farbcode für die Ausgabe
        MOV WORD PTR ES:[DI], AX

        SUB AL, 7

        JMP LabelDecVerSchluessel1

Ver_SchluessellaengeNichtErreicht:
        ; weder ESC, noch Enter
        MOV AH, 0Fh           ; Farbcode für die Ausgabe
        MOV WORD PTR ES:[DI], AX

LabelDecVerSchluessel1:
        ADD DI, 2
        INC CL

        SUB AL, 48            ; damit ASCII auf Hex umgerechnet wird

        CMP CL, 1
        JE ZwischenspeichernInDLVer

        JMP AbInDenRundenschluessel_0_Ver

ZwischenspeichernInDLVer:

        MOV DL, AL

        JMP ZeilenpruefungSchluesseleingabe_Ver

AbInDenRundenschluessel_0_Ver:

        ; oberes A Register leeren (steht noch der Farbwert drin)
        XOR AH, AH

        ; Werte verrechnen -> erster Wert *16 + zweiter Wert
        SHL DL, 4                ; *2 , *4 , *8 , *16

        ADD AL, DL            ; Addition mit zweitem Wert

        MOV Rundenschluessel_0[SI], AL

        INC SI

        MOV DL, 0             ; Reset vom Zwischenspeicher DL
        MOV CL, 0             ; Zaehler fuer die Hexwerte reseten (immer 2 fuer einen Eintrag)

ZeilenpruefungSchluesseleingabe_Ver:
        CMP DI, 2702
        JG TastaturabfrageVer2SchluesselDieDritteVOR ; Maximale Anzahl an Zeichen erreicht?

        JMP TastaturabfrageVerSchluesselDieZweite

;----------------------------NaechsteZeile-------------------------------
TastaturabfrageVer2SchluesselDieDritteVOR:
        MOV DI, 2736
        MOV CL, 0             ; Zaehler fuer die Hexwerte (immer 2 fuer einen Eintrag)

TastaturabfrageVer2SchluesselDieDritte:

        XOR AX, AX
        INT 16h
        CMP AL, ESC_Code
        JE ReturnVersch

        CMP AL, Entertaste_Code
        JE AufrufenVerAusASM

        CMP DI, 2862
        JG TastaturabfrageVer2SchluesselDieDritte ; Maximale Anzahl an Zeichen erreicht?

        CMP AL, 'F'
        JG TastaturabfrageVer2SchluesselDieDritte

        CMP AL, 47            ; 48 = '0'
        JNG TastaturabfrageVer2SchluesselDieDritte

        CMP AL, 57            ; 57 = '9'
        JNG SchluessellaengeNichtErreicht2_Ver

        CMP AL, 64            ; 65 = 'A'
        JG BuchstabeDecVerSchluessel2
        JMP TastaturabfrageVer2SchluesselDieDritte

BuchstabeDecVerSchluessel2:
        ; weder ESC, noch Enter
        MOV AH, 0Fh           ; Farbcode für die Ausgabe
        MOV WORD PTR ES:[DI], AX

        SUB AL, 7

        JMP LabelDecVerSchluessel2

SchluessellaengeNichtErreicht2_Ver:
        ; weder ESC, noch Enter
        MOV AH, 0Fh           ; Farbcode für die Ausgabe
        MOV WORD PTR ES:[DI], AX

LabelDecVerSchluessel2:
        ADD DI, 2
        INC CL

        CMP CL, 1
        JE ZwischenspeichernInDL2_Ver

        JMP AbInDenRundenschluessel_0_DieZweite_Ver

AbInDenRundenschluessel_0_DieZweite_Ver:

        ; oberes A Register leeren (steht noch der Farbwert drin)
        XOR AH, AH

        ; Werte verrechnen -> erster Wert *16 + zweiter Wert
        SHL DL, 4                ; *2 , *4 , *8 , *16

        ADD AL, DL            ; Addition mit zweitem Wert

        MOV Rundenschluessel_0[SI], AL

        INC SI

        MOV DL, 0             ; Reset vom Zwischenspeicher DL
        MOV CL, 0             ; Zaehler fuer die Hexwerte reseten (immer 2 fuer einen Eintrag)


ZwischenspeichernInDL2_Ver:

        MOV DL, AL

        JMP TastaturabfrageVer2SchluesselDieDritte


AufrufenVerAusASM:

;--------------------------------RUNDEN-VERSCHLUESSELUNG-----------------

        ;_____________________________________________________________________________________________________________________________________
        INCLUDE ABLAUF_V.asm

        ; JMP ErgebnisAusgabeVer -> Auskommentiert, da es eh dorthin läuft

;--------------------------------AUSGABE---------------------------------

ErgebnisAusgabeVer:

        MOV BildschirmVar, 4
        CALL BildschirmProcX

        XOR AX, AX

        MOV SI, 0
        MOV DI, 1936

        ; Originaleingabe ausgeben
TastaturBufferOrgAusgabe:
        MOV AL, TastaturBufferOrg[SI]
        MOV AH, 0Fh           ; Farbcode für die Ausgabe
        MOV WORD PTR ES:[DI], AX
        INC SI
        ADD DI, 2
        CMP DI, 2064
        JNE TastaturBufferOrgAusgabe

;-----------------------VerschluesselnderText----------------------------
;--------------------------HexWertAusgabe--------------------------------

        MOV CL, 0             ; Zaehler fuer die Ausgabe
        MOV SI, 0
        MOV DI, 2576

;-----------------------------ErsteZeile---------------------------------

        ; Hexwerte ausgeben
ErgebnisAusgabeVomTastaturBuffer:
        MOV AL, TastaturBuffer[SI]

        CMP CL, 0
        JE ErstesZeichenTastaturBufferAusgabeVer

        ;Ausgabe 2. Zeichen fuer den einen Hexwert
        MOV AL, DL

; Vorbereitung

        SHR DL, 4
        SHL DL, 4
        ; In DL steht jetzt das drin, was in der Ersten Printstelle steht der Beiden
        ; Bsp.: DL urspruenglich 43 -> jetzt 40
        SUB AL, DL

        CMP AL, 9
        JNG ZweitesZeichenAusgabeVerZeile1

        ADD AL, 7

        CMP AL, 72
        JNG ZweitesZeichenAusgabeVerZeile1

        SUB AL, 7

        CMP AL, 79
        JNG ZweitesZeichenAusgabeVerZeile1

        SUB AL, 7

        CMP AL, 86
        JNG ZweitesZeichenAusgabeVerZeile1

        CMP AL, 93
        JNG ZweitesZeichenAusgabeVerZeile1

        CMP AL, 100
        JNG ZweitesZeichenAusgabeVerZeile1

        SUB AL, 7

ZweitesZeichenAusgabeVerZeile1:
        ADD AL, 48            ; + '0'

        MOV AH, 0Fh           ; Farbcode für die Ausgabe
        MOV WORD PTR ES:[DI], AX

        INC SI
        ADD DI, 2

        MOV CL, 0

        CMP DI, 2700
        JNG ErgebnisAusgabeVomTastaturBuffer
        JMP ErgebnisAusgabeVomTastaturBuffer2CLNullen ; Ende der Zeile, also ab zur Naechsten

ErstesZeichenTastaturBufferAusgabeVer:

        MOV DL, AL

        INC CL

        SHR AL, 4             ; :16 damit die vorderen 4 Bits in die Hinteren ruecken
        CMP AL, 9             ; vergleiche mit 9
        JG LabelIncBuchstabeVer

        JMP EndgueltigeAusgabeErsterHexWerteVer

LabelIncBuchstabeVer:         ; Sollte eigentlich nie passieren - Beim Ersten Zeichen nie ueber 6* (hex)

        ADD AL, 7             ; damit da ein Buchstabe steht

EndgueltigeAusgabeErsterHexWerteVer:

        ADD AL, 48            ; +'0'

        ; Ausgabe 1. Zeichen fuer den einen Hexwert
        MOV AH, 0Fh           ; Farbcode für die Ausgabe
        MOV WORD PTR ES:[DI], AX
        ADD DI, 2

        ; kein CMP 2702, da es als erstes Zeichen niemals dort sein kann.
        JMP ErgebnisAusgabeVomTastaturBuffer

;----------------------------------ZweiteZeile---------------------------

ErgebnisAusgabeVomTastaturBuffer2CLNullen:

        MOV CL, 0
        MOV DI, 2736

        ; Hexwerte ausgeben
ErgebnisAusgabeVomTastaturBuffer2:
        MOV AL, TastaturBuffer[SI]

        CMP CL, 0
        JE ErstesZeichenTastaturBufferAusgabeVer2

        ;Ausgabe 2. Zeichen fuer den einen Hexwert
        MOV AL, DL

        ; Vorbereitung

        SHR DL, 4
        SHL DL, 4
        ; In DL steht jetzt das drin, was in der Ersten Printstelle steht der Beiden
        ; Bsp.: DL urspruenglich 43 -> jetzt 40
        SUB AL, DL

        CMP AL, 9
        JNG ZweitesZeichenAusgabeVerZeile2

        ADD AL, 7

        CMP AL, 72
        JNG ZweitesZeichenAusgabeVerZeile2

        SUB AL, 7

        CMP AL, 79
        JNG ZweitesZeichenAusgabeVerZeile2

        SUB AL, 7

        CMP AL, 86
        JNG ZweitesZeichenAusgabeVerZeile2

        CMP AL, 93
        JNG ZweitesZeichenAusgabeVerZeile2

        CMP AL, 100
        JNG ZweitesZeichenAusgabeVerZeile2

        SUB AL, 7

ZweitesZeichenAusgabeVerZeile2:
        ADD AL, 48            ; + '0'

        MOV AH, 0Fh           ; Farbcode für die Ausgabe
        MOV WORD PTR ES:[DI], AX

        INC SI
        ADD DI, 2

        MOV CL, 0

        CMP DI, 2862
        JNG ErgebnisAusgabeVomTastaturBuffer2
        JMP WarteschleifeVer  ; Ende der Zeile, also ab zur Naechsten

ErstesZeichenTastaturBufferAusgabeVer2:

        MOV DL, AL

        INC CL

        SHR AL, 4             ; :16 damit die vorderen 4 Bits in die Hinteren ruecken
        CMP AL, 9             ; vergleiche mit 9
        JG LabelIncBuchstabeVer2

        JMP EndgueltigeAusgabeErsterHexWerteVer2

LabelIncBuchstabeVer2:         ; Sollte eigentlich nie passieren - Beim Ersten Zeichen nie ueber 6* (hex)

        ADD AL, 7             ; damit da ein Buchstabe steht

EndgueltigeAusgabeErsterHexWerteVer2:

        ADD AL, 48            ; +'0'

        ; Ausgabe 1. Zeichen fuer den einen Hexwert
        MOV AH, 0Fh           ; Farbcode für die Ausgabe
        MOV WORD PTR ES:[DI], AX
        ADD DI, 2

        ; kein CMP, da es als erstes Zeichen niemals dort sein kann.
        JMP ErgebnisAusgabeVomTastaturBuffer2

;----------------------------------Endbereich----------------------------

WarteschleifeVer:
        XOR AX, AX
        INT 16h
        CMP AL, ESC_Code
        JNE WarteschleifeVer

ReturnVersch:
        XOR AX, AX
        MOV DI, AX

LeereTastaturBufferVer:
        MOV TastaturBuffer[DI], AL
        MOV TastaturBufferOrg[DI], AL
        INC DI
        CMP DI, 64
        JNG LeereTastaturBufferVer

        ; Mauszeiger anschalten
        MOV AX, 1
        INT 33h
