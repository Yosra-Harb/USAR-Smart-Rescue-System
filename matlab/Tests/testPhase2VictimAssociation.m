function tests = testPhase2VictimAssociation
%% ============================================================
% Test File : testPhase2VictimAssociation
%
% Description :
% اختبار ربط سجلات الضحايا للتأكد من:
%
% 1- دمج القياسات المتقاربة للضحية نفسها.
% 2- عدم تضخيم الثقة بقراءات متكررة من موضع المسبار نفسه.
% 3- احتساب المشاهدة الجديدة عندما يتحرك المسبار مسافة مستقلة.
% 4- عدم دمج ضحيتين حقيقيتين تفصل بينهما ست خلايا.
%% ============================================================

tests = functiontests(localfunctions);
% تحويل الدوال المحلية إلى اختبارات MATLAB

end

%% ============================================================
% Test Repeated Measurements of Same Victim
%% ============================================================

function testOnlySpatiallyIndependentMeasurementsIncreaseCount(testCase)

probe = createAssociationTestProbe();
% إنشاء مسبار بقاعدة بيانات ضحايا فارغة

priorityPacket = createPriorityTestPacket();
% إنشاء حزمة أولوية صالحة للاختبار

firstVitalityPacket = ...
    createVitalityTestPacket([20 20]);
% إنشاء القياس الأول للضحية

probe = updateVictimDatabase( ...
    probe, ...
    firstVitalityPacket, ...
    priorityPacket);
% تسجيل الضحية لأول مرة

firstStoredPosition = ...
    probe.memory.detectedVictims(1).position;

secondVitalityPacket = ...
    createVitalityTestPacket([22 21]);
% إنشاء قياس آخر قريب للضحية نفسها
% المسافة بين القياسين أقل من ثلاث خلايا

probe = updateVictimDatabase( ...
    probe, ...
    secondVitalityPacket, ...
    priorityPacket);
% تحديث قاعدة البيانات بالقياس الثاني

verifyEqual( ...
    testCase, ...
    numel(probe.memory.detectedVictims), ...
    1);
% يجب أن يبقى سجل ضحية واحد فقط

verifyEqual( ...
    testCase, ...
    probe.memory.detectedVictims(1).independentViewCount, ...
    1);
% القراءة الثانية مأخوذة من موضع المسبار نفسه، فلا تُعد تأكيدًا جديدًا

verifyEqual( ...
    testCase, ...
    probe.memory.detectedVictims(1).rawAssociationCount, ...
    2);
% مع ذلك تبقى القراءة الخام محفوظة لأغراض التشخيص

verifyEqual( ...
    testCase, ...
    probe.memory.detectedVictims(1).position, ...
    firstStoredPosition);
% العينة المكررة لا تسحب تقدير موقع الضحية

probe.position = [13 10];
% تحريك المسبار أكثر من مسافة الاستقلال المحددة

thirdVitalityPacket = ...
    createVitalityTestPacket([21 20]);

probe = updateVictimDatabase( ...
    probe, ...
    thirdVitalityPacket, ...
    priorityPacket);

verifyEqual( ...
    testCase, ...
    probe.memory.detectedVictims(1).independentViewCount, ...
    2);

verifyEqual( ...
    testCase, ...
    probe.memory.detectedVictims(1).detectionCount, ...
    2);
% اسم التوافق القديم يساوي عدد المشاهدات المستقلة

verifyEqual( ...
    testCase, ...
    probe.memory.detectedVictims(1).rawAssociationCount, ...
    3);

end

%% ============================================================
% Test Distinct Nearby Victims
%% ============================================================

function testVictimsSixCellsApartRemainDistinct(testCase)

probe = createAssociationTestProbe();
% إنشاء مسبار بقاعدة بيانات فارغة

priorityPacket = createPriorityTestPacket();
% إنشاء حزمة أولوية صالحة

firstVitalityPacket = ...
    createVitalityTestPacket([20 20]);
% موقع الضحية الأولى

probe = updateVictimDatabase( ...
    probe, ...
    firstVitalityPacket, ...
    priorityPacket);
% تسجيل الضحية الأولى

secondVitalityPacket = ...
    createVitalityTestPacket([20 26]);
% موقع ضحية ثانية تبعد ست خلايا عن الأولى

probe = updateVictimDatabase( ...
    probe, ...
    secondVitalityPacket, ...
    priorityPacket);
% محاولة تسجيل الضحية الثانية

verifyEqual( ...
    testCase, ...
    numel(probe.memory.detectedVictims), ...
    2);
% يجب أن تبقى الضحيتان في سجلين منفصلين

victimPositions = vertcat( ...
    probe.memory.detectedVictims.position);
% استخراج المواقع المسجلة

verifyTrue( ...
    testCase, ...
    any(all(victimPositions == [20 20], 2)));
% التأكد من وجود الضحية الأولى

verifyTrue( ...
    testCase, ...
    any(all(victimPositions == [20 26], 2)));
% التأكد من وجود الضحية الثانية وعدم دمجها

end

%% ============================================================
% Test Victim ID Allocation After Historical Merge Gap
%% ============================================================

function testNewVictimIDDoesNotReuseExistingIDAfterGap(testCase)

priorityPacket = createPriorityTestPacket();

firstPacket = createVitalityTestPacket([10 10]);
thirdPacket = createVitalityTestPacket([30 30]);

firstRecord = registerVictim( ...
    1, firstPacket, priorityPacket, [5 5]);
thirdRecord = registerVictim( ...
    3, thirdPacket, priorityPacket, [25 25]);
% نمثل حالة مشروعة بعد دمج سابق: السجل رقم 2 اختفى وبقيت IDs [1 3].

probe = createAssociationTestProbe();
probe.memory.detectedVictims = [firstRecord; thirdRecord];
probe.position = [45 45];

newPacket = createVitalityTestPacket([45 45]);
probe = updateVictimDatabase( ...
    probe, newPacket, priorityPacket);

ids = [probe.memory.detectedVictims.id];

verifyEqual(testCase, numel(ids), 3);
verifyEqual(testCase, numel(unique(ids)), 3);
verifyTrue(testCase, any(ids == 4));
verifyFalse(testCase, sum(ids == 3) > 1);

end

%% ============================================================
% Probe Helper
%% ============================================================

function probe = createAssociationTestProbe()

probe = struct();
% إنشاء هيكل مسبار مبسط

probe.memory = probeMemory();
% إنشاء ذاكرة مستقلة للاختبار

probe.position = [10 10];
% موضع أخذ القياس، ويُستخدم لاختبار استقلال المشاهدات

end

%% ============================================================
% Vitality Packet Helper
%% ============================================================

function vitalityPacket = ...
    createVitalityTestPacket(position)

vitalityPacket = struct();
% إنشاء حزمة حيوية وهمية

vitalityPacket.isVictimDetected = true;
% اعتبار القراءة اكتشافًا صالحًا

vitalityPacket.temporalStability = 0.90;
% استخدام استقرار زمني أعلى من حد التأكيد

vitalityPacket.vitalityIndex = 0.80;
% استخدام مؤشر حيوية أعلى من حد التسجيل

vitalityPacket.estimatedPosition = position;
% تحديد الموقع التقديري للاكتشاف

end

%% ============================================================
% Priority Packet Helper
%% ============================================================

function priorityPacket = createPriorityTestPacket()

priorityPacket = struct();
% إنشاء حزمة أولوية وهمية

priorityPacket.priorityScore = 0.80;
% استخدام درجة أولوية أعلى من حد التسجيل

priorityPacket.priorityLevel = "HIGH";
% تحديد مستوى الأولوية

end
