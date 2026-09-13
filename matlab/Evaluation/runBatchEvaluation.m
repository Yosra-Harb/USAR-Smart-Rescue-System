function [batchTable, rawResults] = ...
    runBatchEvaluation(repetitionsPerScenario, resumeMode)
%% ============================================================
% Function Name : runBatchEvaluation
%
% Description :
% تشغيل تقييم تجميعي على أنواع السيناريوهات الستة.
%
% الاستخدام النهائي:
% 20 تكرارًا × 6 أنواع = 120 تشغيلًا.
%
% تحفظ الدالة نقطة استعادة بعد كل تشغيل حتى لا تضيع
% النتائج إذا توقف MATLAB أو انقطع الاتصال.
%% ============================================================

%% ============================================================
% Default Inputs
%% ============================================================

if nargin < 1
    repetitionsPerScenario = 20;
    % عشرون تشغيلًا لكل نوع يعطي 120 تشغيلًا
end

if nargin < 2
    resumeMode = false;
    % بدء تجربة جديدة افتراضيًا
end

if ~isscalar(repetitionsPerScenario) || ...
        ~isfinite(repetitionsPerScenario) || ...
        repetitionsPerScenario < 1 || ...
        repetitionsPerScenario ~= ...
        round(repetitionsPerScenario)

    error( ...
        "runBatchEvaluation:InvalidRepetitionCount", ...
        "repetitionsPerScenario must be a positive integer.");
    % رفض عدد التكرارات غير الصالح

end

resumeMode = logical(resumeMode);
% توحيد قيمة استكمال التشغيل

%% ============================================================
% Scenario Types
%% ============================================================

scenarioTypes = [ ...
    "Ideal"; ...
    "DenseDebris"; ...
    "HighNoise"; ...
    "DeepBurial"; ...
    "MultipleVictims"; ...
    "WeakVitalSigns"];
% أنواع السيناريوهات المعتمدة في التقييم

numberOfScenarioTypes = numel(scenarioTypes);
% عدد أنواع السيناريوهات

totalRuns = ...
    numberOfScenarioTypes * ...
    repetitionsPerScenario;
% إجمالي عدد التشغيلات

%% ============================================================
% Output Folder
%% ============================================================

evaluationFolder = ...
    fileparts(mfilename('fullpath'));
% مسار مجلد Evaluation

outputFolder = fullfile( ...
    evaluationFolder, ...
    "BatchResults");
% المجلد الذي سيحتوي ملفات النتائج

if ~isfolder(outputFolder)
    mkdir(outputFolder);
    % إنشاء مجلد النتائج إذا لم يكن موجودًا
end

checkpointFile = fullfile( ...
    outputFolder, ...
    "batchCheckpoint.mat");
% ملف الاستعادة بعد الانقطاع

csvFile = fullfile( ...
    outputFolder, ...
    "batchResults.csv");
% ملف النتائج القابل للفتح في Excel

matFile = fullfile( ...
    outputFolder, ...
    "batchResults.mat");
% ملف MATLAB الذي يحتفظ بالنتائج الخام

%% ============================================================
% Initialize Result Storage
%% ============================================================

emptyRow = createEmptyBatchRow();
% إنشاء صف نتائج فارغ

resultRows = repmat( ...
    emptyRow, ...
    totalRuns, ...
    1);
% حجز جميع صفوف النتائج مسبقًا

rawResults = cell(totalRuns,1);
% تخزين الهياكل الكاملة لكل تشغيل

startRunIndex = 1;
% بدء التشغيل من التجربة الأولى

%% ============================================================
% Resume Previous Evaluation
%% ============================================================

