REM INVIO SETTIMANALE PROGETTO VOC (subentro,switchin,voltura)
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
REM SUBENTRO
set "url1=http://localhost:3000/public/question/7558cc06-1259-4d9b-a7ba-a72b177c9815.csv"
set "subentro=subentro_%data%.csv"
REM SWITCH IN
set "url2=http://localhost:3000/public/question/a6ca2a7d-39a9-4f4d-922a-721f9f1cb482.csv"
set "switchin=switchin_%data%.csv"
REM VOLTURA
set "url3=http://localhost:3000/public/question/eaeaaa09-99a0-467d-8feb-e4efbab0d76a.csv"
set "voltura=voltura_%data%.csv"

REM Scarica il primo file
REM echo Download del primo file...
%wget% -O "%destination%\%subentro%" "%url1%"
REM Scarica il secondo file
REM echo Download del secondo file...
%wget% -O "%destination%\%switchin%" "%url2%"
REM Scarica il terzo file
REM echo Download del terzo file...
%wget% -O "%destination%\%voltura%" "%url3%"

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
set expectedFiles=%subentro% %switchin% %voltura%

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
		%blat% -to "%recipient%" -cc %copiaconoscenza% -subject "Upload Settimanale SFTP SANDSIV" -html -body "Salve,<br /><br />Il caricamento dei files <b><i>e' avvenuto correttamente</i></b>.<br /><br />I seguenti files sono stati caricati:<br />- %subentro% <br />- %voltura% <br />- %switchin% <br /><br />Distinti Saluti.<br /><br />team IT Eva Solutions"
	) else (
	%blat% -to "%recipient%" -cc %copiaconoscenza% -subject "Upload Settimanale SFTP SANDSIV" -html -body "Salve,<br /><br />Il caricamento dei files <b><i>NON e' avvenuto correttamente</i></b>.<br /><br />PROCEDERE CON IL CARICAMENTO MANUALE.<br /><br />APRI UNA SEGNALAZIONE A sistemi@evaenergyservice.it.<br /><br />Distinti Saluti.<br /><br />team IT Eva Solutions"
	)
) else (
	%blat% -to "%recipient%" -cc %copiaconoscenza% -subject "Upload Settimanale SFTP SANDSIV" -html -body "Salve,<br /><br />Il caricamento dei files <b><i>NON e' avvenuto correttamente</i></b>.<br /><br />APRI UNA SEGNALAZIONE A sistemi@evaenergyservice.it.<br /><br />Distinti Saluti.<br /><br />team IT Eva Solutions"
)

del %destination%\*.csv
move "c:\VOC\log.log" "c:\VOC\log\SETTIMANALE-log-%data%.log"