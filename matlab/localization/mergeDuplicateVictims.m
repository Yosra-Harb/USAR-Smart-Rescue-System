function victims = mergeDuplicateVictims( ...
    victims, ...
    mergeDistance)
%% ============================================================
% Function Name : mergeDuplicateVictims
%
% Description :
% دمج سجلات الضحايا التي أصبحت مواقعها متقاربة جدًا.
%
% تستخدم الدالة دمجًا محافظًا بمسافة صغيرة حتى لا تدمج
% ضحيتين حقيقيتين متقاربتين خطأً.
%
% عند دمج سجلين:
% 1- يُحسب الموقع بمتوسط موزون بعدد المشاهدات المستقلة.
% 2- تُدمج مواقع الرصد دون عدّ المواقع المتداخلة مرتين.
% 3- يُستخدم أعلى Priority Score لأسباب تتعلق بالسلامة.
% 4- يُحفظ أقدم وقت اكتشاف وأحدث وقت تحديث.
%% ============================================================

%% ============================================================
% Read Default Merge Distance
%% ============================================================

if nargin < 2 || isempty(mergeDistance)

    config = constants();
    % قراءة الإعدادات المركزية

    mergeDistance = ...
        config.victimDatabase.duplicateMergeDistance;
    % استخدام مسافة الدمج المعرفة مركزيًا

end

%% ============================================================
% Handle Empty or Single Record
%% ============================================================

if isempty(victims) || numel(victims) < 2

    return;
    % لا توجد سجلات مكررة محتملة

end

%% ============================================================
% Repeated Pairwise Merge
%% ============================================================

mergeOccurred = true;
% بدء عملية البحث عن السجلات المكررة

while mergeOccurred

    mergeOccurred = false;
    % افتراض عدم وجود دمج جديد في الدورة الحالية

    numberOfVictims = numel(victims);
    % قراءة عدد السجلات الحالي

    for firstIndex = 1:numberOfVictims-1

        firstPosition = ...
            victims(firstIndex).position;
        % موقع السجل الأول

        if ~isValidPosition(firstPosition)

            continue;
            % تجاهل السجل إذا كان موقعه غير صالح

        end

        for secondIndex = firstIndex+1:numberOfVictims

            secondPosition = ...
                victims(secondIndex).position;
            % موقع السجل الثاني

            if ~isValidPosition(secondPosition)

                continue;
                % تجاهل السجل إذا كان موقعه غير صالح

            end

            positionDifference = ...
                firstPosition(1:2) - ...
                secondPosition(1:2);
            % حساب فرق الإحداثيات

            distance = sqrt( ...
                sum(positionDifference.^2));
            % حساب المسافة الإقليدية بين السجلين

            if distance <= mergeDistance

                victims(firstIndex) = ...
                    mergeVictimRecords( ...
                        victims(firstIndex), ...
                        victims(secondIndex));
                % دمج السجل الثاني داخل السجل الأول

                victims(secondIndex) = [];
                % حذف السجل المكرر بعد دمج معلوماته

                mergeOccurred = true;
                % تسجيل حدوث عملية دمج

                break;
                % إعادة فحص القائمة بعد تغير حجمها

            end

        end

        if mergeOccurred

            break;
            % الخروج لإعادة عملية البحث بالقائمة الجديدة

        end

    end

end

end

%% ============================================================
% Local Function: Merge Two Victim Records
%% ============================================================

function mergedRecord = mergeVictimRecords( ...
    firstRecord, ...
    secondRecord)
%% دمج معلومات سجلين يعودان إلى الضحية نفسها

firstCount = readIndependentCount(firstRecord);
% عدد المشاهدات المستقلة التي تدعم السجل الأول

secondCount = readIndependentCount(secondRecord);
% عدد المشاهدات المستقلة التي تدعم السجل الثاني

totalCount = firstCount + secondCount;
% إجمالي عدد مرات الكشف

if totalCount > 0

    mergedPosition = ...
        (firstRecord.position .* firstCount + ...
         secondRecord.position .* secondCount) ./ ...
        totalCount;
    % حساب الموقع بمتوسط موزون بعدد مرات الكشف

    mergedVitalityIndex = ...
        (firstRecord.vitalityIndex .* firstCount + ...
         secondRecord.vitalityIndex .* secondCount) ./ ...
        totalCount;
    % حساب مؤشر الحيوية بمتوسط موزون

else

    mergedPosition = ...
        mean( ...
            [firstRecord.position;
             secondRecord.position], ...
            1);
    % استخدام المتوسط العادي عند غياب أعداد الكشف

    mergedVitalityIndex = ...
        mean( ...
            [firstRecord.vitalityIndex, ...
             secondRecord.vitalityIndex]);
    % حساب متوسط مؤشر الحيوية

end

