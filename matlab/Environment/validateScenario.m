function validateScenario(scenario)
%% ============================================================
% Function Name : validateScenario
%
% Description :
% التحقق من صحة السيناريو بعد إنشائه بالهيكلية الجديدة.
% يتم التأكد من:
% - صحة حجم البيئة
% - صحة الخرائط
% - أن القيم ضمن المجال الصحيح
% - أن الضحايا داخل الخريطة وليسوا داخل عوائق
%% ============================================================

if isempty(scenario.gridSize)
    error("Grid size is missing.");
end

if any(scenario.gridSize <= 0)
    error("Grid size must be positive.");
end

if scenario.numVictims < 0
    error("Number of victims cannot be negative.");
end

debrisMap = scenario.environment.debris;
noiseMap = scenario.environment.noise;
obstacleMap = scenario.environment.obstacles;
accessibilityMap = scenario.environment.accessibility;
riskMap = scenario.environment.risk;
movementCostMap = scenario.environment.movementCost;

if ~isequal(size(debrisMap), scenario.gridSize)
    error("Debris map size does not match grid size.");
end

if ~isequal(size(noiseMap), scenario.gridSize)
    error("Noise map size does not match grid size.");
end

if ~isequal(size(obstacleMap), scenario.gridSize)
    error("Obstacle map size does not match grid size.");
end

if ~isequal(size(accessibilityMap), scenario.gridSize)
    error("Accessibility map size does not match grid size.");
end

if ~isequal(size(riskMap), scenario.gridSize)
    error("Risk map size does not match grid size.");
end

if ~isequal(size(movementCostMap), scenario.gridSize)
    error("Movement cost map size does not match grid size.");
end

if any(debrisMap(:) < 0) || any(debrisMap(:) > 1)
    error("Debris map values must be between 0 and 1.");
end

if any(noiseMap(:) < 0) || any(noiseMap(:) > 1)
    error("Noise map values must be between 0 and 1.");
end

if any(accessibilityMap(:) < 0) || any(accessibilityMap(:) > 1)
    error("Accessibility map values must be between 0 and 1.");
end

if any(riskMap(:) < 0) || any(riskMap(:) > 1)
    error("Risk map values must be between 0 and 1.");
end

if any(movementCostMap(:) < 1)
    error("Movement cost values must be greater than or equal to 1.");
end

if any(~ismember(obstacleMap(:), [0 1]))
    error("Obstacle map must contain only 0 and 1 values.");
end

if ~isfield(scenario.environment, "entryPoint")
    error("Entry point is missing.");
end

if ~isfield(scenario.environment, "exitPoint")
    error("Exit point is missing.");
end

entry = scenario.environment.entryPoint;
exitPoint = scenario.environment.exitPoint;

if entry(1) < 1 || entry(1) > scenario.gridSize(1) || ...
   entry(2) < 1 || entry(2) > scenario.gridSize(2)
    error("Entry point is outside the grid.");
end

if exitPoint(1) < 1 || exitPoint(1) > scenario.gridSize(1) || ...
   exitPoint(2) < 1 || exitPoint(2) > scenario.gridSize(2)
    error("Exit point is outside the grid.");
end

if obstacleMap(entry(1), entry(2)) == 1
    error("Entry point is inside an obstacle.");
end

if obstacleMap(exitPoint(1), exitPoint(2)) == 1
    error("Exit point is inside an obstacle.");
end

for i = 1:size(scenario.victims,1)

    r = scenario.victims(i,1);
    c = scenario.victims(i,2);

    if r < 1 || r > scenario.gridSize(1) || ...
       c < 1 || c > scenario.gridSize(2)
        error("Victim location is outside the grid.");
    end

    if obstacleMap(r,c) == 1
        error("Victim was placed inside an obstacle.");
    end

end

disp("Scenario validation passed successfully.");

end