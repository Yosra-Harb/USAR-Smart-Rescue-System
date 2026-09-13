function probe = updateVictimDatabase( ...
    probe, ...
    vitalityPacket, ...
    priorityPacket)
%% ============================================================
% تحديث قاعدة الضحايا باستخدام تأكيدات مكانية مستقلة
%
% detectionCount اسم توافق قديم، لكنه يساوي الآن عدد المشاهدات
% المستقلة independentViewCount، وليس عدد عينات الحساس المتتابعة.
%% ============================================================

config = constants();

if ~vitalityPacket.isVictimDetected
    return;
end
% لا يُستخدم الثبات الزمني كبوابة تمنع إنشاء سجل مرشح.
% تُجمع المشاهدات المكانية المستقلة أولًا، ثم يقرر فلتر
% التقرير النهائي إن كان السجل مؤكدًا بما يكفي.

estimatedPosition = vitalityPacket.estimatedPosition;

if ~isValidPosition(estimatedPosition)
    return;
end

observationPosition = resolveObservationPosition( ...
    probe, ...
    vitalityPacket, ...
    estimatedPosition);
% يمثل موضع المسبار الذي أخذ القياس، وليس موضع الضحية الحقيقي.

probe.memory.detectedVictims = ensureCurrentSchema( ...
    probe.memory.detectedVictims);
% ترقية السجلات القديمة المحملة من checkpoint دون كسر التوافق.

victimIndex = findNearestAssociatedVictim( ...
    probe.memory.detectedVictims, ...
    estimatedPosition, ...
    config.victimDatabase.associationDistance);

if isempty(victimIndex)

    victimID = allocateNextVictimID( ...
        probe.memory.detectedVictims);
    % لا نستخدم numel(records)+1 لأن دمج السجلات قد يترك فجوات في IDs.
    % استخدام أكبر ID موجود + 1 يمنع إعادة استخدام معرف قديم لضحية جديدة.

    newVictim = registerVictim( ...
        victimID, ...
        vitalityPacket, ...
        priorityPacket, ...
        observationPosition);

    schemaFields = fieldnames( ...
        probe.memory.detectedVictims);
    if ~isempty(schemaFields)
        newVictimFields = fieldnames(newVictim);
        [fieldsMatch,fieldPermutation] = ismember( ...
            schemaFields,newVictimFields);
        if numel(schemaFields) ~= ...
                numel(newVictimFields) || ...
                ~all(fieldsMatch)
            error( ...
                "updateVictimDatabase:VictimSchemaMismatch", ...
                "Victim database schema does not match a new record.");
        end
        newVictim = orderfields( ...
            newVictim,fieldPermutation);
    end

    probe.memory.detectedVictims = ...
        [probe.memory.detectedVictims; newVictim];

else

    victim = probe.memory.detectedVictims(victimIndex);
    victim.rawAssociationCount = victim.rawAssociationCount + 1;
    % يُحفظ العدد الخام للتشخيص، لكنه لا يدخل بوابة التقرير النهائي.

    isRangedMeasurement = ...
        isfield(vitalityPacket,'sourceType') && ...
        string(vitalityPacket.sourceType) == ...
            "RANGED_MEASUREMENT";
    if isRangedMeasurement
        victim.hasRangedMeasurementEvidence = true;
        victim.rangedMeasurementAssociationCount = ...
            victim.rangedMeasurementAssociationCount + 1;
    end

    isIndependentView = isSpatiallyIndependent( ...
        observationPosition, ...
        victim.observationPositions, ...
        config.victimDatabase.minimumIndependentViewDistance);

    if isIndependentView

        oldCount = victim.independentViewCount;
        newCount = oldCount + 1;

        victim.position = round( ...
            (victim.position .* oldCount + ...
             estimatedPosition(1:2)) ./ newCount);
        % متوسط تراكمي موزون بالتأكيدات المستقلة فقط؛ تكرار القراءة من
        % الموضع نفسه لا يسحب تقدير الموقع ولا يضخم الثقة.

        victim.independentViewCount = newCount;
        victim.detectionCount = newCount;
        victim.observationPositions(end+1,:) = ...
            observationPosition(1:2);
        victim.lastObservationPosition = ...
            observationPosition(1:2);

    end

    victim.vitalityIndex = vitalityPacket.vitalityIndex;
    if isfield(vitalityPacket, 'victimCondition')
        victim.victimCondition = vitalityPacket.victimCondition;
    end
    victim.priorityScore = priorityPacket.priorityScore;
    victim.priorityLevel = priorityPacket.priorityLevel;
    victim.lastUpdateTime = datetime("now");

    probe.memory.detectedVictims(victimIndex) = victim;

end


probe.memory.detectedVictims = mergeDuplicateVictims( ...
    probe.memory.detectedVictims, ...
    config.victimDatabase.duplicateMergeDistance);

end


function observationPosition = resolveObservationPosition( ...
    probe, ...
    vitalityPacket, ...
    fallbackPosition)
% أولوية المصدر: موضع المسبار، ثم الموضع المحمول في الحزمة، ثم مسار توافق.

if isfield(probe, "position") && ...
        isValidPosition(probe.position)
    observationPosition = probe.position(1:2);
