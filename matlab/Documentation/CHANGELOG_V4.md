# Changelog v4

## v4.1.4 — Empty schema field-order fix

- يحول `fieldnames(detectedVictims)` إلى permutation رقمي قبل تمريره
  إلى `orderfields` بدل استخدام مصفوفة `struct` الفارغة كمرجع.
- يصلح توافق إصدارات MATLAB التي تشترط مرجعًا قياسيًا أو قائمة أسماء،
  ولا يغير منطق الكشف أو التتبع أو قيم العتبات.

## v4.1.3 — Empty victim schema compatibility

- يضيف حقلي مصدر UWB إلى مخطط `probeMemory.detectedVictims` المركزي.
- يرقّي مخططات قواعد الضحايا الفارغة القديمة دون إنشاء سجل وهمي.
- يرتب حقول أول سجل جديد وفق المخطط النشط قبل إلحاقه، ما يمنع خطأ
  اختلاف حقول مصفوفات `struct` في اختبارات ارتباط الضحايا وتشغيل المهمة.
- لا يغير عتبات الفصل أو الرفض أو الإنقاذ التي أضيفت في v4.1.2.

## v4.1.2 — Evidence-consistent source resolution

- يحفظ مصدر كل سجل ضحية وعداد ارتباطات UWB المباشرة عبر مراحل
  Localization وVitality وقاعدة الضحايا.
- يمنع فصل نسختين للمصدر نفسه لمجرد امتلاكهما مشاهدات UWB كثيرة؛
  يحتاج الفصل إلى مسافة قمة كافية أو هبوط فعلي في سطح الدعم.
- يضيف مستوى رفض ثانٍ للحوض الخريطي غير المدعوم مباشرة عندما يكون
  شديد الضعف نسبيًا، حتى لو انقسم إلى مسارين خامين.
- ينقذ سجل UWB غير المرتبط فقط عند اجتماع تعدد المشاهدات، وتكرار
  القياس المباشر، وقوة Log-Odds والدعم، والانفصال عن المسارات الأخرى.
- يضيف تقارير صريحة للسجلات المنقذة وأدلة الخريطة الخاصة بها وأربعة
  اختبارات انحدار جديدة.
- يستخدم بذور تحقق جديدة `4001:4010` بدل إعادة استعمال مجموعة
  `3001:3010` التي أصبحت نتائجها معروفة.

## v4.1.1 — Continuous-coordinate runtime indexing fix

- يبقي تقديرات UWB العشرية مستمرة داخل التتبع، ويحوّلها إلى فهارس
  صحيحة ومحصورة فقط عند حدود الوصول إلى مصفوفات MATLAB.
- يصلح الانهيار في `calculatePriorityScore` عند معالجة مرشحي UWB
  الإضافيين، وهو الانهيار الذي جعل كل تشغيلات القبول تبدو صفرية.
- يحصّن البحث المحلي وA* وتخطيط الإنقاذ ضد المراكز العشرية أو الخارجة
  قليلًا من الشبكة باستخدام `normalizeGridPosition` موحد.
- يجعل بوابة القبول تطبع `errorIdentifier` و`errorMessage` فور فشل أي
  مهمة بدل الاكتفاء بمقاييس `NaN` غير المشخّصة.
- يضيف خمسة اختبارات انحدار لحدود الفهرسة المستمرة والمسارات الشبكية.

## v4.1.0 — Measurement-resolved multi-target tracking

- يحول قياسات UWB المجهولة ذات `range + bearing` إلى فرضيات مكانية
  مستقلة قبل أن تفقد هوية المصدر داخل خريطة `Log-Odds` المجمعة.
- يبقي قمم الخريطة مسارًا مكملًا للحالات ضعيفة الرادار والدفن العميق،
  مع منع عد القياس المباشر وقمته الخريطية كمسارين مختلفين.
- يمرر جميع مصادر UWB في التحديث إلى قاعدة الضحايا، مع إبقاء مرشح
  واحد فقط لقرار حركة المسبار؛ وبذلك لا يختفي مسار صحيح لغياب السجل.
- يرفض قياس المدى المباشر الذي لا يحمل دورية حيوية، ما يمنع clutter
  الاصطناعي المعروف من إنشاء مسار مباشر دون استخدام Ground Truth.
- يضيف لكل مسار `rangedMeasurementUpdateCount` و
  `independentRangedViewCount` و`rangedObservationPositions`.
- يستخدم تحديث موضع احتمالي يعتمد على covariance لقياسات المدى، مع
  ضوضاء عملية صغيرة تناسب فرضية الضحية الساكنة.
