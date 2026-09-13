function route = planRescueRoute( ...
    scenario, startPosition, victimPosition, routeMode)
%% ============================================================
% A* بثمانية اتجاهات إلى أقرب خلية وصول آمنة حول الضحية.
% routeMode="shortest" يقلل الطول، و"recommended" يوازن الطول
% مع الخطر والركام وسهولة الحركة.
%% ============================================================

if nargin < 4
    routeMode = "recommended";
end
routeMode = lower(string(routeMode));
if ~any(routeMode == ["shortest", "recommended"])
    error("planRescueRoute:InvalidMode", ...
        "routeMode must be shortest or recommended.");
end

config = constants();
planningConfig = config.rescuePlanning;
gridSize = double(scenario.gridSize(1:2));
startPosition = normalizeGridPosition(startPosition,gridSize);
victimPosition = normalizeGridPosition(victimPosition,gridSize);
obstacles = logical(scenario.environment.obstacles);
goalMask = buildGoalMask( ...
    victimPosition, obstacles, gridSize, ...
    planningConfig.goalAccessRadius);

route = emptyRoute(routeMode, startPosition, victimPosition);
if ~any(goalMask(:)) || obstacles(startPosition(1),startPosition(2))
    return;
end

gScore = inf(gridSize);
fScore = inf(gridSize);
parentRow = zeros(gridSize);
parentColumn = zeros(gridSize);
openSet = false(gridSize);
closedSet = false(gridSize);
gScore(startPosition(1),startPosition(2)) = 0;
fScore(startPosition(1),startPosition(2)) = ...
    distanceToNearestGoal(startPosition, goalMask);
openSet(startPosition(1),startPosition(2)) = true;

directions = [-1 0; 1 0; 0 -1; 0 1];
if planningConfig.allowDiagonalMovement
    directions = [directions; -1 -1; -1 1; 1 -1; 1 1];
end

expandedNodes = 0;
goalPosition = [];
while any(openSet(:)) && ...
        expandedNodes < planningConfig.maximumExpandedNodes
    candidateScores = fScore;
    candidateScores(~openSet) = Inf;
    [~, linearIndex] = min(candidateScores(:));
    [currentRow,currentColumn] = ind2sub(gridSize, linearIndex);
    if goalMask(currentRow,currentColumn)
        goalPosition = [currentRow,currentColumn];
        break;
    end

    openSet(currentRow,currentColumn) = false;
    closedSet(currentRow,currentColumn) = true;
    expandedNodes = expandedNodes + 1;

    for directionIndex = 1:size(directions,1)
        direction = directions(directionIndex,:);
        neighbor = [currentRow,currentColumn] + direction;
        if any(neighbor < 1) || neighbor(1) > gridSize(1) || ...
                neighbor(2) > gridSize(2) || ...
                obstacles(neighbor(1),neighbor(2)) || ...
                closedSet(neighbor(1),neighbor(2))
            continue;
        end
        if all(abs(direction) == 1) && ...
                (obstacles(currentRow,neighbor(2)) || ...
                obstacles(neighbor(1),currentColumn))
            continue;
            % منع قطع زاوية بين عائقين.
        end

        geometricStep = hypot(direction(1),direction(2));
        stepCost = geometricStep;
        if routeMode == "recommended"
            debris = readMap(scenario,'debris',neighbor,0);
            risk = readMap(scenario,'risk',neighbor,0);
            accessibility = readMap( ...
                scenario,'accessibility',neighbor,1);
            stepCost = geometricStep * (1 + ...
                planningConfig.debrisWeight*debris + ...
                planningConfig.riskWeight*risk + ...
                planningConfig.inaccessibilityWeight* ...
                (1-accessibility));
        end
        tentative = gScore(currentRow,currentColumn) + stepCost;
        if tentative < gScore(neighbor(1),neighbor(2))
            parentRow(neighbor(1),neighbor(2)) = currentRow;
            parentColumn(neighbor(1),neighbor(2)) = currentColumn;
            gScore(neighbor(1),neighbor(2)) = tentative;
            heuristic = distanceToNearestGoal(neighbor,goalMask);
            fScore(neighbor(1),neighbor(2)) = tentative + heuristic;
            openSet(neighbor(1),neighbor(2)) = true;
        end
    end
