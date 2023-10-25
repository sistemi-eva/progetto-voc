REM INVIO MENSILE PROGETTO VOC (bolletta,switchout,welcomeletter)
@echo off
setlocal enabledelayedexpansion

REM URL dei file da scaricare
REM BOLLETTA
set "url1=http://localhost:3000/public/question/71833775-044d-49f7-aaa2-e9b48e29e081.csv"
REM SWITCH OUT
set "url2=http://localhost:3000/public/question/15b86c29-6978-4882-8660-973d6e8dd556.csv"
REM WELCOME LETTER
set "url3=http://localhost:3000/public/question/d76d76ff-b202-4466-a035-fd9368fa2efa.csv"

REM Definizione della cartella di destinazione
set "destination=C:\VOC\download"

REM Definizione WGET
set "wget="C:\Program Files (x86)\GnuWin32\bin\wget.exe""

REM Scarica il primo file
echo Download del primo file...
%wget% -O "%destination%\file1.csv" "%url1%"

REM Scarica il secondo file
echo Download del secondo file...
%wget% -O "%destination%\file2.csv" "%url2%"

REM Scarica il terzo file
echo Download del terzo file...
%wget% -O "%destination%\file3.csv" "%url3%"

REM Ottieni la data odierna nel formato americano (MM-DD-YYYY)
for /f "tokens=1-3 delims=/" %%a in ('echo %date%') do set "date=%%b-%%a-%%c"

REM Rinomina i file scaricati aggiungendo la data odierna
ren "%destination%\file1.csv" "bolletta_%date%.csv"
ren "%destination%\file2.csv" "switchout_%date%.csv"
ren "%destination%\file3.csv" "welcomeletter_%date%.csv"

echo Download e rinomina completati!

REM Definizione delle variabili di configurazione
REM set "winscpPath=C:\Program Files (x86)\WinSCP\WinSCP.exe"   
REM set "ftpHost=192.168.2.2"                              
REM set "ftpUsername=admin"                        
REM set "ftpPassword=Calendario01."                        
REM set "remotePath=/"                         
REM 
REM REM Esecuzione dell'upload con WinSCP
REM "%winscpPath%" /log="upload.log" /command ^
REM     "option batch abort" ^
REM     "option confirm off" ^
REM     "open ftp://%ftpUsername%:%ftpPassword%@%ftpHost%" ^
REM     "put %destination%\*" ^
REM     "exit"
REM 
REM pause