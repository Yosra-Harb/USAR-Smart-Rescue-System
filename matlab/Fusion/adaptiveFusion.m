function fusionScore = adaptiveFusion(processedPacket, weights)
%% ============================================================
% Function Name : adaptiveFusion
%
% Description :
% تنفيذ عملية الدمج التكيفي بين قراءات الحساسات الثلاثة.
% يتم حساب Fusion Score كمتوسط موزون اعتمادًا على الأوزان
% القادمة من calculateAdaptiveWeights.
%% ============================================================

radarFeature = processedPacket.features.radarFeature; % قراءة/خاصية الرادار بعد المعالجة

thermalFeature = processedPacket.features.thermalFeature; % قراءة/خاصية الحساس الحراري بعد المعالجة

acousticFeature = processedPacket.features.acousticFeature; % قراءة/خاصية الحساس الصوتي بعد المعالجة

fusionScore = ...
    weights.radar * radarFeature + ...
    weights.thermal * thermalFeature + ...
    weights.acoustic * acousticFeature; % حساب قيمة الدمج الموزونة

fusionScore = max(0, min(1, fusionScore)); % حصر نتيجة الدمج بين 0 و1

end