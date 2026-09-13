function state = updateBayesianVictimTracks( ...
    state, ...
    peaks, ...
    observationPosition)
%% ============================================================
% ربط قمم posterior بمسارات احتمالية دون استخدام عدد الضحايا الحقيقي.
%% ============================================================

config = constants();
if isfield(state, 'localizationMethod') && ...
        lower(string(state.localizationMethod)) == ...
        "spatialbayesianfusion"
    bayesianConfig = config.spatialBayesian;
else
    bayesianConfig = config.bayesian;
end
peaks = normalizePeakSchema(peaks);
state.tracks = normalizeTrackSchema(state.tracks);

rangedPeakPositions = zeros(0,2);
for peakIndex = 1:numel(peaks)
    if isRangedMeasurementPeak(peaks(peakIndex))
        rangedPeakPositions(end+1,:) = [ ... %#ok<AGROW>
            peaks(peakIndex).row, ...
            peaks(peakIndex).column];
    end
end

numberOfTracks = numel(state.tracks);
numberOfPeaks = numel(peaks);
trackUsed = false(numberOfTracks,1);
peakUsed = false(numberOfPeaks,1);

if numberOfTracks > 0 && numberOfPeaks > 0
    associations = zeros(0,3);

    for trackIndex = 1:numberOfTracks
        for peakIndex = 1:numberOfPeaks
            distance = hypot( ...
                state.tracks(trackIndex).position(1) - ...
                    peaks(peakIndex).row, ...
                state.tracks(trackIndex).position(2) - ...
                    peaks(peakIndex).column);
            if distance <= bayesianConfig.trackAssociationDistance
                associations(end+1,:) = ...
                    [distance, trackIndex, peakIndex]; %#ok<AGROW>
            end
        end
    end

    if ~isempty(associations)
        associations = sortrows(associations, 1);

        for associationIndex = 1:size(associations,1)
            trackIndex = associations(associationIndex,2);
            peakIndex = associations(associationIndex,3);

            if trackUsed(trackIndex) || peakUsed(peakIndex)
                continue;
            end

            state.tracks(trackIndex) = updateOneTrack( ...
                state.tracks(trackIndex), ...
                peaks(peakIndex), ...
                observationPosition, ...
                state.updateCount, ...
                bayesianConfig);
            trackUsed(trackIndex) = true;
            peakUsed(peakIndex) = true;
        end
    end
end

%% ============================================================
% Track-Conditioned Posterior Maintenance
%% ============================================================

% قد تختفي القمة من خرج NMS عندما يصبح الـ posterior عريضًا أو مسطحًا،
% رغم أن القياس الحالي ما زال يدعم مسارًا موجودًا. في Track-Before-Detect
% يجب صيانة المسار من الدليل الخام داخل بوابته، لا من القمم الحادة فقط.
conditionedAssociations = struct( ...
    'trackIndex', {}, ...
    'peak', {}, ...
    'score', {});

for trackIndex = 1:numberOfTracks

    if trackUsed(trackIndex)
        continue;
    end

    if shouldSuppressMapConditioning( ...
            state.tracks(trackIndex).position, ...
            rangedPeakPositions, ...
            bayesianConfig)
        continue;
        % القياس المباشر استُخدم لمسار واحد فقط. لا يجوز للدليل
        % الخريطي المشتق من القياس نفسه أن يصون مسارًا مكررًا مجاورًا.
    end

    [hasSupport, conditionedPeak, supportScore] = ...
        findTrackConditionedSupport( ...
            state, ...
            state.tracks(trackIndex), ...
            bayesianConfig);

    if hasSupport
        conditionedAssociations(end+1,1) = struct( ... %#ok<AGROW>
            'trackIndex', trackIndex, ...
            'peak', conditionedPeak, ...
            'score', supportScore);
    end

end


