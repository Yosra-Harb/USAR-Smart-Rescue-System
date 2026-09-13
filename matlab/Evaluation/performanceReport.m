function performanceReport( ...
    metrics, ...
    localizationErrorValue, ...
    priorityResult)
%% ============================================================
% Function Name : performanceReport
%
% Description :
% عرض تقرير أداء علمي واضح لاكتشاف الضحايا وتحديد مواقعهم.
%
% يعرض التقرير المقاييس المناسبة لتقييم اكتشاف المواقع،
% ويتجنب عرض Accuracy أو False Alarm Rate عندما لا يكون
% عدد True Negatives معرفًا.
%% ============================================================

disp(' ');
disp('========== PERFORMANCE REPORT ==========');

%% ============================================================
% Detection Counts
%% ============================================================

fprintf( ...
    'Ground Truth Victims       : %d\n', ...
    metrics.numberOfGroundTruthVictims);
% عدد الضحايا الحقيقيين في السيناريو

fprintf( ...
    'System Detections          : %d\n', ...
    metrics.numberOfDetections);
% عدد المواقع التي سجلها النظام كضحايا

fprintf( ...
    'True Positives             : %d\n', ...
    metrics.TP);
% عدد الضحايا المكتشفين بصورة صحيحة

fprintf( ...
    'False Positives            : %d\n', ...
    metrics.FP);
% عدد الاكتشافات التي لا تقابل ضحية حقيقية

fprintf( ...
    'False Negatives            : %d\n', ...
    metrics.FN);
% عدد الضحايا الذين لم يكتشفهم النظام

%% ============================================================
% Object-Detection Metrics
%% ============================================================

fprintf( ...
    'Critical Success Index     : %.4f\n', ...
    metrics.criticalSuccessIndex);
% مؤشر النجاح دون الاعتماد على True Negatives

fprintf( ...
    'Precision                  : %.4f\n', ...
    metrics.precision);
% نسبة الاكتشافات الصحيحة من اكتشافات النظام

fprintf( ...
    'Recall                     : %.4f\n', ...
    metrics.recall);
% نسبة الضحايا الحقيقيين الذين تم اكتشافهم

fprintf( ...
    'F1 Score                   : %.4f\n', ...
    metrics.f1);
% التوازن بين Precision وRecall

fprintf( ...
    'False Discovery Rate       : %.4f\n', ...
    metrics.falseDiscoveryRate);
% نسبة الاكتشافات الكاذبة من جميع اكتشافات النظام

fprintf( ...
    'False Negative Rate        : %.4f\n', ...
    metrics.falseNegativeRate);
% نسبة الضحايا التي لم يكتشفها النظام

fprintf( ...
    'False Alarms Per Mission   : %d\n', ...
    metrics.falseAlarmsPerMission);
% العدد الفعلي للإنذارات الكاذبة خلال المهمة

%% ============================================================
% Conventional Metrics
%% ============================================================

if isnan(metrics.falseAlarmRate)

    disp( ...
        'Conventional FAR          : N/A (TN is undefined)');
    % عدم عرض قيمة مضللة عندما لا يوجد تعريف لـTrue Negatives

else

    fprintf( ...
        'Conventional FAR          : %.4f\n', ...
        metrics.falseAlarmRate);
    % عرض FAR فقط عندما تكون الحالات السلبية معروفة

end

if isnan(metrics.conventionalAccuracy)

    disp( ...
        'Conventional Accuracy     : N/A (TN is undefined)');
    % Accuracy التقليدية غير صالحة دون True Negatives

else

    fprintf( ...
        'Conventional Accuracy     : %.4f\n', ...
        metrics.conventionalAccuracy);
    % عرض Accuracy عند توفر الحالات السلبية

end

%% ============================================================
% Localization Performance
%% ============================================================

fprintf( ...
    'Localization Error          : %.4f\n', ...
    localizationErrorValue);
% عرض متوسط خطأ تحديد الموقع

%% ============================================================
% Priority Performance
%% ============================================================

fprintf( ...
    'Mean Priority               : %.5f\n', ...
    priorityResult.meanPriority);
% متوسط درجات الأولوية

fprintf( ...
    'Maximum Priority            : %.5f\n', ...
    priorityResult.maxPriority);
% أعلى درجة أولوية

fprintf( ...
    'Minimum Priority            : %.5f\n', ...
    priorityResult.minPriority);
% أقل درجة أولوية

disp('========================================');

end