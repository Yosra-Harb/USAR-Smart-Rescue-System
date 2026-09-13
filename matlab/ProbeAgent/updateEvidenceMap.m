function probe = updateEvidenceMap(probe, fusionPacket)
%% ============================================================
% Function Name : updateEvidenceMap
%
% Description :
% تحديث خريطة الأدلة المكانية اعتمادًا على:
% 1- موقع المسبار الحالي.
% 2- نتيجة الدمج Fusion Score.
% 3- درجة الثقة في القياس.
%
% تستخدم الدالة Gaussian Kernel لتوزيع الدليل مكانيًا،
% ثم تطبع الأدلة لمنع تكرار زيارة الخلية من تضخيم قيمتها.
%
% تم تنفيذ العمليات باستخدام المصفوفات بدل الحلقات المتداخلة
% لتقليل زمن تشغيل المحاكاة.
%% ============================================================

%% ============================================================
% Read Localization State
%% ============================================================

state = probe.memory.localizationState;
% قراءة حالة تحديد الموقع من ذاكرة المسبار

%% ============================================================
% Validate Evidence Map Initialization
%% ============================================================

if isempty(state.evidenceMap)

    gridRows = size(probe.visitedCells, 1);
    % استخراج عدد صفوف البيئة

    gridColumns = size(probe.visitedCells, 2);
    % استخراج عدد أعمدة البيئة

    state.gridSize = [gridRows, gridColumns];
    % حفظ حجم البيئة

    state.evidenceSum = zeros(gridRows, gridColumns);
    % تهيئة مجموع الأدلة

    state.weightSum = zeros(gridRows, gridColumns);
    % تهيئة مجموع الأوزان

    state.evidenceMap = zeros(gridRows, gridColumns);
    % تهيئة خريطة الأدلة المطبعة

    state.observationCount = zeros(gridRows, gridColumns);
    % تهيئة عدد المشاهدات

end

%% ============================================================
% Read and Validate Current Measurement
%% ============================================================

probeRow = round(fusionPacket.probePosition(1));
% قراءة صف موقع المسبار

probeColumn = round(fusionPacket.probePosition(2));
% قراءة عمود موقع المسبار

fusionScore = max( ...
    0, ...
    min(1, fusionPacket.fusionScore));
% حصر نتيجة الدمج بين صفر وواحد

measurementConfidence = max( ...
    0, ...
    min(1, fusionPacket.confidence));
% حصر درجة الثقة بين صفر وواحد

if ~isfinite(fusionScore) || ...
        ~isfinite(measurementConfidence)

    probe.memory.localizationState = state;
    % تجاهل أي قراءة غير رقمية أو غير صالحة

    return;

end

if measurementConfidence <= eps

    probe.memory.localizationState = state;
    % تجاهل القياسات التي لا تحمل أي ثقة

    return;

end

%% ============================================================
% Spatial Kernel Configuration
%% ============================================================

kernelRadius = 2;
% نصف قطر نشر الدليل حول موقع المسبار

gaussianSigma = 1.25;
% معامل انتشار Gaussian Kernel

numberOfRows = state.gridSize(1);
% عدد صفوف خريطة الأدلة

numberOfColumns = state.gridSize(2);
% عدد أعمدة خريطة الأدلة

%% ============================================================
% Calculate Valid Local Region
%% ============================================================

minimumRow = max( ...
    1, ...
    probeRow - kernelRadius);
% أول صف صالح داخل البيئة

maximumRow = min( ...
    numberOfRows, ...
    probeRow + kernelRadius);
% آخر صف صالح داخل البيئة

minimumColumn = max( ...
    1, ...
    probeColumn - kernelRadius);
% أول عمود صالح داخل البيئة

maximumColumn = min( ...
    numberOfColumns, ...
    probeColumn + kernelRadius);
% آخر عمود صالح داخل البيئة

if minimumRow > maximumRow || ...
        minimumColumn > maximumColumn

    probe.memory.localizationState = state;
    % إنهاء الدالة إذا كان موقع المسبار خارج حدود البيئة

    return;

