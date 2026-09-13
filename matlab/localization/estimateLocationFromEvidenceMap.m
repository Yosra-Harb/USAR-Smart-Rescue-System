function [estimatedLocation, localizationState] = ...
    estimateLocationFromEvidenceMap( ...
        localizationState, ...
        candidate)
%% ============================================================
% Function Name : estimateLocationFromEvidenceMap
%
% Description :
% تقدير موقع الضحية باستخدام خريطة الأدلة المكانية.
%
% مراحل العمل:
% 1- فحص صلاحية خريطة الأدلة.
% 2- تحديد منطقة بحث حول القراءة الحالية.
% 3- البحث عن أقوى قمة موثوقة داخل المنطقة.
% 4- استخدام Weighted Centroid لتقدير الموقع.
% 5- حساب ثقة تحديد الموقع من قوة القمة وعدد نقاط الدعم.
%
% لا تستخدم الدالة مواقع الضحايا الحقيقية Ground Truth.
%% ============================================================

%% ============================================================
% Default Output
%% ============================================================

estimatedLocation = struct();
% إنشاء هيكل النتيجة

estimatedLocation.isDetected = false;
% لا يوجد اكتشاف مؤكد افتراضيًا

estimatedLocation.position = [];
% لا يوجد موقع تقديري افتراضيًا

estimatedLocation.confidence = 0;
% ثقة التوطين الابتدائية تساوي صفرًا

estimatedLocation.peakValue = 0;
% قيمة أقوى قمة في خريطة الأدلة

estimatedLocation.supportingCells = 0;
% عدد الخلايا التي دعمت تقدير الموقع

estimatedLocation.candidatePeakCount = 0;
% عدد القمم الموثوقة بعد تطبيق NMS داخل نافذة البحث

estimatedLocation.selectionScore = 0;
% درجة اختيار القمة وفق القوة والتوافق المكاني

%% ============================================================
% Validate Candidate
%% ============================================================

if ~isstruct(candidate) || ...
        ~isfield(candidate, 'position') || ...
        isempty(candidate.position) || ...
        numel(candidate.position) < 2

    return;
    % رفض المرشح إذا لم يكن له موقع صالح

end

% لا تُستخدم candidate.isVictim كبوابة هنا؛ فقد تؤكد خريطة الأدلة
% المتراكمة إشارة ضعيفة لم تتجاوز العتبة اللحظية.

%% ============================================================
% Validate Localization State
%% ============================================================

if ~isstruct(localizationState) || ...
        ~isfield(localizationState, 'evidenceMap') || ...
        isempty(localizationState.evidenceMap)

    return;
    % لا يمكن تحديد الموقع دون خريطة أدلة

end

if ~isfield(localizationState, 'observationCount') || ...
        isempty(localizationState.observationCount)

    return;
    % لا يمكن تقييم موثوقية القمة دون عدد المشاهدات

end

evidenceMap = localizationState.evidenceMap;
% قراءة خريطة الأدلة الحالية

observationCount = localizationState.observationCount;
% قراءة عدد المشاهدات لكل خلية

if ~isequal( ...
        size(evidenceMap), ...
        size(observationCount))

    return;
    % رفض الحالة إذا كانت أحجام المصفوفات غير متطابقة

end

%% ============================================================
% Read Central Configuration
%% ============================================================

config = constants();
% قراءة العتبات من ملف الإعدادات المركزي

minimumObservationCount = max( ...
    1, ...
    round(config.clustering.minimumPoints));
% الحد الأدنى لعدد المشاهدات الداعمة للخلية

searchRadius = round( ...
    config.clustering.distanceThreshold);
% نصف قطر البحث حول المرشح الحالي

centroidRadius = max( ...
    1, ...
    round(config.localization.centroidRadius));
% نصف قطر المنطقة المستخدمة لحساب المركز الموزون

%% ============================================================
% Candidate Search Position
%% ============================================================

