function probe = createProbe(scenario, searchMode)
%% ============================================================
% Function Name : createProbe
%
% Description :
% إنشاء المسبار الذكي وتهيئة حالته ومساراته وذاكرته.
% كما تقوم الدالة بإنشاء خرائط الأدلة المكانية بحيث تطابق
% حجم بيئة المحاكاة الحالية.
%% ============================================================

%% ============================================================
% Default Search Mode
%% ============================================================

if nargin < 2
    searchMode = "boustrophedon";
    % استخدام المسح صفًا بصف إذا لم يتم تحديد نمط آخر
end

probe = struct();
% إنشاء الهيكل الرئيسي للمسبار

%% ============================================================
% Basic Probe Information
%% ============================================================

probe.id = 1;
% إعطاء المسبار رقمًا تعريفيًا

probe.position = scenario.environment.entryPoint;
% وضع المسبار في نقطة الدخول المحددة داخل السيناريو

probe.startPosition = scenario.environment.entryPoint;
% حفظ نقطة البداية لاستخدامها في التقييم أو العودة

probe.searchMode = searchMode;
% حفظ نوع خوارزمية المسح المستخدمة

probe.state = "INITIALIZING";
% تعيين الحالة الابتدائية للمسبار

probe.currentStep = 1;
% البدء من أول نقطة في مسار التغطية

%% ============================================================
% Coverage Path
%% ============================================================

probe.coveragePath = generateCoveragePath( ...
    scenario, ...
    searchMode);
% إنشاء مسار التغطية الشامل وفق نمط البحث المختار

probe.headingDegrees = 0;
if size(probe.coveragePath,1) >= 2
    firstDirection = probe.coveragePath(2,:) - ...
        probe.coveragePath(1,:);
    if any(firstDirection ~= 0)
        probe.headingDegrees = atan2d( ...
            firstDirection(1), firstDirection(2));
    end
end
% 0 درجة شرقًا و+90 درجة جنوبًا وفق إحداثيات المصفوفة.

probe.path = probe.position;
% بدء سجل الحركة بموقع الدخول

probe.visitedCells = false( ...
    size(scenario.environment.debris));
% إنشاء مصفوفة تسجل الخلايا التي زارها المسبار

probe.visitedCells( ...
    probe.position(1), ...
    probe.position(2)) = true;
% تسجيل نقطة الدخول كأول خلية تمت زيارتها

probe.coverage = calculateCoverage(probe);
% حساب نسبة التغطية الأولية

%% ============================================================
% Probe Memory Initialization
%% ============================================================

probe.memory = probeMemory();
% إنشاء ذاكرة جديدة ومستقلة لكل تشغيل للمسبار

%% ============================================================
% Environment Dimensions
%% ============================================================

gridRows = size( ...
    scenario.environment.debris, ...
    1);
% استخراج عدد صفوف بيئة المحاكاة

gridColumns = size( ...
    scenario.environment.debris, ...
    2);
% استخراج عدد أعمدة بيئة المحاكاة

probe.memory.localizationState.gridSize = ...
    [gridRows, gridColumns];
% حفظ حجم البيئة داخل حالة تحديد الموقع

%% ============================================================
% Spatial Evidence Map Initialization
%% ============================================================

probe.memory.localizationState.evidenceSum = ...
    zeros(gridRows, gridColumns);
% إنشاء مصفوفة لتجميع الأدلة المكانية في كل خلية

probe.memory.localizationState.weightSum = ...
    zeros(gridRows, gridColumns);
% إنشاء مصفوفة لتجميع أوزان القياسات في كل خلية

probe.memory.localizationState.evidenceMap = ...
    zeros(gridRows, gridColumns);
% إنشاء خريطة الأدلة المطبّعة التي ستُستخدم لتقدير الموقع

probe.memory.localizationState.observationCount = ...
    zeros(gridRows, gridColumns);
% إنشاء مصفوفة لحساب عدد القياسات المؤثرة في كل خلية

probe.memory.localizationState.pointHistory = ...
    zeros(0,2);