if ~isempty(conditionedAssociations)

    [~, conditionedOrder] = sort( ...
        [conditionedAssociations.score], 'descend');
    conditionedAssociations = ...
        conditionedAssociations(conditionedOrder);
    usedConditionedPositions = zeros(0,2);

    for associationIndex = 1:numel(conditionedAssociations)

        association = conditionedAssociations(associationIndex);
        trackIndex = association.trackIndex;

        if trackUsed(trackIndex)
            continue;
        end

        conditionedPosition = [ ...
            association.peak.row, ...
            association.peak.column];

        if ~isempty(usedConditionedPositions)
            conditionedDistances = hypot( ...
                usedConditionedPositions(:,1) - ...
                    conditionedPosition(1), ...
                usedConditionedPositions(:,2) - ...
                    conditionedPosition(2));
            if any(conditionedDistances < ...
                    bayesianConfig.minimumPeakSeparation)
                continue;
                % لا يجوز أن يؤكد الدليل المحلي نفسه مسارين متجاورين.
            end
        end

        state.tracks(trackIndex) = updateOneTrack( ...
            state.tracks(trackIndex), ...
            association.peak, ...
            observationPosition, ...
            state.updateCount, ...
            bayesianConfig);
        trackUsed(trackIndex) = true;
        usedConditionedPositions(end+1,:) = ... %#ok<AGROW>
            conditionedPosition;

    end

end

for trackIndex = 1:numberOfTracks
    if ~trackUsed(trackIndex)
        track = state.tracks(trackIndex);
        if isTrackObservableInCurrentUpdate(state, track.position)
            track.existenceProbability = ...
                track.existenceProbability * ...
                bayesianConfig.trackMissedUpdateRetention;
            track.missedUpdateCount = ...
                track.missedUpdateCount + 1;
            % يُعد غياب القمة missed detection فقط عندما يقع المسار
            % فعلًا داخل مجال الرؤية الحالي. ابتعاد المسبار لا يمثل
            % دليلًا سالبًا على اختفاء ضحية ساكنة.
        end
        track.status = classifyTrack(track, bayesianConfig);
        state.tracks(trackIndex) = track;
    end
end


for peakIndex = 1:numberOfPeaks
    if peakUsed(peakIndex)
        continue;
    end

    peak = peaks(peakIndex);
    newTrack = createTrack( ...
        state.nextTrackID, ...
        peak, ...
        observationPosition, ...
        state.updateCount, ...
        bayesianConfig);
    state.tracks(end+1,1) = newTrack;
    state.nextTrackID = state.nextTrackID + 1;
end


if ~isempty(state.tracks)
    keepMask = [state.tracks.existenceProbability] >= ...
        bayesianConfig.trackDeletionProbability;
    state.tracks = state.tracks(keepMask);
end

end


function [hasSupport, peak, supportScore] = ...
    findTrackConditionedSupport(state, track, config)

hasSupport = false;
peak = emptyConditionedPeak();
supportScore = -Inf;

requiredFields = { ...
    'probabilityMap', ...
    'lastMeasurementLogBayesFactorMap', ...
    'lastVisibilityMask', ...
    'lastObservationStep', ...
    'updateCount'};

isSpatialState = ...
    isfield(state, 'localizationMethod') && ...
    lower(string(state.localizationMethod)) == ...
        "spatialbayesianfusion";

if ~isSpatialState || ...
        ~all(isfield(state, requiredFields)) || ...
        ~isTrackObservableInCurrentUpdate(state, track.position)
    return;
end

gateRadius = max(1, ceil(config.trackAssociationDistance));
centerRow = round(track.position(1));
centerColumn = round(track.position(2));
numberOfRows = size(state.probabilityMap, 1);
numberOfColumns = size(state.probabilityMap, 2);

rowRange = max(1, centerRow-gateRadius): ...
    min(numberOfRows, centerRow+gateRadius);
columnRange = max(1, centerColumn-gateRadius): ...
    min(numberOfColumns, centerColumn+gateRadius);
[rowGrid, columnGrid] = ndgrid(rowRange, columnRange);
distanceMap = hypot( ...
    rowGrid - track.position(1), ...
    columnGrid - track.position(2));

