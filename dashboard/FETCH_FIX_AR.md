# إصلاح اتصال المتصفح بالـBackend — v3.2

تم الإبقاء على Vite Proxy كما هو (`/api` -> `http://127.0.0.1:8000`).

الإصلاح الجديد داخل `src/data/apiMissionDataSource.ts`:

- ربط `globalThis.fetch` صراحةً باستخدام `bind(globalThis)` لمنع أخطاء browser invocation المحتملة.
- إضافة تفاصيل السبب الأصلي إلى رسالة الاتصال إذا فشل `fetch`، بدل إخفاء السبب خلف رسالة عامة.
- لا تغيير على API contract أو تصميم الـDashboard أو بيانات MATLAB.

بعد استبدال النسخة، يجب إيقاف Vite وتشغيل `npm run dev` من جديد.
