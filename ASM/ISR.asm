;===========================================================================
; Abschlussprogramm fuer das Modul "Assemblerprogrammierung" bei Prof. Krämer
;       - Jahrgang 19-INB1 - Tim M. Kretzschmar & Konstantin Blechschmidt
;===========================================================================
; Prinzip:
;       - Steht in den Zeilen als Kommentar (Standard Position 31 wenn mgl)
;===========================================================================
; Inhalt:
;         - ISR1Ch      (Label)
;         - EigeneISR   (PROC)
;         - ISR_Zuruecksetzten (PROC)
;===========================================================================

; Eine eigene ISR
ISR1Ch:
        ; Startbereich
        PUSH DS AX BX         ; alle Register die in einer ISR benutzt werden müssen gesichert werden
        MOV AX, @DATA         ; sicherheitshalber nochmal laden
        MOV DS, AX

        ; Nach Absprache muss keine eigene ISR geschrieben werden (hier nur ein Muster also)
        NOP

        ; Endbereich
        POP BX AX DS          ; und am Ende zurückgesichter nicht vergessen!
        IRET                  ; interrupt return, nimmt 3 16 Bit werte vom Stapel und zwar die Flags, IP, CodeSegmentregister


EigeneISR PROC
        ; eigene ISR einstellen und initialisieren
        ; Lesen von Vektortabellen Eintrag, der 2te Parameter ist der Eintrag den wir lesen wollen
        MOV AL, 1Ch
        MOV AH, 35h
        INT 21h               ; in ES:BX ist die alte ISR Adresse
        ; Sichern dieser in oldIOFF & oldISeg
        MOV oldIOFF, BX       ; OFFSET
        MOV oldISeg, ES       ; Segmentadresse
        ; Eintragen neuer ISR
        ; DOS Routine die neue Adresse der ISR in DS:DX übergeben um nicht unser Datensegment zu verlieren:
        PUSH DS               ; sichern DS
        ; unsere ISR steht ihm CodeSegment und die CodeSegment-Adresse steht in CS
        PUSH CS
        POP DS                ; DS <- CS
        MOV DX, OFFSET ISR1Ch ; Adresse in DS:DX
        MOV AL, 1Ch           ; Vektornummer <vn>
        MOV AH, 25h           ; DS:DX = Pointer des INT handler's
        INT 21h               ; DOS INT -> ISR eingetragen
        POP DS                ; Wiederherstellen DS

        RET

ENDP EigeneISR

ISR_Zuruecksetzten PROC

        ; Reset der InterruptRoutine (OFFSET und SEGMENT)
        MOV DX, oldIOFF       ; Reihenfolge wichtig
        MOV AX, oldISeg
        MOV DS, AX
        MOV AL, 1Ch
        MOV AH, 25h
        INT 21h               ; Eintragen der (alten) Vektoren

        RET

ENDP ISR_Zuruecksetzten
