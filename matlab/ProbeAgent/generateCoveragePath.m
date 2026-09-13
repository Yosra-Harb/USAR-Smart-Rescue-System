function path = generateCoveragePath(scenario, searchMode)
%% ============================================================
% Function Name : generateCoveragePath
%
% Description :
% إنشاء مسار التغطية الأساسي للمسبار.
% حالياً نستخدم Boustrophedon / Row-by-Row.
%% ============================================================

rows = scenario.gridSize(1); % عدد الصفوف

cols = scenario.gridSize(2); % عدد الأعمدة

obstacleMap = scenario.environment.obstacles; % قراءة خريطة العوائق

path = []; % مصفوفة المسار

switch lower(searchMode)

    case "boustrophedon"

        for r = rows:-1:1 % نبدأ من أسفل الخريطة إلى الأعلى

            if mod(rows - r, 2) == 0
                colRange = 1:cols; % صف من اليسار إلى اليمين
            else
                colRange = cols:-1:1; % الصف التالي من اليمين إلى اليسار
            end

            for c = colRange

                if obstacleMap(r,c) == 0 % لا نضيف الخلية إذا كانت عائقًا
                    path = [path; r c]; % إضافة الخلية إلى المسار
                end

            end
        end

    otherwise
        error("Unknown search mode.");
end

end