end

if isempty(goalPosition)
    route.expandedNodes = expandedNodes;
    return;
end

path = reconstructPath(parentRow,parentColumn, ...
    startPosition,goalPosition);
route.reachable = ~isempty(path);
route.path = path;
route.accessPoint = goalPosition;
route.travelCost = gScore(goalPosition(1),goalPosition(2));
route.expandedNodes = expandedNodes;
if route.reachable
    route.pathLength = calculatePathLength(path);
    route.meanRisk = meanMapOnPath(scenario,'risk',path,0);
    route.maximumRisk = maxMapOnPath(scenario,'risk',path,0);
    route.meanAccessibility = ...
        meanMapOnPath(scenario,'accessibility',path,1);
    route.meanDebris = meanMapOnPath(scenario,'debris',path,0);
end

end


function goalMask = buildGoalMask(victim,obstacles,gridSize,radius)

[rowGrid,columnGrid] = ndgrid(1:gridSize(1),1:gridSize(2));
goalMask = false(gridSize);
if ~obstacles(victim(1),victim(2))
    goalMask(victim(1),victim(2)) = true;
else
    goalMask = hypot(rowGrid-victim(1),columnGrid-victim(2)) <= radius;
    goalMask = goalMask & ~obstacles;
end
if ~any(goalMask(:))
    goalMask = ~obstacles & ...
        hypot(rowGrid-victim(1),columnGrid-victim(2)) <= radius+2;
end

end


function distance = distanceToNearestGoal(position,goalMask)

[rows,columns] = find(goalMask);
distance = min(hypot(rows-position(1),columns-position(2)));

end


function path = reconstructPath(parentRow,parentColumn,start,goal)

reversePath = zeros(numel(parentRow),2);
count = 1;
current = goal;
reversePath(count,:) = current;
while ~isequal(current,start)
    parent = [parentRow(current(1),current(2)), ...
        parentColumn(current(1),current(2))];
    if any(parent == 0)
        path = zeros(0,2);
        return;
    end
    current = parent;
    count = count + 1;
    reversePath(count,:) = current;
end
path = flipud(reversePath(1:count,:));

end


function lengthValue = calculatePathLength(path)

if size(path,1) < 2
    lengthValue = 0;
else
    differences = diff(path,1,1);
    lengthValue = sum(hypot(differences(:,1),differences(:,2)));
end

end


function value = readMap(scenario,name,position,fallback)

if isfield(scenario.environment,name)
    map = scenario.environment.(name);
    value = double(map(position(1),position(2)));
else
    value = fallback;
end
value = max(0,min(1,value));

end


function value = meanMapOnPath(scenario,name,path,fallback)

values = zeros(size(path,1),1);
for index = 1:size(path,1)
    values(index) = readMap(scenario,name,path(index,:),fallback);
end
value = mean(values);

end


function value = maxMapOnPath(scenario,name,path,fallback)

values = zeros(size(path,1),1);
for index = 1:size(path,1)
    values(index) = readMap(scenario,name,path(index,:),fallback);
end
value = max(values);

end


function route = emptyRoute(mode,start,victim)

route = struct( ...
    'mode',string(mode),'startPosition',start,'victimPosition',victim, ...
    'reachable',false,'path',zeros(0,2),'accessPoint',zeros(0,2), ...
    'pathLength',Inf,'travelCost',Inf,'meanRisk',NaN, ...
    'maximumRisk',NaN,'meanAccessibility',NaN,'meanDebris',NaN, ...
    'expandedNodes',0);

end
