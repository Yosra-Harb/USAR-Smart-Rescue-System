function memory = probeMemory()
%% ============================================================
% Function Name : probeMemory
%
% Description :
% إنشاء ذاكرة المسبار التي تحتفظ بجميع البيانات التاريخية
% اللازمة أثناء تنفيذ مهمة البحث والإنقاذ.
%
% تشمل الذاكرة:
% 1- سجل حركة المسبار.
% 2- سجل بيانات الحساسات.
% 3- سجل نتائج الدمج والحيوية والأولوية.
% 4- حالة خوارزمية تحديد الموقع.
% 5- خريطة الأدلة المكانية.
% 6- قاعدة بيانات الضحايا المكتشفين.
%% ============================================================

memory = struct();
% إنشاء الهيكل الرئيسي لذاكرة المسبار

%% ============================================================
% Probe Movement History
%% ============================================================

memory.positionHistory = zeros(0,2);
% تخزين جميع المواقع التي زارها المسبار بالشكل [row, column]

%% ============================================================
% Sensor History
%% ============================================================

memory.sensorHistory = [];
% تخزين ملخصات جودة قراءات الحساسات أثناء المهمة

%% ============================================================
% Operational State History
%% ============================================================

memory.stateHistory = strings(0,1);
% تخزين الحالات التشغيلية التي مر بها المسبار

memory.decisionHistory = strings(0,1);
% تخزين القرارات التي اتخذها النظام في كل خطوة

%% ============================================================
% Fusion and Victim Assessment History
%% ============================================================

memory.fusionHistory = [];
% تخزين قيم Fusion Score عبر الزمن

memory.vitalityHistory = [];
% تخزين قيم Vitality Index عبر الزمن

memory.priorityHistory = [];
% تخزين درجات أولوية الإنقاذ عبر الزمن

%% ============================================================
% Detection History
%% ============================================================

memory.suspiciousLocations = zeros(0,2);
% تخزين مواقع المسبار عند ظهور دليل أولي على وجود ضحية

memory.confirmedVictims = zeros(0,2);
% تخزين المواقع التي تم تأكيدها لاحقًا كمواقع ضحايا

%% ============================================================
% Localization State
%% ============================================================

LAST = struct();
% إنشاء حالة مستقلة لخوارزمية تحديد الموقع

localizationState.gridSize = [0 0];
% تخزين أبعاد بيئة المحاكاة، وسيتم ضبطها عند إنشاء المسبار

localizationState.evidenceSum = zeros(0,0);
% تخزين مجموع الأدلة المكانية المتراكمة في كل خلية

localizationState.weightSum = zeros(0,0);
% تخزين مجموع أوزان القياسات التي ساهمت في كل خلية

localizationState.evidenceMap = zeros(0,0);
% خريطة الأدلة النهائية بعد تطبيع الأدلة المتراكمة

localizationState.observationCount = zeros(0,0);
% تخزين عدد القياسات التي ساهمت في كل خلية

localizationState.pointHistory = zeros(0,2);
% الاحتفاظ بسجل نقاط الطريقة القديمة مؤقتًا لضمان التوافق

localizationState.scoreHistory = zeros(0,1);
% تخزين Fusion Score لكل قراءة مقبولة في التوطين

localizationState.confidenceHistory = zeros(0,1);
% تخزين درجة الثقة المقابلة لكل قراءة

localizationState.lastEstimatedPosition = [];
% تخزين آخر موقع تم تقديره للضحية

localizationState.lastPeakValue = 0;
% تخزين قوة أعلى قمة عُثر عليها في خريطة الأدلة
localizationState.lastCandidatePeakCount = 0;
% تخزين عدد القمم المحلية الموثوقة داخل آخر نافذة بحث
localizationState.confirmedPeakPositions = zeros(0,2);
% تخزين القمم المكانية التي اجتازت شروط التأكيد

memory.localizationState = localizationState;
% إضافة حالة تحديد الموقع إلى ذاكرة المسبار الرئيسية

memory.localizationMethod = "adaptiveEvidence";
% سيُستبدل عند إنشاء المسبار وفق إعدادات النسخة النشطة.

memory.bayesianLocalizationState = struct();
% حالة Bayesian TBD تُهيأ بعد معرفة أبعاد البيئة.

%% ============================================================
% Multi-Victim Database
%% ============================================================

memory.detectedVictims = struct( ...
    'id', {}, ...
    'position', {}, ...
    'vitalityIndex', {}, ...
    'victimCondition', {}, ...
    'priorityScore', {}, ...
    'priorityLevel', {}, ...
    'firstDetectionTime', {}, ...
    'lastUpdateTime', {}, ...
    'detectionCount', {}, ...
    'independentViewCount', {}, ...
    'rawAssociationCount', {}, ...
    'hasRangedMeasurementEvidence', {}, ...
    'rangedMeasurementAssociationCount', {}, ...
    'observationPositions', {}, ...
    'lastObservationPosition', {}, ...
    'rescueRank', {}, ...
    'rescuePriorityScore', {}, ...
    'reachable', {}, ...
    'shortestPath', {}, ...
    'recommendedPath', {}, ...
    'shortestPathLength', {}, ...
    'recommendedPathLength', {}, ...
    'recommendedTravelCost', {}, ...
    'meanRouteRisk', {}, ...
    'meanRouteAccessibility', {}, ...
    'rescueAccessPoint', {}, ...
    'priorityComponents', {});
% إنشاء قاعدة بيانات فارغة للضحايا المكتشفين
%
% id                 : رقم الضحية داخل النظام
% position           : الموقع التقديري للضحية
% vitalityIndex      : أحدث قيمة لمؤشر الحيوية
% priorityScore      : درجة أولوية الإنقاذ
% priorityLevel      : مستوى الأولوية
% firstDetectionTime : وقت أول اكتشاف
% lastUpdateTime     : وقت آخر تحديث
% detectionCount     : عدد التأكيدات المستقلة (اسم توافق قديم)
% independentViewCount : عدد مواقع المشاهدة المستقلة مكانيًا
% rawAssociationCount  : جميع القراءات المرتبطة، للتشخيص فقط
% hasRangedMeasurementEvidence : وجود قياس UWB مباشر في السجل
% rangedMeasurementAssociationCount : عدد ارتباطات UWB المباشرة
% observationPositions : مواقع المسبار التي قدمت تأكيدات مستقلة
% lastObservationPosition : أحدث موقع مشاهدة مستقل

end