numberOfRows = size(evidenceMap, 1);
% عدد صفوف الخريطة

numberOfColumns = size(evidenceMap, 2);
% عدد أعمدة الخريطة

candidateRow = round(candidate.position(1));
% صف موقع القراءة الحالية

candidateColumn = round(candidate.position(2));
% عمود موقع القراءة الحالية

if ~isfinite(candidateRow) || ...
        ~isfinite(candidateColumn)

    return;
    % رفض الإحداثيات غير الرقمية

end

candidateRow = max( ...
    1, ...
    min(numberOfRows, candidateRow));
% إبقاء الصف داخل حدود البيئة

candidateColumn = max( ...
    1, ...
    min(numberOfColumns, candidateColumn));
% إبقاء العمود داخل حدود البيئة

%% ============================================================
% Local Search Window
%% ============================================================

minimumRow = max( ...
    1, ...
    candidateRow - searchRadius);
% أول صف داخل منطقة البحث

maximumRow = min( ...
    numberOfRows, ...
    candidateRow + searchRadius);
% آخر صف داخل منطقة البحث

minimumColumn = max( ...
    1, ...
    candidateColumn - searchRadius);
% أول عمود داخل منطقة البحث

maximumColumn = min( ...
    numberOfColumns, ...
    candidateColumn + searchRadius);
% آخر عمود داخل منطقة البحث

rowIndices = minimumRow:maximumRow;
% صفوف منطقة البحث

columnIndices = minimumColumn:maximumColumn;
% أعمدة منطقة البحث

localEvidence = evidenceMap( ...
    rowIndices, ...
    columnIndices);
% استخراج الأدلة داخل منطقة البحث فقط

localObservationCount = observationCount( ...
    rowIndices, ...
    columnIndices);
% استخراج عدد المشاهدات داخل منطقة البحث

%% ============================================================
% Multi-Peak Detection and Candidate-Aware Selection
%% ============================================================

if isfield(localizationState, 'weightSum') && ...
        isequal( ...
            size(localizationState.weightSum), ...
            size(evidenceMap))
    localSupportMap = localizationState.weightSum( ...
        rowIndices, ...
        columnIndices);
    % كسر تعادل هضبة الدليل باستخدام كثافة القياسات الموزونة.
else
    localSupportMap = localObservationCount;
    % توافق مع الحالات والاختبارات القديمة.
end

%% ============================================================
% Adaptive Peak Threshold
%% ============================================================

[adaptivePeakThreshold, ...
    backgroundMedian, ...
    backgroundRobustSigma, ...
    backgroundSampleCount] = ...
    calculateAdaptivePeakThreshold( ...
        localEvidence, ...
        localObservationCount, ...
        config);

localizationState.lastAdaptivePeakThreshold = ...
    adaptivePeakThreshold;
localizationState.lastBackgroundMedian = backgroundMedian;
localizationState.lastBackgroundRobustSigma = ...
    backgroundRobustSigma;
localizationState.lastBackgroundSampleCount = ...
    backgroundSampleCount;

localPeaks = detectReliableLocalPeaks( ...
    localEvidence, ...
    localObservationCount, ...
    adaptivePeakThreshold, ...
    minimumObservationCount, ...
    localSupportMap);
% استخراج جميع القمم المحلية الموثوقة وتطبيق NMS

if isempty(localPeaks)

    return;
    % رفض المنطقة إذا لم توجد أي قمة قوية وموثوقة

end

for peakIndex = 1:numel(localPeaks)
    localPeaks(peakIndex).row = ...
        minimumRow + localPeaks(peakIndex).row - 1;
    localPeaks(peakIndex).column = ...
        minimumColumn + localPeaks(peakIndex).column - 1;
end
% تحويل إحداثيات القمم من النافذة المحلية إلى الخريطة العالمية

