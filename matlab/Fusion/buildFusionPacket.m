function fusionPacket = buildFusionPacket(processedPacket, weights, fusionScore, confidence)
%% ============================================================
% Function Name : buildFusionPacket
%
% Description :
% بناء حزمة الدمج النهائية Fusion Packet.
% هذه الحزمة تحتوي على نتيجة الدمج، أوزان الحساسات،
% درجة الثقة، الخصائص القادمة من Signal Processing،
% ومعلومات الموقع والزمن.
%% ============================================================

fusionPacket = struct(); % إنشاء هيكل حزمة الدمج

fusionPacket.fusionScore = fusionScore; % تخزين قيمة الدمج النهائية

fusionPacket.confidence = confidence; % تخزين درجة الثقة في نتيجة الدمج

fusionPacket.weights = weights; % تخزين أوزان الحساسات المستخدمة في الدمج

fusionPacket.features = processedPacket.features; % الاحتفاظ بالخصائص المستخرجة

fusionPacket.qualityReport = processedPacket.qualityReport; % الاحتفاظ بتقرير جودة القياسات

fusionPacket.probePosition = processedPacket.probePosition; % حفظ موقع المسبار وقت القياس

fusionPacket.timestamp = processedPacket.timestamp; % حفظ زمن القياس

fusionPacket.status = processedPacket.status; % حفظ حالة الحزمة

if fusionScore >= 0.75 % إذا كانت نتيجة الدمج مرتفعة
    fusionPacket.suspicionLevel = "HIGH"; % مستوى اشتباه عالي
elseif fusionScore >= 0.45 % إذا كانت نتيجة الدمج متوسطة
    fusionPacket.suspicionLevel = "MEDIUM"; % مستوى اشتباه متوسط
else
    fusionPacket.suspicionLevel = "LOW"; % مستوى اشتباه منخفض
end

end