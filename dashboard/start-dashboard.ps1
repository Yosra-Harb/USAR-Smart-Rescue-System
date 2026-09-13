$ErrorActionPreference = "Stop"
Write-Host "USAR Dashboard v3 - Dark Real Data" -ForegroundColor Cyan
if (-not (Test-Path "node_modules")) {
    Write-Host "Installing npm dependencies..." -ForegroundColor Yellow
    npm install
}
npm run dev
