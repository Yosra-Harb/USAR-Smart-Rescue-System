function scenarioConfig = ScenarioGenerator(scenarioType)
% هذه الدالة مسؤولة عن تجهيز إعدادات السيناريو قبل إنشاء البيئة الفعلية
% المدخل: نوع السيناريو مثل Custom أو Ideal أو DenseDebris
% المخرج: scenarioConfig يحتوي كل القيم التي ستستخدمها createScenario

if nargin < 1
    scenarioType = "Custom"; % إذا لم يرسل المستخدم نوع السيناريو، نستخدم Custom كقيمة افتراضية
end

scenarioConfig.type = scenarioType; % تخزين اسم السيناريو

scenarioConfig.gridSize = [50 50]; % حجم بيئة البحث: 50 صف و50 عمود

scenarioConfig.numVictims = 3; % عدد الضحايا الافتراضي

scenarioConfig.debrisDensity = 0.4; % كثافة الركام الافتراضية بين 0 و1

scenarioConfig.noiseLevel = 0.3; % مستوى الضوضاء الافتراضي بين 0 و1

scenarioConfig.burialDepth = 0.5; % عمق الدفن الافتراضي بين 0 و1

scenarioConfig.vitalStrength = 0.8; % قوة العلامات الحيوية الافتراضية بين 0 و1

scenarioConfig.accessibility = 0.6; % سهولة الوصول الافتراضية بين 0 و1

scenarioConfig.randomSeed = 10; % رقم ثابت لإعادة توليد نفس السيناريو عند كل تشغيل

switch scenarioType % اختيار القيم حسب نوع السيناريو

    case "Ideal"
        scenarioConfig.numVictims = 1; % ضحية واحدة
        scenarioConfig.debrisDensity = 0.1; % ركام قليل
        scenarioConfig.noiseLevel = 0.1; % ضوضاء منخفضة
        scenarioConfig.burialDepth = 0.2; % دفن بسيط
        scenarioConfig.vitalStrength = 0.9; % علامات حيوية قوية
        scenarioConfig.accessibility = 0.9; % وصول سهل
        scenarioConfig.randomSeed = 1; % Seed خاص بهذا السيناريو

    case "DenseDebris"
        scenarioConfig.numVictims = 1; % ضحية واحدة لعزل تأثير الركام
        scenarioConfig.debrisDensity = 0.8; % ركام كثيف
        scenarioConfig.noiseLevel = 0.3; % ضوضاء متوسطة
        scenarioConfig.burialDepth = 0.6; % دفن متوسط إلى عميق
        scenarioConfig.vitalStrength = 0.8; % علامات حيوية جيدة
        scenarioConfig.accessibility = 0.4; % وصول صعب
        scenarioConfig.randomSeed = 2; % Seed خاص بهذا السيناريو

    case "HighNoise"
        scenarioConfig.numVictims = 1; % ضحية واحدة لعزل تأثير الضوضاء
        scenarioConfig.debrisDensity = 0.4; % ركام متوسط
        scenarioConfig.noiseLevel = 0.8; % ضوضاء عالية
        scenarioConfig.burialDepth = 0.4; % دفن متوسط
        scenarioConfig.vitalStrength = 0.8; % علامات حيوية جيدة
        scenarioConfig.accessibility = 0.6; % وصول متوسط
        scenarioConfig.randomSeed = 3; % Seed خاص بهذا السيناريو

    case "DeepBurial"
        scenarioConfig.numVictims = 1; % ضحية واحدة
        scenarioConfig.debrisDensity = 0.7; % ركام عالٍ
        scenarioConfig.noiseLevel = 0.2; % ضوضاء منخفضة
        scenarioConfig.burialDepth = 0.9; % دفن عميق جدًا
        scenarioConfig.vitalStrength = 0.7; % علامات حيوية متوسطة
        scenarioConfig.accessibility = 0.3; % وصول صعب
        scenarioConfig.randomSeed = 4; % Seed خاص بهذا السيناريو

    case "MultipleVictims"
        scenarioConfig.numVictims = 5; % عدة ضحايا
        scenarioConfig.debrisDensity = 0.5; % ركام متوسط
        scenarioConfig.noiseLevel = 0.4; % ضوضاء متوسطة
        scenarioConfig.burialDepth = 0.5; % دفن متوسط
        scenarioConfig.vitalStrength = 0.7; % علامات حيوية متوسطة
        scenarioConfig.accessibility = 0.5; % وصول متوسط
        scenarioConfig.randomSeed = 5; % Seed خاص بهذا السيناريو

    case "WeakVitalSigns"
        scenarioConfig.numVictims = 1; % ضحية واحدة
        scenarioConfig.debrisDensity = 0.5; % ركام متوسط
        scenarioConfig.noiseLevel = 0.3; % ضوضاء متوسطة
        scenarioConfig.burialDepth = 0.5; % دفن متوسط
        scenarioConfig.vitalStrength = 0.25; % علامات حيوية ضعيفة
        scenarioConfig.accessibility = 0.5; % وصول متوسط
        scenarioConfig.randomSeed = 6; % Seed خاص بهذا السيناريو

    case "Custom"
        % لا نغير القيم الافتراضية
        % لاحقًا سيتم ربط هذه القيم مع Dashboard حتى يدخلها المستخدم بنفسه

    otherwise
        error("Unknown scenario type. Please choose a valid scenario type."); % إظهار خطأ إذا كان اسم السيناريو غير معروف
end

end