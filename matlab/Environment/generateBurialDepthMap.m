function burialDepthMap = ...
    generateBurialDepthMap(scenario)
%% ============================================================
% Function Name : generateBurialDepthMap
%
% Description :
% توليد خريطة عمق الدفن داخل البيئة.
%% ============================================================

burialDepthMap = ...
    scenario.burialDepth .* ...
    ones(scenario.gridSize);

burialDepthMap = ...
    burialDepthMap + ...
    0.1 .* rand(scenario.gridSize);

burialDepthMap = ...
    max(0,min(1,burialDepthMap));

end