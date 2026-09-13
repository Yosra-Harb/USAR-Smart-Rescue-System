function frame = buildMCUTransportFrame(measurement, missionId, sequence)
%BUILDMCUTRANSPORTFRAME Whitelist the data allowed on the future MCU link.
% This is a protocol candidate, not a live Proteus connection.

frame = struct();
frame.schemaVersion = "1.0";
frame.missionId = string(missionId);
frame.sequence = double(sequence);
frame.timestampUtc = string(datetime('now', 'TimeZone', 'UTC', ...
    'Format', "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"));
frame.source = "SIMULATED";
frame.probePosition = double(measurement.probePosition(:)');
frame.probeHeadingDegrees = double(measurement.probeHeadingDegrees);

names = {'radar', 'thermal', 'acoustic'};
frame.sensors = struct();
for k = 1:numel(names)
    name = names{k};
    frame.sensors.(name) = struct( ...
        'normalized', double(measurement.(name)), ...
        'physical', double(measurement.([name 'Physical'])), ...
        'unit', string(measurement.([name 'Unit'])), ...
        'reliability', double(measurement.([name 'Reliability'])));
end

validateMCUTransportFrame(frame);
end
