function runDashboardScenarioRequest(requestFilePath)
%% ============================================================
% Dashboard -> Backend -> MATLAB entrypoint
% Reads one validated Scenario Request JSON file and runs the complete mission.
%% ============================================================

if nargin < 1 || strlength(string(requestFilePath)) == 0
    error( ...
        'runDashboardScenarioRequest:MissingRequestPath', ...
        'A Scenario Request JSON path is required.');
end

requestFilePath = string(requestFilePath);

if ~isfile(requestFilePath)
    error( ...
        'runDashboardScenarioRequest:RequestNotFound', ...
        'Scenario Request file does not exist: %s', ...
        char(requestFilePath));
end

integrationDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(integrationDir);

addpath(fullfile(projectRoot, 'Main'), '-begin');
setupProjectPaths();
rehash;

requestText = fileread(requestFilePath);
request = jsondecode(requestText);

fprintf('\n====================================================\n');
fprintf('DASHBOARD-STARTED USAR MISSION\n');
fprintf('====================================================\n');
fprintf('Request File: %s\n', char(requestFilePath));
fprintf('Scenario    : %s\n', char(string(request.scenarioType)));

[missionRun, ~, ~] = runScenarioRequest(request);

fprintf('\n====================================================\n');
fprintf('DASHBOARD MISSION COMPLETED\n');
fprintf('Mission ID: %s\n', char(string(missionRun.missionId)));
fprintf('====================================================\n');
end
