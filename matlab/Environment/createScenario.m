function scenario = createScenario(config)
%% ============================================================
% Function Name : createScenario
%
% Description :
% إنشاء السيناريو الكامل باستخدام هيكلية طبقات البيئة.
%% ============================================================

scenario = struct();

scenario.type = config.type;
scenario.gridSize = config.gridSize;
scenario.numVictims = config.numVictims;
scenario.debrisDensity = config.debrisDensity;
scenario.noiseLevel = config.noiseLevel;
scenario.burialDepth = config.burialDepth;
scenario.vitalStrength = config.vitalStrength;
scenario.accessibility = config.accessibility;
scenario.randomSeed = config.randomSeed;

rng(scenario.randomSeed);

%% ============================================================
% Environment Layers
%% ============================================================

scenario.environment = struct();

scenario.environment.debris = ...
    generateDebrisMap(scenario);

scenario.environment.noise = ...
    generateNoiseMap(scenario);

scenario.environment.attenuation = ...
    generateAttenuationMap(scenario);

scenario.environment.burialDepth = ...
    generateBurialDepthMap(scenario);

scenario.environment.obstacles = ...
    generateObstacles(scenario);

scenario.environment.accessibility = ...
    generateAccessibilityMap(scenario);

scenario.environment.risk = ...
    generateRiskMap(scenario);

scenario.environment.movementCost = ...
    generateMovementCostMap(scenario);

scenario.environment.entryPoint = ...
    [scenario.gridSize(1),1];

scenario.environment.exitPoint = ...
    [1,scenario.gridSize(2)];

%% ============================================================
% Victims
%% ============================================================

scenario.victims = ...
    generateVictims(scenario);

%% ============================================================
% Vital Signs Map
%% ============================================================

scenario.environment.vitalSigns = ...
    generateVitalSignsMap(scenario);

%% ============================================================
% Ground Truth
%% ============================================================

scenario.groundTruth = ...
    generateGroundTruth(scenario);

%% ============================================================
% Validation
%% ============================================================

validateScenario(scenario);

end