function tests = testPhase3BayesianLikelihood
%% اختبار نموذج القياس البايزي ومنع تسريب Ground Truth.

tests = functiontests(localfunctions);

end


function testGroundTruthChangesDoNotChangeLikelihood(testCase)

scenarioA = buildScenario();
scenarioB = scenarioA;
scenarioB.victims = [1 1; 20 20; 5 17];
scenarioB.groundTruth.locations = [2 19; 18 3];
scenarioB.groundTruth.vitalStrength = [0.01; 1.0];
scenarioB.groundTruth.burialDepth = [1.0; 0.0];
scenarioB.environment.vitalSigns = rand(scenarioB.gridSize);

packet = buildProcessedPacket(0.35, 0.25, 0.15, [10 10]);

resultA = calculateBayesianMeasurementLogBayesFactors( ...
    packet, scenarioA, [10 10], [12 11]);
resultB = calculateBayesianMeasurementLogBayesFactors( ...
    packet, scenarioB, [10 10], [12 11]);

verifyEqual(testCase, resultA, resultB, 'AbsTol', 1e-12);

end


function testStrongMeasurementIsMoreSupportiveThanZero(testCase)

scenario = buildScenario();
strongPacket = buildProcessedPacket(0.45, 0.35, 0.25, [10 10]);
zeroPacket = buildProcessedPacket(0, 0, 0, [10 10]);

strongResult = calculateBayesianMeasurementLogBayesFactors( ...
    strongPacket, scenario, [10 10], [10 10]);
zeroResult = calculateBayesianMeasurementLogBayesFactors( ...
    zeroPacket, scenario, [10 10], [10 10]);

strongEvidence = strongResult.radar.logBayesFactor + ...
    strongResult.thermal.logBayesFactor + ...
    strongResult.acoustic.logBayesFactor;
zeroEvidence = zeroResult.radar.logBayesFactor + ...
    zeroResult.thermal.logBayesFactor + ...
    zeroResult.acoustic.logBayesFactor;

verifyGreaterThan(testCase, strongEvidence, zeroEvidence);
verifyGreaterThan(testCase, strongEvidence, 0);

end


function testLikelihoodOutputsRemainFiniteAndBounded(testCase)

scenario = buildScenario();
packet = buildProcessedPacket(1, 0, 0.4, [2 2]);
result = calculateBayesianMeasurementLogBayesFactors( ...
    packet, scenario, [2 2], [18 18]);
config = constants();

for sensorName = ["radar", "thermal", "acoustic"]
    sensorResult = result.(char(sensorName));
    verifyTrue(testCase, isfinite(sensorResult.logBayesFactor));
    verifyLessThanOrEqual(testCase, ...
        abs(sensorResult.logBayesFactor), ...
        config.bayesian.singleSensorLogBayesFactorLimit);
    verifyGreaterThanOrEqual(testCase, ...
        sensorResult.expectedSignalMean, 0);
    verifyLessThanOrEqual(testCase, ...
        sensorResult.expectedSignalMean, 1);
end

end


function scenario = buildScenario()

gridSize = [20 20];
scenario = struct();
scenario.gridSize = gridSize;
scenario.environment = struct( ...
    'debris', 0.10 * ones(gridSize), ...
    'attenuation', 0.05 * ones(gridSize), ...
    'noise', 0.08 * ones(gridSize), ...
    'obstacles', false(gridSize), ...
    'vitalSigns', zeros(gridSize));
scenario.victims = [10 10];
scenario.groundTruth = struct( ...
    'locations', [10 10], ...
    'vitalStrength', 0.8, ...
    'burialDepth', 0.2);

end


function packet = buildProcessedPacket(radar, thermal, acoustic, position)

packet = struct();
packet.features = struct( ...
    'radarFeature', radar, ...
    'thermalFeature', thermal, ...
    'acousticFeature', acoustic);
packet.qualityReport = struct( ...
    'radarReliability', 0.9, ...
    'thermalReliability', 0.8, ...
    'acousticReliability', 0.7, ...
    'overallQuality', 0.8);
packet.probePosition = position;
packet.status = "VALID";

end
