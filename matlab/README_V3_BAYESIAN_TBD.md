# USAR PhysicalFusion v3 — Bayesian TBD

النسخة الافتراضية تستخدم **Adaptive Multi-Sensor Bayesian Track-Before-Detect**.

## بداية سريعة

1. افتح `USAR_Project.prj` من جذر هذا المجلد.
2. شغّل `runAllTests` وتأكد من عدم وجود Failed أو Incomplete.
3. شغّل `runBatchEvaluation(1,false)` كتجربة smoke test.
4. بعد نجاحها شغّل `runBatchEvaluation(5,false)` ثم 100 سيناريو عند تثبيت
   المعاملات مسبقًا.

لتشغيل خط الأساس القديم غيّر فقط:

```matlab
config.localization.method = "adaptiveEvidence";
```

داخل `Utilities/constants.m`. أعد القيمة إلى `"bayesianTBD"` للنسخة الجديدة.

التصميم والمعادلات والقيود موثقة في
`Documentation/PHASE_3_BAYESIAN_TBD.md`.
