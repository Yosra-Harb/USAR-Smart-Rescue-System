function tests = testAcquisitionFrameV2
tests = functiontests(localfunctions);
end

function setupOnce(~)
testsFolder = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(testsFolder), 'Main'), '-end');
setupProjectPaths();
end

function testJSONRoundTripPreservesRangedAndBearingOnlyObservations(testCase)
measurement = sampleMeasurement();
measurement.groundTruthVictimPosition = [20 21];
measurement.diagnosticRadarOracleReliability = 0.999;
frame = buildAcquisitionFrameV2(measurement, "MISSION_01", 1);
wire = jsonencode(frame);
verifyFalse(testCase, contains(wire, 'groundTruth'));
verifyFalse(testCase, contains(wire, 'Oracle'));
verifyFalse(testCase, contains(wire, 'NaN'));
verifyFalse(testCase, contains(wire, 'Infinity'));
restored = acquireMeasurementV2("SIMULATION", @() wire);
verifyEqual(testCase, restored.probePosition, [4 9]);
verifyEqual(testCase, restored.spatialObservations.radar.range, 4.2);
verifyTrue(testCase, isnan(restored.spatialObservations.thermal.range));
verifyTrue(testCase, isinf(restored.spatialObservations.thermal.rangeStd));
processed = signalProcessingManager(restored);
verifyEqual(testCase, processed.spatialObservations.radar.range, 4.2);
verifyEqual(testCase, processed.probePosition, [4 9]);
end

function testMissingSpatialFieldIsRejected(testCase)
frame = buildAcquisitionFrameV2(sampleMeasurement(), "MISSION_01", 1);
frame.spatialObservations = rmfield(frame.spatialObservations, 'radar');
verifyError(testCase, @() validateAcquisitionFrameV2(frame), ...
    'USAR:AcquisitionV2:Fields');
end

function testRejectGroundTruthLeak(testCase)
frame = buildAcquisitionFrameV2(sampleMeasurement(), "MISSION_01", 1);
frame.groundTruthVictims = [1 2];
verifyError(testCase, @() validateAcquisitionFrameV2(frame), ...
    'USAR:AcquisitionV2:Fields');
end

function testRejectCorruptSpatialObservation(testCase)
frame = buildAcquisitionFrameV2(sampleMeasurement(), "MISSION_01", 1);
frame.spatialObservations.radar{1}.bearingStd = -1;
verifyError(testCase, @() validateAcquisitionFrameV2(frame), ...
    'USAR:AcquisitionV2:Spatial');
end

function testHardwareCannotClaimSimulatedPose(testCase)
frame = buildAcquisitionFrameV2(sampleMeasurement(), "MISSION_01", 1);
frame.source = "HARDWARE";
verifyError(testCase, @() validateAcquisitionFrameV2(frame), ...
    'USAR:AcquisitionV2:Metadata');
end

function testProviderCannotSilentlySwitchSource(testCase)
frame = buildAcquisitionFrameV2(sampleMeasurement(), "MISSION_01", 1);
verifyError(testCase, ...
    @() acquireMeasurementV2("PROTEUS", @() frame), ...
    'USAR:AcquisitionV2:Source');
end

function measurement = sampleMeasurement()
measurement = struct('probePosition', [4 9], ...
    'probeHeadingDegrees', 90, ...
    'radar', 0.3, 'radarPhysical', 0.8, ...
    'radarUnit', "mm", 'radarReliability', 0.75, ...
    'radarNoiseStd', 0.02, ...
    'thermal', 0.2, 'thermalPhysical', 1.2, ...
    'thermalUnit', "C", 'thermalReliability', 0.8, ...
    'thermalNoiseStd', 0.03, ...
    'acoustic', 0.1, 'acousticPhysical', 0.05, ...
    'acousticUnit', "Pa", 'acousticReliability', 0.7, ...
    'acousticNoiseStd', 0.04);
radar = observation(4.2, 0.6, "UWB_RADAR", "MICRO_MOTION");
thermal = observation(NaN, Inf, "THERMAL", "HEAT_CONTRAST");
measurement.spatialObservations = struct();
measurement.spatialObservations.radar = radar;
measurement.spatialObservations.thermal = thermal;
measurement.spatialObservations.acoustic = radar([]);
end

function item = observation(range, rangeStd, sensorName, eventType)
item = struct('range', range, 'rangeStd', rangeStd, ...
    'bearing', 35, 'bearingStd', 4, 'strength', 0.4, ...
    'confidence', 0.8, 'breathingPeriodicity', 0.7, ...
    'heartbeatPeriodicity', 0.3, 'sensorName', sensorName, ...
    'eventType', eventType);
end
