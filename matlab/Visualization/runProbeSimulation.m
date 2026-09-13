function [simulationResult, probe, telemetryInfo] = ...
    runProbeSimulation(scenario, probe, fastMode, telemetryContext)
simulationResult = struct();
% تهيئة نتيجة افتراضية لضمان وجود قيمة إرجاع في جميع مسارات التنفيذ
%% ============================================================
% Function Name : runProbeSimulation
%
% Description :
% تشغيل مهمة المسبار خطوة بخطوة وعرض معلومات المهمة
% ونتائج الدمج، الحيوية، الأولوية، والقرار بشكل لحظي.
%
% بعد انتهاء المهمة تقوم الدالة بما يلي:
% 1- تصفية سجلات الضحايا ضعيفة التأكيد.
% 2- بناء مصفوفة مواقع الضحايا المكتشفين.
% 3- حساب مؤشرات أداء الكشف.
% 4- حساب خطأ تحديد الموقع.
% 5- عرض تقرير الأداء وقاعدة بيانات الضحايا.
%% ============================================================

%% ============================================================
% Create Simulation Figure
%% ============================================================

if nargin < 3

    fastMode = true;
    % التشغيل السريع هو الوضع الافتراضي عند عدم تمرير الخيار الثالث

end

if nargin < 4 || isempty(telemetryContext)
    telemetryContext = struct('enabled',false);
end

telemetryEnabled = ...
    isstruct(telemetryContext) && ...
    isfield(telemetryContext,'enabled') && ...
    logical(telemetryContext.enabled) && ...
    isfield(telemetryContext,'missionId') && ...
    isfield(telemetryContext,'telemetryPath');

telemetrySequence = 0;
previousVictimIDs = zeros(1,0);
telemetryInfo = struct( ...
    'enabled',telemetryEnabled, ...
    'stepRecordsWritten',0, ...
    'telemetryPath',"");
if telemetryEnabled
    telemetryInfo.telemetryPath = ...
        string(telemetryContext.telemetryPath);
end

if ~fastMode

figure;

imagesc(scenario.environment.debris);

colormap("turbo");

colorbar;

axis equal;
axis tight;

hold on;

title("USAR Probe Mission - Step by Step");

xlabel("X Position");

ylabel("Y Position");

%% ============================================================
% Plot Obstacles
%% ============================================================

[obsRows, obsCols] = ...
    find(scenario.environment.obstacles == 1);

plot( ...
    obsCols, ...
    obsRows, ...
    'ks', ...
    'MarkerSize', 4, ...
    'MarkerFaceColor', 'k');

%% ============================================================
% Plot Victim Ground Truth
%% ============================================================

plot( ...
    scenario.victims(:,2), ...
    scenario.victims(:,1), ...
    'rp', ...
    'MarkerSize', 14, ...
    'MarkerFaceColor', 'r');

%% ============================================================
% Plot Entry Point
%% ============================================================

entry = scenario.environment.entryPoint;

plot( ...
    entry(2), ...
    entry(1), ...
    'go', ...
    'MarkerSize', 12, ...
    'MarkerFaceColor', 'g');

%% ============================================================
% Plot Exit Point
%% ============================================================

exitPoint = scenario.environment.exitPoint;

plot( ...
    exitPoint(2), ...
    exitPoint(1), ...
    'co', ...
    'MarkerSize', 12, ...
    'MarkerFaceColor', 'c');

%% ============================================================
% Plot Probe Path
%% ============================================================

pathLine = plot( ...
    probe.position(2), ...
    probe.position(1), ...
    'g-', ...
    'LineWidth', 1.5);

probeMarker = plot( ...
    probe.position(2), ...
    probe.position(1), ...
    'bo', ...
    'MarkerSize', 10, ...
    'MarkerFaceColor', 'b');

%% ============================================================
% Information Window
%% ============================================================

infoText = text( ...
    2, ...
    10, ...
    "", ...
    'Color', 'w', ...
    'FontSize', 10, ...
    'FontWeight', 'bold', ...
    'BackgroundColor', 'k');

legend( ...
    "Obstacles", ...
    "Victim Ground Truth", ...
    "Entry Point", ...
    "Exit Point", ...
    "Probe Path", ...
    "Current Probe", ...
    'Location', ...
    'southoutside');

end
% في الوضع السريع لا تُنشأ مقابض رسومية أصلًا؛ هذا مهم للتقييمات
% التجميعية الطويلة، ولا يغير أي حساب في الحساسات أو التوطين.

