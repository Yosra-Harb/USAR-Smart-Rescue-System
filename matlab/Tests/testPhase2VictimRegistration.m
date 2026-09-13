function tests = testPhase2VictimRegistration
%% ============================================================
% Function Name : testPhase2VictimRegistration
%
% Description :
% اختبار تسجيل الضحايا والتأكد من:
% 1- تسجيل الضحية المؤكدة حتى لو كان Vitality Index منخفضًا.
% 2- رفض القراءة غير المستقرة زمنيًا.
% 3- عدم تسجيل قراءة غير مؤكدة كتحديد ضحية.
%% ============================================================

tests = functiontests(localfunctions);

end

%% ============================================================
% Test Low-Vitality Confirmed Victim
%% ============================================================

function testLowVitalityVictimIsRegistered(testCase)

probe = buildEmptyProbe();

vitalityPacket = buildVitalityPacketFixture( ...
    true, ...
    0.80, ...
    0.15, ...
    [20 25]);

priorityPacket = buildPriorityPacketFixture();

probe = updateVictimDatabase( ...
    probe, ...
    vitalityPacket, ...
    priorityPacket);

verifyNumElements( ...
    testCase, ...
    probe.memory.detectedVictims, ...
    1);

verifyEqual( ...
    testCase, ...
    probe.memory.detectedVictims(1).position, ...
    [20 25]);

verifyEqual( ...
    testCase, ...
    probe.memory.detectedVictims(1).vitalityIndex, ...
    0.15, ...
    'AbsTol', 1e-12);

end

%% ============================================================
% Test Temporally Unstable Candidate
%% ============================================================

function testUnstableCandidateIsStoredAsProvisionalRecord(testCase)
%% ============================================================
% Test:
% المرشح المكتشف مكانيًا يُحفظ كسجل أولي حتى لو كان
% الثبات الزمني الحالي منخفضًا، ولا يُعتبر ضحية مؤكدة
% إلا بعد اجتياز عدد المشاهدات المستقلة في التقرير النهائي.
%% ============================================================

probe = buildEmptyProbe();

vitalityPacket = buildVitalityPacketFixture( ...
    true, ...
    0.40, ...
    0.70, ...
    [20 25]);
% مرشح مكتشف مكانيًا بثبات زمني منخفض

priorityPacket = buildPriorityPacketFixture();

probe = updateVictimDatabase( ...
    probe, ...
    vitalityPacket, ...
    priorityPacket);

verifyNumElements( ...
    testCase, ...
    probe.memory.detectedVictims, ...
    1);
% يجب حفظ سجل أولي بدل حذفه

verifyEqual( ...
    testCase, ...
    probe.memory.detectedVictims(1).independentViewCount, ...
    1);
% السجل ما زال غير مؤكد لأنه يعتمد على مشاهدة مستقلة واحدة فقط

verifyEqual( ...
    testCase, ...
    probe.memory.detectedVictims(1).rawAssociationCount, ...
    1);
% تسجيل محاولة الارتباط الخام الأولى

end
%% ============================================================
% Test Unconfirmed Detection
%% ============================================================

function testUnconfirmedDetectionIsRejected(testCase)

probe = buildEmptyProbe();

vitalityPacket = buildVitalityPacketFixture( ...
    false, ...
    0.90, ...
    0.80, ...
    [20 25]);

priorityPacket = buildPriorityPacketFixture();

probe = updateVictimDatabase( ...
    probe, ...
    vitalityPacket, ...
    priorityPacket);

verifyEmpty( ...
    testCase, ...
    probe.memory.detectedVictims);

end

%% ============================================================
% Helper: Empty Probe
%% ============================================================

function probe = buildEmptyProbe()

probe = struct();

probe.memory = struct();

probe.memory.detectedVictims = struct([]);
% إنشاء قاعدة بيانات ضحايا فارغة

end

%% ============================================================
% Helper: Vitality Packet
%% ============================================================

function vitalityPacket = ...
    buildVitalityPacketFixture( ...
    isDetected, ...
    temporalStability, ...
    vitalityIndex, ...
    position)

vitalityPacket = struct();

vitalityPacket.isVictimDetected = isDetected;

vitalityPacket.temporalStability = ...
    temporalStability;

vitalityPacket.vitalityIndex = ...
    vitalityIndex;

vitalityPacket.estimatedPosition = ...
    position;

end

%% ============================================================
% Helper: Priority Packet
%% ============================================================

function priorityPacket = buildPriorityPacketFixture()

priorityPacket = struct();

priorityPacket.priorityScore = 0.80;

priorityPacket.priorityLevel = "HIGH";

end