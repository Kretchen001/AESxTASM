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
