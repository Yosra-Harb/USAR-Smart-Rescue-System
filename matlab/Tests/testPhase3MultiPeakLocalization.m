function tests = testPhase3MultiPeakLocalization
%% ============================================================
% اختبارات Phase 3 لفصل الضحايا المتقاربين دون تخفيض العتبات
% أو استخدام Ground Truth داخل خوارزمية التوطين.
%% ============================================================

tests = functiontests(localfunctions);

end


function setupOnce(testCase)

testsFolder = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testsFolder);
addpath(fullfile(projectRoot, 'Main'), '-end');
resolvedRoot = setupProjectPaths();
testCase.TestData.projectRoot = resolvedRoot;

end


function testDetectorKeepsTwoReliablePeaksSixCellsApart(testCase)

[evidenceMap, observationCount] = createTwoPeakMap();
config = constants();

peaks = detectReliableLocalPeaks( ...
    evidenceMap, ...
    observationCount, ...
    config.detection.fusionScore, ...
    config.clustering.minimumPoints);

verifyEqual(testCase, numel(peaks), 2);
positions = [[peaks.row]' [peaks.column]'];
verifyTrue(testCase, ismember([11 10], positions, 'rows'));
verifyTrue(testCase, ismember([11 16], positions, 'rows'));

end


function testNonMaximumSuppressionRemovesNearbyDuplicatePeak(testCase)

evidenceMap = zeros(21,21);
observationCount = zeros(21,21);
evidenceMap(11,10) = 0.70;
evidenceMap(11,12) = 0.68;
evidenceMap(10:12,9:13) = max( ...
    evidenceMap(10:12,9:13), ...
    0.30);
evidenceMap(11,10) = 0.70;
evidenceMap(11,12) = 0.68;
observationCount(9:13,8:14) = 5;
config = constants();

peaks = detectReliableLocalPeaks( ...
    evidenceMap, ...
    observationCount, ...
    config.detection.fusionScore, ...
    config.clustering.minimumPoints);

verifyEqual(testCase, numel(peaks), 1);
verifyEqual(testCase, [peaks.row peaks.column], [11 10]);

end


function testCandidateNearWeakerPeakIsNotPulledToGlobalMaximum(testCase)

[evidenceMap, observationCount] = createTwoPeakMap();
localizationState = createLocalizationState( ...
    evidenceMap, ...
    observationCount);
candidate = createCandidate([11 10]);

[estimatedLocation, localizationState] = ... %#ok<ASGLU>
    estimateLocationFromEvidenceMap( ...
        localizationState, ...
        candidate);

verifyTrue(testCase, estimatedLocation.isDetected);
verifyEqual(testCase, estimatedLocation.position, [11 10]);
verifyEqual(testCase, estimatedLocation.candidatePeakCount, 2);
verifyGreaterThan(testCase, estimatedLocation.selectionScore, 0);

end


function testTwoCandidatesResolveToDistinctVictimLocations(testCase)

[evidenceMap, observationCount] = createTwoPeakMap();
firstState = createLocalizationState( ...
    evidenceMap, ...
    observationCount);
secondState = firstState;

[firstEstimate, firstState] = ... %#ok<ASGLU>
    estimateLocationFromEvidenceMap( ...
        firstState, ...
        createCandidate([11 10]));
[secondEstimate, secondState] = ... %#ok<ASGLU>
    estimateLocationFromEvidenceMap( ...
        secondState, ...
        createCandidate([11 16]));

positionDifference = ...
    firstEstimate.position - secondEstimate.position;
estimatedSeparation = sqrt(sum(positionDifference.^2));
config = constants();

verifyTrue(testCase, firstEstimate.isDetected);
verifyTrue(testCase, secondEstimate.isDetected);
verifyGreaterThan( ...
    testCase, ...
    estimatedSeparation, ...
    config.victimDatabase.associationDistance);
verifyEqual(testCase, firstEstimate.position, [11 10]);
verifyEqual(testCase, secondEstimate.position, [11 16]);

end


function testSingleBroadPeakIsNotSplitByCandidatePosition(testCase)

[rowGrid, columnGrid] = ndgrid(1:21, 1:21);
distanceSquared = ...
    (rowGrid - 11).^2 + (columnGrid - 11).^2;
evidenceMap = 0.80 .* exp(-distanceSquared ./ (2 * 2^2));
observationCount = 5 .* ones(21,21);
config = constants();

peaks = detectReliableLocalPeaks( ...
    evidenceMap, ...
    observationCount, ...
    config.detection.fusionScore, ...
    config.clustering.minimumPoints);

