function [reliability, snrDb] = ...
    sensorReliabilityModel( ...
        signalComponent, ...
        noiseStd, ...
        channelTransmission, ...
        sensorConfig)
%% ============================================================
% موثوقية القياس من SNR وجودة قناة الانتشار
%
% تختلف عن الصيغة القديمة التي اعتبرت الخلية الهادئة موثوقة حتى
% عند غياب أي إشارة مفيدة.
%% ============================================================

signalComponent = max(0, finiteOrZero(signalComponent));
noiseStd = max(eps, finiteOrZero(noiseStd));
channelTransmission = max(0, min(1, ...
    finiteOrZero(channelTransmission)));

snrLinear = signalComponent / noiseStd;
snrDb = 20 * log10(max(snrLinear, eps));

snrReliability = 1 / (1 + exp( ...
    -(snrDb - sensorConfig.snrMidpointDb) / ...
    sensorConfig.snrScaleDb));

channelReliability = ...
    sensorConfig.minimumReliability + ...
    (1 - sensorConfig.minimumReliability) * ...
    sqrt(channelTransmission);

reliability = snrReliability * channelReliability;
reliability = max( ...
    sensorConfig.minimumReliability, ...
    min(1, reliability));

end


function value = finiteOrZero(value)

if ~isscalar(value) || ~isfinite(value)
    value = 0;
end

end
