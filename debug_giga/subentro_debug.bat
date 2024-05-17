REM INVIO SETTIMANALE PROGETTO VOC (subentro,switchin,voltura)
@echo off

REM Definizione VARIABILI
set "wget="C:\Program Files (x86)\GnuWin32\bin\wget.exe""
set "blat="C:\VOC_2.0\blat\full\blat.exe""
set "recipient=ggaezza@evaenergyservice.it"
%blat% -install mail.evaenergyservice.it no-reply@evaenergyservice.it tuapassword

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
set "url1=http://localhost:3000/public/question/3fb4ad65-c7ed-4363-8c1d-7afa7e1c980c.csv"
set "subentro=subentro_%data%.csv"
REM Scarica il primo file
REM echo Download del primo file...
%wget% -O "%destination%\%subentro%" "%url1%"
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
:invio_email

REM Set EmailBody="template.html"
rem invio email
if %step1% equ 0 (
	if %step2% equ 0 (
		%blat% -to "%recipient%" -subject "Upload Settimanale SFTP SANDSIV" -html -body "Salve,<br /><br />Il caricamento dei files <b><i>e' avvenuto correttamente</i></b>.<br /><br />I seguenti files sono stati caricati:<br />- %subentro% <br />- %voltura% <br />- %switchin% <br /><br />Distinti Saluti.<br /><br />team IT Eva Solutions"
	) else (
	%blat% -to "%recipient%"  -subject "Upload Settimanale SFTP SANDSIV" -html -body "Salve,<br /><br />Il caricamento dei files <b><i>NON e' avvenuto correttamente</i></b>.<br /><br />PROCEDERE CON IL CARICAMENTO MANUALE.<br /><br />APRI UNA SEGNALAZIONE A sistemi@evaenergyservice.it.<br /><br />Distinti Saluti.<br /><br />team IT Eva Solutions"
	)
) else (
	%blat% -to "%recipient%"  -subject "Upload Settimanale SFTP SANDSIV" -html -body "Salve,<br /><br />Il caricamento dei files <b><i>NON e' avvenuto correttamente</i></b>.<br /><br />APRI UNA SEGNALAZIONE A sistemi@evaenergyservice.it.<br /><br />Distinti Saluti.<br /><br />team IT Eva Solutions"
)