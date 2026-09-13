function obstacleMap = generateObstacles(scenario)
%% ============================================================
% Function Name : generateObstacles
%
% Description :
% إنشاء طبقة العوائق داخل البيئة.
% العوائق تمثل كتلًا صلبة أو جدرانًا منهارة لا يفضل مرور المسبار منها.
%
% 0 = منطقة مفتوحة
% 1 = عائق
%% ============================================================

rows = scenario.gridSize(1); % عدد صفوف البيئة

cols = scenario.gridSize(2); % عدد أعمدة البيئة

obstacleMap = zeros(rows, cols); % إنشاء خريطة عوائق فارغة

debrisMap = scenario.environment.debris; % قراءة خريطة الركام من طبقات البيئة الجديدة

highDebrisThreshold = 0.85 * max(debrisMap(:)); % تحديد أعلى مناطق الركام لتحويل بعضها إلى عوائق

obstacleMap(debrisMap >= highDebrisThreshold) = 1; % تحويل مناطق الركام الشديد إلى عوائق

numWalls = 4; % عدد الجدران المنهارة

for i = 1:numWalls % تكرار لإنشاء جدران منهارة

    wallLength = randi([8 18]); % طول الجدار

    wallThickness = randi([1 2]); % سماكة الجدار

    startRow = randi([5 rows-5]); % صف بداية الجدار

    startCol = randi([5 cols-5]); % عمود بداية الجدار

    orientation = randi([1 2]); % اتجاه الجدار: 1 أفقي، 2 عمودي

    if orientation == 1 % إذا كان الجدار أفقيًا

        endCol = min(cols, startCol + wallLength); % نهاية الجدار أفقيًا

        r1 = max(1, startRow - wallThickness); % أول صف ضمن سماكة الجدار

        r2 = min(rows, startRow + wallThickness); % آخر صف ضمن سماكة الجدار

        obstacleMap(r1:r2, startCol:endCol) = 1; % رسم الجدار الأفقي

    else % إذا كان الجدار عموديًا

        endRow = min(rows, startRow + wallLength); % نهاية الجدار عموديًا

        c1 = max(1, startCol - wallThickness); % أول عمود ضمن سماكة الجدار

        c2 = min(cols, startCol + wallThickness); % آخر عمود ضمن سماكة الجدار

        obstacleMap(startRow:endRow, c1:c2) = 1; % رسم الجدار العمودي

    end
end

numBlocks = 4; % عدد الكتل الخرسانية الكبيرة

for i = 1:numBlocks % تكرار لإنشاء الكتل الخرسانية

    blockRow = randi([5 rows-8]); % صف بداية الكتلة

    blockCol = randi([5 cols-8]); % عمود بداية الكتلة

    blockHeight = randi([3 6]); % ارتفاع الكتلة

    blockWidth = randi([3 7]); % عرض الكتلة

    r2 = min(rows, blockRow + blockHeight); % نهاية الكتلة من جهة الصفوف

    c2 = min(cols, blockCol + blockWidth); % نهاية الكتلة من جهة الأعمدة

    obstacleMap(blockRow:r2, blockCol:c2) = 1; % إضافة الكتلة إلى خريطة العوائق

end

obstacleMap(end,1) = 0; % التأكد أن نقطة الدخول مفتوحة

obstacleMap(1,cols) = 0; % التأكد أن نقطة الخروج مفتوحة

end