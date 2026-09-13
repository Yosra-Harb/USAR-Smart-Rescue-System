function errorValue = ...
    localizationError( ...
    estimatedPosition, ...
    truePosition)
%% ============================================================
% Function Name : localizationError
%% ============================================================

if isempty(estimatedPosition)

    errorValue = inf;
    return;

end

errorValue = sqrt( ...
    (estimatedPosition(1)-truePosition(1)).^2 + ...
    (estimatedPosition(2)-truePosition(2)).^2);

end