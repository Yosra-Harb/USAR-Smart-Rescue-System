function tests = testPhase4BayesianTrackConsolidation
%% اختبارات دمج المسارات البايزية المؤكدة قبل التقرير النهائي.

tests = functiontests(localfunctions);

end


function setupOnce(testCase)

testsFolder = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testsFolder);
addpath(fullfile(projectRoot, 'Main'), '-begin');
testCase.TestData.projectRoot = setupProjectPaths();

end


function testConnectedDuplicateConfirmedTracksBecomeOneVictim(testCase)

trackPositions = [ ...
    8 16;
    10 15;
    13 14];

state = createBayesianState(trackPositions);
victims = createVictimArray(trackPositions);

[consolidated, finalPeaks, report] = ...
    consolidateVictimRecordsByBayesianTracks( ...
        victims, ...
        state);

verifyEqual(testCase, report.rawConfirmedTrackCount, 3);
verifyEqual(testCase, report.confirmedTrackCount, 1);
verifyEqual(testCase, numel(unique(report.trackClusterIndex)), 1);
verifyEqual(testCase, report.matchedRecordCount, 3);
verifyEqual(testCase, numel(finalPeaks), 1);
verifyEqual(testCase, numel(consolidated), 1);

end


function testResolvableConfirmedTracksRemainDistinct(testCase)

trackPositions = [ ...
    10 10;
    10 16];

state = createBayesianState(trackPositions);
victims = createVictimArray(trackPositions);

[consolidated, finalPeaks, report] = ...
    consolidateVictimRecordsByBayesianTracks( ...
        victims, ...
        state);

verifyEqual(testCase, report.rawConfirmedTrackCount, 2);
verifyEqual(testCase, report.confirmedTrackCount, 2);
verifyEqual(testCase, numel(unique(report.trackClusterIndex)), 2);
verifyEqual(testCase, report.matchedRecordCount, 2);
verifyEqual(testCase, numel(finalPeaks), 2);
verifyEqual(testCase, numel(consolidated), 2);

actualPositions = reshape( ...
    [consolidated.position], ...
    2, ...
    [])';

verifyEqual( ...
    testCase, ...
    sortrows(actualPositions), ...
    sortrows(trackPositions));

end


function testUncertaintyGateAssociatesNearbyVictimRecord(testCase)

state = createBayesianState([10 10]);
victims = createVictimArray([10 14.5]);

[consolidated, finalPeaks, report] = ...
    consolidateVictimRecordsByBayesianTracks( ...
        victims, ...
        state);

verifyEqual(testCase, report.confirmedTrackCount, 1);
verifyEqual(testCase, report.matchedRecordCount, 1);
verifyEqual(testCase, report.unmatchedRecordCount, 0);
verifyEqual(testCase, numel(finalPeaks), 1);
verifyEqual(testCase, numel(consolidated), 1);
verifyGreaterThan(testCase, report.assignmentDistances, 3.5);
verifyGreaterThanOrEqual( ...
    testCase, ...
    report.assignmentGates, ...
    report.assignmentDistances);
verifyTrue(testCase, report.usedUncertaintyRescue);

end


function testUncertaintyGateIsDisabledForAmbiguousMultipleRecords(testCase)

trackPositions = [ ...
    10 10;
    25 25];
recordPositions = [ ...
    10 14.5;
    25 29.5];

state = createBayesianState(trackPositions);
victims = createVictimArray(recordPositions);

[consolidated, finalPeaks, report] = ...
    consolidateVictimRecordsByBayesianTracks( ...
        victims, ...
        state);

verifyEqual(testCase, report.confirmedTrackCount, 2);
verifyEqual(testCase, report.matchedRecordCount, 0);
verifyEqual(testCase, report.unmatchedRecordCount, 2);
verifyEqual(testCase, numel(finalPeaks), 2);
verifyEmpty(testCase, consolidated);
verifyFalse(testCase, any(report.usedUncertaintyRescue));

end


function testUncertainAdjacentConfirmedTracksBecomeOneCluster(testCase)

trackPositions = [ ...
    10 10;
    10 14.75];
state = createBayesianState(trackPositions);
state.tracks(1).covariance = 3.0 * eye(2);
state.tracks(2).covariance = 3.0 * eye(2);
victims = createVictimArray(trackPositions);

