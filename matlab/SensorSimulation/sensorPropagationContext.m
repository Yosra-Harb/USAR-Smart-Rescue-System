function context = sensorPropagationContext( ...
    scenario, ...
    probePosition, ...
    victimIndex)
%% ============================================================
% أخذ عينات من المسار المستقيم بين المسبار والضحية
%
% قراءة الحقيقة المرجعية مسموحة هنا فقط لأنها تولد القياس الاصطناعي.
% لا تُمرر إحداثيات الضحية أو هذه البنية إلى الدمج أو التوطين.
%% ============================================================

victimPosition = scenario.victims(victimIndex,1:2);
difference = victimPosition - probePosition(1:2);
distance = sqrt(sum(difference.^2));

sampleCount = max(2, ceil(2 * distance) + 1);
sampleRows = round(linspace( ...
    probePosition(1), ...
    victimPosition(1), ...
    sampleCount));
sampleColumns = round(linspace( ...
    probePosition(2), ...
    victimPosition(2), ...
    sampleCount));

sampleRows = max(1, min(scenario.gridSize(1), sampleRows));
sampleColumns = max(1, min(scenario.gridSize(2), sampleColumns));

linearIndices = sub2ind( ...
    scenario.gridSize(1:2), ...
    sampleRows, ...
    sampleColumns);
linearIndices = unique(linearIndices, 'stable');

context = struct();
context.victimIndex = victimIndex;
context.victimPosition = victimPosition;
context.distance = distance;
context.pathCellCount = numel(linearIndices);
context.meanDebris = meanMapAlongPath( ...
    scenario, 'debris', linearIndices, 0);
context.meanAttenuation = meanMapAlongPath( ...
    scenario, 'attenuation', linearIndices, 0);
context.meanNoise = meanMapAlongPath( ...
    scenario, 'noise', linearIndices, 0);
context.obstacleFraction = meanMapAlongPath( ...
    scenario, 'obstacles', linearIndices, 0);
context.vitalStrength = readVictimProperty( ...
    scenario, victimIndex, 'vitalStrength', 0);
context.burialDepth = readVictimProperty( ...
    scenario, victimIndex, 'burialDepth', 0);

context.meanDebris = clamp01(context.meanDebris);
context.meanAttenuation = clamp01(context.meanAttenuation);
context.meanNoise = clamp01(context.meanNoise);
context.obstacleFraction = clamp01(context.obstacleFraction);
context.vitalStrength = clamp01(context.vitalStrength);
context.burialDepth = clamp01(context.burialDepth);

end


function value = meanMapAlongPath( ...
    scenario, ...
    mapName, ...
    linearIndices, ...
    fallbackValue)

if isfield(scenario, 'environment') && ...
        isfield(scenario.environment, mapName)
    map = scenario.environment.(mapName);
    value = mean(double(map(linearIndices)));
else
    value = fallbackValue;
end

end


function value = readVictimProperty( ...
    scenario, ...
    victimIndex, ...
    propertyName, ...
    fallbackValue)

if isfield(scenario, 'groundTruth') && ...
        isfield(scenario.groundTruth, propertyName) && ...
        numel(scenario.groundTruth.(propertyName)) >= victimIndex
    values = scenario.groundTruth.(propertyName);
    value = values(victimIndex);
elseif isfield(scenario, propertyName)
    values = scenario.(propertyName);
    if isscalar(values)
        value = values;
    elseif numel(values) >= victimIndex
        value = values(victimIndex);
    else
        value = fallbackValue;
    end
else
    value = fallbackValue;
end

end


function value = clamp01(value)

if ~isscalar(value) || ~isfinite(value)
    value = 0;
end
value = max(0, min(1, value));

end
