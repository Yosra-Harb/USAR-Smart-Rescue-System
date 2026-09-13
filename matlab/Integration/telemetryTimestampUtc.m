function value = telemetryTimestampUtc()
%% ============================================================
% Function Name : telemetryTimestampUtc
%
% Description :
% إنشاء Timestamp حقيقي بصيغة UTC وقت تصدير سجل الـTelemetry.
% لا نعتمد على datetime غير مزود بمنطقة زمنية من حزمة القياس، لأن
% إسناد TimeZone='UTC' إلى وقت محلي غير zoned يغيّر معنى الزمن بدل
% تحويله، وقد ينتج عنه فرق ساعات في الـstream.
%% ============================================================

stamp = datetime( ...
    'now', ...
    'TimeZone','UTC', ...
    'Format',"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'");

value = string(stamp);

end
