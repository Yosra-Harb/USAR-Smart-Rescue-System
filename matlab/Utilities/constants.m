function config = constants()
%% ============================================================
% Function Name : constants
%
% Description :
% المصدر المركزي لإعدادات التشغيل والعتبات في مشروع USAR.
% إعدادات نسخة PhysicalFusion_v4 ذات الدمج البايزي المكاني
% مع إبقاء خوارزميات v3 وv2 للمقارنة العلمية.
%% ============================================================

config = struct();

%% Runtime
config.runtime.enableDebugLogging = false;

%% Localization implementation selector
config.localization.method = "spatialBayesianFusion";
% القيم المدعومة: "spatialBayesianFusion" و"bayesianTBD"
% و"adaptiveEvidence". النسخة الجديدة هي الافتراضية.

%% Suspicion and local-search thresholds
config.suspicion.fusionScore = 0.12;
config.suspicion.vitalityIndex = 0.40;
config.suspicion.exitFusionScore = 0.05;
config.suspicion.exitVitalityIndex = 0.35;

%% Candidate-confirmation thresholds
config.detection.fusionScore = 0.28;
config.detection.confidence = 0.55;

%% Temporal clustering parameters
config.clustering.maximumHistory = 20;
config.clustering.distanceThreshold = 8;
config.clustering.minimumPoints = 3;
config.clustering.maximumClusterPoints = 10;

%% Victim-database confirmation and association parameters
config.victimDatabase.minimumTemporalStability = 0.60;
config.victimDatabase.minimumVitalityIndex = 0.45;
config.victimDatabase.minimumPriorityScore = 0.42;
config.victimDatabase.associationDistance = 3;

config.victimDatabase.duplicateMergeDistance = 3;
% دمج سجلات الضحية نفسها عندما تتقارب مواقعها ضمن ثلاث خلايا

config.victimDatabase.minimumIndependentViewDistance = 2.0;
% لا تُحسب القراءة كتأكيد مستقل جديد إلا إذا التقطها المسبار
% من موقع يبعد خليتين على الأقل عن جميع مواقع التأكيد السابقة.

%% Adaptive evidence-peak threshold (legacy v2 baseline)
config.localization.useAdaptivePeakThreshold = true;
% إبقاء خط الأساس التكيفي صالحًا للمقارنة والاختبارات الرجعية.

config.localization.minimumAdaptivePeakThreshold = ...
    config.suspicion.fusionScore;
% السماح بتجميع الإشارات الضعيفة المتكررة حتى 0.12.

config.localization.maximumAdaptivePeakThreshold = 0.40;
% منع العتبة الإحصائية من الارتفاع بلا حد في الخلفيات الصاخبة.

config.localization.backgroundMadMultiplier = 3.0;
% معامل Median Absolute Deviation المستخدم لتقدير ضوضاء الخلفية.

config.localization.minimumBackgroundSamples = 12;
% لا تُقدّر الخلفية إحصائيًا قبل توفر عدد كافٍ من الخلايا المرصودة.
%% ============================================================
% Multi-Peak Localization Parameters
%% ============================================================

config.localization.localMaximumRadius = 1;
% فحص جوار 3×3 لإثبات أن الخلية تمثل قمة محلية.

config.localization.minimumPeakProminence = ...
    0.02 * config.detection.fusionScore;
% الحد الأدنى لبروز القمة بالنسبة إلى عتبة الكشف.
% لا تُخفض عتبة الكشف، بل تمنع قمم الضجيج المسطحة.

config.localization.minimumPeakSeparation = ...
    config.victimDatabase.duplicateMergeDistance + 1;
% يجب أن تتجاوز مسافة فصل القمم مسافة دمج السجلات.
% بذلك لا تنتج الخوارزمية قمتين سيجري دمجهما لاحقًا.

config.localization.maximumPeaksPerWindow = 10;
% الحد الأعلى التصميمي لعدد القمم داخل نافذة البحث.

config.localization.candidateDistanceScale = ...
    0.5 * config.clustering.distanceThreshold;
% مقياس التوافق المكاني بين موضع القياس والقمة المرشحة.

config.localization.peakStrengthWeight = 0.50;
% وزن قوة الدليل عند اختيار القمة.

config.localization.candidateProximityWeight = 0.50;
% وزن قرب القمة من موقع القياس الحالي.

config.localization.centroidRadius = max( ...
    1, ...
    floor( ...
        config.localization.minimumPeakSeparation / 2));
