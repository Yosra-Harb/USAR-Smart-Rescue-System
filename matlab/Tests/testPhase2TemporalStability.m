function tests = testPhase2TemporalStability
%% ============================================================
% Function Name : testPhase2TemporalStability
%
% Description :
% اختبار حساب الثبات الزمني المحلي والتأكد من:
% 1- ارتفاع الثبات للقياسات المحلية المتسقة.
% 2- انخفاضه للقياسات المتذبذبة.
% 3- تجاهل القياسات البعيدة مكانيًا.
% 4- التعامل الآمن مع التاريخ غير الكافي.
% 5- عدم إنتاج NaN عند القراءات الصفرية.
%% ============================================================

tests = functiontests(localfunctions);

end

%% ============================================================
% Test Stable Local Measurements
%% ============================================================

function testStableLocalMeasurements(testCase)

points = [ ...
    10 10;
    10 11;
    11 10;
    11 11;
    10 10];

scores = [ ...
    0.140;
    0.150;
    0.145;
    0.150;
    0.148];

probe = buildTestProbe(points, scores);

stability = calculateTemporalStability(probe);

verifyGreaterThanOrEqual( ...
    testCase, ...
    stability, ...
    0.85);

end

%% ============================================================
% Test Fluctuating Local Measurements
%% ============================================================

function testFluctuatingMeasurementsProduceLowerStability(testCase)

points = [ ...
    10 10;
    10 11;
    11 10;
    11 11;
    10 10];

scores = [ ...
    0.05;
    0.30;
    0.08;
    0.28;
    0.10];

probe = buildTestProbe(points, scores);

stability = calculateTemporalStability(probe);

verifyLessThan( ...
    testCase, ...
    stability, ...
    0.75);

end

%% ============================================================
% Test Distant Measurements Are Ignored
%% ============================================================

function testDistantMeasurementsAreIgnored(testCase)

points = [ ...
     1  1;
     2  2;
     3  1;
    20 20;
    20 21;
    21 20];

scores = [ ...
    0.95;
    0.01;
    0.90;
    0.15;
    0.15;
    0.15];

probe = buildTestProbe(points, scores);

stability = calculateTemporalStability(probe);

verifyGreaterThanOrEqual( ...
    testCase, ...
    stability, ...
    0.85);

end

%% ============================================================
% Test Insufficient Local History
%% ============================================================

function testInsufficientHistoryReturnsNeutralValue(testCase)

points = [ ...
    10 10;
    10 11];

scores = [ ...
    0.15;
    0.16];

probe = buildTestProbe(points, scores);

stability = calculateTemporalStability(probe);

verifyEqual( ...
    testCase, ...
    stability, ...
    0.5, ...
    'AbsTol', 1e-12);

end

%% ============================================================
% Test Zero Signal Does Not Produce NaN
%% ============================================================

function testZeroSignalRemainsFinite(testCase)

points = [ ...
    10 10;
    10 11;
    11 10;
    10 10];

scores = zeros(4,1);

probe = buildTestProbe(points, scores);

stability = calculateTemporalStability(probe);

verifyTrue( ...
    testCase, ...
    isfinite(stability));

verifyGreaterThanOrEqual( ...
    testCase, ...
    stability, ...
    0);

verifyLessThanOrEqual( ...
    testCase, ...
    stability, ...
    1);

end

%% ============================================================
% Helper: Build Probe
%% ============================================================

function probe = buildTestProbe(points, scores)

probe = struct();

probe.memory = struct();

probe.memory.localizationState = struct();

probe.memory.localizationState.pointHistory = points;

probe.memory.localizationState.scoreHistory = scores(:);

end


function testSpatialBayesianTrackProvidesTemporalStability(testCase)

probe = struct();
probe.memory = struct();
probe.memory.localizationMethod = ...
    "spatialBayesianFusion";

state = initializeSpatialBayesianLocalizationState( ...
    [30 30], 0.01);
peak = struct( ...
    'row', 12, ...
    'column', 14, ...
    'probability', 0.95, ...
    'logOdds', log(0.95/0.05), ...
    'prominence', 0.2, ...
    'uncertaintyRadius', 1.0);
state.updateCount = 1;
state = updateBayesianVictimTracks( ...
    state, peak, [10 10]);
probe.memory.bayesianLocalizationState = state;

localizationPacket = struct( ...
    'isVictimDetected', true, ...
    'estimatedPosition', [12 14]);

stability = calculateTemporalStability( ...
    probe, localizationPacket);

verifyGreaterThan(testCase, stability, 0.60);
verifyLessThanOrEqual(testCase, stability, 1);

end
