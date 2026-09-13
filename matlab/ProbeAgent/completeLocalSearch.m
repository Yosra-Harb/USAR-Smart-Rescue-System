function probe = completeLocalSearch( ...
    probe, ...
    completionReason, ...
    recordCompletedCenter)
%% ============================================================
% Function Name : completeLocalSearch
%
% Description :
% إنهاء دورة البحث المحلي من نقطة مركزية واحدة وإعادة حالتها
% التشغيلية بصورة موحدة. يمكن حفظ المركز لمنع إعادة تنفيذ دورة
% كاملة حول المنطقة نفسها.
%% ============================================================

if nargin < 2 || strlength(string(completionReason)) == 0
    completionReason = "UNSPECIFIED";
end

if nargin < 3
    recordCompletedCenter = false;
end

config = constants();

if ~isfield(probe.localSearch, 'completedCenters') || ...
        ~isnumeric(probe.localSearch.completedCenters) || ...
        size(probe.localSearch.completedCenters,2) < 2

    probe.localSearch.completedCenters = zeros(0,2);

end

if recordCompletedCenter && ...
        isValidPosition(probe.localSearch.center)

    center = probe.localSearch.center(1:2);
    completedCenters = ...
        probe.localSearch.completedCenters(:,1:2);

    shouldAppend = isempty(completedCenters);

    if ~shouldAppend

        distances = sqrt( ...
            sum((completedCenters - center).^2, 2));

        shouldAppend = all(distances > ...
            config.localSearch.completedCenterExclusionDistance);

    end

    if shouldAppend

        completedCenters = [completedCenters; center];

        maximumCenters = ...
            config.localSearch.maximumStoredCompletedCenters;

        if size(completedCenters,1) > maximumCenters
            completedCenters = ...
                completedCenters(end-maximumCenters+1:end,:);
        end

        probe.localSearch.completedCenters = completedCenters;

    end

end

probe.localSearch.active = false;
probe.localSearch.path = [];
probe.localSearch.center = [];
probe.localSearch.radius = 2;
probe.localSearch.currentStep = 1;
probe.localSearch.expansionCount = 0;
probe.localSearch.lastCompletionReason = ...
    string(completionReason);

end

function isValid = isValidPosition(position)

isValid = ...
    isnumeric(position) && ...
    numel(position) >= 2 && ...
    all(isfinite(position(1:2)));

end
