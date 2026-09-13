function tests = testPhase1Localization
%% ============================================================
% Function Name : testPhase1Localization
%
% Description :
% اختبارات المرحلة الأولى الخاصة بخريطة الأدلة
% وتحديد الموقع باستخدام القمة والمركز الموزون.
%% ============================================================

tests = functiontests(localfunctions);
% تحويل الدوال المحلية إلى اختبارات MATLAB

end

%% ============================================================
% Test Setup
%% ============================================================

function setupOnce(testCase)

testsFolder = fileparts(mfilename('fullpath'));
% تحديد موقع مجلد الاختبارات

projectRoot = fileparts(testsFolder);
% تحديد المجلد الرئيسي للمشروع

addpath(fullfile(projectRoot, 'Main'), '-end');
% إضافة مجلد Main مؤقتًا للوصول إلى setupProjectPaths

resolvedRoot = setupProjectPaths();
% إضافة مسارات المشروع المعتمدة

testCase.TestData.projectRoot = resolvedRoot;
% حفظ مسار المشروع داخل بيانات الاختبار

end

%% ============================================================
% Test 1: Evidence Map Uses Environment Size
%% ============================================================

function testEvidenceMapUsesEnvironmentSize(testCase)

probe = struct();
% إنشاء مسبار تجريبي

probe.visitedCells = false(12,18);
% إنشاء بيئة غير ثابتة الحجم للتأكد من عدم استخدام 50×50

probe.memory = probeMemory();
% إنشاء ذاكرة المسبار

fusionPacket = struct( ...
    'probePosition', [6 9], ...
    'fusionScore', 0.80, ...
    'confidence', 0.90);
% إنشاء قراءة دمج تجريبية

probe = updateEvidenceMap( ...
    probe, ...
    fusionPacket);
% تحديث خريطة الأدلة

verifySize( ...
    testCase, ...
    probe.memory.localizationState.evidenceMap, ...
    [12 18]);
% التأكد أن الخريطة تطابق حجم البيئة الحقيقي

end

%% ============================================================
% Test 2: Repeated Visits Do Not Inflate Evidence
%% ============================================================

function testRepeatedVisitsDoNotInflateEvidence(testCase)

probe = struct();
% إنشاء مسبار تجريبي

probe.visitedCells = false(15,15);
% إنشاء بيئة اختبار

probe.memory = probeMemory();
% إنشاء ذاكرة جديدة

fusionPacket = struct( ...
    'probePosition', [8 8], ...
    'fusionScore', 0.75, ...
    'confidence', 0.90);
% إنشاء قراءة ثابتة لتكرارها

probe = updateEvidenceMap( ...
    probe, ...
    fusionPacket);
% إضافة القراءة للمرة الأولى

firstValue = ...
    probe.memory.localizationState.evidenceMap(8,8);
% حفظ قيمة مركز الخريطة بعد القراءة الأولى

for repetitionIndex = 1:5

    probe = updateEvidenceMap( ...
        probe, ...
        fusionPacket);
    % تكرار القراءة نفسها خمس مرات

end

repeatedValue = ...
    probe.memory.localizationState.evidenceMap(8,8);
% قراءة القيمة بعد تكرار الزيارة

verifyEqual( ...
    testCase, ...
    repeatedValue, ...
    firstValue, ...
    'AbsTol', 1e-12);
% التأكد أن تكرار الزيارة لم يضخم قيمة الدليل

verifyEqual( ...
    testCase, ...
    repeatedValue, ...
    fusionPacket.fusionScore, ...
    'AbsTol', 1e-12);
% التأكد أن الخريطة تحتفظ بمتوسط الدليل الصحيح

end

%% ============================================================
% Test 3: Reliable Evidence Peak Is Localized
%% ============================================================

function testReliableEvidencePeakIsLocalized(testCase)
localizationState = createSyntheticLocalizationState();
% إنشاء حالة توطين اصطناعية

localizationState.evidenceMap( ...
    11:13, ...
    12:14) = 0.80;
% إنشاء منطقة أدلة مرتفعة حول الموقع المتوقع

localizationState.evidenceMap(12,13) = 0.90;
% إنشاء القمة الرئيسية عند [12,13]