if resumeMode && isfile(checkpointFile)

    checkpoint = load(checkpointFile);
    % تحميل نقطة الاستعادة

    configurationMatches = ...
        isfield(checkpoint, 'scenarioTypes') && ...
        isequal(checkpoint.scenarioTypes, scenarioTypes) && ...
        isfield(checkpoint, 'repetitionsPerScenario') && ...
        checkpoint.repetitionsPerScenario == ...
        repetitionsPerScenario && ...
        isfield(checkpoint, 'resultRows') && ...
        isfield(checkpoint.resultRows, ...
            'LocalizationMethod');
    % التأكد من أن نقطة الاستعادة تخص التجربة نفسها

    if ~configurationMatches

        error( ...
            "runBatchEvaluation:CheckpointMismatch", ...
            "Checkpoint configuration does not match this run.");
        % منع خلط نتائج تجربتين مختلفتين

    end

    resultRows = checkpoint.resultRows;
    rawResults = checkpoint.rawResults;

    startRunIndex = ...
        checkpoint.completedRunIndex + 1;
    % المتابعة من أول تشغيل غير مكتمل

    fprintf( ...
        'Resuming from run %d of %d.\n', ...
        startRunIndex, ...
        totalRuns);

elseif resumeMode

    warning( ...
        "runBatchEvaluation:CheckpointNotFound", ...
        "No checkpoint found. Starting a new evaluation.");
    % بدء تجربة جديدة إذا لم توجد نقطة استعادة

end

%% ============================================================
% Execute Batch
%% ============================================================

batchTimer = tic;
% بدء قياس زمن الدفعة كاملة

runIndex = 0;
% عداد التشغيلات

for scenarioIndex = 1:numberOfScenarioTypes

    currentScenarioType = ...
        scenarioTypes(scenarioIndex);
    % نوع السيناريو الحالي

    for repetitionIndex = 1:repetitionsPerScenario

        runIndex = runIndex + 1;
        % زيادة رقم التشغيل

        if runIndex < startRunIndex
            continue;
            % تجاوز التشغيلات المكتملة عند الاستعادة
        end

        randomSeed = repetitionIndex;
        % استخدام البذور نفسها عبر الأنواع للمقارنة العادلة
        % مع بقاء كل تكرار مختلفًا عن الآخر

        fprintf( ...
            '[%d/%d] Scenario=%s, Seed=%d ... ', ...
            runIndex, ...
            totalRuns, ...
            currentScenarioType, ...
            randomSeed);
        % عرض تقدم مختصر فقط

        currentResult = ...
            runSingleScenarioEvaluation( ...
                currentScenarioType, ...
                randomSeed);
        % تشغيل السيناريو في الوضع الصامت

        rawResults{runIndex} = currentResult;
        % حفظ النتيجة الخام

        resultRows(runIndex) = ...
            createBatchRow( ...
                runIndex, ...
                repetitionIndex, ...
                currentResult);
        % بناء صف جدولي للنتيجة

        if currentResult.runSucceeded

            fprintf( ...
                'Done | F1=%.3f | Loc=%.3f s | Time=%.2f s\n', ...
                currentResult.f1Score, ...
                currentResult.localizationMeanError, ...
                currentResult.runtimeSeconds);
            % عرض نتيجة التشغيل الناجح

        else

            fprintf( ...
                'Failed | %s\n', ...
                currentResult.errorMessage);
            % عرض رسالة مختصرة عند فشل التشغيل

        end

        completedRunIndex = runIndex;
        %#ok<NASGU>
        % رقم آخر تشغيل محفوظ

        save( ...
            checkpointFile, ...
            'resultRows', ...
            'rawResults', ...
            'scenarioTypes', ...
            'repetitionsPerScenario', ...
            'completedRunIndex');
        % حفظ نقطة استعادة بعد كل تشغيل

    end

end

%% ============================================================
% Build and Save Final Table
%% ============================================================

batchTable = struct2table(resultRows);
% تحويل النتائج إلى جدول MATLAB

writetable(batchTable, csvFile);
% حفظ النتائج بصيغة CSV

save( ...
    matFile, ...
    'batchTable', ...
    'rawResults', ...
    'scenarioTypes', ...
    'repetitionsPerScenario');
% حفظ النتائج الكاملة بصيغة MAT

totalBatchTime = toc(batchTimer);
% حساب زمن الدفعة