% حصر المركز الموزون حول القمة المختارة حتى لا ينجذب
% إلى قمة ضحية مجاورة.

%% Bayesian Track-Before-Detect parameters
config.bayesian.priorProbability = [];
% القيمة الفارغة تعني prior مكانيًا متناثرًا يعادل فرضية واحدة موزعة
% على الشبكة، ولا تعني معرفة عدد الضحايا الحقيقي.

config.bayesian.vitalStrengthHypotheses = ...
    [0.10, 0.25, 0.45, 0.70, 0.90];
config.bayesian.vitalStrengthPrior = ...
    [0.10, 0.20, 0.30, 0.25, 0.15];

config.bayesian.burialDepthHypotheses = ...
    [0.00, 0.25, 0.50, 0.75, 1.00];
config.bayesian.burialDepthPrior = ...
    [0.12, 0.20, 0.28, 0.25, 0.15];
% تُهمّش قوة الحيوية وعمق الدفن بدل قراءتهما من Ground Truth.

config.bayesian.maximumUpdateRangeScale = 1.0;
config.bayesian.informationGain = 0.35;
config.bayesian.sensorDependenceDiscount = 0.60;
config.bayesian.localEvidenceRetention = 0.985;
config.bayesian.singleSensorLogBayesFactorLimit = 3.0;
config.bayesian.maximumAbsoluteLogOdds = 14.0;
% تخفيض المعلومات والحدود السابقة تمنع عدّ القياسات المترابطة
% على أنها تجارب مستقلة تمامًا.

config.bayesian.minimumPosteriorProbability = 0.55;
config.bayesian.confirmationProbability = 0.82;
config.bayesian.minimumObservationCount = 3;
config.bayesian.backgroundSigmaMultiplier = 3.0;
config.bayesian.minimumPeakProminence = 0.04;
config.bayesian.localMaximumRadius = 1;
config.bayesian.minimumPeakSeparation = 4;
config.bayesian.maximumPeaksPerUpdate = 10;

config.bayesian.trackAssociationDistance = 4.0;
config.bayesian.trackDeletionProbability = 0.05;
config.bayesian.trackMissedUpdateRetention = 0.9999;
% الضحايا ساكنون في هذه المحاكاة؛ لذلك يحتفظ المسار المؤكد بذاكرة
% طويلة، بينما يبقى حذف المسار الضعيف ممكنًا على المهمات الطويلة.
config.bayesian.minimumIndependentViewDistance = 2.0;
config.bayesian.minimumIndependentViews = 3;
% لا يصبح المسار مؤكدًا قبل ثلاث زوايا مشاهدة مستقلة مكانيًا.

