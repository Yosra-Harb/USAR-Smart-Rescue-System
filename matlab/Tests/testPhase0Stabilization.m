function tests = testPhase0Stabilization
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
testsFolder = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testsFolder);
addpath(fullfile(projectRoot, 'Main'), '-end');
resolvedRoot = setupProjectPaths();
testCase.TestData.projectRoot = resolvedRoot;
end

function testCentralConfigurationIsValid(testCase)
config = constants();

verifyGreaterThanOrEqual(testCase, config.detection.fusionScore, 0);
verifyLessThanOrEqual(testCase, config.detection.fusionScore, 1);
verifyGreaterThanOrEqual(testCase, config.detection.confidence, 0);
verifyLessThanOrEqual(testCase, config.detection.confidence, 1);
verifyGreaterThan(testCase, config.clustering.maximumHistory, 0);
verifyGreaterThan(testCase, config.clustering.minimumPoints, 0);
verifyLessThanOrEqual( ...
    testCase, ...
    config.clustering.minimumPoints, ...
    config.clustering.maximumHistory);
verifyGreaterThan( ...
    testCase, ...
    config.victimDatabase.minimumIndependentViewDistance, ...
    0);
verifyGreaterThanOrEqual( ...
    testCase, ...
    config.reporting.minimumIndependentViewCount, ...
    2);
end

function testDecisionUsesSuspicionThresholds(testCase)
config = constants();

decision = decisionEngine( ...
    config.suspicion.fusionScore, ...
    config.suspicion.vitalityIndex, ...
    false);

verifyEqual(testCase, decision, "SUSPICIOUS");

decision = decisionEngine( ...
    config.suspicion.fusionScore - eps, ...
    config.suspicion.vitalityIndex, ...
    false);

verifyEqual(testCase, decision, "RESUME_SEARCH");
end

function testCandidateUsesConfirmationThresholds(testCase)
config = constants();

fusionPacket = struct( ...
    'probePosition', [10 20], ...
    'fusionScore', config.detection.fusionScore, ...
    'confidence', config.detection.confidence);

candidate = candidateDetection(fusionPacket);
verifyTrue(testCase, candidate.isVictim);

fusionPacket.confidence = config.detection.confidence - eps;
candidate = candidateDetection(fusionPacket);
verifyFalse(testCase, candidate.isVictim);
end

function testClusteringStateDoesNotLeakAcrossRuns(testCase)
candidate = struct( ...
    'isVictim', true, ...
    'position', [5 5], ...
    'score', 0.8, ...
    'confidence', 0.9);

stateA = struct('pointHistory', zeros(0,2));

for sampleIndex = 1:3
    [clusterA, stateA] = victimClustering(candidate, stateA);
end

verifyTrue(testCase, clusterA.hasVictim);

stateB = struct('pointHistory', zeros(0,2));
[clusterB, stateB] = victimClustering(candidate, stateB);

verifyFalse(testCase, clusterB.hasVictim);
verifySize(testCase, stateB.pointHistory, [1 2]);
end

function testEvaluationUsesOneToOneMatching(testCase)
detectedVictims = [10 10];
groundTruth = [10 10; 11 10];

[TP, TN, FP, FN] = ...
    confusionMatrix(detectedVictims, groundTruth);

verifyEqual(testCase, TP, 1);
verifyEqual(testCase, TN, 0);
verifyEqual(testCase, FP, 0);
verifyEqual(testCase, FN, 1);
end

function testLocalPathControlsProbeMovement(testCase)
probe = struct();
probe.finished = false;
probe.position = [1 1];
probe.path = [1 1];
probe.currentStep = 1;
probe.coveragePath = [1 1; 1 2];
probe.visitedCells = false(3,3);
probe.visitedCells(1,1) = true;
probe.localSearch = struct( ...
    'active', true, ...
    'path', [2 2; 2 3], ...
    'currentStep', 1);

probe = moveProbe(probe);

verifyEqual(testCase, probe.position, [2 2]);
verifyEqual(testCase, probe.currentStep, 1);
verifyEqual(testCase, probe.localSearch.currentStep, 2);
verifyEqual(testCase, probe.state, "LOCAL_SEARCH");
end

function testAdaptiveSearchDoesNotResetUnfinishedPath(testCase)
scenario = struct();

probe = struct();
probe.position = [2 2];
probe.localSearch = struct( ...
    'active', true, ...
    'center', [2 2], ...
    'path', [2 2; 2 3; 3 3], ...
    'radius', 2, ...
    'maximumRadius', 6, ...
    'currentStep', 2, ...
    'expansionCount', 0);

vitalityPacket = struct( ...
    'fusionScore', 0.8, ...
    'vitalityIndex', 0.8, ...
    'estimatedPosition', [2 2]);

originalPath = probe.localSearch.path;
probe = adaptiveSearch(scenario, probe, vitalityPacket);

verifyEqual(testCase, probe.localSearch.path, originalPath);
verifyEqual(testCase, probe.localSearch.radius, 2);
verifyEqual(testCase, probe.localSearch.currentStep, 2);
end
