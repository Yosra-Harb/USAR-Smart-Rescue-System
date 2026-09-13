function processedPacket = signalProcessingManager(measurementPacket)
%% ============================================================
% Function Name : signalProcessingManager
%
% Description :
% مدير طبقة معالجة الإشارات.
% يستقبل Measurement Packet من طبقة الحساسات،
% ثم يمرره على مراحل فحص الجودة، إزالة القيم الشاذة،
% التحقق من سلامة القياسات، استخراج الخصائص،
% ثم بناء حزمة معالجة موحدة لاستخدامها في Fusion Layer.
%% ============================================================

qualityReport = signalQualityCheck(measurementPacket); % فحص جودة القياسات القادمة من طبقة الحساسات

cleanPacket = removeOutliers(measurementPacket); % إزالة أو تصحيح القيم الشاذة إن وجدت

validatedPacket = measurementValidation(cleanPacket); % التحقق من سلامة واتساق القياسات بعد التنظيف

features = featureExtraction(validatedPacket); % استخراج الخصائص المطلوبة للدمج التكيفي لاحقًا

processedPacket = buildProcessedMeasurementPacket( ...
    validatedPacket, ...
    features, ...
    qualityReport); % بناء حزمة معالجة موحدة لإرسالها إلى Fusion Layer

end