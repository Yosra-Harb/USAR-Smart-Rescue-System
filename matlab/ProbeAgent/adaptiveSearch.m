function probe = adaptiveSearch( ...
    scenario, ...
    probe, ...
    vitalityPacket)
% adaptiveSearch:
% تدير البحث المحلي التكيفي حول منطقة الاشتباه،
% وتُعيد بيانات المسبار بعد تحديث حالة البحث ومساره.

%% ============================================================
% Read Current Evidence
%% ============================================================

fusionScore = vitalityPacket.fusionScore;
% قراءة نتيجة الدمج التكيفي الحالية.

vitalityIndex = vitalityPacket.vitalityIndex;
% قراءة مؤشر الحيوية الحالي.

config = constants();
% constants:
% تستدعي جميع العتبات والإعدادات المركزية الخاصة بالنظام.

%% ============================================================
% Activate Local Search
%% ============================================================

if ~probe.localSearch.active
    % تنفيذ هذا الجزء إذا لم يكن البحث المحلي مفعّلًا.

    candidateCenter = vitalityPacket.estimatedPosition;
    % استخدام ناتج التوطين كمركز مرشح، مع الإبقاء على موقع المسبار
    % كحل رجوع متوافق مع الحزم القديمة التي لا تحمل موقعًا تقديريًا.

    if isempty(candidateCenter)
        candidateCenter = probe.position;
    end

    candidateCenter = normalizeGridPosition( ...
        candidateCenter,scenario.gridSize);

    [activationAllowed, activationReason] = ...
        canActivateLocalSearch( ...
            probe, ...
            vitalityPacket, ...
            candidateCenter);
    % لا يُفعّل البحث المكلف إلا لقياس اجتاز قرار الكشف الفعلي،
    % وليس لمجرد ارتفاع مؤشر اشتباه منفرد.

    if activationAllowed

        probe.localSearch.active = true;

        logger("DEBUG", "Local search activated.");
        % logger:
        % تسجل رسالة Debug توضح أن البحث المحلي أصبح مفعّلًا.
        % لا تظهر الرسالة إلا عند تفعيل Debug Logging.

        probe.localSearch.center = candidateCenter;
        % تثبيت المركز الذي اجتاز بوابة التفعيل.

        logger( ...
            "DEBUG", ...
            "Local-search center: [%g, %g]", ...
            probe.localSearch.center(1), ...
            probe.localSearch.center(2));
        % logger:
        % تسجل إحداثيات مركز البحث المحلي لأغراض التتبع والفحص.

        probe.localSearch.radius = 2;
        % تحديد نصف قطر البحث المحلي الابتدائي.

        probe.localSearch.currentStep = 1;
        % بدء تنفيذ المسار المحلي من النقطة الأولى.

        probe.localSearch.expansionCount = 0;
        % تصفير عدد مرات توسيع منطقة البحث.

        probe.localSearch.path = ...
            generateLocalSearchPath( ...
                scenario, ...
                probe, ...
                probe.localSearch.center, ...
                fusionScore, ...
                vitalityIndex);
        % generateLocalSearchPath:
        % تنشئ مسار بحث محلي حول مركز الاشتباه.
        % تقيم الخلايا القريبة ثم تستخدم A* لتكوين مسار آمن بينها.

        logger( ...
            "DEBUG", ...
            "Local path contains %d points.", ...
            size(probe.localSearch.path,1));
        % size:
        % تحسب عدد الصفوف في مصفوفة المسار؛
        % أي عدد نقاط الحركة الموجودة في المسار المحلي.
        %
        % logger:
        % تسجل عدد نقاط المسار الذي تم إنشاؤه.

        probe.localSearch.currentStep = 1;
        % التأكد من بدء تنفيذ المسار الجديد من أول نقطة.

    else

        logger( ...
            "DEBUG", ...
            "Local-search activation rejected: %s", ...
            char(activationReason));

    end

    return;
    % return:
    % تنهي تنفيذ الدالة بعد محاولة تفعيل البحث المحلي،
    % وتعيد بنية probe بعد تحديثها.

end

%% ============================================================
% Check Whether the Local Path Is Finished
%% ============================================================

localPathFinished = ...
    isempty(probe.localSearch.path) || ...
    probe.localSearch.currentStep > ...
    size(probe.localSearch.path,1);
% isempty:
% تتحقق هل مسار البحث المحلي فارغ.
%
% size:
% تعيد عدد نقاط المسار المحلي.
%
% يصبح localPathFinished صحيحًا عندما يكون المسار فارغًا
% أو عندما يتجاوز المسبار آخر نقطة فيه.

