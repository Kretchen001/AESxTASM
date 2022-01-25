;===========================================================================
; Abschlussprogramm fuer das Modul "Assemblerprogrammierung" bei Prof. Krämer
;       - Jahrgang 19-INB1 - Tim M. Kretzschmar & Konstantin Blechschmidt
;===========================================================================
; Prinzip: siehe Handbuch Seite 12
;===========================================================================
; Inhalt:
;         - AblaufEntVorrunde (Label)
;         - AblaufEnt         (Label)
;         - AblaufEntEndrunde (Label)
;===========================================================================

        CALL SBOXSubstitution_1

        CALL ShiftRow_1

        CALL Schluesselexpansion
        CALL Schluesselexpansion
        CALL SchluesselAnwenden

        CALL SBOXSubstitution_1

        CALL ShiftRow_1

        CALL SchluesselInitialisieren
        CALL Schluesselexpansion
        CALL SchluesselAnwenden

        CALL SBOXSubstitution_1

;===========================================================================
;                           Nach AES - Standard
;===========================================================================

; ;---------------------------------Vorrunde----------------------------------
; AblaufEntVorrunde:
;         PUSH DI BX AX
;
;         CALL Schluesselexpansion
;         CALL SchluesselAnwenden
;
;         CALL ShiftRow_1
;         CALL SBOXSubstitution_1
;
; ;---------------------------------Hauptrunden-------------------------------
; AblaufEnt:
;         MOV CL, 1             ; Damit laeuft es 9x durch
; RundenENTschluesselnAnzahl:
;         CALL Schluesselexpansion
;         CALL SchluesselAnwenden
;
;         ;CALL ShiftColumn_1
;         CALL ShiftRow_1
;         CALL SBOXSubstitution_1
;
;         INC CL
;         CMP CL, Rundenanzahl
;         JNE RundenENTschluesselnAnzahl
;
; ;--------------------------------Endrunde-----------------------------------
; AblaufEntEndrunde:
;         CALL Schluesselexpansion
;         CALL SchluesselAnwenden
;
;         POP AX BX DI
