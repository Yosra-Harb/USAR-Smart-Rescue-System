function fusionPacket = fusionManager(processedPacket)
%% ============================================================
% Function Name : fusionManager
%
% Description :
% مدير طبقة الدمج التكيفي.
% يستقبل الحزمة المعالجة من Signal Processing،
% ثم يحسب الأوزان التكيفية، ينفذ الدمج، يقدر الثقة،
% ويبني Fusion Packet موحدًا للطبقات التالية.
%% ============================================================

weights = calculateAdaptiveWeights(processedPacket); % حساب أوزان الحساسات حسب جودة وموثوقية القياسات

fusionScore = adaptiveFusion(processedPacket, weights); % تنفيذ الدمج التكيفي بين قراءات الحساسات

confidence = confidenceEstimation(processedPacket, weights, fusionScore); % تقدير ثقة النظام في نتيجة الدمج

fusionPacket = buildFusionPacket(processedPacket, weights, fusionScore, confidence); % بناء حزمة الدمج النهائية

end