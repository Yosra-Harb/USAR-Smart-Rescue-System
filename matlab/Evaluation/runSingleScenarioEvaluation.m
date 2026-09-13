function [runResult, finalProbe] = ...
    runSingleScenarioEvaluation(scenarioType, randomSeed)
%% ============================================================
% Function Name : runSingleScenarioEvaluation
%
% Description :
% تشغيل سيناريو واحد في الوضع الصامت وإرجاع نتائجه
% في هيكل موحد لاستخدامه في التقييم التجميعي.
%
% لا تعرض الدالة الرسومات ولا توقف التجربة إذا فشل التشغيل،
% بل تحفظ رسالة الخطأ داخل النتيجة.
%% ============================================================

%% ============================================================
% Validate Inputs
%% ============================================================

if nargin < 1 || strlength(string(scenarioType)) == 0
    scenarioType = "Custom";
    % استخدام السيناريو المخصص افتراضيًا
end

if nargin < 2
    randomSeed = 1;
    % استخدام بذرة افتراضية
end

scenarioType = string(scenarioType);
% توحيد نوع اسم السيناريو

if ~isscalar(randomSeed) || ...
        ~isfinite(randomSeed) || ...
        randomSeed < 0

    error( ...
        "runSingleScenarioEvaluation:InvalidSeed", ...
        "randomSeed must be a nonnegative finite scalar.");
    % رفض البذور غير الصالحة

end

randomSeed = round(randomSeed);
% تحويل البذرة إلى عدد صحيح

%% ============================================================
% Initialize Default Result
%% ============================================================

runResult = struct();
finalProbe = struct();
% تهيئة مخرج المسبار النهائي لأغراض التشخيص

runResult.scenarioType = scenarioType;
runResult.randomSeed = randomSeed;

runResult.runSucceeded = false;
runResult.perfectMission = false;

runResult.groundTruthVictims = NaN;
runResult.systemDetections = NaN;

runResult.truePositives = NaN;
runResult.falsePositives = NaN;
runResult.falseNegatives = NaN;

runResult.criticalSuccessIndex = NaN;
runResult.precision = NaN;
runResult.recall = NaN;
runResult.f1Score = NaN;
runResult.falseDiscoveryRate = NaN;
runResult.falseNegativeRate = NaN;

runResult.localizationMeanError = NaN;
runResult.localizationRMSE = NaN;
runResult.localizationMedianError = NaN;
runResult.localizationMaximumError = NaN;
runResult.matchedVictimCount = 0;
runResult.matchedDistances = zeros(0,1);
runResult.groundTruthPositions = zeros(0,2);
runResult.detectedVictimPositions = zeros(0,2);
runResult.detectedVictimDatabase = struct([]);
runResult.rescuePlan = struct([]);
runResult.reachableVictimCount = NaN;
runResult.meanRecommendedPathLength = NaN;
runResult.meanRecommendedRouteRisk = NaN;
% حفظ بيانات الاكتشاف التفصيلية لتحليل الإنذارات الكاذبة

runResult.fusionHistorySize = NaN;
runResult.maximumFusionScore = NaN;
runResult.meanFusionScore = NaN;

runResult.localizationMethod = "";
runResult.maximumPosteriorProbability = NaN;
runResult.confirmedTrackCount = NaN;

runResult.runtimeSeconds = NaN;

runResult.errorIdentifier = "";
runResult.errorMessage = "";
% إنشاء جميع الحقول مسبقًا لضمان اتساق نتائج الدفعات

%% ============================================================
% Prepare Headless Graphics Mode
%% ============================================================

previousFigureVisibility = ...
    get(groot, 'defaultFigureVisible');
% حفظ حالة عرض الرسومات الحالية

existingFigures = ...
    findall(groot, 'Type', 'figure');
% حفظ الرسومات المفتوحة قبل بدء التشغيل

graphicsCleanup = onCleanup( ...
    @() restoreGraphicsState( ...
        previousFigureVisibility, ...
        existingFigures));
% ضمان استعادة حالة الرسومات حتى لو حدث خطأ

set(groot, 'defaultFigureVisible', 'off');
% منع ظهور نوافذ الرسومات أثناء التشغيل

%% ============================================================
% Execute Scenario
%% ============================================================

executionTimer = tic;
% بدء قياس زمن التشغيل

