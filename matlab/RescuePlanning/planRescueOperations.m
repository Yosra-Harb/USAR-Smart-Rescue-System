function [victims, rescuePlan] = planRescueOperations( ...
    scenario, victims, startPosition)
%% ============================================================
% حساب المسار الأقصر والمسار الموصى به ثم ترتيب عمليات الإنقاذ.
%% ============================================================

if nargin < 3 || isempty(startPosition)
    startPosition = scenario.environment.entryPoint;
end
rescuePlan = struct([]);
if isempty(victims)
    return;
end

victims = ensurePlanningSchema(victims);
validateUniqueVictimIDs(victims);
% ترتيب rescuePlan يعتمد على victimID، لذلك يجب أن تكون المعرفات فريدة.

for index = 1:numel(victims)
    shortest = planRescueRoute( ...
        scenario,startPosition,victims(index).position,"shortest");
    recommended = planRescueRoute( ...
        scenario,startPosition,victims(index).position,"recommended");
    [score,components] = calculateRescuePriority( ...
        victims(index),recommended);

    victims(index).rescuePriorityScore = score;
    victims(index).priorityScore = score;
    victims(index).priorityLevel = classifyPriority(score);
    victims(index).reachable = recommended.reachable;
    victims(index).shortestPath = shortest.path;
    victims(index).recommendedPath = recommended.path;
    victims(index).shortestPathLength = shortest.pathLength;
    victims(index).recommendedPathLength = recommended.pathLength;
    victims(index).recommendedTravelCost = recommended.travelCost;
    victims(index).meanRouteRisk = recommended.meanRisk;
    victims(index).meanRouteAccessibility = ...
        recommended.meanAccessibility;
    victims(index).rescueAccessPoint = recommended.accessPoint;
    victims(index).priorityComponents = components;

    rescuePlan(index,1).victimID = victims(index).id; %#ok<AGROW>
    rescuePlan(index,1).estimatedPosition = victims(index).position;
    rescuePlan(index,1).shortestRoute = shortest;
    rescuePlan(index,1).recommendedRoute = recommended;
    rescuePlan(index,1).priorityScore = score;
    rescuePlan(index,1).priorityLevel = classifyPriority(score);
    rescuePlan(index,1).priorityComponents = components;
end

victims = rankVictims(victims);
idOrder = [victims.id];
[~,order] = ismember(idOrder,[rescuePlan.victimID]);
rescuePlan = rescuePlan(order);
for index = 1:numel(rescuePlan)
    rescuePlan(index).rescueRank = index;
end

end


function [score,components] = calculateRescuePriority(victim,route)

config = constants();
weights = config.rescuePriority;
vitality = max(0,min(1,victim.vitalityIndex));
severity = 1-vitality;
reachable = double(route.reachable);
if route.reachable
    proximity = exp(-route.pathLength / ...
        max(config.rescuePlanning.proximityScale,eps));
    accessibility = max(0,min(1,route.meanAccessibility));
    safety = 1-max(0,min(1,route.meanRisk));
else
    proximity = 0;
    accessibility = 0;
    safety = 0;
end

base = weights.severityWeight*severity + ...
    weights.reachabilityWeight*reachable + ...
    weights.proximityWeight*proximity + ...
    weights.accessibilityWeight*accessibility + ...
    weights.safetyWeight*safety;
interaction = weights.criticalReachabilityInteraction * ...
    severity * reachable * accessibility * safety;
score = (base+interaction) / ...
    (1+weights.criticalReachabilityInteraction);
score = max(0,min(1,score));

components = struct( ...
    'medicalSeverity',severity, ...
    'reachable',logical(route.reachable), ...
    'proximityScore',proximity, ...
    'accessibilityScore',accessibility, ...
    'safetyScore',safety, ...
    'criticalReachabilityInteraction',interaction);

end


function victims = ensurePlanningSchema(victims)

defaults = struct( ...
    'rescueRank',NaN,'rescuePriorityScore',NaN,'reachable',false, ...
    'shortestPath',zeros(0,2),'recommendedPath',zeros(0,2), ...
    'shortestPathLength',Inf,'recommendedPathLength',Inf, ...
    'recommendedTravelCost',Inf,'meanRouteRisk',NaN, ...
    'meanRouteAccessibility',NaN,'rescueAccessPoint',zeros(0,2), ...
    'priorityComponents',struct());
names = fieldnames(defaults);
for nameIndex = 1:numel(names)
    name = names{nameIndex};
    if ~isfield(victims,name)
        for victimIndex = 1:numel(victims)
            victims(victimIndex).(name) = defaults.(name);
        end
    end
end

end

function validateUniqueVictimIDs(victims)

if isempty(victims)
    return;
end

if ~isfield(victims,'id')
    error( ...
        'planRescueOperations:MissingVictimID', ...
        'Victim records must contain an id field.');
end

ids = double([victims.id]);
if any(~isfinite(ids)) || ...
        any(ids < 1) || ...
        any(ids ~= floor(ids))
    error( ...
        'planRescueOperations:InvalidVictimID', ...
        'Victim IDs must be finite positive integers.');
end

if numel(unique(ids)) ~= numel(ids)
    error( ...
        'planRescueOperations:DuplicateVictimIDs', ...
        'Victim IDs must be unique before rescue planning.');
end

end

