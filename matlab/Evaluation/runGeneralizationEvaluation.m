function [runTable, scenarioSummary, splitSummary, rawResults] = ...
    runGeneralizationEvaluation(repetitionsBySplit)
%% ============================================================
% تقييم تعميم صريح بفصل Calibration/Validation/FinalTest.
%
% الافتراضي: (10+5+5) بذور × 6 أنواع = 120 تشغيلًا.
% لا تُستخدم نتائج FinalTest لضبط العتبات.
%% ============================================================

if nargin < 1
    repetitionsBySplit = [10 5 5];
end
if ~isnumeric(repetitionsBySplit) || ...
        numel(repetitionsBySplit) ~= 3 || ...
        any(~isfinite(repetitionsBySplit)) || ...
        any(repetitionsBySplit < 1) || ...
        any(repetitionsBySplit ~= round(repetitionsBySplit))
    error("runGeneralizationEvaluation:InvalidRepetitions", ...
        "Use three positive integers: [calibration validation final].");
end

scenarioTypes = ["Ideal";"DenseDebris";"HighNoise"; ...
    "DeepBurial";"MultipleVictims";"WeakVitalSigns"];
splitNames = ["Calibration","Validation","FinalTest"];
seedBases = [1,1001,2001];
totalRuns = numel(scenarioTypes)*sum(repetitionsBySplit);
rows = repmat(emptyRow(),totalRuns,1);
rawResults = cell(totalRuns,1);
runIndex = 0;

outputFolder = fullfile(fileparts(mfilename('fullpath')), ...
    "GeneralizationResults");
if ~isfolder(outputFolder)
    mkdir(outputFolder);
end

for splitIndex = 1:3
    for scenarioIndex = 1:numel(scenarioTypes)
        for repetitionIndex = 1:repetitionsBySplit(splitIndex)
            runIndex = runIndex + 1;
            seed = seedBases(splitIndex) + repetitionIndex - 1;
            fprintf('[%d/%d] Split=%s Scenario=%s Seed=%d ... ', ...
                runIndex,totalRuns,splitNames(splitIndex), ...
                scenarioTypes(scenarioIndex),seed);
            result = runSingleScenarioEvaluation( ...
                scenarioTypes(scenarioIndex),seed);
            rawResults{runIndex} = result;
            rows(runIndex) = resultRow(runIndex,splitNames(splitIndex),result);
            if result.runSucceeded
                fprintf('F1=%.3f Loc=%.3f Time=%.2f s\n', ...
                    result.f1Score,result.localizationMeanError, ...
                    result.runtimeSeconds);
            else
                fprintf('FAILED: %s\n',result.errorMessage);
            end
        end
    end
end

runTable = struct2table(rows);
scenarioSummary = summarizeBy(runTable,["Split","ScenarioType"]);
splitSummary = summarizeBy(runTable,"Split");
writetable(runTable,fullfile(outputFolder,"generalizationRuns.csv"));
writetable(scenarioSummary, ...
    fullfile(outputFolder,"scenarioSummary.csv"));
writetable(splitSummary,fullfile(outputFolder,"splitSummary.csv"));
save(fullfile(outputFolder,"generalizationResults.mat"), ...
    'runTable','scenarioSummary','splitSummary','rawResults', ...
    'repetitionsBySplit','scenarioTypes','splitNames');

fprintf('\nGeneralization evaluation complete: %d runs.\n',totalRuns);
fprintf('FinalTest is held out; do not tune thresholds from it.\n');

end


function row = emptyRow()

row = struct( ...
    'RunIndex',0,'Split',"",'ScenarioType',"",'RandomSeed',0, ...
    'RunSucceeded',false,'GroundTruthVictims',NaN, ...
    'SystemDetections',NaN,'TP',NaN,'FP',NaN,'FN',NaN, ...
    'Precision',NaN,'Recall',NaN,'F1Score',NaN, ...
    'LocalizationMeanError',NaN,'LocalizationRMSE',NaN, ...
    'ReachableVictimCount',NaN,'MeanRecommendedPathLength',NaN, ...
    'MeanRecommendedRouteRisk',NaN,'RuntimeSeconds',NaN, ...
    'LocalizationMethod',"",'ErrorMessage',"");

end


function row = resultRow(runIndex,split,result)

row = emptyRow();
row.RunIndex = runIndex;
row.Split = split;
row.ScenarioType = result.scenarioType;
row.RandomSeed = result.randomSeed;
row.RunSucceeded = result.runSucceeded;
row.GroundTruthVictims = result.groundTruthVictims;
row.SystemDetections = result.systemDetections;
row.TP = result.truePositives;
row.FP = result.falsePositives;
row.FN = result.falseNegatives;
row.Precision = result.precision;
row.Recall = result.recall;
row.F1Score = result.f1Score;
row.LocalizationMeanError = result.localizationMeanError;
row.LocalizationRMSE = result.localizationRMSE;
row.ReachableVictimCount = result.reachableVictimCount;
row.MeanRecommendedPathLength = ...
    result.meanRecommendedPathLength;
row.MeanRecommendedRouteRisk = ...
    result.meanRecommendedRouteRisk;
row.RuntimeSeconds = result.runtimeSeconds;
row.LocalizationMethod = result.localizationMethod;
row.ErrorMessage = result.errorMessage;

end


function summary = summarizeBy(runTable,groupVariables)

groupVariables = string(groupVariables);
successful = runTable(runTable.RunSucceeded,:);
if isempty(successful)
    summary = table();
    return;
end

[groups,groupValues] = findgroups(successful(:,groupVariables));
metrics = ["Precision","Recall","F1Score", ...
    "LocalizationMeanError","LocalizationRMSE", ...
    "MeanRecommendedPathLength","MeanRecommendedRouteRisk"];
summary = groupValues;
summary.RunCount = splitapply(@numel,successful.RunIndex,groups);

for metricIndex = 1:numel(metrics)
    metric = metrics(metricIndex);
    values = successful.(metric);
    meanValues = splitapply(@finiteMean,values,groups);
    ciValues = splitapply(@confidenceHalfWidth,values,groups);
    summary.("Mean_"+metric) = meanValues;
    summary.("CI95HalfWidth_"+metric) = ciValues;
end

end


function value = finiteMean(values)

values = values(isfinite(values));
if isempty(values)
    value = NaN;
else
    value = mean(values);
end

end


function value = confidenceHalfWidth(values)

values = values(isfinite(values));
if numel(values) < 2
    value = NaN;
else
    value = 1.96*std(values)/sqrt(numel(values));
end

end
