function results = runSpatialBayesianFusionTests()
%% فحص سريع لاختبارات v4 فقط، ملفًا ملفًا لتوافق إصدارات MATLAB.

testsFolder = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testsFolder);
restoredefaultpath;
addpath(fullfile(projectRoot,'Main'),'-begin');
setupProjectPaths();
addpath(testsFolder,'-end');
testFiles = {'testPhase4SpatialBayesianFusion.m', ...
    'testPhase4RescuePlanning.m', ...
    'testPhase4MeasurementResolvedMultiTargetTracking.m'};

results = run(testsuite(fullfile(testsFolder,testFiles{1})));
for index = 2:numel(testFiles)
    currentResults = run(testsuite( ...
        fullfile(testsFolder,testFiles{index})));
    results = [results,currentResults]; %#ok<AGROW>
end
disp(table(results));
fprintf('\nv4 totals: %d Passed, %d Failed, %d Incomplete.\n', ...
    nnz([results.Passed]),nnz([results.Failed]), ...
    nnz([results.Incomplete]));

end
