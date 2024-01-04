@echo off

set GIT_VERSION=2.43.0
set NODEJS_VERSION=16.20.2

echo "Installing dependencies..."
echo "- Git %GIT_VERSION%"
echo "- Node.js %NODEJS_VERSION%"

cd C:\Users\vagrant

:: --------- GIT INSTALLATION ---------
git --version 2>NUL
if %errorlevel% == 0 goto endgit

echo "Downloading Git..."
powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; (New-Object System.Net.WebClient).DownloadFile('https://github.com/git-for-windows/git/releases/download/v%GIT_VERSION%.windows.1/Git-%GIT_VERSION%-64-bit.exe', 'GitInstaller.exe')"

:: Install Git in silent mode
echo "Install Git..."
start /wait GitInstaller.exe /VERYSILENT /SILENT /NORESTART /NOCANCEL /SP-

:: Remove git installer
del GitInstaller.exe

:endgit

:: --------- NODE INSTALLATION ---------
:: Check if Node.js is already installed
node --version 2>NUL
if %errorlevel% == 0 goto endnode

:: Download Node.js installer
echo "Downloading Node.js..."
powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; (New-Object System.Net.WebClient).DownloadFile('https://nodejs.org/dist/v%NODEJS_VERSION%/node-v%NODEJS_VERSION%-x64.msi', 'NodeJsInstaller.msi')"

:: Install Node.js in silent mode
echo "Installing Node.js..."
start /wait NodeJsInstaller.msi /quiet /norestart

:: Delete the installer file after installation
del NodeJsInstaller.msi

:endnode



:: --------- 7-zip INSTALLATION ---------
if exist "C:\Program Files\7-Zip\7z.exe" goto end7zip

:: Download 7-Zip installer
echo "Downloading 7-Zip..."
powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; (New-Object System.Net.WebClient).DownloadFile('https://www.7-zip.org/a/7z2301-x64.msi', '7ZipInstaller.msi')"

:: Install 7-Zip in silent mode
echo "Installing 7-Zip..."
start /wait msiexec /i 7ZipInstaller.msi /qn /norestart

:: Delete the installer file after installation
del 7ZipInstaller.msi

:end7zip

set PATH="C:\Program Files\7-Zip";%PATH%


:: --------- Inno Setup INSTALLATION ---------

if exist "C:\Program Files (x86)\Inno Setup 5\ISCC.exe" goto endinno

:: Download Inno Setup installer
echo Downloading Inno Setup...
::powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; (New-Object System.Net.WebClient).DownloadFile('http://files.jrsoftware.org/is/6/innosetup-6.1.2.exe', 'InnoSetupInstaller.exe')"
powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; (New-Object System.Net.WebClient).DownloadFile('http://files.jrsoftware.org/is/5/innosetup-5.5.9.exe', 'InnoSetupInstaller.exe')"

:: Install Inno Setup in silent mode
echo Installing Inno Setup...
start /wait InnoSetupInstaller.exe /VERYSILENT /NORESTART /SP-

:: Delete the installer file after installation
del InnoSetupInstaller.exe
:endinno

set PATH="C:\Program Files (x86)\Inno Setup 5";%PATH%

echo "Installing dependencies [OK]"
