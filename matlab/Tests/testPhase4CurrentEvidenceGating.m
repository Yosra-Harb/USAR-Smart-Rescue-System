function tests = testPhase4CurrentEvidenceGating
%% اختبارات منع تحويل posterior تاريخي إلى مشاهدة مستقلة جديدة.

tests = functiontests(localfunctions);

end


function setupOnce(testCase)

testsFolder = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testsFolder);
addpath(fullfile(projectRoot, 'Main'), '-begin');
testCase.TestData.projectRoot = setupProjectPaths();

end


function testHistoricalPosteriorWithoutCurrentEvidenceIsRejected(testCase)

state = buildSpatialPeakState(-0.20);

[peaks, updatedState] = ...
    detectBayesianPosteriorPeaks(state);

verifyEmpty(testCase, peaks);
verifyEqual(testCase, ...
    updatedState.lastCandidatePeakCount, 0);

end


function testCurrentPositiveEvidenceAllowsPosteriorPeak(testCase)

state = buildSpatialPeakState(0.20);

[peaks, updatedState] = ...
    detectBayesianPosteriorPeaks(state);

verifyEqual(testCase, numel(peaks), 1);
verifyEqual(testCase, peaks.row, 8);
verifyEqual(testCase, peaks.column, 8);
verifyEqual(testCase, ...
    updatedState.lastCandidatePeakCount, 1);

end


function state = buildSpatialPeakState(currentLogBayesFactor)

state = initializeSpatialBayesianLocalizationState( ...
    [15 15], ...
    0.01);

state.updateCount = 1;
state.probabilityMap(8,8) = 0.95;
state.logOddsMap(8,8) = log(0.95 / 0.05);
state.observationCount(8,8) = 5;
state.weightedObservationSupport(8,8) = 4;
state.lastObservationStep(8,8) = 1;
state.lastVisibilityMask(8,8) = true;
state.lastMeasurementLogBayesFactorMap(8,8) = ...
    currentLogBayesFactor;

end