localizationState.observationCount( ...
    11:13, ...
    12:14) = 5;
% توفير عدد كافٍ من المشاهدات الداعمة

candidate = struct( ...
    'isVictim', true, ...
    'position', [12 13], ...
    'score', 0.90, ...
    'confidence', 0.85);
% إنشاء مرشح ضحية صالح

[estimatedLocation, localizationState] = ...
    estimateLocationFromEvidenceMap( ...
        localizationState, ...
        candidate);
% تنفيذ تحديد الموقع من خريطة الأدلة

verifyTrue( ...
    testCase, ...
    estimatedLocation.isDetected);
% التأكد من اعتماد الاكتشاف

verifyEqual( ...
    testCase, ...
    estimatedLocation.position, ...
    [12 13]);
% التأكد من صحة الموقع التقديري

verifyGreaterThan( ...
    testCase, ...
    estimatedLocation.confidence, ...
    0);
% التأكد من إنتاج درجة ثقة موجبة

verifyEqual( ...
    testCase, ...
    localizationState.lastEstimatedPosition, ...
    [12 13]);
% التأكد من تحديث حالة التوطين

end

%% ============================================================
% Test 4: Unsupported Peak Is Rejected
%% ============================================================

function testUnsupportedPeakIsRejected(testCase)

config = constants();
% قراءة إعدادات المشروع

localizationState = createSyntheticLocalizationState();
% إنشاء حالة توطين اصطناعية

localizationState.evidenceMap(10,10) = 0.95;
% إنشاء قمة قوية ظاهريًا

localizationState.observationCount(10,10) = ...
    config.clustering.minimumPoints - 1;
% جعل عدد المشاهدات أقل من الحد المطلوب

candidate = struct( ...
    'isVictim', true, ...
    'position', [10 10], ...
    'score', 0.95, ...
    'confidence', 0.90);
% إنشاء مرشح أولي

[estimatedLocation, ~] = ...
    estimateLocationFromEvidenceMap( ...
        localizationState, ...
        candidate);
% محاولة تحديد الموقع

verifyFalse( ...
    testCase, ...
    estimatedLocation.isDetected);
% التأكد من رفض القمة غير المدعومة زمنيًا

verifyEmpty( ...
    testCase, ...
    estimatedLocation.position);
% التأكد من عدم إنتاج موقع غير موثوق

end


%% ============================================================
function testAccumulatedEvidenceOverridesWeakInstantaneousCandidate(testCase)
%% ============================================================
% التأكد من أن الدليل المكاني القوي والمتكرر يستطيع تأكيد الضحية
% حتى عندما تكون القراءة اللحظية الحالية ضعيفة وغير مرشحة.
%% ============================================================

localizationState = createSyntheticLocalizationState();
% إنشاء حالة توطين اصطناعية

localizationState.evidenceMap(10,10) = 0.90;
% إنشاء قمة مكانية قوية ناتجة عن أدلة متراكمة

localizationState.observationCount(10,10) = 10;
% توفير عدد كبير من المشاهدات الداعمة

if isfield(localizationState, 'weightSum')
    localizationState.weightSum(10,10) = 8;
    % توفير دعم موزون للقمة إذا كانت الخريطة موجودة
end

candidate = struct( ...
    'isVictim', false, ...
    'position', [10 10], ...
    'score', 0.10, ...
    'confidence', 0.20);
% تمثل قراءة لحظية ضعيفة لا تتجاوز بوابة الكشف التقليدية

[estimatedLocation, updatedState] = ...
    estimateLocationFromEvidenceMap( ...
        localizationState, ...
        candidate);
% محاولة التوطين باستخدام خريطة الأدلة المتراكمة

verifyTrue( ...
    testCase, ...
    estimatedLocation.isDetected);
% يجب أن تؤكد الأدلة المتراكمة وجود الضحية

verifyEqual( ...
    testCase, ...
    estimatedLocation.position, ...
    [10 10]);
% يجب أن يكون الموقع المقدر عند القمة المكانية

config = constants();

verifyGreaterThanOrEqual( ...
    testCase, ...
    updatedState.lastAdaptivePeakThreshold, ...
    config.localization.minimumAdaptivePeakThreshold);
% التأكد من أن العتبة لم تنخفض عن الحد الآمن

