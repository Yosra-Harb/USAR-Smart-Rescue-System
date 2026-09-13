function weights = calculateAdaptiveWeights(processedPacket)
%% ============================================================
% Function Name : calculateAdaptiveWeights
%
% Description :
% حساب الأوزان التكيفية للحساسات اعتمادًا على:
%
% 1- موثوقية كل حساس.
% 2- اتفاق قراءته مع الوسيط القوي للقراءات.
% 3- تخفيض وزن الحساس الشاذ تدريجيًا.
%
% مجموع الأوزان النهائية يساوي واحدًا دائمًا.
%% ============================================================

%% ============================================================
% Read Sensor Features
%% ============================================================

sensorValues = [ ...
    processedPacket.features.radarFeature, ...
    processedPacket.features.thermalFeature, ...
    processedPacket.features.acousticFeature];
% تجميع قراءات الحساسات

sensorValues = max( ...
    0, ...
    min(1, sensorValues));
% حصر القراءات بين صفر وواحد

sensorValues(~isfinite(sensorValues)) = 0;
% استبدال القيم غير الصالحة بصفر

%% ============================================================
% Read Sensor Reliabilities
%% ============================================================

sensorReliabilities = [ ...
    processedPacket.qualityReport.radarReliability, ...
    processedPacket.qualityReport.thermalReliability, ...
    processedPacket.qualityReport.acousticReliability];
% قراءة موثوقية كل حساس

sensorReliabilities = max( ...
    0, ...
    min(1, sensorReliabilities));
% حصر الموثوقيات بين صفر وواحد

sensorReliabilities( ...
    ~isfinite(sensorReliabilities)) = 0;
% استبدال الموثوقيات غير الصالحة بصفر

%% ============================================================
% Robust Sensor Consensus
%% ============================================================

sensorConsensus = median(sensorValues);
% استخدام الوسيط لتقليل تأثير الحساس الشاذ

sensorDeviations = abs( ...
    sensorValues - sensorConsensus);
% حساب انحراف كل حساس عن الوسيط

medianAbsoluteDeviation = ...
    median(sensorDeviations);
% حساب الانحراف الوسيط المطلق

minimumRobustScale = 0.05;
% منع مقياس الانتشار من الوصول إلى صفر

robustScale = max( ...
    1.4826 * medianAbsoluteDeviation, ...
    minimumRobustScale);
% حساب مقياس انتشار قوي

normalizedDeviations = ...
    sensorDeviations ./ robustScale;
% تطبيع انحرافات الحساسات

%% ============================================================
% Individual Sensor Agreement
%% ============================================================

individualAgreement = ...
    1 ./ (1 + normalizedDeviations.^2);
% استخدام وزن Cauchy لتخفيض تأثير القراءة الشاذة

minimumAgreementWeight = 0.10;
% عدم إلغاء أي حساس بصورة كاملة

individualAgreement = ...
    minimumAgreementWeight + ...
    (1 - minimumAgreementWeight) .* ...
    individualAgreement;
% ضمان حد أدنى لمساهمة كل حساس

%% ============================================================
% Calculate Raw Adaptive Weights
%% ============================================================

rawWeights = ...
    sensorReliabilities .* individualAgreement;
% دمج الموثوقية مع اتفاق كل حساس

rawWeights(~isfinite(rawWeights)) = 0;
% إزالة القيم غير الصالحة

totalWeight = sum(rawWeights);
% حساب مجموع الأوزان الأولية

%% ============================================================
% Normalize Adaptive Weights
%% ============================================================

if totalWeight <= eps

    normalizedWeights = ...
        [1/3, 1/3, 1/3];
    % الرجوع إلى أوزان متساوية إذا غابت الموثوقية

else

    normalizedWeights = ...
        rawWeights ./ totalWeight;
    % جعل مجموع الأوزان مساويًا لواحد

end

%% ============================================================
% Build Output Structure
%% ============================================================

weights = struct();

weights.radar = ...
    normalizedWeights(1);
% وزن حساس الرادار

weights.thermal = ...
    normalizedWeights(2);
% وزن الحساس الحراري

weights.acoustic = ...
    normalizedWeights(3);
% وزن الحساس الصوتي

end