[consolidated, finalPeaks, report] = ...
    consolidateVictimRecordsByBayesianTracks( ...
        victims, ...
        state);

verifyEqual(testCase, report.rawConfirmedTrackCount, 2);
verifyEqual(testCase, report.confirmedTrackCount, 1);
verifyEqual(testCase, numel(unique(report.trackClusterIndex)), 1);
verifyEqual(testCase, report.matchedRecordCount, 2);
verifyEqual(testCase, numel(finalPeaks), 1);
verifyEqual(testCase, numel(consolidated), 1);

end


function testPreciseTracksOutsideFixedGateRemainDistinct(testCase)

trackPositions = [ ...
    10 10;
    10 14.2];
state = createBayesianState(trackPositions);
state.tracks(1).covariance = 0.10 * eye(2);
state.tracks(2).covariance = 0.10 * eye(2);
victims = createVictimArray(trackPositions);

[consolidated, finalPeaks, report] = ...
    consolidateVictimRecordsByBayesianTracks( ...
        victims, ...
        state);

verifyEqual(testCase, report.rawConfirmedTrackCount, 2);
verifyEqual(testCase, report.confirmedTrackCount, 2);
verifyEqual(testCase, numel(unique(report.trackClusterIndex)), 2);
verifyEqual(testCase, report.matchedRecordCount, 2);
verifyEqual(testCase, numel(finalPeaks), 2);
verifyEqual(testCase, numel(consolidated), 2);

end


function testRecordsAssociateThroughRawClusterMembers(testCase)

trackPositions = [ ...
    10 10;
    10 14.50;
    10 15.40];
state = createBayesianState(trackPositions);

for trackIndex = 1:numel(state.tracks)
    state.tracks(trackIndex).covariance = ...
        3.0 * eye(2);
end
state.tracks(1).independentViewCount = 100;
% يسحب وزن المسار الأول مركز العنقود بعيدًا عن السجل الأخير، وبذلك
% يثبت الاختبار أن المطابقة تستخدم العضو الخام لا المركز فقط.

recordPositions = [ ...
    10 10;
    10 15.40];
victims = createVictimArray(recordPositions);

[consolidated, finalPeaks, report] = ...
    consolidateVictimRecordsByBayesianTracks( ...
        victims, ...
        state);

verifyEqual(testCase, report.rawConfirmedTrackCount, 3);
verifyEqual(testCase, report.confirmedTrackCount, 1);
verifyEqual(testCase, report.matchedRecordCount, 2);
verifyEqual(testCase, report.unmatchedRecordCount, 0);
verifyEqual(testCase, report.recordToTrackIndex, [1; 1]);
verifyEqual(testCase, report.assignmentAnchorTrackID, [1; 3]);
verifyEqual(testCase, report.assignmentDistances, [0; 0], ...
    'AbsTol', 1e-12);
verifyEqual(testCase, numel(finalPeaks), 1);
verifyEqual(testCase, numel(consolidated), 1);

end


function testTrackChainCannotExceedMaximumClusterDiameter(testCase)

trackPositions = [ ...
    10 10;
    10 14.50;
    10 19.00];
state = createBayesianState(trackPositions);

for trackIndex = 1:numel(state.tracks)
    state.tracks(trackIndex).covariance = ...
        3.0 * eye(2);
end

victims = createVictimArray(trackPositions);

[consolidated, finalPeaks, report] = ...
    consolidateVictimRecordsByBayesianTracks( ...
        victims, ...
        state);

verifyEqual(testCase, report.rawConfirmedTrackCount, 3);
verifyEqual(testCase, report.confirmedTrackCount, 2);
verifyEqual(testCase, ...
    numel(unique(report.trackClusterIndex)), 2);
verifyLessThanOrEqual(testCase, ...
    max(report.trackClusterDiameters), 5.5);
verifyEqual(testCase, report.matchedRecordCount, 3);
verifyEqual(testCase, numel(finalPeaks), 2);
verifyEqual(testCase, numel(consolidated), 2);

end


function testSingletonFragmentRejoinsOneSupportedCompactCluster(testCase)

trackPositions = [ ...
    10 10;
    10 14.50;
    15 12.25];
state = createBayesianState(trackPositions);

for trackIndex = 1:numel(state.tracks)
    state.tracks(trackIndex).covariance = ...
        3.0 * eye(2);
