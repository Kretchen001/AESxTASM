# AES
Abschlussprojekt "Assemblerprogrammierung"

--Starten von AES--

DOS-BOX Eingabe:

  start.bat   (sollte ein Kompilieren vor dem Start gewünscht sein)
  aes.bat     (starte die EXE von AES)

--Alternativ--

--Compilierhinweis--

TASM Syntax -> DOS Box Compilierbefehle:

  tasm AES.asm      [Ist die main Datei]  
  tlink AES.obj  
  AES.exe           [zum Ausführen]

Bitte nur in der DOS Box Umgebung starten!

--Weitere .bat - Dateien--

  tdaes.bat   (assembliert die AES.asm und startet den Turbodebugger)
  asmaes.bat  (assembliert AES - gut um Error und Warnings zu ermitteln)

--Dokumentation--

  Dokumentation/Ablaufplan.md   (Ablaufplan mit Rechenbeispiel: welches Register, wohin, welcher Befehl)
  Dokumentation/*.pdf           (Handbuch, Anleitung, Entwurfsskizze, Tests)

--Version 2.0.0--

  Behoben: inverse S-Box (Index 70h), ShiftRow (alle 4 Bloecke), eigene Schluesseleingabe,
  MixColumns (ShiftColumn) und neu geschriebene inverse MixColumns (ShiftColumn_1).
  Der Ablauf (Ablauf_V/Ablauf_E) ist unveraendert 2-rundig ohne MixColumns; Details und
  bekannte Einschraenkungen stehen im Ablaufplan (Abschnitte 12 und 13).
