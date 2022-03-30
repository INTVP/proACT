@ECHO OFF

set function_name=windows_req
ECHO %date% %time% [Main Thread] %function_name%: Adding Rscript front-end to all users' path...
Rem adding Rscript to path
set app=Rscript.exe
set cmd="where /r "c:\Program Files\R.*\x64" %app%"
FOR /F "tokens=*" %%i IN (' %cmd% ') DO SET X=%%i
set X=%X:\Rscript.exe=%
ECHO %X%
pause