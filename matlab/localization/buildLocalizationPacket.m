function localizationPacket = buildLocalizationPacket( ...
    fusionPacket, ...
    candidate, ...
    estimatedLocation)
%% ============================================================
% Function Name : buildLocalizationPacket
%
% Description :
% بناء حزمة تحديد الموقع النهائية.
%% ============================================================

localizationPacket = struct();

localizationPacket.isVictimDetected = ...
    estimatedLocation.isDetected; % حالة اكتشاف الضحية

localizationPacket.estimatedPosition = ...
    estimatedLocation.position; % الموقع التقديري للضحية

localizationPacket.localizationConfidence = ...
    estimatedLocation.confidence; % ثقة تحديد الموقع

if isfield(estimatedLocation,'sourceType')
    localizationPacket.sourceType = ...
        string(estimatedLocation.sourceType);
else
    localizationPacket.sourceType = "UNKNOWN";
end
%% ============================================================
% Multi-Peak Diagnostic Information
%% ============================================================

if isfield( ...
        estimatedLocation, ...
        'candidatePeakCount')

    localizationPacket.candidatePeakCount = ...
        estimatedLocation.candidatePeakCount;

else

    localizationPacket.candidatePeakCount = 0;
    % توافق مع نتائج التوطين القديمة

end

if isfield( ...
        estimatedLocation, ...
        'selectionScore')

    localizationPacket.peakSelectionScore = ...
        estimatedLocation.selectionScore;

else

    localizationPacket.peakSelectionScore = 0;
    % توافق مع نتائج التوطين القديمة

end

if isfield(estimatedLocation,'candidatePositions')
    localizationPacket.candidatePositions = ...
        estimatedLocation.candidatePositions;
else
    localizationPacket.candidatePositions = zeros(0,2);
end

if isfield(estimatedLocation,'candidateConfidences')
    localizationPacket.candidateConfidences = ...
        estimatedLocation.candidateConfidences;
else
    localizationPacket.candidateConfidences = zeros(0,1);
end

if isfield(estimatedLocation,'candidateSourceTypes')
    localizationPacket.candidateSourceTypes = ...
        estimatedLocation.candidateSourceTypes;
else
    localizationPacket.candidateSourceTypes = strings(0,1);
end
localizationPacket.fusionScore = ...
    fusionPacket.fusionScore; % حفظ نتيجة الدمج

localizationPacket.fusionConfidence = ...
    fusionPacket.confidence; % حفظ ثقة الدمج

localizationPacket.probePosition = ...
    fusionPacket.probePosition; % حفظ موقع المسبار

localizationPacket.timestamp = ...
    fusionPacket.timestamp; % حفظ الزمن

localizationPacket.status = ...
    fusionPacket.status; % حفظ حالة الحزمة

end
