function tests = testIntegrationContract
%% اختبارات Contract v1 دون تشغيل محاكاة كاملة ثقيلة.

tests = functiontests(localfunctions);

end


function testCustomRequestMapsToEffectiveConfig(testCase)

request = struct( ...
    'scenarioType', "Custom", ...
    'randomSeed', 321, ...
    'numVictims', 4, ...
    'debrisDensity', 0.65, ...
    'noiseLevel', 0.45, ...
    'burialDepth', 0.70, ...
    'vitalStrength', 0.35);

[config, info] = scenarioRequestToConfig(request);

verifyEqual(testCase, string(config.type), "Custom");
verifyEqual(testCase, config.randomSeed, 321);
verifyEqual(testCase, config.numVictims, 4);
verifyEqual(testCase, config.debrisDensity, 0.65, 'AbsTol', 1e-12);
verifyEqual(testCase, config.noiseLevel, 0.45, 'AbsTol', 1e-12);
verifyEqual(testCase, config.burialDepth, 0.70, 'AbsTol', 1e-12);
verifyEqual(testCase, config.vitalStrength, 0.35, 'AbsTol', 1e-12);
verifyEqual(testCase, config.gridSize, [50 50]);
verifyTrue(testCase, info.withinCurrentParameterEnvelope);

end


function testPresetRejectsHiddenOverrides(testCase)

request = struct( ...
    'scenarioType', "Ideal", ...
    'debrisDensity', 0.9);

verifyError(testCase, ...
    @() scenarioRequestToConfig(request), ...
    "scenarioRequestToConfig:PresetOverrideNotAllowed");

end


function testUnsupportedAccessibilityControlIsRejected(testCase)

request = struct( ...
    'scenarioType', "Custom", ...
    'accessibility', 0.2);

verifyError(testCase, ...
    @() scenarioRequestToConfig(request), ...
    "scenarioRequestToConfig:UnsupportedControl");

end


function testOperationalContractDoesNotLeakGroundTruth(testCase)

scenario = minimalScenario();
simulationResult = minimalSimulationResult();
contracts = buildMissionContracts( ...
    "MISSION_TEST", scenario, simulationResult);

verifyFalse(testCase, contracts.result.containsGroundTruth);
verifyFalse(testCase, isfield(contracts.result, 'groundTruthPositions'));
verifyFalse(testCase, isfield(contracts.result, 'groundTruthVictimCount'));
verifyTrue(testCase, contracts.evaluation.evaluationOnly);
verifyEqual(testCase, ...
    contracts.evaluation.positions.groundTruth, [8 2]);

end


function testCoordinateConversionIsExplicit(testCase)

scenario = minimalScenario();
simulationResult = minimalSimulationResult();
contracts = buildMissionContracts( ...
    "MISSION_TEST", scenario, simulationResult);

position = contracts.result.victims(1).estimatedPosition;
verifyEqual(testCase, position.row, 4);
verifyEqual(testCase, position.column, 7);
verifyEqual(testCase, position.x, 7);
verifyEqual(testCase, position.y, 4);

end


function testOperationalContractExportsExactRescueGeometry(testCase)

scenario = minimalScenario();
scenario.environment.obstacles(8,4) = true;
simulationResult = minimalSimulationResult();
contracts = buildMissionContracts( ...
    "MISSION_ROUTE_TEST", scenario, simulationResult);

victim = contracts.result.victims(1);
verifyEqual(testCase, victim.shortestRoute.mode, "shortest");
verifyEqual(testCase, victim.recommendedRoute.mode, "recommended");
verifyEqual(testCase, victim.shortestRoute.path, [1 10; 2 9; 3 8]);
verifyEqual(testCase, victim.recommendedRoute.path, [1 10; 2 9; 3 8]);
verifyTrue(testCase, victim.shortestRoute.reachable);
verifyTrue(testCase, victim.recommendedRoute.reachable);
verifyEqual(testCase, contracts.result.operationalMap.entryPoint.x, 1);
verifyEqual(testCase, contracts.result.operationalMap.entryPoint.y, 10);
verifyTrue(testCase, any(all( ...
    contracts.result.operationalMap.obstacles == [4 8], 2)));
verifyFalse(testCase, contracts.result.operationalMap.containsGroundTruth);

jsonText = jsonencode(contracts.result);
verifyFalse(testCase, contains(lower(jsonText), "groundtruthpositions"));

end


function testOperationalContractRejectsDuplicateVictimIDs(testCase)

scenario = minimalScenario();
simulationResult = minimalSimulationResult();

secondVictim = simulationResult.detectedVictimDatabase;
secondVictim.position = [7 3];
secondVictim.rescueRank = 2;
% intentionally keep id = 1 to verify the contract refuses ambiguity
simulationResult.detectedVictimDatabase = [ ...
    simulationResult.detectedVictimDatabase; secondVictim];
simulationResult.systemDetectionCount = 2;

