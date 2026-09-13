function [localizationPacket, localizationState] = ...
    localizationManager( ...
    fusionPacket, ...
    localizationState)
%% ============================================================
% Function Name : localizationManager
%
% Description :
% إدارة عملية اكتشاف الضحية وتحديد موقعها باستخدام:
% 1- بوابة الكشف الأولية.
% 2- خريطة الأدلة المكانية.
% 3- اكتشاف القمة الموثوقة.
% 4- المركز الموزون Weighted Centroid.
%
% تستبدل هذه الطريقة حساب متوسط مواقع المسبار،
% الذي كان يسبب خطأ كبيرًا في الموقع وإنذارات كاذبة.
%% ============================================================

%% ============================================================
% Candidate Detection
%% ============================================================

candidate = candidateDetection(fusionPacket);
% فحص القراءة الحالية باستخدام نتيجة الدمج ودرجة الثقة

%% ============================================================
% Evidence-Based Localization
%% ============================================================

[estimatedLocation, localizationState] = ...
    estimateLocationFromEvidenceMap( ...
    localizationState, ...
    candidate);
% تقدير موقع الضحية من خريطة الأدلة المكانية
% وتحديث حالة تحديد الموقع

%% ============================================================
% Debug Information
%% ============================================================

logger( ...
    "DEBUG", ...
    "Localization: candidate=%d, detected=%d, peak=%.4f", ...
    candidate.isVictim, ...
    estimatedLocation.isDetected, ...
    estimatedLocation.peakValue);
% تسجيل حالة التوطين عند تفعيل Debug Logging

%% ============================================================
% Build Localization Packet
%% ============================================================

localizationPacket = buildLocalizationPacket( ...
    fusionPacket, ...
    candidate, ...
    estimatedLocation);
% بناء حزمة التوطين الموحدة وإرسالها للطبقات التالية

end