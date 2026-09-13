function result = calculateSpatialMeasurementLogBayesFactors( ...
    processedPacket, scenario, probePosition, candidatePosition)
%% ============================================================
% حساب measurement-set Log Bayes Factor لخلية مرشحة.
%
% لكل حساس نستخدم:
% BF = (1-Pd) + Pd * sum_j(g(z_j|x)/kappa(z_j))
% حيث g نموذج Gaussian للمدى/الزاوية وkappa كثافة clutter منتظمة.
% لا تقرأ الدالة scenario.victims أو scenario.groundTruth.
%% ============================================================

validatePacket(processedPacket);
config = constants();
sensorConfigs = sensorConfiguration();
context = bayesianPropagationContext( ...
    scenario, probePosition, candidatePosition);
sensorNames = {'radar', 'thermal', 'acoustic'};

rowDifference = candidatePosition(1) - probePosition(1);
columnDifference = candidatePosition(2) - probePosition(2);
predictedBearing = wrapAngle180( ...
    atan2d(rowDifference, columnDifference));
heading = 0;
if isfield(processedPacket, 'probeHeadingDegrees') && ...
        isscalar(processedPacket.probeHeadingDegrees) && ...
        isfinite(processedPacket.probeHeadingDegrees)
    heading = processedPacket.probeHeadingDegrees;
end

result = struct();
result.context = context;
result.combinedLogBayesFactor = 0;
result.isVisible = false;

for sensorIndex = 1:numel(sensorNames)
    name = sensorNames{sensorIndex};
    sensorConfig = sensorConfigs.(name);
    observations = processedPacket.spatialObservations.(name);

    relativeBearing = wrapAngle180(predictedBearing - heading);
    isVisible = context.distance <= sensorConfig.detectionRange && ...
        (sensorConfig.fieldOfViewDegrees >= 360 || ...
        abs(relativeBearing) <= sensorConfig.fieldOfViewDegrees / 2);

    sensorResult = emptySensorResult(name, isVisible);
    if isVisible
        detectionProbability = estimateDetectionProbability( ...
            context, sensorConfig, config.spatialBayesian);
        sensorResult.detectionProbability = detectionProbability;
        sensorResult.observationCount = numel(observations);

        likelihoodRatioSum = 0;
        for observationIndex = 1:numel(observations)
            observation = observations(observationIndex);
            bearingResidual = wrapAngle180( ...
                observation.bearing - predictedBearing);
            bearingDensity = gaussianDensity( ...
                bearingResidual, observation.bearingStd);

            if isfinite(observation.range) && ...
                    isfinite(observation.rangeStd)
                rangeResidual = observation.range - context.distance;
                rangeDensity = gaussianDensity( ...
                    rangeResidual, observation.rangeStd);
                targetDensity = rangeDensity * bearingDensity;
                measurementVolume = ...
                    max(sensorConfig.detectionRange, eps) * ...
                    max(sensorConfig.fieldOfViewDegrees, 1);
            else
                targetDensity = bearingDensity;
                measurementVolume = ...
                    max(sensorConfig.fieldOfViewDegrees, 1);
            end

            clutterDensity = max( ...
                config.spatialBayesian.clutterDensityFloor, ...
                sensorConfig.clutterProbability / measurementVolume);
            observationWeight = max(0.05, ...
                observation.confidence) * ...
                (0.30 + 0.50 * observation.strength + ...
                0.20 * max(observation.breathingPeriodicity, ...
                    observation.heartbeatPeriodicity));
            likelihoodRatioSum = likelihoodRatioSum + ...
                observationWeight * targetDensity / clutterDensity;
        end

        bayesFactor = (1 - detectionProbability) + ...
            detectionProbability * likelihoodRatioSum;
        bayesFactor = max(realmin('double'), bayesFactor);
        logBayesFactor = log(bayesFactor);
        limit = config.spatialBayesian.maximumSensorLogBayesFactor;
        sensorResult.logBayesFactor = max(-limit, ...
            min(limit, logBayesFactor));
        result.combinedLogBayesFactor = ...
            result.combinedLogBayesFactor + ...
            sensorResult.logBayesFactor;
        result.isVisible = true;
    end

    result.(name) = sensorResult;
end

end


function probability = estimateDetectionProbability( ...
    context, sensorConfig, spatialConfig)

normalizedDistance = context.distance / ...
    max(sensorConfig.detectionRange, eps);
rangeFactor = 1 / ...
    (1 + normalizedDistance^sensorConfig.pathLossExponent);
environmentLoss = ...
    0.8 * context.meanDebris + ...
    0.6 * context.meanAttenuation + ...
    1.2 * context.obstacleFraction + ...
    0.4 * context.meanNoise;
probability = rangeFactor * exp(-environmentLoss);
probability = max(spatialConfig.minimumDetectionProbability, ...
    min(spatialConfig.maximumDetectionProbability, probability));

end


function density = gaussianDensity(residual, sigma)

sigma = max(1e-6, sigma);
density = exp(-0.5 * (residual / sigma)^2) / ...
    (sqrt(2*pi) * sigma);

end


function result = emptySensorResult(name, visible)

result = struct();
result.sensorName = string(name);
result.isVisible = logical(visible);
result.detectionProbability = 0;
result.observationCount = 0;
result.logBayesFactor = 0;

end


function validatePacket(processedPacket)

if ~isstruct(processedPacket) || ...
        ~isfield(processedPacket, 'spatialObservations') || ...
        ~isstruct(processedPacket.spatialObservations)
    error("calculateSpatialMeasurementLogBayesFactors:InvalidPacket", ...
        "processedPacket must contain spatialObservations.");
end

sensorNames = {'radar', 'thermal', 'acoustic'};
for index = 1:numel(sensorNames)
    if ~isfield(processedPacket.spatialObservations, sensorNames{index})
        error("calculateSpatialMeasurementLogBayesFactors:InvalidPacket", ...
            "A spatial sensor observation set is missing.");
    end
end

end


function angle = wrapAngle180(angle)

angle = mod(angle + 180, 360) - 180;

end
