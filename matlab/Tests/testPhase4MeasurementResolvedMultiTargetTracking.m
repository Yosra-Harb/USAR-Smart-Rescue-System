function tests = testPhase4MeasurementResolvedMultiTargetTracking
%% اختبارات فصل الأهداف قبل انهيارها داخل خريطة Log-Odds.

tests = functiontests(localfunctions);

end


function testTwoRangedSourcesProduceTwoPeaks(testCase)

state = initializeSpatialBayesianLocalizationState([50 50],0.01);
packet = createProcessedPacket([20 20], [ ...
    createRadarObservation(6,0,0.65); ...
    createRadarObservation(6,90,0.70)]);

[peaks,diagnostics] = ...
    extractRangedMeasurementPeaks(packet,state);

verifyEqual(testCase,numel(peaks),2);
verifyEqual(testCase,diagnostics.acceptedObservationCount,2);
verifyEqual(testCase,string(peaks(1).sourceType), ...
    "RANGED_MEASUREMENT");
positions = sortrows([[peaks.row]',[peaks.column]']);
verifyEqual(testCase,positions,[20 26; 26 20], ...
    'AbsTol',1e-12);

end


function testRangedClutterWithoutPeriodicityIsRejected(testCase)

state = initializeSpatialBayesianLocalizationState([50 50],0.01);
trueObservation = createRadarObservation(6,0,0.30);
clutterObservation = createRadarObservation(7,90,0);
clutterObservation.heartbeatPeriodicity = 0;
packet = createProcessedPacket([20 20], [ ...
    trueObservation; clutterObservation]);

[peaks,diagnostics] = ...
    extractRangedMeasurementPeaks(packet,state);

verifyEqual(testCase,numel(peaks),1);
verifyEqual(testCase,diagnostics.rejectedObservationCount,1);
verifyEqual(testCase,peaks.row,20,'AbsTol',1e-12);
verifyEqual(testCase,peaks.column,26,'AbsTol',1e-12);

end


function testMapDuplicateIsSuppressedButDistantPeakRemains(testCase)

rangedPeak = createPeak(20,20,0.80,"RANGED_MEASUREMENT");
mapPeaks = [ ...
    createPeak(21,21,0.99,"MAP"); ...
    createPeak(30,30,0.90,"MAP")];

peaks = combineSpatialTrackingPeaks(mapPeaks,rangedPeak);

verifyEqual(testCase,numel(peaks),2);
verifyEqual(testCase,string(peaks(1).sourceType), ...
    "RANGED_MEASUREMENT");
verifyEqual(testCase,[peaks(2).row peaks(2).column],[30 30]);

end


function testTrackCountsIndependentRangedViews(testCase)

state = initializeSpatialBayesianLocalizationState([40 40],0.01);
peak = createPeak(20,20,0.70,"RANGED_MEASUREMENT");
observationPositions = [10 10; 13 10; 10 13];

for updateIndex = 1:3
    state.updateCount = updateIndex;
    state = updateBayesianVictimTracks( ...
        state,peak,observationPositions(updateIndex,:));
end

verifyEqual(testCase,numel(state.tracks),1);
verifyEqual(testCase, ...
    state.tracks.rangedMeasurementUpdateCount,3);
verifyEqual(testCase, ...
    state.tracks.independentRangedViewCount,3);
verifyEqual(testCase, ...
    size(state.tracks.rangedObservationPositions,1),3);
verifyEqual(testCase,string(state.tracks.status),"CONFIRMED");

end


function testLocalizationPacketPreservesAllCandidateSources(testCase)

fusionPacket = struct( ...
    'fusionScore',0.7, ...
    'confidence',0.8, ...
    'probePosition',[10 10], ...
    'timestamp',datetime("now"), ...
    'status',"VALID");
candidate = struct( ...
    'isVictim',true, ...
    'position',[10 10], ...
    'score',0.7, ...
    'confidence',0.8);
estimatedLocation = struct( ...
    'isDetected',true, ...
    'position',[20 20], ...
    'confidence',0.9, ...
    'candidatePeakCount',2, ...
    'selectionScore',0.9, ...
    'candidatePositions',[20 20; 30 30], ...
    'candidateConfidences',[0.9; 0.8], ...
    'candidateSourceTypes',[ ...
        "RANGED_MEASUREMENT";"RANGED_MEASUREMENT"]);