- يمنع دمج حوضين متصلين إذا امتلك كل منهما ثلاث مشاهدات UWB مستقلة
  وكان الفصل بين المصدرين يتجاوز قدرة ارتباط مسار واحد.
- يحمي المصدر المقاس مباشرة من بوابة رفض الحوض الضعيف، ويضيف حقول
  تقرير صريحة لقرارات الفصل المبني على القياس.
- يضيف سبعة اختبارات انحدار وبوابة قبول واحدة تشمل الحالات الصعبة
  و60 تشغيلًا جديدًا ببذور `3001:3010`.

## v4.0.17 — Temporal-coexistence diagnostics

- يحفظ `updateStepHistory` لكل مسار بايزي منذ إنشائه وحتى آخر تحديث.
- يجمع تاريخ التحديث على مستوى كل عنقود قبل الأحواض، ويضيف إلى التقرير:
  `basinPairwiseTemporalContainment` و`basinPairwiseTemporalJaccard`.
- يقيس الأول نسبة الخطوات المشتركة إلى تاريخ العنقود الأقصر، ويقيس
  الثاني تقاطع الخطوات على اتحادها.
- لا يستخدم القياسان في الدمج أو الرفض في هذا الإصدار؛ الهدف اختبار
  قابلية التزامن للفصل قبل إضافة أي قاعدة سلوكية جديدة.
- يضيف اختبارًا عدديًا لتقاطع تاريخين معروفين؛ العدد المتوقع `126`.

## v4.0.16 — Cumulative-diameter fragment reconciliation

- يفرض حد القطر `5.5` أثناء كل عملية امتصاص لشظية منفردة، وليس
  أثناء تكوين العنقود المدمج الأولي فقط.
- يحسب القطر المقترح باستخدام النواة وكل الشظايا التي امتصت سابقًا؛
  لذلك لا يمكن لشظيتين قريبتين من مركز النواة تمديد العنقود من جهتين
  حتى يتجاوز قطره قدرة الفصل التصميمية.
- يضيف `fragmentRejectedByDiameterTrackMask` إلى تقرير التشخيص لتمييز
  الشظايا التي اجتازت بوابة القرب لكنها رُفضت بسبب القطر التراكمي.
- لا يغيّر عتبات `Log-Odds` أو احتفاظ الدعم أو رفض الحوض الضعيف.
- يضيف اختبار انحدار للحالة التي تكون فيها كل شظية مقبولة منفردة،
  لكن امتصاصهما معًا يكسر حد القطر.

## v4.0.15 — Support-validated basins

- اشترط احتفاظ الدعم الموزون بنسبة 90% على الأقل إلى جانب اتصال
  `Log-Odds` قبل دمج حوضين، لحماية ضحيتين متقاربتين ذواتي دليل متداخل.
- أضاف بوابة مشتركة محافظة للحوض المنفرد الضعيف: مسار خام واحد، فرق
  `Log-Odds` لا يقل عن 6، ودعم نسبي لا يتجاوز 20%، مع وجود حوض أقوى.
- لا تعمل بوابة الرفض عندما يكون الحوض هو الكشف الوحيد، ولذلك تبقى
  حالات `DeepBurial` المنفردة محمية من شرط القوة النسبية.
- أصلح تشخيص المهمة ذات الحوض الواحد ليعيد قمة صالحة بدل `[0,0]`.
- أضاف دعم القمم، مصفوفة احتفاظ الدعم، والعناقيد المرفوضة إلى التقرير.
- أضاف ثلاثة اختبارات للدعم المكاني والرفض المشترك وتشخيص الحوض الواحد.

## v4.0.14 — Log-Odds basin consolidation

- أضاف مرحلة نهائية تدمج عناقيد المسارات عندما تقع قممها داخل حوض
  `Log-Odds` قوي واحد، بدل الاعتماد على قرب المراكز فقط.
- يستخدم هبوطًا أقصى مقداره 4.0 وحدات `Log-Odds`، وهو فرق أرجحية
  يقارب `exp(4)=54.6`، مع مسافة قصوى مقدارها 8 خلايا.
- يشترط أن تبلغ كل قمة مستوى Log-Odds المقابل لاحتمال تأكيد المسار؛
  فلا تُستخدم خريطة فارغة أو ضعيفة كدليل على وحدة الحوض.
- يطبق `complete-link`: يجب أن ينجح كل زوج من العناقيد المراد دمجها،
  ولذلك لا تستطيع سلسلة من الأحواض المحلية عبور وادٍ قوي أو مسافة
  غير مسموحة.
