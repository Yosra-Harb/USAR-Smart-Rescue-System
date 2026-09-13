function temporalStability = ...
    calculateTemporalStability(probe, localizationPacket)
%% ============================================================
% Function Name : calculateTemporalStability
%
% Description :
% حساب الثبات الزمني من القراءات القريبة مكانيًا
% من موقع المسبار الحالي.
%
% لا تستخدم الدالة آخر قراءات المهمة بصورة عشوائية،
% لأن هذه القراءات قد تنتمي إلى مواقع مختلفة.
%
% تعتمد الدالة على:
% 1- وسيط نتائج الدمج المحلية.
% 2- الانحراف الوسيط المطلق MAD.
% 3- عدد القياسات المحلية المتاحة.
%% ============================================================

%% ============================================================
% Default Output
%% ============================================================

temporalStability = 0.5;
% قيمة محايدة عند عدم توفر تاريخ محلي كافٍ

if nargin < 2
    localizationPacket = struct();
end

[bayesianStability, hasBayesianSupport] = ...
    calculateBayesianTrackStability( ...
        probe, localizationPacket);

if hasBayesianSupport
    temporalStability = bayesianStability;
    return;
    % في v4 يمثل استمرار المسار الاحتمالي عبر مشاهدات مستقلة
    % تعريف الثبات الزمني الأنسب، وليس سجل evidenceMap القديم.
end

%% ============================================================
% Validate Probe Memory
%% ============================================================

if ~isstruct(probe) || ...
        ~isfield(probe, 'memory') || ...
        ~isfield(probe.memory, 'localizationState')

    return;
    % لا يمكن حساب الثبات دون ذاكرة التوطين

end


state = probe.memory.localizationState;
% قراءة حالة التوطين

if ~isfield(state, 'pointHistory') || ...
        ~isfield(state, 'scoreHistory') || ...
        isempty(state.pointHistory) || ...
        isempty(state.scoreHistory)

    return;
    % لا يوجد تاريخ مكاني كافٍ

end


if size(state.pointHistory, 2) < 2

    return;
    % يجب أن يحتوي كل موقع على صف وعمود

end

%% ============================================================
% Align History Lengths
%% ============================================================

historyLength = min( ...
    size(state.pointHistory, 1), ...
    numel(state.scoreHistory));
% ضمان تطابق عدد المواقع مع عدد نتائج الدمج

if historyLength < 1

    return;

end

pointHistory = ...
    state.pointHistory(1:historyLength, 1:2);
% قراءة المواقع ذات النتائج المقابلة

scoreHistory = ...
    state.scoreHistory(1:historyLength);
% قراءة نتائج الدمج المرتبطة بالمواقع

%% ============================================================
% Remove Invalid Samples
%% ============================================================

validSamples = ...
    all(isfinite(pointHistory), 2) & ...
    isfinite(scoreHistory);
% تحديد القياسات الصالحة فقط

pointHistory = pointHistory(validSamples, :);
scoreHistory = scoreHistory(validSamples);
% إزالة القياسات غير الصالحة

if isempty(scoreHistory)

    return;

end

scoreHistory = max( ...
    0, ...
    min(1, scoreHistory));
% حصر نتائج الدمج بين صفر وواحد

%% ============================================================
% Read Configuration
%% ============================================================

config = constants();
% قراءة الإعدادات المركزية

maximumHistory = max( ...
    1, ...
    round(config.clustering.maximumHistory));
% أقصى عدد قياسات محلية مستخدمة

minimumLocalSamples = max( ...
    2, ...
    round(config.clustering.minimumPoints));
% أقل عدد مطلوب لحساب ثبات موثوق

spatialRadius = max( ...
    2, ...
    ceil(config.clustering.distanceThreshold / 3));
% نصف قطر محلي أصغر من نصف قطر التجميع العام
% حتى لا تختلط قراءات ضحايا أو مناطق مختلفة

%% ============================================================
% Select Spatially Local Measurements
%% ============================================================

currentPosition = pointHistory(end, :);
% استخدام موقع أحدث قياس كمركز زمني ومكاني

distanceSquared = ...
    (pointHistory(:,1) - currentPosition(1)).^2 + ...
    (pointHistory(:,2) - currentPosition(2)).^2;
% حساب بعد كل قياس سابق عن الموقع الحالي

localIndices = find( ...
    distanceSquared <= spatialRadius^2);
