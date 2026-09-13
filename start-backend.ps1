Set-Location "$PSScriptRoot\backend"
if (-not (Test-Path ".\.venv\Scripts\python.exe")) {
    py -m venv .venv
}
& .\.venv\Scripts\Activate.ps1
python -m pip install -r requirements-dev.txt
python -m uvicorn app.main:app --host 127.0.0.1 --port 8000 --reload
