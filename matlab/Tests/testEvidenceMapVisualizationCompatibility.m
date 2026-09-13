function tests = testEvidenceMapVisualizationCompatibility
%% اختبار توافق رسم خريطة الأدلة مع بنية الذاكرة الحالية والقديمة

tests = functiontests(localfunctions);

end


function testReadsCurrentLocalizationState(testCase)

expectedMap = reshape(1:9, 3, 3);
memory = struct();
memory.localizationState = struct( ...
    'evidenceMap', expectedMap);

actualMap = getEvidenceMapForDisplay(memory);

verifyEqual(testCase, actualMap, expectedMap);

end


function testReadsLegacyTopLevelMap(testCase)

expectedMap = reshape(1:4, 2, 2);
memory = struct('evidenceMap', expectedMap);

actualMap = getEvidenceMapForDisplay(memory);

verifyEqual(testCase, actualMap, expectedMap);

end


function testReadsBayesianPosteriorMap(testCase)

expectedMap = reshape(linspace(0,1,16), 4, 4);
memory = struct();
memory.localizationMethod = "bayesianTBD";
memory.bayesianLocalizationState = struct( ...
    'probabilityMap', expectedMap);
memory.localizationState = struct( ...
    'evidenceMap', zeros(4,4));

actualMap = getEvidenceMapForDisplay(memory);

verifyEqual(testCase, actualMap, expectedMap);

end


function testMissingMapReturnsEmptyMatrix(testCase)

actualMap = getEvidenceMapForDisplay(struct());

verifyEmpty(testCase, actualMap);
verifySize(testCase, actualMap, [0 0]);

end