%% Spatial Bayesian multi-sensor measurement-set parameters
config.spatialBayesian.maximumUpdateRangeScale = 1.10;
config.spatialBayesian.evidenceRetention = 0.992;
config.spatialBayesian.informationGain = 0.60;
config.spatialBayesian.intensityEvidenceWeight = 0.15;
% إبقاء مساهمة منخفضة من نموذج الشدة v3 للمساعدة عندما تكون القياسات
% الزاوية متقطعة، مع بقاء الهندسة المكانية هي المصدر الأساسي.
config.spatialBayesian.maximumSensorLogBayesFactor = 4.5;
config.spatialBayesian.maximumAbsoluteLogOdds = 16;
config.spatialBayesian.minimumPosteriorProbability = 0.62;
config.spatialBayesian.confirmationProbability = 0.88;
config.spatialBayesian.minimumObservationCount = 2;
config.spatialBayesian.backgroundSigmaMultiplier = 3.5;
config.spatialBayesian.minimumPeakProminence = 0.035;
config.spatialBayesian.minimumLogOddsPeakProminence = 0.35;
% عند الاحتمالات القريبة من الواحد يضغط التحويل اللوجستي الفروق
% المكانية حتى تبدو القمم المتجاورة متساوية. لذلك يستخدم الإصدار
% المكاني فرق Log-Odds، حيث تعني 0.35 نسبة أرجحية محلية تقارب 1.42.
config.spatialBayesian.minimumPlateauSupportProminence = 0.10;
% إذا بلغت عدة خلايا حد Log-Odds نفسه، لا تكفي قيمة posterior لاختيار
% القمة. تُقبل خلية الهضبة فقط عندما يكون دعمها الموزون أعلى بصورة
% فريدة وبفارق نسبي لا يقل عن عشرة بالمئة من الجوار.
config.spatialBayesian.localMaximumRadius = 1;
config.spatialBayesian.minimumPeakSeparation = 4;
config.spatialBayesian.maximumPeaksPerUpdate = 10;
config.spatialBayesian.rangedMeasurementMinimumConfidence = 0.10;
config.spatialBayesian.rangedMeasurementMinimumStrength = 0.02;
config.spatialBayesian.rangedMeasurementMinimumPeriodicity = 0.03;
% القياس المباشر لا يصبح فرضية هدف إلا إذا حمل علامة دورية حيوية.
% clutter المولد لا يحمل دورية، بينما يبقى مسار الخريطة متاحًا
% للإشارات الحقيقية الضعيفة التي لا تجتاز هذه البوابة في تحديث معين.
config.spatialBayesian.rangedMeasurementConfidenceWeight = 0.35;
config.spatialBayesian.rangedMeasurementStrengthWeight = 0.20;
config.spatialBayesian.rangedMeasurementPeriodicityWeight = 0.45;
config.spatialBayesian.rangedMeasurementProbabilityFloor = 0.58;
config.spatialBayesian.rangedMeasurementProbabilityScale = 0.40;
config.spatialBayesian.rangedMeasurementProbabilityCeiling = 0.98;
config.spatialBayesian.rangedMeasurementMinimumUncertaintyRadius = 0.50;
config.spatialBayesian.rangedMeasurementMaximumUncertaintyRadius = 3.00;
config.spatialBayesian.rangedMeasurementTrackProcessNoiseVariance = 0.04;
% الضحايا ساكنون، لكن تباينًا صغيرًا يمنع مرشح الموضع من أن يصبح
% واثقًا بصورة مفرطة أمام أخطاء نموذج المدى والزاوية.
config.spatialBayesian.rangedMeasurementSameUpdateMergeDistance = 2.50;
% قياسان راداريان في التحديث نفسه ضمن 2.5 خلية يمثلان غالبًا المصدر
% نفسه. الحد أصغر بكثير من فصل الضحايا التصميمي البالغ 6 خلايا.
config.spatialBayesian.rangedMeasurementMapSuppressionDistance = 4.00;
% يمنع إنشاء مسار خريطي مكرر قرب القياس المباشر، دون حجب ضحية أخرى
% عند الحد الأدنى التصميمي لفصل الضحايا.
config.spatialBayesian.trackAssociationDistance = 3.5;
config.spatialBayesian.trackConsolidationDistance = 3.5;
% المسارات المؤكدة الأقرب من قدرة الفصل المكاني للنظام تُعامل كعنقود
% واحد في التقرير النهائي. القيمة تبقى أصغر من minimumPeakSeparation.
config.spatialBayesian.trackConsolidationMaximumEdgeDistance = 4.8;
config.spatialBayesian.trackConsolidationMaximumMahalanobisDistance = 2.0;
% يسمح بربط فجوة مكانية أكبر قليلًا فقط عندما تتداخل توزيعات عدم
% اليقين للمسارين. المسافة الهندسية وحدها لا تكفي خارج الحد الأساسي.
config.spatialBayesian.trackConsolidationMaximumClusterDiameter = 5.5;
% يمنع single-link chaining: لا ينضم مسار جديد إذا جعل المسافة بين
% أبعد عضوين في العنقود أكبر من 5.5 خلية. هذا الحد أدنى من مسافة
% الفصل التصميمية بين ضحيتين في مولد السيناريو (6 خلايا).
config.spatialBayesian.trackFragmentAssociationDistance = 5.5;
% بعد تكوين العناقيد المدمجة، يمكن إعادة شظية مؤلفة من مسار واحد
% إلى مركز عنقود مدعوم إذا بقيت المسافة دون قدرة الفصل التصميمية.
config.spatialBayesian.trackFragmentAssociationAmbiguityMargin = 0.75;
% لا تُمتص الشظية عندما يكون الفرق بين أقرب عنقودين مدعومين أقل
% من 0.75 خلية؛ عندها تبقى مستقلة بدل اتخاذ قرار مكاني ملتبس.
config.spatialBayesian.trackFragmentMinimumCoreMembers = 2;
% لا يُعد العنقود مرساة لامتصاص الشظايا ما لم يدعمه مساران خامان.
% الشظايا الممتصة لا تصبح مراسي ولا تنقل الاتصال إلى عناقيد أخرى.
config.spatialBayesian.trackBasinMaximumValleyDrop = 4.0;
% هبوط مقداره أربع وحدات Log-Odds يعني تغيرًا في نسبة الأرجحية
% يقارب exp(4)=54.6. ما دون ذلك يعامل كحوض دليل متصل، لا كفاصل قوي.
config.spatialBayesian.trackBasinMaximumPeakDistance = 8.0;
% يمنع دمج أحواض متباعدة حتى لو كان خط الدليل بينهما مرتفعًا بصورة
% غير معتادة. الدمج يستخدم complete-link بين جميع أزواج القمم.
config.spatialBayesian.trackBasinPeakSearchRadius = 2;
% البحث عن قمة الحوض قرب مركز العنقود ضمن نافذة 5×5.
config.spatialBayesian.trackBasinMinimumPeakLogOdds = log( ...
    config.spatialBayesian.confirmationProbability / ...
    (1-config.spatialBayesian.confirmationProbability));
