function localPath = generateLocalSearchPath( ...
    scenario, ...
    probe, ...
    suspicionCenter, ...
    fusionScore, ...
    vitalityIndex)
%% ============================================================
% Function Name : generateLocalSearchPath
%
% Description :
% توليد مسار بحث محلي ذكي حول منطقة الاشتباه.
% يتم حساب Utility لكل خلية ثم اختيار أفضل
% ثلاث خلايا وتوليد مسار A* لكل منها.
%% ============================================================

localPath = [];

radius = probe.localSearch.radius;

gridRows = scenario.gridSize(1);
gridCols = scenario.gridSize(2);

suspicionCenter = normalizeGridPosition( ...
    suspicionCenter,[gridRows gridCols]);
probe.position = normalizeGridPosition( ...
    probe.position,[gridRows gridCols]);

maxCandidates = (2*radius + 1)^2;

candidateCells = zeros(maxCandidates,2);

candidateUtilities = zeros(maxCandidates,1);

candidateCount = 0;

for r = max(1, suspicionCenter(1)-radius) : ...
         min(gridRows, suspicionCenter(1)+radius)

    for c = max(1, suspicionCenter(2)-radius) : ...
             min(gridCols, suspicionCenter(2)+radius)

        if scenario.environment.obstacles(r,c) == 1
            continue;
        end

        utility = explorationUtility( ...
            scenario, ...
            probe.position, ...
            [r c], ...
            suspicionCenter, ...
            fusionScore, ...
            vitalityIndex);

        candidateCount = candidateCount + 1;

        candidateCells(candidateCount,:) = [r c];

        candidateUtilities(candidateCount) = utility;

    end

end

candidateCells = ...
    candidateCells(1:candidateCount,:);

candidateUtilities = ...
    candidateUtilities(1:candidateCount);

if isempty(candidateUtilities)
    return;
end

[~, sortedIndex] = ...
    sort(candidateUtilities,'descend');

topK = min(3,length(sortedIndex));

selectedCells = ...
    candidateCells(sortedIndex(1:topK),:);

currentPosition = probe.position;

pathSegments = cell(topK,1);

segmentCount = 0;

for k = 1:size(selectedCells,1)

    target = selectedCells(k,:);

    partialPath = aStarPathPlanner( ...
        scenario, ...
        currentPosition, ...
        target);

    if isempty(partialPath)
        continue;
    end

    segmentCount = segmentCount + 1;

    if segmentCount == 1
        pathSegments{segmentCount} = partialPath;
    else
        pathSegments{segmentCount} = ...
            partialPath(2:end,:);
    end

    currentPosition = target;

end

if segmentCount == 0
    return;
end

localPath = vertcat( ...
    pathSegments{1:segmentCount});

end
