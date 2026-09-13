function state = initializeSpatialBayesianLocalizationState( ...
    gridSize, priorProbability)
%% ============================================================
% تهيئة الحالة المكانية مع الحفاظ على schema مسارات v3.
%% ============================================================

if nargin < 2
    priorProbability = [];
end

state = initializeBayesianLocalizationState( ...
    gridSize, priorProbability);
state.localizationMethod = "spatialBayesianFusion";
state.lastMeasurementLogBayesFactorMap = ...
    zeros(gridSize(1), gridSize(2));
state.lastVisibilityMask = false(gridSize(1), gridSize(2));
state.lastSpatialDiagnostics = struct();
state.lastMapPeaks = emptyMeasurementResolvedPeakArray();
state.lastRangedMeasurementPeaks = ...
    emptyMeasurementResolvedPeakArray();
state.lastRangedMeasurementDiagnostics = struct();

end


function peaks = emptyMeasurementResolvedPeakArray()

peaks = struct( ...
    'row', {}, ...
    'column', {}, ...
    'probability', {}, ...
    'logOdds', {}, ...
    'prominence', {}, ...
    'uncertaintyRadius', {}, ...
    'sourceType', {});

end