elseif isfield(vitalityPacket, "probePosition") && ...
        isValidPosition(vitalityPacket.probePosition)
    observationPosition = vitalityPacket.probePosition(1:2);
else
    observationPosition = fallbackPosition(1:2);
end

end


function victims = ensureCurrentSchema(victims)
% ترقية بنية قديمة مع إبقاء detectionCount كاسم توافق.

planningDefaults = struct( ...
    'victimCondition',"UNKNOWN", ...
    'rescueRank',NaN, ...
    'rescuePriorityScore',NaN, ...
    'reachable',false, ...
    'shortestPath',zeros(0,2), ...
    'recommendedPath',zeros(0,2), ...
    'shortestPathLength',Inf, ...
    'recommendedPathLength',Inf, ...
    'recommendedTravelCost',Inf, ...
    'meanRouteRisk',NaN, ...
    'meanRouteAccessibility',NaN, ...
    'rescueAccessPoint',zeros(0,2), ...
    'priorityComponents',struct());
planningFields = fieldnames(planningDefaults);

for fieldIndex = 1:numel(planningFields)
    fieldName = planningFields{fieldIndex};
    victims = ensureStructField( ...
        victims,fieldName,planningDefaults.(fieldName));
end

victims = ensureStructField( ...
    victims,'hasRangedMeasurementEvidence',false);
victims = ensureStructField( ...
    victims,'rangedMeasurementAssociationCount',0);

for index = 1:numel(victims)

    legacyCount = max(1, victims(index).detectionCount);

    if ~isfield(victims, "independentViewCount") || ...
            isempty(victims(index).independentViewCount)
        victims(index).independentViewCount = legacyCount;
    end

    if ~isfield(victims, "rawAssociationCount") || ...
            isempty(victims(index).rawAssociationCount)
        victims(index).rawAssociationCount = legacyCount;
    end

    if ~isfield(victims, "observationPositions") || ...
            isempty(victims(index).observationPositions)
        victims(index).observationPositions = ...
            victims(index).position(1:2);
    end

    if ~isfield(victims, "lastObservationPosition") || ...
            ~isValidPosition(victims(index).lastObservationPosition)
        victims(index).lastObservationPosition = ...
            victims(index).observationPositions(end,1:2);
    end

    victims(index).detectionCount = ...
        victims(index).independentViewCount;

end

end


function records = ensureStructField( ...
    records,fieldName,defaultValue)
% يضيف الحقل إلى السجلات غير الفارغة وإلى مخطط struct الفارغ المعرّف.
% يبقى struct([]) غير المعرّف كما هو كي يقبل أول سجل بأي مخطط صالح.

if isfield(records,fieldName)
    return;
end

if isempty(records)
    existingFields = fieldnames(records);
    if isempty(existingFields)
        return;
    end

    template = struct();
    for fieldIndex = 1:numel(existingFields)
        template.(existingFields{fieldIndex}) = [];
    end
    template.(fieldName) = defaultValue;
    records = repmat(template,0,1);
    return;
end

for recordIndex = 1:numel(records)
    records(recordIndex).(fieldName) = defaultValue;
end

end


function victimIndex = findNearestAssociatedVictim( ...
    victims, ...
    estimatedPosition, ...
    associationDistance)
% اختيار أقرب سجل صالح بدل أول سجل في المصفوفة.

victimIndex = [];
nearestDistance = inf;

for index = 1:numel(victims)

    if ~isValidPosition(victims(index).position)
        continue;
    end

    difference = estimatedPosition(1:2) - ...
        victims(index).position(1:2);
    distance = sqrt(sum(difference.^2));

    if distance <= associationDistance && ...
            distance < nearestDistance
        nearestDistance = distance;
        victimIndex = index;
    end

end
end


function isIndependent = isSpatiallyIndependent( ...
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


function isValid = isValidPosition(position)

isValid = isnumeric(position) && ...
    numel(position) >= 2 && ...
    all(isfinite(position(1:2)));

end

function victimID = allocateNextVictimID(victims)
%% ============================================================
% تخصيص معرف تشغيلي فريد ومتزايد للضحية الجديدة.
%
% السبب:
% mergeDuplicateVictims قد يحذف سجلات ويحافظ على أصغر ID، لذلك قد تصبح
% IDs الحالية غير متصلة مثل [1 3]. استخدام numel(victims)+1 سيعيد 3
% مرة ثانية ويولد معرفين متساويين.
%% ============================================================

if isempty(victims)
    victimID = 1;
    return;
end

if ~isfield(victims,'id')
    error( ...
        'updateVictimDatabase:MissingVictimID', ...
        'Existing victim records must contain an id field.');
end

existingIDs = double([victims.id]);

if any(~isfinite(existingIDs)) || ...
        any(existingIDs < 1) || ...
        any(existingIDs ~= floor(existingIDs))
    error( ...
        'updateVictimDatabase:InvalidVictimID', ...
        'Existing victim IDs must be finite positive integers.');
end

if numel(unique(existingIDs)) ~= numel(existingIDs)
    error( ...
        'updateVictimDatabase:DuplicateExistingVictimIDs', ...
        'Existing victim records contain duplicate IDs.');
end

victimID = max(existingIDs) + 1;

end

