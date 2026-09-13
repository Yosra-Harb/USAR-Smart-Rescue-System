function measurement = decodeAcquisitionFrameV2(frame)
%DECODEACQUISITIONFRAMEV2 Produce the same input shape for signal processing.
validateAcquisitionFrameV2(frame);
measurement = struct();
measurement.timestamp = datetime( ...
    string(frame.timestampUtc), 'InputFormat', ...
    "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", 'TimeZone', 'UTC');
measurement.probePosition = double(frame.probePosition(:)');
measurement.probeHeadingDegrees = double(frame.probeHeadingDegrees);
measurement.spatialObservations = struct();
for name = ["radar","thermal","acoustic"]
    label = char(name);
    sensor = frame.sensors.(label);
    measurement.(label) = double(sensor.normalized);
    measurement.([label 'Physical']) = double(sensor.physical);
    measurement.([label 'Unit']) = string(sensor.unit);
    measurement.([label 'Reliability']) = double(sensor.reliability);
    measurement.([label 'NoiseStd']) = double(sensor.noiseStd);

    observations = frame.spatialObservations.(label);
    restored = struct('range', {}, 'rangeStd', {}, 'bearing', {}, ...
        'bearingStd', {}, 'strength', {}, 'confidence', {}, ...
        'breathingPeriodicity', {}, 'heartbeatPeriodicity', {}, ...
        'sensorName', {}, 'eventType', {});
    for k = 1:numel(observations)
        if iscell(observations)
            item = observations{k};
        else
            item = observations(k);
        end
        if logical(item.hasRange)
            range = double(item.range);
            rangeStd = double(item.rangeStd);
        else
            range = NaN;
            rangeStd = Inf;
        end
        restored(end+1,1) = struct( ... %#ok<AGROW>
            'range', range, 'rangeStd', rangeStd, ...
            'bearing', double(item.bearing), ...
            'bearingStd', double(item.bearingStd), ...
            'strength', double(item.strength), ...
            'confidence', double(item.confidence), ...
            'breathingPeriodicity', double(item.breathingPeriodicity), ...
            'heartbeatPeriodicity', double(item.heartbeatPeriodicity), ...
            'sensorName', string(item.sensorName), ...
            'eventType', string(item.eventType));
    end
    measurement.spatialObservations.(label) = restored;
end
measurement.quality = mean([measurement.radarReliability, ...
    measurement.thermalReliability, measurement.acousticReliability]);
measurement.status = "VALID";
measurement.acquisitionSource = string(frame.source);
measurement.poseSource = string(frame.poseSource);
measurement.missionId = string(frame.missionId);
measurement.sequence = double(frame.sequence);
end