%% ============================================================
% Main Simulation Loop
%% ============================================================

while ~probe.finished

    probe = missionController( ...
        scenario, ...
        probe);

    %% ========================================================
    % Live Telemetry Export
    %% ========================================================

    if telemetryEnabled && ~probe.finished
        telemetrySequence = telemetrySequence + 1;

        currentVictimIDs = zeros(1,0);
        if isfield(probe,'memory') && ...
                isstruct(probe.memory) && ...
                isfield(probe.memory,'detectedVictims') && ...
                ~isempty(probe.memory.detectedVictims)
            currentVictimIDs = ...
                [probe.memory.detectedVictims.id];
        end

        newVictimIDs = setdiff( ...
            currentVictimIDs, previousVictimIDs, 'stable');

        telemetryRecord = buildTelemetryRecord( ...
            telemetryContext.missionId, ...
            telemetrySequence, ...
            probe, ...
            newVictimIDs);

        appendTelemetryJsonl( ...
            telemetryContext.telemetryPath, ...
            telemetryRecord);

        previousVictimIDs = currentVictimIDs;
    end

    if fastMode

        continue;
        % تجاوز تحديثات الرسم والطباعة فقط مع استمرار الحسابات كاملة

    end

    %% ========================================================
    % Update Probe Path
    %% ========================================================

    set( ...
        pathLine, ...
        'XData', probe.path(:,2), ...
        'YData', probe.path(:,1));

    set( ...
        probeMarker, ...
        'XData', probe.position(2), ...
        'YData', probe.position(1));

    %% ========================================================
    % Default Runtime Values
    %% ========================================================

    fusionScore = 0;

    fusionConfidence = 0;

    priorityScore = 0;

    priorityLevel = "N/A";

    decisionText = "N/A";

    suspicionLevel = "N/A";

    %% ========================================================
    % Read Fusion Information
    %% ========================================================

    if isfield(probe, 'lastFusionData') && ...
            isstruct(probe.lastFusionData)

        if isfield(probe.lastFusionData, 'fusionScore')

            fusionScore = ...
                probe.lastFusionData.fusionScore;

        end

        if isfield(probe.lastFusionData, 'confidence')

            fusionConfidence = ...
                probe.lastFusionData.confidence;

        end

    end

    %% ========================================================
    % Read Priority Information
    %% ========================================================

    if isfield(probe, 'lastPriorityData') && ...
            isstruct(probe.lastPriorityData)

        if isfield(probe.lastPriorityData, 'priorityScore')

            priorityScore = ...
                probe.lastPriorityData.priorityScore;

        end

        if isfield(probe.lastPriorityData, 'priorityLevel')

            priorityLevel = ...
                string(probe.lastPriorityData.priorityLevel);

        end

    end

    %% ========================================================
    % Read Decision Information
    %% ========================================================

    if isfield(probe, 'lastDecision')

        decisionText = ...
            string(probe.lastDecision);

    end

    %% ========================================================
    % Calculate Suspicion Level
    %% ========================================================

    if isfield(probe, 'lastVitalityData') && ...
            isstruct(probe.lastVitalityData) && ...
            isfield(probe.lastVitalityData, 'vitalityIndex')

        suspicionLevel = ...
            classifySuspicion( ...
                probe.lastVitalityData.vitalityIndex);

    end

    %% ========================================================
    % Build Information Text
    %% ========================================================

    infoString = ...
        "State: " + string(probe.state) + newline + ...
        "Step: " + string(probe.currentStep) + ...
        " / " + string(size(probe.coveragePath,1)) + newline + ...
        "Position: (" + ...
        string(probe.position(2)) + ...
        ", " + ...
        string(probe.position(1)) + ")" + newline + ...
        "Coverage: " + ...
        string(round(probe.coverage * 100,2)) + ...
        " %" + newline + ...
        "Fusion Score: " + ...
        string(round(fusionScore,3)) + newline + ...
        "Confidence: " + ...
        string(round(fusionConfidence,3)) + newline + ...
        "Priority: " + ...
        string(round(priorityScore,3)) + newline + ...
        "Priority Level: " + ...
        string(priorityLevel) + newline + ...
        "Decision: " + ...
        string(decisionText) + newline + ...
        "Suspicion: " + ...
        string(suspicionLevel);

    set( ...
        infoText, ...
        'String', ...
        infoString);

    %% ========================================================
    % Progress Display
    %% ========================================================

    if mod(probe.currentStep,100) == 0

        disp([ ...
            'Step = ', ...
            num2str(probe.currentStep), ...
            ' / ', ...
            num2str(size(probe.coveragePath,1))]);

    end

    %% ========================================================
    % Update Figure Every 20 Steps
    %% ========================================================

    if mod(probe.currentStep,20) == 0

        drawnow;

    end

    pause(0);

