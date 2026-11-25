// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'تيلي كارز';

  @override
  String get languageEnglish => 'الإنجليزية';

  @override
  String get languageArabic => 'العربية';

  @override
  String get loginTitle => 'تسجيل الدخول';

  @override
  String get loginSubtitle => 'سجّل الدخول بحساب الشركة.';

  @override
  String get registerTitle => 'تسجيل موظف';

  @override
  String get registerSubtitle => 'تُنشأ الحسابات الجديدة بدور موظف.';

  @override
  String get nameLabel => 'الاسم';

  @override
  String get emailLabel => 'البريد الإلكتروني';

  @override
  String get passwordLabel => 'كلمة المرور';

  @override
  String get confirmPasswordLabel => 'تأكيد كلمة المرور';

  @override
  String get signIn => 'تسجيل الدخول';

  @override
  String get signOut => 'تسجيل الخروج';

  @override
  String get createEmployeeAccount => 'إنشاء حساب موظف';

  @override
  String get alreadyHaveAccount => 'لديك حساب بالفعل؟ سجّل الدخول';

  @override
  String get validationNameRequired => 'أدخل اسمك.';

  @override
  String get validationEmailRequired => 'أدخل بريدك الإلكتروني.';

  @override
  String get validationEmailInvalid => 'أدخل بريدًا إلكترونيًا صالحًا.';

  @override
  String get validationPasswordRequired => 'أدخل كلمة المرور.';

  @override
  String get validationPasswordShort => 'استخدم 8 أحرف على الأقل.';

  @override
  String get validationConfirmPasswordRequired => 'أكّد كلمة المرور.';

  @override
  String get validationPasswordMismatch => 'كلمتا المرور غير متطابقتين.';

  @override
  String get showPassword => 'إظهار كلمة المرور';

  @override
  String get hidePassword => 'إخفاء كلمة المرور';

  @override
  String get loading => 'جارٍ التحميل';

  @override
  String get tryAgain => 'حاول مرة أخرى';

  @override
  String get couldNotContinue => 'تعذر المتابعة';

  @override
  String get companyAdminHomeTitle => 'إدارة الشركة';

  @override
  String get driversAdminHomeTitle => 'إدارة السائقين';

  @override
  String get driverHomeTitle => 'السائق';

  @override
  String get employeeHomeTitle => 'الموظف';

  @override
  String roleHomeWelcome(String name) {
    return 'مرحبًا، $name';
  }

  @override
  String get companyAdminHomeSubtitle =>
      'راجع طلبات الرحلات وتقدّم الرحلات الإجمالي.';

  @override
  String get requestsTab => 'الطلبات';

  @override
  String get pendingRequestsTab => 'الطلبات المعلّقة';

  @override
  String get tripsTab => 'الرحلات';

  @override
  String get placesTab => 'الأماكن';

  @override
  String get placesEmptyTitle => 'لا توجد أماكن بعد';

  @override
  String get placesEmptyMessage =>
      'أنشئ قائمة أماكن الشركة الافتراضية، أو أضف مكانًا يدويًا. تظهر الأماكن النشطة للموظفين عند طلب رحلة.';

  @override
  String get addPlace => 'إضافة مكان';

  @override
  String get addPlaceTitle => 'إضافة مكان';

  @override
  String get editPlace => 'تعديل المكان';

  @override
  String get editPlaceTitle => 'تعديل المكان';

  @override
  String get savePlace => 'حفظ';

  @override
  String get placeNameEnLabel => 'الاسم (الإنجليزية)';

  @override
  String get placeNameArLabel => 'الاسم (العربية)';

  @override
  String get placeHeadquartersLabel => 'المقر الرئيسي للشركة';

  @override
  String get placeHeadquartersHint =>
      'يمكن وضع علامة المقر على مكان واحد فقط. تفعيل هذا الخيار يزيل العلامة عن الأماكن الأخرى.';

  @override
  String get placeHeadquartersBadge => 'المقر الرئيسي';

  @override
  String get placeStatusActive => 'نشط';

  @override
  String get placeStatusInactive => 'غير نشط';

  @override
  String get placeCreated => 'تمت إضافة المكان.';

  @override
  String get placeUpdated => 'تم تحديث المكان.';

  @override
  String get deletePlace => 'حذف المكان';

  @override
  String get deletePlaceConfirmTitle => 'حذف هذا المكان؟';

  @override
  String deletePlaceConfirmMessage(String name) {
    return 'سيتم إزالة \"$name\" من قائمة الأماكن المعتمدة.';
  }

  @override
  String get placeDeleted => 'تم حذف المكان.';

  @override
  String get seedDefaultPlaces => 'إنشاء الأماكن الافتراضية';

  @override
  String get placesSeeded => 'تم إنشاء الأماكن الافتراضية.';

  @override
  String get validationPlaceNameEnRequired => 'أدخل الاسم بالإنجليزية.';

  @override
  String get validationPlaceNameArRequired => 'أدخل الاسم بالعربية.';

  @override
  String get validationPlaceNameDuplicate => 'يوجد مكان بهذا الاسم بالفعل.';

  @override
  String get errorConflict => 'هذا الاسم مستخدم بالفعل.';

  @override
  String get pendingRequestsEmptyTitle => 'لا توجد طلبات معلّقة';

  @override
  String get pendingRequestsEmptyMessage =>
      'ستظهر طلبات رحلات الموظفين الجديدة هنا.';

  @override
  String get tripsEmptyTitle => 'لا توجد رحلات بعد';

  @override
  String get tripsEmptyMessage =>
      'ستظهر هنا الرحلات التي ينشئها مسؤول السائقين.';

  @override
  String get approveTripRequest => 'موافقة';

  @override
  String get approveTripRequestTitle => 'الموافقة على هذا الطلب؟';

  @override
  String get approveTripRequestMessage =>
      'سينتقل الطلب إلى موافق عليه حتى يتمكن مسؤول السائقين من إنشاء رحلة.';

  @override
  String get confirmApproveTripRequest => 'الموافقة على الطلب';

  @override
  String get tripRequestApproved => 'تمت الموافقة على طلب الرحلة.';

  @override
  String get rejectTripRequest => 'رفض';

  @override
  String get rejectTripRequestTitle => 'رفض هذا الطلب؟';

  @override
  String get rejectTripRequestMessage => 'سيظهر الطلب للموظف كمرفوض.';

  @override
  String get rejectionReasonLabel => 'السبب (اختياري)';

  @override
  String get rejectionReasonHint => 'أخبر الموظف بسبب الرفض';

  @override
  String get confirmRejectTripRequest => 'رفض الطلب';

  @override
  String get dialogCancel => 'إلغاء';

  @override
  String get tripRequestRejected => 'تم رفض طلب الرحلة.';

  @override
  String selectedRequestsCount(int count) {
    return '$count محدّد';
  }

  @override
  String get createOneTripPerRequest => 'إنشاء رحلة لكل طلب';

  @override
  String get groupIntoOneTrip => 'تجميع في رحلة واحدة';

  @override
  String groupingSuggestionBanner(int count) {
    return '$count طلبات يمكن تجميعها';
  }

  @override
  String get groupingSuggestionDismiss => 'إغلاق';

  @override
  String get groupingSuggestionsSheetTitle => 'اقتراحات التجميع';

  @override
  String get groupingSuggestionsEmpty => 'لا تبقى اقتراحات تجميع.';

  @override
  String groupingSuggestionTimeSpan(String span) {
    return 'الوقت: $span';
  }

  @override
  String groupingSuggestionRequestCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count طلب',
      many: '$count طلبًا',
      few: '$count طلبات',
      two: 'طلبان',
      one: 'طلب واحد',
      zero: 'لا طلبات',
    );
    return '$_temp0';
  }

  @override
  String get groupingSuggestionRemoveRequest => 'إزالة من المجموعة';

  @override
  String get groupingSuggestionApproveAsGroup => 'الموافقة كمجموعة';

  @override
  String get groupingSuggestionIgnore => 'تجاهل';

  @override
  String get groupingSuggestionApproved => 'تمت الموافقة على الطلبات كمجموعة.';

  @override
  String suggestedGroupTitle(int count) {
    return 'مجموعة مقترحة ($count)';
  }

  @override
  String suggestedGroupEmployees(String names) {
    return 'الموظفون: $names';
  }

  @override
  String get createGroupedTrip => 'إنشاء رحلة مجمّعة';

  @override
  String get splitSuggestedGroup => 'فصل';

  @override
  String get tripsCreated => 'تم إنشاء الرحلة/الرحلات.';

  @override
  String tripRequestDestinationValue(String destination) {
    return 'إلى: $destination';
  }

  @override
  String tripScheduledValue(String dateTime) {
    return 'الموعد: $dateTime';
  }

  @override
  String tripPassengersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count راكب',
      many: '$count راكبًا',
      few: '$count ركاب',
      two: 'راكبان',
      one: 'راكب واحد',
      zero: 'لا ركاب',
    );
    return '$_temp0';
  }

  @override
  String get tripDetailsTitle => 'تفاصيل الرحلة';

  @override
  String get tripPassengersSection => 'الركاب';

  @override
  String get tripRequestsSection => 'الطلبات';

  @override
  String get tripStatusUnassigned => 'غير معيّنة';

  @override
  String get tripStatusAssigned => 'معيّنة';

  @override
  String get tripStatusGoing => 'في الطريق';

  @override
  String get tripStatusAtDestination => 'عند الوجهة';

  @override
  String get tripStatusReturning => 'عائد';

  @override
  String get tripStatusCompleted => 'مكتملة';

  @override
  String get tripStatusCancelled => 'ملغاة';

  @override
  String get arrivedAtDestination => 'وصلت إلى الوجهة';

  @override
  String get arrivedAtDestinationConfirmTitle => 'تسجيل الوصول إلى الوجهة؟';

  @override
  String get arrivedAtDestinationConfirmMessage =>
      'ينهي هذا مرحلة الذهاب ويحفظ المسار حتى الآن.';

  @override
  String get arrivedAtDestinationSuccess => 'تم الوصول إلى الوجهة.';

  @override
  String get startReturn => 'بدء العودة';

  @override
  String get startReturnConfirmTitle => 'بدء رحلة العودة؟';

  @override
  String get startReturnConfirmMessage =>
      'ستُستأنف مشاركة الموقع لرحلة العودة.';

  @override
  String get startReturnSuccess => 'تم بدء العودة.';

  @override
  String get locationPermissionDeniedTitle => 'يلزم إذن الموقع';

  @override
  String get locationPermissionDeniedMessage =>
      'اسمح بالموقع أثناء استخدام التطبيق حتى تتمكن الإدارة من متابعة رحلتك.';

  @override
  String get locationPermissionPermanentlyDeniedMessage =>
      'تم حظر الوصول إلى الموقع. افتح إعدادات التطبيق لتفعيله.';

  @override
  String get locationServicesDisabledMessage =>
      'فعّل خدمة الموقع / GPS لمشاركة موقع الرحلة.';

  @override
  String get openAppSettings => 'فتح إعدادات التطبيق';

  @override
  String get enableLocationServices => 'تفعيل خدمات الموقع';

  @override
  String get driversAdminHomeSubtitle => 'أدر السائقين وعيّن الرحلات.';

  @override
  String get driversTab => 'السائقون';

  @override
  String get driversEmptyTitle => 'لا يوجد سائقون بعد';

  @override
  String get driversEmptyMessage => 'أضف حساب سائق لبدء تعيين الرحلات.';

  @override
  String get fixLegacyDrivers => 'إصلاح السائقين القدامى';

  @override
  String get fixLegacyDriversConfirmTitle => 'إصلاح ملفات السائقين القدامى؟';

  @override
  String get fixLegacyDriversConfirmMessage =>
      'سيتم كتابة القيم الافتراضية الناقصة (الحالة النشطة والأسماء باللغتين من الاسم القديم) على حسابات السائقين التي ما زالت تستخدم التنسيق السابق.';

  @override
  String get fixLegacyDriversConfirmAction => 'إصلاح الآن';

  @override
  String fixLegacyDriversSuccess(int count) {
    return 'تم تحديث $count من ملفات السائقين.';
  }

  @override
  String get fixLegacyDriversNone => 'جميع ملفات السائقين محدّثة بالفعل.';

  @override
  String get addDriver => 'إضافة سائق';

  @override
  String get addDriverTitle => 'إضافة سائق';

  @override
  String get phoneLabelOptional => 'الهاتف (اختياري)';

  @override
  String get temporaryPasswordLabel => 'كلمة مرور مؤقتة';

  @override
  String get driverStatusActive => 'نشط';

  @override
  String get driverStatusInactive => 'غير نشط';

  @override
  String get driverCreated => 'تم إنشاء حساب السائق.';

  @override
  String get validationPhoneTooLong => 'رقم الهاتف طويل جدًا.';

  @override
  String get errorAccountInactive =>
      'حساب السائق هذا غير نشط. تواصل مع المسؤول.';

  @override
  String get errorOrphanedAccountCleanupFailed =>
      'تم إنشاء الحساب لكن تعذر حفظ الملف الشخصي وفشلت عملية التنظيف. تواصل مع المسؤول.';

  @override
  String get tripsUnassignedTab => 'غير معيّنة';

  @override
  String get tripsAssignedTab => 'معيّنة';

  @override
  String get tripsAllTab => 'الكل';

  @override
  String get adminTripsEmptyTitle => 'لا توجد رحلات هنا';

  @override
  String get adminTripsUnassignedEmptyMessage =>
      'ستظهر هنا الرحلات غير المعيّنة من مسؤول الشركة.';

  @override
  String get adminTripsAssignedEmptyMessage => 'ستظهر هنا الرحلات المعيّنة.';

  @override
  String get adminTripsAllEmptyMessage =>
      'ستظهر هنا الرحلات التي أنشأها مسؤول الشركة.';

  @override
  String tripRouteSummary(String pickup, String destination) {
    return '$pickup ← $destination';
  }

  @override
  String get assignDriver => 'تعيين سائق';

  @override
  String get reassignDriver => 'إعادة تعيين سائق';

  @override
  String get cancelTrip => 'إلغاء الرحلة';

  @override
  String get cancelTripConfirmTitle => 'إلغاء هذه الرحلة؟';

  @override
  String get cancelTripConfirmMessage =>
      'هذه الرحلة لم تبدأ بعد وسيتم تعليمها كملغاة.';

  @override
  String get confirmCancelTrip => 'إلغاء الرحلة';

  @override
  String get tripCancelled => 'تم إلغاء الرحلة.';

  @override
  String get tripDriverAssigned => 'تم تعيين السائق.';

  @override
  String get tripDriverReassigned => 'تمت إعادة تعيين السائق.';

  @override
  String get selectDriverTitle => 'اختر سائقًا';

  @override
  String get noActiveDriversMessage =>
      'لا يوجد سائقون نشطون. فعّل سائقًا أولًا.';

  @override
  String get driverScheduleConflictTitle => 'تداخل في الجدول';

  @override
  String get driverScheduleConflictMessage =>
      'لدى هذا السائق رحلة أخرى خلال ساعتين من هذا الموعد. يمكنك تعيينه رغم ذلك.';

  @override
  String get driverScheduleConflictContinue => 'تعيين على أي حال';

  @override
  String get driverHasNearbyTripHint => 'لديه رحلة أخرى خلال ساعتين';

  @override
  String tripAssignedDriverValue(String name) {
    return 'السائق: $name';
  }

  @override
  String get driverHomeSubtitle => 'اعرض الرحلات المعيّنة والأسبوعية والسابقة.';

  @override
  String get driverTripsAssignedTab => 'معيّنة';

  @override
  String get driverTripsWeeklyTab => 'هذا الأسبوع';

  @override
  String get driverTripsPastTab => 'سابقة';

  @override
  String get driverTripsEmptyTitle => 'لا توجد رحلات هنا';

  @override
  String get driverTripsAssignedEmptyMessage =>
      'ستظهر هنا الرحلات المعيّنة لك.';

  @override
  String get driverTripsWeeklyEmptyMessage =>
      'لا توجد رحلات مخططة لهذا الأسبوع.';

  @override
  String get driverTripsPastEmptyMessage =>
      'ستظهر هنا الرحلات المكتملة والملغاة.';

  @override
  String get startTrip => 'بدء الرحلة';

  @override
  String get endTrip => 'إنهاء الرحلة';

  @override
  String get startTripConfirmTitle => 'بدء هذه الرحلة؟';

  @override
  String get startTripConfirmMessage =>
      'سيظهر للركاب أن هذه الرحلة قيد التنفيذ.';

  @override
  String get endTripConfirmTitle => 'إنهاء هذه الرحلة؟';

  @override
  String get endTripConfirmMessage => 'سيتم تعليم الرحلة كمكتملة.';

  @override
  String get tripStarted => 'تم بدء الرحلة.';

  @override
  String get tripEnded => 'تم إكمال الرحلة.';

  @override
  String get employeeHomeSubtitle => 'ستظهر طلبات رحلاتك هنا.';

  @override
  String get homeEmpty => 'لا يوجد شيء للعرض بعد.';

  @override
  String get errorNetwork => 'تعذر الاتصال. تحقق من الإنترنت وحاول مرة أخرى.';

  @override
  String get errorAuth => 'فشل المصادقة. يرجى تسجيل الدخول مرة أخرى.';

  @override
  String get errorPermission => 'ليس لديك صلاحية للقيام بذلك.';

  @override
  String get errorUnknown => 'حدث خطأ ما. يرجى المحاولة مرة أخرى.';

  @override
  String get errorInvalidEmail => 'أدخل بريدًا إلكترونيًا صالحًا.';

  @override
  String get errorInvalidCredentials =>
      'البريد الإلكتروني أو كلمة المرور غير صحيحة.';

  @override
  String get errorUserDisabled => 'تم تعطيل هذا الحساب. تواصل مع المسؤول.';

  @override
  String get errorEmailAlreadyInUse => 'هذا البريد الإلكتروني مسجل بالفعل.';

  @override
  String get errorWeakPassword => 'كلمة المرور ضعيفة. استخدم 8 أحرف على الأقل.';

  @override
  String get errorTooManyRequests =>
      'محاولات كثيرة. انتظر قليلًا ثم حاول مرة أخرى.';

  @override
  String get errorOperationNotAllowed =>
      'تسجيل الدخول بالبريد الإلكتروني غير متاح.';

  @override
  String get errorMissingProfile =>
      'لا يوجد ملف مستخدم لهذا الحساب. تواصل مع المسؤول أو سجّل حسابًا جديدًا.';

  @override
  String get errorInvalidProfile =>
      'بيانات الحساب غير صالحة. تواصل مع المسؤول.';

  @override
  String get errorNotFound => 'تعذر العثور على هذا العنصر.';

  @override
  String get errorInvalidState => 'هذا الإجراء غير متاح للحالة الحالية.';

  @override
  String get tripRequestsEmptyTitle => 'لا توجد طلبات رحلات بعد';

  @override
  String get tripRequestsEmptyMessage => 'اضغط + لطلب رحلة بسيارة الشركة.';

  @override
  String get newTripRequest => 'طلب رحلة جديد';

  @override
  String get newTripRequestTitle => 'طلب جديد';

  @override
  String get pickupLocationLabel => 'مكان الاستلام';

  @override
  String get destinationLabel => 'مكان الوجهة';

  @override
  String get searchPlacesHint => 'ابحث عن الأماكن';

  @override
  String get otherPlaceOption => 'أخرى (غير مدرجة)';

  @override
  String get customPlaceLabel => 'مكان مخصص';

  @override
  String get customPlaceHint => 'اكتب اسم المكان';

  @override
  String get noPlacesForRequestTitle => 'لا توجد أماكن متاحة';

  @override
  String get noPlacesForRequestMessage =>
      'تواصل مع مسؤول الشركة لإضافة أماكن معتمدة قبل طلب رحلة.';

  @override
  String get requestedDateTimeLabel => 'التاريخ والوقت';

  @override
  String get selectDate => 'اختر التاريخ';

  @override
  String get selectTime => 'اختر الوقت';

  @override
  String get selectDateTime => 'اختر التاريخ والوقت';

  @override
  String get notesLabel => 'ملاحظات';

  @override
  String get notesHint => 'اسم زميل واحد في كل سطر (لا تُدرج أرقام الهواتف).';

  @override
  String get notesFellowEmployeesHint =>
      'اكتب اسمًا واحدًا في كل سطر. لن تُشارك أرقام هواتفهم أبدًا.';

  @override
  String get addAnotherNameLine => 'إضافة اسم آخر';

  @override
  String get submitTripRequest => 'إرسال الطلب';

  @override
  String get cancelTripRequest => 'إلغاء الطلب';

  @override
  String get cancelTripRequestConfirmTitle => 'إلغاء هذا الطلب؟';

  @override
  String get cancelTripRequestConfirmMessage =>
      'سيتم إلغاء هذا الطلب المعلّق. يمكنك إنشاء طلب جديد لاحقًا.';

  @override
  String get confirmCancelTripRequest => 'إلغاء الطلب';

  @override
  String get dialogDismiss => 'الإبقاء على الطلب';

  @override
  String get tripRequestStatusPending => 'قيد الانتظار';

  @override
  String get tripRequestStatusApproved => 'موافق عليه';

  @override
  String get tripRequestStatusRejected => 'مرفوض';

  @override
  String get tripRequestStatusCancelled => 'ملغى';

  @override
  String tripRequestPickupValue(String pickup) {
    return 'من: $pickup';
  }

  @override
  String tripRequestWhenValue(String dateTime) {
    return 'الوقت: $dateTime';
  }

  @override
  String tripRequestNotesValue(String notes) {
    return 'ملاحظات: $notes';
  }

  @override
  String get validationPickupPlaceRequired => 'اختر مكان الاستلام.';

  @override
  String get validationDestinationPlaceRequired => 'اختر مكان الوجهة.';

  @override
  String get validationCustomPlaceRequired => 'أدخل اسم المكان المخصص.';

  @override
  String get validationPickupDestinationSame =>
      'يجب أن يكون مكان الاستلام والوجهة مختلفين.';

  @override
  String get validationDateTimeRequired => 'اختر التاريخ والوقت.';

  @override
  String get validationDateTimeFuture => 'اختر تاريخًا ووقتًا في المستقبل.';

  @override
  String get tripRequestCreated => 'تم إرسال طلب الرحلة.';

  @override
  String get requestATrip => 'طلب رحلة';

  @override
  String get adminRequestChip => 'طلب مسؤول';

  @override
  String get tripRequestCancelled => 'تم إلغاء طلب الرحلة.';

  @override
  String get phoneLabel => 'الهاتف';

  @override
  String get validationPhoneRequired => 'أدخل رقم هاتفك.';

  @override
  String get branchLabel => 'الفرع';

  @override
  String get validationBranchRequired => 'اختر فرعك.';

  @override
  String get branchCompanyHeadquarters => 'المقر الرئيسي';

  @override
  String get branchNewHeadquarters => 'المقر الجديد';

  @override
  String get branchFilterAll => 'الكل';

  @override
  String get branchLockedHint => 'تواصل مع المسؤول لتغيير فرعك.';

  @override
  String get approvalFilterLabel => 'الموافقة';

  @override
  String get tripStatusFilterLabel => 'حالة الرحلة';

  @override
  String get tripStatusUpcoming => 'قادمة';

  @override
  String get tripStatusFilterInProgress => 'قيد التنفيذ';

  @override
  String get driversAdminTripUnassigned =>
      'رحلتك غير معينة. افتحها من هنا لاختيار سائق.';

  @override
  String get completeProfileTitle => 'أكمل ملفك الشخصي';

  @override
  String get completeProfileSubtitle => 'أضف فرعك ورقم هاتفك للمتابعة.';

  @override
  String get completeProfileSubmit => 'حفظ ومتابعة';

  @override
  String get completeProfileSaved => 'تم تحديث الملف الشخصي.';

  @override
  String callEmployeePhone(String phone) {
    return 'اتصال بـ $phone';
  }

  @override
  String get requesterSection => 'مقدّم الطلب';

  @override
  String get requestersSection => 'مقدّمو الطلب';

  @override
  String passengersCountLabel(int count) {
    return 'الركاب: $count';
  }

  @override
  String get requestDetailsTitle => 'تفاصيل الطلب';

  @override
  String tripDriverNameValue(String name) {
    return 'السائق: $name';
  }

  @override
  String get tripDriverUnassigned => 'السائق: غير معيَّن';

  @override
  String tripStartedValue(String dateTime) {
    return 'بدأت: $dateTime';
  }

  @override
  String tripEndedValue(String dateTime) {
    return 'انتهت: $dateTime';
  }

  @override
  String get tripNotStartedYet => 'لم تبدأ بعد';

  @override
  String get tripNotEndedYet => 'لم تنتهِ بعد';

  @override
  String get approvedRequestsTab => 'الطلبات الموافق عليها';

  @override
  String get approvedRequestsEmptyTitle => 'لا توجد طلبات موافق عليها';

  @override
  String get approvedRequestsEmptyMessage =>
      'ستظهر هنا الطلبات الموافق عليها التي لم تُربط برحلة بعد.';

  @override
  String get tripsInProgressTab => 'قيد التنفيذ';

  @override
  String get tripsCompletedTab => 'مكتملة';

  @override
  String get adminTripsInProgressEmptyMessage => 'لا توجد رحلات قيد التنفيذ.';

  @override
  String get adminTripsCompletedEmptyMessage => 'لا توجد رحلات مكتملة بعد.';

  @override
  String get liveMapTab => 'الخريطة المباشرة';

  @override
  String get liveMapTitle => 'الخريطة المباشرة';

  @override
  String get sharingLocation => 'جارٍ مشاركة الموقع';

  @override
  String get locationSharingOff => 'الموقع متوقف';

  @override
  String get locationUpdateKeptLast =>
      'تعذّر إرسال موقع جديد. لا يزال لدى الإدارة آخر موقع معروف.';

  @override
  String get locationSharingWarning =>
      'بدأت الرحلة، لكن مشاركة الموقع متوقفة. اضغط «الموقع متوقف» لتفعيل الـ GPS للمرسل.';

  @override
  String get destinationLocationNotSet => 'موقع الوجهة غير مُعيَّن';

  @override
  String get recenterMap => 'إعادة التمركز';

  @override
  String distanceRemainingKm(String km) {
    return 'متبقٍ $km كم';
  }

  @override
  String get passengersFromNotes => 'الركاب (من الملاحظات)';

  @override
  String get openLiveMap => 'افتح الخريطة المباشرة';

  @override
  String get noActiveTripsRightNow => 'لا توجد رحلات نشطة الآن';

  @override
  String get noActiveTripsRightNowMessage =>
      'تظهر الرحلة هنا فقط بعد أن يشارك تطبيق السائق الـ GPS (إذن الموقع + إشارة). تحقق من جهاز السائق إذا بقيت الصفحة فارغة.';

  @override
  String get fitAllDrivers => 'عرض الكل';

  @override
  String lastSeenMinutesAgo(int minutes) {
    return 'آخر ظهور منذ $minutes د';
  }

  @override
  String speedKmh(String speed) {
    return 'السرعة: $speed كم/س';
  }

  @override
  String lastUpdateValue(String time) {
    return 'آخر تحديث: $time';
  }

  @override
  String get openTripDetails => 'فتح تفاصيل الرحلة';

  @override
  String get placeCoordinatesLabel => 'الموقع على الخريطة';

  @override
  String get useMyCurrentLocation => 'استخدم موقعي الحالي';

  @override
  String get latitudeLabel => 'خط العرض';

  @override
  String get longitudeLabel => 'خط الطول';

  @override
  String get validationLatitudeInvalid => 'أدخل خط عرض صالحًا (-90 إلى 90).';

  @override
  String get validationLongitudeInvalid => 'أدخل خط طول صالحًا (-180 إلى 180).';

  @override
  String get validationPlaceLocationRequired =>
      'اختر موقعًا على الخريطة قبل الحفظ.';

  @override
  String get placeAddressLabel => 'العنوان';

  @override
  String get validationPlaceAddressRequired => 'أدخل العنوان.';

  @override
  String get validationPlaceCoordinatePair =>
      'أدخل خط العرض وخط الطول معًا، أو اتركهما فارغين.';

  @override
  String get placeLocationOptionalHint =>
      'الموقع اختياري. انقر على الخريطة أو أدخل خط العرض وخط الطول.';

  @override
  String get clearPlaceLocation => 'مسح الموقع';

  @override
  String get placeHasCoordinates => 'الإحداثيات مُعيَّنة';

  @override
  String get placeMissingCoordinates => 'لا توجد إحداثيات';

  @override
  String get tapMapToSetLocation => 'انقر على الخريطة لتحديد الموقع';

  @override
  String get placeCannotSelectWithoutLocation =>
      'هذا المكان بلا موقع ولا يمكن استخدامه في رحلة. اطلب من المسؤول إضافة الإحداثيات.';

  @override
  String get noLocationBadge => 'بدون موقع';

  @override
  String get locationServicesDisabled => 'فعّل خدمات الموقع للمتابعة.';

  @override
  String get locationPermissionDenied => 'إذن الموقع مطلوب للمشاركة مع المرسل.';

  @override
  String get locationUnavailable => 'الموقع غير متاح.';

  @override
  String get pickLocationTitle => 'اختر موقعًا';

  @override
  String get myLocationButton => 'موقعي';

  @override
  String get locationSearchHint => 'ابحث عن مكان أو عنوان';

  @override
  String get locationSearchAction => 'بحث';

  @override
  String get locationSearchNoResults => 'لا توجد نتائج لهذا البحث.';

  @override
  String get locationSearchFailed => 'فشل البحث. تحقق من الاتصال وحاول مجددًا.';

  @override
  String get resolvingAddress => 'جاري تحديد العنوان…';

  @override
  String get addressNotAvailable => 'العنوان غير متاح';

  @override
  String get confirmLocation => 'تأكيد الموقع';

  @override
  String get openSettingsAction => 'فتح الإعدادات';

  @override
  String get chooseOnMap => 'اختيار على الخريطة';

  @override
  String get nameMapPlaceTitle => 'سمِّ هذا الموقع';

  @override
  String get placeNameArOptionalLabel => 'الاسم (العربية، اختياري)';

  @override
  String get useLocationForTripOnly => 'استخدم لهذه الرحلة فقط';

  @override
  String get saveLocationAsPlace => 'حفظ كمكان جديد';

  @override
  String get customLocationChip => 'موقع مخصص';

  @override
  String get pickLocationOnMap => 'اختيار على الخريطة';

  @override
  String get editLocationOnMap => 'تعديل على الخريطة';

  @override
  String get enterCoordinatesManually => 'إدخال الإحداثيات يدويًا';

  @override
  String get noMapLocationBadge => 'بدون موقع';

  @override
  String get addLocationAction => 'إضافة موقع';

  @override
  String get editDriver => 'تعديل السائق';

  @override
  String get editDriverTitle => 'تعديل السائق';

  @override
  String get driverUpdated => 'تم تحديث السائق.';

  @override
  String get saveDriver => 'حفظ';

  @override
  String get tripEventsSection => 'أحداث الرحلة';

  @override
  String get tripEventTripStarted => 'بدأت الرحلة';

  @override
  String get tripEventArrivedAtDestination => 'وصلت إلى الوجهة';

  @override
  String get tripEventStartedReturning => 'بدأت العودة';

  @override
  String get tripEventTripEnded => 'انتهت الرحلة';

  @override
  String get tripNotArrivedYet => 'لم تصل بعد';

  @override
  String get tripNotReturningYet => 'لم تبدأ العودة بعد';

  @override
  String handledByValue(String name) {
    return 'عولج بواسطة: $name';
  }

  @override
  String handledAtValue(String dateTime) {
    return 'وقت المعالجة: $dateTime';
  }

  @override
  String get filterPending => 'معلّق';

  @override
  String get filterApproved => 'موافق عليه';

  @override
  String get filterRejected => 'مرفوض';

  @override
  String get requestsEmptyTitle => 'لا توجد طلبات';

  @override
  String get requestsEmptyMessage => 'لا توجد طلبات رحلات تطابق هذا التصفية.';

  @override
  String get driverNameEnLabel => 'الاسم (الإنجليزية)';

  @override
  String get driverNameArLabel => 'الاسم (العربية)';

  @override
  String get nationalIdLabel => 'الرقم القومي';

  @override
  String get carLicenseLabel => 'لوحة السيارة';

  @override
  String get carPlateLettersLabel => 'الحروف';

  @override
  String get carPlateNumbersLabel => 'الأرقام';

  @override
  String get personalLicenseLabel => 'رخصة القيادة الشخصية';

  @override
  String get driverDetailsTitle => 'تفاصيل السائق';

  @override
  String nationalIdMaskedValue(String masked) {
    return 'الرقم القومي: $masked';
  }

  @override
  String get nationalIdNotSet => 'الرقم القومي: غير مُعيَّن';

  @override
  String carLicenseValue(String license) {
    return 'لوحة السيارة: $license';
  }

  @override
  String get carLicenseNotSet => 'لوحة السيارة: غير مُعيَّنة';

  @override
  String get validationDriverNameEnRequired => 'أدخل الاسم بالإنجليزية.';

  @override
  String get validationDriverNameArRequired => 'أدخل الاسم بالعربية.';

  @override
  String get validationPhoneInvalid => 'أدخل رقم هاتف صالحًا.';

  @override
  String get validationNationalIdRequired => 'أدخل الرقم القومي.';

  @override
  String get validationNationalIdInvalid =>
      'أدخل رقمًا قوميًا مصريًا صحيحًا من 14 رقمًا.';

  @override
  String get validationCarLicenseRequired => 'أدخل لوحة السيارة.';

  @override
  String get validationCarPlateInvalid =>
      'أدخل من حرف إلى ثلاثة حروف عربية ومن رقم إلى أربعة أرقام، مثل ط ع ب 9295.';

  @override
  String get validationPersonalLicenseRequired => 'أدخل رخصة القيادة الشخصية.';

  @override
  String get registerSectionDetails => 'بياناتك';

  @override
  String get registerSectionSecurity => 'الأمان';

  @override
  String get roleLabelEmployee => 'موظف';

  @override
  String get roleLabelDriver => 'سائق';

  @override
  String get roleLabelCompanyAdmin => 'إدارة الشركة';

  @override
  String get roleLabelDriversAdmin => 'إدارة السائقين';

  @override
  String get bootstrapGettingLocation => 'جارٍ تحديد موقعك';

  @override
  String get bootstrapLoadingLocations => 'جارٍ تحميل مواقع الرحلة';

  @override
  String get bootstrapPreparingRoute => 'جارٍ تجهيز المسار';

  @override
  String get bootstrapSharingLocation => 'جارٍ مشاركة الموقع مع المرسل';

  @override
  String get waitingForGpsSignal => 'بانتظار إشارة الـ GPS';

  @override
  String get locationOffTapToFix => 'الموقع متوقف، اضغط للإصلاح';

  @override
  String get approximateRoute => 'المسار غير متاح، يُعرض خط مباشر';

  @override
  String get approximateLocation => 'موقع تقريبي';

  @override
  String locationNotSetFor(String name) {
    return 'الموقع غير مُعيَّن لـ $name';
  }

  @override
  String get youHaveArrived => 'لقد وصلت';

  @override
  String get arrivedStartReturn => 'وصلت / بدء العودة';

  @override
  String get navigateButton => 'تنقّل';

  @override
  String tripProgressPercent(int percent) {
    return 'اكتمل $percent%';
  }

  @override
  String distanceCoveredRemaining(String covered, String remaining) {
    return 'قطعت $covered كم · متبقٍ $remaining كم';
  }

  @override
  String etaApproximateMinutes(int minutes) {
    return 'الوصول المتوقع ~$minutes د (تقريبي)';
  }

  @override
  String get devToolsTitle => 'أدوات التطوير';

  @override
  String get devSimulateMovement => 'محاكاة الحركة';

  @override
  String devSimulateSpeed(int speed) {
    return 'السرعة: $speed كم/س';
  }

  @override
  String get devPauseSimulation => 'إيقاف مؤقت';

  @override
  String get devResumeSimulation => 'متابعة';

  @override
  String get devJumpToNinety => 'انتقال إلى 90%';

  @override
  String adminTripProgress(int percent, String remaining) {
    return '$percent% · متبقٍ $remaining كم';
  }

  @override
  String get routeUnavailableShowingDirectLine =>
      'المسار غير متاح، يُعرض خط مباشر';

  @override
  String get recalculateRoute => 'إعادة حساب المسار';

  @override
  String get retryAction => 'إعادة المحاولة';

  @override
  String get locatingDriverPosition => 'جارٍ تحديد موقعك…';

  @override
  String get locationFixTimedOut =>
      'تعذّر تحديد موقعك. تحقق من الـ GPS وحاول مجددًا.';

  @override
  String get liveMapPhaseArrived => 'وصلت';

  @override
  String estimatedDistanceKm(String km) {
    return '$km كم';
  }

  @override
  String estimatedEtaMinutes(int minutes) {
    return 'الوصول المتوقع $minutes د';
  }

  @override
  String get tripReportTitle => 'تقرير الرحلة';

  @override
  String get tripReportInProgress => 'التقرير قيد التقدم';

  @override
  String get tripReportStartedAt => 'وقت البدء';

  @override
  String get tripReportFinishedAt => 'وقت الانتهاء';

  @override
  String get tripReportTotalDuration => 'المدة الإجمالية';

  @override
  String get tripReportGoingDuration => 'مدة الذهاب';

  @override
  String get tripReportWaitingDuration => 'الانتظار عند الوجهة';

  @override
  String get tripReportReturnDuration => 'مدة العودة';

  @override
  String get tripReportDistanceGoing => 'مسافة الذهاب';

  @override
  String get tripReportDistanceReturn => 'مسافة العودة';

  @override
  String get tripReportDistanceTotal => 'المسافة الإجمالية';

  @override
  String tripReportDistanceKmValue(String km) {
    return '$km كم';
  }

  @override
  String tripReportDurationHoursMinutesSeconds(
    int hours,
    int minutes,
    int seconds,
  ) {
    return '$hoursس $minutesد $secondsث';
  }

  @override
  String tripReportDurationMinutesSeconds(int minutes, int seconds) {
    return '$minutesد $secondsث';
  }

  @override
  String tripReportDurationSeconds(int seconds) {
    return '$secondsث';
  }

  @override
  String get tripReportRouteSection => 'المسار';

  @override
  String get tripReportGoingRouteLegend => 'الذهاب';

  @override
  String get tripReportReturnRouteLegend => 'العودة';

  @override
  String get viewTripDetails => 'تفاصيل الرحلة';

  @override
  String get noAvailableDriversTitle => 'لا يوجد سائقون متاحون';

  @override
  String get noAvailableDriversMessage =>
      'وافق على طلب توفر أولاً، أو انتظر حتى يصبح سائق متفرغًا.';

  @override
  String get relativeTimeJustNow => 'الآن';

  @override
  String relativeTimeMinutesAgo(int minutes) {
    return 'منذ $minutes د';
  }

  @override
  String relativeTimeHoursAgo(int hours) {
    return 'منذ $hours س';
  }

  @override
  String relativeTimeDaysAgo(int days) {
    return 'منذ $days ي';
  }

  @override
  String get favoritePlacesLabel => 'الأماكن المفضلة';

  @override
  String get favoritePlacesSearchHint => 'ابحث عن أماكن لإضافتها';

  @override
  String get favoritePlaceRemove => 'إزالة المكان المفضل';

  @override
  String get recommendedDriversSection => 'موصى بهم';

  @override
  String get otherDriversSection => 'سائقون آخرون';

  @override
  String get driverReasonFavoritePlace => 'مكان مفضل';

  @override
  String get driverReasonAvailable => 'متاح';

  @override
  String get driverReasonUnavailable => 'غير متاح';

  @override
  String get driverReasonOnActiveTrip => 'في رحلة نشطة';

  @override
  String get driverReasonScheduleConflict => 'تعارض في الجدول';

  @override
  String get assignDriverWarningTitle => 'تعيين هذا السائق؟';

  @override
  String get assignDriverWarningMessage =>
      'هذا السائق غير متاح بالكامل لهذه الرحلة. يمكنك تعيينه رغم ذلك.';

  @override
  String get assignDriverWarningContinue => 'تعيين على أي حال';

  @override
  String get driverFavoritePlacesEmpty => 'لا يوجد';

  @override
  String get myRequestsTab => 'طلباتي';

  @override
  String get myRequestsFilterAll => 'الكل';

  @override
  String get myRequestsFilterActive => 'النشطة';

  @override
  String get myRequestsFilterCompleted => 'المكتملة';

  @override
  String get myRequestsFilterCancelledRejected => 'ملغاة / مرفوضة';

  @override
  String get myRequestsEmptyTitle => 'لا توجد طلبات بعد';

  @override
  String get myRequestsEmptyMessage =>
      'ستظهر هنا طلبات الرحلات التي تنشئها لنفسك.';

  @override
  String get myRequestsFilteredEmptyMessage =>
      'لا توجد طلبات مطابقة لهذا التصفية.';

  @override
  String get myRequestProgressTitle => 'تقدم الطلب';

  @override
  String get requestProgressStepRequested => 'تم الطلب';

  @override
  String get requestProgressStepApproved => 'تمت الموافقة';

  @override
  String get requestProgressStepDriverAssigned => 'تم تعيين سائق';

  @override
  String get requestProgressStepGoing => 'في الطريق';

  @override
  String get requestProgressStepArrived => 'وصل';

  @override
  String get requestProgressStepReturning => 'العودة';

  @override
  String get requestProgressStepCompleted => 'مكتمل';

  @override
  String requestProgressCurrentStep(String step) {
    return 'الحالي: $step';
  }

  @override
  String requestProgressFailedStep(String step) {
    return 'فشل: $step';
  }

  @override
  String get assignedDriverSection => 'السائق المعيَّن';

  @override
  String assignedDriverPhoneValue(String phone) {
    return 'الهاتف: $phone';
  }

  @override
  String get assignedDriverPending => 'لم يُعيَّن سائق بعد.';

  @override
  String get roleLabelAdmin => 'مسؤول النظام';

  @override
  String get adminDashboardTitle => 'لوحة تحكم المسؤول';

  @override
  String get adminDashboardSubtitle =>
      'إدارة السائقين والأماكن والموظفين. اطلب رحلات لنفسك.';

  @override
  String get adminDriversSection => 'السائقون';

  @override
  String get adminDriversSectionHint =>
      'إضافة أو تعديل أو إلغاء تنشيط السائقين';

  @override
  String get adminPlacesSection => 'الأماكن';

  @override
  String get adminPlacesSectionHint => 'إدارة المواقع ونقاط الخريطة';

  @override
  String get adminEmployeesSection => 'الموظفون';

  @override
  String get adminEmployeesSectionHint =>
      'إضافة أو تعديل أو إلغاء تنشيط الموظفين';

  @override
  String get adminUsersSection => 'المستخدمون';

  @override
  String get adminUsersSectionHint => 'تعيين كلمة مرور مؤقتة لأي حساب';

  @override
  String get adminUsersSearchHint => 'ابحث بالاسم أو البريد أو الهاتف';

  @override
  String get adminFilterAllRoles => 'كل الأدوار';

  @override
  String get adminUsersEmptyTitle => 'لا يوجد مستخدمون';

  @override
  String get adminUsersEmptyMessage => 'لا توجد حسابات تطابق هذا البحث.';

  @override
  String get adminResetPasswordAction => 'إعادة تعيين كلمة المرور';

  @override
  String get adminResetPasswordTitle => 'إعادة تعيين كلمة المرور';

  @override
  String adminResetPasswordMessage(String name) {
    return 'يجب على $name تغيير كلمة المرور هذه عند تسجيل الدخول التالي.';
  }

  @override
  String get adminResetPasswordNote =>
      'شارك كلمة المرور هذه مع المستخدم. يجب تغييرها عند تسجيل الدخول.';

  @override
  String get adminResetPasswordSuccess => 'تم حفظ كلمة المرور المؤقتة.';

  @override
  String get adminTemporaryPasswordBadge => 'كلمة مرور مؤقتة';

  @override
  String get adminMyTripsSection => 'رحلاتي';

  @override
  String get adminMyTripsSectionHint => 'تابع تقدم طلباتك';

  @override
  String get adminRequestTripSection => 'طلب رحلة';

  @override
  String get adminRequestTripSectionHint => 'يُقبل تلقائياً ويُرسل لتعيين سائق';

  @override
  String get adminSearchHint => 'ابحث بالاسم أو البريد أو الهاتف';

  @override
  String get adminFilterAll => 'الكل';

  @override
  String get adminFilterActive => 'نشط';

  @override
  String get adminFilterInactive => 'غير نشط';

  @override
  String get adminFilterAllBranches => 'كل الفروع';

  @override
  String get adminDriversEmptyTitle => 'لا يوجد سائقون';

  @override
  String get adminDriversEmptyMessage =>
      'أضف سائقاً أو امسح عوامل التصفية لعرض النتائج.';

  @override
  String get adminEmployeesEmptyTitle => 'لا يوجد موظفون';

  @override
  String get adminEmployeesEmptyMessage =>
      'أضف موظفاً أو امسح عوامل التصفية لعرض النتائج.';

  @override
  String get adminAddEmployeeTitle => 'إضافة موظف';

  @override
  String get adminEditEmployeeTitle => 'تعديل موظف';

  @override
  String get adminAddEmployee => 'إضافة موظف';

  @override
  String get adminSaveEmployee => 'حفظ الموظف';

  @override
  String get adminEmployeeCreated => 'تم إنشاء الموظف';

  @override
  String get adminEmployeeUpdated => 'تم تحديث الموظف';

  @override
  String get adminSoftDeleteConfirmTitle => 'إلغاء تنشيط الحساب؟';

  @override
  String adminSoftDeleteDriverMessage(String name) {
    return 'سيتم إلغاء تنشيط $name ولن يتمكن من تسجيل الدخول. يُحتفظ بحساب المصادقة.';
  }

  @override
  String adminSoftDeleteEmployeeMessage(String name) {
    return 'سيتم إلغاء تنشيط $name ولن يتمكن من تسجيل الدخول. يُحتفظ بحساب المصادقة.';
  }

  @override
  String get adminSoftDeleteAction => 'إلغاء التنشيط';

  @override
  String get adminSoftDeleteSuccess => 'تم إلغاء تنشيط الحساب';

  @override
  String get adminReactivateAction => 'إعادة التنشيط';

  @override
  String get adminSeedDebugTitle => 'تهيئة ملف المسؤول (تطوير)';

  @override
  String get adminSeedDebugMessage =>
      'يكتب ملف مسؤول لمعرّف مستخدم موجود مسبقاً.';

  @override
  String get adminSeedUidLabel => 'معرّف المصادقة';

  @override
  String get adminSeedDebugAction => 'كتابة الملف';

  @override
  String get adminSeedDebugSuccess => 'تم كتابة ملف المسؤول';

  @override
  String get navMyTrips => 'رحلاتي';

  @override
  String get navTrips => 'الرحلات';

  @override
  String get navRequests => 'الطلبات';

  @override
  String get navPlaces => 'الأماكن';

  @override
  String get navMyRequests => 'طلباتي';

  @override
  String get navDrivers => 'السائقون';

  @override
  String get navLiveMap => 'الخريطة';

  @override
  String get navDashboard => 'لوحة التحكم';

  @override
  String get navEmployees => 'الموظفون';

  @override
  String get navUsers => 'المستخدمون';

  @override
  String get navRequestedTrips => 'الرحلات المطلوبة';

  @override
  String get navAssignedTrips => 'الرحلات المعيّنة';

  @override
  String get navCompletedTrips => 'الرحلات المكتملة';

  @override
  String get navStats => 'الإحصائيات';

  @override
  String get comingSoon => 'قريبًا';

  @override
  String get forcedChangePasswordTitle => 'غيّر كلمة المرور';

  @override
  String get forcedChangePasswordMessage =>
      'يجب تغيير كلمة المرور قبل المتابعة.';

  @override
  String get navProfile => 'الملف';

  @override
  String get navSettings => 'الإعدادات';

  @override
  String get navMore => 'المزيد';

  @override
  String get profileTitle => 'الملف الشخصي';

  @override
  String get profileSaved => 'تم حفظ الملف';

  @override
  String get profileSave => 'حفظ الملف';

  @override
  String get roleFieldLabel => 'الدور';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get languageSection => 'اللغة';

  @override
  String get changePasswordTitle => 'تغيير كلمة المرور';

  @override
  String get currentPasswordLabel => 'كلمة المرور الحالية';

  @override
  String get newPasswordLabel => 'كلمة المرور الجديدة';

  @override
  String get changePasswordAction => 'تحديث كلمة المرور';

  @override
  String get changePasswordSuccess => 'تم تحديث كلمة المرور';

  @override
  String get changePasswordRateLimited =>
      'محاولات كثيرة. حاول مرة أخرى بعد دقيقة.';

  @override
  String get logoutConfirmTitle => 'تسجيل الخروج؟';

  @override
  String get logoutConfirmMessage =>
      'ستحتاج إلى تسجيل الدخول مرة أخرى للمتابعة.';

  @override
  String get logoutActiveTripWarning =>
      'لديك رحلة جارية. تسجيل الخروج يوقف التتبع المباشر.';

  @override
  String get logoutConfirmAction => 'تسجيل الخروج';

  @override
  String liveMapScheduledAt(String time) {
    return 'الموعد $time';
  }

  @override
  String get myTripsTabAll => 'الكل';

  @override
  String get myTripsTabActive => 'النشطة';

  @override
  String get myTripsTabCompleted => 'المكتملة';

  @override
  String get myTripsTabCancelled => 'الملغاة';

  @override
  String myTripsNeedReport(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count رحلات تحتاج تقريرك',
      one: 'رحلة واحدة تحتاج تقريرك',
    );
    return '$_temp0';
  }

  @override
  String get myTripsEmptyTitle => 'لا توجد رحلات هنا';

  @override
  String get myTripsEmptyMessage => 'ستظهر طلبات الرحلات في هذا التبويب هنا.';

  @override
  String myTripsDriverName(String name) {
    return 'السائق: $name';
  }

  @override
  String get tripRequestDetailsTitle => 'تفاصيل الرحلة';

  @override
  String get detailPickup => 'الانطلاق';

  @override
  String get detailDestination => 'الوجهة';

  @override
  String get detailAddress => 'العنوان';

  @override
  String get detailRequestedAt => 'الموعد المطلوب';

  @override
  String get detailNotes => 'ملاحظات';

  @override
  String get detailPhone => 'الهاتف';

  @override
  String get detailBranch => 'الفرع';

  @override
  String get detailEmployee => 'الموظف';

  @override
  String get detailRejectionReason => 'سبب الرفض';

  @override
  String get detailHandledAt => 'تاريخ المعالجة';

  @override
  String get detailNoNotes => 'لا توجد ملاحظات';

  @override
  String get tripBlockTitle => 'الرحلة المعينة';

  @override
  String get tripBlockNoDriver => 'لم يُعيَّن سائق بعد';

  @override
  String get confirmationUnconfirmed =>
      'غير مؤكدة (أُغلقت تلقائيًا بعد 24 ساعة)';

  @override
  String get confirmationConfirmed => 'تم التأكيد';

  @override
  String get confirmationPending => 'بانتظار تقريرك';

  @override
  String get driverShowedUpYes => 'حضر السائق';

  @override
  String get driverShowedUpNo => 'لم يحضر السائق';

  @override
  String get confirmTripQuestion => 'هل حضر السائق؟';

  @override
  String get confirmTripYes => 'حضر السائق';

  @override
  String get confirmTripNo => 'لم يحضر';

  @override
  String get confirmTripNoteHint => 'اختياري';

  @override
  String get confirmTripSubmit => 'إرسال التقرير';

  @override
  String get confirmTripSuccess => 'تم إرسال تقرير الرحلة.';

  @override
  String get confirmTripAlreadyClosed =>
      'تم تأكيد هذه الرحلة أو إغلاقها بالفعل';

  @override
  String get confirmTripChooseAnswer => 'اختر هل حضر السائق.';

  @override
  String get confirmTripNoteTooLong => 'يجب ألا تتجاوز الملاحظة 500 حرف.';

  @override
  String get periodWeek => 'أسبوع';

  @override
  String get periodMonth => 'شهر';

  @override
  String get periodYear => 'سنة';

  @override
  String get periodAll => 'الكل';

  @override
  String get periodAllTime => 'كل الوقت';

  @override
  String get periodPrevious => 'الفترة السابقة';

  @override
  String get periodNext => 'الفترة التالية';

  @override
  String get assignedTripsEmptyMessage => 'لا توجد رحلات معينة في هذه الفترة.';

  @override
  String get completedTripsEmptyMessage =>
      'لا توجد رحلات مكتملة في هذه الفترة.';

  @override
  String tripDistanceValue(String distance) {
    return 'المسافة $distance كم';
  }

  @override
  String tripDurationValue(String duration) {
    return 'المدة $duration';
  }

  @override
  String get statsTrips => 'الرحلات';

  @override
  String get statsTime => 'الوقت';

  @override
  String get statsDistance => 'المسافة';

  @override
  String statsKmValue(String distance) {
    return '$distance كم';
  }

  @override
  String get statsChartEmpty => 'لا توجد رحلات في هذه الفترة.';

  @override
  String get myTripsTabCancelledRejected => 'ملغاة/مرفوضة';

  @override
  String tripStatusLine(String status) {
    return 'حالة الرحلة: $status';
  }

  @override
  String confirmationStatusValue(String status) {
    return 'التأكيد: $status';
  }

  @override
  String get driverDidNotShow => 'السائق لم يحضر';

  @override
  String get tripsAwaitingReportTab => 'بانتظار التقرير';

  @override
  String liveProgressLastSeen(String time) {
    return 'آخر ظهور $time';
  }

  @override
  String get liveMapStateOnTrip => 'في رحلة';

  @override
  String get liveMapStateAvailable => 'متاح';

  @override
  String get liveMapStateUnavailable => 'غير متاح';

  @override
  String get liveMapNoLocationTitle => 'لا يوجد موقع بعد';

  @override
  String get driverMustChangePasswordNote =>
      'يجب على السائق تغيير كلمة المرور هذه عند أول تسجيل دخول.';

  @override
  String get favoritePlacesLimit => 'اختر حتى 5 أماكن مفضلة.';

  @override
  String recommendationTier(int tier) {
    return 'المستوى $tier';
  }

  @override
  String recommendationTripsThisWeek(int count) {
    return '$count رحلات هذا الأسبوع';
  }

  @override
  String get cannotDeleteHeadquartersPlace => 'لا يمكن حذف مكان المقر.';

  @override
  String get loadMore => 'تحميل المزيد';

  @override
  String get createdByMeEmptyTitle => 'لا توجد رحلات في هذا التبويب';

  @override
  String get createdByMeEmptyMessage => 'الرحلات التي تنشئها ستظهر هنا.';

  @override
  String get adminTripsAwaitingReportEmptyMessage =>
      'لا توجد رحلات بانتظار تقرير الراكب.';

  @override
  String get liveMapNoDrivers => 'لا يوجد سائقون يطابقون هذا التصفية.';

  @override
  String get realtimeConnected => 'مباشر';

  @override
  String get realtimeConnecting => 'جار الاتصال';

  @override
  String get realtimeDisconnected => 'غير متصل';

  @override
  String get trackingPendingApproval => 'بانتظار الموافقة';

  @override
  String get trackingApprovedQuestion => 'تمت الموافقة؟';

  @override
  String trackingApprovedAt(String time) {
    return 'تمت الموافقة $time';
  }

  @override
  String get trackingNotYet => 'ليس بعد';

  @override
  String get trackingDriverQuestion => 'تم تعيين سائق؟';

  @override
  String trackingDriverLine(String name, String phone) {
    return '$name · $phone';
  }

  @override
  String get trackingNowQuestion => 'أين الطلب الآن؟';

  @override
  String get trackingStageSubmitted => 'تم الإرسال';

  @override
  String get trackingStageApproved => 'تمت الموافقة';

  @override
  String get trackingStageRejected => 'مرفوض';

  @override
  String get trackingStageDriverAssigned => 'تم تعيين سائق';

  @override
  String get trackingStageInProgress => 'قيد التنفيذ';

  @override
  String get trackingStageFinished => 'انتهت الرحلة';

  @override
  String get trackingStageAwaitingConfirmation => 'بانتظار التأكيد';

  @override
  String get trackingStageConfirmed => 'مؤكد';

  @override
  String get trackingStageUnconfirmed => 'غير مؤكد';

  @override
  String get trackingStageCancelled => 'ملغى';

  @override
  String get trackingChipDriverAssigned => 'تم تعيين سائق';

  @override
  String get trackingRejectionTitle => 'سبب الرفض';

  @override
  String trackingScheduled(String time) {
    return 'الموعد $time';
  }

  @override
  String trackingVehicle(String license) {
    return 'لوحة السيارة $license';
  }

  @override
  String get trackingNoPhone => 'لا يوجد هاتف';

  @override
  String get useThisTime => 'استخدم هذا الوقت';

  @override
  String get notificationsTitle => 'الإشعارات';

  @override
  String get notificationsEmpty => 'لا توجد إشعارات.';

  @override
  String get notificationsMarkAll => 'تعليم الكل كمقروء';

  @override
  String get notificationsUnread => 'غير مقروء';

  @override
  String get notificationUnknown => 'إشعار';

  @override
  String get notificationRequestSubmittedTitle => 'طلب رحلة جديد';

  @override
  String notificationRequestSubmittedBody(
    String requester,
    String pickup,
    String destination,
  ) {
    return 'طلب $requester رحلة من $pickup إلى $destination.';
  }

  @override
  String get notificationTripReadyTitle => 'رحلة جاهزة للتعيين';

  @override
  String notificationTripReadyBody(
    String requester,
    String pickup,
    String destination,
  ) {
    return '$requester بانتظار سائق للرحلة من $pickup إلى $destination.';
  }

  @override
  String get notificationTripAssignedTitle => 'تم تعيين السائق';

  @override
  String notificationTripAssignedBody(
    String driver,
    String pickup,
    String destination,
  ) {
    return 'تم تعيين $driver للرحلة من $pickup إلى $destination.';
  }

  @override
  String get notificationOwnTripAssignedTitle => 'تم تعيين سائق لرحلتك';

  @override
  String notificationOwnTripAssignedBody(
    String driver,
    String pickup,
    String destination,
  ) {
    return 'تم تعيين $driver لرحلتك من $pickup إلى $destination.';
  }

  @override
  String get notificationTripEndedTitle => 'انتهت الرحلة';

  @override
  String notificationTripEndedBody(String pickup, String destination) {
    return 'انتهت رحلتك من $pickup إلى $destination. يرجى تقديم التقرير.';
  }

  @override
  String get notificationChannelTrips => 'الرحلات';

  @override
  String get notificationChannelTripsDescription =>
      'تعيينات الرحلات وتحديثات الطلبات';

  @override
  String get navAttendance => 'الحضور';

  @override
  String get attendanceCardTitle => 'الحضور';

  @override
  String get attendanceNotCheckedIn => 'لم يتم تسجيل الحضور';

  @override
  String attendanceCheckedInAt(String time) {
    return 'تم تسجيل الحضور في $time';
  }

  @override
  String attendanceCheckedOutAt(String time) {
    return 'تم تسجيل الانصراف في $time';
  }

  @override
  String get attendanceScanCheckIn => 'امسح الرمز لتسجيل الحضور';

  @override
  String get attendanceScanCheckOut => 'امسح الرمز لتسجيل الانصراف';

  @override
  String get attendanceScanTitle => 'مسح رمز QR';

  @override
  String get attendanceScanCancelled => 'تم إلغاء المسح.';

  @override
  String get attendanceScanUnsupported =>
      'مسح الرمز يعمل على تطبيق أندرويد أو iOS. أوقف التطبيق بالكامل ثم افتحه على هاتف أو محاكي. إعادة التحميل السريعة لا تفعّل الكاميرا.';

  @override
  String get attendanceCheckedInSuccess => 'تم تسجيل الحضور.';

  @override
  String get attendanceCheckedOutSuccess => 'تم تسجيل الانصراف.';

  @override
  String get attendanceHistoryEmpty => 'لا يوجد حضور في هذه الفترة.';

  @override
  String attendanceTotals(int present, int absent, String hours) {
    return 'حاضر $present، غائب $absent، في الموقع $hours س';
  }

  @override
  String get attendanceAbsent => 'غائب';

  @override
  String get attendanceNoCheckOut => 'بدون انصراف';

  @override
  String attendanceDayLine(String checkIn, String checkOut, String hours) {
    return 'حضور $checkIn · انصراف $checkOut · $hours س';
  }

  @override
  String get attendanceStatusCheckedIn => 'حاضر';

  @override
  String get attendanceStatusCheckedOut => 'تم الانصراف';

  @override
  String get attendanceInvalidQr => 'رمز الاستجابة غير صالح.';

  @override
  String get attendanceMockLocation =>
      'لا يمكن استخدام موقع وهمي لتسجيل الحضور.';

  @override
  String get attendanceLowAccuracy => 'دقة الموقع غير كافية.';

  @override
  String attendanceOutsideRadius(int distance, int radius) {
    return 'أنت على بعد $distance م من المقر. النطاق المسموح $radius م.';
  }

  @override
  String get attendanceAlreadyCheckedIn => 'تم تسجيل حضورك اليوم.';

  @override
  String get attendanceNotCheckedInError => 'سجّل الحضور قبل الانصراف.';

  @override
  String get attendanceAlreadyCheckedOut => 'تم تسجيل انصرافك اليوم.';

  @override
  String get attendanceActiveTrip => 'أنهِ الرحلة الحالية قبل تسجيل الانصراف.';

  @override
  String get attendanceFilterAll => 'الكل';

  @override
  String get attendanceFilterCheckedIn => 'مسجّل الحضور اليوم';

  @override
  String get attendanceFilterNotCheckedIn => 'غير مسجّل الحضور';

  @override
  String get attendanceFilterEmpty => 'لا يوجد سائقون مطابقون لفلتر الحضور.';

  @override
  String get attendanceOnTrip => 'في رحلة';

  @override
  String get attendanceAdjustTitle => 'تعديل الحضور';

  @override
  String get attendanceWorkDate => 'يوم العمل';

  @override
  String get attendanceCheckInTime => 'وقت الحضور';

  @override
  String get attendanceCheckOutTime => 'وقت الانصراف';

  @override
  String get attendanceReasonLabel => 'السبب';

  @override
  String get attendanceReasonRequired => 'أدخل سببًا.';

  @override
  String get attendanceAdjustSave => 'حفظ';

  @override
  String get attendanceCancel => 'إلغاء';

  @override
  String get attendanceQrTitle => 'رمز الحضور';

  @override
  String get attendanceOffDay => 'اليوم إجازة أسبوعية.';

  @override
  String get locationPreciseRequired => 'يلزم موقع دقيق.';

  @override
  String get locationInaccurate => 'قراءة الموقع غير دقيقة بما يكفي.';

  @override
  String get locationMocked => 'المواقع الوهمية غير مسموحة.';

  @override
  String get slideToCheckIn => 'اسحب لتسجيل الحضور';

  @override
  String get slideToCheckOut => 'اسحب لتسجيل الانصراف';

  @override
  String get formSectionPersonal => 'البيانات الشخصية';

  @override
  String get formSectionContact => 'التواصل';

  @override
  String get formSectionVehicle => 'المركبة والرخصة';

  @override
  String get formSectionAccess => 'تسجيل الدخول';

  @override
  String get formSectionWork => 'العمل';

  @override
  String get formSectionLocation => 'الموقع';

  @override
  String get formSectionPlace => 'بيانات المكان';

  @override
  String get formFixErrors => 'راجع الحقول المحددة.';

  @override
  String get passwordStrengthWeak => 'ضعيفة';

  @override
  String get passwordStrengthFair => 'مقبولة';

  @override
  String get passwordStrengthGood => 'جيدة';

  @override
  String get passwordStrengthStrong => 'قوية';

  @override
  String get clearSearch => 'مسح البحث';

  @override
  String get adminTripsWeekTitle => 'رحلات هذا الأسبوع';

  @override
  String get adminTripsWeekSubtitle => 'المجدولة يوميًا، آخر 7 أيام';
}
