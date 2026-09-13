function [localizationPacket, state] = ...
    bayesianLocalizationManager( ...
        scenario, ...
        processedPacket, ...
        fusionPacket, ...
        state)
%% ============================================================
% مدير Bayesian Track-Before-Detect للتحديث والكشف والتتبع.
%% ============================================================

[state, ~] = updateBayesianTBDMap( ...
    state, ...
    scenario, ...
    processedPacket);

[peaks, state] = detectBayesianPosteriorPeaks(state);

state = updateBayesianVictimTracks( ...
    state, ...
    peaks, ...
    processedPacket.probePosition);

estimatedLocation = buildEstimatedLocation( ...
    peaks, ...
    processedPacket.probePosition);

candidate = struct();
candidate.isVictim = estimatedLocation.isDetected;
candidate.position = processedPacket.probePosition;
candidate.score = fusionPacket.fusionScore;
candidate.confidence = fusionPacket.confidence;

localizationPacket = buildLocalizationPacket( ...
    fusionPacket, ...
    candidate, ...
    estimatedLocation);
localizationPacket.localizationMethod = "bayesianTBD";
localizationPacket.posteriorProbability = ...
    estimatedLocation.confidence;

end


function estimatedLocation = buildEstimatedLocation( ...
    peaks, ...
    probePosition)

estimatedLocation = struct();
estimatedLocation.isDetected = false;
estimatedLocation.position = [];
estimatedLocation.confidence = 0;
estimatedLocation.peakValue = 0;
estimatedLocation.supportingCells = 0;
estimatedLocation.candidatePeakCount = numel(peaks);
estimatedLocation.selectionScore = 0;

if isempty(peaks)
    return;
end

probabilities = [peaks.probability];
distances = zeros(1,numel(peaks));

for index = 1:numel(peaks)
    distances(index) = hypot( ...
        peaks(index).row - probePosition(1), ...
        peaks(index).column - probePosition(2));
end

distanceScale = max(1, median(distances) + 1);
selectionScores = ...
    0.75 * probabilities + ...
    0.25 * exp(-distances / distanceScale);
[selectionScore, selectedIndex] = max(selectionScores);
selectedPeak = peaks(selectedIndex);

estimatedLocation.isDetected = true;
estimatedLocation.position = ...
    [selectedPeak.row, selectedPeak.column];
estimatedLocation.confidence = selectedPeak.probability;
estimatedLocation.peakValue = selectedPeak.probability;
estimatedLocation.supportingCells = 1;
estimatedLocation.selectionScore = selectionScore;

end