selectedPeak = selectCandidateAwarePeak( ...
    localPeaks, ...
    [candidateRow, candidateColumn]);
% اختيار القمة المتوافقة مع موضع القياس بدل argmax المطلق

if isempty(selectedPeak)
    return;
end

peakRow = selectedPeak.row;
peakColumn = selectedPeak.column;
peakValue = selectedPeak.value;

%% ============================================================
% Weighted Centroid Region
%% ============================================================

centroidMinimumRow = max( ...
    1, ...
    peakRow - centroidRadius);
% أول صف في منطقة حساب المركز

centroidMaximumRow = min( ...
    numberOfRows, ...
    peakRow + centroidRadius);
% آخر صف في منطقة حساب المركز

centroidMinimumColumn = max( ...
    1, ...
    peakColumn - centroidRadius);
% أول عمود في منطقة حساب المركز

centroidMaximumColumn = min( ...
    numberOfColumns, ...
    peakColumn + centroidRadius);
% آخر عمود في منطقة حساب المركز

centroidRows = ...
    centroidMinimumRow:centroidMaximumRow;
% صفوف منطقة المركز الموزون

centroidColumns = ...
    centroidMinimumColumn:centroidMaximumColumn;
% أعمدة منطقة المركز الموزون

centroidEvidence = evidenceMap( ...
    centroidRows, ...
    centroidColumns);
% قيم الأدلة المحيطة بالقمة

centroidObservations = observationCount( ...
    centroidRows, ...
    centroidColumns);
% عدد المشاهدات المحيطة بالقمة

[rowGrid, columnGrid] = ndgrid( ...
    centroidRows, ...
    centroidColumns);
% إنشاء إحداثيات خلايا منطقة المركز

distanceSquared = ...
    (rowGrid - peakRow).^2 + ...
    (columnGrid - peakColumn).^2;
% حساب بعد كل خلية عن القمة

relativeEvidenceThreshold = max( ...
    adaptivePeakThreshold, ...
    0.75 * peakValue);
% قبول الخلايا القريبة من قوة القمة فقط

centroidMask = ...
    distanceSquared <= centroidRadius^2 & ...
    centroidObservations >= minimumObservationCount & ...
    centroidEvidence >= relativeEvidenceThreshold;
% تحديد الخلايا الموثوقة المشاركة في حساب الموقع

centroidWeights = ...
    centroidEvidence .* double(centroidMask);
% استخدام قوة الدليل كوزن لكل خلية

totalCentroidWeight = ...
    sum(centroidWeights(:));
% حساب مجموع أوزان الخلايا

if totalCentroidWeight <= eps

    estimatedRow = peakRow;
    estimatedColumn = peakColumn;
    % استخدام موقع القمة إذا لم توجد خلايا كافية حولها

else

    estimatedRow = sum( ...
        rowGrid(:) .* centroidWeights(:)) / ...
        totalCentroidWeight;
    % حساب الصف الموزون للموقع التقديري

    estimatedColumn = sum( ...
        columnGrid(:) .* centroidWeights(:)) / ...
        totalCentroidWeight;
    % حساب العمود الموزون للموقع التقديري

end

estimatedPosition = round( ...
    [estimatedRow, estimatedColumn]);
% تحويل النتيجة إلى أقرب خلية في البيئة

%% ============================================================
% Localization Confidence
%% ============================================================

supportingCells = nnz(centroidMask);
% حساب عدد الخلايا الداعمة للموقع

requiredSupportingCells = max( ...
    3, ...
    2 * minimumObservationCount);
% تحديد العدد المطلوب للوصول إلى دعم مكاني كامل

spatialSupport = min( ...
    1, ...
    supportingCells / requiredSupportingCells);
% تطبيع مقدار الدعم المكاني بين صفر وواحد

candidateConfidence = 0;

if isfield(candidate, 'confidence') && ...
        isscalar(candidate.confidence) && ...
        isfinite(candidate.confidence)
    candidateConfidence = max( ...
        0, ...
        min(1, candidate.confidence));
