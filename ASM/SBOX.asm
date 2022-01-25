;===========================================================================
; Beinhaltet die SBOX, die zum Austauschen der Werte genutzt wird
;===========================================================================
; Prinzip:
;         Der ASCII Wert des TastaturBuffer zeigt auf die Stelle im Array und
;         ermittelt somit den (substituierten) Wert.
;===========================================================================

;SBOX
; ein s beinhaltet 16 Eintraege
        ; 0..15
s_0 DB 63h, 7Ch, 77h, 7Bh, 0F2h, 6Bh, 6Fh, 0C5h, 30h, 01h, 67h, 2Bh, 0FEh, 0D7h, 0ABh, 76h
        ; 16..31
    DB 0CAh, 82h, 0C9h, 7Dh, 0FAh, 59h, 47h, 0F0h, 0ADh, 0D4h, 0A2h, 0AFh, 9Ch, 0A4h, 72h, 0C0h
        ; 32..47
    DB 0B7h, 0FDh, 93h, 26h, 36h, 3Fh, 0F7h, 0CCh, 34h, 0A5h, 0E5h, 0F1h, 71h, 0D8h, 31h, 15h
        ; 48..63
    DB 04h, 0C7h, 23h, 0C3h, 18h, 96h, 05h, 9Ah, 07h, 12h, 80h, 0E2h, 0EBh, 27h, 0B2h, 75h
        ; 64..79
    DB 09h, 83h, 2Ch, 1Ah, 1Bh, 6Eh, 5Ah, 0A0h, 52h, 3Bh, 0D6h, 0B3h, 29h, 0E3h, 2Fh, 84h
        ; 80..95
    DB 53h, 0D1h, 00h, 0EDh, 20h, 0FCh, 0B1h, 5Bh, 6Ah, 0CBh, 0BEh, 39h, 4Ah, 4Ch, 58h, 0CFh
        ; 96..111
    DB 0D0h, 0EFh, 0AAh, 0FBh, 43h, 4Dh, 33h, 85h, 45h, 0F9h, 02h, 7Fh, 50h, 3Ch, 9Fh, 0A8h
        ; 112..127
    DB 51h, 0A3h, 40h, 8Fh, 92h, 9Dh, 38h, 0F5h, 0BCh, 0B6h, 0DAh, 21h, 10h, 0FFh, 0F3h, 0D2h
        ; 128..143
    DB 0CDh, 0Ch, 13h, 0ECh, 5Fh, 97h, 44h, 17h, 0C4h, 0A7h, 7Eh, 3Dh, 64h, 5Dh, 19h, 73h
        ; 144..159
    DB 60h, 81h, 4Fh, 0DCh, 22h, 2Ah, 90h, 88h, 46h, 0EEh, 0B8h, 14h, 0DEh, 5Eh, 0Bh, 0DBh
        ; 160..175
    DB 0E0h, 32h, 3Ah, 0Ah, 49h, 06h, 24h, 5Ch, 0C2h, 0D3h, 0ACh, 62h, 91h, 95h, 0E4h, 79h
        ; 176..191
    DB 0E7h, 0C8h, 37h, 6Dh, 8Dh, 0D5h, 4Eh, 0A9h, 6Ch, 56h, 0F4h, 0EAh, 65h, 7Ah, 0AEh, 08h
        ; 192..207
    DB 0BAh, 78h, 25h, 2Eh, 1Ch, 0A6h, 0B4h, 0C6h, 0E8h, 0DDh, 74h, 1Fh, 4Bh, 0BDh, 8Bh, 8Ah
        ; 208..223
    DB 70h, 3Eh, 0B5h, 66h, 48h, 03h, 0F6h, 0Eh, 61h, 35h, 57h, 0B9h, 86h, 0C1h, 1Dh, 9Eh
        ; 224..239
    DB 0E1h, 0F8h, 98h, 11h, 69h, 0D9h, 8Eh, 94h, 9Bh, 1Eh, 87h, 0E9h, 0CEh, 55h, 28h, 0DFh
        ; 240..255
    DB 8Ch, 0A1h, 89h, 0Dh, 0BFh, 0E6h, 42h, 68h, 41h, 99h, 2Dh, 0Fh, 0B0h, 54h, 0BBh, 16h


