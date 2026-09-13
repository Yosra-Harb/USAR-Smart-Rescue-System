# USAR End-to-End v2.1 — تكامل مسارات الإنقاذ (نسخة مرشحة)

هذه نسخة منفصلة مشتقة من `USAR_EndToEnd_v2_ScenarioControl`، أُدمجت فيها ملفات `USAR_RouteVisualization_v2_1_PATCH` مباشرة في مجلدي `dashboard` و`matlab`. النسختان الأصليتان لم تتغيرا. **لا تُشغّل `APPLY_ROUTE_PATCH.ps1` على هذه الحزمة**؛ التعديل مُطبّق بالفعل، والسكربت القديم يستهدف هيكل v1 باسم مجلد مختلف.

## ما الذي تغيّر؟

- يصدّر MATLAB المسارين `recommendedRoute` و`shortestRoute` ونقاطهما لكل ضحية نهائية ضمن `result.json` بالإصدار `1.1`، مع عوائق الخريطة التشغيلية دون Ground Truth.
- تقرأ الواجهة هندسة المسار، وترسمه في الخريطة، وتتيح الاختيار بين المسار الموصى به والأقصر، وتعرض نقاط الانعطاف. الأطوال **بوحدات الشبكة** لا بالأمتار.
- بقي تشغيل السيناريوهات من `Scenario Center` وتدفق الـtelemetry عبر الـBackend كما في v2؛ ملفات إعدادات المستخدم الأصلية غير مضمّنة في الحزمة.

## ما تحقق هنا

- اجتاز TypeScript فحص `tsc -b` بعد الدمج (صفر أخطاء).
- اجتازت ملفات Backend فحص بناء بايثون `compileall` (من دون تشغيل التطبيق).
- **لم** يُشغّل `npm run build` كاملاً لأن الاعتماديات المتاحة محليًا أصلًا مبنية لويندوز، ولم تُشغّل `pytest` لأنها غير مثبتة هنا، ولم تُشغّل اختبارات MATLAB أو مهمة فعلية لأن MATLAB غير متاح في بيئة الإعداد. لذلك هذه **نسخة مرشحة** وليست نقطة تجميد معتمدة.

## اختبار القبول على Windows / MATLAB R2024a

1. فكّي الحزمة في مجلد جديد، ولا تدمجيها فوق مشروعك العامل قبل نجاح الاختبارات.
2. انسخي `backend/.env.example` إلى `backend/.env` ثم ضعي المسارين الحقيقيين لـ `USAR_MISSIONS_ROOT` و`USAR_MATLAB_PROJECT_ROOT` في جهازك. إذا لم يجد النظام MATLAB، حددي `USAR_MATLAB_EXECUTABLE` إلى `matlab.exe` الخاص بـR2024a.
3. من MATLAB، اجعلي مجلد `matlab` هو Current Folder، ونفذي `addpath(fullfile(pwd,'Main')); setupProjectPaths; runAllTests`. احتفظي بعدد الاختبارات، والإخفاقات إن وجدت؛ لا نفترض مسبقًا أن العدد القديم 154 بقي نفسه بعد إضافة اختبارات المسار.
4. في Terminal من `backend` نفذي: `py -m venv .venv` ثم `.\.venv\Scripts\Activate.ps1` ثم `python -m pip install -r requirements-dev.txt` و`python -m pytest -q` و`python -m uvicorn app.main:app --host 127.0.0.1 --port 8000`.
5. في Terminal ثانٍ من `dashboard` نفذي `npm ci` ثم `npm run build` ثم `npm run dev`.
6. افتحي صفحة Scenario Center، وشغلي مهمة **جديدة**؛ بيانات `result.json` القديمة لا تتضمن `shortestRoute` و`operationalMap`. بعد اكتمالها، اختاري ضحية واختبري تبديل Recommended / Shortest، وظهور خط المسار والعوائق، وعدم عرض Ground Truth أثناء المهمة.

إن لم يظهر المسار، افحصي أولاً `result.json`: يجب أن تكون `schemaVersion` مساوية لـ`1.1` وأن تحتوي الضحية على `recommendedRoute.path` و`shortestRoute.path`. ظهور `reachable=false` أو مسار فارغ يبرر حالة Route unavailable ولا يعني بحد ذاته مشكلة عرض.