end

thresholdMargin = max( ...
    0, ...
    (peakValue - adaptivePeakThreshold) / ...
    max(1 - adaptivePeakThreshold, eps));

localizationConfidence = ...
    0.35 * peakValue + ...
    0.25 * candidateConfidence + ...
    0.25 * spatialSupport + ...
    0.15 * thresholdMargin;
% دمج قوة القمة وثقة القياس والدعم المكاني

localizationConfidence = max( ...
    0, ...
    min(1, localizationConfidence));
% حصر ثقة تحديد الموقع بين صفر وواحد

%% ============================================================
% Build Successful Result
%% ============================================================

estimatedLocation.isDetected = true;
% اعتماد وجود اكتشاف مكاني

estimatedLocation.position = estimatedPosition;
% حفظ الموقع المحسوب بالمركز الموزون

estimatedLocation.confidence = localizationConfidence;
% حفظ ثقة تحديد الموقع

estimatedLocation.peakValue = peakValue;
% حفظ قوة القمة المستخدمة

estimatedLocation.supportingCells = supportingCells;
% حفظ عدد الخلايا الداعمة

estimatedLocation.candidatePeakCount = numel(localPeaks);
% حفظ عدد القمم الموثوقة لأغراض التشخيص والاختبارات

estimatedLocation.selectionScore = selectedPeak.selectionScore;
% حفظ درجة الاختيار دون استخدامها كبديل لثقة التوطين

%% ============================================================
% Update Localization State
%% ============================================================

localizationState.lastEstimatedPosition = ...
    estimatedPosition;
% حفظ آخر موقع تم تقديره

localizationState.lastPeakValue = peakValue;
% حفظ قيمة آخر قمة مقبولة

localizationState.lastCandidatePeakCount = numel(localPeaks);
% حفظ عدد القمم المتاحة داخل آخر نافذة بحث

end


function [adaptiveThreshold, ...
    backgroundMedian, ...
    backgroundRobustSigma, ...
    backgroundSampleCount] = ...
    calculateAdaptivePeakThreshold( ...
        localEvidence, ...
        localObservationCount, ...
        config)

adaptiveThreshold = config.detection.fusionScore;
backgroundMedian = 0;
backgroundRobustSigma = 0;
backgroundSampleCount = 0;

if ~isfield(config, 'localization') || ...
        ~isfield(config.localization, ...
            'useAdaptivePeakThreshold') || ...
        ~config.localization.useAdaptivePeakThreshold
    return;
end

minimumThreshold = ...
    config.localization.minimumAdaptivePeakThreshold;
maximumThreshold = ...
    config.localization.maximumAdaptivePeakThreshold;
madMultiplier = ...
    config.localization.backgroundMadMultiplier;
minimumBackgroundSamples = ...
    config.localization.minimumBackgroundSamples;

validBackgroundMask = ...
    isfinite(localEvidence) & ...
    localObservationCount > 0;
backgroundSamples = localEvidence(validBackgroundMask);
backgroundSamples = ...
    backgroundSamples(isfinite(backgroundSamples));
backgroundSampleCount = numel(backgroundSamples);

if backgroundSampleCount < minimumBackgroundSamples
    adaptiveThreshold = minimumThreshold;
    if backgroundSampleCount > 0
        backgroundMedian = median(backgroundSamples);
    end
    return;
end

backgroundMedian = median(backgroundSamples);
medianAbsoluteDeviation = median( ...
    abs(backgroundSamples - backgroundMedian));
backgroundRobustSigma = ...
    1.4826 * medianAbsoluteDeviation;
statisticalThreshold = ...
    backgroundMedian + ...
    madMultiplier * backgroundRobustSigma;

adaptiveThreshold = max( ...
    minimumThreshold, ...
    min(maximumThreshold, statisticalThreshold));

end
