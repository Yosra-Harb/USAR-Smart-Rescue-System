function riskMap = generateRiskMap(scenario)
%% ============================================================
% Function Name : generateRiskMap
%
% Description :
% إنشاء خريطة الخطورة داخل البيئة.
% القيمة تكون بين 0 و 1:
% 0 = منطقة آمنة نسبياً
% 1 = منطقة عالية الخطورة
%% ============================================================

debrisMap = scenario.environment.debris; % قراءة طبقة الركام

noiseMap = scenario.environment.noise; % قراءة طبقة الضوضاء

obstacleMap = scenario.environment.obstacles; % قراءة طبقة العوائق

riskMap = 0.6 * debrisMap + 0.3 * noiseMap + 0.1 * obstacleMap; % حساب الخطورة من الركام والضوضاء والعوائق

riskMap = max(0, min(1, riskMap)); % ضمان أن القيم بين 0 و1

end