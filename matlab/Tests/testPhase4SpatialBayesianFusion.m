function tests = testPhase4SpatialBayesianFusion
%% اختبارات عقد القياس المكاني ومعادلة Bayes الهندسية.

tests = functiontests(localfunctions);

end


function testConsistentRangeBearingFavoursCorrectCell(testCase)

scenario = syntheticScenario();
packet = syntheticProcessedPacket();
probePosition = [10 10];

correct = calculateSpatialMeasurementLogBayesFactors( ...
    packet,scenario,probePosition,[10 15]);
incorrect = calculateSpatialMeasurementLogBayesFactors( ...
    packet,scenario,probePosition,[15 10]);

verifyGreaterThan(testCase, ...
    correct.combinedLogBayesFactor, ...
    incorrect.combinedLogBayesFactor);
verifyFalse(testCase, ...
    any(contains(lower(string(fieldnames(packet))),"victim")));

end


function testNoObservationProvidesNegativeEvidence(testCase)

scenario = syntheticScenario();
packet = syntheticProcessedPacket();
packet.spatialObservations.radar = ...
    sanitizeSpatialObservationSet(struct([]));
packet.spatialObservations.thermal = ...
    sanitizeSpatialObservationSet(struct([]));
packet.spatialObservations.acoustic = ...
    sanitizeSpatialObservationSet(struct([]));

result = calculateSpatialMeasurementLogBayesFactors( ...
    packet,scenario,[10 10],[10 15]);
verifyLessThan(testCase,result.combinedLogBayesFactor,0);

end


function testSpatialMapIncreasesAtConsistentCell(testCase)

scenario = syntheticScenario();
packet = syntheticProcessedPacket();
state = initializeSpatialBayesianLocalizationState([20 20],0.01);
prior = state.probabilityMap(10,15);

[state,diagnostics] = updateSpatialBayesianMap( ...
    state,scenario,packet);
verifyGreaterThan(testCase,state.probabilityMap(10,15),prior);
verifyGreaterThan(testCase,diagnostics.updatedCellCount,0);

end


function testSensorPacketCarriesAnonymousSpatialContract(testCase)

scenario = syntheticScenario();
probe = struct('position',[10 10],'headingDegrees',0);
rng(910);
measurementPacket = sensorManager(scenario,probe);
processedPacket = signalProcessingManager(measurementPacket);

verifyTrue(testCase,isfield(measurementPacket,'spatialObservations'));
verifyTrue(testCase,isfield(processedPacket,'spatialObservations'));
sensorNames = {'radar','thermal','acoustic'};
for index = 1:numel(sensorNames)
    name = sensorNames{index};
    verifyTrue(testCase,isfield( ...
        processedPacket.spatialObservations,name));
    fields = lower(string(fieldnames( ...
        processedPacket.spatialObservations.(name))));
    verifyFalse(testCase,any(contains(fields,"victim")));
    verifyFalse(testCase,any(contains(fields,"true")));
end

end


function packet = syntheticProcessedPacket()

radarObservation = buildObservation(5,0.4,0,3,0.9,0.95,"UWB_Radar");
thermalObservation = buildObservation(NaN,Inf,0,5,0.8,0.9,"Thermal_Sensor");
acousticObservation = buildObservation(NaN,Inf,1,8,0.6,0.75,"Acoustic_Sensor");
packet = struct();
packet.probePosition = [10 10];
packet.probeHeadingDegrees = 0;
packet.spatialObservations = struct( ...
    'radar',radarObservation, ...
    'thermal',thermalObservation, ...
    'acoustic',acousticObservation);

end


function observation = buildObservation( ...
    range,rangeStd,bearing,bearingStd,strength,confidence,sensorName)

observation = struct( ...
    'range',range,'rangeStd',rangeStd, ...
    'bearing',bearing,'bearingStd',bearingStd, ...
    'strength',strength,'confidence',confidence, ...
    'breathingPeriodicity',0.8, ...
    'heartbeatPeriodicity',0.6, ...
    'sensorName',string(sensorName),'eventType',"TEST");

end


function scenario = syntheticScenario()

gridSize = [20 20];
scenario = struct();
scenario.gridSize = gridSize;
scenario.environment = struct( ...
    'debris',zeros(gridSize), ...
    'attenuation',zeros(gridSize), ...
    'noise',zeros(gridSize), ...
    'obstacles',false(gridSize), ...
    'accessibility',ones(gridSize), ...
    'risk',zeros(gridSize), ...
    'movementCost',ones(gridSize), ...
    'entryPoint',[20 1]);
scenario.victims = [10 15];
scenario.groundTruth = struct( ...
    'vitalStrength',0.8,'burialDepth',0.2);

end
