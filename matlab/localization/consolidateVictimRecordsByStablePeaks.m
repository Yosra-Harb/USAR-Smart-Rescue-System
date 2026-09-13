function [ ...
    consolidatedVictims, ...
    stablePeaks, ...
    report] = ...
    consolidateVictimRecordsByStablePeaks( ...
        victims, ...
        localizationState)
%% ============================================================
% Function Name :
% consolidateVictimRecordsByStablePeaks
%
% Description :
% تجميع سجلات الضحايا المؤقتة حول القمم المستقرة في خريطة
% الأدلة النهائية.
%
% لا تستخدم الدالة Ground Truth أو عدد الضحايا الحقيقي.
%
% قواعد العمل:
% 1- استخراج القمم المستقرة من خريطة الأدلة النهائية.
% 2- إسناد كل سجل إلى أقرب قمة ضمن نافذة التوطين الأصلية.
% 3- دمج السجلات المسندة إلى القمة نفسها.
% 4- إزالة التكرار من مواقع المشاهدات المستقلة.
% 5- الاحتفاظ بالسجلات غير المدعومة دون حذفها.
%% ============================================================

%% ============================================================
% Default Outputs
%% ============================================================

consolidatedVictims = victims;

stablePeaks = struct( ...
    'row', {}, ...
    'column', {}, ...
    'value', {}, ...
    'prominence', {}, ...
    'selectionScore', {});

report = struct();

report.inputRecordCount = ...
    numel(victims);

report.stablePeakCount = 0;

report.matchedRecordCount = 0;

report.unmatchedRecordCount = ...
    numel(victims);

report.consolidatedRecordCount = ...
    numel(victims);

report.recordToPeakIndex = ...
    zeros(numel(victims),1);

report.assignmentDistances = ...
    inf(numel(victims),1);

%% ============================================================
% Validate Inputs
%% ============================================================

if isempty(victims)

    return;

end

if ~isstruct(victims) || ...
        ~isstruct(localizationState)

    return;

end

requiredStateFields = { ...
    'evidenceMap', ...
    'observationCount'};

for fieldIndex = 1:numel(requiredStateFields)

    if ~isfield( ...
            localizationState, ...
            requiredStateFields{fieldIndex})

        return;

    end

end

evidenceMap = ...
    localizationState.evidenceMap;

observationCount = ...
    localizationState.observationCount;

if isempty(evidenceMap) || ...
        ~isequal( ...
            size(evidenceMap), ...
            size(observationCount))

    return;

end

%% ============================================================
% Resolve Weighted Support Map
%% ============================================================

if isfield( ...
        localizationState, ...
        'weightSum') && ...
        isequal( ...
            size(localizationState.weightSum), ...
            size(evidenceMap))

    supportMap = ...
        localizationState.weightSum;

else

    supportMap = ...
        observationCount;
    % توافق مع حالات التوطين القديمة

end

%% ============================================================
% Detect Final Stable Peaks
%% ============================================================

config = constants();

stablePeaks = detectReliableLocalPeaks( ...
    evidenceMap, ...
    observationCount, ...
    config.detection.fusionScore, ...
    config.clustering.minimumPoints, ...
    supportMap);

report.stablePeakCount = ...
    numel(stablePeaks);

if isempty(stablePeaks)

    return;
    % عدم حذف أو دمج أي سجل إذا لم توجد قمم مستقرة

end

