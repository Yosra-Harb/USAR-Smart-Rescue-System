# Phase 3: Adaptive Multi-Sensor Bayesian Track-Before-Detect

## الهدف

تستبدل هذه المرحلة تحويل `Fusion Score` إلى خريطة مكانية مباشرة بنموذج
احتمالي يقيّم كل خلية مرشحة وفق القياسات الثلاثة. الخوارزمية القديمة ما زالت
متاحة كخط أساس باسم `adaptiveEvidence`، بينما الإعداد الافتراضي هو
`bayesianTBD` في `Utilities/constants.m`.

## فرضيات الاحتمال

لكل حساس \(k\) وخلية مرشحة \(x\):

```text
H0(x): لا توجد ضحية في الخلية x
H1(x): توجد ضحية في x مع قوة حيوية وعمق دفن مجهولين
```

يُحسب:

```text
LBF_k(x) = log p(y_k | H1(x)) - log p(y_k | H0(x))
```

لا تُقرأ قوة الحيوية أو عمق الدفن الحقيقيان. بدلًا من ذلك يُهمّشان على شبكة
فرضيات معرفة في `constants.m`:

```text
p(y | H1) = sum_v sum_b p(y | v,b,H1) p(v) p(b)
```

الحساس الصوتي يستخدم mixture إضافيًا بين النشاط المستمر الضعيف والحدث
المتقطع. ويستخدم likelihood توزيع Gaussian censored عند الصفر والواحد لأن
مولد القياس يقص القراءات إلى المجال `[0,1]`.

## تحديث الخريطة

```text
logOdds_t(x) = priorLogOdds
             + retention * (logOdds_(t-1)(x) - priorLogOdds)
             + informationGain * dependenceDiscount
               * sum_k reliability_k * LBF_k(x)
```

- `reliability_k` تعتمد على معلومات المستقبل القابلة للملاحظة فقط.
- `informationGain` و`dependenceDiscount` يمنعان المبالغة في عدّ القياسات
  المترابطة زمنيًا أو بين الحساسات.
- تُحفظ مساهمة كل حساس في خريطة منفصلة لدراسات ablation وشرح القرار.

## القمم والمسارات

1. تُستخرج القمم من posterior بعتبة تكيفية مبنية على median وMAD.
2. تُطبق Non-Maximum Suppression لمنع تكرار القمة نفسها.
3. تُربط القمم بمسارات مكانية بأقرب جار ضمن بوابة محددة.
4. لا يصبح المسار `CONFIRMED` قبل تجاوز posterior المطلوب والحصول على ثلاث
   مشاهدات مستقلة مكانيًا.
5. التقرير النهائي يقبل المسارات المؤكدة فقط، ولا يستخدم Ground Truth في
   الدمج أو التصفية. Ground Truth يبقى محصورًا في مولد السيناريو والتقييم.

## منع تسريب الحقيقة المرجعية

المسار الاستدلالي لا يستخدم:

- `scenario.victims`
- `scenario.groundTruth`
- `environment.vitalSigns`
- `diagnostic*OracleReliability`
- `diagnostic*SignalComponent`

الدالة `bayesianPropagationContext` تقرأ فقط خرائط الركام والتوهين والضوضاء
والعوائق على المسار بين المسبار والخلية المرشحة.

## التشغيل والاختبار

بعد فتح `USAR_Project.prj` نفّذ:

```matlab
restoredefaultpath;
projectRoot = fileparts(which("USAR_Project.prj"));
addpath(fullfile(projectRoot,"Main"),"-begin");
setupProjectPaths;
addpath(fullfile(projectRoot,"Tests"),"-end");
results = runAllTests;
```

ثم فحص سيناريو واحد:

```matlab
[trialTable, rawResults] = runBatchEvaluation(1,false);
disp(trialTable(:,["ScenarioType","TP","FP","FN", ...
    "F1Score","LocalizationMeanError"]));
```

وبعد نجاحه شغّل بذورًا غير مستخدمة في الضبط:

```matlab
[validationTable, validationRawResults] = runBatchEvaluation(5,false);
scenarioAverages = groupsummary(validationTable, ...
    "ScenarioType","mean", ...
    ["Precision","Recall","F1Score","LocalizationMeanError"]);
disp(scenarioAverages);
```

## حدود الادعاء العلمي

هذه خوارزمية محاكاة قابلة للدفاع من حيث فصل الحقيقة المرجعية، وصياغة
likelihood، والتراكم الاحتمالي، والتأكيد المستقل. لكنها ليست بديلًا عن معايرة
جهاز حقيقي أو محاكاة waveform. لا يجوز وصف القيم العددية الحالية بأنها
معايير لأجهزة إنقاذ عالمية قبل تحليل الحساسية، واختبار بذور غير مرئية،
ومعايرة بيانات حقيقية أو بيانات تجريبية موثقة.
