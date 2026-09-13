function record = buildTelemetryRecord( ...
    missionId, sequence, probe, newVictimIDs)
%% ============================================================
% Function Name : buildTelemetryRecord
%
% Description :
% بناء سجل Telemetry تشغيلي آمن بعد كل دورة Mission Controller.
% يُصدر فقط البيانات التي يعرفها النظام أثناء الاستدلال، ولا يقرأ
% scenario.victims أو Ground Truth أو الحقول التشخيصية Oracle.
%% ============================================================

if nargin < 4
    newVictimIDs = zeros(1,0);
end

record = struct();
record.schemaVersion = "1.1";
record.contractType = "mission-telemetry";
record.eventType = "STEP";
if ~isempty(newVictimIDs)
    record.eventType = "VICTIM_TRACK_CREATED";
end
record.missionId = string(missionId);
record.sequence = double(sequence);
record.timestampUtc = telemetryTimestampUtc();
record.containsGroundTruth = false;

record.probe = buildProbeTelemetry(probe);
record.sensors = buildSensorTelemetry(probe);
record.fusion = buildFusionTelemetry(probe);
record.localization = buildLocalizationTelemetry(probe);
record.vitality = buildVitalityTelemetry(probe);
record.priority = buildPriorityTelemetry(probe);
record.decision = readStringField(probe, 'lastDecision', "UNKNOWN");

victimCount = 0;
if isfield(probe,'memory') && isstruct(probe.memory) && ...
        isfield(probe.memory,'detectedVictims')
    victimCount = numel(probe.memory.detectedVictims);
end
record.activeTrackCount = double(victimCount);
record.newTracks = buildNewVictimTelemetry(probe, newVictimIDs);

end


function output = buildProbeTelemetry(probe)
output = struct();
output.id = readNumericField(probe,'id',[]);
output.position = telemetryPoint(readField(probe,'position',[]));
output.state = readStringField(probe,'state',"UNKNOWN");
output.currentStep = readNumericField(probe,'currentStep',[]);
output.coverage = readNumericField(probe,'coverage',[]);
end


function output = buildSensorTelemetry(probe)
output = emptySensorTelemetry();
if ~isfield(probe,'lastSensorData') || ...
        ~isstruct(probe.lastSensorData)
    return;
end
packet = probe.lastSensorData;
output.quality = readNumericField(packet,'quality',[]);
output.radar = oneSensor(packet,'radar','radarPhysical', ...
    'radarUnit','radarReliability');
output.thermal = oneSensor(packet,'thermal','thermalPhysical', ...
    'thermalUnit','thermalReliability');
output.acoustic = oneSensor(packet,'acoustic','acousticPhysical', ...
    'acousticUnit','acousticReliability');
end


function output = oneSensor(packet,normalizedName,physicalName,unitName,reliabilityName)
output = struct( ...
    'normalized', readNumericField(packet,normalizedName,[]), ...
    'physical', readNumericField(packet,physicalName,[]), ...
    'unit', readStringField(packet,unitName,""), ...
    'reliability', readNumericField(packet,reliabilityName,[]));
end


function output = emptySensorTelemetry()
emptyOne = struct('normalized',[],'physical',[],'unit',"",'reliability',[]);
output = struct('quality',[],'radar',emptyOne,'thermal',emptyOne,'acoustic',emptyOne);
end


function output = buildFusionTelemetry(probe)
output = struct( ...
    'score',[], ...
    'confidence',[], ...
    'weights',struct('radar',[],'thermal',[],'acoustic',[]));
if ~isfield(probe,'lastFusionData') || ~isstruct(probe.lastFusionData)
    return;
end
packet = probe.lastFusionData;
output.score = readNumericField(packet,'fusionScore',[]);
output.confidence = readNumericField(packet,'confidence',[]);
if isfield(packet,'weights') && isstruct(packet.weights)
    output.weights.radar = readNumericField(packet.weights,'radar',[]);
    output.weights.thermal = readNumericField(packet.weights,'thermal',[]);
    output.weights.acoustic = readNumericField(packet.weights,'acoustic',[]);
end
end


function output = buildLocalizationTelemetry(probe)
output = struct( ...
    'isVictimDetected',false, ...
    'estimatedPosition',telemetryPoint([]), ...
    'confidence',[], ...
    'sourceType',"UNKNOWN", ...
    'method',"UNKNOWN", ...
    'posteriorProbability',[]);
if ~isfield(probe,'lastLocalizationData') || ...
        ~isstruct(probe.lastLocalizationData)
    return;
