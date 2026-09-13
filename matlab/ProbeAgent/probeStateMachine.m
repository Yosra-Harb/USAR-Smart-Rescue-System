function newState = probeStateMachine(currentState, decision)
%% ============================================================
% Function Name : probeStateMachine
%
% Description :
% إدارة انتقالات الحالة التشغيلية للمسبار بناءً على القرار الحالي.
%% ============================================================

switch decision

    case "SUSPICIOUS"
        newState = "LOCAL_SEARCH"; % عند وجود اشتباه ينتقل المسبار إلى سلوك البحث المحلي

    case "VICTIM_CONFIRMED"
        newState = "VICTIM_CONFIRMED"; % الانتقال إلى حالة تأكيد وجود ضحية

    case "RESUME_SEARCH"
        newState = "SEARCHING"; % إعادة المسبار إلى مسار التغطية الأساسي بعد انتهاء الفحص المحلي

    case "MISSION_COMPLETE"
        newState = "MISSION_COMPLETE"; % الانتقال إلى حالة انتهاء المهمة

    otherwise
        newState = "SEARCHING"; % في الوضع الطبيعي يستمر المسبار في البحث الأساسي

end

end