end

victims = createVictimArray(trackPositions);

[consolidated, finalPeaks, report] = ...
    consolidateVictimRecordsByBayesianTracks( ...
        victims, ...
        state);

verifyEqual(testCase, report.rawConfirmedTrackCount, 3);
verifyEqual(testCase, ...
    numel(unique(report.compactTrackClusterIndex)), 2);
verifyEqual(testCase, report.confirmedTrackCount, 1);
verifyEqual(testCase, ...
    report.absorbedFragmentTrackMask, ...
    [false; false; true]);
verifyEqual(testCase, ...
    report.fragmentTargetCompactClusterIndex, ...
    [0; 0; 1]);
verifyLessThanOrEqual(testCase, ...
    max(report.compactTrackClusterDiameters), 5.5);
verifyLessThanOrEqual(testCase, ...
    max(report.trackClusterDiameters), 5.5);
verifyFalse(testCase, ...
    any(report.fragmentRejectedByDiameterTrackMask));
verifyEqual(testCase, report.matchedRecordCount, 3);
verifyEqual(testCase, numel(finalPeaks), 1);
verifyEqual(testCase, numel(consolidated), 1);

end


function testFragmentAbsorptionPreservesCumulativeClusterDiameter(testCase)

trackPositions = [ ...
    10 10;
    10 14.50;
    15 12.25;
     5 12.25];
state = createBayesianState(trackPositions);

for trackIndex = 1:numel(state.tracks)
    state.tracks(trackIndex).covariance = ...
        3.0 * eye(2);
end

victims = createVictimArray(trackPositions);

[consolidated, finalPeaks, report] = ...
    consolidateVictimRecordsByBayesianTracks( ...
        victims, ...
        state);

verifyEqual(testCase, report.rawConfirmedTrackCount, 4);
verifyEqual(testCase, ...
    numel(unique(report.compactTrackClusterIndex)), 3);
verifyEqual(testCase, report.confirmedTrackCount, 2);
verifyEqual(testCase, ...
    report.absorbedFragmentTrackMask, ...
    [false; false; true; false]);
verifyEqual(testCase, ...
    report.fragmentRejectedByDiameterTrackMask, ...
    [false; false; false; true]);
verifyLessThanOrEqual(testCase, ...
    max(report.trackClusterDiameters), 5.5);
verifyEqual(testCase, numel(finalPeaks), 2);
verifyEqual(testCase, numel(consolidated), 2);

end


function testSupportedCompactClustersNeverMergeAsFragments(testCase)

trackPositions = [ ...
    10.0 10.0;
    10.0 14.5;
    14.5 10.0;
    14.5 14.5];
state = createBayesianState(trackPositions);

for trackIndex = 1:numel(state.tracks)
    state.tracks(trackIndex).covariance = ...
        3.0 * eye(2);
end

victims = createVictimArray(trackPositions);

[consolidated, finalPeaks, report] = ...
    consolidateVictimRecordsByBayesianTracks( ...
        victims, ...
        state);

verifyEqual(testCase, ...
    numel(unique(report.compactTrackClusterIndex)), 2);
verifyEqual(testCase, report.confirmedTrackCount, 2);
verifyFalse(testCase, ...
    any(report.absorbedFragmentTrackMask));
verifyEqual(testCase, numel(finalPeaks), 2);
verifyEqual(testCase, numel(consolidated), 2);

end


function testAmbiguousSingletonFragmentRemainsIndependent(testCase)

trackPositions = [ ...
    10.00 10.00;
    10.00 14.50;
    14.50 10.00;
    14.50 14.50;
    12.25 17.00];
state = createBayesianState(trackPositions);

for trackIndex = 1:numel(state.tracks)
    state.tracks(trackIndex).covariance = ...
        3.0 * eye(2);
end

victims = createVictimArray(trackPositions);

[consolidated, finalPeaks, report] = ...
    consolidateVictimRecordsByBayesianTracks( ...
        victims, ...
        state);

verifyEqual(testCase, ...
    numel(unique(report.compactTrackClusterIndex)), 3);
verifyEqual(testCase, report.confirmedTrackCount, 3);
verifyFalse(testCase, ...
    any(report.absorbedFragmentTrackMask));
