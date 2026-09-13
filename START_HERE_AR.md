# USAR End-to-End v2 — Scenario Control

هذه النسخة تضيف **تشغيل MATLAB من داخل الـDashboard**.

## الجديد

- زر **Fixed Runs** في Mission Operations.
- زر **Generate Scenario** في Mission Operations.
- صفحة Scenario Center فعلية.
- 6 تشغيلات ثابتة: Ideal / Dense Debris / High Noise / Deep Burial / Multiple Victims / Weak Vital Signs.
- مولد Custom Scenario بالقيم الفعالة فعليًا في MATLAB Contract v1.
- زر **Start Generated Mission** يشغل MATLAB من الـBackend؛ لا حاجة لتنفيذ `runScenarioRequest` يدويًا في Command Window.
- Backend endpoint جديد: `POST /api/v1/scenario/run`.
- Backend endpoint جديد: `GET /api/v1/scenario/run/current`.
- MATLAB entrypoint جديد: `Integration/runDashboardScenarioRequest.m`.

## التدفق

Dashboard → POST scenario request → FastAPI ScenarioRunManager → MATLAB `-batch` → `runDashboardScenarioRequest.m` → `runScenarioRequest` → `telemetry.jsonl` → Backend consumer → Dashboard live polling.

## التشغيل

### Terminal 1 — Backend

```powershell
cd backend
py -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -r requirements-dev.txt
python -m uvicorn app.main:app --host 127.0.0.1 --port 8000 --reload
```

### Terminal 2 — Dashboard

```powershell
cd dashboard
npm install
npm run dev
```

ثم افتحي:

`http://127.0.0.1:5173`

## MATLAB executable

الـBackend يحاول بالترتيب:

1. `USAR_MATLAB_EXECUTABLE` إذا كان مضبوطًا.
2. الأمر `matlab` إذا كان في PATH.
3. أحدث `matlab.exe` يجده تحت `C:\Program Files\MATLAB\R*\bin\matlab.exe`.

إذا فشل، ضعي المسار الحقيقي في `backend/.env`.

## ملاحظة علمية

في Custom Scenario نعرض فقط: victim count, debris density, noise, burial depth, vital strength, random seed. Accessibility / risk / obstacle density ما زالت خصائص يولدها MATLAB وليست controls مستقلة فعالة في Contract v1.
