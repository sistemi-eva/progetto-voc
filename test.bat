@echo off

for /f "tokens=1-3 delims=/" %%a in ('echo %date%') do set "date=%%c%%b%%a"
echo %date%
set stringa=%date%
set sottostringa=%stringa:~2%
echo %sottostringa%