function tests = testPhase3BayesianMapAndPeaks
%% اختبار تراكم Log-Odds واستخراج القمم البايزية.

tests = functiontests(localfunctions);

end


function testRepeatedStrongMeasurementsIncreasePosterior(testCase)

scenario = buildScenario();
state = initializeBayesianLocalizationState([20 20], 0.01);
packet = buildProcessedPacket([10 10]);
initialMaximum = max(state.probabilityMap(:));

for updateIndex = 1:8
    [state, diagnostics] = updateBayesianTBDMap( ...
        state, scenario, packet);
end

verifyGreaterThan(testCase, ...
    max(state.probabilityMap(:)), ...
    initialMaximum);
verifyGreaterThan(testCase, diagnostics.updatedCellCount, 0);
verifyTrue(testCase, all(isfinite(state.logOddsMap(:))));
verifyTrue(testCase, all(state.probabilityMap(:) >= 0));
verifyTrue(testCase, all(state.probabilityMap(:) <= 1));

end


function testUnsupportedPeakIsRejected(testCase)

state = initializeBayesianLocalizationState([15 15], 0.01);
state.probabilityMap(8,8) = 0.95;
state.logOddsMap(8,8) = log(0.95/0.05);

[peaks, state] = detectBayesianPosteriorPeaks(state);

verifyEmpty(testCase, peaks);
verifyEqual(testCase, state.lastCandidatePeakCount, 0);

end


function testTwoSeparatedSupportedPeaksArePreserved(testCase)

state = initializeBayesianLocalizationState([20 20], 0.01);
state.observationCount(:) = 5;
state.weightedObservationSupport(:) = 4;
state.probabilityMap(:) = 0.08;
state.logOddsMap(:) = log(0.08/0.92);

state.probabilityMap(6,6) = 0.91;
state.probabilityMap(15,15) = 0.87;
state.logOddsMap(6,6) = log(0.91/0.09);
state.logOddsMap(15,15) = log(0.87/0.13);

[peaks, ~] = detectBayesianPosteriorPeaks(state);
positions = [[peaks.row]', [peaks.column]'];

verifyEqual(testCase, numel(peaks), 2);
verifyTrue(testCase, ismember([6 6], positions, 'rows'));
verifyTrue(testCase, ismember([15 15], positions, 'rows'));

end


function scenario = buildScenario()

gridSize = [20 20];
scenario = struct();
scenario.gridSize = gridSize;
scenario.environment = struct( ...
    'debris', zeros(gridSize), ...
    'attenuation', zeros(gridSize), ...
    'noise', 0.02 * ones(gridSize), ...
    'obstacles', false(gridSize));

end


function packet = buildProcessedPacket(position)

packet = struct();
packet.features = struct( ...
    'radarFeature', 0.50, ...
    'thermalFeature', 0.40, ...
    'acousticFeature', 0.30);
packet.qualityReport = struct( ...
    'radarReliability', 0.95, ...
    'thermalReliability', 0.90, ...
    'acousticReliability', 0.85, ...
    'overallQuality', 0.90);
packet.probePosition = position;
packet.status = "VALID";

end
