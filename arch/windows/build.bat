@echo off

:: Install dependencies
call install.bat
if %errorlevel% neq 0 (
  ::pause
  exit %errorlevel%
)

set NW_VERSION=0.83.0
set NW_RELEASE=v%NW_VERSION%
set NW_BASENAME=nwjs
REM set NW_BASENAME=nwjs-sdk
set NW=%NW_BASENAME%-%NW_RELEASE%-win-x64
set NW_GZ=%NW%.zip
echo "NW.js %NW_VERSION%"

set SOURCE=C:\vagrant
if not exist "%SOURCE%" (
  echo "ERROR: Folder C:\vagrant not mounted!"
  exit 1
)
cd C:\Users\vagrant


echo "Deleting old files..."
del /s /q cesium-v*-web.zip
rd /s /q cesium
rd /s /q cesium_release

echo "Cloning Cesium (from github.com)..."
git clone https://github.com/duniter/cesium.git
if not exist C:\Users\vagrant\cesium (
  echo "ERROR: Cannot clone Cesium source!"
  ::pause
  exit 1
)
cd cesium

for /f "delims=" %%a in ('git rev-list --tags --max-count=1') do @set CESIUM_REV=%%a
for /f "delims=" %%a in ('git describe --tags %CESIUM_REV%') do @set CESIUM_TAG=%%a
set CESIUM=cesium-%CESIUM_TAG%-web
set CESIUM_ZIP=%CESIUM%.zip
echo "Version: %CESIUM_TAG%"
echo "Basename: %CESIUM%"
echo "Filename: %CESIUM_ZIP%"

cd ..

if not exist %SOURCE%\%NW_GZ% (
  echo "Downloading %NW%.zip..."
  REM powershell -Command "Invoke-WebRequest -Uri https://dl.nwjs.io/v%NW_VERSION%/%NW%.zip -OutFile %SOURCE%\%NW_GZ%"
  powershell -Command "(New-Object System.Net.WebClient).DownloadFile(\"https://dl.nwjs.io/v%NW_VERSION%/%NW%.zip\", \"%SOURCE%\%NW_GZ%\")"
)

if not exist %SOURCE%\%CESIUM_ZIP% (
  echo "Downloading %CESIUM_ZIP%..."
  powershell -Command "(New-Object System.Net.WebClient).DownloadFile(\"https://github.com/duniter/cesium/releases/download/%CESIUM_TAG%/%CESIUM_ZIP%\", \"%SOURCE%\%CESIUM_ZIP%\")"
)

call 7z x %SOURCE%\%NW_GZ%
move %NW% cesium_release
if not exist cesium_release (
  echo "ERROR Missing cesium_release folder !"
  ::pause
  exit 1
)
cd cesium_release
mkdir cesium
cd cesium
call 7z x %SOURCE%\%CESIUM_ZIP%

cd ..
xcopy %SOURCE%\LICENSE.txt .\ /s /e
xcopy %SOURCE%\package.json .\ /s /e
xcopy %SOURCE%\cesium-desktop.js .\ /s /e
xcopy %SOURCE%\splash.html .\ /s /e
call npm install

cd C:\Users\vagrant\cesium_release\cesium
powershell -Command "(Get-Content C:\Users\vagrant\cesium_release\cesium\index.html) | foreach-object {$_ -replace '<script src=\"config.js\"></script>','<script src=\"config.js\"></script><script src=\"../cesium-desktop.js\"></script>' } | Set-Content C:\Users\vagrant\cesium_release\cesium\index.txt"
move index.txt index.html
del "dist_js/*api.js"
del "dist_css/*api.css"
rmdir /s /q "maps"
rmdir /s /q ".git"
cd ..

iscc %SOURCE%\cesium.iss /DROOT_PATH=%cd%
move %cd%\Cesium.exe %SOURCE%\cesium-desktop-%CESIUM_TAG%-windows-x64.exe
echo "Build done: binary available at cesium-desktop-%CESIUM_TAG%-windows-x64.exe"

::pause
exit 0
