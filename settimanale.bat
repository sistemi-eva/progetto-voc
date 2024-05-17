REM INVIO SETTIMANALE PROGETTO VOC (subentro,switchin,voltura)
@echo off

REM Definizione VARIABILI
set "wget="C:\Program Files (x86)\GnuWin32\bin\wget.exe""
set "blat="C:\VOC_2.0\blat\full\blat.exe""
set "recipient=sistemi@evaenergyservice.it"
set "copiaconoscenza=fdellamorte@evaenergyservice.it"
%blat% -install mail.evaenergyservice.it db-bi@ugmlocal.com password

REM Definizione della cartella di destinazione
set "destination=C:\VOC_2.0\download"

REM Ottieni la data odierna nel formato americano (YY-MM-DD)
for /f "tokens=1-3 delims=/" %%a in ('echo %date%') do set "date_orig=%%c%%b%%a"
set date_str=%date_orig%
set data=%date_str:~2%

REM Variabili di controllo dei vari step
set "step1=99"
set "step2=99"

REM URL dei file da scaricare
REM SUBENTRO
set "url1=https://cruscottodb.evaenergyservice.it/public/question/3fb4ad65-c7ed-4363-8c1d-7afa7e1c980c.csv"
set "subentro=subentro_%data%.csv"
REM SWITCH IN
set "url2=https://cruscottodb.evaenergyservice.it/public/question/3f576a8d-6d0d-4568-8867-fef9be952460.csv"
set "switchin=switchin_%data%.csv"
REM VOLTURA
set "url3=https://cruscottodb.evaenergyservice.it/public/question/50f5ed94-b9dd-4737-b74b-4e4ae052341c.csv"
set "voltura=voltura_%data%.csv"

REM Scarica il primo file
%wget% -O "%destination%\%subentro%" "%url1%"
REM Scarica il secondo file
%wget% -O "%destination%\%switchin%" "%url2%"
REM Scarica il terzo file
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
set "logFile=C:\VOC_2.0\log\SETTIMANALE-log-%data%.log"
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

REM invio email
if %step1% equ 0 (
	if %step2% equ 0 (
		%blat% -to "%recipient%" -cc %copiaconoscenza% -subject "Upload Settimanale SANDSIV OK" -html -body "Ciao,<br /><br />ti informiamo che il caricamento dei files <b><i>e' avvenuto correttamente</i></b>.<br /><br />I seguenti files sono stati caricati:<br />- %subentro% <br />- %voltura% <br />- %switchin% <br /><br />Il Team IT Eva Solutions"
	) else (
	%blat% -to "%recipient%" -cc %copiaconoscenza% -subject "Errore upload Settimanale SANDSIV" -html -body "Ciao,<br /><br />ti informiamo che il caricamento dei files <b><i>NON e' avvenuto correttamente</i></b>.<br /><br />Procedere con il caricamento manuale.<br /><br />Il Team IT Eva Solutions"
	)
) else (
	%blat% -to "%recipient%" -cc %copiaconoscenza% -subject "Errore upload Settimanale SANDSIV" -html -body "Ciao,<br /><br />ti informiamo che il caricamento dei files <b><i>NON e' avvenuto correttamente</i></b>.<br /><br />APRI UNA SEGNALAZIONE A sistemi@evaenergyservice.it.<br /><br />Il Team IT Eva Solutions"
)

del %destination%\*.csv