packet = buildLocalizationPacket( ...
    fusionPacket,candidate,estimatedLocation);

verifyEqual(testCase,packet.candidatePositions, ...
    [20 20;30 30]);
verifyEqual(testCase,packet.candidateConfidences, ...
    [0.9;0.8]);
verifyEqual(testCase,packet.candidateSourceTypes, ...
    ["RANGED_MEASUREMENT";"RANGED_MEASUREMENT"]);

end


function testResolvedRangedSourcesVetoFlatBasinMerge(testCase)

state = createFlatBasinState();

for trackIndex = 1:numel(state.tracks)
    state.tracks(trackIndex).independentRangedViewCount = 3;
    state.tracks(trackIndex).rangedMeasurementUpdateCount = 8;
    state.tracks(trackIndex).rangedObservationPositions = [ ...
        5 5; 8 5; 5 8];
end

victims = createVictims([10 11; 10 18]);
[consolidated,finalPeaks,report] = ...
    consolidateVictimRecordsByBayesianTracks(victims,state);

verifyEqual(testCase, ...
    numel(unique(report.preBasinTrackClusterIndex)),2);
verifyEqual(testCase,report.confirmedTrackCount,2);
verifyTrue(testCase, ...
    report.basinPairwiseMeasurementResolvedVeto(1,2));
verifyEqual(testCase,report.basinMergedClusterCount,0);
verifyEqual(testCase,numel(finalPeaks),2);
verifyEqual(testCase,numel(consolidated),2);

end


function testFlatBasinStillMergesWithoutResolvedRangedEvidence(testCase)

state = createFlatBasinState();
victims = createVictims([10 11; 10 18]);

[consolidated,finalPeaks,report] = ...
    consolidateVictimRecordsByBayesianTracks(victims,state);

verifyFalse(testCase, ...
    report.basinPairwiseMeasurementResolvedVeto(1,2));
verifyEqual(testCase,report.confirmedTrackCount,1);
verifyEqual(testCase,report.basinMergedClusterCount,1);
verifyEqual(testCase,numel(finalPeaks),1);
verifyEqual(testCase,numel(consolidated),1);

end


function testResolvedDuplicatePeaksMergeAcrossFlatSupportBridge(testCase)

state = createTwoResolvedPeakState(1.00);
victims = createVictims([10 10;10 14.5]);

[consolidated,finalPeaks,report] = ...
    consolidateVictimRecordsByBayesianTracks(victims,state);

verifyEqual(testCase, ...
    numel(unique(report.preBasinTrackClusterIndex)),2);
verifyEqual(testCase, ...
    report.basinPairwisePeakDistances(1,2),5, ...
    'AbsTol',1e-12);
verifyEqual(testCase, ...
    report.basinPairwiseSupportRetention(1,2),1, ...
    'AbsTol',1e-12);
verifyFalse(testCase, ...
    report.basinPairwiseMeasurementResolvedVeto(1,2));
verifyEqual(testCase,report.confirmedTrackCount,1);
verifyEqual(testCase,numel(finalPeaks),1);
verifyEqual(testCase,numel(consolidated),1);

end


function testResolvedCloseSourcesRemainSplitAcrossSupportValley(testCase)

state = createTwoResolvedPeakState(0.95);
victims = createVictims([10 10;10 14.5]);

[consolidated,finalPeaks,report] = ...
    consolidateVictimRecordsByBayesianTracks(victims,state);

verifyLessThanOrEqual(testCase, ...
    report.basinPairwiseSupportRetention(1,2),0.95);
verifyTrue(testCase, ...
    report.basinPairwiseMeasurementResolvedVeto(1,2));
verifyEqual(testCase,report.confirmedTrackCount,2);
verifyEqual(testCase,numel(finalPeaks),2);
verifyEqual(testCase,numel(consolidated),2);

end


function packet = createProcessedPacket(probePosition,observations)

packet = struct();
packet.probePosition = probePosition;
packet.spatialObservations = struct( ...
    'radar', observations, ...
    'thermal', observations([]), ...
    'acoustic', observations([]));

end


function observation = createRadarObservation( ...
    range,bearing,periodicity)

