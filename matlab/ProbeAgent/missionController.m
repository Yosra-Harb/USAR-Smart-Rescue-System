function probe = missionController(scenario, probe)
%% ============================================================
% Function Name : missionController
%
% Description :
% تنفيذ دورة تشغيل كاملة للمسبار:
%
% MOVING
%    ↓
% SENSOR ACQUISITION
%    ↓
% SIGNAL PROCESSING
%    ↓
% ADAPTIVE FUSION
%    ↓
% LOCALIZATION
%    ↓
% VITALITY ASSESSMENT
%    ↓
% PRIORITY RANKING
%    ↓
% DECISION
%    ↓
% STATE UPDATE
%% ============================================================

%% ============================================================
% Movement Layer
%% ============================================================

probe.state = "MOVING";

probe = moveProbe(probe);

if probe.finished

    probe.state = "MISSION_COMPLETE";

    return;

end

%% ============================================================
% Sensor Acquisition Layer
%% ============================================================

probe.state = "SENSING";

measurementPacket = requestSensorData( ...
    scenario, ...
    probe);

%% ============================================================
% Signal Processing Layer
%% ============================================================

probe.state = "PROCESSING";

processedPacket = signalProcessingManager( ...
    measurementPacket);

%% ============================================================
% Adaptive Fusion Layer
%% ============================================================

probe.state = "FUSION";

fusionPacket = fusionManager( ...
    processedPacket);

%% ============================================================
% Localization Layer
%% ============================================================

probe.state = "LOCALIZATION";

config = constants();
localizationMethod = lower(string( ...
    config.localization.method));

switch localizationMethod
    case "spatialbayesianfusion"
        [localizationPacket, ...
            probe.memory.bayesianLocalizationState] = ...
            spatialBayesianLocalizationManager( ...
                scenario, ...
                processedPacket, ...
                fusionPacket, ...
                probe.memory.bayesianLocalizationState);

    case "bayesiantbd"
        [localizationPacket, ...
            probe.memory.bayesianLocalizationState] = ...
            bayesianLocalizationManager( ...
                scenario, ...
                processedPacket, ...
                fusionPacket, ...
                probe.memory.bayesianLocalizationState);

    case "adaptiveevidence"
        probe = updateEvidenceMap( ...
            probe, ...
            fusionPacket);
        [localizationPacket, probe.memory.localizationState] = ...
            localizationManager( ...
                fusionPacket, ...
                probe.memory.localizationState);

    otherwise
        error( ...
            "missionController:UnknownLocalizationMethod", ...
            "Unsupported localization method: %s", ...
            localizationMethod);
end

probe.memory.localizationMethod = ...
    string(config.localization.method);

%% ============================================================
% Vitality Layer
%% ============================================================

probe.state = "VITALITY";

vitalityPacket = vitalityManager( ...
    localizationPacket, ...
    fusionPacket, ...
    probe);

%% ============================================================
% Debug Information
%% ============================================================

logger( ...
    "DEBUG", ...
    "Fusion=%.4f, vitality=%.4f", ...
    vitalityPacket.fusionScore, ...
    vitalityPacket.vitalityIndex);

%% ============================================================
% Priority Ranking Layer
%% ============================================================

probe.state = "PRIORITY";

priorityPacket = ...
    priorityRankingManager( ...
        scenario, ...
        vitalityPacket);

logger( ...
    "DEBUG", ...
    "Priority=%.4f, level=%s", ...
    priorityPacket.priorityScore, ...
    char(priorityPacket.priorityLevel));

%% ============================================================
% Decision Layer
%% ============================================================

probe.state = "DECISION";

decision = probeDecisionEngine( ...
    vitalityPacket, ...
    probe);

probe.state = probeStateMachine( ...
    probe.state, ...
    decision);

%% ============================================================
% Save Runtime Information
%% ============================================================

probe.lastSensorData = ...
    measurementPacket;

probe.lastProcessedData = ...
    processedPacket;

probe.lastFusionData = ...
    fusionPacket;

probe.lastLocalizationData = ...
    localizationPacket;

probe.lastVitalityData = ...
    vitalityPacket;

probe.lastPriorityData = ...
    priorityPacket;
%% ============================================================
% Update Victim Database
%% ============================================================