verifyEqual(testCase, numel(finalPeaks), 3);
verifyEqual(testCase, numel(consolidated), 3);

end


function testSupportedClustersInsideOneLogOddsBasinMerge(testCase)

trackPositions = [ ...
    10.0 10.0;
    10.0 14.5;
    14.5 10.0;
    14.5 14.5];
state = createBayesianState(trackPositions);

for trackIndex = 1:numel(state.tracks)
    state.tracks(trackIndex).covariance = ...
        3.0 * eye(2);
end

state.logOddsMap(:) = -8;
state.logOddsMap(7:18,7:18) = 12;
state.weightedObservationSupport(7:18,7:18) = 100;
victims = createVictimArray(trackPositions);

[consolidated, finalPeaks, report] = ...
    consolidateVictimRecordsByBayesianTracks( ...
        victims,state);

verifyEqual(testCase, ...
    numel(unique(report.preBasinTrackClusterIndex)), 2);
verifyEqual(testCase, report.confirmedTrackCount, 1);
verifyEqual(testCase, ...
    report.basinPreToFinalClusterIndex,[1; 1]);
verifyEqual(testCase, report.basinMergedClusterCount, 1);
verifyLessThanOrEqual(testCase, ...
    report.basinPairwiseValleyDrops(1,2),4.0);
verifyGreaterThanOrEqual(testCase, ...
    report.basinPairwiseSupportRetention(1,2),0.90);
verifyEqual(testCase, numel(finalPeaks), 1);
verifyEqual(testCase, numel(consolidated), 1);

end


function testSupportedClustersAcrossLogOddsValleyRemainDistinct(testCase)

trackPositions = [ ...
    10.0 10.0;
    10.0 14.5;
    14.5 10.0;
    14.5 14.5];
state = createBayesianState(trackPositions);

for trackIndex = 1:numel(state.tracks)
    state.tracks(trackIndex).covariance = ...
        3.0 * eye(2);
end

state.logOddsMap(:) = -8;
state.logOddsMap(7:12,7:18) = 12;
state.logOddsMap(14:19,7:18) = 12;
state.weightedObservationSupport(7:19,7:18) = 100;
victims = createVictimArray(trackPositions);

[consolidated, finalPeaks, report] = ...
    consolidateVictimRecordsByBayesianTracks( ...
        victims,state);

verifyEqual(testCase, ...
    numel(unique(report.preBasinTrackClusterIndex)), 2);
verifyEqual(testCase, report.confirmedTrackCount, 2);
verifyEqual(testCase, ...
    report.basinPreToFinalClusterIndex,[1; 2]);
verifyEqual(testCase, report.basinMergedClusterCount, 0);
verifyGreaterThan(testCase, ...
    report.basinPairwiseValleyDrops(1,2),4.0);
verifyEqual(testCase, numel(finalPeaks), 2);
verifyEqual(testCase, numel(consolidated), 2);

end


function testBasinCompleteLinkPreventsLongMergeChain(testCase)

trackPositions = [ ...
    10 10;
    10 12;
    15 10;
    15 12;
    20 10;
    20 12];
state = createBayesianState(trackPositions);
state.logOddsMap(:) = -8;
state.logOddsMap(7:23,7:15) = 12;
state.weightedObservationSupport(7:23,7:15) = 100;
victims = createVictimArray(trackPositions);

[consolidated, finalPeaks, report] = ...
    consolidateVictimRecordsByBayesianTracks( ...
        victims,state);

verifyEqual(testCase, ...
    numel(unique(report.preBasinTrackClusterIndex)), 3);
verifyEqual(testCase, report.confirmedTrackCount, 2);
verifyEqual(testCase, ...
    report.basinPreToFinalClusterIndex,[1; 1; 2]);
verifyEqual(testCase, report.basinMergedClusterCount, 1);
verifyEqual(testCase, numel(finalPeaks), 2);
verifyEqual(testCase, numel(consolidated), 2);

end


function testSupportValleyProtectsTwoStrongBasins(testCase)

trackPositions = [ ...
    10.0 10.0;
    10.0 14.5;
    14.5 10.0;
    14.5 14.5];
state = createBayesianState(trackPositions);

for trackIndex = 1:numel(state.tracks)
    state.tracks(trackIndex).covariance = ...
        3.0 * eye(2);
end

