# Ensure the script runs with Administrative privileges (Required for Machine PATH changes)
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "==========================================================" -ForegroundColor Red
    Write-Host " Error: This script requires Administrative privileges!"    -ForegroundColor Red
    Write-Host " Please restart your PowerShell console as Administrator."  -ForegroundColor Red
    Write-Host "==========================================================" -ForegroundColor Red
    Exit
}

# Ensure the script runs with high color feedback
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "    Claude Code + DeepSeek V4 Flash Setup" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# 1. Install Node.js via Chocolatey if not present
if ((Get-Command "node" -ErrorAction SilentlyContinue) -eq $null) {
    Write-Host "`n[1/4] Node.js not found. Installing via Chocolatey..." -ForegroundColor Yellow
    
    if ((Get-Command "choco" -ErrorAction SilentlyContinue) -eq $null) {
        Write-Host "Error: Chocolatey is not installed or not in your PATH. Please install Chocolatey first." -ForegroundColor Red
        Exit
    }
    
    choco install nodejs.install -y
} else {
    Write-Host "`n[1/4] Node.js is already installed." -ForegroundColor Green
}

# 2. Check and Install Claude Code globally
if ((Get-Command "claude" -ErrorAction SilentlyContinue) -eq $null) {
    Write-Host "`n[2/4] Claude Code not found. Running native Windows installer..." -ForegroundColor Yellow
    irm https://claude.ai/install.ps1 | iex
} else {
    Write-Host "`n[2/4] Claude Code is already installed." -ForegroundColor Green
}

# 3. Inject and fix the environment variable path permanently (User & Machine)
Write-Host "`n[3/4] Registering Claude binary PATH environment variables..." -ForegroundColor Yellow
$TargetBinPath = Join-Path $HOME ".local\bin"

# --- Update User PATH ---
$UserPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
if ($UserPath -notlike "*$TargetBinPath*") {
    $NewUserPath = if ($UserPath.EndsWith(";")) { "$UserPath$TargetBinPath" } else { "$UserPath;$TargetBinPath" }
    [System.Environment]::SetEnvironmentVariable("Path", $NewUserPath, "User")
    Write-Host "Successfully appended to User PATH." -ForegroundColor Green
} else {
    Write-Host "Target path already exists in User PATH." -ForegroundColor Green
}

# --- Update Machine PATH ---
$MachinePath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
if ($MachinePath -notlike "*$TargetBinPath*") {
    $NewMachinePath = if ($MachinePath.EndsWith(";")) { "$MachinePath$TargetBinPath" } else { "$MachinePath;$TargetBinPath" }
    [System.Environment]::SetEnvironmentVariable("Path", $NewMachinePath, "Machine")
    Write-Host "Successfully appended to Machine PATH." -ForegroundColor Green
} else {
    Write-Host "Target path already exists in Machine PATH." -ForegroundColor Green
}

# Force reload the active environment block in this exact open console window so it works immediately
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")


# 4. Securely read the OpenRouter API Key
Write-Host "`n[4/4] Configuration parameters required:" -ForegroundColor Cyan
Write-Host "--------------------------------------------------" -ForegroundColor Cyan
Write-Host "Please enter your OpenRouter API Key" -ForegroundColor Cyan
Write-Host "(It typically looks like: sk-or-v1-...)" -ForegroundColor Cyan
Write-Host "--------------------------------------------------" -ForegroundColor Cyan
$OR_KEY = Read-Host -Prompt "API Key"

if ([string]::IsNullOrWhiteSpace($OR_KEY)) {
    Write-Host "❌ Error: API key cannot be empty. Setup aborted." -ForegroundColor Red
    Exit
}

# Create local config directory and write the OpenRouter matrix
$ConfigDir = Join-Path $HOME ".claude"
if (!(Test-Path $ConfigDir)) {
    New-Item -ItemType Directory -Path $ConfigDir | Out-Null
}

$ConfigJson = @"
{
  "env": {
    "OPENROUTER_API_KEY": "$OR_KEY",
    "ANTHROPIC_BASE_URL": "https://openrouter.ai/api",
    "ANTHROPIC_AUTH_TOKEN": "$OR_KEY",
    "ANTHROPIC_API_KEY": "",
    "ANTHROPIC_MODEL": "deepseek/deepseek-v4-flash"
  }
}
"@

$ConfigFile = Join-Path $ConfigDir "settings.json"
Set-Content -Path $ConfigFile -Value $ConfigJson

Write-Host "`nSetup execution complete!" -ForegroundColor Green
Write-Host "🚀 Environment paths have been flushed and updated globally." -ForegroundColor Green
Write-Host "🤖 Active Engine: DeepSeek V4 Flash via OpenRouter" -ForegroundColor Cyan
Write-Host "--------------------------------------------------" -ForegroundColor Cyan