% اختيار القراءات القريبة مكانيًا فقط

if isempty(localIndices)

    return;

end

if numel(localIndices) > maximumHistory

    localIndices = ...
        localIndices(end-maximumHistory+1:end);
    % استخدام أحدث القياسات المحلية فقط

end

localHistory = scoreHistory(localIndices);
% استخراج نتائج الدمج المحلية

numberOfLocalSamples = numel(localHistory);
% حساب عدد القياسات المحلية

if numberOfLocalSamples < minimumLocalSamples

    return;
    % إبقاء القيمة المحايدة حتى يتوفر دعم محلي كافٍ

end

%% ============================================================
% Robust Local Stability
%% ============================================================

medianFusion = median(localHistory);
% استخدام الوسيط لتقليل تأثير القراءة الشاذة

medianAbsoluteDeviation = median( ...
    abs(localHistory - medianFusion));
% حساب MAD المحلي

robustSpread = ...
    1.4826 * medianAbsoluteDeviation;
% تحويل MAD إلى تقدير قوي للانتشار

stabilityFloor = 0.03;
% منع القسمة على صفر عند الإشارات الصغيرة جدًا

normalizedVariation = ...
    robustSpread / ...
    max(abs(medianFusion), stabilityFloor);
% قياس التغير نسبةً إلى مستوى الإشارة المحلية

consistencyScore = exp( ...
    -normalizedVariation);
% تحويل التغير إلى درجة ثبات بين صفر وواحد

%% ============================================================
% Local Sample Support
%% ============================================================

sampleSupport = ...
    1 - exp( ...
    -numberOfLocalSamples / ...
    minimumLocalSamples);
% زيادة الثقة تدريجيًا مع زيادة عدد القياسات المحلية

sampleSupport = max( ...
    0, ...
    min(1, sampleSupport));
% حصر دعم العينات بين صفر وواحد

%% ============================================================
% Final Temporal Stability
%% ============================================================

temporalStability = ...
    0.75 * consistencyScore + ...
    0.25 * sampleSupport;
% إعطاء الاتساق المحلي التأثير الأكبر
% مع الاستفادة من عدد القياسات المتكررة

temporalStability = max( ...
    0, ...
    min(1, temporalStability));
% ضمان أن النتيجة بين صفر وواحد

end


function [stability, hasSupport] = ...
    calculateBayesianTrackStability( ...
        probe, localizationPacket)

stability = 0.5;
hasSupport = false;

if ~isstruct(probe) || ...
        ~isfield(probe, 'memory') || ...
        ~isfield(probe.memory, 'localizationMethod') || ...
        lower(string(probe.memory.localizationMethod)) ~= ...
            "spatialbayesianfusion" || ...
        ~isfield(probe.memory, 'bayesianLocalizationState') || ...
        ~isstruct(localizationPacket) || ...
        ~isfield(localizationPacket, 'isVictimDetected') || ...
        ~logical(localizationPacket.isVictimDetected) || ...
        ~isfield(localizationPacket, 'estimatedPosition') || ...
        numel(localizationPacket.estimatedPosition) < 2
    return;
end

state = probe.memory.bayesianLocalizationState;
if ~isfield(state, 'tracks') || isempty(state.tracks)
    return;
end

estimatedPosition = ...
    double(localizationPacket.estimatedPosition(1:2));
if any(~isfinite(estimatedPosition))
    return;
end

trackPositions = reshape( ...
    [state.tracks.position], 2, [])';
distances = hypot( ...
    trackPositions(:,1) - estimatedPosition(1), ...
    trackPositions(:,2) - estimatedPosition(2));
[minimumDistance, trackIndex] = min(distances);

config = constants();
if minimumDistance > ...
        config.spatialBayesian.trackAssociationDistance
    return;
end

track = state.tracks(trackIndex);
existenceProbability = max(0, min(1, ...
    double(track.existenceProbability)));
minimumViews = max(1, ...
    config.spatialBayesian.minimumIndependentViews);
viewSupport = 1 - exp( ...
    -double(track.independentViewCount) / minimumViews);
updateSupport = 1 - exp( ...
    -double(track.updateCount) / minimumViews);

stability = ...
    0.65 * existenceProbability + ...
    0.25 * viewSupport + ...
    0.10 * updateSupport;
stability = max(0, min(1, stability));
hasSupport = true;

end
