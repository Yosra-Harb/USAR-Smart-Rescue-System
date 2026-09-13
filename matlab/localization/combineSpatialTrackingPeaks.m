function peaks = combineSpatialTrackingPeaks( ...
    mapPeaks, rangedMeasurementPeaks)
%% ============================================================
% جمع فرضيات القياس المباشر مع قمم الخريطة دون عد المصدر مرتين.
%% ============================================================

config = constants();
spatialConfig = config.spatialBayesian;
mapPeaks = normalizePeakArray(mapPeaks,"MAP");
rangedMeasurementPeaks = normalizePeakArray( ...
    rangedMeasurementPeaks,"RANGED_MEASUREMENT");
peaks = rangedMeasurementPeaks;

for mapIndex = 1:numel(mapPeaks)
    mapPeak = mapPeaks(mapIndex);

    if ~isempty(rangedMeasurementPeaks)
        rangedDistances = hypot( ...
            [rangedMeasurementPeaks.row]' - mapPeak.row, ...
            [rangedMeasurementPeaks.column]' - mapPeak.column);
        if any(rangedDistances < ...
                spatialConfig.rangedMeasurementMapSuppressionDistance)
            continue;
        end
    end

    peaks(end+1,1) = mapPeak; %#ok<AGROW>

    if numel(peaks) >= ...
            spatialConfig.maximumPeaksPerUpdate
        break;
    end
end

if numel(peaks) > spatialConfig.maximumPeaksPerUpdate
    peaks = peaks(1:spatialConfig.maximumPeaksPerUpdate);
end

end


function peaks = normalizePeakArray(peaks,defaultSourceType)

if isempty(peaks)
    peaks = emptyPeakArray();
    return;
end

if ~isfield(peaks,'sourceType')
    [peaks.sourceType] = deal(string(defaultSourceType));
else
    for index = 1:numel(peaks)
        if strlength(string(peaks(index).sourceType)) == 0
            peaks(index).sourceType = string(defaultSourceType);
        else
            peaks(index).sourceType = ...
                string(peaks(index).sourceType);
        end
    end
end

end


function peaks = emptyPeakArray()

peaks = struct( ...
    'row', {}, ...
    'column', {}, ...
    'probability', {}, ...
    'logOdds', {}, ...
    'prominence', {}, ...
    'uncertaintyRadius', {}, ...
    'sourceType', {});

end
