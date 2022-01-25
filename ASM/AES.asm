;===========================================================================
; Abschlussprogramm fuer das Modul "Assemblerprogrammierung" bei Prof. Krämer
;       - Jahrgang 19-INB1 - Tim M. Kretzschmar & Konstantin Blechschmidt
;===========================================================================
; Prinzip:
;       Dies ist die "main"-Datei, welche die Grundstruktur von AES verwaltet
;       Dabei wird hier vorrangig ueber INCLUDE`s jede Datei eingebunden.
;===========================================================================
; Unterprogramme:
;       - Mausposition bei Primaertastenklick LINKS (in der MAUS.asm)
;       - Verschluesseln (in der Ver_Code.asm, VERS.asm)
;       - Entschluesseln (in der Ent_Code.asm, ENTS.asm)
;       - Bildschirm-Zeichnen-PROC`s (in der BildPROC.asm)
;       - eigene ISR (zur Demonstration; in der ISR.asm)
;===========================================================================
        .MODEL SMALL
        .486                  ; Prozessortyp
        .STACK 100h
        .DATA
INCLUDE SBOX.asm              ; Beinhaltet die zum Ent- und Verschluesseln benoetigte SBOX
INCLUDE config.asm            ; Bildschirme und Variablen fuer die Interna

        .CODE
INCLUDE ISR.asm               ; Beinhaltet den Code fuer die Demonstration der Kenntnis,
                              ; wie man eine ISR anlegt (die jedoch hier keinerlei Verwendung findet)
INCLUDE BildPROC.asm          ; Beinhaltet die 2 PROC`s fuer das Darstellen der einzelnen Bildschirme
INCLUDE MAUS.asm              ; Beinhaltet die Positionsabfrage der Maus beim Klick
INCLUDE VERS.asm              ; Beinhaltet den Code fuers Verschluesseln
INCLUDE ENTS.asm              ; Beinhaltet den Code fuers Entschluesseln

Beginn:
        MOV AX, @DATA         ; Startadresse vom DATA-Segment in AX laden
        MOV DS, AX            ; Startadresse vom DATA-Segment aus AX in DS schieben

        ; Eigene ISR eintragen -> ausgeklammert, da nicht erforderlich
        ;CALL EigeneISR             ; siehe ISR.asm


; Ruft den Hauptbildschirm String auf und schreibt ihn auf den Videomodus3 (80x25 Blöcke)
HauptbildschirmDarstellen:
        ; MausPosiProc herstellen/eintragen
        ; Maustastenklick -> TU WAS
        MOV CX, 00000110b     ; Maustatste Links Freisetzen
        PUSH CS
        POP ES                ; CS steht somit nun in ES
        MOV DX, OFFSET MausPosiProc ; in DX steht der Pointer auf die Label,
                              ; zu welcher beim Mausklick gesprungen werden soll
        MOV AX, 0Ch           ; Fkt 0Ch -> Eigene Maussubroutine und Input Maske einstellen
        INT 33h

        CALL HauptbildschirmProc  ; zeichnet den Haupt/Startbildschirm

; Fragt die Tastatur ab welche Taste gedrueckt wurde
Endlosschleife:
        MOV AH, 01h           ; TastaturINT -> Fkt 1
        INT 16h               ; https://de.wikibooks.org/wiki/Interrupts_80x86/_INT_16
        CMP AL, ESC_Code      ; Vergleiche ASCII Code der gedrueckten Taste mit ESC_Code
        JE ESCEnde            ; Uebereinstimmung -> JMP ESCEnde (Label)

        CMP bool_Ent_Ver, 1
        JE  EntschluesselungBeginn  ; Maus war auf "Entschluesseln"
        CMP bool_Ent_Ver, 2
        JE  VerschluesselungBeginn  ; Maus war auf "Verschluesseln"
        JNE SHORT Endlosschleife ; Nicht korrekt -> Zurueck zur Endlosschleife

VerschluesselungBeginn:

        CALL SchluesselInitialisieren
        INCLUDE Ver_Code.asm
        MOV bool_Ent_Ver, 3   ; Variable zuruecksetzten

        JMP HauptbildschirmDarstellen

EntschluesselungBeginn:

        CALL SchluesselInitialisieren
        INCLUDE Ent_Code.asm
        MOV bool_Ent_Ver, 3   ; Variable zuruecksetzten

        JMP HauptbildschirmDarstellen


; Fragt ab, in welchem Bildschirm und Programmmodus wir uns befinden
ESCEnde:
        CMP bool_Ent_Ver, 3   ; Startbildschirmvergleich
        JE SHORT Ende         ; Übereinstimmung mit "NOP" -> Programm beenden
        JNE HauptbildschirmDarstellen ; Sonst zurueck zum Startbildschirm

Ende:
        ; Bildschirm reset -> Leeren vor dem Schliessen
        MOV AL, 03h
        MOV AH, 00h
        INT 10h

        ; ISR1Ch zuruecksetzen -> wenn nicht auskommentiert spinnt die DOS-Box
        ;CALL ISR_Zuruecksetzten    ; MACRO aus ISR.asm

        ; zurueck zur DOS
        MOV AH, 4Ch
        INT 21h

END Beginn
; Programm-Ende