% لا يُدمج حوض اعتمادًا على خريطة ضعيفة أو غير مهيأة؛ يجب أن تبلغ
% كل قمة على الأقل Log-Odds المقابل لاحتمال تأكيد المسار.
config.spatialBayesian.trackBasinLineSamplesPerCell = 5;
% خمس عينات خطية لكل خلية تمنع تجاوز وادٍ ضيق بين قمتين.
config.spatialBayesian.trackBasinMinimumSupportRetention = 0.90;
% لا يكفي اتصال Log-Odds المشبع: يجب ألا ينخفض الدعم الموزون على
% الخط بين القمتين عن 90% من دعم أضعف القمتين.
config.spatialBayesian.weakIsolatedBasinMinimumLogOddsGap = 6.0;
% لا يعد الحوض ضعيفًا إلا إذا كانت نسبة أرجحيته أقل من الأقوى
% بمعامل exp(6) تقريبًا، مع تحقق الشروط المستقلة التالية أيضًا.
config.spatialBayesian.weakIsolatedBasinMaximumRelativeSupport = 0.20;
% يشترط أن يكون دعم الحوض الضعيف 20% أو أقل من أقوى حوض في المهمة.
config.spatialBayesian.weakIsolatedBasinMaximumRawTracks = 1;
% لا ترفض القاعدة عنقودًا تدعمه عدة مسارات خام، ولا تعمل أصلًا عندما
% يكون الحوض هو الكشف الوحيد؛ وهذا يحمي حالات الدفن العميق المنفردة.
config.spatialBayesian.weakMapBasinMaximumRawTracks = 2;
config.spatialBayesian.weakMapBasinMinimumLogOddsGap = 8.0;
config.spatialBayesian.weakMapBasinMaximumRelativeSupport = 0.10;
% حوض الخريطة غير المدعوم بقياس UWB قد ينقسم إلى مسارين خامين بسبب
% هضبة محلية. يسمح المستوى الثاني برفضه فقط عندما تجتمع ثلاثة شروط
% أشد: مساران على الأكثر، وفجوة Log-Odds كبيرة، ودعم لا يتجاوز 10%.
config.spatialBayesian.trackDeletionProbability = 0.08;
config.spatialBayesian.trackMissedUpdateRetention = 0.985;
config.spatialBayesian.minimumIndependentViewDistance = 2.5;
config.spatialBayesian.minimumIndependentViews = 3;
config.spatialBayesian.minimumResolvedRangedViews = 3;
config.spatialBayesian.resolvedSourceMinimumSeparation = 5.25;
% لا يجوز لسطح Log-Odds متصل أن يدمج مصدرين إذا امتلك كل منهما
% ثلاث مشاهدات UWB مستقلة وكان الفصل بين مركزيهما 5.25 خلية أو أكثر.
% هذا أقل من فصل مولد الضحايا (6) وأكبر من بوابة ارتباط المسار (3.5).
config.spatialBayesian.resolvedSourceSoftPeakSeparation = 4.25;
config.spatialBayesian.resolvedSourceMaximumBridgeRetention = 0.98;
% الفصل الأقصر من 5.25 يحتاج دليلًا ثانيًا: هبوطًا فعليًا في سطح
% الدعم بين القمتين. يمنع ذلك اعتبار انحرافين للمصدر نفسه ضحيتين،
% مع حماية مصدرين حقيقيين تقاربت قممهما بسبب ضوضاء القياس.
config.spatialBayesian.unmatchedRangedRecordRescueMinimumViews = 3;
config.spatialBayesian.unmatchedRangedRecordRescueMinimumAssociations = 3;
config.spatialBayesian.unmatchedRangedRecordRescueMinimumLogOdds = 8.0;
config.spatialBayesian.unmatchedRangedRecordRescueMinimumSupport = 100;
config.spatialBayesian.unmatchedRangedRecordRescueMinimumSeparation = 5.5;
config.spatialBayesian.unmatchedRangedRecordRescuePeakSearchRadius = 2;
% إنقاذ سجل بلا مسار مؤكد لا يعتمد على السجل وحده: يجب أن يكون مصدره
% UWB، متعدد المشاهدات، مدعومًا بخريطة قوية، ومنفصلًا عن جميع المسارات
% المؤكدة والكشوف المقبولة. هذه بوابة تقاطع أدلة وليست تخفيفًا عامًا.
config.spatialBayesian.trackConditionedMinimumLogBayesFactor = 0.10;
% لا تُصان المسارات المؤقتة من posterior تاريخي وحده. يجب أن يحمل
% القياس الحالي داخل بوابة المسار دليلًا موجبًا واضحًا أيضًا.
config.spatialBayesian.minimumCurrentPeakLogBayesFactor = 0.10;
% لا تتحول خلية ذات posterior تاريخي مرتفع إلى قمة جديدة ما لم يدعمها
% القياس الحالي بدليل موجب. يمنع ذلك عد الذاكرة كمشاهدة مستقلة جديدة.
config.spatialBayesian.recordAssociationUncertaintyScale = 1.0;
config.spatialBayesian.maximumRecordAssociationDistance = 7.0;
% مطابقة سجل الحيوية بالمسار المؤكد تستخدم عدم يقين المسار مع حد أعلى
% محافظ، بدل رفض السجل بسبب تجاوز بسيط لمسافة الارتباط الثابتة.
config.spatialBayesian.minimumDetectionProbability = 0.03;
config.spatialBayesian.maximumDetectionProbability = 0.95;
config.spatialBayesian.clutterDensityFloor = 1e-5;
% القياسات المكانـية تستخدم مجموعات anonymous range/bearing مع نموذج
% clutter صريح؛ لا تدخل مواقع الضحايا الحقيقية إلى هذه المعادلات.

