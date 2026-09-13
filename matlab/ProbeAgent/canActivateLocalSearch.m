function [canActivate, reason] = ...
    canActivateLocalSearch( ...
        probe, ...
        vitalityPacket, ...
        candidateCenter)
%% ============================================================
% Function Name : canActivateLocalSearch
%
% Description :
% تحديد هل يسمح ببدء دورة بحث محلي جديدة.
%
% لا يكفي الاشتباه الضعيف لتفعيل البحث. يجب أولًا أن تكون طبقة
% Localization قد أنتجت كشفًا صالحًا، كما يُمنع بدء دورة جديدة
% حول مركز سبق استكمال البحث فيه.
%% ============================================================

canActivate = false;
reason = "UNCONFIRMED_CANDIDATE";

if ~isstruct(vitalityPacket) || ...
        ~isfield(vitalityPacket, 'isVictimDetected') || ...
        ~logical(vitalityPacket.isVictimDetected)

    return;

end

if ~isValidPosition(candidateCenter)

    reason = "INVALID_CENTER";
    return;

end

config = constants();

if ~isfield(vitalityPacket, 'fusionScore') || ...
        ~isfinite(vitalityPacket.fusionScore) || ...
        vitalityPacket.fusionScore < ...
        config.suspicion.fusionScore

    reason = "INSUFFICIENT_FUSION";
    return;

end

if ~isfield(vitalityPacket, 'vitalityIndex') || ...
        ~isfinite(vitalityPacket.vitalityIndex) || ...
        vitalityPacket.vitalityIndex < ...
        config.suspicion.vitalityIndex

    reason = "INSUFFICIENT_VITALITY";
    return;

end

completedCenters = zeros(0,2);

if isfield(probe, 'localSearch') && ...
        isstruct(probe.localSearch) && ...
        isfield(probe.localSearch, 'completedCenters') && ...
        isnumeric(probe.localSearch.completedCenters) && ...
        size(probe.localSearch.completedCenters,2) >= 2

    completedCenters = ...
        probe.localSearch.completedCenters(:,1:2);

end

if ~isempty(completedCenters)

    centerDifference = ...
        completedCenters - candidateCenter(1:2);

    centerDistances = sqrt( ...
        sum(centerDifference.^2, 2));

    if any(centerDistances <= ...
            config.localSearch.completedCenterExclusionDistance)

        reason = "COMPLETED_CENTER_SUPPRESSED";
        return;

    end

end


canActivate = true;
reason = "VALID_CONFIRMED_CANDIDATE";

end

function isValid = isValidPosition(position)

isValid = ...
    isnumeric(position) && ...
    numel(position) >= 2 && ...
    all(isfinite(position(1:2)));

end
