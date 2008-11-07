@echo off
setlocal enableextensions
cd /d %~dp0 2>nul >nul

:testmklink
set errorlevel=0
mklink %~dp0linktest.tmp %~dp0create-bin-links.cmd 2>nul >nul || goto nomklink

:testarguments
if "%1" == "" goto help
if "%2" == "" goto help

:checkclosedeclipse
set /p eclipse= Did you close Eclipse? (Note, you must enter "yes"!): 
if "%eclipse%" == "yes" goto makelinks
goto end

:makelinks
REM go into the branch root
cd /d %~1 2>nul >nul  || goto fail
REM create links
for /f "usebackq delims==" %%i IN (`dir bin /a:d /b /s`) DO (md "%2%%~psi%%~nxi" 2>nul && rd /s /q "%%~fi" 2>nul && mklink /d "%%~fi" "%2%%~psi%%~nxi" 2>nul) || goto fail
goto end

:help
echo -------------------------------------------------
echo Creating links for Eclipse project "bin" folders.
echo -------------------------------------------------
echo\
echo If you have a SSD, it might be a good idea to create the compile output
echo into a different directory on a different drive. This utility assists
echo you with that task on Windows Vista using the "mklink" utility.
echo\
echo Syntax: create-bin-links.cmd ^<source^> ^<target^>
echo         ^<source^> - the source which should be searched for bin folders 
echo         ^<target^> - the target folder where the links should point to
echo\
echo\
goto fail

:nomklink
echo ERROR: Your platform does not support 'mklink'.
goto fail

:fail
endlocal
del /F /Q %~dp0*.tmp 2>nul >nul
exit /b 1

:end
endlocal
del /F /Q %~dp0*.tmp 2>nul >nul
exit /b 0