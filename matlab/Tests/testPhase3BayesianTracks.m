function tests = testPhase3BayesianTracks
%% اختبار الارتباط والتأكيد المستقل لمسارات الضحايا.

tests = functiontests(localfunctions);

end


function testTrackNeedsIndependentViewsForConfirmation(testCase)

state = initializeBayesianLocalizationState([30 30], 0.01);
peak = buildPeak(12, 14, 0.90);

state.updateCount = 1;
state = updateBayesianVictimTracks(state, peak, [10 10]);
state.updateCount = 2;
state = updateBayesianVictimTracks(state, peak, [10 10]);

verifyEqual(testCase, numel(state.tracks), 1);
verifyEqual(testCase, ...
    state.tracks.independentViewCount, 1);
verifyEqual(testCase, ...
    string(state.tracks.status), "PROVISIONAL");

state.updateCount = 3;
state = updateBayesianVictimTracks(state, peak, [13 10]);
state.updateCount = 4;
state = updateBayesianVictimTracks(state, peak, [10 13]);

verifyEqual(testCase, ...
    state.tracks.independentViewCount, 3);
verifyEqual(testCase, ...
    string(state.tracks.status), "CONFIRMED");

end


function testSeparatedPeaksCreateSeparateTracks(testCase)

state = initializeBayesianLocalizationState([30 30], 0.01);
peaks = [ ...
    buildPeak(5, 5, 0.85); ...
    buildPeak(22, 22, 0.88)];
state.updateCount = 1;
state = updateBayesianVictimTracks(state, peaks, [10 10]);

verifyEqual(testCase, numel(state.tracks), 2);
verifyNotEqual(testCase, ...
    state.tracks(1).id, state.tracks(2).id);

end


function testSpatialTrackIsRetainedOutsideCurrentVisibility(testCase)

state = initializeSpatialBayesianLocalizationState( ...
    [30 30], 0.01);
peak = buildPeak(12, 14, 0.90);

state.updateCount = 1;
state = updateBayesianVictimTracks( ...
    state, peak, [10 10]);
originalProbability = ...
    state.tracks.existenceProbability;

state.lastVisibilityMask(:) = false;
state.updateCount = 2;
state = updateBayesianVictimTracks( ...
    state, peak([]), [28 28]);

verifyEqual(testCase, numel(state.tracks), 1);
verifyEqual(testCase, ...
    state.tracks.existenceProbability, ...
    originalProbability, 'AbsTol', 1e-12);
verifyEqual(testCase, ...
    state.tracks.missedUpdateCount, 0);

end


function testSpatialTrackDecaysOnlyWhenObservableAndMissed(testCase)

state = initializeSpatialBayesianLocalizationState( ...
    [30 30], 0.01);
peak = buildPeak(12, 14, 0.90);

state.updateCount = 1;
state = updateBayesianVictimTracks( ...
    state, peak, [10 10]);
originalProbability = ...
    state.tracks.existenceProbability;

state.lastVisibilityMask(:) = false;
state.lastVisibilityMask(12,14) = true;
state.updateCount = 2;
state = updateBayesianVictimTracks( ...
    state, peak([]), [10 10]);

verifyLessThan(testCase, ...
    state.tracks.existenceProbability, ...
    originalProbability);
verifyEqual(testCase, ...
    state.tracks.missedUpdateCount, 1);

end


function testSpatialTrackUsesConditionedEvidenceWhenPeakSuppressed(testCase)

state = initializeSpatialBayesianLocalizationState( ...
    [30 30], 0.01);
peak = buildPeak(12, 14, 0.90);

state.updateCount = 1;
state = updateBayesianVictimTracks( ...
    state, peak, [10 10]);
originalProbability = ...
    state.tracks.existenceProbability;

state.updateCount = 2;
state.lastVisibilityMask(:) = false;
state.lastVisibilityMask(12,14) = true;
state.lastObservationStep(12,14) = 2;
state.probabilityMap(12,14) = 0.96;
state.logOddsMap(12,14) = log(0.96/0.04);
state.lastMeasurementLogBayesFactorMap(12,14) = 0.80;

state = updateBayesianVictimTracks( ...
    state, peak([]), [14 10]);

state.updateCount = 3;
state.lastObservationStep(12,14) = 3;
state.lastMeasurementLogBayesFactorMap(12,14) = 0.70;
state = updateBayesianVictimTracks( ...
    state, peak([]), [10 14]);

verifyEqual(testCase, state.tracks.updateCount, 3);
verifyEqual(testCase, ...
    state.tracks.independentViewCount, 3);
verifyEqual(testCase, ...
    state.tracks.missedUpdateCount, 0);
verifyGreaterThanOrEqual(testCase, ...
    state.tracks.existenceProbability, ...
    originalProbability);
verifyEqual(testCase, ...
    string(state.tracks.status), "CONFIRMED");

end


function testHistoricalPosteriorAloneDoesNotMaintainTrack(testCase)

state = initializeSpatialBayesianLocalizationState( ...
    [30 30], 0.01);
peak = buildPeak(12, 14, 0.90);

state.updateCount = 1;
state = updateBayesianVictimTracks( ...
    state, peak, [10 10]);
originalProbability = ...
    state.tracks.existenceProbability;

state.updateCount = 2;
state.lastVisibilityMask(:) = false;
state.lastVisibilityMask(12,14) = true;
state.lastObservationStep(12,14) = 2;
state.probabilityMap(12,14) = 0.99;
state.logOddsMap(12,14) = log(0.99/0.01);
state.lastMeasurementLogBayesFactorMap(12,14) = -0.20;

state = updateBayesianVictimTracks( ...
    state, peak([]), [14 10]);

verifyEqual(testCase, state.tracks.updateCount, 1);
verifyEqual(testCase, ...
    state.tracks.independentViewCount, 1);
verifyEqual(testCase, ...
    state.tracks.missedUpdateCount, 1);
verifyLessThan(testCase, ...
    state.tracks.existenceProbability, ...
    originalProbability);

end


function peak = buildPeak(row, column, probability)

peak = struct( ...
    'row', row, ...
    'column', column, ...
    'probability', probability, ...
    'logOdds', log(probability/(1-probability)), ...
    'prominence', 0.2, ...
    'uncertaintyRadius', 1.0);

end
