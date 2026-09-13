function estimatedLocation = ...
    estimateVictimLocation(cluster)

estimatedLocation = struct();

estimatedLocation.isDetected = false;

estimatedLocation.position = [];

estimatedLocation.confidence = ...
    cluster.confidence;

if ~cluster.hasVictim
    return;
end

estimatedLocation.isDetected = true;

centroid = ...
    round(mean(cluster.points,1));

estimatedLocation.position = ...
    centroid;

end