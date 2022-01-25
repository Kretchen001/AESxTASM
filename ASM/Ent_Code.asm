;===========================================================================
; Abschlussprogramm fuer das Modul "Assemblerprogrammierung" bei Prof. Krämer
;       - Jahrgang 19-INB1 - Tim M. Kretzschmar & Konstantin Blechschmidt
;===========================================================================
; Prinzip:
;       Ablauf der Eingabe (mit graphischer Darstellung) in Hexwerten
;       Aufruf der Entschluesselung
;       Ablauf der Ausgabe des Ergebnisses (Klartext)
;===========================================================================
; Inhalt:
;         Code, welcher die Tastaturabfragen fuer die Entschluesselung ueber-
;         nimmt. Dabei wird ebenfalls das Entschluesseln an sich ebenfalls
;         aufgerufen. Dies geschieht in der inkludierten ABLAUF_E.asm (naeheres
;         dazu in der entsprechenden Datei).
;===========================================================================

        ; Maus ausschalten
        MOV AX, 0h
        INT 33h

        MOV DI, 1936          ; Stelle Anfang
        MOV SI, 0             ; IndexCounter fuer den TastaturBuffer

        MOV CL, 0             ; Zaehler

        MOV DL, 0             ; Zwischenspeicher Eingabe (Grund: Unteres Register von DX)

TastaturabfrageEnt:

        MOV AX, video_seg
        MOV ES, AX

; ------------------------Inhalt-----------------------------------------
        XOR AX, AX
        INT 16h
        CMP AL, ESC_Code
        JE ReturnEntsch

        CMP AL, Entertaste_Code
        JE TastaturabfrageEnt2Schluessel

        CMP AL, 'F'           ; hoechstes HEX-Zeichen was eingegeben werden darf
        JG TastaturabfrageEnt

        CMP AL, 47            ; 48 = '0'
        JNG TastaturabfrageEnt

        CMP AL, 57            ; 57 = '9'
        JNG LabelEntText1

        CMP AL, 64            ; 65 = 'A'
        JG BuchstabeDecEntText1

        JMP TastaturabfrageEnt

LabelEntText1:
        CMP DI, 2062
        JNG ZuVerschluesselndeZeichenZeile_Eins
        CMP DI, 2064
        JE DIUmstellen
        CMP DI, 2222
        JNG ZuVerschluesselndeZeichenZweiteZeile ; Maximale Anzahl an Zeichen erreicht? -> Zweite Zeile
        JMP TastaturabfrageEnt

DIUmstellen:
        MOV DI, 2096
        JMP ZuVerschluesselndeZeichenZweiteZeile

BuchstabeDecEntText1:

        CMP AL, 64
        JNG TastaturabfrageEnt

        MOV AH, 0Fh           ; Farbcode für die Ausgabe
        MOV WORD PTR ES:[DI], AX

        SUB AL, 7             ; damit der eingegebene Buchstaben-Wert wirklich ein interner Hexwert wird

        JMP LabelDecEntText

ZuVerschluesselndeZeichenZeile_Eins:
        CMP AL, 64            ; 65 = 'A'
        JG BuchstabeDecEntText1

        ; weder ESC, noch Enter
        MOV AH, 0Fh           ; Farbcode für die Ausgabe
        MOV WORD PTR ES:[DI], AX

LabelDecEntText:
        ADD DI, 2
        INC CL
        CMP CL, 1
        JE ErstesZeichenOderZweitesEntTextZeile1

        JMP AbInDenTastaturbuffer

ZuVerschluesselndeZeichenZweiteZeile:

        MOV AH, 0Fh           ; Farbcode für die Ausgabe
        MOV WORD PTR ES:[DI], AX

        ADD DI, 2
        INC CL
        CMP CL, 1
        JE ErstesZeichenOderZweitesEntTextZeile1  ; 1 entspricht dem ersten Zeichen | 2 dem zweiten

        JMP AbInDenTastaturbuffer

