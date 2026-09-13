function priorityPacket = buildPriorityPacket( ...
    vitalityPacket, ...
    priorityScore, ...
    priorityLevel, ...
    priorityComponents)
%% ============================================================
% Function Name : buildPriorityPacket
%
% Description :
% بناء حزمة أولوية الإنقاذ النهائية.
%% ============================================================

priorityPacket = struct();

priorityPacket.isVictimDetected = ...
    vitalityPacket.isVictimDetected;

priorityPacket.estimatedPosition = ...
    vitalityPacket.estimatedPosition;

priorityPacket.probePosition = ...
    vitalityPacket.probePosition;

priorityPacket.vitalityIndex = ...
    vitalityPacket.vitalityIndex;

priorityPacket.priorityScore = ...
    priorityScore;

priorityPacket.priorityLevel = ...
    priorityLevel;

if nargin < 4 || isempty(priorityComponents)
    priorityComponents = struct();
end
priorityPacket.priorityComponents = priorityComponents;

priorityPacket.timestamp = ...
    vitalityPacket.timestamp;

end
