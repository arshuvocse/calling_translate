@echo off
echo ==========================================
echo ASP.NET Core API Publish Script
echo ==========================================

cd /d "%~dp0"

echo [1/4] Restoring NuGet packages...
dotnet restore .\VoiceTranslator.Api\VoiceTranslator.Api.csproj --configfile .\NuGet.config
if %errorlevel% neq 0 (
    echo Restore failed!
    pause
    exit /b %errorlevel%
)

echo [2/4] Cleaning previous publish folder...
if exist .\publish rmdir /s /q .\publish
if exist .\publish.zip del /f /q .\publish.zip

echo [3/4] Publishing project in Release mode...
dotnet publish .\VoiceTranslator.Api\VoiceTranslator.Api.csproj -c Release -o .\publish /p:UseAppHost=false
if %errorlevel% neq 0 (
    echo Publish failed!
    pause
    exit /b %errorlevel%
)

echo [4/4] Creating publish.zip archive...
powershell -Command "Compress-Archive -Path '.\publish\*' -DestinationPath '.\publish.zip' -Force"

echo.
echo ==========================================
echo API published successfully!
echo Publish Directory: %~dp0publish
echo Publish Zip Package: %~dp0publish.zip
echo ==========================================
echo.
pause