end
packet = probe.lastLocalizationData;
output.isVictimDetected = readLogicalField(packet,'isVictimDetected',false);
output.estimatedPosition = telemetryPoint(readField(packet,'estimatedPosition',[]));
output.confidence = readNumericField(packet,'localizationConfidence',[]);
output.sourceType = readStringField(packet,'sourceType',"UNKNOWN");
output.method = readStringField(packet,'localizationMethod',"UNKNOWN");
output.posteriorProbability = readNumericField(packet,'posteriorProbability',[]);
end


function output = buildVitalityTelemetry(probe)
output = struct( ...
    'isVictimDetected',false, ...
    'vitalityIndex',[], ...
    'condition',"UNKNOWN", ...
    'temporalStability',[]);
if ~isfield(probe,'lastVitalityData') || ~isstruct(probe.lastVitalityData)
    return;
end
packet = probe.lastVitalityData;
output.isVictimDetected = readLogicalField(packet,'isVictimDetected',false);
output.vitalityIndex = readNumericField(packet,'vitalityIndex',[]);
output.condition = readStringField(packet,'victimCondition',"UNKNOWN");
output.temporalStability = readNumericField(packet,'temporalStability',[]);
end


function output = buildPriorityTelemetry(probe)
output = struct( ...
    'score',[], ...
    'level',"UNKNOWN", ...
    'medicalSeverity',[]);
if ~isfield(probe,'lastPriorityData') || ~isstruct(probe.lastPriorityData)
    return;
end
packet = probe.lastPriorityData;
output.score = readNumericField(packet,'priorityScore',[]);
output.level = readStringField(packet,'priorityLevel',"UNKNOWN");
if isfield(packet,'priorityComponents') && isstruct(packet.priorityComponents)
    output.medicalSeverity = readNumericField( ...
        packet.priorityComponents,'medicalSeverity',[]);
end
end


function victimsOutput = buildNewVictimTelemetry(probe,newVictimIDs)
template = struct( ...
    'id',[], ...
    'estimatedPosition',telemetryPoint([]), ...
    'vitalityIndex',[], ...
    'medicalSeverity',[], ...
    'priorityScore',[], ...
    'priorityLevel',"UNKNOWN", ...
    'rescueRank',[]);

if isempty(newVictimIDs) || ~isfield(probe,'memory') || ...
        ~isfield(probe.memory,'detectedVictims') || ...
        isempty(probe.memory.detectedVictims)
    victimsOutput = repmat(template,0,1);
    return;
end

allVictims = probe.memory.detectedVictims;
allIDs = [allVictims.id];
selected = find(ismember(allIDs,newVictimIDs));
victimsOutput = repmat(template,numel(selected),1);

for k = 1:numel(selected)
    victim = allVictims(selected(k));
    victimsOutput(k).id = double(victim.id);
    victimsOutput(k).estimatedPosition = telemetryPoint( ...
        readField(victim,'position',[]));
    victimsOutput(k).vitalityIndex = readNumericField(victim,'vitalityIndex',[]);
    if ~isempty(victimsOutput(k).vitalityIndex)
        victimsOutput(k).medicalSeverity = 1 - victimsOutput(k).vitalityIndex;
    end
    victimsOutput(k).priorityScore = readNumericField(victim,'priorityScore',[]);
    victimsOutput(k).priorityLevel = readStringField(victim,'priorityLevel',"UNKNOWN");
    victimsOutput(k).rescueRank = readNumericField(victim,'rescueRank',[]);
end
end


function point = telemetryPoint(position)
point = struct('row',[],'column',[],'x',[],'y',[]);
if isempty(position) || numel(position) < 2
    return;
end
position = double(position(1:2));
if any(~isfinite(position))
    return;
end
point.row = position(1);
point.column = position(2);
point.x = position(2);
point.y = position(1);
end


function value = readField(container,name,defaultValue)
if isstruct(container) && isfield(container,name)
    value = container.(name);
else
    value = defaultValue;
end
end


function value = readNumericField(container,name,defaultValue)
value = readField(container,name,defaultValue);
if isempty(value)
    value = [];
    return;
end
if ~isnumeric(value) && ~islogical(value)
    value = defaultValue;
    return;
end
value = double(value);
if any(~isfinite(value(:)))
    value = [];
end
end


function value = readLogicalField(container,name,defaultValue)
raw = readField(container,name,defaultValue);
if isempty(raw) || ~isscalar(raw)
    value = logical(defaultValue);
else
    value = logical(raw);
end
end


function value = readStringField(container,name,defaultValue)
raw = readField(container,name,defaultValue);
if isempty(raw)
    value = string(defaultValue);
else
    value = string(raw);
    if ~isscalar(value)
        value = string(defaultValue);
    end
end
end
