function contracts = buildMissionContracts( ...
    missionId, scenario, simulationResult)
%% ============================================================
% Function Name : buildMissionContracts
%
% Description :
% بناء ثلاثة Contracts منفصلة:
% 1) scenario   : معلومات آمنة لعرض السيناريو دون كشف مواقع الضحايا.
% 2) result     : نتائج تشغيلية آمنة للداشبورد دون Ground Truth.
% 3) evaluation : نتائج التقييم بعد انتهاء المهمة فقط.
%
% الفصل يمنع تسرب Ground Truth إلى الواجهة التشغيلية أثناء البحث.
%% ============================================================

missionId = string(missionId);

contracts = struct();
contracts.scenario = buildScenarioContract(missionId, scenario);
contracts.result = buildOperationalResult( ...
    missionId, scenario, simulationResult);
contracts.evaluation = buildEvaluationResult( ...
    missionId, simulationResult);

end


function output = buildScenarioContract(missionId, scenario)

output = struct();
output.schemaVersion = "1.0";
output.contractType = "scenario";
output.missionId = missionId;
output.scenarioType = string(scenario.type);
output.randomSeed = double(scenario.randomSeed);
output.gridSize = double(scenario.gridSize(1:2));
output.parameters = struct( ...
    'numVictims', double(scenario.numVictims), ...
    'debrisDensity', double(scenario.debrisDensity), ...
    'noiseLevel', double(scenario.noiseLevel), ...
    'burialDepth', double(scenario.burialDepth), ...
    'vitalStrength', double(scenario.vitalStrength));
output.environmentSummary = struct( ...
    'meanDebris', mean(scenario.environment.debris(:)), ...
    'meanNoise', mean(scenario.environment.noise(:)), ...
    'obstacleFraction', mean(double(scenario.environment.obstacles(:))), ...
    'meanAccessibility', mean(scenario.environment.accessibility(:)), ...
    'meanRisk', mean(scenario.environment.risk(:)));
output.entryPoint = pointRCXY(scenario.environment.entryPoint);
output.exitPoint = pointRCXY(scenario.environment.exitPoint);
output.groundTruthHidden = true;

end


function output = buildOperationalResult( ...
    missionId, scenario, simulationResult)

output = struct();
output.schemaVersion = "1.1";
output.contractType = "mission-result";
output.missionId = missionId;
output.status = "COMPLETED";
output.scenarioType = string(simulationResult.scenarioType);
output.randomSeed = finiteOrEmpty(simulationResult.randomSeed);
output.systemDetectionCount = double( ...
    simulationResult.systemDetectionCount);
output.localizationMethod = string( ...
    simulationResult.localizationMethod);
output.fusion = struct( ...
    'historySize', double(simulationResult.fusionHistorySize), ...
    'maximumScore', finiteOrEmpty(simulationResult.maximumFusionScore), ...
    'meanScore', finiteOrEmpty(simulationResult.meanFusionScore));
output.victims = buildVictimList( ...
    simulationResult.detectedVictimDatabase, ...
    simulationResult.rescuePlan);
output.operationalMap = buildOperationalMap(scenario);
output.rescue = buildRescueSummary(simulationResult.rescuePlan);
output.containsGroundTruth = false;

end


function output = buildEvaluationResult(missionId, simulationResult)

matchedDistances = double(simulationResult.matchedDistances(:));
matchedDistances = matchedDistances(isfinite(matchedDistances));

metrics = simulationResult.metrics;

output = struct();
output.schemaVersion = "1.0";
output.contractType = "mission-evaluation";
output.missionId = missionId;
output.evaluationOnly = true;
output.releasePolicy = "POST_MISSION_ONLY";
output.counts = struct( ...
    'groundTruthVictims', double(simulationResult.groundTruthVictimCount), ...
    'systemDetections', double(simulationResult.systemDetectionCount), ...
    'truePositives', double(simulationResult.truePositives), ...
    'falsePositives', double(simulationResult.falsePositives), ...
    'falseNegatives', double(simulationResult.falseNegatives));