localPosterior = state.probabilityMap( ...
    rowRange, columnRange);
localEvidence = state.lastMeasurementLogBayesFactorMap( ...
    rowRange, columnRange);
localVisibility = state.lastVisibilityMask( ...
    rowRange, columnRange);
localObservationStep = state.lastObservationStep( ...
    rowRange, columnRange);

eligibleMask = ...
    distanceMap <= config.trackAssociationDistance & ...
    localVisibility & ...
    localObservationStep == state.updateCount & ...
    isfinite(localPosterior) & ...
    isfinite(localEvidence) & ...
    localPosterior >= config.minimumPosteriorProbability & ...
    localEvidence >= ...
        config.trackConditionedMinimumLogBayesFactor;

if ~any(eligibleMask(:))
    return;
end

% يعطي القياس الحالي الوزن الأكبر، ثم posterior المتراكم، مع عقوبة
% صغيرة للابتعاد عن موضع المسار المتوقع.
localScore = localEvidence + ...
    0.25 .* localPosterior - ...
    0.05 .* distanceMap;
localScore(~eligibleMask) = -Inf;
[supportScore, linearIndex] = max(localScore(:));

if ~isfinite(supportScore)
    return;
end

[localRow, localColumn] = ind2sub( ...
    size(localScore), linearIndex);
selectedRow = rowRange(localRow);
selectedColumn = columnRange(localColumn);
selectedProbability = ...
    state.probabilityMap(selectedRow, selectedColumn);
selectedLogOdds = state.logOddsMap( ...
    selectedRow, selectedColumn);
uncertaintyRadius = max( ...
    0.5, ...
    sqrt(max(eps, trace(track.covariance) / 2)));

peak = struct( ...
    'row', selectedRow, ...
    'column', selectedColumn, ...
    'probability', selectedProbability, ...
    'logOdds', selectedLogOdds, ...
    'prominence', max(0, ...
        state.lastMeasurementLogBayesFactorMap( ...
            selectedRow, selectedColumn)), ...
    'uncertaintyRadius', uncertaintyRadius, ...
    'sourceType', "MAP_CONDITIONED");
hasSupport = true;

end


function peak = emptyConditionedPeak()

peak = struct( ...
    'row', NaN, ...
    'column', NaN, ...
    'probability', NaN, ...
    'logOdds', NaN, ...
    'prominence', NaN, ...
    'uncertaintyRadius', NaN, ...
    'sourceType', "MAP_CONDITIONED");

end


function track = createTrack( ...
    trackID, ...
    peak, ...
    observationPosition, ...
    updateStep, ...
    config)

track = struct();
track.id = trackID;
track.position = [peak.row, peak.column];
track.existenceProbability = peak.probability;
track.covariance = ...
    eye(2) * peak.uncertaintyRadius^2;
track.updateCount = 1;
track.independentViewCount = 1;
track.observationPositions = observationPosition(1:2);
track.maximumProbability = peak.probability;
track.missedUpdateCount = 0;
track.status = classifyTrack(track, config);
track.lastUpdateStep = updateStep;
track.updateStepHistory = updateStep;
if isRangedMeasurementPeak(peak)
    track.rangedMeasurementUpdateCount = 1;
    track.independentRangedViewCount = 1;
    track.rangedObservationPositions = ...
        observationPosition(1:2);
else
    track.rangedMeasurementUpdateCount = 0;
    track.independentRangedViewCount = 0;
    track.rangedObservationPositions = zeros(0,2);
end

end


function track = updateOneTrack( ...
    track, ...
    peak, ...
    observationPosition, ...
    updateStep, ...
    config)

peakPosition = [peak.row, peak.column];
isRangedMeasurement = isRangedMeasurementPeak(peak);

if isRangedMeasurement
    [track.position,track.covariance] = ...
        updateStationaryRangedTrackPosition( ...
            track.position, ...
            track.covariance, ...
            peakPosition, ...
            peak.uncertaintyRadius, ...
            config);
