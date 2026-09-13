function qualityReport = signalQualityCheck(measurementPacket)
%% ============================================================
% Function Name : signalQualityCheck
%
% Description :
% فحص جودة حزمة القياسات القادمة من طبقة الحساسات.
% يتحقق من حالة الحزمة، موثوقية الحساسات، واكتمال القيم الأساسية.
%% ============================================================

qualityReport = struct(); % إنشاء هيكل تقرير الجودة

qualityReport.packetStatus = measurementPacket.status; % قراءة حالة حزمة القياسات

qualityReport.radarReliability = measurementPacket.radarReliability; % موثوقية الرادار

qualityReport.thermalReliability = measurementPacket.thermalReliability; % موثوقية الحساس الحراري

qualityReport.acousticReliability = measurementPacket.acousticReliability; % موثوقية الحساس الصوتي

qualityReport.overallQuality = measurementPacket.quality; % الجودة العامة للحزمة

qualityReport.isComplete = ...
    isfield(measurementPacket, "radar") && ...
    isfield(measurementPacket, "thermal") && ...
    isfield(measurementPacket, "acoustic"); % التحقق من وجود القراءات الأساسية

qualityReport.isReliable = qualityReport.overallQuality >= 0.4; % تحديد هل الحزمة موثوقة مبدئياً

if qualityReport.isComplete && qualityReport.isReliable
    qualityReport.status = "GOOD"; % الحزمة جيدة
elseif qualityReport.isComplete && ~qualityReport.isReliable
    qualityReport.status = "LOW_QUALITY"; % الحزمة مكتملة لكن جودتها منخفضة
else
    qualityReport.status = "INCOMPLETE"; % الحزمة غير مكتملة
end

end