output.detection = struct( ...
    'precision', finiteOrEmpty(metrics.precision), ...
    'recall', finiteOrEmpty(metrics.recall), ...
    'f1Score', finiteOrEmpty(metrics.f1), ...
    'criticalSuccessIndex', finiteOrEmpty(metrics.criticalSuccessIndex), ...
    'falseDiscoveryRate', finiteOrEmpty(metrics.falseDiscoveryRate), ...
    'falseNegativeRate', finiteOrEmpty(metrics.falseNegativeRate));
output.localization = struct( ...
    'matchedVictimCount', numel(matchedDistances), ...
    'meanError', aggregateOrEmpty(matchedDistances, "mean"), ...
    'rmse', aggregateOrEmpty(matchedDistances, "rmse"), ...
    'medianError', aggregateOrEmpty(matchedDistances, "median"), ...
    'maximumError', aggregateOrEmpty(matchedDistances, "max"), ...
    'matchedErrors', matchedDistances);
output.positions = struct( ...
    'coordinateOrder', "xy", ...
    'groundTruth', positionsRCToXY(simulationResult.groundTruthPositions), ...
    'detected', positionsRCToXY(simulationResult.detectedVictimPositions));
output.rescue = buildRescueSummary(simulationResult.rescuePlan);

end


function victimsOutput = buildVictimList(victims, rescuePlan)

victimTemplate = struct( ...
    'id', [], ...
    'estimatedPosition', emptyPoint(), ...
    'vitalityIndex', [], ...
    'medicalSeverity', [], ...
    'condition', "UNKNOWN", ...
    'priorityScore', [], ...
    'priorityLevel', "UNKNOWN", ...
    'rescueRank', [], ...
    'reachable', false, ...
    'independentViewCount', [], ...
    'shortestRoute', emptyRouteContract("shortest"), ...
    'recommendedRoute', emptyRouteContract("recommended"));

if isempty(victims)
    victimsOutput = repmat(victimTemplate, 0, 1);
    return;
end

validateOperationalVictimIDs(victims);
% الـDashboard وProteus يحتاجان معرفًا فريدًا وثابتًا لكل ضحية.

victimsOutput = repmat(victimTemplate, numel(victims), 1);

for index = 1:numel(victims)
    victim = victims(index);
    [shortestRoute, recommendedRoute] = ...
        findVictimRoutes(victim, rescuePlan);

    condition = "UNKNOWN";
    if isfield(victim, 'victimCondition')
        condition = string(victim.victimCondition);
    end

    rescueRank = [];
    if isfield(victim, 'rescueRank')
        rescueRank = finiteOrEmpty(victim.rescueRank);
    end

    reachable = false;
    if isfield(victim, 'reachable')
        reachable = logical(victim.reachable);
    elseif recommendedRoute.reachable
        reachable = true;
    end

    independentViews = [];
    if isfield(victim, 'independentViewCount')
        independentViews = finiteOrEmpty(victim.independentViewCount);
    end

    vitality = double(victim.vitalityIndex);
    victimsOutput(index).id = double(victim.id);
    victimsOutput(index).estimatedPosition = pointRCXY(victim.position);
    victimsOutput(index).vitalityIndex = vitality;
    victimsOutput(index).medicalSeverity = 1 - max(0,min(1,vitality));
    victimsOutput(index).condition = condition;
    victimsOutput(index).priorityScore = finiteOrEmpty(victim.priorityScore);
    victimsOutput(index).priorityLevel = string(victim.priorityLevel);
    victimsOutput(index).rescueRank = rescueRank;
    victimsOutput(index).reachable = reachable;
    victimsOutput(index).independentViewCount = independentViews;
    victimsOutput(index).shortestRoute = shortestRoute;
    victimsOutput(index).recommendedRoute = recommendedRoute;
end

end


function [shortestRoute, recommendedRoute] = ...
    findVictimRoutes(victim, rescuePlan)

