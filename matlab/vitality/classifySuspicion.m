function suspicion = classifySuspicion(vitalityIndex)
%% ============================================================
% Function Name : classifySuspicion
%
% Description :
% تحويل مؤشر الحيوية إلى مستوى الاشتباه.
%% ============================================================

if vitalityIndex < 0.30

    suspicion = "LOW";

elseif vitalityIndex < 0.60

    suspicion = "MEDIUM";

else

    suspicion = "HIGH";

end

end