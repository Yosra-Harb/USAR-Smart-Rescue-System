function [scenarioConfig, requestInfo] = scenarioRequestToConfig(request)
%% ============================================================
% Function Name : scenarioRequestToConfig
%
% Description :
% تحويل طلب السيناريو القادم من طبقة التكامل/الداشبورد إلى
% scenarioConfig متوافق بالكامل مع ScenarioGenerator/createScenario.
%
% ملاحظة مهمة:
% النسخة v4.1.4 لا تجعل accessibility scalar مدخلاً فعالاً في
% generateAccessibilityMap؛ خريطة الوصول مشتقة حالياً من الركام والعوائق.
% لذلك لا نعرض accessibility/risk/obstacleDensity كمدخلات قابلة للتحكم
% في Contract v1 حتى لا نعطي المستخدم تحكماً وهمياً.
%% ============================================================

request = normalizeRequest(request);
validateSchemaVersion(request);

allowedScenarioTypes = [ ...
    "Ideal", ...
    "DenseDebris", ...
    "HighNoise", ...
    "DeepBurial", ...
    "MultipleVictims", ...
    "WeakVitalSigns", ...
    "Custom"];

scenarioType = normalizeScenarioType(readRequiredString( ...
    request, "scenarioType"), allowedScenarioTypes);

scenarioConfig = ScenarioGenerator(scenarioType);

% طبقات التحقق مرتبة عمدًا حتى تُرجع الأخطاء الدلالية الصحيحة:
% 1) Controls معروفة لكنها غير مدعومة حاليًا.
% 2) Overrides معروفة لكنها ممنوعة للـ preset scenarios.
% 3) حقول غير معروفة فعلاً.
rejectUnsupportedControls(request);

if scenarioType ~= "Custom"
    rejectPresetOverrides(request);
end

rejectUnknownFields(request);

if isfield(request, 'randomSeed')
    scenarioConfig.randomSeed = validateSeed(request.randomSeed);
end

if scenarioType == "Custom"
    scenarioConfig = applyCustomField( ...
        scenarioConfig, request, 'numVictims', @validateVictimCount);
    scenarioConfig = applyCustomField( ...
        scenarioConfig, request, 'debrisDensity', @validateUnitScalar);
    scenarioConfig = applyCustomField( ...
        scenarioConfig, request, 'noiseLevel', @validateUnitScalar);
    scenarioConfig = applyCustomField( ...
        scenarioConfig, request, 'burialDepth', @validateUnitScalar);
    scenarioConfig = applyCustomField( ...
        scenarioConfig, request, 'vitalStrength', @validateUnitScalar);
end

% نبقي حجم الشبكة 50x50 في Contract v1 لأن التقييم الإحصائي الحالي
% ومعلمات البحث/التوطين بُنيت على هذا الحجم.
scenarioConfig.gridSize = [50 50];

requestInfo = struct();
requestInfo.schemaVersion = "1.0";
requestInfo.scenarioType = scenarioType;
requestInfo.withinCurrentParameterEnvelope = ...
    isWithinCurrentParameterEnvelope(scenarioConfig);
requestInfo.parameterEnvelopeNote = ...
    "Per-parameter envelope only; joint Random Challenge validation is still required.";

end


function request = normalizeRequest(request)

if ischar(request) || (isstring(request) && isscalar(request))
    textValue = string(request);
    if isfile(textValue)
        textValue = string(fileread(textValue));
    end
    request = jsondecode(char(textValue));
end

if ~isstruct(request) || numel(request) ~= 1
    error( ...
        'scenarioRequestToConfig:InvalidRequest', ...
        'Scenario request must be a scalar struct, JSON string, or JSON file path.');
end

end


function validateSchemaVersion(request)

if ~isfield(request, 'schemaVersion')
    return;
end
version = string(request.schemaVersion);
if ~isscalar(version) || version ~= "1.0"
    error( ...
        'scenarioRequestToConfig:UnsupportedSchemaVersion', ...
        'Contract v1 accepts schemaVersion=''1.0''.');
end

end


function rejectUnknownFields(request)
% جميع الحقول التالية معروفة للـ Contract حتى لو كان بعضها
% ممنوعًا بسياسة منفصلة. هذا يضمن أن field معروف لكنه غير مسموح
% لا يتحول بالخطأ إلى UnknownField.

knownFields = { ...
    'schemaVersion', ...
    'scenarioType', ...
    'randomSeed', ...
    'numVictims', ...
    'debrisDensity', ...
    'noiseLevel', ...
    'burialDepth', ...
    'vitalStrength', ...
    'accessibility', ...
    'riskLevel', ...
    'obstacleDensity'};