verifyError(testCase, ...
    @() buildMissionContracts( ...
        "MISSION_DUPLICATE_ID", scenario, simulationResult), ...
    "buildMissionContracts:DuplicateVictimIDs");

end


function testTelemetryRecordHasSafeRuntimeContract(testCase)

probe = minimalTelemetryProbe();
record = buildTelemetryRecord( ...
    "MISSION_TELEMETRY_TEST", 7, probe, 42);

verifyEqual(testCase, record.schemaVersion, "1.1");
verifyEqual(testCase, record.eventType, "VICTIM_TRACK_CREATED");
verifyEqual(testCase, record.sequence, 7);
verifyFalse(testCase, record.containsGroundTruth);
verifyEqual(testCase, record.probe.position.x, 9);
verifyEqual(testCase, record.probe.position.y, 6);
verifyEqual(testCase, record.sensors.radar.normalized, 0.7, 'AbsTol', 1e-12);
verifyEqual(testCase, record.fusion.weights.radar, 0.5, 'AbsTol', 1e-12);
verifyEqual(testCase, record.newTracks(1).id, 42);

jsonText = jsonencode(record);
verifyFalse(testCase, contains(lower(jsonText), "groundtruthpositions"));
verifyFalse(testCase, contains(lower(jsonText), "oracle"));

end


function testTelemetryJsonlAppendRoundTrip(testCase)

filePath = string(tempname) + ".jsonl";
cleanup = onCleanup(@() deleteIfPresent(filePath)); %#ok<NASGU>

record1 = struct( ...
    'schemaVersion',"1.0", ...
    'missionId',"M1", ...
    'sequence',0, ...
    'eventType',"MISSION_STARTED");
record2 = struct( ...
    'schemaVersion',"1.0", ...
    'missionId',"M1", ...
    'sequence',1, ...
    'eventType',"STEP");

appendTelemetryJsonl(filePath,record1);
appendTelemetryJsonl(filePath,record2);

lines = splitlines(string(fileread(filePath)));
lines = lines(strlength(strtrim(lines)) > 0);
verifyEqual(testCase,numel(lines),2);
verifyEqual(testCase,jsondecode(lines(1)).sequence,0);
verifyEqual(testCase,jsondecode(lines(2)).sequence,1);

end


function testTelemetryLifecycleNeverExportsGroundTruth(testCase)

scenario = minimalScenario();
simulationResult = minimalSimulationResult();
startRecord = buildTelemetryLifecycleRecord( ...
    "MISSION_STARTED","M2",0,scenario,[]);
completeRecord = buildTelemetryLifecycleRecord( ...
    "MISSION_COMPLETED","M2",11,scenario,simulationResult);

verifyFalse(testCase,startRecord.containsGroundTruth);
verifyFalse(testCase,completeRecord.containsGroundTruth);
verifyFalse(testCase,isfield(completeRecord,'evaluation'));
verifyFalse(testCase,isfield(completeRecord,'groundTruthVictimCount'));
verifyEqual(testCase,completeRecord.summary.systemDetectionCount,1);

end



function testTelemetryUsesUtcExportClock(testCase)

probe = minimalTelemetryProbe();
% deliberately inject an old unzoned measurement timestamp. Telemetry UTC
% must represent export time, not relabel this local/unzoned clock as UTC.
probe.lastSensorData.timestamp = datetime(2001,1,1,12,0,0);

beforeUtc = datetime('now','TimeZone','UTC');
record = buildTelemetryRecord( ...
    "MISSION_TIME_TEST", 1, probe, []);
afterUtc = datetime('now','TimeZone','UTC');

stamp = datetime( ...
    record.timestampUtc, ...
    'InputFormat',"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", ...
    'TimeZone','UTC');

verifyGreaterThanOrEqual(testCase, stamp, beforeUtc-seconds(2));
verifyLessThanOrEqual(testCase, stamp, afterUtc+seconds(2));

end


function testTelemetryNeverCallsNewTrackConfirmed(testCase)

probe = minimalTelemetryProbe();
record = buildTelemetryRecord( ...
    "MISSION_TRACK_SEMANTICS", 3, probe, 42);

verifyEqual(testCase, record.eventType, "VICTIM_TRACK_CREATED");
verifyFalse(testCase, isfield(record,'confirmedVictimCount'));
verifyTrue(testCase, isfield(record,'activeTrackCount'));
verifyFalse(testCase, isfield(record,'newVictims'));
verifyTrue(testCase, isfield(record,'newTracks'));
verifyEqual(testCase, record.newTracks(1).id, 42);

end

function probe = minimalTelemetryProbe()

victim = struct( ...
    'id',42, ...
    'position',[4 7], ...
    'vitalityIndex',0.2, ...
    'priorityScore',0.88, ...
    'priorityLevel',"HIGH", ...
    'rescueRank',1);

