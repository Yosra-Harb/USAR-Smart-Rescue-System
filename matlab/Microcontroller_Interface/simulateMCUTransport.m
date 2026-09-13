function response = simulateMCUTransport(frame, previousSequence)
%SIMULATEMCUTRANSPORT Software stand-in for a future MCU firmware exchange.
% The caller owns previousSequence and must reset it on each new mission.
if nargin < 2
    previousSequence = -1;
end

% JSON round-trip exercises the actual wire-compatible representation.
frame = jsondecode(jsonencode(frame));
validateMCUTransportFrame(frame);
if ~isnumeric(previousSequence) || ~isscalar(previousSequence) || ...
        ~isfinite(previousSequence) || frame.sequence <= previousSequence
    error('USAR:MCUTransport:Sequence', ...
        'Duplicate or out-of-order sensor frame.');
end

response = struct('schemaVersion', "1.0", ...
    'missionId', string(frame.missionId), ...
    'sequence', frame.sequence, 'ack', "ACK", ...
    'status', "VALID", 'sensors', frame.sensors);
response = jsondecode(jsonencode(response));
end
