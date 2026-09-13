function [missionRun, finalProbe, scenario] = ...
    runScenarioRequest(request, outputRoot)
%% ============================================================
% Function Name : runScenarioRequest
%
% Description :
% نقطة دخول الـBackend. تنشئ Mission ID قبل تشغيل المحاكاة،
% تفعّل Live Telemetry، تشغل النواة المجمدة، ثم تصدر النتائج النهائية.
%% ============================================================

if nargin < 2
    outputRoot = "";
end

[scenarioConfig, requestInfo] = scenarioRequestToConfig(request);
scenario = createScenario(scenarioConfig);

% يجب إنشاء Mission ID قبل بدء المحاكاة حتى تحمل كل Telemetry Record
% المعرف نفسه الذي سيستخدمه result.json وevaluation.json لاحقًا.
missionId = buildMissionId(scenario);
telemetryContext = prepareTelemetryContext( ...
    missionId, scenario, outputRoot);

probe = createProbe(scenario, "boustrophedon");
[simulationResult, finalProbe, telemetryInfo] = runProbeSimulation( ...
    scenario, probe, true, telemetryContext);

artifacts = exportMissionArtifacts( ...
    missionId, scenario, simulationResult, outputRoot);

completionRecord = buildTelemetryLifecycleRecord( ...
    "MISSION_COMPLETED", ...
    missionId, ...
    telemetryInfo.stepRecordsWritten + 1, ...
    scenario, ...
    simulationResult);
appendTelemetryJsonl( ...
    telemetryContext.telemetryPath, completionRecord);

artifacts.telemetryPath = telemetryContext.telemetryPath;
artifacts.telemetryRecordCount = ...
    telemetryInfo.stepRecordsWritten + 2;
% + MISSION_STARTED + MISSION_COMPLETED

missionRun = struct();
missionRun.missionId = missionId;
missionRun.requestInfo = requestInfo;
missionRun.scenarioConfig = scenarioConfig;
missionRun.simulationResult = simulationResult;
missionRun.telemetryInfo = telemetryInfo;
missionRun.artifacts = artifacts;

end


function missionId = buildMissionId(scenario)

milliseconds = round(posixtime(datetime("now")) * 1000);
missionId = "MISSION_" + string(milliseconds) + ...
    "_S" + string(scenario.randomSeed);

end