shortestRoute = emptyRouteContract("shortest");
recommendedRoute = emptyRouteContract("recommended");

if ~isempty(rescuePlan) && isfield(rescuePlan,'victimID')
    ids = double([rescuePlan.victimID]);
    routeIndex = find(ids == double(victim.id), 1, 'first');
    if ~isempty(routeIndex)
        item = rescuePlan(routeIndex);
        if isfield(item,'shortestRoute')
            shortestRoute = routeToContract( ...
                item.shortestRoute, "shortest");
        end
        if isfield(item,'recommendedRoute')
            recommendedRoute = routeToContract( ...
                item.recommendedRoute, "recommended");
        end
        return;
    end
end

% Backward-compatible fallback for older victim records.
shortestRoute = routeFromVictimFields(victim, "shortest");
recommendedRoute = routeFromVictimFields(victim, "recommended");

end


function route = routeToContract(source, mode)

route = emptyRouteContract(mode);
if isempty(source) || ~isstruct(source)
    return;
end

route.reachable = fieldLogicalOrFalse(source,'reachable');
route.path = positionsRCToXY(fieldOrEmpty(source,'path'));
route.pathLength = finiteFieldOrEmpty(source,'pathLength');
route.travelCost = finiteFieldOrEmpty(source,'travelCost');
route.meanRisk = finiteFieldOrEmpty(source,'meanRisk');
route.maximumRisk = finiteFieldOrEmpty(source,'maximumRisk');
route.meanAccessibility = ...
    finiteFieldOrEmpty(source,'meanAccessibility');
route.meanDebris = finiteFieldOrEmpty(source,'meanDebris');
route.expandedNodes = finiteFieldOrEmpty(source,'expandedNodes');

accessPoint = fieldOrEmpty(source,'accessPoint');
if numel(accessPoint) >= 2
    route.accessPoint = pointRCXY(accessPoint);
end

end


function route = routeFromVictimFields(victim, mode)

route = emptyRouteContract(mode);

if mode == "recommended"
    if isfield(victim,'recommendedPath')
        route.path = positionsRCToXY(victim.recommendedPath);
    end
    route.pathLength = finiteFieldOrEmpty( ...
        victim,'recommendedPathLength');
    route.travelCost = finiteFieldOrEmpty( ...
        victim,'recommendedTravelCost');
    route.meanRisk = finiteFieldOrEmpty(victim,'meanRouteRisk');
    route.meanAccessibility = finiteFieldOrEmpty( ...
        victim,'meanRouteAccessibility');
    if isfield(victim,'reachable')
        route.reachable = logical(victim.reachable);
    end
    if isfield(victim,'rescueAccessPoint') && ...
            numel(victim.rescueAccessPoint) >= 2
        route.accessPoint = pointRCXY(victim.rescueAccessPoint);
    end
else
    if isfield(victim,'shortestPath')
        route.path = positionsRCToXY(victim.shortestPath);
    end
    route.pathLength = finiteFieldOrEmpty(victim,'shortestPathLength');
    route.reachable = ~isempty(route.path);
    if ~isempty(route.path)
        route.accessPoint = pointXY(route.path(end,:));
    end
end

end


function route = emptyRouteContract(mode)

route = struct( ...
    'mode', string(mode), ...
    'coordinateOrder', "xy", ...
    'reachable', false, ...
    'path', zeros(0,2), ...
    'pathLength', [], ...
    'travelCost', [], ...
    'meanRisk', [], ...
    'maximumRisk', [], ...
    'meanAccessibility', [], ...
    'meanDebris', [], ...
    'expandedNodes', [], ...
    'accessPoint', emptyPoint());

end


function output = buildOperationalMap(scenario)

obstacles = logical(scenario.environment.obstacles);
[rows,columns] = find(obstacles);
obstaclePositions = [rows,columns];

