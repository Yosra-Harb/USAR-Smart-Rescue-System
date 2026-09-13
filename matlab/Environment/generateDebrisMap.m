function debrisMap = generateDebrisMap(scenario)
%% ============================================================
% Function Name : generateDebrisMap
%
% Description :
% إنشاء خريطة ركام احترافية على شكل كتل ومناطق متجمعة
% بدل خريطة عشوائية بالكامل.
%
% كل خلية بين 0 و 1:
% 0 = لا يوجد ركام
% 1 = ركام كثيف جداً
%% ============================================================

rows = scenario.gridSize(1); % عدد الصفوف

cols = scenario.gridSize(2); % عدد الأعمدة

debrisMap = zeros(rows, cols); % إنشاء خريطة ركام فارغة

numDebrisClusters = 8; % عدد كتل الركام الكبيرة

for i = 1:numDebrisClusters % إنشاء عدة كتل ركام

    centerRow = randi([5 rows-5]); % اختيار مركز الكتلة بعيداً عن الحواف

    centerCol = randi([5 cols-5]); % اختيار مركز الكتلة بعيداً عن الحواف

    sigmaRow = randi([3 8]); % انتشار الكتلة عمودياً

    sigmaCol = randi([3 10]); % انتشار الكتلة أفقياً

    strength = 0.5 + 0.5*rand(); % شدة الركام داخل الكتلة

    for r = 1:rows % المرور على الصفوف

        for c = 1:cols % المرور على الأعمدة

            gaussianValue = exp(-(((r-centerRow)^2)/(2*sigmaRow^2) + ...
                ((c-centerCol)^2)/(2*sigmaCol^2))); % كتلة ركام ناعمة

            debrisMap(r,c) = debrisMap(r,c) + strength * gaussianValue; % إضافة الكتلة للخريطة

        end

    end

end

backgroundDebris = 0.08 * rand(rows, cols); % ركام خفيف منتشر في الخلفية

debrisMap = debrisMap + backgroundDebris; % إضافة الركام الخفيف للخريطة

debrisMap = debrisMap / max(debrisMap(:)); % تطبيع القيم لتصبح بين 0 و1

debrisMap = scenario.debrisDensity * debrisMap; % ربط شدة الخريطة بكثافة السيناريو

debrisMap = min(max(debrisMap, 0), 1); % ضمان أن القيم بين 0 و1

end