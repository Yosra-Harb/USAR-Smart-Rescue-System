function noiseMap = generateNoiseMap(scenario)
%% ============================================================
% Function Name : generateNoiseMap
%
% Description :
% هذه الدالة تنشئ خريطة الضوضاء داخل بيئة البحث.
% كل خلية تأخذ قيمة بين 0 و 1:
% 0 تعني ضوضاء منخفضة
% 1 تعني ضوضاء عالية جدًا
%
% Inputs :
% scenario -> يحتوي حجم البيئة ومستوى الضوضاء العام
%
% Outputs :
% noiseMap -> خريطة الضوضاء المستخدمة في المحاكاة
%% ============================================================

rows = scenario.gridSize(1); % استخراج عدد الصفوف من حجم البيئة

cols = scenario.gridSize(2); % استخراج عدد الأعمدة من حجم البيئة

baseNoise = scenario.noiseLevel * rand(rows, cols); % إنشاء ضوضاء عشوائية حسب مستوى الضوضاء العام

numNoiseSources = 4; % عدد مصادر الضوضاء داخل البيئة

for i = 1:numNoiseSources % تكرار لإنشاء أكثر من مصدر ضوضاء

    sourceRow = randi([1 rows]); % اختيار صف عشوائي لمصدر الضوضاء

    sourceCol = randi([1 cols]); % اختيار عمود عشوائي لمصدر الضوضاء

    sourceRadius = randi([5 12]); % تحديد نصف قطر تأثير مصدر الضوضاء

    sourceStrength = 0.4 + 0.6 * rand(); % تحديد شدة مصدر الضوضاء

    for r = 1:rows % المرور على كل صف

        for c = 1:cols % المرور على كل عمود

            distance = sqrt((r - sourceRow)^2 + (c - sourceCol)^2); % حساب بعد الخلية عن مصدر الضوضاء

            if distance <= sourceRadius % إذا كانت الخلية داخل مجال تأثير مصدر الضوضاء

                effect = sourceStrength * exp(-distance / sourceRadius); % تأثير الضوضاء يقل كلما ابتعدنا عن المصدر

                baseNoise(r,c) = baseNoise(r,c) + effect; % إضافة تأثير مصدر الضوضاء إلى الخلية

            end % نهاية الشرط

        end % نهاية الأعمدة

    end % نهاية الصفوف

end % نهاية مصادر الضوضاء

noiseMap = min(baseNoise, 1); % منع القيم من تجاوز 1

noiseMap = max(noiseMap, 0); % منع القيم من النزول أقل من 0

end