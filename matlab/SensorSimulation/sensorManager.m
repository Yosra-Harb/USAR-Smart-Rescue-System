function sensorData = sensorManager(scenario, probe)
%% ============================================================
% Function Name : sensorManager
%
% Description :
% إدارة دورة الحصول على بيانات الحساسات الثلاثة.
%
% تقوم الدالة بالتسلسل التالي:
%
% Radar Simulation
% Thermal Simulation
% Acoustic Simulation
%        ↓
% Microcontroller Communication Layer
%        ↓
% Measurement Packet
%
% طبقة Microcontroller Interface تحاكي إرسال قراءات الحساسات
% إلى الميكروكنترولر، استقبال حالة ACK، والتحقق من الحزمة.
%
% Inputs :
% scenario -> السيناريو وخرائط البيئة الحالية.
% probe    -> بيانات المسبار وموقعه الحالي.
%
% Output :
% sensorData -> حزمة قياسات موحدة ترسل إلى Signal Processing.
%% ============================================================

%% ============================================================
% Radar Sensor Simulation
%% ============================================================

radarOutput = radarSimulation( ...
    scenario, ...
    probe);
% محاكاة قراءة رادار UWB عند موقع المسبار الحالي

%% ============================================================
% Thermal Sensor Simulation
%% ============================================================

thermalOutput = thermalSimulation( ...
    scenario, ...
    probe);
% محاكاة قراءة الحساس الحراري عند موقع المسبار الحالي

%% ============================================================
% Acoustic Sensor Simulation
%% ============================================================

acousticOutput = acousticSimulation( ...
    scenario, ...
    probe);
% محاكاة قراءة الحساس الصوتي عند موقع المسبار الحالي

%% ============================================================
% Microcontroller Communication Interface
%% ============================================================

mcuPacket = communicationManager( ...
    radarOutput, ...
    thermalOutput, ...
    acousticOutput);
% إرسال مخرجات الحساسات إلى طبقة الاتصال الافتراضية
% ومحاكاة دورة الإرسال والاستقبال والتحقق من الحزمة

%% ============================================================
% Validate MCU Packet
%% ============================================================

if ~isstruct(mcuPacket)
    error( ...
        "sensorManager:InvalidMCUPacket", ...
        "Microcontroller packet must be a structure.");
end
% التحقق من أن الحزمة المستقبلة من طبقة الميكروكنترولر
% عبارة عن هيكل بيانات صالح

requiredFields = [ ...
    "radar", ...
    "thermal", ...
    "acoustic", ...
    "status"];
% تحديد الحقول الأساسية المطلوبة داخل حزمة الميكروكنترولر

for fieldIndex = 1:numel(requiredFields)

    currentField = requiredFields(fieldIndex);

    if ~isfield(mcuPacket, currentField)

        error( ...
            "sensorManager:MissingMCUField", ...
            "Missing field '%s' in MCU packet.", ...
            currentField);

    end

end
% التأكد من وجود جميع مخرجات الحساسات وحالة الحزمة

if string(mcuPacket.status) ~= "VALID"

    error( ...
        "sensorManager:InvalidMCUStatus", ...
        "The MCU packet status is not VALID.");

end
% رفض الحزمة إذا لم تنجح دورة الاتصال والتحقق

%% ============================================================
% Extract Sensor Outputs From MCU Packet
%% ============================================================

radarOutput = mcuPacket.radar;
% استخراج قراءة الرادار بعد مرورها عبر طبقة الميكروكنترولر

thermalOutput = mcuPacket.thermal;
% استخراج قراءة الحساس الحراري

acousticOutput = mcuPacket.acoustic;
% استخراج قراءة الحساس الصوتي

%% ============================================================
% Build Unified Measurement Packet
%% ============================================================

sensorData = buildMeasurementPacket( ...
    radarOutput, ...
    thermalOutput, ...
    acousticOutput, ...
    probe);
% بناء Measurement Packet الموحدة التي ستنتقل
% إلى طبقة Signal Processing

%% ============================================================
% Attach Microcontroller Metadata
%% ============================================================

if isfield(mcuPacket, "packetID")

    sensorData.packetID = mcuPacket.packetID;

else

    sensorData.packetID = -1;

end
% حفظ رقم الحزمة لتتبع البيانات لاحقًا

if isfield(mcuPacket, "MCUStatus")

    sensorData.MCUStatus = mcuPacket.MCUStatus;

else

    sensorData.MCUStatus = "UNKNOWN";

end
% حفظ حالة الاستجابة القادمة من الميكروكنترولر

if isfield(mcuPacket, "timestamp")

    sensorData.mcuTimestamp = mcuPacket.timestamp;

else

    sensorData.mcuTimestamp = datetime("now");

end
% حفظ زمن إنشاء حزمة الميكروكنترولر

sensorData.communicationStatus = mcuPacket.status;
% حفظ حالة الاتصال النهائية داخل Measurement Packet

end