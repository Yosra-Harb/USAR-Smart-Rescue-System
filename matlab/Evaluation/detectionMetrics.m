function metrics = detectionMetrics( ...
    TP, ...
    TN, ...
    FP, ...
    FN)
%% ============================================================
% Function Name : detectionMetrics
%
% Description :
% حساب مؤشرات أداء اكتشاف الضحايا.
%
% في تقييم اكتشاف الأجسام والمواقع لا يوجد تعريف مباشر
% لعدد True Negatives، لذلك تعتمد الدالة أساسًا على:
%
% Precision
% Recall
% F1 Score
% Critical Success Index
% False Discovery Rate
% False Negative Rate
% وعدد الإنذارات الكاذبة في المهمة
%% ============================================================

%% ============================================================
% Validate Inputs
%% ============================================================

TP = max(0, TP);
% عدد الضحايا الحقيقيين الذين اكتشفهم النظام

TN = max(0, TN);
% عدد الحالات السلبية الصحيحة إذا كان معرفًا

FP = max(0, FP);
% عدد الاكتشافات التي لا تقابل ضحية حقيقية

FN = max(0, FN);
% عدد الضحايا الحقيقيين الذين لم يكتشفهم النظام

%% ============================================================
% Precision
%% ============================================================

if TP + FP > 0

    precision = TP / (TP + FP);
    % نسبة الاكتشافات الصحيحة من جميع اكتشافات النظام

else

    precision = 0;
    % لا توجد اكتشافات يمكن تقييم دقتها

end

%% ============================================================
% Recall
%% ============================================================

if TP + FN > 0

    recall = TP / (TP + FN);
    % نسبة الضحايا الذين اكتشفهم النظام من الضحايا الحقيقيين

else

    recall = 0;
    % لا توجد ضحايا حقيقية يمكن حساب الاستدعاء لها

end

%% ============================================================
% F1 Score
%% ============================================================

if precision + recall > 0

    f1Score = ...
        2 * precision * recall / ...
        (precision + recall);
    % المتوسط التوافقي بين Precision وRecall

else

    f1Score = 0;
    % لا يوجد أداء كشف صالح لحساب F1

end

%% ============================================================
% Critical Success Index
%% ============================================================

if TP + FP + FN > 0

    criticalSuccessIndex = ...
        TP / (TP + FP + FN);
    % مقياس مناسب لتقييم اكتشاف الأحداث دون الاعتماد على TN

else

    criticalSuccessIndex = 1;
    % لا توجد ضحايا ولا اكتشافات خاطئة

end

%% ============================================================
% False Discovery Rate
%% ============================================================

if TP + FP > 0

    falseDiscoveryRate = ...
        FP / (TP + FP);
    % نسبة الاكتشافات الكاذبة من جميع اكتشافات النظام

else

    falseDiscoveryRate = 0;
    % لا توجد اكتشافات كاذبة عندما لا توجد اكتشافات

end

%% ============================================================
% False Negative Rate
%% ============================================================

if TP + FN > 0

    falseNegativeRate = ...
        FN / (TP + FN);
    % نسبة الضحايا التي أخفق النظام في اكتشافها

else

    falseNegativeRate = 0;
    % لا توجد ضحايا حقيقية فائتة

end

%% ============================================================
% Conventional False Alarm Rate
%% ============================================================

if TN > 0

    falseAlarmRate = ...
        FP / (FP + TN);
    % حساب FAR فقط عندما يكون عدد الحالات السلبية معرفًا

else

    falseAlarmRate = NaN;
    % FAR غير معرف في تقييم المواقع دون True Negatives

end

%% ============================================================
% Conventional Accuracy
%% ============================================================

totalClassifiedCases = ...
    TP + TN + FP + FN;
% مجموع حالات التقييم المتوفرة

if TN > 0 && totalClassifiedCases > 0

    conventionalAccuracy = ...
        (TP + TN) / totalClassifiedCases;
    % حساب Accuracy التقليدي عند توفر True Negatives

else

    conventionalAccuracy = NaN;
    % Accuracy التقليدية غير معرفة دون True Negatives

end

%% ============================================================
% Build Metrics Structure
%% ============================================================

metrics = struct();
% إنشاء حزمة مؤشرات الأداء

metrics.precision = precision;
% حفظ Precision

metrics.recall = recall;
% حفظ Recall

metrics.f1 = f1Score;
% حفظ F1 Score

metrics.criticalSuccessIndex = ...
    criticalSuccessIndex;
% حفظ مؤشر نجاح الاكتشاف

metrics.falseDiscoveryRate = ...
    falseDiscoveryRate;
% حفظ نسبة الاكتشافات الكاذبة

metrics.falseNegativeRate = ...
    falseNegativeRate;
% حفظ نسبة الضحايا الفائتة

metrics.falseAlarmRate = ...
    falseAlarmRate;
% حفظ FAR التقليدي أو NaN عندما لا يكون معرفًا

metrics.conventionalAccuracy = ...
    conventionalAccuracy;
% حفظ Accuracy التقليدية أو NaN

metrics.falseAlarmsPerMission = FP;
% حفظ عدد الإنذارات الكاذبة في المهمة

metrics.numberOfDetections = TP + FP;
% حفظ العدد الكلي لاكتشافات النظام

metrics.numberOfGroundTruthVictims = TP + FN;
% حفظ عدد الضحايا الحقيقيين

metrics.TP = TP;
% حفظ عدد True Positives

metrics.TN = TN;
% حفظ عدد True Negatives

metrics.FP = FP;
% حفظ عدد False Positives

metrics.FN = FN;
% حفظ عدد False Negatives

%% ============================================================
% Backward Compatibility
%% ============================================================

metrics.accuracy = criticalSuccessIndex;
% إبقاء الحقل القديم مؤقتًا لمنع تعطل الملفات الأخرى
% لكنه يمثل الآن Critical Success Index وليس Accuracy التقليدية

end