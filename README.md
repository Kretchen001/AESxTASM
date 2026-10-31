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

  Dokumentation/LaTeX/          (Dokumentation zur Version 2.0.0 als LaTeX-Projekt)
                                 Kapitel: Einleitung, Grundlagen, ASM-Dateien, Beispiel "Hallo", Batch-Dateien,
                                 Anleitung, Funktionalitaet, Einschraenkungen, Aenderungen, Entwurf, Tests, Erklaerung
                                 Kompilieren mit pdflatex + biber: siehe Kopf von Dokumentation/LaTeX/main.tex
                                 Die alten PDFs wurden durch dieses Projekt ersetzt.
  Dokumentation/Ablaufplan.md   (Ablaufplan mit Rechenbeispiel: welches Register, wohin, welcher Befehl)
  Dokumentation/Modelltest/     (Python-Nachbau der Rechen-PROCs, prueft sie gegen unabhaengige Referenzen:
                                 python3 Dokumentation/Modelltest/modelltest.py)

--Version 2.0.0--

  Behoben: inverse S-Box (Index 70h), ShiftRow (alle 4 Bloecke), eigene Schluesseleingabe,
  MixColumns (ShiftColumn) und neu geschriebene inverse MixColumns (ShiftColumn_1).
  Der Ablauf (Ablauf_V/Ablauf_E) ist unveraendert 2-rundig ohne MixColumns, also AES-aehnlich
  und NICHT fuer den Schutz echter Daten geeignet. Details: Dokumentation/LaTeX (Kapitel
  "Aenderungen" und "Bekannte Einschraenkungen") bzw. Ablaufplan Abschnitte 12 und 13.

  Stand der Pruefung: Die Logik ist im Python-Modell geprueft. Das Uebersetzen mit TASM und
  der Lauf in der DOS-Box stehen noch aus (Testplan D1-D7 im Kapitel "Tests").
