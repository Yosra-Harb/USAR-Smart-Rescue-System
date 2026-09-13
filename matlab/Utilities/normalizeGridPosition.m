function gridPosition = normalizeGridPosition(position,gridSize)
%% Convert a continuous spatial estimate into a safe MATLAB grid index.
%
% Sensor-localization positions are intentionally continuous.  Matrix
% access is not.  This function is the single boundary between those two
% coordinate domains: it validates, rounds, and clamps a position without
% changing the continuous estimate stored by the tracker.

if ~isnumeric(position) || numel(position) < 2 || ...
        any(~isfinite(position(1:2)))
    error("normalizeGridPosition:InvalidPosition", ...
        "position must contain at least two finite numeric coordinates.");
end

if ~isnumeric(gridSize) || numel(gridSize) < 2 || ...
        any(~isfinite(gridSize(1:2))) || ...
        any(gridSize(1:2) < 1)
    error("normalizeGridPosition:InvalidGridSize", ...
        "gridSize must contain two positive finite dimensions.");
end

gridSize = max(1,round(double(gridSize(1:2))));
gridPosition = round(double(position(1:2)));
gridPosition = max([1 1],min(gridSize,gridPosition));

end