verifyLessThanOrEqual( ...
    testCase, ...
    updatedState.lastAdaptivePeakThreshold, ...
    config.localization.maximumAdaptivePeakThreshold);
% التأكد من أن العتبة لم تتجاوز الحد الأعلى

end

function testWeakPersistentPeakIsLocalized(testCase)
%% ============================================================
% التأكد من كشف إشارة ضعيفة متكررة في خلفية هادئة
%% ============================================================

localizationState = createSyntheticLocalizationState();

localizationState.evidenceMap(8:12,8:12) = 0.03;
% إنشاء خلفية هادئة مرصودة حول موقع الاختبار

localizationState.observationCount(8:12,8:12) = 5;
% توفير مشاهدات كافية لتقدير الخلفية

if isfield(localizationState, 'weightSum')
    localizationState.weightSum(8:12,8:12) = 2;
end

localizationState.evidenceMap(10,10) = 0.18;
% قمة ضعيفة أقل من عتبة الكشف التقليدية 0.28

localizationState.observationCount(10,10) = 10;

if isfield(localizationState, 'weightSum')
    localizationState.weightSum(10,10) = 7;
end

candidate = struct( ...
    'isVictim', false, ...
    'position', [10 10], ...
    'score', 0.18, ...
    'confidence', 0.30);

[estimatedLocation, updatedState] = ...
    estimateLocationFromEvidenceMap( ...
        localizationState, ...
        candidate);

verifyTrue( ...
    testCase, ...
    estimatedLocation.isDetected);
% يجب كشف القمة الضعيفة المتكررة

verifyEqual( ...
    testCase, ...
    estimatedLocation.position, ...
    [10 10]);

verifyLessThan( ...
    testCase, ...
    updatedState.lastAdaptivePeakThreshold, ...
    0.18);
% يجب أن تتكيف العتبة لتصبح أقل من قوة القمة الضعيفة

end

function testNoisyBackgroundRaisesThresholdAndRejectsFalsePeak(testCase)
%% ============================================================
% التأكد من ارتفاع العتبة في الخلفية الصاخبة
% ورفض قمة غير مميزة بما يكفي عن الضوضاء
%% ============================================================

localizationState = createSyntheticLocalizationState();

noiseValues = repmat( ...
    [0.16, 0.20, 0.24], ...
    1, ...
    9);

noiseValues = noiseValues(1:25);

localizationState.evidenceMap(8:12,8:12) = ...
    reshape(noiseValues, 5, 5);
% إنشاء خلفية متغيرة تحاكي بيئة صاخبة

localizationState.observationCount(8:12,8:12) = 5;
% اعتبار الخلفية مرصودة بعدة قياسات

if isfield(localizationState, 'weightSum')
    localizationState.weightSum(8:12,8:12) = 2;
end

localizationState.evidenceMap(10,10) = 0.30;
% قمة أعلى من العتبة القديمة، لكنها غير قوية إحصائيًا
% مقارنة بتباين الخلفية الصاخبة

localizationState.observationCount(10,10) = 10;

if isfield(localizationState, 'weightSum')
    localizationState.weightSum(10,10) = 7;
end

candidate = struct( ...
    'isVictim', true, ...
    'position', [10 10], ...
    'score', 0.30, ...
    'confidence', 0.70);

[estimatedLocation, updatedState] = ...
    estimateLocationFromEvidenceMap( ...
        localizationState, ...
        candidate);

verifyFalse( ...
    testCase, ...
    estimatedLocation.isDetected);
% يجب رفض القمة لأنها لا تتميز كفاية عن الضوضاء

verifyGreaterThan( ...
    testCase, ...
    updatedState.lastAdaptivePeakThreshold, ...
    0.30);
% يجب أن ترتفع العتبة فوق قيمة القمة الكاذبة

end

%% ============================================================
% Test Helper
%% ============================================================

function localizationState = ...
    createSyntheticLocalizationState()

gridRows = 20;
% عدد صفوف خريطة الاختبار

gridColumns = 20;
% عدد أعمدة خريطة الاختبار

localizationState = struct();
% إنشاء حالة التوطين

localizationState.gridSize = ...
    [gridRows, gridColumns];
% حفظ حجم خريطة الاختبار

