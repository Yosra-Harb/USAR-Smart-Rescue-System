function validatedPacket = measurementValidation(cleanPacket)
%% ============================================================
% Function Name : measurementValidation
%
% Description :
% التحقق من سلامة حزمة القياسات بعد إزالة القيم الشاذة.
% هذه الدالة لا تعيد التطبيع، بل تتحقق فقط من:
% - عدم وجود NaN
% - عدم وجود Inf
% - بقاء القيم المعيارية داخل المجال [0, 1]
%% ============================================================

validatedPacket = cleanPacket; % إنشاء نسخة من الحزمة النظيفة

sensorValues = [ ...
    cleanPacket.radar, ...
    cleanPacket.thermal, ...
    cleanPacket.acoustic]; % تجميع القراءات المعيارية في مصفوفة واحدة للفحص

if any(isnan(sensorValues)) % التحقق من وجود قيم غير معرفة NaN
    validatedPacket.status = "INVALID_NAN"; % تحديث حالة الحزمة
    return; % الخروج لأن الحزمة غير صالحة
end

if any(isinf(sensorValues)) % التحقق من وجود قيم لا نهائية Inf
    validatedPacket.status = "INVALID_INF"; % تحديث حالة الحزمة
    return; % الخروج لأن الحزمة غير صالحة
end

if any(sensorValues < 0) || any(sensorValues > 1) % التحقق أن القيم داخل المجال الصحيح
    validatedPacket.status = "INVALID_RANGE"; % تحديث حالة الحزمة
    return; % الخروج لأن القيم خارج المجال
end

validatedPacket.status = "VALID"; % إذا نجحت جميع الفحوصات تعتبر الحزمة صالحة

if isfield(cleanPacket, 'probeHeadingDegrees') && ...
        (~isscalar(cleanPacket.probeHeadingDegrees) || ...
        ~isfinite(cleanPacket.probeHeadingDegrees))
    validatedPacket.status = "INVALID_HEADING";
end

end
