function [noiseSample, noiseStd, observableNoiseStd] = ...
    sensorNoiseModel( ...
        scenario, ...
        probe, ...
        sensorConfig, ...
        pathNoiseLevel)
%% ============================================================
% ضوضاء قياس صفرية المتوسط تعتمد على ضوضاء الموقع ومسار الانتشار
%% ============================================================

r = probe.position(1);
c = probe.position(2);

localNoiseLevel = 0;
if isfield(scenario.environment, 'noise')
    localNoiseLevel = scenario.environment.noise(r,c);
end

if nargin < 4 || isempty(pathNoiseLevel) || ...
        ~isscalar(pathNoiseLevel) || ~isfinite(pathNoiseLevel)
    pathNoiseLevel = localNoiseLevel;
end

effectiveNoiseLevel = max( ...
    clamp01(localNoiseLevel), ...
    clamp01(pathNoiseLevel));

noiseStd = sensorConfig.baseNoiseStd + ...
    sensorConfig.noiseStdScale * ...
    sensorConfig.noiseSensitivity * ...
    effectiveNoiseLevel;

observableNoiseStd = sensorConfig.baseNoiseStd + ...
    sensorConfig.noiseStdScale * ...
    sensorConfig.noiseSensitivity * ...
    clamp01(localNoiseLevel);
% هذا التقدير يعتمد فقط على خريطة الضوضاء عند المستقبِل، وهي معلومة
% للنظام. أما noiseStd أعلاه فيبقى جزءًا من مولّد القياس وقد يتضمن
% ضوضاء المسار المرتبطة بموقع الضحية الحقيقي.

noiseSample = noiseStd * randn();

end


function value = clamp01(value)

if ~isscalar(value) || ~isfinite(value)
    value = 0;
end
value = max(0, min(1, value));

end