state.logOddsMap(:) = -8;
state.logOddsMap(8:17,10:14) = 10;
state.logOddsMap(10,12) = 12;
state.logOddsMap(15,12) = 12;
state.weightedObservationSupport(:) = 0;
state.weightedObservationSupport(8:17,10:14) = 10;
state.weightedObservationSupport(10,12) = 100;
state.weightedObservationSupport(15,12) = 100;
victims = createVictimArray(trackPositions);

[consolidated, finalPeaks, report] = ...
    consolidateVictimRecordsByBayesianTracks( ...
        victims,state);

verifyEqual(testCase, ...
    numel(unique(report.preBasinTrackClusterIndex)), 2);
verifyLessThanOrEqual(testCase, ...
    report.basinPairwiseValleyDrops(1,2),4.0);
verifyLessThan(testCase, ...
    report.basinPairwiseSupportRetention(1,2),0.90);
verifyEqual(testCase, report.confirmedTrackCount, 2);
verifyEqual(testCase, ...
    report.basinPreToFinalClusterIndex,[1; 2]);
verifyEqual(testCase, numel(finalPeaks), 2);
verifyEqual(testCase, numel(consolidated), 2);

end


function testJointWeakIsolationGateRejectsOnlyWeakSingleton(testCase)

trackPositions = [ ...
    10 10;
    10 12;
    20 20];
state = createBayesianState(trackPositions);
state.logOddsMap(:) = -8;
state.logOddsMap(10,11) = 16;
state.logOddsMap(20,20) = 4;
state.weightedObservationSupport(:) = 0;
state.weightedObservationSupport(10,11) = 100;
state.weightedObservationSupport(20,20) = 10;
victims = createVictimArray(trackPositions);

[consolidated, finalPeaks, report] = ...
    consolidateVictimRecordsByBayesianTracks( ...
        victims,state);

verifyEqual(testCase, ...
    numel(unique(report.preBasinTrackClusterIndex)), 2);
verifyEqual(testCase, ...
    report.basinPreToFinalClusterIndex,[1; 0]);
verifyEqual(testCase, ...
    report.basinRejectedPreClusterMask,[false; true]);
verifyEqual(testCase, report.basinRejectedClusterCount, 1);
verifyEqual(testCase, report.confirmedTrackCount, 1);
verifyEqual(testCase, numel(finalPeaks), 1);
verifyEqual(testCase, numel(consolidated), 1);

end


function testWeakMapOnlyTwoTrackBasinIsRejected(testCase)

trackPositions = [10 10;10 12;20 20;20 22];
state = createBayesianState(trackPositions);
state.logOddsMap(:) = -8;
state.logOddsMap(10,11) = 16;
state.logOddsMap(20,21) = 6;
state.weightedObservationSupport(:) = 0;
state.weightedObservationSupport(10,11) = 1000;
state.weightedObservationSupport(20,21) = 50;
victims = createVictimArray(trackPositions);

[consolidated,finalPeaks,report] = ...
    consolidateVictimRecordsByBayesianTracks(victims,state);

verifyEqual(testCase, ...
    report.basinRejectedPreClusterMask,[false;true]);
verifyEqual(testCase,report.basinRejectedClusterCount,1);
verifyEqual(testCase,report.confirmedTrackCount,1);
verifyEqual(testCase,numel(finalPeaks),1);
verifyEqual(testCase,numel(consolidated),1);

end


function testStrongUnmatchedRangedRecordIsRescued(testCase)

state = createBayesianState([10 10]);
state.logOddsMap(:) = -8;
state.logOddsMap(10,10) = 16;
state.logOddsMap(25,25) = 12;
state.weightedObservationSupport(:) = 0;
state.weightedObservationSupport(10,10) = 300;
state.weightedObservationSupport(25,25) = 200;
victims = createVictimArray([10 10;25 25]);

for recordIndex = 1:numel(victims)
    victims(recordIndex).hasRangedMeasurementEvidence = false;
    victims(recordIndex).rangedMeasurementAssociationCount = 0;
end
victims(2).hasRangedMeasurementEvidence = true;
victims(2).rangedMeasurementAssociationCount = 5;

[consolidated,finalPeaks,report] = ...
    consolidateVictimRecordsByBayesianTracks(victims,state);

verifyEqual(testCase, ...
    report.rescuedUnmatchedRecordMask,[false;true]);
