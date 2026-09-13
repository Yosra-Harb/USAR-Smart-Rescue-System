function logger(level, message, varargin)
%% ============================================================
% Function Name : logger
%
% Description :
% سجل تشغيل مركزي. رسائل DEBUG لا تظهر إلا عند تفعيلها من constants.
%% ============================================================

config = constants();
normalizedLevel = upper(string(level));

if normalizedLevel == "DEBUG" && ...
        ~config.runtime.enableDebugLogging
    return;
end

formattedMessage = sprintf(char(message), varargin{:});
fprintf('[%s] %s\n', char(normalizedLevel), formattedMessage);

end