strongLocalEvidence = ...
    fusionScore >= config.suspicion.fusionScore || ...
    vitalityIndex >= config.suspicion.vitalityIndex;
% تحديد هل ما زالت هناك أدلة اشتباه قوية
% اعتمادًا على Fusion Score أو Vitality Index.

%% ============================================================
% Expand Local Search
%% ============================================================

if localPathFinished && strongLocalEvidence
    % توسيع البحث فقط بعد انتهاء المسار الحالي
    % مع استمرار وجود أدلة اشتباه قوية.

    if probe.localSearch.radius < ...
            probe.localSearch.maximumRadius
        % التأكد من عدم تجاوز أكبر نصف قطر مسموح.

        probe.localSearch.radius = ...
            probe.localSearch.radius + 1;
        % زيادة نصف قطر البحث بمقدار خلية واحدة.

        probe.localSearch.expansionCount = ...
            probe.localSearch.expansionCount + 1;
        % زيادة عداد مرات توسيع البحث.

        probe.localSearch.path = ...
            generateLocalSearchPath( ...
                scenario, ...
                probe, ...
                probe.localSearch.center, ...
                fusionScore, ...
                vitalityIndex);
        % generateLocalSearchPath:
        % تعيد إنشاء المسار المحلي باستخدام نصف القطر الجديد.

        probe.localSearch.currentStep = 1;
        % بدء تنفيذ المسار الموسع من النقطة الأولى.

        return;
        % localPathFinished يصف المسار السابق المنتهي. يجب الخروج هنا
        % كي لا يُفسَّر المسار الجديد عند نصف القطر الأقصى على أنه منتهٍ.

    end

end

%% ============================================================
% Complete Local Search at Maximum Radius
%% ============================================================

if localPathFinished && ...
        probe.localSearch.radius >= ...
        probe.localSearch.maximumRadius
    % إنهاء البحث المحلي إذا انتهى المسار ووصل النظام
    % إلى أكبر نصف قطر بحث مسموح.

    probe = completeLocalSearch( ...
        probe, ...
        "MAXIMUM_RADIUS_COMPLETED", ...
        true);
    % تسجيل المركز المكتمل يمنع إعادة فتح بحث جديد حول المنطقة نفسها.

    logger( ...
        "DEBUG", ...
        "Local search completed at maximum radius.");
    % logger:
    % تسجل أن البحث المحلي انتهى بعد الوصول لأقصى نصف قطر.

    return;
    % return:
    % تنهي تنفيذ الدالة بعد اكتمال البحث المحلي.

end

%% ============================================================
% Exit Local Search When Evidence Becomes Weak
%% ============================================================

if fusionScore < ...
        config.suspicion.exitFusionScore && ...
        vitalityIndex < ...
        config.suspicion.exitVitalityIndex
    % الخروج المبكر من البحث المحلي عندما تصبح
    % نتيجة الدمج ومؤشر الحيوية أقل من عتبات الخروج.

    probe = completeLocalSearch( ...
        probe, ...
        "EVIDENCE_BECAME_WEAK", ...
        false);
    % الانسحاب بسبب ضعف الدليل لا يسجّل المنطقة كمركز مكتمل.

    logger("DEBUG", "Returning to coverage path.");
    % logger:
    % تسجل عودة المسبار إلى مسار التغطية الأساسي.

    if ~isempty(probe.coveragePath)
        % isempty:
        % تتحقق أن مسار التغطية الأساسي موجود وغير فارغ.

        remainingPath = ...
            probe.coveragePath( ...
                probe.currentStep:end,:);
        % استخراج الجزء المتبقي من مسار التغطية الأساسي.

        if ~isempty(remainingPath)
            % isempty:
            % تتحقق من وجود نقاط متبقية في مسار التغطية.

            distances = sqrt( ...
                (remainingPath(:,1)-probe.position(1)).^2 + ...
                (remainingPath(:,2)-probe.position(2)).^2);
            % sqrt:
            % تحسب الجذر التربيعي المستخدم لإيجاد
            % المسافة الإقليدية بين المسبار وكل نقطة متبقية.

            [~, nearestIndex] = min(distances);
            % min:
            % تبحث عن أصغر مسافة وتعيد فهرس
            % أقرب نقطة في مسار التغطية الأساسي.
            %
            % الرمز ~ يعني أننا لا نحتاج قيمة المسافة نفسها،
            % بل نحتاج فهرس النقطة الأقرب فقط.

            probe.currentStep = ...
                probe.currentStep + nearestIndex - 1;
            % تحديث مؤشر مسار التغطية للعودة
            % إلى أقرب نقطة غير مكتملة.

        end

    end

end

end
