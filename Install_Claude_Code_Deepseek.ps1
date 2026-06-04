# Ensure the script runs with high color feedback
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "   Claude Code + DeepSeek V4 Flash Setup" -ForegroundColor Cyan
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

# 3. Inject and fix the environment variable path permanently
Write-Host "`n[3/4] Registering Claude binary PATH environment variable..." -ForegroundColor Yellow
$TargetBinPath = Join-Path $HOME ".local\bin"

# Read current User PATH array
$UserPath = [System.Environment]::GetEnvironmentVariable("Path", "User")

# Check if the path is already in the User PATH string; if not, append it
if ($UserPath -notlike "*$TargetBinPath*") {
    # Combine nicely, ensuring a trailing semi-colon match isn't duplicated
    $NewUserPath = if ($UserPath.EndsWith(";")) { "$UserPath$TargetBinPath" } else { "$UserPath;$TargetBinPath" }
    
    # Save back to the permanent Windows User Environment Variables Registry
    [System.Environment]::SetEnvironmentVariable("Path", $NewUserPath, "User")
    Write-Host "Successfully appended $TargetBinPath to your User PATH environment variable." -ForegroundColor Green
} else {
    Write-Host "Environment variable target path already exists in User PATH." -ForegroundColor Green
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
Write-Host "🚀 Environment paths have been flushed and updated." -ForegroundColor Green
Write-Host "🤖 Active Engine: DeepSeek V4 Flash via OpenRouter" -ForegroundColor Cyan
Write-Host "--------------------------------------------------" -ForegroundColor Cyan