function vitalityPacket = vitalityManager(localizationPacket, fusionPacket, probe)
%% ============================================================
% Function Name : vitalityManager
%
% Description :
% مدير طبقة تقييم حيوية الضحية.
% يستقبل Localization Packet و Fusion Packet،
% ثم يحسب:
% 1- الثبات الزمني للمؤشرات.
% 2- مؤشر الحيوية.
% 3- تصنيف حالة الضحية.
% 4- بناء Vitality Packet.
%% ============================================================

temporalStability = calculateTemporalStability( ...
    probe, ...
    localizationPacket);
% تمرير نتيجة التوطين الحالية يسمح لمسار v4 بقياس الثبات من
% المسار البايزي المرتبط بدل الاعتماد على تاريخ خريطة v2 القديمة.

vitalityIndex = calculateVitalityIndex( ...
    fusionPacket, ...
    localizationPacket, ...
    temporalStability);

victimCondition = estimateVictimCondition(vitalityIndex);

vitalityPacket = buildVitalityPacket( ...
    localizationPacket, ...
    fusionPacket, ...
    temporalStability, ...
    vitalityIndex, ...
    victimCondition);

end
