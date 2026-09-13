function [state, diagnostics] = updateSpatialBayesianMap( ...
    state, scenario, processedPacket)
%% ============================================================
% تحديث posterior المكاني من قياسات range/bearing مجهولة الهوية.
%
% Performance design:
% - تُبنى جميع سياقات الانتشار المحلية دفعة واحدة.
% - تُحسب عوامل Bayes لكل حساس على متجه الخلايا المرشحة.
% - لا يُعاد حساب نموذج الشدة داخل حلقة منفصلة لكل خلية.
%
% لا تستخدم هذه الدالة مواقع الضحايا أو Ground Truth.
%% ============================================================

config = constants();
spatialConfig = config.spatialBayesian;
sensorConfigs = sensorConfiguration();
probePosition = round(processedPacket.probePosition(1:2));

maximumRange = max([ ...
    sensorConfigs.radar.detectionRange, ...
    sensorConfigs.thermal.detectionRange, ...
    sensorConfigs.acoustic.detectionRange]);
updateRadius = max(1, ceil( ...
    maximumRange * spatialConfig.maximumUpdateRangeScale));

state.updateCount = state.updateCount + 1;
state.lastProbePosition = probePosition;
state.lastMeasurementLogBayesFactorMap(:) = 0;
state.lastVisibilityMask(:) = false;

minimumRow = max(1, probePosition(1) - updateRadius);
maximumRow = min(state.gridSize(1), ...
    probePosition(1) + updateRadius);
minimumColumn = max(1, probePosition(2) - updateRadius);
maximumColumn = min(state.gridSize(2), ...
    probePosition(2) + updateRadius);

[rowGrid, columnGrid] = ndgrid( ...
    minimumRow:maximumRow, ...
    minimumColumn:maximumColumn);
insideUpdateRadius = hypot( ...
    rowGrid - probePosition(1), ...
    columnGrid - probePosition(2)) <= updateRadius;

candidateRows = rowGrid(insideUpdateRadius);
candidateColumns = columnGrid(insideUpdateRadius);
candidatePositions = [candidateRows, candidateColumns];

[spatialEvidence, visibilityMask, context] = ...
    calculateSpatialEvidenceBatch( ...
        processedPacket, ...
        scenario, ...
        probePosition, ...
        candidatePositions, ...
        sensorConfigs, ...
        spatialConfig);

intensityEvidence = calculateIntensityEvidenceBatch( ...
    processedPacket, ...
    context, ...
    sensorConfigs, ...
    config.bayesian);
% نموذج الشدة v3 ما زال مستخدمًا، لكنه يُحسب الآن على جميع الخلايا
% متجهيًا بدل استدعائه مرة ثانية لكل خلية.

combinedEvidence = spatialEvidence + ...
    spatialConfig.intensityEvidenceWeight .* intensityEvidence;

visibleRows = candidateRows(visibilityMask);
visibleColumns = candidateColumns(visibilityMask);
visibleEvidence = combinedEvidence(visibilityMask);
visibleLinearIndices = sub2ind( ...
    state.gridSize, visibleRows, visibleColumns);

oldCentered = state.logOddsMap(visibleLinearIndices) - ...
    state.priorLogOdds;
updatedLogOdds = state.priorLogOdds + ...
    spatialConfig.evidenceRetention .* oldCentered + ...
    spatialConfig.informationGain .* visibleEvidence;
logOddsLimit = spatialConfig.maximumAbsoluteLogOdds;
updatedLogOdds = max( ...
    -logOddsLimit, min(logOddsLimit, updatedLogOdds));

state.logOddsMap(visibleLinearIndices) = updatedLogOdds;
state.lastMeasurementLogBayesFactorMap( ...
    visibleLinearIndices) = visibleEvidence;
state.lastVisibilityMask(visibleLinearIndices) = true;
state.observationCount(visibleLinearIndices) = ...
    state.observationCount(visibleLinearIndices) + 1;
state.weightedObservationSupport(visibleLinearIndices) = ...
    state.weightedObservationSupport(visibleLinearIndices) + ...
    max(0, visibleEvidence);