else
    oldWeight = max(eps, track.existenceProbability);
    newWeight = max(eps, peak.probability);
    track.position = ...
        (oldWeight * track.position + ...
         newWeight * peakPosition) / ...
        (oldWeight + newWeight);
end

isIndependentView = isIndependentObservation( ...
    observationPosition, ...
    track.observationPositions, ...
    config.minimumIndependentViewDistance);
isIndependentRangedView = ...
    isRangedMeasurement && ...
    isIndependentObservation( ...
        observationPosition, ...
        track.rangedObservationPositions, ...
        config.minimumIndependentViewDistance);

if isIndependentView
    track.existenceProbability = ...
        1 - (1 - track.existenceProbability) * ...
        (1 - peak.probability);
else
    % القمة نفسها مشتقة من posterior تاريخي؛ لذلك لا يجوز إعادة
    % احتسابها كتجربة مستقلة عند بقاء المسبار في الموضع نفسه.
    track.existenceProbability = max( ...
        track.existenceProbability, peak.probability);
end
track.existenceProbability = max(0, min(1, ...
    track.existenceProbability));
track.maximumProbability = max( ...
    track.maximumProbability, peak.probability);
if ~isRangedMeasurement
    track.covariance = ...
        0.6 * track.covariance + ...
        0.4 * eye(2) * peak.uncertaintyRadius^2;
end
track.updateCount = track.updateCount + 1;
track.missedUpdateCount = 0;
track.lastUpdateStep = updateStep;

if ~isfield(track, 'updateStepHistory') || ...
        isempty(track.updateStepHistory)
    track.updateStepHistory = updateStep;
elseif track.updateStepHistory(end) ~= updateStep
    track.updateStepHistory(end+1,1) = updateStep;
end

if isIndependentView
    track.independentViewCount = ...
        track.independentViewCount + 1;
    track.observationPositions(end+1,:) = ...
        observationPosition(1:2);
end

if isRangedMeasurement
    track.rangedMeasurementUpdateCount = ...
        track.rangedMeasurementUpdateCount + 1;
end

if isIndependentRangedView
    track.independentRangedViewCount = ...
        track.independentRangedViewCount + 1;
    track.rangedObservationPositions(end+1,:) = ...
        observationPosition(1:2);
end

track.status = classifyTrack(track, config);

end


function [position,covariance] = ...
    updateStationaryRangedTrackPosition( ...
        position,covariance,measurementPosition, ...
        uncertaintyRadius,config)

processNoiseVariance = 0;
if isfield(config,'rangedMeasurementTrackProcessNoiseVariance')
    processNoiseVariance = max(0, ...
        config.rangedMeasurementTrackProcessNoiseVariance);
end

if ~isequal(size(covariance),[2 2]) || ...
        any(~isfinite(covariance),'all')
    covariance = eye(2) * uncertaintyRadius^2;
end

