function results = runAllTests()
%% ============================================================
% Function Name : runAllTests
%
% Description :
% تشغيل جميع اختبارات المشروع الموجودة داخل مجلد Tests
% بصورة تلقائية، بما يشمل المراحل الحالية والمستقبلية.
%% ============================================================

%% ============================================================
% Locate Project Root
%% ============================================================

testsFolder = fileparts(mfilename('fullpath'));
% استخراج المسار الكامل لمجلد الاختبارات

projectRoot = fileparts(testsFolder);
% استخراج المسار الرئيسي للمشروع

restoredefaultpath;
% إزالة مسارات نسخ المشروع السابقة التي قد تحجب النسخة النشطة.

mainFolder = fullfile(projectRoot, 'Main');
addpath(mainFolder, '-begin');
setupProjectPaths();
addpath(testsFolder, '-end');
% استخدام قائمة المسارات المعتمدة فقط لمنع نسخ قديمة متداخلة
% من حجب ملفات النسخة الجاري اختبارها.

%% ============================================================
% Build Complete Test Suite
%% ============================================================

testSuite = testsuite( ...
    testsFolder, ...
    'IncludeSubfolders', true);
% اكتشاف جميع ملفات الاختبار داخل مجلد Tests تلقائيًا

%% ============================================================
% Run Tests
%% ============================================================

results = run(testSuite);
% تشغيل مجموعة الاختبارات كاملة

disp(table(results));
% عرض نتائج كل اختبار في جدول

%% ============================================================
% Display Test Summary
%% ============================================================

numberOfPassedTests = nnz([results.Passed]);
% حساب عدد الاختبارات الناجحة

numberOfFailedTests = nnz([results.Failed]);
% حساب عدد الاختبارات الفاشلة

numberOfIncompleteTests = nnz([results.Incomplete]);
% حساب عدد الاختبارات غير المكتملة

fprintf('\nTotals:\n');
fprintf('%d Passed, %d Failed, %d Incomplete.\n', ...
    numberOfPassedTests, ...
    numberOfFailedTests, ...
    numberOfIncompleteTests);
% عرض الملخص النهائي

end