verifyEqual(testCase,report.rescuedUnmatchedRecordCount,1);
verifyEqual(testCase,report.unmatchedRecordCount,0);
verifyEqual(testCase,numel(finalPeaks),2);
verifyEqual(testCase,numel(consolidated),2);
positions = reshape([consolidated.position],2,[])';
verifyEqual(testCase,sortrows(positions),[10 10;25 25]);

end


function testSingleBasinDiagnosticsContainValidPeak(testCase)

state = createBayesianState([10 10]);
state.logOddsMap(:) = -8;
state.logOddsMap(10,10) = 8;
state.weightedObservationSupport(10,10) = 50;
victims = createVictimArray([10 10]);

[consolidated, finalPeaks, report] = ...
    consolidateVictimRecordsByBayesianTracks( ...
        victims,state);

verifyEqual(testCase,report.basinPeakPositions,[10 10]);
verifyEqual(testCase,report.basinPeakLogOdds,8);
verifyEqual(testCase,report.basinPeakSupport,50);
verifyEqual(testCase,report.basinRejectedClusterCount,0);
verifyEqual(testCase,report.confirmedTrackCount,1);
verifyEqual(testCase,numel(finalPeaks),1);
verifyEqual(testCase,numel(consolidated),1);

end


function testTemporalCoexistenceDiagnosticsUseUpdateHistories(testCase)

state = createBayesianState([10 10; 20 20]);
state.tracks(1).updateStepHistory = [1; 2; 3; 4];
state.tracks(2).updateStepHistory = [3; 4; 5; 6];
victims = createVictimArray([10 10; 20 20]);

[consolidated, finalPeaks, report] = ...
    consolidateVictimRecordsByBayesianTracks( ...
        victims,state);

verifyEqual(testCase, ...
    report.basinPairwiseTemporalContainment(1,2), ...
    0.5,'AbsTol',1e-12);
verifyEqual(testCase, ...
    report.basinPairwiseTemporalJaccard(1,2), ...
    1/3,'AbsTol',1e-12);
verifyEqual(testCase,report.confirmedTrackCount,2);
verifyEqual(testCase,numel(finalPeaks),2);
verifyEqual(testCase,numel(consolidated),2);

end


function state = createBayesianState(trackPositions)

state = initializeSpatialBayesianLocalizationState( ...
    [40 40], ...
    0.01);
state.localizationMethod = "SpatialBayesianFusion";
state.tracks = repmat(createTrack(1, [1 1]), 0, 1);

for index = 1:size(trackPositions,1)
    state.tracks(end+1,1) = createTrack( ... %#ok<AGROW>
        index, ...
        trackPositions(index,:));
end

end


function track = createTrack(trackID, position)

observationPositions = [ ...
    position + [-2 0];
    position + [0 2];
    position + [2 0]];

track = struct( ...
    'id', trackID, ...
    'position', position, ...
    'existenceProbability', 0.92, ...
    'covariance', eye(2), ...
    'updateCount', 5, ...
    'independentViewCount', 3, ...
    'observationPositions', observationPositions, ...
    'maximumProbability', 0.95, ...
    'missedUpdateCount', 0, ...
    'status', "CONFIRMED", ...
    'lastUpdateStep', 10, ...
    'updateStepHistory', 10);

end


function victims = createVictimArray(positions)

victims = repmat(createVictim(1, [1 1]), 0, 1);

for index = 1:size(positions,1)
    victims(end+1,1) = createVictim( ... %#ok<AGROW>
        index, ...
        positions(index,:));
end

end


function victim = createVictim(victimID, position)

observationPositions = [ ...
    position + [-2 0];
    position + [0 2];
    position + [2 0]];
currentTime = datetime("now");

victim = struct( ...
    'id', victimID, ...
    'position', position, ...
    'vitalityIndex', 0.50, ...
    'victimCondition', "MODERATE", ...
    'priorityScore', 0.50, ...
    'priorityLevel', "MEDIUM", ...
    'firstDetectionTime', currentTime, ...
    'lastUpdateTime', currentTime, ...
    'detectionCount', 3, ...
    'independentViewCount', 3, ...
    'rawAssociationCount', 5, ...
    'observationPositions', observationPositions, ...
    'lastObservationPosition', observationPositions(end,:));

end
