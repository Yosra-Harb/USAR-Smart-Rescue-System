function observations = generateSpatialObservations( ...
    scenario, ...
    probe, ...
    sensorConfig)
%% ============================================================
% توليد قياسات مكانية مجهولة الهوية للحساس.
%
% يستخدم مولد المحاكاة الحقيقة المرجعية فقط لصنع قياس noisy كما يحدث
% في أي simulator. لا تُصدر هوية الضحية أو موقعها الحقيقي إلى طبقات
% المعالجة أو التوطين. المخرجات الوحيدة هي range/bearing وعدم اليقين.
%
% Convention: 0 deg = east (column increases), +90 deg = south
% (row increases). Bearing is global, not relative to the probe body.
%% ============================================================

observations = emptyObservationArray();

if ~isstruct(scenario) || ~isfield(scenario, 'victims') || ...
        isempty(scenario.victims)
    observations = addClutterObservation( ...
        observations, scenario, probe, sensorConfig);
    return;
end

probePosition = double(probe.position(1:2));
headingDegrees = readHeading(probe);

for victimIndex = 1:size(scenario.victims,1)

    [transmission, ~, context] = sensorAttenuationModel( ...
        scenario, probe, sensorConfig, victimIndex);

    trueRange = context.distance;
    if trueRange > sensorConfig.detectionRange || trueRange <= eps
        continue;
    end

    rowDifference = context.victimPosition(1) - probePosition(1);
    columnDifference = context.victimPosition(2) - probePosition(2);
    trueBearing = wrapAngle180(atan2d(rowDifference, columnDifference));
    relativeBearing = wrapAngle180(trueBearing - headingDegrees);

    if sensorConfig.fieldOfViewDegrees < 360 && ...
            abs(relativeBearing) > sensorConfig.fieldOfViewDegrees / 2
        continue;
    end

    activityGain = calculateActivityGain( ...
        sensorConfig, context.vitalStrength);
    sourceVariation = max(0, ...
        1 + sensorConfig.sourceVariationStd * randn());
    signalStrength = max(0, min(1, ...
        context.vitalStrength * activityGain * ...
        sourceVariation * transmission));

    observableNoiseStd = estimateObservableNoiseStd( ...
        scenario, probe, sensorConfig);
    observedSnrDb = 20 * log10(max( ...
        signalStrength / max(observableNoiseStd, eps), eps));
    detectionProbability = logistic( ...
        (observedSnrDb - sensorConfig.minimumSpatialSnrDb) / ...
        max(sensorConfig.spatialDetectionSlopeDb, eps));
    detectionProbability = detectionProbability * ...
        (0.35 + 0.65 * sqrt(max(0, transmission)));
    detectionProbability = max(0.02, min(0.995, ...
        detectionProbability));

    if rand() > detectionProbability
        continue;
    end

    rangeStd = Inf;
    measuredRange = NaN;
    if sensorConfig.supportsRange
        rangeStd = sensorConfig.rangeStdBase + ...
            sensorConfig.rangeStdPerCell * trueRange + ...
            0.25 * observableNoiseStd / ...
            max(sensorConfig.baseNoiseStd, eps);
        measuredRange = max(0, trueRange + rangeStd * randn());
    end

    bearingStd = sensorConfig.bearingStdDegrees * ...
        (1 + 0.50 * observableNoiseStd / ...
        max(sensorConfig.baseNoiseStd, eps));
    measuredBearing = wrapAngle180( ...
        trueBearing + bearingStd * randn());

    confidence = logistic((observedSnrDb + 2) / 4);
    confidence = max(0.05, min(0.99, confidence));

    [breathingPeriodicity, heartbeatPeriodicity] = ...
        generatePeriodicity(sensorConfig.name, ...
            context.vitalStrength, confidence);

    observations(end+1,1) = createObservation( ... %#ok<AGROW>
        measuredRange, rangeStd, measuredBearing, bearingStd, ...
        signalStrength, confidence, breathingPeriodicity, ...
        heartbeatPeriodicity, sensorConfig.name);

end

observations = addClutterObservation( ...
    observations, scenario, probe, sensorConfig);

end


function observations = addClutterObservation( ...
    observations, scenario, probe, sensorConfig)

localNoise = 0;
if isstruct(scenario) && isfield(scenario, 'environment') && ...
        isfield(scenario.environment, 'noise')
    position = round(probe.position(1:2));
    noiseMap = scenario.environment.noise;
    if position(1) >= 1 && position(1) <= size(noiseMap,1) && ...
            position(2) >= 1 && position(2) <= size(noiseMap,2)
        localNoise = max(0, min(1, noiseMap(position(1),position(2))));
    end
end

