@echo off
setlocal enabledelayedexpansion
set "APP_HOME=%~dp0"
set "PROPS=%APP_HOME%gradle\wrapper\gradle-wrapper.properties"

if not exist "%PROPS%" (
  echo ERROR: Gradle wrapper properties not found: %PROPS% 1>&2
  exit /b 1
)

for /f "tokens=1,* delims==" %%A in ('findstr /b "distributionUrl=" "%PROPS%"') do set "DIST_URL=%%B"
set "DIST_URL=%DIST_URL:\:=%"

if "%DIST_URL%"=="" (
  echo ERROR: distributionUrl is missing from %PROPS% 1>&2
  exit /b 1
)

for %%F in ("%DIST_URL%") do set "ARCHIVE=%%~nxF"
set "DIST_NAME=%ARCHIVE:.zip=%"
if "%GRADLE_USER_HOME%"=="" set "GRADLE_USER_HOME=%USERPROFILE%\.gradle"
set "INSTALL_ROOT=%GRADLE_USER_HOME%\wrapper\dists\edubridge"
set "INSTALL_DIR=%INSTALL_ROOT%\%DIST_NAME%"
set "GRADLE_BIN=%INSTALL_DIR%\bin\gradle.bat"

if not exist "%GRADLE_BIN%" (
  if not exist "%INSTALL_ROOT%" mkdir "%INSTALL_ROOT%"
  set "TMP_DIR=%TEMP%\edubridge-gradle-%RANDOM%-%RANDOM%"
  mkdir "!TMP_DIR!"

  echo Downloading Gradle from %DIST_URL%
  powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$ErrorActionPreference='Stop'; Invoke-WebRequest -UseBasicParsing '%DIST_URL%' -OutFile '!TMP_DIR!\%ARCHIVE%'; Expand-Archive -Path '!TMP_DIR!\%ARCHIVE%' -DestinationPath '!TMP_DIR!' -Force"
  if errorlevel 1 (
    rmdir /s /q "!TMP_DIR!" >nul 2>&1
    exit /b 1
  )

  for /d %%D in ("!TMP_DIR!\gradle-*") do (
    if exist "%%D\bin\gradle.bat" (
      if exist "%INSTALL_DIR%" rmdir /s /q "%INSTALL_DIR%"
      move "%%D" "%INSTALL_DIR%" >nul
      goto :installed
    )
  )

  echo ERROR: downloaded Gradle distribution is invalid. 1>&2
  rmdir /s /q "!TMP_DIR!" >nul 2>&1
  exit /b 1

  :installed
  rmdir /s /q "!TMP_DIR!" >nul 2>&1
)

call "%GRADLE_BIN%" %*
exit /b %ERRORLEVEL%