observation = struct( ...
    'range', range, ...
    'rangeStd', 0.60, ...
    'bearing', bearing, ...
    'bearingStd', 5.0, ...
    'strength', 0.40, ...
    'confidence', 0.70, ...
    'breathingPeriodicity', periodicity, ...
    'heartbeatPeriodicity', 0.50*periodicity, ...
    'sensorName', "UWB_Radar", ...
    'eventType', "MICRO_MOTION");

end


function peak = createPeak(row,column,probability,sourceType)

peak = struct( ...
    'row', row, ...
    'column', column, ...
    'probability', probability, ...
    'logOdds', log(probability/(1-probability)), ...
    'prominence', 0.5, ...
    'uncertaintyRadius', 1.0, ...
    'sourceType', string(sourceType));

end


function state = createFlatBasinState()

trackPositions = [10 10; 10 12; 10 17; 10 19];
state = initializeSpatialBayesianLocalizationState([40 40],0.01);
state.localizationMethod = "SpatialBayesianFusion";
state.tracks = repmat(createTrack(1,[1 1]),0,1);

for trackIndex = 1:size(trackPositions,1)
    state.tracks(end+1,1) = createTrack( ... %#ok<AGROW>
        trackIndex,trackPositions(trackIndex,:));
end

state.logOddsMap(:) = -8;
state.logOddsMap(7:13,7:22) = 12;
state.weightedObservationSupport(7:13,7:22) = 100;

end


function state = createTwoResolvedPeakState(bridgeRetention)

state = initializeSpatialBayesianLocalizationState([30 30],0.01);
state.localizationMethod = "SpatialBayesianFusion";
state.tracks = [ ...
    createTrack(1,[10 10]); ...
    createTrack(2,[10 14.5])];

for trackIndex = 1:numel(state.tracks)
    state.tracks(trackIndex).covariance = 0.05*eye(2);
    state.tracks(trackIndex).independentRangedViewCount = 3;
    state.tracks(trackIndex).rangedMeasurementUpdateCount = 8;
    state.tracks(trackIndex).rangedObservationPositions = [ ...
        5 5;8 5;5 8];
end

state.logOddsMap(:) = -8;
state.logOddsMap(10,10:15) = 12;
state.logOddsMap(10,10) = 16;
state.logOddsMap(10,15) = 16;
state.weightedObservationSupport(:) = 0;
state.weightedObservationSupport(10,10:15) = ...
    100*bridgeRetention;
state.weightedObservationSupport(10,10) = 100;
state.weightedObservationSupport(10,15) = 100;

end


function track = createTrack(trackID,position)

observationPositions = [ ...
    position+[-2 0]; ...
    position+[0 2]; ...
    position+[2 0]];

track = struct( ...
    'id', trackID, ...
    'position', position, ...
    'existenceProbability', 0.95, ...
    'covariance', eye(2), ...
    'updateCount', 8, ...
    'independentViewCount', 3, ...
    'observationPositions', observationPositions, ...
    'maximumProbability', 0.98, ...
    'missedUpdateCount', 0, ...
    'status', "CONFIRMED", ...
    'lastUpdateStep', 10, ...
    'updateStepHistory', (1:8)', ...
    'rangedMeasurementUpdateCount', 0, ...
    'independentRangedViewCount', 0, ...
    'rangedObservationPositions', zeros(0,2));

end


function victims = createVictims(positions)

victims = repmat(createVictim(1,[1 1]),0,1);
for victimIndex = 1:size(positions,1)
    victims(end+1,1) = createVictim( ... %#ok<AGROW>
        victimIndex,positions(victimIndex,:));
end

end


function victim = createVictim(victimID,position)

currentTime = datetime("now");
observationPositions = [ ...
    position+[-2 0]; position+[0 2]; position+[2 0]];
victim = struct( ...
    'id', victimID, ...
    'position', position, ...
    'vitalityIndex', 0.5, ...
    'victimCondition', "MODERATE", ...
    'priorityScore', 0.5, ...
    'priorityLevel', "MEDIUM", ...
    'firstDetectionTime', currentTime, ...
    'lastUpdateTime', currentTime, ...
    'detectionCount', 3, ...
    'independentViewCount', 3, ...
    'rawAssociationCount', 5, ...
    'observationPositions', observationPositions, ...
    'lastObservationPosition', observationPositions(end,:));

end
