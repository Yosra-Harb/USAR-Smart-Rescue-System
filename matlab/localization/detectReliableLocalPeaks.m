function peaks = detectReliableLocalPeaks( ...
    evidenceMap, ...
    observationCount, ...
    peakThreshold, ...
    minimumObservationCount, ...
    supportMap)
%% ============================================================
% Function Name : detectReliableLocalPeaks
%
% Description :
% استخراج القمم المحلية الموثوقة من خريطة الأدلة باستخدام MATLAB
% الأساسي فقط، ثم تطبيق Non-Maximum Suppression مكاني.
%
% لا تستخدم الدالة Ground Truth ولا عدد الضحايا الحقيقي.
%% ============================================================

peaks = emptyPeakArray();
% نتيجة فارغة آمنة عند عدم وجود قمم صالحة

if nargin < 5 || isempty(supportMap)
    supportMap = observationCount;
    % توافق مع الاستدعاءات القديمة والاختبارات المباشرة.
end

if ~isnumeric(evidenceMap) || ...
        ~isnumeric(observationCount) || ...
        ~isnumeric(supportMap) || ...
        isempty(evidenceMap) || ...
        ~isequal(size(evidenceMap), size(observationCount)) || ...
        ~isequal(size(evidenceMap), size(supportMap))
    return;
end

if ~isscalar(peakThreshold) || ...
        ~isfinite(peakThreshold) || ...
        ~isscalar(minimumObservationCount) || ...
        ~isfinite(minimumObservationCount)
    return;
end

config = constants();
neighborhoodRadius = ...
    max(1, round(config.localization.localMaximumRadius));
minimumProminence = ...
    max(0, config.localization.minimumPeakProminence);
minimumSeparation = ...
    max(0, config.localization.minimumPeakSeparation);
maximumPeakCount = ...
    max(1, round(config.localization.maximumPeaksPerWindow));

numberOfRows = size(evidenceMap, 1);
numberOfColumns = size(evidenceMap, 2);
candidatePeaks = emptyPeakArray();

for rowIndex = 1:numberOfRows
    for columnIndex = 1:numberOfColumns

        peakValue = evidenceMap(rowIndex, columnIndex);

        if ~isfinite(peakValue) || ...
                peakValue < peakThreshold || ...
                observationCount(rowIndex, columnIndex) < ...
                minimumObservationCount
            continue;
        end

        minimumRow = max(1, rowIndex - neighborhoodRadius);
        maximumRow = min(numberOfRows, rowIndex + neighborhoodRadius);
        minimumColumn = max(1, columnIndex - neighborhoodRadius);
        maximumColumn = min(numberOfColumns, columnIndex + neighborhoodRadius);

        neighborhoodEvidence = evidenceMap( ...
            minimumRow:maximumRow, ...
            minimumColumn:maximumColumn);
        neighborhoodReliability = observationCount( ...
            minimumRow:maximumRow, ...
            minimumColumn:maximumColumn) >= ...
            minimumObservationCount;
        neighborhoodSupport = supportMap( ...
            minimumRow:maximumRow, ...
            minimumColumn:maximumColumn);
        % كثافة الدعم الموزون داخل جوار القمة.

        localRow = rowIndex - minimumRow + 1;
        localColumn = columnIndex - minimumColumn + 1;
        neighborMask = neighborhoodReliability & ...
            isfinite(neighborhoodEvidence);
        neighborMask(localRow, localColumn) = false;
        neighborValues = neighborhoodEvidence(neighborMask);

        if isempty(neighborValues)
            prominence = peakValue;
        else
            maximumNeighbor = max(neighborValues);
            evidenceTolerance = max( ...
                1e-12, ...
                eps(max(1, abs(peakValue))));
            prominence = peakValue - median(neighborValues);

            if peakValue < maximumNeighbor - evidenceTolerance
                continue;
            end

            if prominence < minimumProminence
                plateauMask = neighborMask & ...
                    abs(neighborhoodEvidence - peakValue) <= ...
                    evidenceTolerance;
                plateauSupportValues = ...
                    neighborhoodSupport(plateauMask);
                currentSupport = ...
                    supportMap(rowIndex, columnIndex);
                supportTolerance = max( ...
                    1e-12, ...
                    eps(max(1, abs(currentSupport))));

                if isempty(plateauSupportValues) || ...
                        ~isfinite(currentSupport) || ...
                        currentSupport <= ...
                        max(plateauSupportValues) + supportTolerance
                    continue;
                    % في الهضبة المسطحة لا تُقبل إلا الخلية ذات
                    % أعلى دعم موزون بصورة فريدة.
                end
            end
        end

        if prominence < 0
            continue;
        end

        candidatePeaks(end+1,1) = struct( ...
            'row', rowIndex, ...
            'column', columnIndex, ...
            'value', peakValue, ...
            'prominence', prominence, ...
            'selectionScore', 0); %#ok<AGROW>

    end
end

if isempty(candidatePeaks)
    return;
end

[~, peakOrder] = sort([candidatePeaks.value], 'descend');
candidatePeaks = candidatePeaks(peakOrder);

for candidateIndex = 1:numel(candidatePeaks)

    candidatePeak = candidatePeaks(candidateIndex);
    isSeparated = true;

    for selectedIndex = 1:numel(peaks)
        rowDifference = candidatePeak.row - peaks(selectedIndex).row;
        columnDifference = ...
            candidatePeak.column - peaks(selectedIndex).column;
        peakDistance = sqrt( ...
            rowDifference^2 + columnDifference^2);

        if peakDistance < minimumSeparation
            isSeparated = false;
            break;
        end
    end

    if isSeparated
        peaks(end+1,1) = candidatePeak; %#ok<AGROW>
    end

    if numel(peaks) >= maximumPeakCount
        break;
    end

end


function peaks = emptyPeakArray()

peaks = struct( ...
    'row', {}, ...
    'column', {}, ...
    'value', {}, ...
    'prominence', {}, ...
    'selectionScore', {});

end

end
