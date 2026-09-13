function tests = testPhase4ContinuousGridIndexing
%% Regression tests for continuous localization at matrix-access boundaries.

tests = functiontests(localfunctions);

end


function testNormalizeRoundsAndClampsContinuousPosition(testCase)

verifyEqual(testCase, ...
    normalizeGridPosition([4.6 5.2],[10 10]),[5 5]);
verifyEqual(testCase, ...
    normalizeGridPosition([-2.4 12.8],[10 10]),[1 10]);

end


function testPriorityAcceptsContinuousMeasurementPosition(testCase)

scenario = createGridScenario([12 14]);
scenario.environment.accessibility(5,6) = 0.35;
scenario.environment.risk(5,6) = 0.60;
packet = struct( ...
    'vitalityIndex',0.45, ...
    'estimatedPosition',[4.6 5.7], ...
    'probePosition',[2 2]);

[score,components] = calculatePriorityScore(scenario,packet);

verifyTrue(testCase,isfinite(score));
verifyGreaterThanOrEqual(testCase,score,0);
verifyLessThanOrEqual(testCase,score,1);
verifyEqual(testCase,components.gridPosition,[5 6]);
verifyEqual(testCase,components.accessibilityScore,0.35, ...
    'AbsTol',1e-12);
verifyEqual(testCase,components.safetyScore,0.40, ...
    'AbsTol',1e-12);

end


function testLocalSearchAcceptsContinuousCenter(testCase)

scenario = createGridScenario([12 14]);
probe = struct();
probe.position = [2.2 2.4];
probe.localSearch = struct('radius',2);

path = generateLocalSearchPath( ...
    scenario,probe,[5.4 6.6],0.80,0.70);

verifyNotEmpty(testCase,path);
verifyEqual(testCase,path,round(path));
verifyTrue(testCase,all(path(:,1) >= 1 & ...
    path(:,1) <= scenario.gridSize(1)));
verifyTrue(testCase,all(path(:,2) >= 1 & ...
    path(:,2) <= scenario.gridSize(2)));

end


function testAStarClampsContinuousEndpoints(testCase)

scenario = createGridScenario([8 9]);
path = aStarPathPlanner( ...
    scenario,[-1.2 2.4],[8.8 10.7]);

verifyNotEmpty(testCase,path);
verifyEqual(testCase,path(1,:),[1 2]);
verifyEqual(testCase,path(end,:),[8 9]);
verifyEqual(testCase,path,round(path));

end


function testRescueRouteAcceptsContinuousVictimPosition(testCase)

scenario = createGridScenario([12 14]);
route = planRescueRoute( ...
    scenario,[1.2 1.4],[10.6 12.7],"shortest");

verifyTrue(testCase,route.reachable);
verifyEqual(testCase,route.startPosition,[1 1]);
verifyEqual(testCase,route.victimPosition,[11 13]);
verifyEqual(testCase,route.path,round(route.path));

end


function scenario = createGridScenario(gridSize)

scenario = struct();
scenario.gridSize = gridSize;
scenario.environment = struct();
scenario.environment.entryPoint = [1 1];
scenario.environment.obstacles = false(gridSize);
scenario.environment.accessibility = ones(gridSize);
scenario.environment.risk = zeros(gridSize);
scenario.environment.movementCost = ones(gridSize);
scenario.environment.debris = zeros(gridSize);

end
