function measurementPacket = buildMeasurementPacket(radarOutput, thermalOutput, acousticOutput, probe)
%% ============================================================
% Function Name : buildMeasurementPacket
%
% Description :
% بناء حزمة قياسات موحدة تحتوي على القراءات المعيارية،
% القراءات الفيزيائية، وحدات القياس، الموثوقية، وحالة القياس.
%% ============================================================

measurementPacket = struct();

measurementPacket.radar = radarOutput.normalizedValue;
measurementPacket.thermal = thermalOutput.normalizedValue;
measurementPacket.acoustic = acousticOutput.normalizedValue;

measurementPacket.radarPhysical = radarOutput.physicalReading;
measurementPacket.thermalPhysical = thermalOutput.physicalReading;
measurementPacket.acousticPhysical = acousticOutput.physicalReading;

measurementPacket.radarUnit = radarOutput.physicalUnit;
measurementPacket.thermalUnit = thermalOutput.physicalUnit;
measurementPacket.acousticUnit = acousticOutput.physicalUnit;

measurementPacket.radarReliability = ...
    radarOutput.observableReliability;
measurementPacket.thermalReliability = ...
    thermalOutput.observableReliability;
measurementPacket.acousticReliability = ...
    acousticOutput.observableReliability;
% حقول الاستدلال تعتمد على ضوضاء المستقبِل القابلة للملاحظة فقط.

measurementPacket.diagnosticRadarOracleReliability = ...
    radarOutput.reliability;
measurementPacket.diagnosticThermalOracleReliability = ...
    thermalOutput.reliability;
measurementPacket.diagnosticAcousticOracleReliability = ...
    acousticOutput.reliability;

measurementPacket.diagnosticRadarSnrDb = radarOutput.snrDb;
measurementPacket.diagnosticThermalSnrDb = thermalOutput.snrDb;
measurementPacket.diagnosticAcousticSnrDb = acousticOutput.snrDb;

measurementPacket.diagnosticRadarSignalComponent = ...
    radarOutput.signalComponent;
measurementPacket.diagnosticThermalSignalComponent = ...
    thermalOutput.signalComponent;
measurementPacket.diagnosticAcousticSignalComponent = ...
    acousticOutput.signalComponent;

measurementPacket.radarNoiseStd = radarOutput.observableNoiseStd;
measurementPacket.thermalNoiseStd = thermalOutput.observableNoiseStd;
measurementPacket.acousticNoiseStd = acousticOutput.observableNoiseStd;

measurementPacket.spatialObservations = struct();
measurementPacket.spatialObservations.radar = ...
    readSpatialObservations(radarOutput);
measurementPacket.spatialObservations.thermal = ...
    readSpatialObservations(thermalOutput);
measurementPacket.spatialObservations.acoustic = ...
    readSpatialObservations(acousticOutput);
% مجموعات قياس مجهولة الهوية: لا تحتوي مواقع ضحايا أو معرفاتهم.

measurementPacket.diagnosticRadarActualNoiseStd = ...
    radarOutput.noiseStd;
measurementPacket.diagnosticThermalActualNoiseStd = ...
    thermalOutput.noiseStd;
measurementPacket.diagnosticAcousticActualNoiseStd = ...
    acousticOutput.noiseStd;

measurementPacket.sensorModelVersion = ...
    "SOURCE_PATH_RECEIVER_V4_SPATIAL_NO_ORACLE_INFERENCE";
% بيانات تشخيصية لا تدخل مباشرة في قرار الكشف، لكنها تجعل التحقق
% من معادلات الحساسات وعمليات المعايرة قابلة للتتبع.

measurementPacket.timestamp = datetime("now");
measurementPacket.probePosition = probe.position;
if isfield(probe, 'headingDegrees')
    measurementPacket.probeHeadingDegrees = probe.headingDegrees;
else
    measurementPacket.probeHeadingDegrees = 0;
end

measurementPacket.status = "VALID";

measurementPacket.quality = mean([ ...
    radarOutput.observableReliability, ...
    thermalOutput.observableReliability, ...
    acousticOutput.observableReliability]);

end


function observations = readSpatialObservations(sensorOutput)

if isstruct(sensorOutput) && ...
        isfield(sensorOutput, 'spatialObservations') && ...
        isstruct(sensorOutput.spatialObservations)
    observations = sensorOutput.spatialObservations;
else
    observations = struct( ...
        'range', {}, 'rangeStd', {}, ...
        'bearing', {}, 'bearingStd', {}, ...
        'strength', {}, 'confidence', {}, ...
        'breathingPeriodicity', {}, ...
        'heartbeatPeriodicity', {}, ...
        'sensorName', {}, 'eventType', {});
end

end