end

%% ============================================================
% Validate Victim Database
%% ============================================================

if ~isfield(probe, 'memory') || ...
        ~isfield(probe.memory, 'detectedVictims')

    probe.memory.detectedVictims = struct([]);

end

%% ============================================================
% Filter Weak Victim Records
%% ============================================================

config = constants();

minimumIndependentViewCount = ...
    config.reporting.minimumIndependentViewCount;

isBayesianLocalization = ...
    isfield(probe.memory, 'localizationMethod') && ...
    any(lower(string(probe.memory.localizationMethod)) == ...
        ["bayesiantbd", "spatialbayesianfusion"]);

if ~isBayesianLocalization && ...
        ~isempty(probe.memory.detectedVictims)

    if isfield( ...
            probe.memory.detectedVictims, ...
            'independentViewCount')
        independentViewCounts = ...
            [probe.memory.detectedVictims.independentViewCount];
    else
        independentViewCounts = ...
            [probe.memory.detectedVictims.detectionCount];
        % توافق مع نتائج قديمة سبقت فصل العدادين.
    end

    validMask = ...
        independentViewCounts >= ...
        minimumIndependentViewCount;

    probe.memory.detectedVictims = ...
        probe.memory.detectedVictims(validMask);

end
%% ============================================================
% Consolidate Records Using Final Stable Peaks
%% ============================================================

if isBayesianLocalization

    [probe.memory.detectedVictims, ...
        finalStablePeaks, ...
        consolidationReport] = ...
        consolidateVictimRecordsByBayesianTracks( ...
            probe.memory.detectedVictims, ...
            probe.memory.bayesianLocalizationState);

    probe.memory.bayesianLocalizationState.finalStablePeaks = ...
        finalStablePeaks;
    probe.memory.bayesianLocalizationState.consolidationReport = ...
        consolidationReport;
else
    [probe.memory.detectedVictims, ...
        finalStablePeaks, ...
        consolidationReport] = ...
        consolidateVictimRecordsByStablePeaks( ...
            probe.memory.detectedVictims, ...
            probe.memory.localizationState);

    probe.memory.localizationState.finalStablePeaks = ...
        finalStablePeaks;
    probe.memory.localizationState.consolidationReport = ...
        consolidationReport;
end
% توحيد السجلات بالمسارات المؤكدة أو القمم القديمة دون Ground Truth.
%% ============================================================
% Build Rescue Routes and Operational Priority
%% ============================================================

[probe.memory.detectedVictims, rescuePlan] = ...
    planRescueOperations( ...
        scenario, ...
        probe.memory.detectedVictims, ...
        scenario.environment.entryPoint);
% حساب مسار أقصر ومسار موصى به آمن نسبيًا لكل ضحية من نقطة الدخول.

if ~fastMode && ~isempty(rescuePlan)
    for routeIndex = 1:numel(rescuePlan)
        route = rescuePlan(routeIndex).recommendedRoute;
        if route.reachable && ~isempty(route.path)
            plot(route.path(:,2),route.path(:,1),'m--', ...
                'LineWidth',1.5);
        end
    end
end
% عرض المسارات الموصى بها باللون البنفسجي المتقطع في الوضع المرئي.

%% ============================================================
% Rank Valid Victims
%% ============================================================

probe.memory.detectedVictims = ...
    rankVictims( ...
        probe.memory.detectedVictims);

%% ============================================================
% Build Detected Victim Position Matrix
%% ============================================================

numberOfVictims = ...
    numel(probe.memory.detectedVictims);

detectedVictims = ...
    zeros(numberOfVictims,2);

counter = 0;

for k = 1:numberOfVictims

    currentPosition = ...
        probe.memory.detectedVictims(k).position;

    if isnumeric(currentPosition) && ...
            numel(currentPosition) >= 2

        counter = counter + 1;

        detectedVictims(counter,:) = ...
            currentPosition(1,1:2);

    end