% تصفير سجل المواقع لضمان استقلال كل تجربة

probe.memory.localizationState.scoreHistory = ...
    zeros(0,1);
% تصفير سجل قيم الدمج

probe.memory.localizationState.confidenceHistory = ...
    zeros(0,1);
% تصفير سجل درجات الثقة

probe.memory.localizationState.lastEstimatedPosition = [];
% لا يوجد موقع تقديري عند بداية المهمة

probe.memory.localizationState.lastPeakValue = 0;
% لا توجد قمة أدلة عند بداية المهمة

probe.memory.localizationState.confirmedPeakPositions = ...
    zeros(0,2);
% لا توجد قمم مؤكدة عند بداية المهمة

config = constants();
probe.memory.localizationMethod = ...
    string(config.localization.method);

if lower(string(config.localization.method)) == ...
        "spatialbayesianfusion"
    probe.memory.bayesianLocalizationState = ...
        initializeSpatialBayesianLocalizationState( ...
            [gridRows, gridColumns], ...
            config.bayesian.priorProbability);
elseif isempty(config.bayesian.priorProbability)
    probe.memory.bayesianLocalizationState = ...
        initializeBayesianLocalizationState( ...
            [gridRows, gridColumns]);
else
    probe.memory.bayesianLocalizationState = ...
        initializeBayesianLocalizationState( ...
            [gridRows, gridColumns], ...
            config.bayesian.priorProbability);
end
% تهيئة مستقلة تجعل التبديل بين الخوارزميتين قابلًا للاختبار.

%% ============================================================
% Additional Memory Compatibility
%% ============================================================

if ~isfield(probe.memory, 'priorityHistory')
    probe.memory.priorityHistory = [];
    % إنشاء سجل الأولوية إذا لم يكن موجودًا
end

%% ============================================================
% Detection Information
%% ============================================================

probe.detectedCandidates = [];
% لا توجد قراءات مرشحة عند بداية المهمة

probe.confirmedVictims = [];
% لا توجد ضحايا مؤكدة عند بداية المهمة

probe.lastSensorData = [];
% لا توجد حزمة حساسات سابقة

probe.lastProcessedData = [];
% لا توجد بيانات معالجة سابقة

probe.lastFusionData = [];
% لا توجد نتيجة دمج سابقة

probe.lastLocalizationData = [];
% لا توجد نتيجة تحديد موقع سابقة

probe.lastVitalityData = [];
% لا توجد نتيجة حيوية سابقة

probe.lastPriorityData = [];
% لا توجد نتيجة أولوية سابقة

probe.lastDecision = "NONE";
% لم يتخذ النظام أي قرار بعد

%% ============================================================
% Adaptive Local Search Initialization
%% ============================================================

probe.localSearch = struct();
% إنشاء حالة البحث المحلي التكيفي

probe.localSearch.active = false;
% البحث المحلي غير نشط عند بداية المهمة

probe.localSearch.center = [];
% لا يوجد مركز بحث محلي حتى الآن

probe.localSearch.path = [];
% لا يوجد مسار بحث محلي حتى الآن

probe.localSearch.radius = 2;
% بدء البحث المحلي بنصف قطر صغير

probe.localSearch.maximumRadius = 6;
% تحديد أكبر نصف قطر مسموح للبحث المحلي

probe.localSearch.currentStep = 1;
% تهيئة مؤشر خطوة البحث المحلي

probe.localSearch.expansionCount = 0;
% لم يتم توسيع منطقة البحث المحلي بعد

probe.localSearch.completedCenters = zeros(0,2);
% مراكز البحث المحلي التي استُكملت حتى أقصى نصف قطر.
% تمنع إعادة تشغيل دورة كاملة حول المنطقة نفسها.

probe.localSearch.lastCompletionReason = "NONE";
% سبب إنهاء آخر دورة بحث محلي لأغراض التتبع والاختبار.

%% ============================================================
% Mission Status
%% ============================================================

probe.finished = false;
% المهمة لم تنتهِ بعد

probe.state = "SEARCHING";
% نقل المسبار إلى حالة البحث

end