output = struct();
output.coordinateOrder = "xy";
output.gridSize = double(scenario.gridSize(1:2));
output.entryPoint = pointRCXY(scenario.environment.entryPoint);
output.exitPoint = pointRCXY(scenario.environment.exitPoint);
output.obstacles = positionsRCToXY(obstaclePositions);
output.obstacleCount = size(obstaclePositions,1);
output.containsGroundTruth = false;

end


function value = fieldOrEmpty(source, name)

if isfield(source,name)
    value = source.(name);
else
    value = [];
end

end


function value = finiteFieldOrEmpty(source, name)

value = [];
if isfield(source,name)
    value = finiteOrEmpty(source.(name));
end

end


function value = fieldLogicalOrFalse(source, name)

value = false;
if isfield(source,name)
    candidate = source.(name);
    if ~isempty(candidate)
        value = logical(candidate);
    end
end

end


function point = pointXY(position)

if isempty(position) || numel(position) < 2 || ...
        any(~isfinite(double(position(1:2))))
    point = emptyPoint();
    return;
end

point = struct( ...
    'row', [], ...
    'column', [], ...
    'x', double(position(1)), ...
    'y', double(position(2)));

end


function summary = buildRescueSummary(rescuePlan)

summary = struct( ...
    'victimCount', 0, ...
    'reachableVictimCount', 0, ...
    'meanRecommendedPathLength', [], ...
    'meanRecommendedRouteRisk', []);

if isempty(rescuePlan)
    return;
end

summary.victimCount = numel(rescuePlan);
routes = [rescuePlan.recommendedRoute];
reachableMask = [routes.reachable];
summary.reachableVictimCount = nnz(reachableMask);

if any(reachableMask)
    summary.meanRecommendedPathLength = mean( ...
        [routes(reachableMask).pathLength]);
    summary.meanRecommendedRouteRisk = mean( ...
        [routes(reachableMask).meanRisk]);
end

end


function point = pointRCXY(position)

if isempty(position) || numel(position) < 2 || ...
        any(~isfinite(double(position(1:2))))
    point = emptyPoint();
    return;
end

row = double(position(1));
column = double(position(2));
point = struct( ...
    'row', row, ...
    'column', column, ...
    'x', column, ...
    'y', row);

end


function point = emptyPoint()

point = struct('row',[],'column',[],'x',[],'y',[]);

end


function positionsXY = positionsRCToXY(positionsRC)

if isempty(positionsRC)
    positionsXY = zeros(0,2);
    return;
end

positionsRC = double(positionsRC);
if size(positionsRC,2) < 2
    error( ...
        "buildMissionContracts:InvalidPositions", ...
        "Position arrays must contain at least two columns [row column].");
end
positionsXY = [positionsRC(:,2), positionsRC(:,1)];

end


function value = finiteOrEmpty(value)

value = double(value);
if isempty(value) || ~isscalar(value) || ~isfinite(value)
    value = [];
end

end


function value = aggregateOrEmpty(values, method)

if isempty(values)
    value = [];
    return;
end

switch string(method)
    case "mean"
        value = mean(values);
    case "rmse"
        value = sqrt(mean(values.^2));
    case "median"
        value = median(values);
    case "max"
        value = max(values);
    otherwise
        error( ...
            "buildMissionContracts:UnknownAggregate", ...
            "Unknown aggregate method: %s", method);
end

end

function validateOperationalVictimIDs(victims)

if ~isfield(victims,'id')
    error( ...
        'buildMissionContracts:MissingVictimID', ...
        'Operational victim records must contain an id field.');
end

ids = double([victims.id]);
if any(~isfinite(ids)) || ...
        any(ids < 1) || ...
        any(ids ~= floor(ids))
    error( ...
        'buildMissionContracts:InvalidVictimID', ...
        'Operational victim IDs must be finite positive integers.');
end

if numel(unique(ids)) ~= numel(ids)
    error( ...
        'buildMissionContracts:DuplicateVictimIDs', ...
        'Operational victim IDs must be unique.');
end

end

