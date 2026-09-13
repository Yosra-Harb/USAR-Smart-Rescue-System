function victims = rankVictims(victims)
%% ============================================================
% Function Name : rankVictims
%
% Description :
% ترتيب الضحايا تنازلياً حسب درجة الأولوية.
%
% الضحية ذات Priority Score الأعلى تظهر أولاً.
%% ============================================================

if isempty(victims)
    return;
end

scores = zeros(length(victims),1);

for k = 1:length(victims)

    if isfield(victims, 'rescuePriorityScore') && ...
            isscalar(victims(k).rescuePriorityScore) && ...
            isfinite(victims(k).rescuePriorityScore)
        scores(k) = victims(k).rescuePriorityScore;
    else
        scores(k) = victims(k).priorityScore;
    end

end

[~,idx] = ...
    sort(scores,'descend');

victims = ...
    victims(idx);

if isfield(victims, 'rescueRank')
    for rankIndex = 1:numel(victims)
        victims(rankIndex).rescueRank = rankIndex;
    end
end

end