end

detectedVictims = ...
    detectedVictims(1:counter,:);

%% ============================================================
% Read Ground Truth Locations
%% ============================================================

if isstruct(scenario.groundTruth) && ...
        isfield(scenario.groundTruth, 'locations')

    groundTruth = ...
        scenario.groundTruth.locations;

else

    error( ...
        "runProbeSimulation:InvalidGroundTruth", ...
        "scenario.groundTruth.locations is missing.");

end

%% ============================================================
% Detection Performance Evaluation
%% ============================================================

[TP, TN, FP, FN, matchedDistances] = ...
    confusionMatrix( ...
        detectedVictims, ...
        groundTruth);

metrics = ...
    detectionMetrics( ...
        TP, ...
        TN, ...
        FP, ...
        FN);

%% ============================================================
% Priority Evaluation
%% ============================================================

if isfield(probe.memory, 'priorityHistory')

    priorityResult = ...
        priorityEvaluation( ...
            probe.memory.priorityHistory);

else

    priorityResult = ...
        priorityEvaluation([]);

end

%% ============================================================
% Localization Error Evaluation
%% ============================================================

localError = NaN;
% يكون خطأ الموقع غير معرف إذا لم توجد أزواج صحيحة متطابقة

if ~isempty(matchedDistances)

    localError = mean(matchedDistances);
    % حساب متوسط خطأ الموقع للأزواج المتطابقة واحدًا لواحد فقط

end

%% ============================================================
% Fusion History Information
%% ============================================================

disp(' ');
disp('========== FUSION HISTORY ==========');

if isfield(probe.memory, 'fusionHistory') && ...
        ~isempty(probe.memory.fusionHistory)

    disp(['Fusion History Size: ', ...
        num2str(numel(probe.memory.fusionHistory))]);

    disp(['Maximum Fusion Score: ', ...
        num2str(max(probe.memory.fusionHistory))]);

    disp(['Mean Fusion Score: ', ...
        num2str(mean(probe.memory.fusionHistory))]);

else

    disp('Fusion History is empty.');

end

disp('====================================');

%% ============================================================
% Performance Report
%% ============================================================

evidenceMapForDisplay = ...
    getEvidenceMapForDisplay(probe.memory);
% قراءة خريطة الأدلة من بنية Localization الحالية، مع دعم بنية
% checkpoints القديمة التي خزنتها مباشرة داخل memory.

if ~fastMode && ~isempty(evidenceMapForDisplay)
    figure;
    imagesc(evidenceMapForDisplay);
    colorbar;
    title('Victim Evidence Heatmap');
    axis equal;
    axis tight;
elseif ~fastMode
    warning( ...
        "runProbeSimulation:EvidenceMapUnavailable", ...
        "Evidence map is unavailable; heatmap was not drawn.");
end

performanceReport( ...
    metrics, ...
    localError, ...
    priorityResult);

%% ============================================================
% Detected Victims Database
%% ============================================================

disp(' ');
disp('========== DETECTED VICTIMS ==========');

if isempty(probe.memory.detectedVictims)

    disp('No valid victims registered.');

else

    disp([ ...
        'Number of Valid Victims: ', ...
        num2str(numel(probe.memory.detectedVictims))]);

    for k = 1:numel(probe.memory.detectedVictims)

        currentVictim = ...
            probe.memory.detectedVictims(k);

        disp(' ');
        disp(['Victim ID: ', ...
            num2str(currentVictim.id)]);

        disp(['Position: ', ...
            num2str(currentVictim.position)]);

        disp(['Vitality Index: ', ...
            num2str(currentVictim.vitalityIndex)]);

        disp(['Priority Score: ', ...
            num2str(currentVictim.priorityScore)]);

        disp(['Priority Level: ', ...
            char(string(currentVictim.priorityLevel))]);

        if isfield(currentVictim, 'rescueRank')
            disp(['Rescue Rank: ', ...
                num2str(currentVictim.rescueRank)]);
            disp(['Reachable: ', ...
                char(string(currentVictim.reachable))]);
            disp(['Shortest Path Length: ', ...
                num2str(currentVictim.shortestPathLength)]);
            disp(['Recommended Path Length: ', ...
                num2str(currentVictim.recommendedPathLength)]);
            disp(['Mean Route Risk: ', ...
                num2str(currentVictim.meanRouteRisk)]);
        end

        if isfield(currentVictim, 'independentViewCount')
            disp(['Independent View Count: ', ...
                num2str(currentVictim.independentViewCount)]);
        else
            disp(['Independent View Count (legacy): ', ...
                num2str(currentVictim.detectionCount)]);
        end

        if isfield(currentVictim, 'rawAssociationCount')
            disp(['Raw Association Count: ', ...
                num2str(currentVictim.rawAssociationCount)]);
        end

    end

