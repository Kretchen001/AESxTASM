;===========================================================================
; Abschlussprogramm fuer das Modul "Assemblerprogrammierung" bei Prof. Krämer
;       - Jahrgang 19-INB1 - Tim M. Kretzschmar & Konstantin Blechschmidt
;===========================================================================
; Inhalt:
;         In dieser Datei befinden sich alle Variablen, die das Programm fuer
;         seinen Ablauf braucht. (Ausnahme = SBOX -> SBOX.asm)
;         Ebenfalls befinden sich hier Array`s, wie die fuer die Bildschirme
;         z.B. oder dem TastaturBuffer, welcher die Eingabe des Benutzers ab-
;         bzw. zwischenspeichert.
;===========================================================================


; Variablen fuer den Ablauf und soweiter
Rundenanzahl DB 10            ; wir werden 10 Runden AES anwenden
bool_Ent_Ver DB 3             ; 1 - Entschluesseln, 2 - Verschluesseln, 3 - NOP

; Konstanten
ESC_Code = 1Bh                ; Hex-Wert (ASCII) fuer Taste ESC
Entertaste_Code = 0Dh         ; Hex-Wert (ASCII) fuer Taste Enter (LF)
Video_Seg = 0B800h            ; Wichtig fuer den Videomodus3

; Die naechsten Zwei sind nur relevant, fuer die eigenen ISR
oldIOFF DW ?                  ; OFFSET vom alten Interrupt-Vektor
oldISeg DW ?                  ; Segmentadresse vom alten ISR-Vektor

; Startbildschirm
Hauptbildschirm DB ""         ; leere Obere Zeile
        DB " ############################################################################## "
        DB " #                                                                            # "
        DB " #        ------------------                       ------------------         # "
        DB " #        | Entschluesseln |                       | Verschluesseln |         # "
        DB " #        ------------------                       ------------------         # "
        DB " #                                                                            # "
        DB " #                                                                            # "
        DB " #                      ,---,           ,---,.  .--.--.                       # "
        DB " #                     '  .' \        ,'  .' | /  /    '.                     # "
        DB " #                   /  ;    '.    ,---.'   ||  :  /`. /                      # "
        DB " #                  :  :       \   |   |   .';  |  |--`                       # "
        DB " #                  :  |   /\   \  :   :  |-,|  :  ;_                         # "
        DB " #                  |  :  ' ;.   : :   |  ;/| \  \    `.                      # "
        DB " #                  |  |  ;/  \   \|   :   .'  `----.   \                     # "
        DB " #                  '  :  | \  \ ,'|   |  |-,  __ \  \  |                     # "
        DB " #                  |  |  '  '--'  '   :  ;/| /  /`--'  /                     # "
        DB " #                  |  :  :        |   |    \'--'.     /                      # "
        DB " #                  |  | ,'        |   :   .'  `--'---'                       # "
        DB " #                  `--''          |   | ,'                                   # "
        DB " #                                 `----'                                     # "
        DB " #                                                                            # "
        DB " #                                                                            # "
        DB " ##############################################################################$"

Hauptbildschirm3 DB ""          ; leere Obere Zeile
        DB " ############################################################################## "
        DB " #      __      __                _     _ _   _              _                # "
        DB " #      \ \    / /               | |   | (_) (_)            | |               # "
        DB " #       \ \  / /__ _ __ ___  ___| |__ | |_   _ ___ ___  ___| |_ __           # "
        DB " #        \ \/ / _ \ '__/ __|/ __| '_ \| | | | / __/ __|/ _ \ | '_ \          # "
        DB " #         \  /  __/ |  \__ \ (__| | | | | |_| \__ \__ \  __/ | | | |         # "
        DB " #          \/ \___|_|  |___/\___|_| |_|_|\__,_|___/___/\___|_|_| |_|         # "
        DB " #                                                                            # "
        DB " #                                                                            # "
        DB " #   Klartext eingeben:                                                       # "
        DB " #                                                                            # "
        DB " #     |                                                                |     # "
        DB " #                                                                            # "
        DB " #   Schluessel  (hexadezimal)                                                # "
        DB " #                                                                            # "
        DB " #     |                                                                |     # "
        DB " #     |                                                                |     # "
        DB " #                                                                            # "
        DB " #                                                                            # "
        DB " #            Enter betaetigen, sobald der Text vollstaendig ist              # "
        DB " #       Nach der Schluesseleingabe (optional) erneut Enter betaetigen        # "
        DB " #                 Eingabe Klartext nur ueber eine Zeile!!!                   # "
        DB " ##############################################################################$"

