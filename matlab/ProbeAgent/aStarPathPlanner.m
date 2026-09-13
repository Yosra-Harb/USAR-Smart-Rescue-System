function path = aStarPathPlanner(scenario, startPosition, goalPosition)
%% ============================================================
% Function Name : aStarPathPlanner
%
% Description :
% تنفيذ خوارزمية A* لإيجاد أقصر مسار قابل للحركة
% بين موقع البداية والهدف مع تجنب العوائق.
%
% Inputs:
% scenario       -> بيئة المحاكاة.
% startPosition  -> [row, column].
% goalPosition   -> [row, column].
%
% Output:
% path           -> مصفوفة تحتوي المسار:
%                   [row1 col1;
%                    row2 col2;
%                    ...]
%% ============================================================

path = [];

gridRows = scenario.gridSize(1);
gridColumns = scenario.gridSize(2);

startPosition = normalizeGridPosition( ...
    startPosition,[gridRows gridColumns]);
goalPosition = normalizeGridPosition( ...
    goalPosition,[gridRows gridColumns]);

obstacleMap = scenario.environment.obstacles;

if obstacleMap(goalPosition(1), goalPosition(2)) == 1
    return;
end

gScore = inf(gridRows, gridColumns);
fScore = inf(gridRows, gridColumns);

parentRow = zeros(gridRows, gridColumns);
parentCol = zeros(gridRows, gridColumns);

openSet = false(gridRows, gridColumns);
closedSet = false(gridRows, gridColumns);

startRow = startPosition(1);
startCol = startPosition(2);

goalRow = goalPosition(1);
goalCol = goalPosition(2);

gScore(startRow, startCol) = 0;

fScore(startRow, startCol) = ...
    heuristic(startPosition, goalPosition);

openSet(startRow, startCol) = true;

neighborDirections = [ ...
    -1  0;
     1  0;
     0 -1;
     0  1];

while any(openSet(:))

    candidateScores = fScore;
    candidateScores(~openSet) = inf;

    [~, linearIndex] = min(candidateScores(:));

    [currentRow, currentCol] = ...
        ind2sub(size(candidateScores), linearIndex);

    if currentRow == goalRow && ...
            currentCol == goalCol

        path = reconstructPath( ...
            parentRow, ...
            parentCol, ...
            startPosition, ...
            goalPosition);

        return;

    end

    openSet(currentRow, currentCol) = false;
    closedSet(currentRow, currentCol) = true;

    for k = 1:size(neighborDirections,1)

        neighborRow = ...
            currentRow + neighborDirections(k,1);

        neighborCol = ...
            currentCol + neighborDirections(k,2);

        if neighborRow < 1 || ...
                neighborRow > gridRows || ...
                neighborCol < 1 || ...
                neighborCol > gridColumns
            continue;
        end

        if obstacleMap(neighborRow, neighborCol) == 1
            continue;
        end

        if closedSet(neighborRow, neighborCol)
            continue;
        end

        movementCost = ...
            scenario.environment.movementCost( ...
            neighborRow, ...
            neighborCol);

        tentativeG = ...
            gScore(currentRow, currentCol) + movementCost;

        if tentativeG < gScore(neighborRow, neighborCol)

            parentRow(neighborRow, neighborCol) = currentRow;
            parentCol(neighborRow, neighborCol) = currentCol;

            gScore(neighborRow, neighborCol) = tentativeG;

            h = heuristic( ...
                [neighborRow neighborCol], ...
                goalPosition);

            fScore(neighborRow, neighborCol) = ...
                tentativeG + h;

            openSet(neighborRow, neighborCol) = true;

        end

    end

end

end

%% ============================================================
% Heuristic Function
%% ============================================================

function h = heuristic(position, goal)

h = abs(position(1) - goal(1)) + ...
    abs(position(2) - goal(2));

end

%% ============================================================
% Reconstruct Path
%% ============================================================

function path = reconstructPath( ...
    parentRow, ...
    parentCol, ...
    startPosition, ...
    goalPosition)

maxPathLength = numel(parentRow);

reversePath = zeros(maxPathLength,2);

pathIndex = 1;

current = goalPosition;

reversePath(pathIndex,:) = current;

while ~( ...
        current(1) == startPosition(1) && ...
        current(2) == startPosition(2))

    row = current(1);
    col = current(2);

    parentR = parentRow(row,col);
    parentC = parentCol(row,col);

    if parentR == 0
        path = [];
        return;
    end

    current = [parentR parentC];

    pathIndex = pathIndex + 1;

    reversePath(pathIndex,:) = current;

end

reversePath = reversePath(1:pathIndex,:);

path = flipud(reversePath);

end
