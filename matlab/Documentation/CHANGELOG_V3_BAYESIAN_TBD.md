# Changelog — v3 Bayesian TBD

## الاستدلال

- إضافة likelihood بايزي مستقل لكل حساس مع marginalization لقوة الحيوية
  وعمق الدفن.
- استخدام censored Gaussian likelihood المتوافق مع قص القياس إلى `[0,1]`.
- إضافة خريطة Log-Odds وخرائط مساهمة منفصلة للرادار والحراري والصوتي.
- إضافة عتبة posterior تكيفية مبنية على median وMAD.
- إضافة NMS وتتبع احتمالي وتأكيد من ثلاث مشاهدات مستقلة.
- إبقاء `adaptiveEvidence` كخط أساس قابل للاختيار.

## سلامة المحاكاة

- فصل oracle SNR/الموثوقية/الإشارة عن حقول الاستدلال.
- حقول oracle أصبحت تبدأ بـ `diagnostic` ولا تنتقل إلى الحزمة المعالجة.
- likelihood وخريطة الانتشار لا تقرآن مواقع الضحايا أو Ground Truth أو
  خريطة `vitalSigns`.

## التشغيل والتقييم

- منع إنشاء الرسومات في `fastMode` لتحسين زمن التقييم التجميعي.
- إضافة `LocalizationMethod` و`MaximumPosteriorProbability` و
  `ConfirmedTrackCount` إلى نتائج الدفعات.
- تحديث `runAllTests` لإزالة مسارات النسخ القديمة قبل الاختبار.
- إضافة اختبارات likelihood والخريطة والقمم والمسارات وعدم تسريب الحقيقة.

## ملاحظة التحقق

أُجريت فحوصات ساكنة على بنية الملفات وتوازن كتل MATLAB في بيئة البناء.
يجب تشغيل `runBayesianTBDTests` ثم `runAllTests` داخل MATLAB لأن بيئة البناء
لا تحتوي على MATLAB Runtime.
