function cleanPacket = removeOutliers(measurementPacket)
%% ============================================================
% Function Name : removeOutliers
%
% Description :
% إزالة أو تصحيح القيم الشاذة في قراءات الحساسات.
% بما أن القراءات المعيارية يجب أن تكون بين 0 و 1،
% يتم قص أي قيمة خارج هذا المجال.
%% ============================================================

cleanPacket = measurementPacket; % إنشاء نسخة من حزمة القياسات للحفاظ على الأصل

cleanPacket.radar = max(0, min(1, measurementPacket.radar)); % تصحيح قراءة الرادار إذا خرجت عن المجال

cleanPacket.thermal = max(0, min(1, measurementPacket.thermal)); % تصحيح قراءة الحساس الحراري إذا خرجت عن المجال

cleanPacket.acoustic = max(0, min(1, measurementPacket.acoustic)); % تصحيح قراءة الحساس الصوتي إذا خرجت عن المجال

if isfield(measurementPacket, 'spatialObservations') && ...
        isstruct(measurementPacket.spatialObservations)
    sensorNames = {'radar', 'thermal', 'acoustic'};
    cleanPacket.spatialObservations = struct();
    for sensorIndex = 1:numel(sensorNames)
        name = sensorNames{sensorIndex};
        if isfield(measurementPacket.spatialObservations, name)
            cleanPacket.spatialObservations.(name) = ...
                sanitizeSpatialObservationSet( ...
                    measurementPacket.spatialObservations.(name));
        else
            cleanPacket.spatialObservations.(name) = ...
                sanitizeSpatialObservationSet(struct([]));
        end
    end
end

end