try

    commandOutput = evalc( ...
        ['[simulationResult, finalProbe, scenario] = ', ...
        'executeScenarioRun(scenarioType, randomSeed);']);
    %#ok<NASGU>
    % تشغيل السيناريو مع حجز المخرجات النصية لمنع ازدحام Command Window

    runResult.runtimeSeconds = toc(executionTimer);
    % حفظ زمن التشغيل الناجح

    %% --------------------------------------------------------
    % Detection Counts
    %% --------------------------------------------------------

    runResult.groundTruthVictims = ...
        simulationResult.groundTruthVictimCount;

    runResult.systemDetections = ...
        simulationResult.systemDetectionCount;

    runResult.truePositives = ...
        simulationResult.truePositives;

    runResult.falsePositives = ...
        simulationResult.falsePositives;

    runResult.falseNegatives = ...
        simulationResult.falseNegatives;

    TP = runResult.truePositives;
    FP = runResult.falsePositives;
    FN = runResult.falseNegatives;

    %% --------------------------------------------------------
    % Object-Detection Metrics
    %% --------------------------------------------------------

    runResult.criticalSuccessIndex = ...
        TP / max(TP + FP + FN, 1);
    % CSI = TP / (TP + FP + FN)

    runResult.precision = ...
        TP / max(TP + FP, 1);
    % Precision = TP / (TP + FP)

    runResult.recall = ...
        TP / max(TP + FN, 1);
    % Recall = TP / (TP + FN)

    runResult.f1Score = ...
        2 * runResult.precision * runResult.recall / ...
        max(runResult.precision + runResult.recall, eps);
    % المتوسط التوافقي بين Precision وRecall

    runResult.falseDiscoveryRate = ...
        FP / max(TP + FP, 1);
    % نسبة الاكتشافات الكاذبة من جميع اكتشافات النظام

    runResult.falseNegativeRate = ...
        FN / max(TP + FN, 1);
    % نسبة الضحايا الحقيقيين الذين لم يكتشفهم النظام

    %% --------------------------------------------------------
    % Localization Metrics
    %% --------------------------------------------------------

    matchedDistances = ...
        simulationResult.matchedDistances(:);
    % تحويل أخطاء التوطين إلى متجه عمودي

    matchedDistances = matchedDistances( ...
        isfinite(matchedDistances));
    % استبعاد القيم غير الرقمية

    runResult.matchedDistances = matchedDistances;
    runResult.matchedVictimCount = numel(matchedDistances);

    if ~isempty(matchedDistances)

        runResult.localizationMeanError = ...
            mean(matchedDistances);

        runResult.localizationRMSE = ...
            sqrt(mean(matchedDistances.^2));

        runResult.localizationMedianError = ...
            median(matchedDistances);

        runResult.localizationMaximumError = ...
            max(matchedDistances);

    end
    %% --------------------------------------------------------
% Detailed Detection Diagnostics
%% --------------------------------------------------------

runResult.groundTruthPositions = ...
    simulationResult.groundTruthPositions;
% المواقع الحقيقية للضحايا

runResult.detectedVictimPositions = ...
    simulationResult.detectedVictimPositions;
% المواقع التي سجلها النظام

runResult.detectedVictimDatabase = ...
    simulationResult.detectedVictimDatabase;
% السجلات التفصيلية للاكتشافات

runResult.rescuePlan = simulationResult.rescuePlan;
if ~isempty(runResult.rescuePlan)
    recommendedRoutes = [runResult.rescuePlan.recommendedRoute];
    reachableMask = [recommendedRoutes.reachable];
    runResult.reachableVictimCount = nnz(reachableMask);
    if any(reachableMask)
        runResult.meanRecommendedPathLength = mean( ...
            [recommendedRoutes(reachableMask).pathLength]);
        runResult.meanRecommendedRouteRisk = mean( ...
            [recommendedRoutes(reachableMask).meanRisk]);
    end
else
    runResult.reachableVictimCount = 0;
end
    %% --------------------------------------------------------
    % Fusion Statistics
    %% --------------------------------------------------------

    runResult.fusionHistorySize = ...
        simulationResult.fusionHistorySize;

    runResult.maximumFusionScore = ...
        simulationResult.maximumFusionScore;

    runResult.meanFusionScore = ...
        simulationResult.meanFusionScore;

    runResult.localizationMethod = ...
        simulationResult.localizationMethod;
    runResult.maximumPosteriorProbability = ...
        simulationResult.maximumPosteriorProbability;
    runResult.confirmedTrackCount = ...
        simulationResult.confirmedTrackCount;

    %% --------------------------------------------------------
    % Run Status
    %% --------------------------------------------------------

    runResult.runSucceeded = true;
    % التشغيل البرمجي اكتمل دون استثناء

    runResult.perfectMission = ...
        FP == 0 && FN == 0;
    % المهمة مثالية فقط عند عدم وجود إنذارات كاذبة أو ضحايا مفقودين

catch executionError

    runResult.runtimeSeconds = toc(executionTimer);
    % حفظ زمن التشغيل حتى عند الفشل

    runResult.errorIdentifier = ...
        string(executionError.identifier);
    % حفظ معرف الخطأ

    runResult.errorMessage = ...
        string(executionError.message);
    % حفظ رسالة الخطأ دون إيقاف بقية الدفعة

end

end

%% ============================================================
% Execute Complete Scenario
%% ============================================================

function [simulationResult, finalProbe, scenario] = ...
    executeScenarioRun(scenarioType, randomSeed)

scenarioConfig = ScenarioGenerator(scenarioType);
% إنشاء إعدادات نوع السيناريو

scenarioConfig.randomSeed = randomSeed;
% تغيير البذرة لإنتاج بيئة مستقلة قابلة لإعادة التشغيل

scenario = createScenario(scenarioConfig);
% إنشاء السيناريو الكامل

initialProbe = createProbe( ...
    scenario, ...
    "boustrophedon");
% إنشاء مسبار جديد مستقل

[simulationResult, finalProbe] = ...
    runProbeSimulation( ...
        scenario, ...
        initialProbe, ...
        true);
% تشغيل المحاكاة في الوضع السريع

end

%% ============================================================
% Restore Graphics State
%% ============================================================

function restoreGraphicsState( ...
    previousFigureVisibility, ...
    existingFigures)

currentFigures = ...
    findall(groot, 'Type', 'figure');
% قراءة جميع الرسومات الموجودة بعد التشغيل

for figureIndex = 1:numel(currentFigures)

    currentFigure = currentFigures(figureIndex);

    if ~any(currentFigure == existingFigures)

        delete(currentFigure);
        % حذف الرسومات التي أنشأها تشغيل التقييم فقط

    end

end

set( ...
    groot, ...
    'defaultFigureVisible', ...
    previousFigureVisibility);
% استعادة إعداد ظهور الرسومات السابق

end
