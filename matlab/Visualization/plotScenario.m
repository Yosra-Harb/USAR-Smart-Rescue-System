function plotScenario(scenario)
%% ============================================================
% Function Name : plotScenario
%
% Description :
% رسم بيئة المحاكاة بالهيكلية الجديدة:
% Debris Layer + Obstacles + Victims + Entry/Exit
%% ============================================================

figure; % فتح نافذة رسم جديدة

imagesc(scenario.environment.debris); % رسم طبقة الركام

colormap("turbo"); % اختيار ألوان توضح اختلاف كثافة الركام

colorbar; % إظهار شريط الألوان

axis equal; % جعل أبعاد الخلايا متساوية

axis tight; % ضبط حدود الرسم على حجم الخريطة

hold on; % السماح بإضافة عناصر فوق الخريطة

title("USAR Environment - Scenario: " + scenario.type); % عنوان الشكل

xlabel("X Position"); % تسمية المحور الأفقي

ylabel("Y Position"); % تسمية المحور الرأسي

[obsRows, obsCols] = find(scenario.environment.obstacles == 1); % استخراج مواقع العوائق

plot(obsCols, obsRows, 'ks', ...
     'MarkerSize', 4, ...
     'MarkerFaceColor', 'k'); % رسم العوائق بالأسود

plot(scenario.victims(:,2), ...
     scenario.victims(:,1), ...
     'rp', ...
     'MarkerSize', 14, ...
     'MarkerFaceColor', 'r'); % رسم الضحايا باللون الأحمر

entry = scenario.environment.entryPoint; % قراءة نقطة الدخول

plot(entry(2), entry(1), ...
     'go', ...
     'MarkerSize', 12, ...
     'MarkerFaceColor', 'g'); % رسم نقطة الدخول باللون الأخضر

exitPoint = scenario.environment.exitPoint; % قراءة نقطة الخروج

plot(exitPoint(2), exitPoint(1), ...
     'co', ...
     'MarkerSize', 12, ...
     'MarkerFaceColor', 'c'); % رسم نقطة الخروج باللون السماوي

legend("Obstacles", ...
       "Victim Ground Truth", ...
       "Entry Point", ...
       "Exit Point", ...
       'Location', 'southoutside'); % مفتاح الرسم

end