Hauptbildschirm2 DB ""          ; leere Obere Zeile
        DB " ############################################################################## "
        DB " #       ______       _            _     _ _   _              _               # "
        DB " #      |  ____|     | |          | |   | (_) (_)            | |              # "
        DB " #      | |__   _ __ | |_ ___  ___| |__ | |_   _ ___ ___  ___| |_ __          # "
        DB " #      |  __| | '_ \| __/ __|/ __| '_ \| | | | / __/ __|/ _ \ | '_ \         # "
        DB " #      | |____| | | | |_\__ \ (__| | | | | |_| \__ \__ \  __/ | | | |        # "
        DB " #      |______|_| |_|\__|___/\___|_| |_|_|\__,_|___/___/\___|_|_| |_|        # "
        DB " #                                                                            # "
        DB " #                                                                            # "
        DB " #   Hexwerte eingeben (nicht durch Leerzeichen trennen):                     # "
        DB " #                                                                            # "
        DB " #     |                                                                |     # "
        DB " #     |                                                                |     # "
        DB " #                                                                            # "
        DB " #   Schluessel  (hexadezimal)                                                # "
        DB " #                                                                            # "
        DB " #     |                                                                |     # "
        DB " #     |                                                                |     # "
        DB " #                                                                            # "
        DB " #          Enter betaetigen, sobald der Text vollstaendig ist                # "
        DB " #       Nach der Schluesseleingabe (optional) erneut Enter betaetigen        # "
        DB " #                                                                            # "
        DB " ##############################################################################$"

Hauptbildschirm4_Ergebnis DB "" ; leere Obere Zeile
        DB " ############################################################################## "
        DB " #      __      __                _     _ _   _              _                # "
        DB " #      \ \    / /               | |   | (_) (_)            | |               # "
        DB " #       \ \  / /__ _ __ ___  ___| |__ | |_   _ ___ ___  ___| |_ __           # "
        DB " #        \ \/ / _ \ '__/ __|/ __| '_ \| | | | / __/ __|/ _ \ | '_ \          # "
        DB " #         \  /  __/ |  \__ \ (__| | | | | |_| \__ \__ \  __/ | | | |         # "
        DB " #          \/ \___|_|  |___/\___|_| |_|_|\__,_|___/___/\___|_|_| |_|         # "
        DB " #                                                                            # "
        DB " #                                                                            # "
        DB " #   Klartext eingegeben:                                                     # "
        DB " #                                                                            # "
        DB " #     |                                                                |     # "
        DB " #                                                                            # "
        DB " #   Ergebnis der Verschluesselung  (hexadezimal)                             # "
        DB " #                                                                            # "
        DB " #     |                                                                |     # "
        DB " #     |                                                                |     # "
        DB " #                                                                            # "
        DB " #                                                                            # "
        DB " #                                                                            # "
        DB " #              ESC betaetigen Bitte, damit eine Rueckkehr zum                # "
        DB " #                         Startbildschrim erfolgt.                           # "
        DB " ##############################################################################$"

