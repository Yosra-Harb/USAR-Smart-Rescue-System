function tests = testPhase2PhysicalSensorModels
%% اختبارات خصائص نماذج الرادار والحراري والصوتي الجديدة

tests = functiontests(localfunctions);

end


function testAllModalitiesDecayWithDistance(testCase)

scenario = createSensorTestScenario();
nearProbe = struct('position', [16 17]);
farProbe = struct('position', [2 2]);

rng(110);
nearRadar = radarSimulation(scenario, nearProbe);
rng(110);
farRadar = radarSimulation(scenario, farProbe);

rng(120);
nearThermal = thermalSimulation(scenario, nearProbe);
rng(120);
farThermal = thermalSimulation(scenario, farProbe);

rng(130);
nearAcoustic = acousticSimulation(scenario, nearProbe);
rng(130);
farAcoustic = acousticSimulation(scenario, farProbe);

verifyGreaterThan(testCase, ...
    nearRadar.signalComponent, farRadar.signalComponent);
verifyGreaterThan(testCase, ...
    nearThermal.signalComponent, farThermal.signalComponent);
verifyGreaterThan(testCase, ...
    nearAcoustic.signalComponent, farAcoustic.signalComponent);

end


function testThermalIsMoreSensitiveToOpaqueObstacle(testCase)

scenario = createSensorTestScenario();
probe = struct('position', [16 6]);
scenario.environment.obstacles(16,11) = true;

rng(210);
radarOutput = radarSimulation(scenario, probe);
rng(210);
thermalOutput = thermalSimulation(scenario, probe);

verifyLessThan(testCase, ...
    thermalOutput.pathTransmission, ...
    radarOutput.pathTransmission);
verifyLessThan(testCase, ...
    thermalOutput.signalComponent, ...
    radarOutput.signalComponent);

end


function testAmbientNoiseRaisesUncertainty(testCase)

quietScenario = createSensorTestScenario();
noisyScenario = quietScenario;
noisyScenario.environment.noise(:) = 1;
probe = struct('position', [16 18]);

rng(310);
quietOutput = radarSimulation(quietScenario, probe);
rng(310);
noisyOutput = radarSimulation(noisyScenario, probe);

verifyGreaterThan(testCase, ...
    noisyOutput.noiseStd, quietOutput.noiseStd);
verifyLessThan(testCase, ...
    noisyOutput.snrDb, quietOutput.snrDb);
verifyLessThan(testCase, ...
    noisyOutput.reliability, quietOutput.reliability);

end


function testLegacyVitalMapCannotLeakIntoSensorReading(testCase)

scenarioA = createSensorTestScenario();
scenarioB = scenarioA;
scenarioA.environment.vitalSigns = zeros(scenarioA.gridSize);
scenarioB.environment.vitalSigns = ones(scenarioB.gridSize);
probe = struct('position', [16 18]);

rng(410);
outputA = radarSimulation(scenarioA, probe);
rng(410);
outputB = radarSimulation(scenarioB, probe);

verifyEqual(testCase, ...
    outputA.normalizedValue, ...
    outputB.normalizedValue, ...
    'AbsTol', 1e-12);
verifyEqual(testCase, ...
    outputA.pathTransmission, ...
    outputB.pathTransmission, ...
    'AbsTol', 1e-12);

end


function testEmptySceneProducesValidBoundedOutputs(testCase)

scenario = createSensorTestScenario();
scenario.victims = zeros(0,2);
scenario.groundTruth.vitalStrength = zeros(0,1);
scenario.groundTruth.burialDepth = zeros(0,1);
probe = struct('position', [16 16]);

rng(510);
outputs = { ...
    radarSimulation(scenario, probe), ...
    thermalSimulation(scenario, probe), ...
    acousticSimulation(scenario, probe)};

for outputIndex = 1:numel(outputs)
    output = outputs{outputIndex};
    verifyGreaterThanOrEqual(testCase, output.normalizedValue, 0);
    verifyLessThanOrEqual(testCase, output.normalizedValue, 1);
    verifyTrue(testCase, isfinite(output.normalizedValue));
    verifyEqual(testCase, output.signalComponent, 0);
end

end


function testFixedSeedReproducesSensorPacket(testCase)

scenario = createSensorTestScenario();
probe = struct('position', [16 18]);

rng(610);
packetA = sensorManager(scenario, probe);
rng(610);
packetB = sensorManager(scenario, probe);

verifyEqual(testCase, packetA.radar, packetB.radar, ...
    'AbsTol', 1e-12);
verifyEqual(testCase, packetA.thermal, packetB.thermal, ...
    'AbsTol', 1e-12);
verifyEqual(testCase, packetA.acoustic, packetB.acoustic, ...
    'AbsTol', 1e-12);
verifyEqual(testCase, ...
    packetA.sensorModelVersion, ...
    "SOURCE_PATH_RECEIVER_V4_SPATIAL_NO_ORACLE_INFERENCE");

verifyEqual(testCase, ...
    packetA.radarReliability, ...
    packetB.radarReliability, ...
    'AbsTol', 1e-12);

verifyTrue(testCase, ...
    isfield(packetA, ...
        'diagnosticRadarOracleReliability'));

end


function testBurialPenalizesThermalMoreThanRadar(testCase)

scenario = createSensorTestScenario();
scenario.groundTruth.burialDepth = 0.9;
probe = struct('position', [16 18]);

rng(710);
radarOutput = radarSimulation(scenario, probe);
rng(710);
thermalOutput = thermalSimulation(scenario, probe);

verifyLessThan(testCase, ...
    thermalOutput.pathTransmission, ...
    radarOutput.pathTransmission);

end


function testInferenceReliabilityDoesNotUseVictimTruth(testCase)

scenarioNear = createSensorTestScenario();
scenarioFar = scenarioNear;
scenarioNear.victims = [16 16];
scenarioFar.victims = [2 2];
probe = struct('position', [16 18]);

rng(810);
packetNear = sensorManager(scenarioNear, probe);
rng(810);
packetFar = sensorManager(scenarioFar, probe);

inferenceReliabilityNear = [ ...
    packetNear.radarReliability, ...
    packetNear.thermalReliability, ...
    packetNear.acousticReliability];
inferenceReliabilityFar = [ ...
    packetFar.radarReliability, ...
    packetFar.thermalReliability, ...
    packetFar.acousticReliability];

verifyEqual(testCase, ...
    inferenceReliabilityNear, ...
    inferenceReliabilityFar, ...
    'AbsTol', 1e-12);
% تغيير موقع الحقيقة يؤثر في مولد الإشارة، لكنه لا يغير جودة
% المستقبل التي تدخل الدمج والتوطين.

end


function scenario = createSensorTestScenario()

gridSize = [31 31];
scenario = struct();
scenario.gridSize = gridSize;
scenario.victims = [16 16];
scenario.vitalStrength = 0.9;
scenario.burialDepth = 0.2;
scenario.environment = struct( ...
    'debris', 0.15 * ones(gridSize), ...
    'attenuation', 0.10 * ones(gridSize), ...
    'noise', 0.05 * ones(gridSize), ...
    'obstacles', false(gridSize), ...
    'vitalSigns', zeros(gridSize));
scenario.groundTruth = struct( ...
    'vitalStrength', 0.9, ...
    'burialDepth', 0.2);

end
