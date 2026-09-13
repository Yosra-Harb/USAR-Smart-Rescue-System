function tests = testPhase4LogOddsContrastPeaks
%% اختبارات استخراج القمم عندما يضغط posterior فروق Log-Odds.

tests = functiontests(localfunctions);

end


function setupOnce(testCase)

testsFolder = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testsFolder);
addpath(fullfile(projectRoot, 'Main'), '-begin');
testCase.TestData.projectRoot = setupProjectPaths();

end


function testCompressedPosteriorPreservesLogOddsPeak(testCase)

state = buildSpatialState();

backgroundLogOdds = 12.0;
peakLogOdds = 15.5;
state.logOddsMap(7:9,7:9) = backgroundLogOdds;
state.probabilityMap(7:9,7:9) = logistic(backgroundLogOdds);
state.logOddsMap(8,8) = peakLogOdds;
state.probabilityMap(8,8) = logistic(peakLogOdds);
state.weightedObservationSupport(8,8) = 12;

[peaks, ~] = detectBayesianPosteriorPeaks(state);

verifyEqual(testCase, numel(peaks), 1);
verifyEqual(testCase, [peaks.row peaks.column], [8 8]);
verifyGreaterThan(testCase, peaks.prominence, 0.35);

end


function testSaturatedPlateauUsesUniqueWeightedSupport(testCase)

state = buildSpatialState();

config = constants();
limit = config.spatialBayesian.maximumAbsoluteLogOdds;
state.logOddsMap(7:9,7:9) = limit;
state.probabilityMap(7:9,7:9) = logistic(limit);
state.weightedObservationSupport(7:9,7:9) = 8;
state.weightedObservationSupport(8,8) = 10;

[peaks, ~] = detectBayesianPosteriorPeaks(state);

verifyEqual(testCase, numel(peaks), 1);
verifyEqual(testCase, [peaks.row peaks.column], [8 8]);

end


function testFlatSaturatedPlateauIsRejected(testCase)

state = buildSpatialState();

config = constants();
limit = config.spatialBayesian.maximumAbsoluteLogOdds;
state.logOddsMap(7:9,7:9) = limit;
state.probabilityMap(7:9,7:9) = logistic(limit);
state.weightedObservationSupport(7:9,7:9) = 10;

[peaks, ~] = detectBayesianPosteriorPeaks(state);

verifyEmpty(testCase, peaks);

end


function state = buildSpatialState()

state = initializeSpatialBayesianLocalizationState([15 15], 0.01);
state.updateCount = 1;
state.observationCount(8,8) = 5;
state.lastObservationStep(8,8) = 1;
state.lastVisibilityMask(8,8) = true;
state.lastMeasurementLogBayesFactorMap(8,8) = 0.25;

end


function probability = logistic(logOdds)

probability = 1 ./ (1 + exp(-logOdds));

end