Hauptbildschirm5_Ergebnis DB "" ; leere Obere Zeile
        DB " ############################################################################## "
        DB " #       ______       _            _     _ _   _              _               # "
        DB " #      |  ____|     | |          | |   | (_) (_)            | |              # "
        DB " #      | |__   _ __ | |_ ___  ___| |__ | |_   _ ___ ___  ___| |_ __          # "
        DB " #      |  __| | '_ \| __/ __|/ __| '_ \| | | | / __/ __|/ _ \ | '_ \         # "
        DB " #      | |____| | | | |_\__ \ (__| | | | | |_| \__ \__ \  __/ | | | |        # "
        DB " #      |______|_| |_|\__|___/\___|_| |_|_|\__,_|___/___/\___|_|_| |_|        # "
        DB " #                                                                            # "
        DB " #                                                                            # "
        DB " #   Klartext:                                                                # "
        DB " #                                                                            # "
        DB " #     |                                                                |     # "
        DB " #                                                                            # "
        DB " #                                                                            # "
        DB " #                                                                            # "
        DB " #                                                                            # "
        DB " #                                                                            # "
        DB " #                                                                            # "
        DB " #                                                                            # "
        DB " #                                                                            # "
        DB " #               ESC betaetigen Bitte, damit eine Rueckkehr zum               # "
        DB " #                         Startbildschrim erfolgt.                           # "
        DB " ##############################################################################$"

BildschirmVar DB 1            ; Variable fuer die Festlegung, des zu zeichnenden Bildschirms
        ; Muster:
        ;         2 - Entschluesseln Eingabe
        ;         3 - Verschluesseln Eingabe
        ;         4 - Verschluesseln Ergebnisausgabe
        ;         5 - Entschluesseln Ergebnisausgabe

; Hauptbildschirm-Blocknummern fuer das Vergleichen mit dem Mausklick
EntR1_L DW 499                ; obere Zeile linkester Block
EntR1_R DW 535                ; obere Zeile rechtester Block
EntR2_L DW 659                ; mittlere Zeile linkester Block
EntR2_R DW 695                ; mittlere Zeile rechtester Block
EntR3_L DW 819                ; untere Zeile linkester Block
EntR3_R DW 855                ; untere Zeile rechtester Block
VerR1_L DW 581                ; obere Zeile linkester Block
VerR1_R DW 617                ; obere Zeile rechtester Block
VerR2_L DW 741                ; mittlere Zeile linkester Block
VerR2_R DW 777                ; mittlere Zeile rechtester Block
VerR3_L DW 901                ; untere Zeile linkester Block
VerR3_R DW 937                ; untere Zeile rechtester Block

; Tastatureingabe
TastaturBuffer DB 65 DUP(0)   ; speichert die Eingabe der Tastatur in hexwerten nach ASCII Tabelle
TastaturBufferOrg DB 65 DUP(0); sichert den TastaturBuffer fuer die Ausgabe

; Interna fuer die Verschluesselung/Entschluesselung
Konstante DB 01011111b        ; = 5Fh
Rundekonstante DB 1 DUP (0)   ; Zwischenspeicher fuer die Konstanten i+1

; 64 Eingabewerte -> 64 Schluesselwerte von noeten
Rundenschluessel_0  DB 01010001b, 11011011b, 10101101b, 11001111b, 10000011b, 10011111b, 10111101b, 00100111b
                    DB 10110111b, 11111111b, 00100101b, 10001010b, 00011111b, 10100110b, 10110011b, 10010001b
                    DB 11111011b, 10011100b, 01110011b, 11001011b, 00110001b, 11110110b, 01010011b, 01000100b
                    DB 01111111b, 01100010b, 00011001b, 10011110b, 01100011b, 00000001b, 11100010b, 00101000b
                    DB 00110000b, 11010011b, 10100101b, 11101100b, 11011111b, 00010101b, 01000101b, 00111110b
                    DB 11001110b, 10100111b, 11000010b, 01101001b, 11110011b, 10111001b, 11101010b, 00001001b
                    DB 00001010b, 10011011b, 10010011b, 10100011b, 11110010b, 11110111b, 01111011b, 10111011b
                    DB 11001010b, 10001001b, 00010000b, 10011101b, 01001010b, 00100000b, 01011111b, 00000101b

; Hier werden jeweils die Rundenschluessel zwischengespeichert
Rundenschluessel_Expand DB 64 DUP (0)

; Zwischenlager fuer das ShiftRow
ShiftZwSpeicher DB 4 DUP (0)

; Zwischenspeicher für BX Register
ShiftBXZwSpeicher DW 0

; ShiftColumnVariablen
ShiftColumnZW DB 0
ShiftColumnZW2 DB 4 DUP(0)
