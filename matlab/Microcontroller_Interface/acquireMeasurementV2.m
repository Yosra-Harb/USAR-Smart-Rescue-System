function measurement = acquireMeasurementV2(expectedSource, provider)
%ACQUIREMEASUREMENTV2 One strict acquisition seam for swappable sources.
% provider() returns a v2 struct or one JSON object; no implicit fallback.
expectedSource = string(expectedSource);
if ~isscalar(expectedSource) || ...
        ~ismember(expectedSource, ...
            ["SIMULATION","PROTEUS","HARDWARE"]) || ...
        ~isa(provider, 'function_handle')
    error('USAR:AcquisitionV2:Provider', 'Invalid provider or source.');
end
raw = provider();
if ischar(raw) || (isstring(raw) && isscalar(raw))
    try
        raw = jsondecode(raw);
    catch
        error('USAR:AcquisitionV2:JSON', 'Invalid acquisition JSON.');
    end
end
validateAcquisitionFrameV2(raw);
if ~strcmp(string(raw.source), expectedSource)
    error('USAR:AcquisitionV2:Source', ...
        'Measurement source does not match selected provider.');
end
measurement = decodeAcquisitionFrameV2(raw);
end
