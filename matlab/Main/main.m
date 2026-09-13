clc; % تنظيف نافذة الأوامر

clear; % حذف المتغيرات القديمة

close all; % إغلاق الرسومات القديمة

mainFolder = fileparts(mfilename('fullpath'));
addpath(mainFolder, '-end');

setupProjectPaths(); % إضافة مجلدات التنفيذ المعتمدة فقط بترتيب ثابت

scenarioConfig = ScenarioGenerator("Custom"); % إنشاء إعدادات السيناريو

scenario = createScenario(scenarioConfig); % إنشاء السيناريو الكامل

probe = createProbe(scenario, "boustrophedon"); % إنشاء المسبار

[simulationResult, probe] = ...
    runProbeSimulation(scenario, probe);
% حفظ نتائج التشغيل وحالة المسبار النهائية