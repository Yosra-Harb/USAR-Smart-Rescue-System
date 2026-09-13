function telemetryContext = prepareTelemetryContext( ...
    missionId, scenario, outputRoot)
%% ============================================================
% Function Name : prepareTelemetryContext
%
% Description :
% تهيئة ملف telemetry.jsonl قبل بدء المهمة. الملف Append-Only حتى
% يستطيع الـBackend قراءته تدريجيًا أثناء تشغيل MATLAB، كما يقلل
% فقد البيانات إذا انقطع التشغيل بعد تسجيل خطوات سابقة.
%% ============================================================

if nargin < 3 || strlength(string(outputRoot)) == 0
    integrationFolder = fileparts(mfilename('fullpath'));
    projectRoot = fileparts(integrationFolder);
    outputRoot = fullfile(projectRoot, 'Outputs', 'missions');
end

missionId = string(missionId);
missionFolder = fullfile(string(outputRoot), missionId);
if ~isfolder(missionFolder)
    mkdir(missionFolder);
end

telemetryPath = fullfile(missionFolder, 'telemetry.jsonl');

% ابدأ ملفًا جديدًا لنفس Mission ID بدل إضافة بيانات تشغيل قديم.
fileId = fopen(telemetryPath, 'w', 'n', 'UTF-8');
if fileId < 0
    error( ...
        "prepareTelemetryContext:OpenFailed", ...
        "Could not create telemetry file: %s", telemetryPath);
end
fclose(fileId);

telemetryContext = struct();
telemetryContext.enabled = true;
telemetryContext.schemaVersion = "1.1";
telemetryContext.missionId = missionId;
telemetryContext.missionFolder = string(missionFolder);
telemetryContext.telemetryPath = string(telemetryPath);

startRecord = buildTelemetryLifecycleRecord( ...
    "MISSION_STARTED", missionId, 0, scenario, []);
appendTelemetryJsonl(telemetryPath, startRecord);

end
