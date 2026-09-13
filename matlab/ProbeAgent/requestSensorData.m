function sensorData = requestSensorData(scenario, probe)
%% ============================================================
% Function Name : requestSensorData
%
% Description :
% نقطة الاتصال بين Probe Agent و Sensor Simulation Layer.
% المسبار لا يحسب قراءات الحساسات بنفسه، بل يطلبها من Sensor Manager.
%% ============================================================

sensorData = sensorManager(scenario, probe); % طلب بيانات الحساسات من مدير الحساسات

end