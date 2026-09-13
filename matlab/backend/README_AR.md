# USAR Backend v0.1 — Telemetry Consumer

هذه النسخة هي أول Backend حقيقي بين MATLAB والـDashboard.

## المسؤولية

الـBackend لا يعيد تنفيذ أي خوارزمية من MATLAB. MATLAB يبقى مصدر الحقيقة
للمحاكاة، الحساسات، Fusion، Localization، Vitality، Priority وRescue Planning.

الـBackend مسؤول فقط عن:

1. اكتشاف أحدث Mission داخل `Outputs/missions`.
2. قراءة `telemetry.jsonl` بصورة Incremental وليس من البداية في كل Request.
3. رفض أي كسر في Sequence / Mission ID / UTC / Ground-Truth boundary.
4. بناء Operational State آمن للواجهة.
5. توفير Incremental Telemetry API.
6. الإفراج عن `result.json` فقط بعد اكتمال المهمة.
7. الإفراج عن `evaluation.json` فقط بعد `MISSION_COMPLETED`.

## لماذا FastAPI؟

وثيقة Dashboard القديمة كانت تذكر Flask كاختيار مبدئي، لكنها ما زالت Draft ولم
يكن Backend قد تم تنفيذه. هذه النسخة تستخدم FastAPI لأن المشروع يحتاج الآن إلى:
typed validation، OpenAPI تلقائي، عقود API قابلة للاختبار، وتمهيد واضح لبث Live
Telemetry لاحقًا. MATLAB لا يعتمد على FastAPI ولا يعرف بوجوده.

## Endpoints

- `GET /api/v1/health`
- `GET /api/v1/mission/current/state`
- `GET /api/v1/mission/current/telemetry?after_sequence=-1&limit=250`
- `GET /api/v1/mission/current/result`
- `GET /api/v1/mission/current/evaluation`

كل endpoint يرجع envelope:

```json
{
  "success": true,
  "data": {},
  "timestamp": "2026-09-02T13:00:00.000Z",
  "version": "v1"
}
```

## Windows Setup

```powershell
cd USAR_Backend_v0_1_TelemetryConsumer_CANDIDATE

py -m venv .venv
.\.venv\Scripts\Activate.ps1

python -m pip install --upgrade pip
pip install -r requirements-dev.txt

Copy-Item .env.example .env
```

افتح `.env` وعدّل:

```env
USAR_MISSIONS_ROOT=C:\Users\TOP\Downloads\USAR_v4_1_6_LiveTelemetry_FIX1\Outputs\missions
```

ثم:

```powershell
pytest
uvicorn app.main:app --host 127.0.0.1 --port 8000 --reload
```

افتح:

- `http://127.0.0.1:8000/docs`
- `http://127.0.0.1:8000/api/v1/health`

## Live Test

شغّل MATLAB Mission في نفس النسخة التي يشير إليها `USAR_MISSIONS_ROOT`.

أثناء تشغيل MATLAB:

```text
GET /api/v1/mission/current/state
```

يجب أن يتغير `lastSequence` وموضع probe والـFusion مع تقدم المهمة.

لاستقبال الأحداث الجديدة فقط:

```text
GET /api/v1/mission/current/telemetry?after_sequence=100&limit=250
```

فتعود فقط السجلات التي sequence لها أكبر من 100.

## Ground Truth

`state` و`telemetry` لا يقرآن `evaluation.json` إطلاقًا.

`evaluation.json` غير متاح عبر API قبل `MISSION_COMPLETED`.

هذا فصل مقصود حتى لا تستطيع واجهة التشغيل معرفة Ground Truth أثناء المهمة.

## المرحلة التالية

بعد قبول Backend v0.1:
- تحديث React API adapter لفك الـresponse envelope.
- Polling خفيف أو SSE.
- فصل Provisional Tracks بصريًا عن Final Confirmed Victims.
- ربط Mission Status / Probe / Sensors / Fusion مباشرة بالـLive state.