state.lastObservationStep(visibleLinearIndices) = ...
    state.updateCount;

state.probabilityMap = stableLogistic(state.logOddsMap);

diagnostics = struct();
diagnostics.updatedCellCount = numel(visibleLinearIndices);
diagnostics.maximumPosteriorProbability = ...
    max(state.probabilityMap(:));
if isempty(visibleEvidence)
    diagnostics.maximumMeasurementLogBayesFactor = 0;
else
    diagnostics.maximumMeasurementLogBayesFactor = ...
        max(visibleEvidence);
end
diagnostics.vectorizedUpdate = true;
diagnostics.candidateCellCount = size(candidatePositions, 1);
state.lastSpatialDiagnostics = diagnostics;

end


function [combinedEvidence, visibilityMask, context] = ...
    calculateSpatialEvidenceBatch( ...
        processedPacket, scenario, probePosition, ...
        candidatePositions, sensorConfigs, spatialConfig)

validateSpatialPacket(processedPacket);
context = buildPropagationContextBatch( ...
    scenario, probePosition, candidatePositions);

numberOfCandidates = size(candidatePositions, 1);
combinedEvidence = zeros(numberOfCandidates, 1);
visibilityMask = false(numberOfCandidates, 1);

rowDifference = candidatePositions(:,1) - probePosition(1);
columnDifference = candidatePositions(:,2) - probePosition(2);
predictedBearing = wrapAngle180( ...
    atan2d(rowDifference, columnDifference));

heading = 0;
if isfield(processedPacket, 'probeHeadingDegrees') && ...
        isscalar(processedPacket.probeHeadingDegrees) && ...
        isfinite(processedPacket.probeHeadingDegrees)
    heading = processedPacket.probeHeadingDegrees;
end

relativeBearing = wrapAngle180(predictedBearing - heading);
sensorNames = {'radar', 'thermal', 'acoustic'};

for sensorIndex = 1:numel(sensorNames)
    sensorName = sensorNames{sensorIndex};
    sensorConfig = sensorConfigs.(sensorName);
    observations = ...
        processedPacket.spatialObservations.(sensorName);

    sensorVisibility = ...
        context.distance <= sensorConfig.detectionRange & ...
        (sensorConfig.fieldOfViewDegrees >= 360 | ...
        abs(relativeBearing) <= ...
        sensorConfig.fieldOfViewDegrees / 2);

    detectionProbability = estimateDetectionProbabilityBatch( ...
        context, sensorConfig, spatialConfig);
    likelihoodRatioSum = zeros(numberOfCandidates, 1);

    for observationIndex = 1:numel(observations)
        observation = observations(observationIndex);
        bearingResidual = wrapAngle180( ...
            observation.bearing - predictedBearing);
        bearingDensity = gaussianDensity( ...
            bearingResidual, observation.bearingStd);

        if isfinite(observation.range) && ...
                isfinite(observation.rangeStd)
            rangeResidual = ...
                observation.range - context.distance;
            rangeDensity = gaussianDensity( ...
                rangeResidual, observation.rangeStd);
            targetDensity = rangeDensity .* bearingDensity;
            measurementVolume = ...
                max(sensorConfig.detectionRange, eps) * ...
                max(sensorConfig.fieldOfViewDegrees, 1);
        else
            targetDensity = bearingDensity;
            measurementVolume = ...
                max(sensorConfig.fieldOfViewDegrees, 1);
        end

        clutterDensity = max( ...
            spatialConfig.clutterDensityFloor, ...
            sensorConfig.clutterProbability / measurementVolume);
        observationWeight = max(0.05, ...
            observation.confidence) * ...
            (0.30 + 0.50 * observation.strength + ...
            0.20 * max( ...
                observation.breathingPeriodicity, ...
                observation.heartbeatPeriodicity));
        likelihoodRatioSum = likelihoodRatioSum + ...
            observationWeight .* targetDensity ./ clutterDensity;
    end

    bayesFactor = (1 - detectionProbability) + ...
        detectionProbability .* likelihoodRatioSum;
    bayesFactor = max(realmin('double'), bayesFactor);
    logBayesFactor = log(bayesFactor);
    factorLimit = spatialConfig.maximumSensorLogBayesFactor;
    logBayesFactor = max( ...
        -factorLimit, min(factorLimit, logBayesFactor));
    logBayesFactor(~sensorVisibility) = 0;

    combinedEvidence = combinedEvidence + logBayesFactor;
    visibilityMask = visibilityMask | sensorVisibility;
