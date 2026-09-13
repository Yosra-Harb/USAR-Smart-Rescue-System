function victimCondition = estimateVictimCondition(vitalityIndex)
%% ============================================================
% Function Name : estimateVictimCondition
%
% Description :
% تصنيف حالة الضحية اعتمادًا على مؤشر الحيوية.
%% ============================================================

if vitalityIndex < 0.30

    victimCondition = "WEAK";

elseif vitalityIndex < 0.60

    victimCondition = "MODERATE";

elseif vitalityIndex < 0.80

    victimCondition = "STRONG";

else

    victimCondition = "VERY_STRONG";

end

end