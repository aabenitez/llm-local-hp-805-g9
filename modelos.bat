@echo off
rem Levanta llama-server en modo router: todos los modelos de la cache quedan
rem disponibles en el selector del chat y se cargan de a uno.
rem Los ajustes de cada modelo estan en modelos.ini, que se busca en la misma
rem carpeta donde esta este archivo.
rem Uso: doble clic, o desde una terminal:  modelos.bat
setlocal

set "SCRIPT_DIR=%~dp0"
if not defined PRESET set "PRESET=%SCRIPT_DIR%modelos.ini"
if not defined PORT set "PORT=8080"

rem --- Ubicar llama-server.exe ---------------------------------------------
rem 1) Si definiste LLAMA_DIR, se busca ahi.
rem 2) Si no, en una carpeta "llama.cpp" junto a este archivo.
rem 3) Si no, en el PATH (por ejemplo si lo instalaste con winget).
set "SERVER="
if defined LLAMA_DIR if exist "%LLAMA_DIR%\llama-server.exe" set "SERVER=%LLAMA_DIR%\llama-server.exe"
if defined LLAMA_DIR if exist "%LLAMA_DIR%\build\bin\Release\llama-server.exe" set "SERVER=%LLAMA_DIR%\build\bin\Release\llama-server.exe"
if not defined SERVER if exist "%SCRIPT_DIR%llama.cpp\llama-server.exe" set "SERVER=%SCRIPT_DIR%llama.cpp\llama-server.exe"
if not defined SERVER if exist "%SCRIPT_DIR%llama.cpp\build\bin\Release\llama-server.exe" set "SERVER=%SCRIPT_DIR%llama.cpp\build\bin\Release\llama-server.exe"
if not defined SERVER for /f "delims=" %%i in ('where llama-server 2^>nul') do if not defined SERVER set "SERVER=%%i"

if not defined SERVER goto :no_server
if not exist "%PRESET%" goto :no_preset

rem --- Si ya hay un llama-server corriendo, lo detiene ----------------------
tasklist /FI "IMAGENAME eq llama-server.exe" 2>nul | find /I "llama-server.exe" >nul
if not errorlevel 1 (
  echo ^>^> Deteniendo llama-server existente...
  taskkill /IM llama-server.exe /F >nul 2>&1
  timeout /t 2 /nobreak >nul
)

echo ^>^> Modo router ^| presets: %PRESET% ^| http://127.0.0.1:%PORT%

rem Importante: device, contexto, etc. NO van aca. Lo que se pasa por linea de
rem comandos pisa a los presets, asi que todo eso vive en modelos.ini.
"%SERVER%" --models-preset "%PRESET%" --models-max 1 --host 127.0.0.1 --port %PORT%
goto :fin

:no_server
echo Error: no encuentro llama-server.exe
echo        Indica la carpeta donde esta, por ejemplo:
echo        set LLAMA_DIR=C:\llama.cpp
echo        modelos.bat
goto :fin

:no_preset
echo Error: no encuentro el archivo de presets en %PRESET%

:fin
echo.
pause
endlocal
