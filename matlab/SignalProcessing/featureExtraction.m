function features = featureExtraction(validatedPacket)
%% ============================================================
% Function Name : featureExtraction
%
% Description :
% استخراج خصائص أولية من حزمة القياسات.
% هذه الخصائص ستستخدم لاحقًا في Adaptive Fusion وقرار الاشتباه.
%% ============================================================

features = struct(); % إنشاء هيكل الخصائص

features.radarFeature = validatedPacket.radar; % خاصية الرادار المعيارية

features.thermalFeature = validatedPacket.thermal; % خاصية الحساس الحراري المعيارية

features.acousticFeature = validatedPacket.acoustic; % خاصية الحساس الصوتي المعيارية

features.meanResponse = mean([ ...
    validatedPacket.radar, ...
    validatedPacket.thermal, ...
    validatedPacket.acoustic]); % متوسط استجابة الحساسات الثلاثة

features.maxResponse = max([ ...
    validatedPacket.radar, ...
    validatedPacket.thermal, ...
    validatedPacket.acoustic]); % أعلى استجابة بين الحساسات

features.sensorAgreement = 1 - std([ ...
    validatedPacket.radar, ...
    validatedPacket.thermal, ...
    validatedPacket.acoustic]); % درجة اتفاق الحساسات؛ تقل عندما تختلف القراءات كثيرًا

features.sensorAgreement = max(0, min(1, features.sensorAgreement)); % حصر درجة الاتفاق بين 0 و1

features.spatialObservationCount = 0;
features.meanSpatialConfidence = 0;
if isfield(validatedPacket, 'spatialObservations') && ...
        isstruct(validatedPacket.spatialObservations)
    sensorNames = {'radar', 'thermal', 'acoustic'};
    confidences = zeros(0,1);
    for sensorIndex = 1:numel(sensorNames)
        name = sensorNames{sensorIndex};
        if isfield(validatedPacket.spatialObservations, name)
            observations = validatedPacket.spatialObservations.(name);
            features.spatialObservationCount = ...
                features.spatialObservationCount + numel(observations);
            if ~isempty(observations)
                confidences = [confidences; ...
                    [observations.confidence]']; %#ok<AGROW>
            end
        end
    end
    if ~isempty(confidences)
        features.meanSpatialConfidence = mean(confidences);
    end
end

end
