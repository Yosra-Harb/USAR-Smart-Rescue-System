function [priorityScore, components] = calculatePriorityScore( ...
    scenario, ...
    vitalityPacket)

%% ============================================================
% Function Name : calculatePriorityScore
%
% Description :
% حساب درجة أولوية الإنقاذ.
%% ============================================================

VI = max(0, min(1, vitalityPacket.vitalityIndex));
medicalSeverity = 1 - VI;
% انخفاض مؤشر الحيوية يعني حالة أكثر خطورة وأولوية طبية أعلى.

%% ============================================================
% Determine Position
%% ============================================================

if isempty(vitalityPacket.estimatedPosition)

    position = ...
        vitalityPacket.probePosition;

else

    position = ...
        vitalityPacket.estimatedPosition;

end

position = double(position(1:2));
r = position(1);
c = position(2);

%% ============================================================
% Distance Score
%% ============================================================

entry = ...
    scenario.environment.entryPoint;

distance = sqrt( ...
    (r-entry(1))^2 + ...
    (c-entry(2))^2);

config = constants();
distanceScore = exp(-distance / ...
    max(config.rescuePlanning.proximityScale, eps));

%% ============================================================
% Accessibility and Risk
%% ============================================================

gridPosition = normalizeGridPosition( ...
    position,size(scenario.environment.accessibility));
gridRow = gridPosition(1);
gridColumn = gridPosition(2);

A = scenario.environment.accessibility( ...
    gridRow,gridColumn);

R = scenario.environment.risk( ...
    gridRow,gridColumn);

A = max(0, min(1, A));
R = max(0, min(1, R));
safety = 1 - R;
reachabilityProxy = A * safety;

%% ============================================================
% Priority Equation
%% ============================================================

weights = config.rescuePriority;
baseScore = ...
    weights.severityWeight * medicalSeverity + ...
    weights.reachabilityWeight * reachabilityProxy + ...
    weights.proximityWeight * distanceScore + ...
    weights.accessibilityWeight * A + ...
    weights.safetyWeight * safety;
interaction = weights.criticalReachabilityInteraction * ...
    medicalSeverity * reachabilityProxy;
priorityScore = (baseScore + interaction) / ...
    (1 + weights.criticalReachabilityInteraction);

priorityScore = ...
    max(0,min(1,priorityScore));

components = struct();
components.medicalSeverity = medicalSeverity;
components.proximityScore = distanceScore;
components.accessibilityScore = A;
components.safetyScore = safety;
components.reachabilityScore = reachabilityProxy;
components.directDistance = distance;
components.gridPosition = gridPosition;

end
