function appendTelemetryJsonl(filePath, record)
%% ============================================================
% Function Name : appendTelemetryJsonl
%
% Description :
% إضافة Telemetry Record واحد كسطر JSON مستقل. نفتح ونغلق الملف
% لكل سجل عمدًا حتى تصبح السجلات السابقة متاحة فورًا للـBackend
% وتبقى محفوظة حتى لو توقف تشغيل لاحق.
%% ============================================================

requiredFields = {'schemaVersion','missionId','sequence','eventType'};
if ~isstruct(record) || ~all(isfield(record, requiredFields))
    error( ...
        "appendTelemetryJsonl:InvalidRecord", ...
        "Telemetry record is missing required contract fields.");
end

filePath = string(filePath);
parentFolder = fileparts(filePath);
if strlength(parentFolder) > 0 && ~isfolder(parentFolder)
    mkdir(parentFolder);
end

jsonText = jsonencode(record);
fileId = fopen(filePath, 'a', 'n', 'UTF-8');
if fileId < 0
    error( ...
        "appendTelemetryJsonl:OpenFailed", ...
        "Could not open telemetry file: %s", filePath);
end
cleanup = onCleanup(@() fclose(fileId)); %#ok<NASGU>
fprintf(fileId, '%s\n', jsonText);

end
