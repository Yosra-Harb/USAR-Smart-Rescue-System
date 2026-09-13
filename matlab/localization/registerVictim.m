function victim = registerVictim( ...
    victimID, ...
    vitalityPacket, ...
    priorityPacket, ...
    observationPosition)
%% ============================================================
% Function Name : registerVictim
%
% Description :
% إنشاء سجل ضحية جديد داخل قاعدة بيانات الضحايا.
%% ============================================================

victim = struct();

if nargin < 4 || ...
        ~isValidPosition(observationPosition)

    observationPosition = ...
        vitalityPacket.estimatedPosition;
    % مسار توافق للاختبارات أو الاستدعاءات القديمة التي لا تمرر موقع المسبار

end

%% ============================================================
% Basic Information
%% ============================================================

victim.id = victimID;

victim.position = ...
    vitalityPacket.estimatedPosition;

%% ============================================================
% Victim Assessment
%% ============================================================

victim.vitalityIndex = ...
    vitalityPacket.vitalityIndex;

if isfield(vitalityPacket, 'victimCondition')
    victim.victimCondition = vitalityPacket.victimCondition;
else
    victim.victimCondition = estimateVictimCondition( ...
        vitalityPacket.vitalityIndex);
end

victim.priorityScore = ...
    priorityPacket.priorityScore;

victim.priorityLevel = ...
    priorityPacket.priorityLevel;

%% ============================================================
% Time Information
%% ============================================================

victim.firstDetectionTime = ...
    datetime("now");

victim.lastUpdateTime = ...
    datetime("now");

%% ============================================================
% Statistics
%% ============================================================

victim.detectionCount = 1;
% أصبح هذا العداد يمثل تأكيدًا مستقلًا، لا كل قراءة مرتبطة.

victim.independentViewCount = 1;
% عدد مواقع المشاهدة المستقلة.

victim.rawAssociationCount = 1;
% العدد الخام لجميع القراءات المرتبطة بالسجل، للتشخيص فقط.

victim.hasRangedMeasurementEvidence = ...
    isfield(vitalityPacket,'sourceType') && ...
    string(vitalityPacket.sourceType) == ...
        "RANGED_MEASUREMENT";
victim.rangedMeasurementAssociationCount = ...
    double(victim.hasRangedMeasurementEvidence);
% تحفظ قاعدة البيانات مصدر القياس كي لا يُنقذ سجل خريطي ضعيف لاحقًا
% كما لو كان فرضية UWB مستقلة متعددة المشاهدات.

victim.observationPositions = ...
    observationPosition(1:2);
% أول موقع للمسبار قدم دليلًا مستقلًا.

victim.lastObservationPosition = ...
    observationPosition(1:2);

victim.rescueRank = NaN;
victim.rescuePriorityScore = NaN;
victim.reachable = false;
victim.shortestPath = zeros(0,2);
victim.recommendedPath = zeros(0,2);
victim.shortestPathLength = Inf;
victim.recommendedPathLength = Inf;
victim.recommendedTravelCost = Inf;
victim.meanRouteRisk = NaN;
victim.meanRouteAccessibility = NaN;
victim.rescueAccessPoint = zeros(0,2);
victim.priorityComponents = struct();

end

function isValid = isValidPosition(position)

isValid = ...
    isnumeric(position) && ...
    numel(position) >= 2 && ...
    all(isfinite(position(1:2)));

end