end

%% ============================================================
% Build Gaussian Spatial Kernel
%% ============================================================

[rowGrid, columnGrid] = ndgrid( ...
    minimumRow:maximumRow, ...
    minimumColumn:maximumColumn);
% إنشاء إحداثيات المنطقة المحلية دفعة واحدة

distanceSquared = ...
    (rowGrid - probeRow).^2 + ...
    (columnGrid - probeColumn).^2;
% حساب مربع المسافة عن موقع المسبار

spatialKernel = exp( ...
    -distanceSquared ./ ...
    (2 * gaussianSigma^2));
% حساب الأوزان المكانية باستخدام Gaussian Kernel

spatialKernel( ...
    distanceSquared > kernelRadius^2) = 0;
% منع نشر الدليل خارج نصف القطر المحدد

measurementWeight = ...
    measurementConfidence .* spatialKernel;
% دمج الثقة مع الوزن المكاني للقياس

%% ============================================================
% Accumulate Spatial Evidence
%% ============================================================

rowIndices = minimumRow:maximumRow;
% الصفوف التي ستتأثر بالقياس

columnIndices = minimumColumn:maximumColumn;
% الأعمدة التي ستتأثر بالقياس

state.evidenceSum( ...
    rowIndices, ...
    columnIndices) = ...
    state.evidenceSum( ...
        rowIndices, ...
        columnIndices) + ...
    fusionScore .* measurementWeight;
% إضافة الدليل الحالي إلى الأدلة المتراكمة

state.weightSum( ...
    rowIndices, ...
    columnIndices) = ...
    state.weightSum( ...
        rowIndices, ...
        columnIndices) + ...
    measurementWeight;
% إضافة وزن القياس إلى مجموع الأوزان

state.observationCount( ...
    rowIndices, ...
    columnIndices) = ...
    state.observationCount( ...
        rowIndices, ...
        columnIndices) + ...
    double(spatialKernel > 0);
% زيادة عدد المشاهدات في الخلايا المتأثرة

%% ============================================================
% Normalize Evidence Map
%% ============================================================

localEvidenceSum = state.evidenceSum( ...
    rowIndices, ...
    columnIndices);
% قراءة مجموع الأدلة في المنطقة المحلية

localWeightSum = state.weightSum( ...
    rowIndices, ...
    columnIndices);
% قراءة مجموع الأوزان في المنطقة المحلية

normalizedEvidence = ...
    localEvidenceSum ./ ...
    max(localWeightSum, eps);
% حساب متوسط الأدلة الموزون لمنع تضخم الخلايا المتكررة

normalizedEvidence = max( ...
    0, ...
    min(1, normalizedEvidence));
% حصر قيم خريطة الأدلة بين صفر وواحد

state.evidenceMap( ...
    rowIndices, ...
    columnIndices) = ...
    normalizedEvidence;
% تحديث الجزء المتأثر فقط بدل إعادة حساب الخريطة كاملة

%% ============================================================
% Save Measurement History
%% ============================================================

state.pointHistory(end+1,:) = ...
    [probeRow, probeColumn];
% حفظ موقع القياس حتى يمكن حساب الثبات الزمني
% من قراءات متقاربة مكانيًا بدل خلط مواقع مختلفة

state.scoreHistory(end+1,1) = ...
    fusionScore;
% حفظ نتيجة الدمج الحالية بنفس فهرس الموقع

state.confidenceHistory(end+1,1) = ...
    measurementConfidence;
% حفظ درجة الثقة الحالية بنفس فهرس الموقع والنتيجة

%% ============================================================
% Persist Updated Localization State
%% ============================================================

probe.memory.localizationState = state;
% إعادة الحالة المحدّثة إلى ذاكرة المسبار.
% بنية struct في MATLAB تُمرر بالقيمة، ولذلك لا يكفي تعديل
% المتغير المحلي state دون إسناده مرة أخرى إلى probe.

end