predictedCovariance = 0.5*(covariance+covariance') + ...
    processNoiseVariance*eye(2);
measurementCovariance = ...
    max(eps,uncertaintyRadius^2)*eye(2);
innovationCovariance = ...
    predictedCovariance+measurementCovariance;
kalmanGain = predictedCovariance / ...
    innovationCovariance;
innovation = measurementPosition(:)-position(:);
position = (position(:)+kalmanGain*innovation)';
identityMatrix = eye(2);
covariance = ...
    (identityMatrix-kalmanGain)*predictedCovariance* ...
        (identityMatrix-kalmanGain)' + ...
    kalmanGain*measurementCovariance*kalmanGain';
covariance = 0.5*(covariance+covariance');

end


function status = classifyTrack(track, config)

if isfield(track, 'status') && ...
        string(track.status) == "CONFIRMED" && ...
        track.existenceProbability >= ...
        config.trackDeletionProbability
    status = "CONFIRMED";
elseif track.existenceProbability >= ...
        config.confirmationProbability && ...
        track.independentViewCount >= ...
        config.minimumIndependentViews
    status = "CONFIRMED";
else
    status = "PROVISIONAL";
end

end


function isIndependent = isIndependentObservation( ...
    observationPosition, ...
    previousPositions, ...
    minimumDistance)

if isempty(previousPositions)
    isIndependent = true;
    return;
end

differences = previousPositions(:,1:2) - ...
    observationPosition(1:2);
distances = sqrt(sum(differences.^2, 2));
isIndependent = all(distances >= minimumDistance);

end


function tracks = normalizeTrackSchema(tracks)

for index = 1:numel(tracks)
    if ~isfield(tracks, 'observationPositions')
        tracks(index).observationPositions = zeros(0,2);
    end
    if ~isfield(tracks, 'maximumProbability')
        tracks(index).maximumProbability = ...
            tracks(index).existenceProbability;
    end
    if ~isfield(tracks, 'missedUpdateCount')
        tracks(index).missedUpdateCount = 0;
    end
    if ~isfield(tracks, 'updateStepHistory') || ...
            isempty(tracks(index).updateStepHistory)
        if isfield(tracks, 'lastUpdateStep') && ...
                ~isempty(tracks(index).lastUpdateStep)
            tracks(index).updateStepHistory = ...
                tracks(index).lastUpdateStep;
        else
            tracks(index).updateStepHistory = zeros(0,1);
        end
    end
    if ~isfield(tracks, 'rangedMeasurementUpdateCount') || ...
            isempty(tracks(index).rangedMeasurementUpdateCount)
        tracks(index).rangedMeasurementUpdateCount = 0;
    end
    if ~isfield(tracks, 'independentRangedViewCount') || ...
            isempty(tracks(index).independentRangedViewCount)
        tracks(index).independentRangedViewCount = 0;
    end
    if ~isfield(tracks, 'rangedObservationPositions') || ...
            isempty(tracks(index).rangedObservationPositions)
        tracks(index).rangedObservationPositions = zeros(0,2);
    end
end

end


function peaks = normalizePeakSchema(peaks)

if isempty(peaks)
    return;
end

if ~isfield(peaks,'sourceType')
    [peaks.sourceType] = deal("MAP");
else
    for index = 1:numel(peaks)
        peaks(index).sourceType = ...
            string(peaks(index).sourceType);
    end
end

end


function isRanged = isRangedMeasurementPeak(peak)

isRanged = isfield(peak,'sourceType') && ...
    string(peak.sourceType) == "RANGED_MEASUREMENT";

end


function suppress = shouldSuppressMapConditioning( ...
    trackPosition,rangedPeakPositions,config)

suppress = false;

if isempty(rangedPeakPositions) || ...
        ~isfield(config,'rangedMeasurementMapSuppressionDistance')
    return;
end

distances = hypot( ...
    rangedPeakPositions(:,1)-trackPosition(1), ...
    rangedPeakPositions(:,2)-trackPosition(2));
suppress = any(distances < ...
    config.rangedMeasurementMapSuppressionDistance);

end


function isObservable = isTrackObservableInCurrentUpdate( ...
    state, trackPosition)

isSpatialState = ...
    isfield(state, 'localizationMethod') && ...
    lower(string(state.localizationMethod)) == ...
        "spatialbayesianfusion";

if ~isSpatialState || ...
        ~isfield(state, 'lastVisibilityMask') || ...
        isempty(state.lastVisibilityMask)
    isObservable = true;
    % يحافظ مسار v3 والاختبارات القديمة على سلوك missed update السابق.
    return;
end

row = round(trackPosition(1));
column = round(trackPosition(2));
isInsideMap = ...
    row >= 1 && row <= size(state.lastVisibilityMask,1) && ...
    column >= 1 && column <= size(state.lastVisibilityMask,2);

if ~isInsideMap
    isObservable = false;
    return;
end

isObservable = logical(state.lastVisibilityMask(row,column));

end