end

end


function context = buildPropagationContextBatch( ...
    scenario, probePosition, candidatePositions)

numberOfCandidates = size(candidatePositions, 1);
rowDifference = candidatePositions(:,1) - probePosition(1);
columnDifference = candidatePositions(:,2) - probePosition(2);
distance = hypot(rowDifference, columnDifference);

% مسار رقمي متجهي: عينة واحدة لكل خلية يعبرها الشعاع تقريبًا.
sampleCount = max(abs(rowDifference), abs(columnDifference)) + 1;
sampleCount = max(1, round(sampleCount));
maximumSampleCount = max(sampleCount);
sampleOrdinal = 0:(maximumSampleCount - 1);
validSampleMask = sampleOrdinal < sampleCount;
sampleDenominator = max(sampleCount - 1, 1);
sampleFraction = sampleOrdinal ./ sampleDenominator;

sampleRows = round( ...
    probePosition(1) + rowDifference .* sampleFraction);
sampleColumns = round( ...
    probePosition(2) + columnDifference .* sampleFraction);
sampleRows = max(1, min(scenario.gridSize(1), sampleRows));
sampleColumns = max(1, min(scenario.gridSize(2), sampleColumns));
linearIndices = sub2ind( ...
    scenario.gridSize(1:2), sampleRows, sampleColumns);

context = struct();
context.distance = distance;
context.pathCellCount = sampleCount;
context.meanDebris = meanMapSamples( ...
    scenario, 'debris', linearIndices, ...
    validSampleMask, sampleCount);
context.meanAttenuation = meanMapSamples( ...
    scenario, 'attenuation', linearIndices, ...
    validSampleMask, sampleCount);
context.meanNoise = meanMapSamples( ...
    scenario, 'noise', linearIndices, ...
    validSampleMask, sampleCount);
context.obstacleFraction = meanMapSamples( ...
    scenario, 'obstacles', linearIndices, ...
    validSampleMask, sampleCount);

context.meanDebris = clamp01(context.meanDebris);
context.meanAttenuation = clamp01(context.meanAttenuation);
context.meanNoise = clamp01(context.meanNoise);
context.obstacleFraction = clamp01( ...
    context.obstacleFraction);

if numberOfCandidates == 0
    context.distance = zeros(0,1);
end

end


function values = meanMapSamples( ...
    scenario, mapName, linearIndices, validMask, sampleCount)

if isfield(scenario, 'environment') && ...
        isfield(scenario.environment, mapName) && ...
        (isnumeric(scenario.environment.(mapName)) || ...
        islogical(scenario.environment.(mapName)))
    environmentMap = double(scenario.environment.(mapName));
    sampleValues = environmentMap(linearIndices);
    sampleValues(~validMask) = 0;
    values = sum(sampleValues, 2) ./ max(sampleCount, 1);
else
    values = zeros(size(sampleCount));
end

end


function probability = estimateDetectionProbabilityBatch( ...
    context, sensorConfig, spatialConfig)

normalizedDistance = context.distance ./ ...
    max(sensorConfig.detectionRange, eps);
rangeFactor = 1 ./ ...
    (1 + normalizedDistance .^ sensorConfig.pathLossExponent);
environmentLoss = ...
    0.8 .* context.meanDebris + ...
    0.6 .* context.meanAttenuation + ...
    1.2 .* context.obstacleFraction + ...
    0.4 .* context.meanNoise;
probability = rangeFactor .* exp(-environmentLoss);
probability = max( ...
    spatialConfig.minimumDetectionProbability, ...
    min(spatialConfig.maximumDetectionProbability, probability));

end