verifyEqual(testCase, numel(peaks), 1);

firstState = createLocalizationState( ...
    evidenceMap, ...
    observationCount);
secondState = firstState;
[firstEstimate, firstState] = ... %#ok<ASGLU>
    estimateLocationFromEvidenceMap( ...
        firstState, ...
        createCandidate([11 8]));
[secondEstimate, secondState] = ... %#ok<ASGLU>
    estimateLocationFromEvidenceMap( ...
        secondState, ...
        createCandidate([11 14]));

verifyEqual( ...
    testCase, ...
    firstEstimate.position, ...
    secondEstimate.position);
verifyEqual(testCase, firstEstimate.position, [11 11]);

end


function testProbeMemoryInitializesMultiPeakState(testCase)

memory = probeMemory();

verifyTrue( ...
    testCase, ...
    isfield( ...
        memory.localizationState, ...
        'lastCandidatePeakCount'));
verifyEqual( ...
    testCase, ...
    memory.localizationState.lastCandidatePeakCount, ...
    0);

end


function testLocalizationPacketSupportsNewAndLegacyResults(testCase)

fusionPacket = struct( ...
    'fusionScore', 0.62, ...
    'confidence', 0.85, ...
    'probePosition', [11 10], ...
    'timestamp', datetime("now"), ...
    'status', "VALID");
candidate = createCandidate([11 10]);
estimatedLocation = struct( ...
    'isDetected', true, ...
    'position', [11 10], ...
    'confidence', 0.62, ...
    'peakValue', 0.62, ...
    'supportingCells', 1, ...
    'candidatePeakCount', 2, ...
    'selectionScore', 0.93);

currentPacket = buildLocalizationPacket( ...
    fusionPacket, ...
    candidate, ...
    estimatedLocation);

verifyEqual(testCase, currentPacket.candidatePeakCount, 2);
verifyEqual( ...
    testCase, ...
    currentPacket.peakSelectionScore, ...
    0.93, ...
    'AbsTol', 1e-12);

legacyEstimate = rmfield( ...
    estimatedLocation, ...
    {'candidatePeakCount', 'selectionScore'});
legacyPacket = buildLocalizationPacket( ...
    fusionPacket, ...
    candidate, ...
    legacyEstimate);

verifyEqual(testCase, legacyPacket.candidatePeakCount, 0);
verifyEqual(testCase, legacyPacket.peakSelectionScore, 0);

end


function testFlatEvidencePlateauUsesWeightedSupport(testCase)
% إعادة إنتاج الانحدار الذي كشفه اختبار Phase 1: ثلاث قراءات
% متساوية القوة يجب ألا تختفي بسبب بروز صفري لخريطة الدليل.

probe = struct();
probe.visitedCells = false(16,16);
probe.memory = probeMemory();
observationPositions = [ ...
    8 7; ...
    8 8; ...
    8 9];

for observationIndex = 1:size(observationPositions,1)
    fusionPacket = struct( ...
        'probePosition', observationPositions(observationIndex,:), ...
        'fusionScore', 0.80, ...
        'confidence', 0.90, ...
        'timestamp', datetime("now"), ...
        'status', "VALID");
    probe = updateEvidenceMap(probe, fusionPacket);
end

[localizationPacket, ~] = localizationManager( ...
    fusionPacket, ...
    probe.memory.localizationState);

verifyTrue(testCase, localizationPacket.isVictimDetected);
verifySize(testCase, localizationPacket.estimatedPosition, [1 2]);
verifyLessThanOrEqual( ...
    testCase, ...
    norm(localizationPacket.estimatedPosition - [8 8]), ...
    1);

end


function [evidenceMap, observationCount] = createTwoPeakMap()

evidenceMap = zeros(21,21);
observationCount = zeros(21,21);

evidenceMap(10:12,9:11) = 0.40;
evidenceMap(11,10) = 0.62;
observationCount(9:13,8:12) = 5;

evidenceMap(10:12,15:17) = 0.44;
evidenceMap(11,16) = 0.72;
observationCount(9:13,14:18) = 5;

end


function localizationState = createLocalizationState( ...
    evidenceMap, ...
    observationCount)

localizationState = struct();
localizationState.evidenceMap = evidenceMap;
localizationState.observationCount = observationCount;
localizationState.lastEstimatedPosition = [];
localizationState.lastPeakValue = 0;
localizationState.lastCandidatePeakCount = 0;

end


function candidate = createCandidate(position)

candidate = struct( ...
    'isVictim', true, ...
    'position', position, ...
    'score', 0.70, ...
    'confidence', 0.85);

end