end

disp('======================================');

%% ============================================================
% Final Figure Update
%% ============================================================

if ~fastMode
    drawnow;
end

%% Build Machine-Readable Simulation Result
% الكود السابق كاملًا هنا
simulationResult = struct();
% إنشاء هيكل موحد لنتائج المحاكاة

%% Scenario Information

if isfield(scenario, 'type')
    simulationResult.scenarioType = string(scenario.type);
else
    simulationResult.scenarioType = "Unknown";
end
% حفظ نوع السيناريو

if isfield(scenario, 'randomSeed')
    simulationResult.randomSeed = scenario.randomSeed;
else
    simulationResult.randomSeed = NaN;
end
% حفظ البذرة العشوائية لإعادة التجربة

%% Detection Results

simulationResult.groundTruthVictimCount = ...
    size(groundTruth, 1);
% عدد الضحايا الحقيقيين

simulationResult.systemDetectionCount = ...
    size(detectedVictims, 1);
% عدد الضحايا المكتشفين

simulationResult.truePositives = TP;
% عدد الاكتشافات الصحيحة

simulationResult.trueNegatives = TN;
% عدد السلبيات الصحيحة إذا كان معرفًا

simulationResult.falsePositives = FP;
% عدد الإنذارات الكاذبة

simulationResult.falseNegatives = FN;
% عدد الضحايا غير المكتشفين

simulationResult.metrics = metrics;
% حفظ جميع مقاييس الكشف

%% Localization Results

simulationResult.localizationError = localError;
% متوسط خطأ التوطين للأزواج الصحيحة المتطابقة

simulationResult.matchedDistances = matchedDistances;
% أخطاء المواقع الفردية

simulationResult.detectedVictimPositions = detectedVictims;
% مواقع الضحايا المقدرة

simulationResult.groundTruthPositions = groundTruth;
% المواقع الحقيقية المستخدمة في التقييم فقط

%% Victim Database and Priority

simulationResult.detectedVictimDatabase = ...
    probe.memory.detectedVictims;
% حفظ قاعدة بيانات الضحايا النهائية
simulationResult.rescuePlan = rescuePlan;

telemetryInfo.stepRecordsWritten = telemetrySequence;
% المسار الأقصر والمسار الموصى به وترتيب الإنقاذ لكل ضحية.
simulationResult.finalStablePeaks = ...
    finalStablePeaks;
% القمم المستقرة المستخرجة من خريطة الأدلة النهائية

simulationResult.victimConsolidationReport = ...
    consolidationReport;
% تفاصيل عدد السجلات قبل التجميع وبعده
simulationResult.priorityResult = priorityResult;
% حفظ نتائج تقييم الأولوية

simulationResult.localizationMethod = ...
    string(probe.memory.localizationMethod);

if isBayesianLocalization
    simulationResult.maximumPosteriorProbability = max( ...
        probe.memory.bayesianLocalizationState.probabilityMap(:));
    trackStatuses = string({ ...
        probe.memory.bayesianLocalizationState.tracks.status});
    simulationResult.confirmedTrackCount = nnz( ...
        trackStatuses == "CONFIRMED");
else
    simulationResult.maximumPosteriorProbability = NaN;
    simulationResult.confirmedTrackCount = NaN;
end
% تشخيصات خوارزمية التوطين المستخدمة في هذا التشغيل.

%% Fusion Statistics

if isfield(probe.memory, 'fusionHistory') && ...
        ~isempty(probe.memory.fusionHistory)

    simulationResult.fusionHistorySize = ...
        numel(probe.memory.fusionHistory);

    simulationResult.maximumFusionScore = ...
        max(probe.memory.fusionHistory);

    simulationResult.meanFusionScore = ...
        mean(probe.memory.fusionHistory);

else

    simulationResult.fusionHistorySize = 0;
    simulationResult.maximumFusionScore = NaN;
    simulationResult.meanFusionScore = NaN;

end
% حفظ إحصاءات الدمج التكيفي
end
