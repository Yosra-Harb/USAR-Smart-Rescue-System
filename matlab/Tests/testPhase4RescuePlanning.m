function tests = testPhase4RescuePlanning
%% اختبارات المسار الأقصر والمسار الآمن وترتيب الإنقاذ.

tests = functiontests(localfunctions);

end


function testRoutesAvoidObstacles(testCase)

scenario = routeScenario();
shortest = planRescueRoute(scenario,[12 1],[2 11],"shortest");
recommended = planRescueRoute( ...
    scenario,[12 1],[2 11],"recommended");

verifyTrue(testCase,shortest.reachable);
verifyTrue(testCase,recommended.reachable);
verifyFalse(testCase,any(pathTouchesObstacle( ...
    shortest.path,scenario.environment.obstacles)));
verifyFalse(testCase,any(pathTouchesObstacle( ...
    recommended.path,scenario.environment.obstacles)));

end


function testRecommendedRouteTradesDistanceForSafety(testCase)

scenario = routeScenario();
shortest = planRescueRoute(scenario,[12 1],[2 11],"shortest");
recommended = planRescueRoute( ...
    scenario,[12 1],[2 11],"recommended");

verifyLessThanOrEqual(testCase, ...
    recommended.meanRisk,shortest.meanRisk+1e-12);

end


function testCriticalReachableVictimRanksFirst(testCase)

scenario = routeScenario();
victims = [buildVictim(1,[4 4],0.15); ...
    buildVictim(2,[4 9],0.75)];
[ranked,rescuePlan] = planRescueOperations( ...
    scenario,victims,[12 1]);

verifyEqual(testCase,ranked(1).id,1);
verifyEqual(testCase,rescuePlan(1).victimID,1);
verifyGreaterThan(testCase, ...
    ranked(1).rescuePriorityScore, ...
    ranked(2).rescuePriorityScore);

end


function victim = buildVictim(id,position,vitality)

victim = struct( ...
    'id',id,'position',position,'vitalityIndex',vitality, ...
    'priorityScore',0,'priorityLevel',"LOW");

end


function mask = pathTouchesObstacle(path,obstacles)

indices = sub2ind(size(obstacles),path(:,1),path(:,2));
mask = obstacles(indices);

end


function scenario = routeScenario()

gridSize = [12 12];
obstacles = false(gridSize);
obstacles(3:10,6) = true;
obstacles(7,6) = false;
risk = zeros(gridSize);
risk(7,2:10) = 0.95;
accessibility = ones(gridSize);
accessibility(7,2:10) = 0.2;
scenario = struct();
scenario.gridSize = gridSize;
scenario.environment = struct( ...
    'obstacles',obstacles,'debris',zeros(gridSize), ...
    'risk',risk,'accessibility',accessibility, ...
    'movementCost',ones(gridSize),'entryPoint',[12 1]);

end