- أضاف مصفوفات المسافات وهبوط الأودية وخريطة الدمج إلى تقرير
  التشخيص، وثلاثة اختبارات للحوض الواحد والواد الحقيقي ومنع السلسلة.

## v4.0.13 — Non-propagating singleton-fragment reconciliation

- أبقى تكوين العناقيد المدمجة محدود القطر كما في v4.0.12.
- أضاف مرحلة ثانية تعيد العنقود المنفرد فقط إلى أقرب عنقود مدعوم
  بمسارين خامين على الأقل عندما تكون المسافة دون 5.5 خلية.
- يرفض المطابقة إذا كان أقرب عنقودين متقاربين في المسافة بأقل من
  هامش 0.75 خلية، حتى لا تُحسم الحالات المكانية الملتبسة عشوائيًا.
- تستخدم المرحلة مراكز العناقيد المدمجة الأصلية ولا تعيد الحساب بعد
  الامتصاص؛ لذلك لا تستطيع الشظية الممتصة تكوين جسر اتصال جديد.
- لا تدمج المرحلة عنقودين مدعومين، وتحافظ على المسار المنفرد الحقيقي
  إذا لم توجد مرساة مدعومة ووحيدة ضمن البوابة.
- أضافت حقول تشخيص للعناقيد المدمجة والشظايا الممتصة، وثلاثة
  اختبارات للانضمام الآمن ومنع دمج عنقودين ورفض الشظية الملتبسة.

## v4.0.12 — Diameter-constrained track clustering

- استبدل نمو connected-component غير المحدود بنمو عنقود يحافظ على
  حد أقصى لقطره مقداره 5.5 خلية.
- أبقى بوابتي المسافة وMahalanobis لكل وصلة، لكنه أضاف شرطًا عالميًا
  يمنع سلسلة الوصلات القصيرة من دمج ضحيتين متباعدتين.
- أضاف `trackClusterDiameters` إلى تقرير التشخيص.
- أضاف اختبار انحدار لسلسلة من ثلاثة مسارات ذات وصلات صالحة وقطر غير
  صالح، مع الحفاظ على اختبار المطابقة عبر أعضاء العنقود الخام.

## v4.0.11 — Log-Odds contrast peak extraction

- أبقى بوابة الدليل الحالي وعتبة posterior وNMS دون تخفيف.
- نقل اختبار البروز المكاني إلى مجال Log-Odds في المسار المكاني فقط.
- أضاف كسر تعادل محافظًا للهضبات المشبعة باستخدام الدعم الموزون الفريد.
- أضاف ثلاثة اختبارات انحدار: قمة posterior المضغوطة، هضبة ذات دعم
  فريد، وهضبة مسطحة يجب رفضها.

## v4.0.10 — Cluster-member record association

- Supersedes the rejected v4.0.9 evaluation behavior where a correctly merged
  HighNoise track cluster lost all victim records at the centroid gate.
- Retains raw confirmed tracks after clustering and matches each victim record
  to the nearest raw member of a candidate cluster.
- Keeps the merged centroid as the final reported victim position.
- Adds `assignmentAnchorTrackID` to consolidation diagnostics.
- Adds a regression test with a chained three-track cluster whose centroid is
  outside the fixed record gate while its endpoint members support both
  records.
- Retains the 4.8-cell Euclidean and 2.0 Mahalanobis uncertainty bridge.

## v4.0.9 — Validated uncertainty bridge

- Increased only the bounded secondary confirmed-track edge from 4.5 to
  4.8 cells; the fixed 3.5-cell rule is unchanged.
- Retained the Mahalanobis-distance limit of 2.0, so Euclidean proximity
  alone still cannot merge tracks outside the fixed gate.
- The change targets HighNoise seed 2, whose duplicate fragments were
  separated by 4.741 cells with Mahalanobis distance 1.983.
- Before changing the boundary, all five MultipleVictims seeds were checked
  for cross-cluster pairs inside the proposed gate; none were observed.
- Moved the uncertainty-bridge regression case to 4.75 cells.
- This release does not claim to solve the separate missed-victim/recall
  issue in MultipleVictims seeds 1, 3, and 4.

## v4.0.8 — Uncertainty-aware confirmed-track clustering

- Preserved v4.0.7 conservative record-to-track association.
- Added a bounded secondary track-clustering edge requiring both Euclidean
  distance at most 4.5 cells and Mahalanobis distance at most 2.0.
- Kept the original fixed 3.5-cell merge rule unchanged for close fragments.
- Added regression tests for merging uncertain adjacent fragments and keeping
  precise tracks outside the fixed gate distinct.