peakPositions = [ ...
    [stablePeaks.row]', ...
    [stablePeaks.column]'];

%% ============================================================
% Assign Records to Nearest Stable Peak
%% ============================================================

maximumAssignmentDistance = ...
    config.clustering.distanceThreshold;
% استخدام نصف قطر نافذة التوطين الأصلية، وليس عتبة جديدة

recordToPeakIndex = ...
    zeros(numel(victims),1);

assignmentDistances = ...
    inf(numel(victims),1);

for victimIndex = 1:numel(victims)

    if ~isfield(victims, 'position') || ...
            ~isValidPosition( ...
                victims(victimIndex).position)

        continue;

    end

    victimPosition = ...
        victims(victimIndex).position(1:2);

    positionDifferences = ...
        peakPositions - victimPosition;

    distances = sqrt( ...
        sum(positionDifferences.^2, 2));

    [nearestDistance, nearestPeakIndex] = ...
        min(distances);

    if isfinite(nearestDistance) && ...
            nearestDistance <= ...
            maximumAssignmentDistance

        recordToPeakIndex(victimIndex) = ...
            nearestPeakIndex;

        assignmentDistances(victimIndex) = ...
            nearestDistance;

    end

end

report.recordToPeakIndex = ...
    recordToPeakIndex;

report.assignmentDistances = ...
    assignmentDistances;

report.matchedRecordCount = ...
    nnz(recordToPeakIndex > 0);

report.unmatchedRecordCount = ...
    nnz(recordToPeakIndex == 0);

%% ============================================================
% Consolidate Records Assigned to Each Peak
%% ============================================================

consolidatedVictims = ...
    repmat(victims(1), 0, 1);

for peakIndex = 1:numel(stablePeaks)

    assignedIndices = find( ...
        recordToPeakIndex == peakIndex);

    if isempty(assignedIndices)

        continue;
        % لا ننشئ ضحية من القمة وحدها دون سجل مؤكد

    end

    assignedRecords = ...
        victims(assignedIndices);

    stablePeakPosition = [ ...
        stablePeaks(peakIndex).row, ...
        stablePeaks(peakIndex).column];

    mergedRecord = mergeRecordsAtPeak( ...
        assignedRecords, ...
        stablePeakPosition, ...
        config);

    consolidatedVictims(end+1,1) = ...
        mergedRecord; %#ok<AGROW>

end

%% ============================================================
% Preserve Unmatched Records
%% ============================================================

unmatchedIndices = find( ...
    recordToPeakIndex == 0);

for unmatchedIndex = ...
        reshape(unmatchedIndices,1,[])

    consolidatedVictims(end+1,1) = ...
        victims(unmatchedIndex); %#ok<AGROW>

end

report.consolidatedRecordCount = ...
    numel(consolidatedVictims);

end


function mergedRecord = mergeRecordsAtPeak( ...
    records, ...
    stablePeakPosition, ...
    config)
%% دمج جميع السجلات التي تدعم القمة المستقرة نفسها

recordCount = ...
    numel(records);

independentCounts = ...
    zeros(recordCount,1);

for recordIndex = 1:recordCount

    independentCounts(recordIndex) = ...
        readIndependentCount( ...
            records(recordIndex));

end

%% Select Oldest Record as Base

recordIDs = ...
    [records.id];

[~, baseIndex] = ...
    min(recordIDs);

mergedRecord = ...
    records(baseIndex);

mergedRecord.id = ...
    min(recordIDs);

mergedRecord.position = ...
    round(stablePeakPosition);
% الموقع النهائي يأتي من القمة المستقرة

%% Merge Vitality Conservatively

vitalityValues = ...
    [records.vitalityIndex]';

validVitalityMask = ...
    isfinite(vitalityValues);

vitalityWeights = ...
    independentCounts;

vitalityWeights( ...
    ~validVitalityMask) = 0;

if sum(vitalityWeights) > eps

    mergedRecord.vitalityIndex = ...
        sum( ...
            vitalityValues(validVitalityMask) .* ...
            vitalityWeights(validVitalityMask)) / ...
        sum(vitalityWeights(validVitalityMask));

elseif any(validVitalityMask)

    mergedRecord.vitalityIndex = ...
        mean( ...
            vitalityValues(validVitalityMask));

end

%% Preserve Highest Rescue Priority

priorityScores = ...
    [records.priorityScore];

validPriorityScores = ...
    priorityScores(isfinite(priorityScores));

if ~isempty(validPriorityScores)

    mergedRecord.priorityScore = ...
        max(validPriorityScores);

    mergedRecord.priorityLevel = ...
        classifyPriority( ...
            mergedRecord.priorityScore);

end

%% Merge Observation Histories Without Double Counting

allObservationPositions = ...
    zeros(0,2);

if isfield(records, 'observationPositions')

    for recordIndex = 1:recordCount

        currentPositions = ...
            records(recordIndex).observationPositions;

        if isnumeric(currentPositions) && ...
                size(currentPositions,2) >= 2

            allObservationPositions = [ ...
                allObservationPositions;
                currentPositions(:,1:2)]; %#ok<AGROW>

        end

    end

end

mergedObservationPositions = ...
    mergeIndependentPositions( ...
        allObservationPositions, ...
        config.victimDatabase. ...
        minimumIndependentViewDistance);

if ~isempty(mergedObservationPositions)

    mergedRecord.observationPositions = ...
        mergedObservationPositions;

    mergedRecord.independentViewCount = ...
        size(mergedObservationPositions,1);

else

    mergedRecord.independentViewCount = ...
        max(independentCounts);
    % مسار محافظ للسجلات القديمة التي لا تحفظ تاريخ المواقع

end

mergedRecord.detectionCount = ...
    mergedRecord.independentViewCount;

%% Merge Raw Diagnostic Count

if isfield(records, 'rawAssociationCount')

    rawCounts = ...
        [records.rawAssociationCount];

    rawCounts( ...
        ~isfinite(rawCounts)) = 0;

    mergedRecord.rawAssociationCount = ...
        sum(rawCounts);

end

%% Preserve Detection Times

if isfield(records, 'firstDetectionTime')

    mergedRecord.firstDetectionTime = ...
        min( ...
            [records.firstDetectionTime]);

end

if isfield(records, 'lastUpdateTime')

    [mergedRecord.lastUpdateTime, latestIndex] = ...
        max( ...
            [records.lastUpdateTime]);

    if isfield(records, 'lastObservationPosition')

        mergedRecord.lastObservationPosition = ...
            records(latestIndex). ...
            lastObservationPosition;

    end

end

end


function count = readIndependentCount(record)
%% قراءة عدد المشاهدات المستقلة مع توافق الإصدارات القديمة

if isfield(record, 'independentViewCount') && ...
        ~isempty(record.independentViewCount) && ...
        isfinite(record.independentViewCount)

    count = max( ...
        0, ...
        record.independentViewCount);

elseif isfield(record, 'detectionCount') && ...
        ~isempty(record.detectionCount) && ...
        isfinite(record.detectionCount)

    count = max( ...
        0, ...
        record.detectionCount);

else

    count = 0;

end

end


function mergedPositions = mergeIndependentPositions( ...
    positions, ...
    minimumDistance)
%% إزالة مواقع الرصد المتداخلة مكانيًا

mergedPositions = ...
    zeros(0,2);

if isempty(positions)

    return;

end

validPositionMask = ...
    all(isfinite(positions(:,1:2)),2);

positions = ...
    positions(validPositionMask,1:2);

positions = ...
    sortrows(positions, [1 2]);
% ترتيب ثابت يجعل نتيجة الدمج قابلة لإعادة الإنتاج

for positionIndex = 1:size(positions,1)

    candidatePosition = ...
        positions(positionIndex,:);

    if isempty(mergedPositions)

        mergedPositions(end+1,:) = ...
            candidatePosition; %#ok<AGROW>

        continue;

    end

    positionDifferences = ...
        mergedPositions - candidatePosition;

    distances = sqrt( ...
        sum(positionDifferences.^2,2));

    if all(distances >= minimumDistance)

        mergedPositions(end+1,:) = ...
            candidatePosition; %#ok<AGROW>

    end

end

end


function isValid = isValidPosition(position)
%% التحقق من صلاحية الإحداثيات

isValid = ...
    isnumeric(position) && ...
    numel(position) >= 2 && ...
    all(isfinite(position(1:2)));

end