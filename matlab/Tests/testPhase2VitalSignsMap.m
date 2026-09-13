function tests = testPhase2VitalSignsMap
%% ============================================================
% Test File : testPhase2VitalSignsMap
%
% Description :
% اختبار خريطة العلامات الحيوية للتأكد من:
%
% 1- وقوع أعلى قمة عند موقع الضحية.
% 2- انخفاض الإشارة بوضوح مع المسافة.
% 3- دعم ضحايا بقيم حيوية مختلفة.
%% ============================================================

tests = functiontests(localfunctions);
% تحويل الدوال المحلية إلى اختبارات MATLAB

end

%% ============================================================
% Test Peak Location
%% ============================================================

function testVitalPeakMatchesVictimLocation(testCase)

scenario = createMapTestScenario( ...
    [25 25], ...
    0.80);
% إنشاء سيناريو يحتوي ضحية واحدة في مركز الخريطة

vitalMap = generateVitalSignsMap(scenario);
% إنشاء خريطة العلامات الحيوية

[~, maximumIndex] = max(vitalMap(:));
% استخراج موقع أعلى قيمة في الخريطة

[peakRow, peakColumn] = ind2sub( ...
    size(vitalMap), ...
    maximumIndex);
% تحويل فهرس القمة إلى صف وعمود

verifyEqual( ...
    testCase, ...
    [peakRow, peakColumn], ...
    [25 25]);
% يجب أن تقع أعلى قمة عند موقع الضحية نفسه

verifyEqual( ...
    testCase, ...
    vitalMap(25,25), ...
    0.80, ...
    'AbsTol', 1e-12);
% قيمة القمة يجب أن تساوي قوة الضحية الحيوية

end

%% ============================================================
% Test Spatial Signal Decay
%% ============================================================

function testVitalSignalDecreasesWithDistance(testCase)

scenario = createMapTestScenario( ...
    [25 25], ...
    0.80);
% إنشاء ضحية واحدة في مركز الخريطة

vitalMap = generateVitalSignsMap(scenario);
% إنشاء خريطة العلامات الحيوية

config = constants();
% قراءة إعداد الانتشار المكاني

testDistance = round( ...
    2 * config.environment.vitalFieldSigma);
% اختيار مسافة تقارب ضعف Sigma

peakValue = vitalMap(25,25);
% قراءة الإشارة عند موقع الضحية

distantValue = vitalMap( ...
    25, ...
    25 + testDistance);
% قراءة الإشارة على بعد يقارب ضعف Sigma

signalRatio = distantValue / peakValue;
% حساب نسبة الإشارة البعيدة إلى القمة

verifyLessThan( ...
    testCase, ...
    signalRatio, ...
    0.20);
% عند مسافة تقارب 2 Sigma يجب أن تقل الإشارة عن 20% من القمة

verifyGreaterThanOrEqual( ...
    testCase, ...
    signalRatio, ...
    0);
% التأكد من أن الإشارة لا تصبح سالبة

end

%% ============================================================
% Test Multiple Victim Strengths
%% ============================================================

function testMapSupportsDifferentVictimStrengths(testCase)

scenario = createMapTestScenario( ...
    [15 15; 35 35], ...
    [0.80; 0.50]);
% إنشاء ضحيتين بعيدتين بقوتين حيويتين مختلفتين

vitalMap = generateVitalSignsMap(scenario);
% إنشاء خريطة العلامات الحيوية

verifyEqual( ...
    testCase, ...
    vitalMap(15,15), ...
    0.80, ...
    'AbsTol', 1e-10);
% قمة الضحية الأولى يجب أن تساوي قوتها الحيوية

verifyEqual( ...
    testCase, ...
    vitalMap(35,35), ...
    0.50, ...
    'AbsTol', 1e-10);
% قمة الضحية الثانية يجب أن تساوي قوتها الحيوية

verifyLessThan( ...
    testCase, ...
    vitalMap(25,25), ...
    0.10);
% المنطقة البعيدة بين الضحيتين يجب ألا تحمل إشارة مرتفعة مصطنعة

end

%% ============================================================
% Scenario Helper
%% ============================================================

function scenario = ...
    createMapTestScenario(victimLocations, vitalStrengths)

scenario = struct();
% إنشاء سيناريو مبسط مخصص للاختبار

scenario.gridSize = [50 50];
% تحديد حجم البيئة

scenario.victims = victimLocations;
% تحديد مواقع الضحايا

scenario.vitalStrength = vitalStrengths;
% تحديد قوة العلامات الحيوية لكل ضحية

end