- Targets the duplicate confirmed-track fragments observed in Ideal seed 2
  and MultipleVictims seed 5 without globally increasing the merge distance.

## v4.0.7 — Conservative record-to-track association

- Retained current-positive-evidence gating introduced in v4.0.6.
- Restored the fixed record-to-track association distance as the default.
- Limited covariance-expanded association to the unambiguous case of one
  victim record and one confirmed track after strict association fails.
- Added `usedUncertaintyRescue` to consolidation diagnostics.
- Added a regression test proving uncertainty expansion is disabled for
  ambiguous multi-record/multi-track scenes.
- Intended effect: preserve the recovered DeepBurial singleton while avoiding
  extra false positives caused by broad uncertainty gates in Ideal,
  HighNoise, and MultipleVictims runs.

## v4.0.6 — Current-evidence gating and uncertainty association

- Requires a positive current measurement Log Bayes factor before a spatial
  posterior cell can be emitted as a new peak.
- Prevents a historical posterior maximum from being counted again as an
  independent view merely because the cell is visible in the current update.
- Associates vitality records with confirmed tracks through a bounded
  covariance-aware gate rather than a fixed distance alone.
- Extends consolidation diagnostics with input-record positions, raw and
  consolidated track positions, assignment distances, and assignment gates.
- Adds regression tests for negative/positive current evidence and uncertain
  record-to-track association.

## v4.0.5 — Confirmed-track clustering

- Clusters spatially connected confirmed Bayesian tracks before creating the
  final victim database and final peak list.
- Uses a 3.5-cell consolidation distance, below the configured four-cell peak
  separation, so resolvable victims remain distinct.
- Merges positions and covariances with existence/view-weighted statistics and
  unions only spatially independent observation positions.
- Adds diagnostics for raw confirmed-track count and cluster assignments.
- Adds regression tests for duplicate-track merging and preservation of two
  resolvable victims.

## v4.0.4 — Track-conditioned posterior maintenance

- Maintains an existing provisional Bayesian track from current positive
  measurement evidence inside its spatial gate when global NMS suppresses a
  broad or flat posterior peak.
- Requires both a current observation and a positive log Bayes factor; a
  historical saturated posterior alone cannot maintain or confirm a track.
- Prevents one conditioned support region from confirming multiple nearby
  tracks in the same update.
- Adds regression tests for suppressed-peak maintenance and historical-only
  posterior rejection.

## v4.0.3 — Visibility-aware track lifecycle

- A missing peak now penalizes a spatial Bayesian track only when the
  track cell lies inside the current sensor visibility mask.
- Moving the probe away from a static victim is no longer treated as
  negative evidence that deletes the victim track.
- Spatial Bayesian temporal stability is now derived from the associated
  track posterior, update support, and independent-view support instead of
  the unused legacy evidence-map history.
- Added regression tests for out-of-view retention, observable missed
  detections, and Bayesian temporal-stability integration.

## v4.0.2 — Vectorized spatial Bayesian update

- Replaced the per-cell propagation and Bayes-factor loop with one batched
  local-grid update.
- Vectorized the observable path-context calculation for debris,
  attenuation, noise, and obstacle maps.
- Vectorized the retained v3 intensity likelihood across all candidate
  cells instead of recomputing it inside every cell update.
- Preserved anonymous range/bearing evidence, explicit clutter, negative
  evidence, environmental attenuation, and the original posterior update.
- Added runtime diagnostics (`vectorizedUpdate` and
  `candidateCellCount`) to the spatial update result.

## v4.0.1 — Regression compatibility corrections

- Restored the adaptive evidence-peak threshold used by the retained v2
  comparison path, including its MAD-based diagnostics.
- Corrected the vectorized Gaussian likelihood exponent from matrix power
  to element-wise power.
- Aligned the empty victim-database schema with the rescue-planning fields
  produced by `registerVictim`.
- Kept the default v4 localization method unchanged as
  `spatialBayesianFusion`.

## v4.0.0

- Added anonymous multi-target range/bearing observations with uncertainty.
- Added breathing and heartbeat periodicity proxies to the sensor contract.
- Added measurement-set spatial Bayes factors with explicit clutter density.
- Added independent-view protection against posterior double counting.
- Added shortest and risk-aware A* rescue routes.
- Redesigned rescue priority around medical severity and route feasibility.
- Added 120-run calibration/validation/final-test generalization protocol.
- Added Phase 4 spatial localization and rescue-planning unit tests.
