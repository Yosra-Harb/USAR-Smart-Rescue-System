function [cluster, localizationState] = ...
    victimClustering(candidate, localizationState)

config = constants();

if nargin < 2 || ...
        ~isstruct(localizationState) || ...
        ~isfield(localizationState, 'pointHistory')

    localizationState = struct( ...
        'pointHistory', zeros(0,2));

end

cluster = struct();

cluster.hasVictim = false;
cluster.points = [];
cluster.score = candidate.score;
cluster.confidence = candidate.confidence;

if ~candidate.isVictim
    return;
end

localizationState.pointHistory = ...
    [localizationState.pointHistory;
    candidate.position];

maxHistory = ...
    config.clustering.maximumHistory;

if size(localizationState.pointHistory,1) > maxHistory

    localizationState.pointHistory = ...
        localizationState.pointHistory( ...
        end-maxHistory+1:end,:);

end

distanceThreshold = ...
    config.clustering.distanceThreshold;

currentPoint = candidate.position;

distances = sqrt( ...
    (localizationState.pointHistory(:,1)-currentPoint(1)).^2 + ...
    (localizationState.pointHistory(:,2)-currentPoint(2)).^2);

clusterPoints = ...
    localizationState.pointHistory( ...
    distances <= distanceThreshold , :);

if size(clusterPoints,1) >= ...
        config.clustering.minimumPoints

    cluster.hasVictim = true;

   cluster.points = clusterPoints;

if size(cluster.points,1) > ...
        config.clustering.maximumClusterPoints

    cluster.points = ...
        cluster.points( ...
        end-config.clustering.maximumClusterPoints+1:end,:);

end
end

end
