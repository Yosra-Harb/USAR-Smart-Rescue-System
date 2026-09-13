function accessibilityMap = generateAccessibilityMap(scenario)
%% ============================================================
% Function Name : generateAccessibilityMap
%
% Description :
% إنشاء خريطة سهولة الوصول داخل البيئة.
% القيمة تكون بين 0 و 1:
% 1 = الوصول سهل
% 0 = الوصول صعب جداً أو مغلق
%% ============================================================

debrisMap = scenario.environment.debris; % قراءة طبقة الركام

obstacleMap = scenario.environment.obstacles; % قراءة طبقة العوائق

accessibilityMap = 1 - debrisMap; % كلما زاد الركام قلت سهولة الوصول

accessibilityMap(obstacleMap == 1) = 0; % العوائق تعتبر مناطق غير قابلة للوصول

accessibilityMap = max(0, min(1, accessibilityMap)); % ضمان أن القيم بين 0 و1

end