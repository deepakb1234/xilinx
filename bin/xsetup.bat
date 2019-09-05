@echo off
REM store the original image dir into a variable
set INSTALLER_ROOT_DIR=%~dp0\.. 

rem resolve UNC path
pushd %~dp0
set root="%cd%"

rem xsetup.bat is in <root>\bin, get the parent directory (<root>)
set parent=%cd%\..

@setlocal enableextensions enabledelayedexpansion
rem Check for exclamation point
rem Remove exclamation point if any in the parent folder path and check if the folder exists
set parent_fixed=%parent:!=%

IF NOT EXIST "%parent_fixed%" (
  start cmd /c "echo ERROR: The character '^!' is not allowed in path. Please correct the problem and try again. && pause"
  endlocal
  set EXITCODE=1
  goto :end
)
endlocal

%SYSTEMROOT%\System32\net session >nul 2>&1
if NOT %errorLevel% == 0 (
  echo ERROR: Administrative permissions are not available. Please restart the command line shell as Administrator.
  set EXITCODE=1
  goto :end
)
CALL %root%\setup-boot-loader.bat %*
set ARGS=%ARGS% --add-modules java.se.ee -DINSTALLER_ROOT_DIR="%INSTALLER_ROOT_DIR%"

REM if the argument -Uninstall was specified, run the uninstaller
IF NOT [%1]==[] (
  IF [%1]==[-Uninstall] (
    set ARGS=%ARGS% -DINSTALLATION_MODE=Uninstall
  )
) 
set ARGS=%ARGS% -Dlog4j.configuration="%parent%/data/log4j.xml"

IF NOT "%DEBUG_ARGS%" == "" (
 echo adding %DEBUG_ARGS% to %ARGS%
 set ARGS=%DEBUG_ARGS% %ARGS%
)

set ARGS=%ARGS% -DHAS_DYNAMIC_LANGUAGE_BUNDLE=true

IF [%X_BATCH%] == [1] (
  rem Check if it is a 32-bit platform and exit if 32 libraries are not available.
  IF [%ARCH%] == 32 (
    set libDir=%parent%\lib\win32.o
    IF NOT EXIST "%libDir%" (
      echo ERROR: This installation is not supported for 32 bit platforms
      set EXITCODE=1
      goto :end
    )
  )
  %X_JAVA_HOME%\bin\java.exe %ARGS% -cp "%X_CLASS_PATH%;%parent%\lib\classes\commons-cli-1.2.jar" com.xilinx.installer.api.InstallerLauncher %*
) ELSE (
  %X_JAVA_HOME%\bin\java.exe %ARGS% -splash:"%parent%\data\images\splash.png" -jar "%parent%\lib\classes\xinstaller.jar"
)
set EXITCODE=%errorlevel%
:end
IF NOT [%TEMP_NATIVE_LIB%] == [] (
  IF EXIST [%TEMP_NATIVE_LIB%] (
    RMDIR /Q /S [%TEMP_NATIVE_LIB%]
  )
)
popd
exit /b %EXITCODE%

