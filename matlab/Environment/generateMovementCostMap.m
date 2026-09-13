function movementCostMap = generateMovementCostMap(scenario)
%% ============================================================
% Function Name : generateMovementCostMap
%
% Description :
% إنشاء خريطة تكلفة الحركة للمسبار داخل البيئة.
% كل خلية تأخذ قيمة تمثل صعوبة المرور منها.
%
% 1   = حركة سهلة
% 2-4 = ركام خفيف/متوسط
% 5-8 = ركام كثيف
% 999 = عائق شبه مغلق
%% ============================================================

debrisMap = scenario.environment.debris; % قراءة طبقة الركام

obstacleMap = scenario.environment.obstacles; % قراءة طبقة العوائق

movementCostMap = 1 + 7 * debrisMap; % تحويل كثافة الركام إلى تكلفة حركة بين 1 و8 تقريباً

movementCostMap(obstacleMap == 1) = 999; % العوائق تأخذ تكلفة عالية جداً

movementCostMap = max(1, movementCostMap); % التأكد أن أقل تكلفة هي 1

end