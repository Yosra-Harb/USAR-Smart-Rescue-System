function coverage = calculateCoverage(probe)
%% ============================================================
% Function Name : calculateCoverage
%
% Description :
% حساب نسبة الخلايا التي زارها المسبار.
%% ============================================================

visitedCount = nnz(probe.visitedCells); % عدد الخلايا المزارة

totalCells = numel(probe.visitedCells); % العدد الكلي للخلايا

coverage = visitedCount / totalCells; % نسبة التغطية

end