fprintf('\n========================================\n');
fprintf('Batch evaluation completed.\n');
fprintf('Completed runs : %d\n', totalRuns);
fprintf('Total time     : %.2f seconds\n', totalBatchTime);
fprintf('CSV file       : %s\n', csvFile);
fprintf('MAT file       : %s\n', matFile);
fprintf('========================================\n');

end

%% ============================================================
% Create Empty Batch Row
%% ============================================================

function row = createEmptyBatchRow()

row = struct();

row.RunIndex = 0;
row.ScenarioType = "";
row.Repetition = 0;
row.RandomSeed = 0;

row.RunSucceeded = false;
row.PerfectMission = false;

row.GroundTruthVictims = NaN;
row.SystemDetections = NaN;

row.TP = NaN;
row.FP = NaN;
row.FN = NaN;

row.CSI = NaN;
row.Precision = NaN;
row.Recall = NaN;
row.F1Score = NaN;
row.FalseDiscoveryRate = NaN;
row.FalseNegativeRate = NaN;

row.LocalizationMeanError = NaN;
row.LocalizationRMSE = NaN;
row.LocalizationMedianError = NaN;
row.LocalizationMaximumError = NaN;
row.MatchedVictimCount = 0;

row.FusionHistorySize = NaN;
row.MaximumFusionScore = NaN;
row.MeanFusionScore = NaN;

row.LocalizationMethod = "";
row.MaximumPosteriorProbability = NaN;
row.ConfirmedTrackCount = NaN;
row.ReachableVictimCount = NaN;
row.MeanRecommendedPathLength = NaN;
row.MeanRecommendedRouteRisk = NaN;

row.RuntimeSeconds = NaN;

row.ErrorIdentifier = "";
row.ErrorMessage = "";

end

%% ============================================================
% Convert Single Result to Batch Row
%% ============================================================

function row = ...
    createBatchRow(runIndex, repetitionIndex, result)

row = createEmptyBatchRow();
% إنشاء صف جديد

row.RunIndex = runIndex;
row.ScenarioType = result.scenarioType;
row.Repetition = repetitionIndex;
row.RandomSeed = result.randomSeed;

row.RunSucceeded = result.runSucceeded;
row.PerfectMission = result.perfectMission;

row.GroundTruthVictims = result.groundTruthVictims;
row.SystemDetections = result.systemDetections;

row.TP = result.truePositives;
row.FP = result.falsePositives;
row.FN = result.falseNegatives;

row.CSI = result.criticalSuccessIndex;
row.Precision = result.precision;
row.Recall = result.recall;
row.F1Score = result.f1Score;
row.FalseDiscoveryRate = result.falseDiscoveryRate;
row.FalseNegativeRate = result.falseNegativeRate;

row.LocalizationMeanError = ...
    result.localizationMeanError;

row.LocalizationRMSE = ...
    result.localizationRMSE;

row.LocalizationMedianError = ...
    result.localizationMedianError;

row.LocalizationMaximumError = ...
    result.localizationMaximumError;

row.MatchedVictimCount = ...
    result.matchedVictimCount;

row.FusionHistorySize = ...
    result.fusionHistorySize;

row.MaximumFusionScore = ...
    result.maximumFusionScore;

row.MeanFusionScore = ...
    result.meanFusionScore;

row.LocalizationMethod = ...
    result.localizationMethod;

row.MaximumPosteriorProbability = ...
    result.maximumPosteriorProbability;

row.ConfirmedTrackCount = ...
    result.confirmedTrackCount;

row.ReachableVictimCount = ...
    result.reachableVictimCount;
row.MeanRecommendedPathLength = ...
    result.meanRecommendedPathLength;
row.MeanRecommendedRouteRisk = ...
    result.meanRecommendedRouteRisk;

row.RuntimeSeconds = ...
    result.runtimeSeconds;

row.ErrorIdentifier = ...
    result.errorIdentifier;

row.ErrorMessage = ...
    result.errorMessage;

end
