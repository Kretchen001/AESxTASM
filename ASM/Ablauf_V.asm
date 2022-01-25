;===========================================================================
; Abschlussprogramm fuer das Modul "Assemblerprogrammierung" bei Prof. Krämer
;       - Jahrgang 19-INB1 - Tim M. Kretzschmar & Konstantin Blechschmidt
;===========================================================================
; Prinzip: siehe Handbuch Seite 10
;===========================================================================
; Inhalt:
;         - AblaufVerVorrunde (Label)
;         - AblaufVer         (Label)
;         - AblaufVerEndrunde (Label)
;===========================================================================

        CALL SBOXSubstitution

        CALL Schluesselexpansion
        CALL SchluesselAnwenden

        CALL ShiftRow

        CALL SBOXSubstitution

        CALL Schluesselexpansion
        CALL SchluesselAnwenden

        CALL ShiftRow

        CALL SBOXSubstitution

;===========================================================================
;                           Nach AES - Standard
;===========================================================================

; ;---------------------------------Vorrunde----------------------------------
; AblaufVerVorrunde:
;         PUSH DI BX AX
;
;         CALL Schluesselexpansion
;         CALL SchluesselAnwenden
;
; ;---------------------------------Hauptrunden-------------------------------
; AblaufVer:
;         MOV CL, 1             ; Damit laeuft es 9x durch
; RundenVERschluesselnAnzahl:
;         CALL SBOXSubstitution
;         CALL ShiftRow
;         ;CALL ShiftColumn
;
;         CALL Schluesselexpansion
;         CALL SchluesselAnwenden
;
;         INC CL
;         CMP CL, Rundenanzahl  ; Rundenanzahl = 10 (standard) -> 9 Durchlaeufe
;         JNE RundenVERschluesselnAnzahl
;
; ;--------------------------------Endrunde-----------------------------------
; AblaufVerEndrunde:
;         CALL SBOXSubstitution
;         CALL ShiftRow
;
;         CALL Schluesselexpansion
;         CALL SchluesselAnwenden
;
;         POP AX BX DI
