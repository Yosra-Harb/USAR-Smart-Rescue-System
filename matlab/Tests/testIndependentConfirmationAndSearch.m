function tests = testIndependentConfirmationAndSearch
%% اختبار بوابة التأكيد المستقل ودورة البحث المحلي المصححة

tests = functiontests(localfunctions);

end


function testUnconfirmedCandidateCannotActivateSearch(testCase)

probe = createLocalSearchProbe();
packet = createConfirmedPacket();
packet.isVictimDetected = false;

[canActivate, reason] = canActivateLocalSearch( ...
    probe, ...
    packet, ...
    packet.estimatedPosition);

verifyFalse(testCase, canActivate);
verifyEqual(testCase, reason, "UNCONFIRMED_CANDIDATE");

end


function testConfirmedCandidateCanActivateSearch(testCase)

probe = createLocalSearchProbe();
packet = createConfirmedPacket();

[canActivate, reason] = canActivateLocalSearch( ...
    probe, ...
    packet, ...
    packet.estimatedPosition);

verifyTrue(testCase, canActivate);
verifyEqual(testCase, reason, "VALID_CONFIRMED_CANDIDATE");

end


function testCompletedCenterIsSuppressed(testCase)

probe = createLocalSearchProbe();
probe.localSearch.completedCenters = [8 8];
packet = createConfirmedPacket();
packet.estimatedPosition = [9 9];

[canActivate, reason] = canActivateLocalSearch( ...
    probe, ...
    packet, ...
    packet.estimatedPosition);

verifyFalse(testCase, canActivate);
verifyEqual(testCase, reason, "COMPLETED_CENTER_SUPPRESSED");

end


function testCompletingSearchRecordsCenterAndResetsState(testCase)

probe = createLocalSearchProbe();
probe.localSearch.active = true;
probe.localSearch.center = [8 8];
probe.localSearch.path = [8 8; 8 9];
probe.localSearch.radius = 6;
probe.localSearch.currentStep = 3;
probe.localSearch.expansionCount = 4;

probe = completeLocalSearch( ...
    probe, ...
    "MAXIMUM_RADIUS_COMPLETED", ...
    true);

verifyFalse(testCase, probe.localSearch.active);
verifyEmpty(testCase, probe.localSearch.path);
verifyEmpty(testCase, probe.localSearch.center);
verifyEqual(testCase, probe.localSearch.radius, 2);
verifyEqual(testCase, probe.localSearch.currentStep, 1);
verifyEqual(testCase, probe.localSearch.completedCenters, [8 8]);
verifyEqual( ...
    testCase, ...
    probe.localSearch.lastCompletionReason, ...
    "MAXIMUM_RADIUS_COMPLETED");

end


function testMaximumRadiusPathExecutesBeforeCompletion(testCase)
% اختبار انحدار: كان المسار الجديد عند نصف القطر 6 يُنهى فور إنشائه.

scenario = createOpenScenario();
probe = createLocalSearchProbe();
probe.localSearch.active = true;
probe.localSearch.center = [8 8];
probe.localSearch.radius = 5;
probe.localSearch.path = [8 8];
probe.localSearch.currentStep = 2;
packet = createConfirmedPacket();

probe = adaptiveSearch(scenario, probe, packet);

verifyTrue(testCase, probe.localSearch.active);
verifyEqual(testCase, probe.localSearch.radius, 6);
verifyNotEmpty(testCase, probe.localSearch.path);
verifyEqual(testCase, probe.localSearch.currentStep, 1);
verifyEmpty(testCase, probe.localSearch.completedCenters);

probe.localSearch.currentStep = ...
    size(probe.localSearch.path,1) + 1;
probe = adaptiveSearch(scenario, probe, packet);

verifyFalse(testCase, probe.localSearch.active);
verifyEqual(testCase, probe.localSearch.completedCenters, [8 8]);

end


function testDuplicateMergeDoesNotDoubleCountOverlappingViews(testCase)

packetA = createConfirmedPacket();
packetB = packetA;
packetB.estimatedPosition = [9 8];
priorityPacket = struct( ...
    'priorityScore', 0.80, ...
    'priorityLevel', "HIGH");

victimA = registerVictim( ...
    1, packetA, priorityPacket, [2 2]);
victimB = registerVictim( ...
    2, packetB, priorityPacket, [2 3]);

mergedVictims = mergeDuplicateVictims( ...
    [victimA; victimB], ...
    3);

verifyNumElements(testCase, mergedVictims, 1);
verifyEqual(testCase, mergedVictims.independentViewCount, 1);
verifyEqual(testCase, mergedVictims.detectionCount, 1);
verifyEqual(testCase, mergedVictims.rawAssociationCount, 2);

end


function testDuplicateMergePreservesSeparatedViews(testCase)

packetA = createConfirmedPacket();
packetB = packetA;
packetB.estimatedPosition = [9 8];
priorityPacket = struct( ...
    'priorityScore', 0.80, ...
    'priorityLevel', "HIGH");

victimA = registerVictim( ...
    1, packetA, priorityPacket, [2 2]);
victimB = registerVictim( ...
    2, packetB, priorityPacket, [5 2]);

mergedVictims = mergeDuplicateVictims( ...
    [victimA; victimB], ...
    3);

verifyNumElements(testCase, mergedVictims, 1);
verifyEqual(testCase, mergedVictims.independentViewCount, 2);
verifyEqual(testCase, mergedVictims.detectionCount, 2);

end


function probe = createLocalSearchProbe()

probe = struct();
probe.position = [8 8];
probe.coveragePath = [8 8; 8 9];
probe.currentStep = 1;
probe.localSearch = struct( ...
    'active', false, ...
    'center', [], ...
    'path', [], ...
    'radius', 2, ...
    'maximumRadius', 6, ...
    'currentStep', 1, ...
    'expansionCount', 0, ...
    'completedCenters', zeros(0,2), ...
    'lastCompletionReason', "NONE");

end


function packet = createConfirmedPacket()

packet = struct( ...
    'isVictimDetected', true, ...
    'fusionScore', 0.80, ...
    'vitalityIndex', 0.80, ...
    'estimatedPosition', [8 8]);

end


function scenario = createOpenScenario()

gridSize = [15 15];
scenario = struct();
scenario.gridSize = gridSize;
scenario.environment = struct( ...
    'obstacles', false(gridSize), ...
    'accessibility', ones(gridSize), ...
    'movementCost', ones(gridSize));

end
