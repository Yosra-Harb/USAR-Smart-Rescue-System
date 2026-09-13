function tests = testMCUTransportContract
% Run independently: runtests('testMCUTransportContract')
tests = functiontests(localfunctions);
end

function testWhitelistAndRoundTrip(testCase)
measurement = sampleMeasurement();
measurement.groundTruthVictimPosition = [12 17];
measurement.diagnosticRadarOracleReliability = 1;
frame = buildMCUTransportFrame(measurement, "MISSION_01", 1);
verifyFalse(testCase, contains(jsonencode(frame), 'groundTruth'));
verifyFalse(testCase, contains(jsonencode(frame), 'Oracle'));
response = simulateMCUTransport(frame, 0);
validateMCUTransportResponse(frame, response);
verifyEqual(testCase, response.sensors.radar.normalized, 0.3);
end

function testDecodedPoseAcceptsColumnVector(testCase)
frame = buildMCUTransportFrame(sampleMeasurement(), "MISSION_01", 1);
decoded = jsondecode(jsonencode(frame));
verifyEqual(testCase, size(decoded.probePosition), [2 1]);
validateMCUTransportFrame(decoded);
end

function testRejectMalformedReading(testCase)
frame = buildMCUTransportFrame(sampleMeasurement(), "MISSION_01", 1);
frame.sensors.acoustic.reliability = NaN;
verifyError(testCase, @() validateMCUTransportFrame(frame), ...
    'USAR:MCUFrame:Reading');
end

function testRejectOracleField(testCase)
frame = buildMCUTransportFrame(sampleMeasurement(), "MISSION_01", 1);
frame.victimPosition = [2 3];
verifyError(testCase, @() validateMCUTransportFrame(frame), ...
    'USAR:MCUFrame:Fields');
end

function testRejectDuplicateOrOutOfOrder(testCase)
frame = buildMCUTransportFrame(sampleMeasurement(), "MISSION_01", 1);
verifyError(testCase, @() simulateMCUTransport(frame, 1), ...
    'USAR:MCUTransport:Sequence');
verifyError(testCase, @() simulateMCUTransport(frame, 2), ...
    'USAR:MCUTransport:Sequence');
end

function testRejectWrongAckOrAlteredPayload(testCase)
frame = buildMCUTransportFrame(sampleMeasurement(), "MISSION_01", 1);
response = simulateMCUTransport(frame, 0);
response.sequence = 2;
verifyError(testCase, @() validateMCUTransportResponse(frame, response), ...
    'USAR:MCUTransport:ACK');
response.sequence = 1;
response.sensors.thermal.normalized = 0.9;
verifyError(testCase, @() validateMCUTransportResponse(frame, response), ...
    'USAR:MCUTransport:Payload');
end

function measurement = sampleMeasurement()
measurement = struct('probePosition', [4 9], ...
    'probeHeadingDegrees', 90, ...
    'radar', 0.3, 'radarPhysical', 0.8, ...
    'radarUnit', "mm", 'radarReliability', 0.75, ...
    'thermal', 0.2, 'thermalPhysical', 1.2, ...
    'thermalUnit', "C", 'thermalReliability', 0.8, ...
    'acoustic', 0.1, 'acousticPhysical', 0.05, ...
    'acousticUnit', "Pa", 'acousticReliability', 0.7);
end
