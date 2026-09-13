function artifacts = exportMissionArtifacts( ...
    missionId, scenario, simulationResult, outputRoot)
%% ============================================================
% Function Name : exportMissionArtifacts
%
% Description :
% تصدير Contracts المهمة إلى JSON بحدود واضحة بين البيانات التشغيلية
% وبيانات Ground Truth الخاصة بالتقييم.
%% ============================================================

if nargin < 4 || strlength(string(outputRoot)) == 0
    integrationFolder = fileparts(mfilename('fullpath'));
    projectRoot = fileparts(integrationFolder);
    outputRoot = fullfile(projectRoot, 'Outputs', 'missions');
end

missionId = string(missionId);
missionFolder = fullfile(string(outputRoot), missionId);
if ~isfolder(missionFolder)
    mkdir(missionFolder);
end

contracts = buildMissionContracts( ...
    missionId, scenario, simulationResult);

scenarioPath = fullfile(missionFolder, 'scenario.json');
resultPath = fullfile(missionFolder, 'result.json');
evaluationPath = fullfile(missionFolder, 'evaluation.json');

writeJsonFile(scenarioPath, contracts.scenario);
writeJsonFile(resultPath, contracts.result);
writeJsonFile(evaluationPath, contracts.evaluation);

artifacts = struct();
artifacts.missionId = missionId;
artifacts.missionFolder = string(missionFolder);
artifacts.scenarioPath = string(scenarioPath);
artifacts.resultPath = string(resultPath);
artifacts.evaluationPath = string(evaluationPath);

end


function writeJsonFile(filePath, value)

jsonText = jsonencode(value, 'PrettyPrint', true);
fileId = fopen(filePath, 'w', 'n', 'UTF-8');
if fileId < 0
    error( ...
        "exportMissionArtifacts:OpenFailed", ...
        "Could not open output file: %s", filePath);
end
cleanup = onCleanup(@() fclose(fileId)); %#ok<NASGU>
fprintf(fileId, '%s', jsonText);

end
