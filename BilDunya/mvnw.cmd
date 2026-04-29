@REM Maven Wrapper Script - Windows
@REM

setlocal

@REM Find java.exe
set JAVA_EXE=java.exe
if defined JAVA_HOME goto findJavaFromJavaHome

where %JAVA_EXE% >nul 2>&1
if %ERRORLEVEL% equ 0 (
    echo Copying jar files ...
    goto execute
)

echo.
echo ERROR: JAVA_HOME is not set and no 'java' command could be found in your PATH.
echo.
echo Please set the JAVA_HOME variable in your environment to match the
echo location of your Java installation.
goto fail

:findJavaFromJavaHome
set JAVA_HOME=%JAVA_HOME:"=%
set JAVA_EXE=%JAVA_HOME%/bin/java.exe

if exist "%JAVA_EXE%" goto execute

echo.
echo ERROR: JAVA_HOME is set to an invalid directory: %JAVA_HOME%
echo.
echo Please set the JAVA_HOME variable in your environment to match the
echo location of your Java installation.
goto fail

:execute
@REM Setup the command line
setlocal enabledelayedexpansion
set MAVEN_CMD_LINE_ARGS=%*

@REM Execute Maven
"%JAVA_EXE%" ^
  %MAVEN_OPTS% ^
  -Dclassworlds.conf="%~dp0\.mvn\wrapper\m2.conf" ^
  -Dmaven.home="%~dp0\.mvn\wrapper" ^
  -Dmaven.multiModuleProjectDirectory="%~dp0" ^
  -jar "%~dp0\.mvn\wrapper\maven-wrapper.jar" %MAVEN_CMD_LINE_ARGS%

if %ERRORLEVEL% neq 0 (
  goto fail
)
goto end

:fail
echo.
echo Maven execution failed
exit /b 1

:end
endlocal
