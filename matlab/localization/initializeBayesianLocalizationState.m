function state = initializeBayesianLocalizationState( ...
    gridSize, ...
    priorProbability)
%% ============================================================
% Function Name : initializeBayesianLocalizationState
%
% Description :
% تهيئة حالة التوطين البايزي على شبكة البيئة.
%
% تحفظ الحالة:
% 1- خريطة Log-Odds الكلية.
% 2- احتمال وجود ضحية في كل خلية.
% 3- مساهمة كل حساس بصورة مستقلة.
% 4- عدد المشاهدات والدعم الموزون.
% 5- القمم والمسارات الاحتمالية.
%
% لا تستخدم الدالة مواقع الضحايا الحقيقية أو عددهم الحقيقي.
%% ============================================================

%% ============================================================
% Validate Grid Size
%% ============================================================

if ~isnumeric(gridSize) || ...
        numel(gridSize) ~= 2 || ...
        any(~isfinite(gridSize)) || ...
        any(gridSize < 1) || ...
        any(gridSize ~= round(gridSize))

    error( ...
        "initializeBayesianLocalizationState:InvalidGridSize", ...
        "gridSize must contain two positive integers.");

end

gridSize = double(gridSize(:)');
% توحيد الحجم بالشكل [rows columns]

numberOfRows = gridSize(1);
numberOfColumns = gridSize(2);

%% ============================================================
% Sparse Prior Probability
%% ============================================================

if nargin < 2 || isempty(priorProbability)

    priorProbability = ...
        1 / (numberOfRows * numberOfColumns);
    % Prior محافظ يعادل ضحية متوقعة واحدة موزعة على الشبكة.
    % لا يعني أن النظام يعرف عدد الضحايا الحقيقي.

end

if ~isscalar(priorProbability) || ...
        ~isfinite(priorProbability) || ...
        priorProbability <= 0 || ...
        priorProbability >= 1

    error( ...
        "initializeBayesianLocalizationState:InvalidPrior", ...
        "priorProbability must be strictly between zero and one.");

end

minimumProbability = 1e-6;
maximumProbability = 1 - minimumProbability;

priorProbability = max( ...
    minimumProbability, ...
    min(maximumProbability, priorProbability));

priorLogOdds = log( ...
    priorProbability / ...
    (1 - priorProbability));
% تحويل الاحتمال القبلي إلى Log-Odds

%% ============================================================
% Initialize Core Probability Maps
%% ============================================================

state = struct();

state.gridSize = gridSize;

state.priorProbability = priorProbability;
state.priorLogOdds = priorLogOdds;

state.logOddsMap = ...
    priorLogOdds .* ones(numberOfRows, numberOfColumns);
% خريطة الأدلة البايزية المتراكمة

state.probabilityMap = ...
    priorProbability .* ones(numberOfRows, numberOfColumns);
% النسخة الاحتمالية من الخريطة

%% ============================================================
% Initialize Per-Sensor Evidence Maps
%% ============================================================

state.sensorLogBayesFactorMaps = struct();

state.sensorLogBayesFactorMaps.radar = ...
    zeros(numberOfRows, numberOfColumns);

state.sensorLogBayesFactorMaps.thermal = ...
    zeros(numberOfRows, numberOfColumns);

state.sensorLogBayesFactorMaps.acoustic = ...
    zeros(numberOfRows, numberOfColumns);
% الاحتفاظ بمساهمة كل حساس لشرح القرار وتحليل الإزالة Ablation

%% ============================================================
% Initialize Observation Support
%% ============================================================

state.observationCount = ...
    zeros(numberOfRows, numberOfColumns);
% عدد القياسات التي دعمت كل خلية

state.weightedObservationSupport = ...
    zeros(numberOfRows, numberOfColumns);
% مجموع موثوقية القياسات المؤثرة في كل خلية

state.lastObservationStep = ...
    zeros(numberOfRows, numberOfColumns);
% آخر خطوة حصلت فيها الخلية على دليل

state.updateCount = 0;
% عدد تحديثات النظام البايزي

state.lastProbePosition = [];
% آخر موقع للمسبار استُخدم في التحديث

%% ============================================================
% Initialize Peak Diagnostics
%% ============================================================

state.lastAdaptiveThreshold = NaN;

state.lastBackgroundMedian = NaN;

state.lastBackgroundRobustSigma = NaN;

state.lastCandidatePeakCount = 0;

state.lastPeaks = emptyBayesianPeakArray();
% لا توجد قمم عند التهيئة

%% ============================================================
% Initialize Probabilistic Victim Tracks
%% ============================================================

state.tracks = emptyBayesianTrackArray();
% لا توجد مسارات ضحايا أولية أو مؤكدة

state.nextTrackID = 1;
% أول رقم لمسار جديد

end

%% ============================================================
% Empty Peak Structure
%% ============================================================

function peaks = emptyBayesianPeakArray()

peaks = struct( ...
    'row', {}, ...
    'column', {}, ...
    'probability', {}, ...
    'logOdds', {}, ...
    'prominence', {}, ...
    'uncertaintyRadius', {}, ...
    'sourceType', {});

end

%% ============================================================
% Empty Track Structure
%% ============================================================

function tracks = emptyBayesianTrackArray()

tracks = struct( ...
    'id', {}, ...
    'position', {}, ...
    'existenceProbability', {}, ...
    'covariance', {}, ...
    'updateCount', {}, ...
    'independentViewCount', {}, ...
    'observationPositions', {}, ...
    'maximumProbability', {}, ...
    'missedUpdateCount', {}, ...
    'status', {}, ...
    'lastUpdateStep', {}, ...
    'updateStepHistory', {}, ...
    'rangedMeasurementUpdateCount', {}, ...
    'independentRangedViewCount', {}, ...
    'rangedObservationPositions', {});

end
