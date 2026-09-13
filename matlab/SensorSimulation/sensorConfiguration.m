function sensorConfigs = sensorConfiguration()
%% ============================================================
% إعدادات نموذج المصدر–مسار الانتشار–المستقبِل للحساسات الثلاثة
%
% جميع الخسائر المادية ممثلة بالديسيبل ثم تحول إلى معامل سعة خطي.
% القيم التالية معاملات محاكاة أولية قابلة للمعايرة وليست مواصفات
% جهاز تجاري بعينه؛ لذلك يجب تقييم حساسيتها قبل النشر.
%% ============================================================

sensorConfigs = struct();

%% UWB radar: حركة صدر دقيقة مستمرة نسبيًا ومقاومة أفضل للركام
sensorConfigs.radar = createBaseConfiguration();
sensorConfigs.radar.name = "UWB_Radar";
sensorConfigs.radar.detectionRange = 10;
sensorConfigs.radar.pathLossExponent = 2.0;
sensorConfigs.radar.debrisLossDbPerCell = 0.70;
sensorConfigs.radar.attenuationLossDbPerCell = 0.85;
sensorConfigs.radar.obstacleLossDbPerCell = 1.50;
sensorConfigs.radar.burialLossDb = 5.0;
sensorConfigs.radar.noiseSensitivity = 0.25;
sensorConfigs.radar.baseNoiseStd = 0.012;
sensorConfigs.radar.sourceVariationStd = 0.08;
sensorConfigs.radar.sourceModel = "CONTINUOUS";
sensorConfigs.radar.physicalUnit = "mm chest displacement proxy";
sensorConfigs.radar.physicalMax = 3.5;
sensorConfigs.radar.supportsRange = true;
sensorConfigs.radar.supportsBearing = true;
sensorConfigs.radar.fieldOfViewDegrees = 180;
sensorConfigs.radar.rangeStdBase = 0.45;
sensorConfigs.radar.rangeStdPerCell = 0.035;
sensorConfigs.radar.bearingStdDegrees = 5.0;
sensorConfigs.radar.minimumSpatialSnrDb = -5.0;
sensorConfigs.radar.spatialDetectionSlopeDb = 3.5;
sensorConfigs.radar.clutterProbability = 0.010;

%% Thermal: فرق حرارة يحتاج رؤية حرارية ويتأثر بشدة بالحجب والدفن
sensorConfigs.thermal = createBaseConfiguration();
sensorConfigs.thermal.name = "Thermal_Sensor";
sensorConfigs.thermal.detectionRange = 6;
sensorConfigs.thermal.pathLossExponent = 2.4;
sensorConfigs.thermal.debrisLossDbPerCell = 2.50;
sensorConfigs.thermal.attenuationLossDbPerCell = 1.20;
sensorConfigs.thermal.obstacleLossDbPerCell = 18.0;
sensorConfigs.thermal.burialLossDb = 16.0;
sensorConfigs.thermal.noiseSensitivity = 0.35;
sensorConfigs.thermal.baseNoiseStd = 0.010;
sensorConfigs.thermal.sourceVariationStd = 0.04;
sensorConfigs.thermal.sourceModel = "CONTINUOUS";
sensorConfigs.thermal.physicalUnit = "C temperature contrast";
sensorConfigs.thermal.physicalMax = 6.0;
sensorConfigs.thermal.supportsRange = false;
sensorConfigs.thermal.supportsBearing = true;
sensorConfigs.thermal.fieldOfViewDegrees = 120;
sensorConfigs.thermal.rangeStdBase = Inf;
sensorConfigs.thermal.rangeStdPerCell = 0;
sensorConfigs.thermal.bearingStdDegrees = 7.5;
sensorConfigs.thermal.minimumSpatialSnrDb = -4.0;
sensorConfigs.thermal.spatialDetectionSlopeDb = 4.0;
sensorConfigs.thermal.clutterProbability = 0.012;

%% Acoustic: نشاط متقطع، حساس للضوضاء ولعدم تجانس مسار الركام
sensorConfigs.acoustic = createBaseConfiguration();
sensorConfigs.acoustic.name = "Acoustic_Sensor";
sensorConfigs.acoustic.detectionRange = 8;
sensorConfigs.acoustic.pathLossExponent = 2.2;
sensorConfigs.acoustic.debrisLossDbPerCell = 1.80;
sensorConfigs.acoustic.attenuationLossDbPerCell = 0.90;
sensorConfigs.acoustic.obstacleLossDbPerCell = 4.0;
sensorConfigs.acoustic.burialLossDb = 9.0;
sensorConfigs.acoustic.noiseSensitivity = 0.60;
sensorConfigs.acoustic.baseNoiseStd = 0.020;
sensorConfigs.acoustic.sourceVariationStd = 0.12;
sensorConfigs.acoustic.sourceModel = "INTERMITTENT";
sensorConfigs.acoustic.eventProbability = 0.22;
sensorConfigs.acoustic.continuousActivityFloor = 0.12;
sensorConfigs.acoustic.physicalUnit = "Pa RMS proxy";
sensorConfigs.acoustic.physicalMax = 0.02;
sensorConfigs.acoustic.supportsRange = false;
sensorConfigs.acoustic.supportsBearing = true;
sensorConfigs.acoustic.fieldOfViewDegrees = 360;
sensorConfigs.acoustic.rangeStdBase = Inf;
sensorConfigs.acoustic.rangeStdPerCell = 0;
sensorConfigs.acoustic.bearingStdDegrees = 12.0;
sensorConfigs.acoustic.minimumSpatialSnrDb = -6.0;
sensorConfigs.acoustic.spatialDetectionSlopeDb = 5.0;
sensorConfigs.acoustic.clutterProbability = 0.018;

end


function sensorConfig = createBaseConfiguration()

sensorConfig = struct();
sensorConfig.noiseStdScale = 0.12;
sensorConfig.snrMidpointDb = 0.0;
sensorConfig.snrScaleDb = 4.0;
sensorConfig.minimumReliability = 0.02;
sensorConfig.eventProbability = 1.0;
sensorConfig.continuousActivityFloor = 1.0;
sensorConfig.supportsRange = false;
sensorConfig.supportsBearing = false;
sensorConfig.fieldOfViewDegrees = 360;
sensorConfig.rangeStdBase = Inf;
sensorConfig.rangeStdPerCell = 0;
sensorConfig.bearingStdDegrees = 15;
sensorConfig.minimumSpatialSnrDb = -5;
sensorConfig.spatialDetectionSlopeDb = 4;
sensorConfig.clutterProbability = 0.01;

end
