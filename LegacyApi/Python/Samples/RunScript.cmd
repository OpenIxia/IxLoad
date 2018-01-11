Rem Launch python script 
Rem Usage: RunScript.cmd <filename>

SET ROOT=%~dp0
ECHO.%ROOT%
SET ROOT=%ROOT:\PythonScripts\Samples\=%
set PATH=%ROOT%\3rdParty\Python2.7\;%ROOT%\3rdParty\Python2.7\DLLs;%ROOT%\3rdParty\Python2.7\Scripts;%PATH%
SET PYTHONPATH=%ROOT%\PythonScripts\Samples;%ROOT%\PythonScripts\lib
"%ROOT%\3rdParty\Python2.7\python.exe" %1 %2

@endlocal