function intensityEvidence = calculateIntensityEvidenceBatch( ...
    processedPacket, context, sensorConfigs, bayesianConfig)

numberOfCandidates = numel(context.distance);
intensityEvidence = zeros(numberOfCandidates, 1);
if ~isfield(processedPacket, 'features') || ...
        ~isfield(processedPacket, 'qualityReport')
    return;
end

sensorNames = {'radar', 'thermal', 'acoustic'};
reliabilityNames = { ...
    'radarReliability', ...
    'thermalReliability', ...
    'acousticReliability'};

vitalHypotheses = bayesianConfig.vitalStrengthHypotheses(:)';
vitalPrior = normalizeProbabilityVector( ...
    bayesianConfig.vitalStrengthPrior(:)');
burialHypotheses = bayesianConfig.burialDepthHypotheses(:)';
burialPrior = normalizeProbabilityVector( ...
    bayesianConfig.burialDepthPrior(:)');

for sensorIndex = 1:numel(sensorNames)
    sensorName = sensorNames{sensorIndex};
    featureName = [sensorName, 'Feature'];
    if ~isfield(processedPacket.features, featureName)
        continue;
    end

    measurementValue = clamp01( ...
        processedPacket.features.(featureName));
    sensorConfig = sensorConfigs.(sensorName);
    reliability = readUnitScalar( ...
        processedPacket.qualityReport, ...
        reliabilityNames{sensorIndex});

    normalizedDistance = context.distance ./ ...
        max(sensorConfig.detectionRange, eps);
    distanceTransmission = 1 ./ ...
        (1 + normalizedDistance .^ ...
        sensorConfig.pathLossExponent);
    pathLength = max(1, context.distance);
    effectiveObstacleCells = ...
        context.obstacleFraction .* context.pathCellCount;
    observableMaterialLossDb = pathLength .* ( ...
        sensorConfig.debrisLossDbPerCell .* ...
        context.meanDebris + ...
        sensorConfig.attenuationLossDbPerCell .* ...
        context.meanAttenuation) + ...
        sensorConfig.obstacleLossDbPerCell .* ...
        effectiveObstacleCells;
    noiseStd = sensorConfig.baseNoiseStd + ...
        sensorConfig.noiseStdScale .* ...
        sensorConfig.noiseSensitivity .* context.meanNoise;
    noiseStd = max(noiseStd, 1e-6);

    logLikelihoodH0 = censoredGaussianLogLikelihoodBatch( ...
        measurementValue, zeros(numberOfCandidates,1), noiseStd);

    componentCount = ...
        numel(vitalHypotheses) * numel(burialHypotheses);
    componentMeans = zeros(numberOfCandidates, componentCount);
    componentWeights = zeros(1, componentCount);
    componentVital = zeros(1, componentCount);
    componentIndex = 0;

    for vitalIndex = 1:numel(vitalHypotheses)
        for burialIndex = 1:numel(burialHypotheses)
            componentIndex = componentIndex + 1;
            totalMaterialLossDb = ...
                observableMaterialLossDb + ...
                sensorConfig.burialLossDb .* ...
                burialHypotheses(burialIndex);
            transmission = max(0, min(1, ...
                distanceTransmission .* ...
                10 .^ (-totalMaterialLossDb ./ 20)));
            componentMeans(:,componentIndex) = max(0, min(1, ...
                vitalHypotheses(vitalIndex) .* transmission));
            componentWeights(componentIndex) = ...
                vitalPrior(vitalIndex) * burialPrior(burialIndex);
            componentVital(componentIndex) = ...
                vitalHypotheses(vitalIndex);
        end
    end

    if string(sensorConfig.sourceModel) == "INTERMITTENT"
        eventProbability = min(1, ...
            sensorConfig.eventProbability .* ...
            (0.5 + 0.5 .* componentVital));
        componentMeans = [ ...
            sensorConfig.continuousActivityFloor .* componentMeans, ...
            componentMeans];
        componentWeights = [ ...
            componentWeights .* (1 - eventProbability), ...
            componentWeights .* eventProbability];
    end

    componentSigma = hypot( ...
        noiseStd, ...
        componentMeans .* sensorConfig.sourceVariationStd);
    componentLogLikelihoods = ...
        censoredGaussianLogLikelihoodBatch( ...
            measurementValue, componentMeans, componentSigma);
    componentLogWeights = log(max( ...
        realmin('double'), componentWeights));
    logLikelihoodH1 = rowLogSumExp( ...
        componentLogLikelihoods + componentLogWeights);

    logBayesFactor = logLikelihoodH1 - logLikelihoodH0;
    factorLimit = ...
        bayesianConfig.singleSensorLogBayesFactorLimit;
    logBayesFactor = max( ...
        -factorLimit, min(factorLimit, logBayesFactor));
    intensityEvidence = intensityEvidence + ...
        reliability .* logBayesFactor;
end


end


function logLikelihood = censoredGaussianLogLikelihoodBatch( ...
    value, meanValue, sigma)

sigma = max(1e-6, sigma);
minimumProbability = realmin('double');
if value <= 1e-12
    probability = normalCdf((0 - meanValue) ./ sigma);
    logLikelihood = log(max(minimumProbability, probability));
elseif value >= 1 - 1e-12
    probability = 1 - normalCdf((1 - meanValue) ./ sigma);
    logLikelihood = log(max(minimumProbability, probability));
else
    standardizedValue = (value - meanValue) ./ sigma;
    logLikelihood = ...
        -0.5 .* standardizedValue .^ 2 - ...
        log(sigma) - 0.5 * log(2*pi);
end

end


function value = rowLogSumExp(logValues)

maximumValue = max(logValues, [], 2);
value = maximumValue + ...
    log(sum(exp(logValues - maximumValue), 2));
invalidMaximum = ~isfinite(maximumValue);
value(invalidMaximum) = maximumValue(invalidMaximum);

end


function probabilities = normalizeProbabilityVector(probabilities)

if any(~isfinite(probabilities)) || ...
        any(probabilities < 0) || sum(probabilities) <= 0
    error( ...
        "updateSpatialBayesianMap:InvalidPrior", ...
        "Bayesian hypothesis priors must be finite and nonnegative.");
end
probabilities = probabilities ./ sum(probabilities);

end


function value = readUnitScalar(structure, fieldName)

value = 0;
if isfield(structure, fieldName) && ...
        isscalar(structure.(fieldName)) && ...
        isfinite(structure.(fieldName))
    value = clamp01(structure.(fieldName));
end

end


function validateSpatialPacket(processedPacket)

if ~isstruct(processedPacket) || ...
        ~isfield(processedPacket, 'spatialObservations') || ...
        ~isstruct(processedPacket.spatialObservations)
    error( ...
        "updateSpatialBayesianMap:InvalidPacket", ...
        "processedPacket must contain spatialObservations.");
end

sensorNames = {'radar', 'thermal', 'acoustic'};
for sensorIndex = 1:numel(sensorNames)
    if ~isfield( ...
            processedPacket.spatialObservations, ...
            sensorNames{sensorIndex})
        error( ...
            "updateSpatialBayesianMap:InvalidPacket", ...
            "A spatial sensor observation set is missing.");
    end
end

end


function density = gaussianDensity(residual, sigma)

sigma = max(1e-6, sigma);
density = exp(-0.5 .* (residual ./ sigma) .^ 2) ./ ...
    (sqrt(2*pi) .* sigma);

end


function probability = normalCdf(value)

probability = 0.5 .* (1 + erf(value ./ sqrt(2)));
probability = max(0, min(1, probability));

end


function angle = wrapAngle180(angle)

angle = mod(angle + 180, 360) - 180;

end


function probability = stableLogistic(logOdds)

probability = zeros(size(logOdds));
positiveMask = logOdds >= 0;
probability(positiveMask) = ...
    1 ./ (1 + exp(-logOdds(positiveMask)));
negativeExponent = exp(logOdds(~positiveMask));
probability(~positiveMask) = ...
    negativeExponent ./ (1 + negativeExponent);

end


function value = clamp01(value)

value(~isfinite(value)) = 0;
value = max(0, min(1, value));

end