probe = struct();
probe.id = 1;
probe.position = [6 9];
probe.state = "SEARCHING";
probe.currentStep = 20;
probe.coverage = 0.4;
probe.lastSensorData = struct( ...
    'radar',0.7,'thermal',0.4,'acoustic',0.2, ...
    'radarPhysical',12.0,'thermalPhysical',35.1,'acousticPhysical',0.3, ...
    'radarUnit',"a.u.",'thermalUnit',"C",'acousticUnit',"a.u.", ...
    'radarReliability',0.9,'thermalReliability',0.8, ...
    'acousticReliability',0.6,'quality',0.7667, ...
    'timestamp',datetime('now'));
probe.lastFusionData = struct( ...
    'fusionScore',0.61,'confidence',0.82, ...
    'weights',struct('radar',0.5,'thermal',0.3,'acoustic',0.2));
probe.lastLocalizationData = struct( ...
    'isVictimDetected',true,'estimatedPosition',[4 7], ...
    'localizationConfidence',0.8,'sourceType',"RANGED_MEASUREMENT", ...
    'localizationMethod',"SPATIAL_BAYESIAN", ...
    'posteriorProbability',0.81);
probe.lastVitalityData = struct( ...
    'isVictimDetected',true,'vitalityIndex',0.2, ...
    'victimCondition',"WEAK",'temporalStability',0.75);
probe.lastPriorityData = struct( ...
    'priorityScore',0.88,'priorityLevel',"HIGH", ...
    'priorityComponents',struct('medicalSeverity',0.8));
probe.lastDecision = "LOCAL_SEARCH";
probe.memory = struct('detectedVictims',victim);

end


function deleteIfPresent(filePath)
if isfile(filePath)
    delete(filePath);
end
end


function scenario = minimalScenario()

gridSize = [10 10];
scenario = struct();
scenario.type = "Custom";
scenario.randomSeed = 10;
scenario.gridSize = gridSize;
scenario.numVictims = 1;
scenario.debrisDensity = 0.4;
scenario.noiseLevel = 0.3;
scenario.burialDepth = 0.5;
scenario.vitalStrength = 0.8;
scenario.environment = struct( ...
    'debris',0.4*ones(gridSize), ...
    'noise',0.3*ones(gridSize), ...
    'obstacles',false(gridSize), ...
    'accessibility',0.6*ones(gridSize), ...
    'risk',0.2*ones(gridSize), ...
    'entryPoint',[10 1], ...
    'exitPoint',[1 10]);

end


function simulationResult = minimalSimulationResult()

victim = struct( ...
    'id',1, ...
    'position',[4 7], ...
    'vitalityIndex',0.2, ...
    'victimCondition',"WEAK", ...
    'priorityScore',0.88, ...
    'priorityLevel',"HIGH", ...
    'rescueRank',1, ...
    'reachable',true, ...
    'independentViewCount',3, ...
    'recommendedPath',[10 1; 9 2; 8 3], ...
    'recommendedPathLength',2.82842712474619, ...
    'recommendedTravelCost',4.2, ...
    'meanRouteRisk',0.1, ...
    'meanRouteAccessibility',0.9, ...
    'rescueAccessPoint',[5 7]);

shortestRoute = struct( ...
    'mode',"shortest", ...
    'reachable',true, ...
    'path',[10 1; 9 2; 8 3], ...
    'accessPoint',[8 3], ...
    'pathLength',2.82842712474619, ...
    'travelCost',2.82842712474619, ...
    'meanRisk',0.2, ...
    'maximumRisk',0.2, ...
    'meanAccessibility',0.6, ...
    'meanDebris',0.4, ...
    'expandedNodes',5);
recommendedRoute = struct( ...
    'mode',"recommended", ...
    'reachable',true, ...
    'path',[10 1; 9 2; 8 3], ...
    'accessPoint',[8 3], ...
    'pathLength',2.82842712474619, ...
    'travelCost',4.2, ...
    'meanRisk',0.1, ...
    'maximumRisk',0.2, ...
    'meanAccessibility',0.9, ...
    'meanDebris',0.4, ...
    'expandedNodes',7);
rescuePlan = struct( ...
    'victimID',1, ...
    'shortestRoute',shortestRoute, ...
    'recommendedRoute',recommendedRoute);

simulationResult = struct();
simulationResult.scenarioType = "Custom";
simulationResult.randomSeed = 10;
simulationResult.groundTruthVictimCount = 1;
simulationResult.systemDetectionCount = 1;
simulationResult.truePositives = 1;
simulationResult.falsePositives = 0;
simulationResult.falseNegatives = 0;
simulationResult.metrics = detectionMetrics(1,0,0,0);
simulationResult.matchedDistances = 1.0;
simulationResult.detectedVictimPositions = [4 7];
simulationResult.groundTruthPositions = [2 8];
simulationResult.detectedVictimDatabase = victim;
simulationResult.rescuePlan = rescuePlan;
simulationResult.localizationMethod = "SPATIAL_BAYESIAN";
simulationResult.fusionHistorySize = 10;
simulationResult.maximumFusionScore = 0.9;
simulationResult.meanFusionScore = 0.5;

end
