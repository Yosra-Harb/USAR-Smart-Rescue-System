# USAR Dashboard v3 — Dark + Real Data

هذه النسخة تربط واجهة React مباشرة بباك إند USAR FastAPI الحالي، ولا تستخدم Mock Data افتراضيًا.

## مسار البيانات

MATLAB → `telemetry.jsonl` → FastAPI Backend → REST API → `ApiMissionDataSource` → React State → Dashboard Components.

## ما تم ربطه فعليًا

- حالة المهمة والوقت وSequence الحالي من `/mission/current/state`.
- السجلات الجديدة Incremental من `/mission/current/telemetry`.
- موقع المسبار الحالي ومساره من Telemetry الحقيقية.
- Live sensor readings: UWB Radar / Thermal / Acoustic.
- Fusion score / confidence / adaptive weights.
- Provisional victim tracks أثناء التشغيل.
- Final victims وRescue Rank وReachability وRecommended Route بعد انتهاء المهمة.
- Post-mission Precision / Recall / F1 / CSI / TP / FP / FN / Localization Error من `/mission/current/evaluation`.
- Ground Truth لا يظهر إلا بعد اكتمال المهمة ونجاح release policy من الباك إند.

## التصميم

الواجهة أصبحت Dark Operations Theme بالكامل. اللون الأبيض لم يعد خلفية التشغيل الأساسية. الخريطة مضبوطة حاليًا على شبكة MATLAB ذات 50×50 خلية، وتعرض Probe Path حيًا.

## التشغيل على Windows

### 1. شغّل الباك إند أولًا

داخل مجلد الباك إند:

```powershell
.\.venv\Scripts\Activate.ps1
uvicorn app.main:app --host 127.0.0.1 --port 8000 --reload
```

وتأكد أن:

```text
http://127.0.0.1:8000/api/v1/health
```

يعمل.

### 2. شغّل الداشبورد

داخل هذا المجلد:

```powershell
npm install
npm run dev
```

ثم افتح:

```text
http://localhost:5173
```

## إعداد عنوان الباك إند

النسخة جاهزة افتراضيًا على:

```env
VITE_USAR_API_BASE_URL=http://127.0.0.1:8000/api/v1
```

يمكن تغييره من ملف `.env`.

## Polling

الواجهة تطلب Snapshot جديدًا كل 750ms، لكن `ApiMissionDataSource` لا يعيد تنزيل Telemetry القديمة. يحتفظ بآخر `sequence` ويطلب فقط السجلات الجديدة على صفحات حجمها 500 سجل.

## ملاحظات مهمة

- أثناء RUNNING تظهر `VICTIM_TRACK_CREATED` على أنها **Provisional Tracks** وليست ضحايا نهائية.
- عند `MISSION_COMPLETED` ينتقل العرض إلى Final Victims من `result.json`.
- أي حقل غير موجود فعلًا في MATLAB لا يتم اختراعه في الواجهة؛ يظهر `—` أو Pending بدل Mock values.
- لم نعد نعرض Assigned Team أو ETA وهميين لأن الباك إند الحالي لا يرسل هذه المعلومات.

## ملاحظة v1.1: Same-Origin Proxy
هذه النسخة تستخدم `VITE_USAR_API_BASE_URL=/api/v1` وVite proxy إلى `http://127.0.0.1:8000` لتجنب مشاكل CORS/loopback المحلية. بعد أي تعديل في `.env` أو `vite.config.ts` أعد تشغيل Vite.
