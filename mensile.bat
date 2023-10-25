REM INVIO MENSILE PROGETTO VOC (bolletta,switchout,welcomeletter)
@echo off

REM Definizione VARIABILI
set "wget="C:\Program Files (x86)\GnuWin32\bin\wget.exe""
set "blat="C:\VOC\blat\full\blat.exe""
set "recipient=sistemi@evaenergyservice.it"
set "copiaconoscenza=mpascarella@evaenergyservice.it"
%blat% -install mail.evaenergyservice.it no-reply@evaenergyservice.it tuapassword

REM Definizione della cartella di destinazione
set "destination=C:\VOC\download"

REM Ottieni la data odierna nel formato americano (YY-MM-DD)
for /f "tokens=1-3 delims=/" %%a in ('echo %date%') do set "date_orig=%%c%%b%%a"
set date_str=%date_orig%
set data=%date_str:~2%

REM Variabili di controllo dei vari step
set "step1=99"
set "step2=99"

REM URL dei file da scaricare
REM BOLLETTA
REM set "url1=http://localhost:3000/public/question/71833775-044d-49f7-aaa2-e9b48e29e081.csv"
REM set "bolletta=bolletta_%data%.csv"
REM SWITCH OUT
set "url2=http://localhost:3000/public/question/15b86c29-6978-4882-8660-973d6e8dd556.csv"
set "switchout=switchout_%data%.csv"

REM WELCOME LETTER DA ATTIVARE QUANDO VERRà CHIESTO e COMMENTARE IL SET DELLA VARIABILE VUOTA
REM set "url3=http://localhost:3000/public/question/d76d76ff-b202-4466-a035-fd9368fa2efa.csv"
REM set "welcomeletter=welcomeletter_%data%.csv"
set "welcomeletter="

REM Scarica il primo file
REM echo Download del primo file...
REM %wget% -O "%destination%\%bolletta%" "%url1%"
REM Scarica il secondo file
REM echo Download del secondo file...
%wget% -O "%destination%\%switchout%" "%url2%"
REM Scarica il terzo file
REM echo Download del terzo file... ATTIVARE CON WELCOME LETTER
REM %wget% -O "%destination%\%welcomeletter%" "%url3%"

REM Controllo se il file esiste ed e' non vuoto
for %%A in ("%destination%\*.*") do (
    if %%~zA GTR 0 (
        REM echo Il file "%%~nxA" esiste e non e' vuoto.
		set "step1=0"
    ) else (
        REM echo Il file "%%~nxA" esiste ma e' vuoto.
		set "step1=1"
		goto invio_email
		
    )
)
timeout 10
REM CONNESSIONE SFTP
set "winscpPath=C:\Program Files (x86)\WinSCP\WinSCP.exe"   
set "ftpHost=sftp.sandsiv.com"                              
set "ftpUsername=uniongas"                        
set "ftpPassword=zaq12wsx"                        
set "remotePath=/uniongas/InputFiles"
set "logFile=C:\VOC\log.log"
REM set expectedFiles=%bolletta% %switchout% %welcomeletter%
set expectedFiles=%switchout%

REM Esegui WinSCP per la copia dei file
"%winscpPath%" /log="%logFile%" /command ^
	"open sftp://%ftpUsername%:%ftpPassword%@%ftpHost% -hostkey=*" ^
    "lcd %destination%" ^
    "cd %remotePath%" ^
    "put *" ^
    "close" ^
    "exit"

REM Controllo se il file e' stato caricato su ftp
"%winscpPath%" /log="%logFile%" /command ^
    "open sftp://%ftpUsername%:%ftpPassword%@%ftpHost% -hostkey=*" ^
	"cd %remotePath%" ^
    "ls" ^
	"close" ^
    "exit"

for %%f in (%expectedFiles%) do (
    find /i "%%f" "%logFile%" > nul
    if not errorlevel 1 (
        REM echo Il file %%f e' stato trovato nell'elenco dei file.
		set "step2=0"
    ) else (
        REM echo Il file %%f non e' stato trovato nell'elenco dei file.
		set "step2=1"
		goto invio_email
    )
)

:invio_email

REM Set EmailBody="template.html"
rem invio email
if %step1% equ 0 (
	if %step2% equ 0 (
		%blat% -to "%recipient%" -cc %copiaconoscenza% -subject "Upload Mensile SFTP SANDSIV" -html -body "Salve,<br /><br />Il caricamento dei files <b><i>e' avvenuto correttamente</i></b>.<br /><br />I seguenti files sono stati caricati:<br />- %bolletta% <br />- %switchout% <br />- %welcomeletter% <br /><br />Distinti Saluti.<br /><br />team IT Eva Solutions"
	) else (
	%blat% -to "%recipient%" -cc %copiaconoscenza% -subject "Upload Mensile SFTP SANDSIV" -html -body "Salve,<br /><br />Il caricamento dei files <b><i>NON e' avvenuto correttamente</i></b>.<br /><br />PROCEDERE CON IL CARICAMENTO MANUALE.<br /><br />APRI UNA SEGNALAZIONE A sistemi@evaenergyservice.it.<br /><br />Distinti Saluti.<br /><br />team IT Eva Solutions"
	)
) else (
	%blat% -to "%recipient%" -cc %copiaconoscenza% -subject "Upload Mensile SFTP SANDSIV" -html -body "Salve,<br /><br />Il caricamento dei files <b><i>NON e' avvenuto correttamente</i></b>.<br /><br />APRI UNA SEGNALAZIONE A sistemi@evaenergyservice.it.<br /><br />Distinti Saluti.<br /><br />team IT Eva Solutions"
)

del %destination%\*.csv
move "c:\VOC\log.log" "c:\VOC\log\MENSILE-log-%data%.log"

pause