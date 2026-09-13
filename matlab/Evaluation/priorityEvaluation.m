function result = ...
    priorityEvaluation(priorityHistory)
%% ============================================================
% Function Name : priorityEvaluation
%% ============================================================

result = struct();

if isempty(priorityHistory)

    result.meanPriority = 0;
    result.maxPriority = 0;
    result.minPriority = 0;
    return;

end

result.meanPriority = ...
    mean(priorityHistory);

result.maxPriority = ...
    max(priorityHistory);

result.minPriority = ...
    min(priorityHistory);

end