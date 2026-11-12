@echo off
rem Descarga a la cache todos los modelos de la lista, uno tras otro, mostrando
rem la barra de progreso. Los que ya estan descargados se saltean.
rem Usa llama.cpp para bajar, asi quedan en la misma cache y con los mismos
rem nombres que usa el servidor (modelos.bat / modelos.ini).
rem
rem Uso: doble clic, o desde una terminal:
rem      descargar-modelos.bat
rem      descargar-modelos.bat usuario/repo:CUANT otro/repo:CUANT    (solo esos)
setlocal EnableDelayedExpansion

set "SCRIPT_DIR=%~dp0"

rem --- Lista de modelos: agrega lineas, o anteponer "rem" para saltear una --
set "MODELOS="
set "MODELOS=!MODELOS! LiquidAI/LFM2.5-8B-A1B-GGUF:Q4_K_M"
set "MODELOS=!MODELOS! ggml-org/gpt-oss-20b-GGUF:MXFP4"
set "MODELOS=!MODELOS! unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF:Q4_K_M"
set "MODELOS=!MODELOS! mradermacher/Qwen3.6-35B-A3B-GGUF:IQ4_XS"
set "MODELOS=!MODELOS! unsloth/GLM-4.7-Flash-GGUF:Q4_K_XL"
set "MODELOS=!MODELOS! unsloth/gemma-4-26B-A4B-it-GGUF:Q4_K_M"
set "MODELOS=!MODELOS! bartowski/Qwen2.5-Coder-7B-Instruct-GGUF:Q4_K_M"
set "MODELOS=!MODELOS! bartowski/nvidia_NVIDIA-Nemotron-Nano-9B-v2-GGUF:Q4_K_M"
set "MODELOS=!MODELOS! mradermacher/Nemotron-9B-OpenCode-GGUF:Q4_K_M"
rem set "MODELOS=!MODELOS! unsloth/gemma-4-e4b-it-GGUF:Q4_K_M"
rem --------------------------------------------------------------------------

if not "%~1"=="" set "MODELOS=%*"

rem --- Carpeta de la cache ---------------------------------------------------
set "CACHE=%USERPROFILE%\.cache\huggingface\hub"
if defined HF_HOME set "CACHE=%HF_HOME%\hub"
if defined HF_HUB_CACHE set "CACHE=%HF_HUB_CACHE%"

rem --- Ubicar llama-bench.exe ------------------------------------------------
rem 1) LLAMA_DIR, 2) carpeta "llama.cpp" junto a este archivo, 3) el PATH.
set "BENCH="
if defined LLAMA_DIR if exist "%LLAMA_DIR%\llama-bench.exe" set "BENCH=%LLAMA_DIR%\llama-bench.exe"
if defined LLAMA_DIR if exist "%LLAMA_DIR%\build\bin\Release\llama-bench.exe" set "BENCH=%LLAMA_DIR%\build\bin\Release\llama-bench.exe"
if not defined BENCH if exist "%SCRIPT_DIR%llama.cpp\llama-bench.exe" set "BENCH=%SCRIPT_DIR%llama.cpp\llama-bench.exe"
if not defined BENCH if exist "%SCRIPT_DIR%llama.cpp\build\bin\Release\llama-bench.exe" set "BENCH=%SCRIPT_DIR%llama.cpp\build\bin\Release\llama-bench.exe"
if not defined BENCH for /f "delims=" %%i in ('where llama-bench 2^>nul') do if not defined BENCH set "BENCH=%%i"
if not defined BENCH goto :no_bench

echo Cache: %CACHE%
echo.

set /a total=0
for %%m in (!MODELOS!) do set /a total+=1
set /a i=0
set /a nok=0
set /a nskip=0
set /a nfail=0
set "BAJADOS="
set "FALLIDOS="

for %%m in (!MODELOS!) do call :uno "%%m"

echo ================ Resumen ================
echo Descargados ahora : !nok!
for %%m in (!BAJADOS!) do echo    + %%m
echo Ya estaban        : !nskip!
echo Con error         : !nfail!
for %%m in (!FALLIDOS!) do echo    x %%m
echo.
echo Los modelos estan en: %CACHE%
goto :fin

rem ===========================================================================
:uno
set "m=%~1"
set /a i+=1
set "repo="
set "quant="
for /f "tokens=1,2 delims=:" %%a in ("!m!") do (
  set "repo=%%a"
  set "quant=%%b"
)
if not defined quant set "quant=Q4_K_M"
set "dir=!CACHE!\models--!repo:/=--!"

echo === [!i!/!total!] !m! ===

rem Ya esta en la cache? Busca un .gguf de esa cuantizacion, completo.
set "tiene="
if not exist "!dir!\snapshots" goto :bajar
rem una descarga a medias deja archivos .incomplete
dir /s /b "!dir!\*.incomplete" >nul 2>&1
if not errorlevel 1 goto :bajar
for /f "delims=" %%f in ('dir /s /b "!dir!\snapshots\*!quant!*.gguf" 2^>nul ^| findstr /v /i "mmproj"') do set "tiene=1"
if not defined tiene goto :bajar

echo     ya esta en la cache, lo salteo.
echo.
set /a nskip+=1
goto :eof

:bajar
rem Prueba minima en CPU: baja el modelo (con barra de progreso) y confirma
rem que carga. No redirigir la salida: la barra solo se ve en la terminal.
"%BENCH%" -hf "!m!" -ngl 0 -p 16 -n 0 -r 1 --no-warmup
if errorlevel 1 (
  echo     FALLO la descarga o la carga de !m!
  set /a nfail+=1
  set "FALLIDOS=!FALLIDOS! !m!"
) else (
  set /a nok+=1
  set "BAJADOS=!BAJADOS! !m!"
)
echo.
goto :eof

rem ===========================================================================
:no_bench
echo Error: no encuentro llama-bench.exe
echo        Indica la carpeta donde esta llama.cpp, por ejemplo:
echo        set LLAMA_DIR=C:\llama.cpp
echo        descargar-modelos.bat

:fin
echo.
pause
endlocal