; Invertierete SBOX
        ; 0..15
s_1_0 DB 52h, 09h, 6Ah, 0D5H, 30h, 36h, 0A5h, 38h, 0BFh, 40h, 0A3h, 9Eh, 81h, 0F3h, 0D7h, 0FBh
        ; 16..31
      DB 7Ch, 0E3h, 39h, 82h, 9Bh, 2Fh, 0FFh, 87h, 34h, 8Eh, 43h, 44h, 0C4h, 0DEh, 0E9h, 0CBh
        ; 32..47
      DB 54h, 7Bh, 94h, 32h, 0A6h, 0C2h, 23h, 3Dh, 0EEh, 4Ch, 95h, 0Bh, 42h, 0FAh, 0C3h, 4Eh
        ; 48..63
      DB 08h, 2Eh, 0A1h, 66h, 28h, 0D9h, 24h, 0B2h, 76h, 5Bh, 0A2h, 49h, 6Dh, 8Bh, 0D1h, 25h
        ; 64..79
      DB 72h, 0F8h, 0F6h, 64h, 86h, 68h, 98h, 16h, 0D4h, 0A4h, 5Ch, 0CCh, 5Dh, 65h, 0B6h, 92h
        ; 80..95
      DB 6Ch, 70h, 48h, 50h, 0FDh, 0EDh, 0B9h, 0DAh, 5Eh, 15h, 46h, 57h, 0A7h, 8Dh, 9Dh, 84h
        ; 96..111
      DB 90h, 0D8h, 0ABh, 00h, 8Ch, 0BCh, 0D3h, 0Ah, 0F7h, 0E4h, 58h, 05h, 0B8h, 0B3h, 45h, 06h
        ; 112..127
      DB 0Dh, 2Ch, 1Eh, 8Fh, 0CAh, 3Fh, 0Fh, 02h, 0C1h, 0AFh, 0BDh, 03h, 01h, 13h, 8Ah, 6Bh
        ; 128..143
      DB 3Ah, 91h, 11h, 41h, 4Fh, 67h, 0DCh, 0EAh, 97h, 0F2h, 0CFh, 0CEh, 0F0h, 0B4h, 0E6h, 73h
        ; 144..159
      DB 96h, 0ACh, 74h, 22h, 0E7h, 0ADh, 35h, 85h, 0E2h, 0F9h, 37h, 0E8h, 1Ch, 75h, 0DFh, 6Eh
        ; 160..175
      DB 47h, 0F1h, 1Ah, 71h, 1Dh, 29h, 0C5h, 89h, 6Fh, 0B7h, 62h, 0Eh, 0AAh, 18h, 0BEh, 1Bh
        ; 176..191
      DB 0FCh, 56h, 3Eh, 4Bh, 0C6h, 0D2h, 79h, 20h, 9Ah, 0DBh, 0C0h, 0FEh, 78h, 0CDh, 5Ah, 0F4h
        ; 192..207
      DB 1Fh, 0DDh, 0A8h, 33h, 88h, 07h, 0C7h, 31h, 0B1h, 12h, 10h, 59h, 27h, 80h, 0ECh, 5Fh
        ; 208..223
      DB 60h, 51h, 7Fh, 0A9h, 19h, 0B5h, 4Ah, 0Dh, 2Dh, 0E5h, 7Ah, 9Fh, 93h, 0C9h, 9Ch, 0EFh
        ; 224..239
      DB 0A0h, 0E0h, 3Bh, 4Dh, 0AEh, 2Ah, 0F5h, 0B0h, 0C8h, 0EBh, 0BBh, 3Ch, 83h, 53h, 99h, 61h
        ; 240..255
      DB 17h, 2Bh, 04h, 7Eh, 0BAh, 77h, 0D6h, 26h, 0E1h, 69h, 14h, 63h, 55h, 21h, 0Ch, 7Dh