mergedRecord = firstRecord;
% استخدام السجل الأول كأساس للسجل المدمج

mergedRecord.id = min( ...
    firstRecord.id, ...
    secondRecord.id);
% الاحتفاظ بالرقم الأقدم أو الأصغر

mergedRecord.position = round(mergedPosition);
% حفظ الموقع الموزون كخلية صحيحة

mergedRecord.vitalityIndex = ...
    mergedVitalityIndex;
% حفظ مؤشر الحيوية المدمج

mergedRecord.priorityScore = max( ...
    firstRecord.priorityScore, ...
    secondRecord.priorityScore);
% الاحتفاظ بأعلى أولوية حفاظًا على السلامة

mergedRecord.priorityLevel = ...
    classifyPriority( ...
        mergedRecord.priorityScore);
% إعادة تصنيف مستوى الأولوية

mergedRecord.firstDetectionTime = min( ...
    firstRecord.firstDetectionTime, ...
    secondRecord.firstDetectionTime);
% الاحتفاظ بأقدم وقت اكتشاف

mergedRecord.lastUpdateTime = max( ...
    firstRecord.lastUpdateTime, ...
    secondRecord.lastUpdateTime);
% الاحتفاظ بأحدث وقت تحديث

hasObservationHistory = ...
    isfield(firstRecord, "observationPositions") && ...
    isfield(secondRecord, "observationPositions");

if hasObservationHistory

    config = constants();
    mergedObservations = mergeIndependentPositions( ...
        [firstRecord.observationPositions(:,1:2); ...
         secondRecord.observationPositions(:,1:2)], ...
        config.victimDatabase.minimumIndependentViewDistance);

    mergedRecord.observationPositions = mergedObservations;
    mergedRecord.independentViewCount = ...
        size(mergedObservations, 1);
    mergedRecord.detectionCount = ...
        mergedRecord.independentViewCount;
    % يمنع احتساب موقع الرصد نفسه مرتين بعد دمج سجلين مكررين.

else

    mergedRecord.detectionCount = totalCount;
    % توافق مع السجلات القديمة التي لا تحفظ تاريخ مواقع الرصد.

end

if isfield(firstRecord, "rawAssociationCount") && ...
        isfield(secondRecord, "rawAssociationCount")
    mergedRecord.rawAssociationCount = ...
        firstRecord.rawAssociationCount + ...
        secondRecord.rawAssociationCount;
end

if isfield(firstRecord,"hasRangedMeasurementEvidence") && ...
        isfield(secondRecord,"hasRangedMeasurementEvidence")
    mergedRecord.hasRangedMeasurementEvidence = ...
        logical(firstRecord.hasRangedMeasurementEvidence) || ...
        logical(secondRecord.hasRangedMeasurementEvidence);
end

if isfield(firstRecord,"rangedMeasurementAssociationCount") && ...
        isfield(secondRecord,"rangedMeasurementAssociationCount")
    mergedRecord.rangedMeasurementAssociationCount = ...
        firstRecord.rangedMeasurementAssociationCount + ...
        secondRecord.rangedMeasurementAssociationCount;
end

if isfield(firstRecord, "lastObservationPosition") && ...
        isfield(secondRecord, "lastObservationPosition")
    if secondRecord.lastUpdateTime > firstRecord.lastUpdateTime
        mergedRecord.lastObservationPosition = ...
            secondRecord.lastObservationPosition;
    else
        mergedRecord.lastObservationPosition = ...
            firstRecord.lastObservationPosition;
    end
end

end

%% ============================================================
% Local Function: Read Independent Count
%% ============================================================

function count = readIndependentCount(record)

if isfield(record, "independentViewCount") && ...
        ~isempty(record.independentViewCount)
    count = max(0, record.independentViewCount);
else
    count = max(0, record.detectionCount);
end

end

%% ============================================================
% Local Function: Merge Spatially Independent Positions
%% ============================================================

function mergedPositions = mergeIndependentPositions( ...
    positions, ...
    minimumDistance)

mergedPositions = zeros(0,2);

for index = 1:size(positions,1)

    candidate = positions(index,1:2);

    if ~isValidPosition(candidate)
        continue;
    end

    if isempty(mergedPositions)
        mergedPositions(end+1,:) = candidate;
        continue;
    end

    differences = mergedPositions - candidate;
    distances = sqrt(sum(differences.^2, 2));

    if all(distances >= minimumDistance)
        mergedPositions(end+1,:) = candidate;
    end

end

end

%% ============================================================
% Local Function: Validate Position
%% ============================================================

function isValid = isValidPosition(position)
%% فحص أن الموقع يحتوي على إحداثيين رقميين صالحين

isValid = ...
    isnumeric(position) && ...
    numel(position) >= 2 && ...
    all(isfinite(position(1:2)));
% إرجاع true فقط للموقع الرقمي الصالح

end
