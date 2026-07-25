# ==========================================
# ASP.NET Core API Publish Script (PowerShell)
# ==========================================

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptDir

Write-Host "[1/4] Starting API Publish Process..." -ForegroundColor Cyan

$ProjectPath = ".\VoiceTranslator.Api\VoiceTranslator.Api.csproj"
$PublishDir = ".\publish"
$ZipPath = ".\publish.zip"

# Step 1: Restore dependencies
Write-Host "[2/4] Restoring NuGet packages..." -ForegroundColor Yellow
dotnet restore $ProjectPath --configfile ".\NuGet.config"

if ($LASTEXITCODE -ne 0) {
    Write-Host "Restore failed!" -ForegroundColor Red
    exit 1
}

# Step 2: Clean previous publish folder
if (Test-Path $PublishDir) {
    Write-Host "Cleaning existing publish folder..." -ForegroundColor Yellow
    Remove-Item -Path $PublishDir -Recurse -Force
}

if (Test-Path $ZipPath) {
    Remove-Item -Path $ZipPath -Force
}

# Step 3: Publish project in Release mode
Write-Host "[3/4] Publishing Web API (Release Configuration)..." -ForegroundColor Yellow
dotnet publish $ProjectPath -c Release -o $PublishDir /p:UseAppHost=false

if ($LASTEXITCODE -ne 0) {
    Write-Host "Publish failed!" -ForegroundColor Red
    exit 1
}

# Step 4: Create zip package for easy server upload
Write-Host "[4/4] Creating publish.zip package..." -ForegroundColor Yellow
Compress-Archive -Path "$PublishDir\*" -DestinationPath $ZipPath -Force

Write-Host "API published successfully!" -ForegroundColor Green
Write-Host "Publish Directory: $ScriptDir\publish" -ForegroundColor White
Write-Host "Publish Zip Package: $ScriptDir\publish.zip" -ForegroundColor White
