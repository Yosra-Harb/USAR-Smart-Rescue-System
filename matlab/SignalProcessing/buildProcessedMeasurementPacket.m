function processedPacket = buildProcessedMeasurementPacket(validatedPacket, features, qualityReport)
%% ============================================================
% Function Name : buildProcessedMeasurementPacket
%
% Description :
% بناء حزمة معالجة موحدة تحتوي على القياسات بعد الفحص،
% الخصائص المستخرجة، وتقرير جودة القياسات.
% هذه الحزمة ستكون مدخلًا لطبقة Adaptive Fusion لاحقًا.
%% ============================================================

processedPacket = struct(); % إنشاء هيكل الحزمة المعالجة

processedPacket.radar = validatedPacket.radar; % قراءة الرادار بعد التحقق

processedPacket.thermal = validatedPacket.thermal; % قراءة الحساس الحراري بعد التحقق

processedPacket.acoustic = validatedPacket.acoustic; % قراءة الحساس الصوتي بعد التحقق

processedPacket.features = features; % تخزين الخصائص المستخرجة

processedPacket.qualityReport = qualityReport; % تخزين تقرير الجودة

processedPacket.timestamp = validatedPacket.timestamp; % الاحتفاظ بزمن القياس الأصلي

processedPacket.probePosition = validatedPacket.probePosition; % الاحتفاظ بموقع المسبار وقت القياس

if isfield(validatedPacket, 'probeHeadingDegrees')
    processedPacket.probeHeadingDegrees = ...
        validatedPacket.probeHeadingDegrees;
else
    processedPacket.probeHeadingDegrees = 0;
end

if isfield(validatedPacket, 'spatialObservations')
    processedPacket.spatialObservations = ...
        validatedPacket.spatialObservations;
else
    processedPacket.spatialObservations = struct( ...
        'radar', sanitizeSpatialObservationSet(struct([])), ...
        'thermal', sanitizeSpatialObservationSet(struct([])), ...
        'acoustic', sanitizeSpatialObservationSet(struct([])));
end

processedPacket.status = validatedPacket.status; % حالة الحزمة بعد التحقق

end