clutterProbability = sensorConfig.clutterProbability * ...
    (0.25 + 0.75 * localNoise);
if rand() >= clutterProbability
    return;
end

headingDegrees = readHeading(probe);
if sensorConfig.fieldOfViewDegrees >= 360
    clutterBearing = -180 + 360 * rand();
else
    clutterBearing = headingDegrees + ...
        sensorConfig.fieldOfViewDegrees * (rand() - 0.5);
end
clutterBearing = wrapAngle180(clutterBearing);

clutterRange = NaN;
clutterRangeStd = Inf;
if sensorConfig.supportsRange
    clutterRange = sensorConfig.detectionRange * sqrt(rand());
    clutterRangeStd = max(0.75, 0.15 * sensorConfig.detectionRange);
end

observations(end+1,1) = createObservation( ...
    clutterRange, clutterRangeStd, clutterBearing, ...
    1.5 * sensorConfig.bearingStdDegrees, ...
    0.05 + 0.12 * rand(), 0.08 + 0.17 * rand(), 0, 0, ...
    sensorConfig.name);

end


function observation = createObservation( ...
    range, rangeStd, bearing, bearingStd, ...
    strength, confidence, breathingPeriodicity, ...
    heartbeatPeriodicity, sensorName)

observation = struct();
observation.range = range;
observation.rangeStd = rangeStd;
observation.bearing = bearing;
observation.bearingStd = bearingStd;
observation.strength = max(0, min(1, strength));
observation.confidence = max(0, min(1, confidence));
observation.breathingPeriodicity = max(0, ...
    min(1, breathingPeriodicity));
observation.heartbeatPeriodicity = max(0, ...
    min(1, heartbeatPeriodicity));
observation.sensorName = string(sensorName);
observation.eventType = eventTypeForSensor(sensorName);

end


function observations = emptyObservationArray()

observations = struct( ...
    'range', {}, ...
    'rangeStd', {}, ...
    'bearing', {}, ...
    'bearingStd', {}, ...
    'strength', {}, ...
    'confidence', {}, ...
    'breathingPeriodicity', {}, ...
    'heartbeatPeriodicity', {}, ...
    'sensorName', {}, ...
    'eventType', {});

end


function [breathing, heartbeat] = generatePeriodicity( ...
    sensorName, vitalStrength, confidence)

name = lower(string(sensorName));
if contains(name,"radar")
    breathing = vitalStrength*confidence + 0.06*randn();
    heartbeat = 0.75*vitalStrength*confidence + 0.08*randn();
elseif contains(name,"acoustic")
    breathing = 0.85*vitalStrength*confidence + 0.10*randn();
    heartbeat = 0;
else
    breathing = 0.15*vitalStrength*confidence;
    heartbeat = 0;
end
breathing = max(0,min(1,breathing));
heartbeat = max(0,min(1,heartbeat));

end


function eventType = eventTypeForSensor(sensorName)

name = lower(string(sensorName));
if contains(name, "radar")
    eventType = "MICRO_MOTION";
elseif contains(name, "thermal")
    eventType = "HEAT_CONTRAST";
else
    eventType = "BREATHING_OR_CALL";
end

end


function gain = calculateActivityGain(sensorConfig, vitalStrength)

if string(sensorConfig.sourceModel) == "INTERMITTENT"
    eventProbability = sensorConfig.eventProbability * ...
        (0.5 + 0.5 * vitalStrength);
    eventActive = rand() < min(1, eventProbability);
    gain = sensorConfig.continuousActivityFloor + ...
        (1 - sensorConfig.continuousActivityFloor) * ...
        double(eventActive);
else
    gain = 1;
end

end


function noiseStd = estimateObservableNoiseStd( ...
    scenario, probe, sensorConfig)

position = round(probe.position(1:2));
localNoise = 0;
if isfield(scenario.environment, 'noise')
    noiseMap = scenario.environment.noise;
    localNoise = noiseMap(position(1), position(2));
end
localNoise = max(0, min(1, localNoise));
noiseStd = sensorConfig.baseNoiseStd + ...
    sensorConfig.noiseStdScale * ...
    sensorConfig.noiseSensitivity * localNoise;

end


function heading = readHeading(probe)

heading = 0;
if isstruct(probe) && isfield(probe, 'headingDegrees') && ...
        isscalar(probe.headingDegrees) && isfinite(probe.headingDegrees)
    heading = wrapAngle180(probe.headingDegrees);
end

end


function value = logistic(argument)

if argument >= 0
    value = 1 / (1 + exp(-argument));
else
    exponent = exp(argument);
    value = exponent / (1 + exponent);
end

end


function angle = wrapAngle180(angle)

angle = mod(angle + 180, 360) - 180;

end
