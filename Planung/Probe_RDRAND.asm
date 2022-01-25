        .MODEL SMALL
        ;.486                  ; Prozessortyp
        .STACK 100h
        .DATA

        .CODE

Beginn:

        ; Funktioniert leider nicht mit TASM, da zu alt...
        RDRAND AX

Ende:
        ; zurueck zur DOS
        MOV AH, 4Ch
        INT 21h

END Beginn
