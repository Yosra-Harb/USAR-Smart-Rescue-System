function candidate = candidateDetection(fusionPacket)
%% ============================================================
% Function Name : candidateDetection
%
% Description :
% تحديد ما إذا كانت القراءة الحالية تمثل ضحية محتملة
% اعتمادًا على Fusion Score ودرجة الثقة.
%% ============================================================

candidate = struct();

candidate.isVictim = false;

candidate.position = ...
    fusionPacket.probePosition;

candidate.score = ...
    fusionPacket.fusionScore;

candidate.confidence = ...
    fusionPacket.confidence;

config = constants();

%% ============================================================
% Detection Thresholds
%% ============================================================

detectionThreshold = ...
    config.detection.fusionScore;

confidenceThreshold = ...
    config.detection.confidence;

%% ============================================================
% Candidate Detection
%% ============================================================

if fusionPacket.fusionScore >= ...
        detectionThreshold && ...
        fusionPacket.confidence >= ...
        confidenceThreshold

    candidate.isVictim = true;

    logger( ...
        "DEBUG", ...
        "Victim candidate detected: fusion=%.4f, confidence=%.4f", ...
        fusionPacket.fusionScore, ...
        fusionPacket.confidence);

end

end
