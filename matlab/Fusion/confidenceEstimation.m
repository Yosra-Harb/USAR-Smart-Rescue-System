function confidence = confidenceEstimation( ...
    processedPacket, ...
    weights, ...
    fusionScore)
%% ============================================================
% Function Name : confidenceEstimation
%
% Description :
% حساب الثقة في الدمج التكيفي باستخدام:
% 1- الموثوقية الموزونة للحساسات.
% 2- الاتفاق الموزون بين قراءات الحساسات.
% 3- الجودة العامة للقياس.
%
% لا تستخدم الدالة sensorAgreement القديم، ولا تعاقب
% اختلاف الأوزان؛ لأن اختلافها مطلوب في الدمج التكيفي.
%% ============================================================

%% Read Sensor Features

sensorValues = [ ...
    processedPacket.features.radarFeature, ...
    processedPacket.features.thermalFeature, ...
    processedPacket.features.acousticFeature];
% قراءة الخصائص المستخرجة من الحساسات

sensorValues = max(0, min(1, sensorValues));
% حصر القراءات بين صفر وواحد

sensorValues(~isfinite(sensorValues)) = 0;
% إزالة القيم غير الصالحة

%% Read Sensor Reliabilities

sensorReliabilities = [ ...
    processedPacket.qualityReport.radarReliability, ...
    processedPacket.qualityReport.thermalReliability, ...
    processedPacket.qualityReport.acousticReliability];
% قراءة موثوقية كل حساس

sensorReliabilities = ...
    max(0, min(1, sensorReliabilities));
% حصر الموثوقيات بين صفر وواحد

sensorReliabilities( ...
    ~isfinite(sensorReliabilities)) = 0;
% إزالة القيم غير الصالحة

%% Read and Normalize Adaptive Weights

weightVector = [ ...
    weights.radar, ...
    weights.thermal, ...
    weights.acoustic];
% تجميع الأوزان التكيفية

weightVector( ...
    ~isfinite(weightVector) | ...
    weightVector < 0) = 0;
% إزالة الأوزان غير الصالحة

totalWeight = sum(weightVector);
% حساب مجموع الأوزان

if totalWeight <= eps

    weightVector = [1/3, 1/3, 1/3];
    % استخدام أوزان متساوية عند غياب أوزان صالحة

else

    weightVector = weightVector ./ totalWeight;
    % ضمان أن مجموع الأوزان يساوي واحدًا

end

%% Calculate Weighted Reliability

weightedReliability = sum( ...
    weightVector .* sensorReliabilities);
% إعطاء الحساس الأعلى وزنًا تأثيرًا أكبر في الثقة

weightedReliability = ...
    max(0, min(1, weightedReliability));
% حصر الموثوقية الموزونة

%% Calculate Weighted Agreement

fusionScore = max(0, min(1, fusionScore));
% حصر نتيجة الدمج بين صفر وواحد

weightedVariance = sum( ...
    weightVector .* ...
    (sensorValues - fusionScore).^2);
% حساب الاختلاف الموزون حول نتيجة الدمج

weightedDeviation = sqrt( ...
    max(0, weightedVariance));
% حساب الانحراف الموزون

agreementScale = 0.25;
% تحديد مقدار الاختلاف المقبول

weightedAgreement = exp( ...
    -0.5 * ...
    (weightedDeviation / agreementScale)^2);
% تحويل الاختلاف إلى درجة اتفاق بين صفر وواحد

weightedAgreement = ...
    max(0, min(1, weightedAgreement));
% حصر درجة الاتفاق

%% Read Overall Quality

overallQuality = ...
    processedPacket.qualityReport.overallQuality;
% قراءة الجودة العامة لحزمة القياس

if ~isfinite(overallQuality)

    overallQuality = 0;
    % استبدال القيمة غير الصالحة بصفر

end

overallQuality = max(0, min(1, overallQuality));
% حصر الجودة بين صفر وواحد

%% Calculate Final Confidence

confidence = ...
    0.65 * weightedReliability + ...
    0.25 * weightedAgreement + ...
    0.10 * overallQuality;
% حساب الثقة النهائية دون تكرار عقوبة Fusion Score

confidence = max(0, min(1, confidence));
% ضمان بقاء الثقة بين صفر وواحد

end