ErstesZeichenOderZweitesEntTextZeile1:

        MOV DL, AL            ; ersten HEXwert abspeichern

        JMP TastaturabfrageEnt

AbInDenTastaturbuffer:

; Erstes Zeichen -> hinterer Wert weg (Eingabebeispiel: 33h ('3'))
        SHL DL, 4             ; z.B. 33h -> 30h
; Zweites Zeichen -> vorderer Wert weg (Eingabebeispiel: 35h ('5'))
        SHL AL, 4             ; z.B. 35h -> 50h
        SHR AL, 4             ; -> 05h

        ADD AL, DL            ; -> 30h + 05h  = 35h (Und somit der Eingabe in Hex)

        ; oberes A Register leeren (steht noch der Farbwert drin)
        XOR AH, AH

        MOV TastaturBuffer[SI], AL
        MOV TastaturBufferOrg[SI], AL ; Speicher der Originaleingabe

        INC SI                ; naechste Stelle im TastaturBuffer

        MOV Cl, 0

        JMP TastaturabfrageEnt

; ------------------------Schluessel-------------------------------------
TastaturabfrageEnt2Schluessel:

        ; bei sofortigem Enter einfach den Standardschluessel nehmen (config.asm)
        ; Jeder eingetragene Wert ueberschreibt also den Eintrag im Standardschluessel.

        MOV DI, 2736

TastaturabfrageEnt2SchluesselDieZweite:

        XOR AX, AX
        INT 16h
        CMP AL, ESC_Code
        JE ReturnVersch

        CMP AL, Entertaste_Code
        JE AufrufenEntAusASM

        CMP AL, 'F'
        JG TastaturabfrageEnt2SchluesselDieZweite

        CMP AL, 47            ; 48 = '0'
        JNG TastaturabfrageEnt2SchluesselDieZweite

        CMP AL, 57            ; 57 = '9'
        JNG Ent_SchluessellaengeNichtErreicht

        CMP AL, 64            ; 65 = 'A'
        JG BuchstabeDecEntSchluessel1

        JMP TastaturabfrageEnt2SchluesselDieZweite

BuchstabeDecEntSchluessel1:
        ; weder ESC, noch Enter
        MOV AH, 0Fh           ; Farbcode für die Ausgabe
        MOV WORD PTR ES:[DI], AX

        SUB AL, 7

        JMP LabelDecEntSchluessel1

Ent_SchluessellaengeNichtErreicht:
        ; weder ESC, noch Enter
        MOV AH, 0Fh           ; Farbcode für die Ausgabe
        MOV WORD PTR ES:[DI], AX

LabelDecEntSchluessel1:
        ADD DI, 2
        INC CL

        SUB AL, 48            ; damit ASCII auf Hex umgerechnet wird

        CMP CL, 1
        JE ZwischenspeichernInDL

        JMP AbInDenRundenschluessel_0

ZwischenspeichernInDL:

        MOV DL, AL

        JMP ZeilenpruefungSchluesseleingabe_Ent

AbInDenRundenschluessel_0:

        ; oberes A Register leeren (steht noch der Farbwert drin)
        XOR AH, AH

        ; Werte verrechnen -> erster Wert *16 + zweiter Wert
        SHL DL, 4                ; *2 , *4 , *8 , *16

        ADD AL, DL            ; Addition mit zweitem Wert

        MOV Rundenschluessel_0[SI], AL

        INC SI

        MOV DL, 0             ; Reset vom Zwischenspeicher DL
        MOV CL, 0             ; Zaehler fuer die Hexwerte reseten (immer 2 fuer einen Eintrag)

ZeilenpruefungSchluesseleingabe_Ent:
        CMP DI, 2862
        JG TastaturabfrageEnt2SchluesselDieDritteVOR ; Maximale Anzahl an Zeichen erreicht?

        JMP TastaturabfrageEnt2SchluesselDieZweite

;----------------------------NaechsteZeile-------------------------------
TastaturabfrageEnt2SchluesselDieDritteVOR:
        MOV DI, 2896
        MOV CL, 0             ; Zaehler fuer die Hexwerte (immer 2 fuer einen Eintrag)

