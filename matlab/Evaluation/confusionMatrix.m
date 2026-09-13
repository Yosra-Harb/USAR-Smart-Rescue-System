function [TP, TN, FP, FN, matchedDistances, matchedPairs] = ...
    confusionMatrix( ...
        detectedVictims, ...
        groundTruth)
%% ============================================================
% Function Name : confusionMatrix
%
% Description :
% تنفيذ مطابقة مكانية واحد إلى واحد بين المواقع المكتشفة
% ومواقع الضحايا الحقيقية.
%
% لا يسمح باستخدام الاكتشاف نفسه لأكثر من ضحية،
% ولا يسمح باستخدام الضحية الحقيقية لأكثر من اكتشاف.
%
% Outputs:
% TP               : الاكتشافات الصحيحة
% TN               : الحالات السلبية الصحيحة عندما تكون معرفة
% FP               : الاكتشافات الكاذبة
% FN               : الضحايا غير المكتشفين
% matchedDistances : مسافة كل زوج متطابق
% matchedPairs     : أرقام الاكتشافات والضحايا المتطابقة
%% ============================================================

%% ============================================================
% Initialize Outputs
%% ============================================================

TP = 0;
% عدد الاكتشافات الصحيحة

TN = 0;
% عدد الحالات السلبية الصحيحة

FP = 0;
% عدد الاكتشافات الكاذبة

FN = 0;
% عدد الضحايا غير المكتشفين

matchedDistances = zeros(0,1);
% تخزين مسافات الأزواج المقبولة

matchedPairs = zeros(0,2);
% العمود الأول رقم الاكتشاف والثاني رقم الضحية الحقيقية

config = constants();
% قراءة مسافة المطابقة من الإعدادات المركزية

matchingDistance = ...
    config.evaluation.matchingDistance;
% أكبر مسافة تسمح باعتبار الاكتشاف صحيحًا

%% ============================================================
% Validate Inputs
%% ============================================================

if isempty(detectedVictims)

    detectedVictims = zeros(0,2);
    % تمثيل عدم وجود اكتشافات بمصفوفة صحيحة الحجم

end

if isempty(groundTruth)

    groundTruth = zeros(0,2);
    % تمثيل عدم وجود ضحايا بمصفوفة صحيحة الحجم

end

if size(detectedVictims,2) < 2 || ...
        size(groundTruth,2) < 2

    error( ...
        "confusionMatrix:InvalidPositionMatrix", ...
        "Position matrices must contain at least two columns.");
    % رفض مصفوفات المواقع غير الصالحة

end

detectedVictims = detectedVictims(:,1:2);
% استخدام إحداثيي الصف والعمود فقط

groundTruth = groundTruth(:,1:2);
% استخدام إحداثيي الصف والعمود فقط

numberOfDetections = size(detectedVictims,1);
% عدد اكتشافات النظام

numberOfVictims = size(groundTruth,1);
% عدد الضحايا الحقيقيين

%% ============================================================
% Handle Empty Cases
%% ============================================================

if numberOfVictims == 0

    FP = numberOfDetections;
    % كل اكتشاف يكون كاذبًا عند عدم وجود ضحايا

    if numberOfDetections == 0
        TN = 1;
        % المهمة الخالية دون إنذارات تمثل حالة سلبية صحيحة
    end

    return;

end

if numberOfDetections == 0

    FN = numberOfVictims;
    % جميع الضحايا الحقيقيين غير مكتشفين

    return;

end

%% ============================================================
% Build Distance Matrix
%% ============================================================

distanceMatrix = ...
    inf(numberOfDetections, numberOfVictims);
% إنشاء مصفوفة مسافة بين كل اكتشاف وكل ضحية

for detectionIndex = 1:numberOfDetections

    coordinateDifference = ...
        groundTruth - ...
        detectedVictims(detectionIndex,:);
    % حساب فرق الإحداثيات بين الاكتشاف وجميع الضحايا

    distanceMatrix(detectionIndex,:) = ...
        sqrt(sum(coordinateDifference.^2,2));
    % حساب المسافات الإقليدية دفعة واحدة

end

%% ============================================================
% One-to-One Spatial Matching
%% ============================================================

while true

    [minimumDistance, linearIndex] = ...
        min(distanceMatrix(:));
    % البحث عن أقرب زوج متبقٍ

    if isempty(minimumDistance) || ...
            ~isfinite(minimumDistance) || ...
            minimumDistance > matchingDistance

        break;
        % إنهاء المطابقة عند عدم وجود زوج صالح

    end

    [detectionIndex, victimIndex] = ...
        ind2sub( ...
            size(distanceMatrix), ...
            linearIndex);
    % استخراج رقم الاكتشاف ورقم الضحية

    TP = TP + 1;
    % تسجيل اكتشاف صحيح

    matchedDistances(end+1,1) = ...
        minimumDistance;
    % حفظ خطأ الموقع للزوج المتطابق

    matchedPairs(end+1,:) = ...
        [detectionIndex, victimIndex];
    % حفظ أرقام الزوج المتطابق

    distanceMatrix(detectionIndex,:) = Inf;
    % منع استخدام الاكتشاف نفسه مرة أخرى

    distanceMatrix(:,victimIndex) = Inf;
    % منع استخدام الضحية نفسها مرة أخرى

end

%% ============================================================
% Calculate Remaining Errors
%% ============================================================

FP = numberOfDetections - TP;
% الاكتشافات التي لم تتطابق هي False Positives

FN = numberOfVictims - TP;
% الضحايا التي لم تتطابق هي False Negatives

end