probe = ...
    updateVictimDatabase( ...
    probe, ...
    vitalityPacket, ...
    priorityPacket);

probe = registerAdditionalRangedCandidates( ...
    scenario, ...
    probe, ...
    localizationPacket, ...
    fusionPacket);
% قد يحتوي تحديث UWB واحد على أكثر من مصدر. يعالج المسار التشغيلي
% الرئيسي مرشحًا واحدًا لاتخاذ قرار الحركة، لكن قاعدة الضحايا يجب أن
% تستقبل كل فرضية مدى موثوقة في التحديث نفسه. لا تُضاف قمم الخريطة
% الإضافية هنا حتى لا تتحول شظايا السطح إلى سجلات زائفة.

probe.memory.detectedVictims = ...
    rankVictims( ...
    probe.memory.detectedVictims);

probe.lastDecision = ...
    decision;

%% ============================================================
% Update Memory
%% ============================================================

probe.memory.positionHistory = [ ...
    probe.memory.positionHistory;
    probe.position];

probe.memory.sensorHistory = [ ...
    probe.memory.sensorHistory;
    measurementPacket.quality];

probe.memory.stateHistory = [ ...
    probe.memory.stateHistory;
    {char(probe.state)}];

probe.memory.decisionHistory = [ ...
    probe.memory.decisionHistory;
    {char(decision)}];

probe.memory.fusionHistory = [ ...
    probe.memory.fusionHistory;
    fusionPacket.fusionScore];

probe.memory.vitalityHistory = [ ...
    probe.memory.vitalityHistory;
    vitalityPacket.vitalityIndex];

probe.memory.priorityHistory = [ ...
    probe.memory.priorityHistory;
    priorityPacket.priorityScore];

if vitalityPacket.isVictimDetected

    probe.memory.suspiciousLocations = [ ...
        probe.memory.suspiciousLocations;
        vitalityPacket.estimatedPosition];

end

%% ============================================================
% Adaptive Local Search
%% ============================================================

probe = adaptiveSearch( ...
    scenario, ...
    probe, ...
    vitalityPacket);

end


function probe = registerAdditionalRangedCandidates( ...
    scenario,probe,localizationPacket,fusionPacket)

requiredFields = { ...
    'candidatePositions', ...
    'candidateConfidences', ...
    'candidateSourceTypes'};

if ~all(isfield(localizationPacket,requiredFields)) || ...
        isempty(localizationPacket.candidatePositions)
    return;
end

candidatePositions = ...
    localizationPacket.candidatePositions;
candidateConfidences = ...
    localizationPacket.candidateConfidences;
candidateSourceTypes = string( ...
    localizationPacket.candidateSourceTypes);
primaryPosition = localizationPacket.estimatedPosition;

for candidateIndex = 1:size(candidatePositions,1)
    candidatePosition = ...
        candidatePositions(candidateIndex,1:2);

    if candidateIndex > numel(candidateSourceTypes) || ...
            candidateSourceTypes(candidateIndex) ~= ...
            "RANGED_MEASUREMENT" || ...
            any(~isfinite(candidatePosition))
        continue;
    end

    if numel(primaryPosition) >= 2 && ...
            norm(candidatePosition-primaryPosition(1:2)) < 1e-9
        continue;
    end

    candidateLocalizationPacket = localizationPacket;
    candidateLocalizationPacket.isVictimDetected = true;
    candidateLocalizationPacket.estimatedPosition = ...
        candidatePosition;
    candidateLocalizationPacket.sourceType = ...
        "RANGED_MEASUREMENT";

    if candidateIndex <= numel(candidateConfidences) && ...
            isfinite(candidateConfidences(candidateIndex))
        candidateLocalizationPacket.localizationConfidence = ...
            candidateConfidences(candidateIndex);
        candidateLocalizationPacket.posteriorProbability = ...
            candidateConfidences(candidateIndex);
    end

    candidateVitalityPacket = vitalityManager( ...
        candidateLocalizationPacket,fusionPacket,probe);
    candidatePriorityPacket = priorityRankingManager( ...
        scenario,candidateVitalityPacket);
    probe = updateVictimDatabase( ...
        probe,candidateVitalityPacket, ...
        candidatePriorityPacket);
end

end
