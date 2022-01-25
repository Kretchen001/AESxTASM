;===========================================================================
; Abschlussprogramm fuer das Modul "Assemblerprogrammierung" bei Prof. Krämer
;       - Jahrgang 19-INB1 - Tim M. Kretzschmar & Konstantin Blechschmidt
;===========================================================================
; Unterprogramm Mausposition abfragen
;===========================================================================
; Prinzip:
;       INT 33h -> Funktion 0Ch <- Fange jeden Mausklick ab
;       Nach dessen Ausfuehrung steht:
;                                     - XPosition -> CX (0..639)
;                                     - YPosition -> DX (0..199)
;       Danach wird Anhand der Blöcke ermittelt, ob der Mausklick eine Aktion
;       ausloesen soll und welche.
;       Dabei gibt es drei Faelle:
;                   1) Es wurde kein Aktionsbereich getroffen
;                       -> Mache nichts, springe sofort zum PosiStimmtNicht-Label
;                   2) Es wurder der Bereich "Entschluesseln" getroffen
;                       -> trage in den bool_Ent_Ver eine "1" ein, schreibe
;                          die initial-Konstante in die Rundenkonstante, schiebe
;                          den Grundschluessel in den Rundenschluessel_Expand
;                          (damit dieser auf keinen Fall leer ist) und rufe
;                          die BildschirmProc2 auf (Entschluesel-Bildschirm)
;                   3) Es wurder der Bereich "Verschluesseln" getroffen
;                       -> trage in den bool_Ent_Ver eine "2" ein, schreibe
;                          die initial-Konstante in die Rundenkonstante, schiebe
;                          den Grundschluessel in den Rundenschluessel_Expand
;                          (damit dieser auf keinen Fall leer ist) und rufe
;                          die BildschirmProc3 auf (Verschluesel-Bildschirm)
;===========================================================================
; Inhalt:
;         - MausPosiProc (PROC)
;===========================================================================

; Rufe je nach gedrueckter Mausposition einen anderen Bildschirm auf und setzte
; die MerkeVariable "bool_Ent_Ver" auf den jeweiligen Wert
MausPosiProc PROC FAR

        ENTER 0, 0

        ; DX enthaelt Zeilen Adresse
        ; MOV y_wert, DX	;y Koordinate in Variable sichern
        SHR DX, 3             ; y Koordinate/8
        IMUL DX, 160          ; DX * 160 -> Koordinate in Zeichenposition umrechnen

        ; CX enthaelt Spalten Adresse
        ; MOV x_wert, CX	;x Koordinate in Variable sichern
        SHR CX, 2             ; x Koordinate/4
        ADD CX, DX            ; Spalten aufaddieren


Runde1:
        ; Vergleiche Reihe 1
        ; Vergleiche ob der Mauszeiger zu weit Links ist
        CMP CX, EntR1_L
        JNG PosiStimmtNicht
        ; Vergleiche ob der Mauszeiger zu weit Rechts ist
        CMP CX, EntR1_R
        JG Runde4
        JNG PosiEnt

Runde2:
        ; Verlgeiche Reihe 2
        ; Vergleiche ob der Mauszeiger zu weit Links ist
        CMP CX, EntR2_L
        JNG PosiStimmtNicht
        ; Vergleiche ob der Mauszeiger zu weit Rechts ist
        CMP CX, EntR2_R
        JG Runde5
        JNG PosiEnt

Runde3:
        ; Vergleiche Reihe 3
        ; Vergleiche ob der Mauszeiger zu weit Links ist
        CMP CX, EntR3_L
        JNG PosiStimmtNicht
        ; Vergleiche ob der Mauszeiger zu weit Rechts ist
        CMP CX, EntR3_R
        JG Runde6
        JNG PosiEnt

Runde4:
        ; Vergleiche Reihe 1
        ; Vergleiche ob der Mauszeiger zu weit Links ist
        CMP CX, VerR1_L
        JNG PosiStimmtNicht
        ; Vergleiche ob der Mauszeiger zu weit Rechts ist
        CMP CX, VerR1_R
        JG Runde2
        JNG PosiVer

Runde5:
        ; Verlgeiche Reihe 2
        ; Vergleiche ob der Mauszeiger zu weit Links ist
        CMP CX, VerR2_L
        JNG PosiStimmtNicht
        ; Vergleiche ob der Mauszeiger zu weit Rechts ist
        CMP CX, VerR2_R
        JG Runde3
        JNG PosiVer

Runde6:
        ; Vergleiche Reihe 3
        ; Vergleiche ob der Mauszeiger zu weit Links ist
        CMP CX, VerR3_L
        JNG PosiStimmtNicht
        ; Vergleiche ob der Mauszeiger zu weit Rechts ist
        CMP CX, VerR3_R
        JG PosiStimmtNicht
        JNG PosiVer

PosiEnt:
        MOV bool_Ent_Ver, 1

        MOV BildschirmVar, 2
        CALL BildschirmProcX

        JMP Endverfahren

PosiVer:
        MOV bool_Ent_Ver, 2

        MOV BildschirmVar, 3
        CALL BildschirmProcX

        JMP Endverfahren

PosiStimmtNicht:

        MOV bool_Ent_Ver, 3

        ;JMP Endverfahren     ; unnoetig, da eh dort hinlaufend

Endverfahren:

        LEAVE                 ; Stackbereich wieder verlassen
        RET

ENDP MausPosiProc
