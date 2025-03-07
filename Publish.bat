@echo off
SetLocal EnableDelayedExpansion
cd /d "%~dp0"

REM Minimize PATH modification
SET GIT_PATH=C:\Program Files (x86)\Git\bin
SET PATH=%PATH%;%GIT_PATH%

REM Store version for single read
echo === Git Stash Uncommitted Changes ===
git stash >nul 2>&1

REM Optimize version reading and increment with single file read
set "MAJOR="
set "MINOR="
set "NEWREV="
for /F "usebackq tokens=1,2,3 delims= " %%a in (`type Version.h ^| findstr "VERSION_"`) do (
    if "%%a %%b"=="#define VERSION_MAJOR" set "MAJOR=%%c"
    if "%%a %%b"=="#define VERSION_MINOR" set "MINOR=%%c"
    if "%%a %%b"=="#define VERSION_REVISION" set /a "NEWREV=%%c+1"
)

REM Write version file efficiently
(
    echo #define VERSION_MAJOR %MAJOR%
    echo #define VERSION_MINOR %MINOR%
    echo #define VERSION_REVISION %NEWREV%
)>Version.h

echo Current Version: %MAJOR%.%MINOR%.%NEWREV%

REM Clean directories efficiently
echo === Cleaning Output Directories ===
for %%D in ("x32\Zip Release" "x64\Zip Release" "Zip Release") do (
    if exist "%%~D" rd /s /q "%%~D"
)

REM Use newer VS path and minimize environment modification
call "C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\Tools\VsDevCmd.bat" >nul 2>&1

REM Build with optimized output
echo === Building Targets ===
for %%P in (Win32 x64) do (
    echo Building %%P...
    MSBuild StereoVisionHacks.sln /p:Configuration="Zip Release" /p:Platform=%%P /v:minimal /m /nr:false /restore:false
)

REM Commit version change
git commit -am "Build %MAJOR%.%MINOR%.%NEWREV%" >nul 2>&1

REM Restore state
git stash pop >nul 2>&1

REM Create directory structure efficiently
echo === Preparing Release Structure ===
set "ZIP_DIR=.\Zip Release"
for %%D in (
    "%ZIP_DIR%\x32\ShaderFixes"
    "%ZIP_DIR%\x64\ShaderFixes"
    "%ZIP_DIR%\loader\x32"
    "%ZIP_DIR%\loader\x64"
    "%ZIP_DIR%\cmd_Decompiler"
) do mkdir "%%~D" 2>nul

REM Move files efficiently
for %%A in (x32 x64) do (
    move ".\%%A\Zip Release\d3dx.ini" "%ZIP_DIR%\%%A\"
    move ".\%%A\Zip Release\uninstall.bat" "%ZIP_DIR%\%%A\"
    move ".\%%A\Zip Release\*.dll" "%ZIP_DIR%\%%A\"
    move ".\%%A\Zip Release\ShaderFixes\*.*" "%ZIP_DIR%\%%A\ShaderFixes\"
    move ".\%%A\Zip Release\3DMigoto Loader.exe" "%ZIP_DIR%\loader\%%A\"
)

move ".\x32\Zip Release\cmd_Decompiler.exe" "%ZIP_DIR%\cmd_Decompiler\"
copy "%ZIP_DIR%\x32\d3dcompiler_47.dll" "%ZIP_DIR%\cmd_Decompiler\" >nul

REM Create zips efficiently
echo === Creating Release Archives ===
set "VERSION=%MAJOR%.%MINOR%.%NEWREV%"
7zip\7za a -tzip "%ZIP_DIR%\3Dmigoto-%VERSION%.zip" "%ZIP_DIR%\x32" "%ZIP_DIR%\x64" "%ZIP_DIR%\loader" -mx=1
7zip\7za a -tzip "%ZIP_DIR%\cmd_Decompiler-%VERSION%.zip" "%ZIP_DIR%\cmd_Decompiler\*" -mx=1

echo Version-%VERSION%>"%ZIP_DIR%\Version-%VERSION%"

pause
exit /b 0