%% Rescue planning and operational priority
config.rescuePlanning.goalAccessRadius = 2;
config.rescuePlanning.allowDiagonalMovement = true;
config.rescuePlanning.debrisWeight = 2.0;
config.rescuePlanning.riskWeight = 3.0;
config.rescuePlanning.inaccessibilityWeight = 2.5;
config.rescuePlanning.maximumExpandedNodes = 20000;
config.rescuePlanning.proximityScale = 25;

config.rescuePriority.severityWeight = 0.50;
config.rescuePriority.reachabilityWeight = 0.20;
config.rescuePriority.proximityWeight = 0.12;
config.rescuePriority.accessibilityWeight = 0.10;
config.rescuePriority.safetyWeight = 0.08;
config.rescuePriority.criticalReachabilityInteraction = 0.30;
% الخطر الطبي هو العامل الأكبر، وتُعطى أفضلية إضافية للضحية الحرجة
% عندما يكون الوصول إليها ممكنًا وآمنًا نسبيًا.

%% Adaptive local-search confirmation controls
config.localSearch.completedCenterExclusionDistance = 4.0;
% منع إعادة تشغيل دورة بحث محلي كاملة حول مركز سبق استكماله.
% القيمة أصغر من الحد الأدنى لتباعد الضحايا الحقيقيين (6 خلايا).

config.localSearch.maximumStoredCompletedCenters = 50;
% منع نمو سجل مراكز البحث المكتملة دون حد أثناء المهمات الطويلة.

%% Evaluation and reporting parameters
config.evaluation.matchingDistance = 10;
config.reporting.minimumIndependentViewCount = 3;
% يتطلب التقرير النهائي ثلاث مشاهدات مستقلة مكانيًا على الأقل.

config.reporting.minimumDetectionCount = ...
    config.reporting.minimumIndependentViewCount;
% اسم قديم محفوظ مؤقتًا للتوافق مع الملفات الخارجية.
%% Spatial Vital-Sign Field Configuration
config.environment.vitalFieldSigma = 6.2;
% قيمة معايرة تمنح نصف قطر كشف يقارب ست خلايا مع العتبات الحالية،
% وتبقى أضيق بكثير من القيمة القديمة غير الواقعية 15
end
