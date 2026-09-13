function victims = generateVictims(scenario)
%% ============================================================
% Function Name : generateVictims
%
% Description :
% توليد مواقع الضحايا داخل مناطق ركام مناسبة،
% مع التأكد أنهم ليسوا داخل عوائق صلبة.
%
% Outputs :
% victims -> مصفوفة مواقع الضحايا [row, col]
%% ============================================================

rows = scenario.gridSize(1); % عدد الصفوف

cols = scenario.gridSize(2); % عدد الأعمدة

numVictims = scenario.numVictims; % عدد الضحايا المطلوب

debrisMap = scenario.environment.debris; % قراءة طبقة الركام

obstacleMap = scenario.environment.obstacles; % قراءة طبقة العوائق

victims = zeros(numVictims, 2); % مصفوفة تخزين مواقع الضحايا

minDistanceBetweenVictims = 6; % أقل مسافة بين الضحايا

safeMargin = 5; % هامش لتجنب الحواف

victimCount = 0; % عداد الضحايا الذين تم توليدهم

maxAttempts = 3000; % الحد الأعلى للمحاولات

attempts = 0; % عداد المحاولات

while victimCount < numVictims && attempts < maxAttempts % الاستمرار حتى توليد كل الضحايا

    attempts = attempts + 1; % زيادة عدد المحاولات

    r = randi([safeMargin, rows-safeMargin]); % اختيار صف عشوائي

    c = randi([safeMargin, cols-safeMargin]); % اختيار عمود عشوائي

    if obstacleMap(r,c) == 1 % رفض الموقع إذا كان داخل عائق
        continue;
    end

    if debrisMap(r,c) < 0.25 * max(debrisMap(:)) % رفض الموقع إذا كان الركام ضعيفًا جدًا
        continue;
    end

    if victimCount > 0 % إذا كان يوجد ضحايا سابقون

        existingVictims = victims(1:victimCount,:); % استخراج مواقع الضحايا السابقة

        distances = sqrt((existingVictims(:,1)-r).^2 + ...
            (existingVictims(:,2)-c).^2); % حساب المسافات

        if any(distances < minDistanceBetweenVictims) % رفض الموقع إذا كان قريبًا من ضحية أخرى
            continue;
        end
    end

    victimCount = victimCount + 1; % قبول الموقع

    victims(victimCount,:) = [r c]; % تخزين موقع الضحية

end

if victimCount < numVictims % إذا لم ننجح بتوليد كل الضحايا
    warning("Could not generate all victims. Generated only " + victimCount + " victims.");
    victims = victims(1:victimCount,:); % الاحتفاظ بالمواقع المقبولة فقط
end

end