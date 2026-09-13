function packet = buildSensorPacket( ...
    radarOutput, ...
    thermalOutput, ...
    acousticOutput)

packet = struct();

packet.radar = radarOutput;

packet.thermal = thermalOutput;

packet.acoustic = acousticOutput;

packet.timestamp = datetime("now");

packet.packetID = randi([1000 9999]);

packet.status = "READY";

end