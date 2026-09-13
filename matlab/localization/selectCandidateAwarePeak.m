function selectedPeak = selectCandidateAwarePeak( ...
    peaks, ...
    candidatePosition)
%% ============================================================
% Function Name : selectCandidateAwarePeak
%
% Description :
% اختيار القمة الأنسب للقياس الحالي اعتمادًا على:
% 1- قوة الدليل عند القمة.
% 2- قرب القمة من موقع القياس الحالي.
%
% تمنع هذه الطريقة جميع القياسات من الانجذاب دائمًا إلى
% أقوى قمة داخل نافذة البحث.
%
% لا تستخدم الدالة Ground Truth أو عدد الضحايا الحقيقي.
%% ============================================================

%% ============================================================
% Default Output
%% ============================================================

selectedPeak = struct([]);
% نتيجة فارغة إذا لم توجد قمة صالحة

%% ============================================================
% Validate Candidate Position
%% ============================================================

if ~isnumeric(candidatePosition) || ...
        numel(candidatePosition) < 2 || ...
        any(~isfinite(candidatePosition(1:2)))

    return;

end

candidatePosition = ...
    candidatePosition(1:2);

%% ============================================================
% Validate Peak Structure
%% ============================================================

if ~isstruct(peaks) || isempty(peaks)

    return;

end

requiredFields = { ...
    'row', ...
    'column', ...
    'value', ...
    'prominence', ...
    'selectionScore'};

for fieldIndex = 1:numel(requiredFields)

    if ~isfield( ...
            peaks, ...
            requiredFields{fieldIndex})

        return;

    end

end

%% ============================================================
% Remove Invalid Peaks
%% ============================================================

validPeakMask = false( ...
    1, ...
    numel(peaks));

for peakIndex = 1:numel(peaks)

    validPeakMask(peakIndex) = ...
        isscalar(peaks(peakIndex).row) && ...
        isfinite(peaks(peakIndex).row) && ...
        isscalar(peaks(peakIndex).column) && ...
        isfinite(peaks(peakIndex).column) && ...
        isscalar(peaks(peakIndex).value) && ...
        isfinite(peaks(peakIndex).value) && ...
        peaks(peakIndex).value >= 0;

end

peaks = peaks(validPeakMask);

if isempty(peaks)

    return;

end

%% ============================================================
% Read and Normalize Selection Weights
%% ============================================================

config = constants();

strengthWeight = max( ...
    0, ...
    config.localization.peakStrengthWeight);

proximityWeight = max( ...
    0, ...
    config.localization.candidateProximityWeight);

weightTotal = ...
    strengthWeight + proximityWeight;

if ~isfinite(weightTotal) || ...
        weightTotal <= eps

    strengthWeight = 0.50;
    proximityWeight = 0.50;

else

    strengthWeight = ...
        strengthWeight / weightTotal;

    proximityWeight = ...
        proximityWeight / weightTotal;

end

distanceScale = ...
    config.localization.candidateDistanceScale;

if ~isfinite(distanceScale) || ...
        distanceScale <= eps

    distanceScale = 1;

end

%% ============================================================
% Normalize Peak Strength
%% ============================================================

peakValues = ...
    [peaks.value];

maximumPeakValue = ...
    max(peakValues);

maximumPeakValue = ...
    max(maximumPeakValue, eps);

selectionScores = zeros( ...
    1, ...
    numel(peaks));

%% ============================================================
% Calculate Candidate-Aware Score
%% ============================================================

for peakIndex = 1:numel(peaks)

    rowDifference = ...
        peaks(peakIndex).row - ...
        candidatePosition(1);

    columnDifference = ...
        peaks(peakIndex).column - ...
        candidatePosition(2);

    peakDistance = sqrt( ...
        rowDifference^2 + ...
        columnDifference^2);

    normalizedStrength = ...
        peaks(peakIndex).value / ...
        maximumPeakValue;

    spatialCompatibility = exp( ...
        -0.5 * ...
        (peakDistance / distanceScale)^2);

    selectionScores(peakIndex) = ...
        strengthWeight * normalizedStrength + ...
        proximityWeight * spatialCompatibility;

end

%% ============================================================
% Select Best Compatible Peak
%% ============================================================

[~, selectedIndex] = ...
    max(selectionScores);

selectedPeak = ...
    peaks(selectedIndex);

selectedPeak.selectionScore = ...
    selectionScores(selectedIndex);

end