requestFields = fieldnames(request);
for index = 1:numel(requestFields)
    fieldName = requestFields{index};
    if ~ismember(fieldName, knownFields)
        error( ...
            'scenarioRequestToConfig:UnknownField', ...
            'Unknown Scenario Request field: %s', ...
            fieldName);
    end
end

end


function value = readRequiredString(request, fieldName)

if ~isfield(request, fieldName)
    error( ...
        'scenarioRequestToConfig:MissingField', ...
        'Required field is missing: %s', fieldName);
end

value = string(request.(fieldName));
if ~isscalar(value) || strlength(strtrim(value)) == 0
    error( ...
        'scenarioRequestToConfig:InvalidField', ...
        '%s must be a non-empty string.', fieldName);
end

end


function scenarioType = normalizeScenarioType(value, allowedTypes)

value = strtrim(string(value));
matchIndex = find(strcmpi(value, allowedTypes), 1, 'first');
if isempty(matchIndex)
    error( ...
        'scenarioRequestToConfig:UnknownScenarioType', ...
        'Unsupported scenarioType: %s', char(value));
end
scenarioType = allowedTypes(matchIndex);

end


function scenarioConfig = applyCustomField( ...
    scenarioConfig, request, fieldName, validator)

if isfield(request, fieldName)
    scenarioConfig.(fieldName) = validator(request.(fieldName));
end

end


function rejectPresetOverrides(request)

customFields = { ...
    'numVictims', ...
    'debrisDensity', ...
    'noiseLevel', ...
    'burialDepth', ...
    'vitalStrength'};

for index = 1:numel(customFields)
    fieldName = customFields{index};
    if isfield(request, fieldName)
        error( ...
            'scenarioRequestToConfig:PresetOverrideNotAllowed', ...
            ['Preset scenarios use their validated preset parameters. ' ...
             'Use scenarioType=''Custom'' to override %s.'], ...
            fieldName);
    end
end

end


function rejectUnsupportedControls(request)

unsupportedFields = {'accessibility','riskLevel','obstacleDensity'};
for index = 1:numel(unsupportedFields)
    fieldName = unsupportedFields{index};
    if isfield(request, fieldName)
        error( ...
            'scenarioRequestToConfig:UnsupportedControl', ...
            ['%s is not an effective independent control in MATLAB v4.1.4 ' ...
             'and is intentionally excluded from Contract v1.'], ...
            fieldName);
    end
end

end


function value = validateVictimCount(value)

if ~isnumeric(value) || ~isscalar(value) || ~isfinite(value)
    error( ...
        'scenarioRequestToConfig:InvalidVictimCount', ...
        'numVictims must be a finite numeric scalar.');
end

value = round(double(value));
if value < 1 || value > 20
    error( ...
        'scenarioRequestToConfig:InvalidVictimCount', ...
        'numVictims must be between 1 and 20 for Contract v1.');
end

end


function value = validateUnitScalar(value)

if ~isnumeric(value) || ~isscalar(value) || ~isfinite(value)
    error( ...
        'scenarioRequestToConfig:InvalidUnitScalar', ...
        'Scenario intensity values must be finite numeric scalars.');
end

value = double(value);
if value < 0 || value > 1
    error( ...
        'scenarioRequestToConfig:InvalidUnitScalar', ...
        'Scenario intensity values must be between 0 and 1.');
end

end


function value = validateSeed(value)

if ~isnumeric(value) || ~isscalar(value) || ~isfinite(value)
    error( ...
        'scenarioRequestToConfig:InvalidSeed', ...
        'randomSeed must be a finite numeric scalar.');
end

value = round(double(value));
if value < 0 || value > 2^32-1
    error( ...
        'scenarioRequestToConfig:InvalidSeed', ...
        'randomSeed must be between 0 and 2^32-1.');
end

end


function isInside = isWithinCurrentParameterEnvelope(config)
% حدود المعلمات التي ظهرت في السيناريوهات القياسية الحالية.
% هذا ليس بعد Validated Operating Envelope مشتركة؛ يلزم اختبار
% 500-1000 توليفة عشوائية قبل استخدام هذا المصطلح في الهكاثون.

isInside = ...
    config.numVictims >= 1 && config.numVictims <= 5 && ...
    config.debrisDensity >= 0.10 && config.debrisDensity <= 0.80 && ...
    config.noiseLevel >= 0.10 && config.noiseLevel <= 0.80 && ...
    config.burialDepth >= 0.20 && config.burialDepth <= 0.90 && ...
    config.vitalStrength >= 0.25 && config.vitalStrength <= 0.90;

end