TastaturabfrageEnt2SchluesselDieDritte:

        XOR AX, AX
        INT 16h
        CMP AL, ESC_Code
        JE ReturnEntsch

        CMP AL, Entertaste_Code
        JE AufrufenEntAusASM

        CMP DI, 3022
        JG TastaturabfrageEnt2SchluesselDieDritte ; Maximale Anzahl an Zeichen erreicht?

        CMP AL, 'F'
        JG TastaturabfrageEnt2SchluesselDieDritte

        CMP AL, 47            ; 48 = '0'
        JNG TastaturabfrageEnt2SchluesselDieDritte

        CMP AL, 57            ; 57 = '9'
        JNG SchluessellaengeNichtErreicht2_Ent

        CMP AL, 64            ; 65 = 'A'
        JG BuchstabeDecEntSchluessel2
        JMP TastaturabfrageEnt2SchluesselDieDritte

BuchstabeDecEntSchluessel2:
        ; weder ESC, noch Enter
        MOV AH, 0Fh           ; Farbcode für die Ausgabe
        MOV WORD PTR ES:[DI], AX

        SUB AL, 7

        JMP LabelDecEntSchluessel2

SchluessellaengeNichtErreicht2_Ent:
        ; weder ESC, noch Enter
        MOV AH, 0Fh           ; Farbcode für die Ausgabe
        MOV WORD PTR ES:[DI], AX

LabelDecEntSchluessel2:
        ADD DI, 2
        INC CL

        CMP CL, 1
        JE ZwischenspeichernInDL2

        JMP AbInDenRundenschluessel_0_DieZweite

AbInDenRundenschluessel_0_DieZweite:

        ; oberes A Register leeren (steht noch der Farbwert drin)
        XOR AH, AH

        ; Werte verrechnen -> erster Wert *16 + zweiter Wert
        SHL DL, 4                ; *2 , *4 , *8 , *16

        ADD AL, DL            ; Addition mit zweitem Wert

        MOV Rundenschluessel_0[SI], AL

        INC SI

        MOV DL, 0             ; Reset vom Zwischenspeicher DL
        MOV CL, 0             ; Zaehler fuer die Hexwerte reseten (immer 2 fuer einen Eintrag)


ZwischenspeichernInDL2:

        MOV DL, AL

        JMP TastaturabfrageEnt2SchluesselDieDritte

;--------------------------------RUNDEN-ENTSCHLUESSELUNG-----------------

AufrufenEntAusASM:

        ;_____________________________________________________________________________________________________________________________________
        INCLUDE Ablauf_E.asm

        ; JMP ErgebnisAusgabeEnt -> Auskommentiert, da es eh dorthin laeuft

;--------------------------------AUSGABE---------------------------------

ErgebnisAusgabeEnt:

        MOV BildschirmVar, 5
        CALL BildschirmProcX

        MOV SI, 0
        MOV DI, 1936

; Hexwerte ausgeben
ErgebnisAusgabeVomTastaturBufferEnt:
        MOV AL, TastaturBuffer[SI]
        MOV AH, 0Fh           ; Farbcode für die Ausgabe
        MOV WORD PTR ES:[DI], AX
        INC SI
        ADD DI, 2
        CMP DI, 2064
        JNE ErgebnisAusgabeVomTastaturBufferEnt

;_____________________________________________________________________________________________________

Warteschleife2:
        XOR AX, AX
        INT 16h
        CMP AL, ESC_Code
        JNE Warteschleife2

ReturnEntsch:
        XOR AX, AX
        MOV DI, AX

LeereTastaturBufferEnt:
        MOV TastaturBuffer[DI], AL
        MOV TastaturBufferOrg[DI], AL
        INC DI
        CMP DI, 64
        JNG LeereTastaturBufferEnt

        ; Mauszeiger anschalten
        MOV AX, 1
        INT 33h
