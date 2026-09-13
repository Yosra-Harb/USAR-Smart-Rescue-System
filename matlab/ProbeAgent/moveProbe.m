function probe = moveProbe(probe)
%% ============================================================
% Function Name : moveProbe
%
% Description :
% تنفيذ خطوة حركة واحدة للمسبار وفق مسار التغطية النشط.
% هذه الدالة لا ترسم ولا تقرأ الحساسات.
% وظيفتها فقط تحديث موقع المسبار وحالته وذاكرته.
%% ============================================================

if probe.finished == true % إذا كانت المهمة منتهية
    return; % لا يتم تنفيذ أي حركة إضافية
end

%% ============================================================
% Local-search movement has priority while it is active.
%% ============================================================

useLocalPath = ...
    probe.localSearch.active && ...
    ~isempty(probe.localSearch.path) && ...
    probe.localSearch.currentStep <= ...
    size(probe.localSearch.path,1);

if useLocalPath

    nextPosition = ...
        probe.localSearch.path( ...
        probe.localSearch.currentStep,:);

    probe.localSearch.currentStep = ...
        probe.localSearch.currentStep + 1;

    probe.state = "LOCAL_SEARCH";

else

    probe.currentStep = ...
        probe.currentStep + 1; % الانتقال إلى خطوة التغطية التالية

    if probe.currentStep > size(probe.coveragePath,1)
        probe.finished = true;
        probe.state = "MISSION_COMPLETE";
        return;
    end

    nextPosition = ...
        probe.coveragePath(probe.currentStep,:);

    probe.state = "SEARCHING";

end

previousPosition = probe.position;
movement = nextPosition - previousPosition;
if any(movement ~= 0)
    probe.headingDegrees = atan2d(movement(1), movement(2));
end
% تحديث اتجاه المسبار قبل تسجيل الموقع الجديد.

probe.position = nextPosition; % تحديث موقع المسبار الحالي داخل بيئة المهمة

probe.path = [probe.path; nextPosition]; % إضافة الموقع الجديد إلى المسار الفعلي الذي قطعه المسبار

probe.visitedCells(nextPosition(1), nextPosition(2)) = true; % تحديث ذاكرة التغطية بتسجيل الخلية الحالية كخلية تمت زيارتها

probe.coverage = calculateCoverage(probe); % تحديث نسبة التغطية بعد الحركة

end
