function results = runPhase0Tests()
%% Run all Phase-0 regression tests from MATLAB Online.

testsFolder = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testsFolder);

addpath(fullfile(projectRoot, 'Main'), '-end');
setupProjectPaths();

results = runtests( ...
    fullfile(testsFolder, 'testPhase0Stabilization.m'));

disp(table(results));

if any([results.Failed])
    error( ...
        "runPhase0Tests:Failed", ...
        "One or more Phase-0 regression tests failed.");
end

end
