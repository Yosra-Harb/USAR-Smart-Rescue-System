function attenuationMap = ...
    generateAttenuationMap(scenario)
%% ============================================================
% Function Name : generateAttenuationMap
%
% Description :
% توليد خريطة التوهين داخل بيئة الانهيار.
%% ============================================================

attenuationMap = ...
    scenario.environment.debris;

attenuationMap = ...
    attenuationMap + ...
    0.3 .* scenario.environment.noise;

attenuationMap = ...
    max(0,min(1,attenuationMap));

end