function vitalMap = generateVitalSignsMap(scenario)
%% ============================================================
% Function Name : generateVitalSignsMap
%
% Description :
% إنشاء خريطة مكانية للعلامات الحيوية حول مواقع الضحايا
% باستخدام Gaussian Field مضبوط وفق نطاق الحساسات.
%
% تستخدم الدالة أعلى استجابة بين الضحايا بدل جمع الإشارات،
% لمنع تضخيم الإشارة اصطناعيًا عند تداخل مجال ضحيتين.
%% ============================================================

%% ============================================================
% Read Central Configuration
%% ============================================================

config = constants();
% قراءة إعدادات النظام المركزية

spatialSigma = ...
    config.environment.vitalFieldSigma;
% قراءة معامل الانتشار المكاني للعلامات الحيوية

if ~isscalar(spatialSigma) || ...
        ~isfinite(spatialSigma) || ...
        spatialSigma <= 0

    error( ...
        "generateVitalSignsMap:InvalidSigma", ...
        "Vital-field sigma must be a positive finite scalar.");
    % رفض قيمة الانتشار إذا كانت غير صالحة

end

%% ============================================================
% Validate Scenario Dimensions
%% ============================================================

if ~isfield(scenario, 'gridSize') || ...
        numel(scenario.gridSize) < 2

    error( ...
        "generateVitalSignsMap:MissingGridSize", ...
        "Scenario gridSize is missing or invalid.");
    % لا يمكن إنشاء الخريطة دون معرفة حجم البيئة

end

numberOfRows = scenario.gridSize(1);
% عدد صفوف البيئة

numberOfColumns = scenario.gridSize(2);
% عدد أعمدة البيئة

vitalMap = zeros( ...
    numberOfRows, ...
    numberOfColumns);
% إنشاء خريطة علامات حيوية فارغة

%% ============================================================
% Validate Victim Locations
%% ============================================================

if ~isfield(scenario, 'victims') || ...
        isempty(scenario.victims)

    disp('Max Vital = 0');
    return;
    % إعادة خريطة فارغة إذا لم توجد ضحايا في السيناريو

end

if size(scenario.victims, 2) < 2

    error( ...
        "generateVitalSignsMap:InvalidVictimLocations", ...
        "Victim locations must contain row and column coordinates.");
    % يجب أن يحتوي كل موقع على صف وعمود

end

numberOfVictims = size(scenario.victims, 1);
% حساب عدد الضحايا

%% ============================================================
% Read Victim Vital Strength
%% ============================================================

if ~isfield(scenario, 'vitalStrength') || ...
        isempty(scenario.vitalStrength)

    error( ...
        "generateVitalSignsMap:MissingVitalStrength", ...
        "Scenario vitalStrength is missing.");
    % لا يمكن إنشاء المجال دون قوة العلامات الحيوية

end

if isscalar(scenario.vitalStrength)

    victimVitalStrengths = repmat( ...
        scenario.vitalStrength, ...
        numberOfVictims, ...
        1);
    % استخدام القوة نفسها لجميع الضحايا عند إعطاء قيمة واحدة

elseif numel(scenario.vitalStrength) == numberOfVictims

    victimVitalStrengths = ...
        scenario.vitalStrength(:);
    % السماح بقوة حيوية مختلفة لكل ضحية مستقبلًا

else

    error( ...
        "generateVitalSignsMap:InvalidVitalStrength", ...
        "vitalStrength must be scalar or match victim count.");
    % رفض عدد قيم لا يتطابق مع عدد الضحايا

end

victimVitalStrengths = max( ...
    0, ...
    min(1, victimVitalStrengths));
% حصر قوة العلامات الحيوية بين صفر وواحد

%% ============================================================
% Build Environment Coordinate Grid
%% ============================================================

[rowGrid, columnGrid] = ndgrid( ...
    1:numberOfRows, ...
    1:numberOfColumns);
% إنشاء إحداثيات جميع خلايا البيئة

%% ============================================================
% Generate Victim Vital Fields
%% ============================================================

for victimIndex = 1:numberOfVictims

    victimRow = ...
        scenario.victims(victimIndex, 1);
    % صف موقع الضحية

    victimColumn = ...
        scenario.victims(victimIndex, 2);
    % عمود موقع الضحية

    if ~isfinite(victimRow) || ...
            ~isfinite(victimColumn) || ...
            victimRow < 1 || ...
            victimRow > numberOfRows || ...
            victimColumn < 1 || ...
            victimColumn > numberOfColumns

        error( ...
            "generateVitalSignsMap:VictimOutsideGrid", ...
            "Victim location is outside the scenario grid.");
        % رفض مواقع الضحايا الواقعة خارج البيئة

    end

    distanceSquared = ...
        (rowGrid - victimRow).^2 + ...
        (columnGrid - victimColumn).^2;
    % حساب مربع المسافة من جميع الخلايا إلى الضحية

    gaussianField = ...
        victimVitalStrengths(victimIndex) .* ...
        exp( ...
            -distanceSquared ./ ...
            (2 * spatialSigma^2));
    % إنشاء مجال Gaussian متمركز عند موقع الضحية

    vitalMap = max( ...
        vitalMap, ...
        gaussianField);
    % الاحتفاظ بأقوى ضحية مؤثرة في كل خلية
    % لمنع تضخيم الإشارات عند تداخل المجالات

end

%% ============================================================
% Normalize Final Map
%% ============================================================

vitalMap = max( ...
    0, ...
    min(1, vitalMap));
% حصر خريطة العلامات الحيوية بين صفر وواحد

disp([ ...
    'Max Vital = ', ...
    num2str(max(vitalMap(:)))]);
% عرض أعلى قوة حيوية لأغراض التحقق

end