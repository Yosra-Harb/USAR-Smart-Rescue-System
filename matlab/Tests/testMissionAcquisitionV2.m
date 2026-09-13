function tests = testMissionAcquisitionV2
tests = functiontests(localfunctions);
end


function setupOnce(~)
testsFolder = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(testsFolder), 'Main'), '-end');
setupProjectPaths();
end


function setup(testCase)
testCase.TestData.randomState = rng;
end


function teardown(testCase)
rng(testCase.TestData.randomState);
end


function testRequestUsesV2AndAdvancesPerMissionSequence(testCase)
[scenario, probe] = sampleMission(941);
probe.memory.acquisitionV2 = initializeAcquisitionStateV2( ...
    "SIMULATION", "MISSION_TEST_941", "SIMULATED");

[first, probe] = requestSensorData(scenario, probe);
[second, probe] = requestSensorData(scenario, probe);

verifyEqual(testCase, first.acquisitionContractVersion, "2.0");
verifyEqual(testCase, first.acquisitionSource, "SIMULATION");
verifyEqual(testCase, first.poseSource, "SIMULATED");
verifyEqual(testCase, first.missionId, "MISSION_TEST_941");
verifyEqual(testCase, [first.sequence second.sequence], [1 2]);
verifyEqual(testCase, probe.memory.acquisitionV2.lastSequence, 2);
verifyTrue(testCase, isfield(first, 'spatialObservations'));
end


function testMissionBoundaryDoesNotLeakOracleDiagnostics(testCase)
[scenario, probe] = sampleMission(942);
[measurement, ~] = requestSensorData(scenario, probe);

names = string(fieldnames(measurement));
verifyFalse(testCase, any(contains(lower(names), "oracle")));
verifyFalse(testCase, any(contains(lower(names), "groundtruth")));
verifyTrue(testCase, isfield(measurement, 'sensorModelVersion'));
end


function testUnconfiguredHardwareCannotFallBackToSimulation(testCase)
[scenario, probe] = sampleMission(943);
probe.memory.acquisitionV2 = initializeAcquisitionStateV2( ...
    "HARDWARE", "MISSION_HW_943", "MEASURED");

verifyError(testCase, ...
    @() requestSensorData(scenario, probe), ...
    'USAR:AcquisitionV2:ProviderNotConfigured');
end


function testControllerStoresContractedMeasurement(testCase)
[scenario, probe] = sampleMission(944);
probe = missionController(scenario, probe);

verifyEqual(testCase, ...
    probe.lastSensorData.acquisitionContractVersion, "2.0");
verifyEqual(testCase, probe.lastSensorData.sequence, 1);
verifyEqual(testCase, ...
    probe.memory.acquisitionV2.lastSequence, 1);
end


function [scenario, probe] = sampleMission(seed)
config = ScenarioGenerator("Ideal");
config.randomSeed = seed;
scenario = createScenario(config);
probe = createProbe(scenario, "boustrophedon");
end
