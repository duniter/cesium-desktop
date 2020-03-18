
set NW_VERSION=0.42.2
set NW_RELEASE=v%NW_VERSION%
set NW_BASENAME=nwjs
REM set NW_BASENAME=nwjs-sdk
set NW=%NW_BASENAME%-%NW_RELEASE%-win-x64
set NW_GZ=%NW%.zip
echo "NW.js %NW_VERSION%"

REM NPM
set PATH="C:\Users\vagrant\AppData\Roaming\npm";%PATH%
REM InnoSetup
set PATH="C:\Program Files (x86)\Inno Setup 5";%PATH%

cd C:\Users\vagrant
REM echo "Suppression des anciennes sources..."
del /s /q cesium-v*-web.zip
rd /s /q cesium
rd /s /q cesium_release
echo "Clonage de Cesium..."
git clone https://github.com/duniter/cesium.git
cd cesium

for /f "delims=" %%a in ('git rev-list --tags --max-count=1') do @set CESIUM_REV=%%a
for /f "delims=" %%a in ('git describe --tags %CESIUM_REV%') do @set CESIUM_TAG=%%a
set CESIUM=cesium-%CESIUM_TAG%-web
set CESIUM_ZIP=%CESIUM%.zip
echo %CESIUM_TAG%
echo %CESIUM%
echo %CESIUM_ZIP%

cd ..

if not exist C:\vagrant\%NW_GZ% (
  echo "Telechargement de %NW%.zip..."
  REM powershell -Command "Invoke-WebRequest -Uri https://dl.nwjs.io/v%NW_VERSION%/%NW%.zip -OutFile C:\vagrant\%NW_GZ%"
  powershell -Command "(New-Object System.Net.WebClient).DownloadFile(\"https://dl.nwjs.io/v%NW_VERSION%/%NW%.zip\", \"C:\vagrant\%NW_GZ%\")"
)

if not exist C:\vagrant\%CESIUM_ZIP% (
  echo "Downloading %CESIUM_ZIP%..."
  powershell -Command "(New-Object System.Net.WebClient).DownloadFile(\"https://github.com/duniter/cesium/releases/download/%CESIUM_TAG%/%CESIUM_ZIP%\", \"C:\vagrant\%CESIUM_ZIP%\")"
)

call 7z x C:\vagrant\%NW_GZ%
move %NW% cesium_release
cd cesium_release
mkdir cesium
cd cesium
call 7z x C:\vagrant\%CESIUM_ZIP%

cd ..
xcopy C:\vagrant\LICENSE.txt .\ /s /e
xcopy C:\vagrant\package.json .\ /s /e
xcopy C:\vagrant\node.js .\cesium\ /s /e
call npm install

cd C:\Users\vagrant\cesium_release\cesium
powershell -Command "(Get-Content C:\Users\vagrant\cesium_release\cesium\index.html) | foreach-object {$_ -replace '<script src=\"config.js\"></script>','<script src=\"config.js\"></script><script src=\"node.js\"></script>' } | Set-Content C:\Users\vagrant\cesium_release\cesium\index.txt"
move index.txt index.html
del "dist_js/*api.js"
del "dist_css/*api.css"
rmdir /s /q "maps"
rmdir /s /q ".git"
cd ..

iscc C:\vagrant\cesium.iss /DROOT_PATH=%cd%
move %cd%\Cesium.exe C:\vagrant\cesium-desktop-%CESIUM_TAG%-windows-x64.exe
echo "Build done: binary available at cesium-desktop-%CESIUM_TAG%-windows-x64.exe"
