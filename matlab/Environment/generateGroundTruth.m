function groundTruth = generateGroundTruth(scenario)
%% ============================================================
% Function Name : generateGroundTruth
%
% Description :
% إنشاء بيانات الحقيقة المرجعية Ground Truth للضحايا.
% هذه البيانات تمثل القيم الحقيقية التي سنقارن معها نتائج النظام لاحقاً.
%
% Outputs :
% groundTruth -> يحتوي مواقع الضحايا وخصائصهم الحقيقية
%% ============================================================

numVictims = size(scenario.victims, 1); % حساب عدد الضحايا الفعليين

groundTruth = struct(); % إنشاء هيكل لتخزين بيانات الحقيقة المرجعية

groundTruth.numVictims = numVictims; % تخزين عدد الضحايا

groundTruth.locations = scenario.victims; % تخزين المواقع الحقيقية للضحايا

groundTruth.vitalStrength = zeros(numVictims, 1); % إنشاء مصفوفة لقوة العلامات الحيوية لكل ضحية

groundTruth.burialDepth = zeros(numVictims, 1); % إنشاء مصفوفة لعمق الدفن لكل ضحية

groundTruth.accessibility = zeros(numVictims, 1); % إنشاء مصفوفة لسهولة الوصول لكل ضحية

groundTruth.riskLevel = zeros(numVictims, 1); % إنشاء مصفوفة لمستوى الخطورة عند موقع كل ضحية

for i = 1:numVictims % المرور على كل ضحية

    r = scenario.victims(i,1); % صف الضحية

    c = scenario.victims(i,2); % عمود الضحية

    groundTruth.vitalStrength(i) = max(0, min(1, ...
        scenario.vitalStrength + 0.1*randn())); % توليد قوة حيوية قريبة من إعداد السيناريو

    groundTruth.burialDepth(i) = max(0, min(1, ...
        scenario.burialDepth + 0.1*randn())); % توليد عمق دفن قريب من إعداد السيناريو

    groundTruth.accessibility(i) = scenario.environment.accessibility(r,c); % أخذ سهولة الوصول من خريطة الوصول

    groundTruth.riskLevel(i) = scenario.environment.risk(r,c); % أخذ مستوى الخطورة من خريطة الخطورة

end

groundTruth.isAlive = groundTruth.vitalStrength > 0.15; % تحديد هل الضحية حية بناءً على قوة العلامات الحيوية

end