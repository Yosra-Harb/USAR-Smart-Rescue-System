function decision = decisionEngine( ...
    fusionScore, ...
    vitalityIndex, ...
    localSearchActive)
%% ============================================================
% Function Name : decisionEngine
%% ============================================================

config = constants();

fusionThreshold = ...
    config.suspicion.fusionScore;

vitalityThreshold = ...
    config.suspicion.vitalityIndex;

if fusionScore >= fusionThreshold && ...
        vitalityIndex >= vitalityThreshold

    decision = "SUSPICIOUS";
    return;

end

if localSearchActive

    decision = "LOCAL_SEARCH";
    return;

end

decision = "RESUME_SEARCH";

end