localizationState.evidenceSum = ...
    zeros(gridRows, gridColumns);
% تهيئة مجموع الأدلة

localizationState.weightSum = ...
    zeros(gridRows, gridColumns);
% تهيئة مجموع الأوزان

localizationState.evidenceMap = ...
    zeros(gridRows, gridColumns);
% تهيئة خريطة الأدلة

localizationState.observationCount = ...
    zeros(gridRows, gridColumns);
% تهيئة عدد المشاهدات

localizationState.pointHistory = zeros(0,2);
% إنشاء سجل النقاط للتوافق

localizationState.scoreHistory = zeros(0,1);
% إنشاء سجل نتائج الدمج

localizationState.confidenceHistory = zeros(0,1);
% إنشاء سجل الثقة

localizationState.lastEstimatedPosition = [];
% لا يوجد موقع سابق

localizationState.lastPeakValue = 0;
% لا توجد قمة سابقة

localizationState.confirmedPeakPositions = zeros(0,2);
% لا توجد قمم مؤكدة

end

%% ============================================================
% Test: Evidence State Persists and Reaches Localization
%% ============================================================

function testEvidenceStatePersistsAndReachesLocalization(testCase)

probe = struct();
probe.visitedCells = false(16,16);
probe.memory = probeMemory();
% إنشاء مسبار مصغر بذاكرة توطين حقيقية

observationPositions = [ ...
    8 7;
    8 8;
    8 9];
% ثلاث قراءات مستقلة ومتجاورة حول قمة واحدة

for observationIndex = 1:size(observationPositions,1)

    fusionPacket = struct( ...
        'probePosition', observationPositions(observationIndex,:), ...
        'fusionScore', 0.80, ...
        'confidence', 0.90, ...
        'timestamp', datetime("now"), ...
        'status', "VALID");

    probe = updateEvidenceMap(probe, fusionPacket);

end

state = probe.memory.localizationState;

verifyEqual(testCase, size(state.pointHistory,1), 3);
% يجب ألا تضيع تحديثات state داخل المتغير المحلي للدالة

verifyGreaterThan(testCase, max(state.evidenceMap(:)), 0);
% يجب أن تحتوي الخريطة المحفوظة على دليل فعلي

[localizationPacket, ~] = localizationManager( ...
    fusionPacket, ...
    state);

verifyTrue(testCase, localizationPacket.isVictimDetected);
% يجب أن تستطيع طبقة Localization رؤية الأدلة المحدثة

positionError = norm( ...
    localizationPacket.estimatedPosition - [8 8]);

verifyLessThanOrEqual(testCase, positionError, 1);
% يجب أن تبقى القمة المقدرة ضمن خلية واحدة من مركز القياسات

end

%% ============================================================
% Test 6: False Positive Does Not Affect Localization Error
%% ============================================================

function testFalsePositiveDoesNotAffectLocalizationError(testCase)

detectedVictims = [ ...
    10 10;
    40 40];
% الاكتشاف الأول قريب من ضحية حقيقية
% والاكتشاف الثاني إنذار كاذب بعيد

groundTruth = [11 10];
% موقع الضحية الحقيقي

[TP, TN, FP, FN, matchedDistances] = ...
    confusionMatrix( ...
        detectedVictims, ...
        groundTruth);
% تنفيذ المطابقة واحدًا لواحد

verifyEqual(testCase, TP, 1);
% التأكد من وجود اكتشاف صحيح واحد

verifyEqual(testCase, TN, 0);
% لا توجد حالات سلبية معرفة في تقييم المواقع

verifyEqual(testCase, FP, 1);
% التأكد من تسجيل الاكتشاف البعيد كإنذار كاذب

verifyEqual(testCase, FN, 0);
% التأكد من عدم فقد الضحية الحقيقية

verifyEqual( ...
    testCase, ...
    matchedDistances, ...
    1, ...
    'AbsTol', 1e-12);
% يجب أن تحتوي أخطاء الموقع على مسافة الزوج الصحيح فقط

verifyEqual( ...
    testCase, ...
    mean(matchedDistances), ...
    1, ...
    'AbsTol', 1e-12);
% التأكد من عدم إدخال الإنذار الكاذب في متوسط خطأ الموقع

end

%% ============================================================
% Test 7: Object-Detection Metrics Are Scientifically Consistent
%% ============================================================

function testObjectDetectionMetricsAreConsistent(testCase)

metrics = detectionMetrics( ...
    3, ...
    0, ...
    1, ...
    0);
% ثلاث إصابات صحيحة وإنذار كاذب واحد

verifyEqual( ...
    testCase, ...
    metrics.precision, ...
    0.75, ...
    'AbsTol', 1e-12);
% Precision يجب أن تساوي 3 من أصل 4 اكتشافات

verifyEqual( ...
    testCase, ...
    metrics.recall, ...
    1, ...
    'AbsTol', 1e-12);
% تم اكتشاف جميع الضحايا الحقيقيين

verifyEqual( ...
    testCase, ...
    metrics.falseDiscoveryRate, ...
    0.25, ...
    'AbsTol', 1e-12);
% ربع اكتشافات النظام كاذبة

verifyEqual( ...
    testCase, ...
    metrics.criticalSuccessIndex, ...
    0.75, ...
    'AbsTol', 1e-12);
% مؤشر النجاح يساوي ثلاثة أرباع

verifyTrue( ...
    testCase, ...
    isnan(metrics.falseAlarmRate));
% يجب ألا تُعرض FAR تقليدية دون True Negatives

verifyTrue( ...
    testCase, ...
    isnan(metrics.conventionalAccuracy));
% Accuracy التقليدية غير معرفة دون True Negatives

end

function testNearbyVictimRecordsAreMerged(testCase)
%% ============================================================
% Test Duplicate Victim Record Merging
%
% Description:
% التأكد من دمج سجلين متقاربين يمثلان الضحية نفسها،
% مع إبقاء الضحية البعيدة كسجل مستقل.
%% ============================================================

currentTime = datetime("now");
% تحديد وقت موحد لسجلات الاختبار

victim1 = struct( ...
    'id', 1, ...
    'position', [20 20], ...
    'vitalityIndex', 0.60, ...
    'priorityScore', 0.50, ...
    'priorityLevel', "HIGH", ...
    'firstDetectionTime', currentTime, ...
    'lastUpdateTime', currentTime, ...
    'detectionCount', 10);
% السجل الأول للضحية المتكررة

victim2 = struct( ...
    'id', 2, ...
    'position', [22 21], ...
    'vitalityIndex', 0.70, ...
    'priorityScore', 0.80, ...
    'priorityLevel', "HIGH", ...
    'firstDetectionTime', currentTime, ...
    'lastUpdateTime', currentTime, ...
    'detectionCount', 5);
% سجل ثانٍ قريب يمثل الضحية نفسها

victim3 = struct( ...
    'id', 3, ...
    'position', [40 40], ...
    'vitalityIndex', 0.55, ...
    'priorityScore', 0.40, ...
    'priorityLevel', "MEDIUM", ...
    'firstDetectionTime', currentTime, ...
    'lastUpdateTime', currentTime, ...
    'detectionCount', 7);
% سجل ضحية أخرى بعيدة ويجب ألا يتم دمجه

victims = [victim1, victim2, victim3];
% تجميع سجلات الاختبار

mergedVictims = mergeDuplicateVictims(victims, 3);
% دمج السجلات التي تفصل بينها مسافة لا تتجاوز ثلاث خلايا

verifyEqual(testCase, numel(mergedVictims), 2);
% يجب أن تصبح السجلات الثلاثة سجلين فقط

detectionCounts = [mergedVictims.detectionCount];

verifyTrue(testCase, any(detectionCounts == 15));
% عدد اكتشافات السجلين المتقاربين يجب أن يصبح 10 + 5

verifyTrue(testCase, any(detectionCounts == 7));
% سجل الضحية البعيدة يجب أن يبقى كما هو

mergedPositions = vertcat(mergedVictims.position);

verifyTrue( ...
    testCase, ...
    any(all(mergedPositions == [40 40], 2)));
% التأكد من بقاء موقع الضحية البعيدة

priorityScores = [mergedVictims.priorityScore];

verifyTrue(testCase, any(priorityScores == 0.80));
% السجل المدمج يجب أن يحتفظ بأعلى درجة أولوية

end
