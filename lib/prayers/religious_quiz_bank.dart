class ReligiousQuizQuestion {
  const ReligiousQuizQuestion({
    required this.id,
    required this.dayIndex,
    required this.question,
    required this.options,
    required this.correctIndex,
  });

  final int id;

  /// Which day of the 15-day challenge cycle this question belongs to (1-15).
  final int dayIndex;
  final String question;
  final List<String> options;
  final int correctIndex;
}

/// Religious knowledge questions for a 10-year-old, based on the Quran and
/// Sunnah — 5 fixed questions per day across a 15-day cycle (matching the
/// prayer challenge length) instead of a random daily pick, so the topics
/// build up as a small curriculum: pillars of Islam/prayer/wudu, the Mothers
/// of the Believers, pillars of faith, prophets, the Seerah, the Quran,
/// the five prayers, Islamic manners, Ramadan, Hajj, and the names of Allah.
const List<ReligiousQuizQuestion> kReligiousQuizBank = [
  // Day 1 — أركان الإسلام الخمسة
  ReligiousQuizQuestion(id: 1, dayIndex: 1, question: 'كم عدد أركان الإسلام؟', options: ['ثلاثة', 'أربعة', 'خمسة', 'ستة'], correctIndex: 2),
  ReligiousQuizQuestion(id: 2, dayIndex: 1, question: 'ما هو الركن الأول من أركان الإسلام؟', options: ['الصلاة', 'الشهادتان', 'الصيام', 'الزكاة'], correctIndex: 1),
  ReligiousQuizQuestion(id: 3, dayIndex: 1, question: 'في أي شهر يجب على المسلم القادر أن يصوم؟', options: ['شعبان', 'رمضان', 'رجب', 'شوال'], correctIndex: 1),
  ReligiousQuizQuestion(id: 4, dayIndex: 1, question: 'الحج واجب على المسلم القادر كم مرة في العمر؟', options: ['مرة واحدة', 'مرتين', 'كل سنة', 'ثلاث مرات'], correctIndex: 0),
  ReligiousQuizQuestion(id: 5, dayIndex: 1, question: 'الزكاة تعني:', options: ['الصلاة في المسجد', 'إخراج جزء من المال للفقراء', 'الصيام في رمضان', 'الحج إلى مكة'], correctIndex: 1),

  // Day 2 — أركان الصلاة
  ReligiousQuizQuestion(id: 6, dayIndex: 2, question: 'ما هو أول ركن من أركان الصلاة؟', options: ['تكبيرة الإحرام', 'الركوع', 'السجود', 'التشهد'], correctIndex: 0),
  ReligiousQuizQuestion(id: 7, dayIndex: 2, question: 'ماذا نقرأ في كل ركعة من الصلاة؟', options: ['سورة الإخلاص', 'سورة الفاتحة', 'آية الكرسي', 'سورة الناس'], correctIndex: 1),
  ReligiousQuizQuestion(id: 8, dayIndex: 2, question: 'كم عدد السجدات في كل ركعة؟', options: ['واحدة', 'اثنتان', 'ثلاث', 'أربع'], correctIndex: 1),
  ReligiousQuizQuestion(id: 9, dayIndex: 2, question: 'ما اسم الركن الذي ننحني فيه وأيدينا على ركبتينا؟', options: ['السجود', 'الركوع', 'القيام', 'الجلوس'], correctIndex: 1),
  ReligiousQuizQuestion(id: 10, dayIndex: 2, question: 'بماذا تُختتم الصلاة؟', options: ['التكبير', 'السجود', 'التسليم', 'الركوع'], correctIndex: 2),

  // Day 3 — الوضوء ونواقضه
  ReligiousQuizQuestion(id: 11, dayIndex: 3, question: 'ما أول عضو نغسله في الوضوء؟', options: ['الوجه', 'الكفّان (اليدان)', 'الرجلان', 'الرأس'], correctIndex: 1),
  ReligiousQuizQuestion(id: 12, dayIndex: 3, question: 'كم مرة يُستحب أن نغسل كل عضو في الوضوء؟', options: ['مرة', 'مرتين', 'ثلاث مرات', 'أربع مرات'], correctIndex: 2),
  ReligiousQuizQuestion(id: 13, dayIndex: 3, question: 'ماذا نمسح في الوضوء ولا نغسله؟', options: ['الوجه', 'اليدين', 'الرأس', 'الرجلين'], correctIndex: 2),
  ReligiousQuizQuestion(id: 14, dayIndex: 3, question: 'أيّ من هذا ينقض الوضوء؟', options: ['قراءة القرآن', 'الخروج من الحمام (قضاء الحاجة)', 'السلام على الناس', 'الأكل الحلال'], correctIndex: 1),
  ReligiousQuizQuestion(id: 15, dayIndex: 3, question: 'ماذا نقول قبل أن نبدأ الوضوء؟', options: ['الحمد لله', 'بسم الله', 'الله أكبر', 'سبحان الله'], correctIndex: 1),

  // Day 4 — أمهات المؤمنين (1)
  ReligiousQuizQuestion(id: 16, dayIndex: 4, question: 'من هي أول زوجة للنبي محمد صلى الله عليه وسلم؟', options: ['عائشة', 'خديجة', 'حفصة', 'سودة'], correctIndex: 1),
  ReligiousQuizQuestion(id: 17, dayIndex: 4, question: 'ماذا نسمي زوجات النبي صلى الله عليه وسلم؟', options: ['الصحابيات', 'أمهات المؤمنين', 'المهاجرات', 'الأنصاريات'], correctIndex: 1),
  ReligiousQuizQuestion(id: 18, dayIndex: 4, question: 'من هي الزوجة التي كانت بنت أبي بكر الصديق رضي الله عنه؟', options: ['خديجة', 'عائشة', 'صفية', 'ميمونة'], correctIndex: 1),
  ReligiousQuizQuestion(id: 19, dayIndex: 4, question: 'كانت خديجة رضي الله عنها تعمل في:', options: ['الزراعة', 'التجارة', 'التعليم', 'الطب'], correctIndex: 1),
  ReligiousQuizQuestion(id: 20, dayIndex: 4, question: 'من هي أول من آمنت بالنبي صلى الله عليه وسلم من النساء؟', options: ['عائشة', 'خديجة', 'فاطمة', 'حفصة'], correctIndex: 1),

  // Day 5 — أمهات المؤمنين (2)
  ReligiousQuizQuestion(id: 21, dayIndex: 5, question: 'من هي زوجة النبي التي كانت بنت عمر بن الخطاب رضي الله عنه؟', options: ['حفصة', 'سودة', 'زينب', 'ميمونة'], correctIndex: 0),
  ReligiousQuizQuestion(id: 22, dayIndex: 5, question: 'تقريبًا، كم عدد أمهات المؤمنين (زوجات النبي صلى الله عليه وسلم)؟', options: ['خمس', 'ثمان', 'إحدى عشرة', 'ثلاث'], correctIndex: 2),
  ReligiousQuizQuestion(id: 23, dayIndex: 5, question: 'من هي أمّ المؤمنين التي أسلمت وتزوجها النبي بعد أن كانت من أهل خيبر؟', options: ['صفية بنت حيي', 'عائشة', 'أم سلمة', 'زينب بنت جحش'], correctIndex: 0),
  ReligiousQuizQuestion(id: 24, dayIndex: 5, question: 'من هي أمّ المؤمنين التي لُقبت بـ"أم المساكين" لكثرة إحسانها للفقراء؟', options: ['زينب بنت خزيمة', 'أم حبيبة', 'جويرية', 'ميمونة'], correctIndex: 0),
  ReligiousQuizQuestion(id: 25, dayIndex: 5, question: 'أي أمهات المؤمنين توفيت في مكة قبل هجرة النبي صلى الله عليه وسلم؟', options: ['عائشة', 'خديجة', 'حفصة', 'سودة'], correctIndex: 1),

  // Day 6 — أركان الإيمان الستة
  ReligiousQuizQuestion(id: 26, dayIndex: 6, question: 'كم عدد أركان الإيمان؟', options: ['أربعة', 'خمسة', 'ستة', 'سبعة'], correctIndex: 2),
  ReligiousQuizQuestion(id: 27, dayIndex: 6, question: 'الركن الأول من أركان الإيمان هو الإيمان بـ:', options: ['الملائكة', 'الله', 'الكتب', 'الرسل'], correctIndex: 1),
  ReligiousQuizQuestion(id: 28, dayIndex: 6, question: 'من الذين خلقهم الله من نور ولا يعصونه أبدًا؟', options: ['الجن', 'الملائكة', 'الإنس', 'الشياطين'], correctIndex: 1),
  ReligiousQuizQuestion(id: 29, dayIndex: 6, question: 'آخر الكتب السماوية وخاتمها هو:', options: ['التوراة', 'الإنجيل', 'الزبور', 'القرآن الكريم'], correctIndex: 3),
  ReligiousQuizQuestion(id: 30, dayIndex: 6, question: 'الإيمان بالقضاء والقدر يعني أن نؤمن بأن:', options: ['كل شيء يحدث بالصدفة', 'كل شيء بعلم الله وقدره', 'لا داعي للعمل والاجتهاد', 'الإنسان يتحكم بكل شيء'], correctIndex: 1),

  // Day 7 — أسماء بعض الأنبياء
  ReligiousQuizQuestion(id: 31, dayIndex: 7, question: 'من هو أول نبي وأول إنسان خلقه الله؟', options: ['نوح عليه السلام', 'آدم عليه السلام', 'إبراهيم عليه السلام', 'إدريس عليه السلام'], correctIndex: 1),
  ReligiousQuizQuestion(id: 32, dayIndex: 7, question: 'من هو النبي الذي ابتلعه الحوت؟', options: ['يونس عليه السلام', 'يوسف عليه السلام', 'يعقوب عليه السلام', 'صالح عليه السلام'], correctIndex: 0),
  ReligiousQuizQuestion(id: 33, dayIndex: 7, question: 'من هو النبي الذي بنى السفينة بأمر الله؟', options: ['نوح عليه السلام', 'هود عليه السلام', 'لوط عليه السلام', 'شعيب عليه السلام'], correctIndex: 0),
  ReligiousQuizQuestion(id: 34, dayIndex: 7, question: 'من هو النبي الذي أُلقي في النار فجعلها الله عليه بردًا وسلامًا؟', options: ['موسى عليه السلام', 'إبراهيم عليه السلام', 'داود عليه السلام', 'سليمان عليه السلام'], correctIndex: 1),
  ReligiousQuizQuestion(id: 35, dayIndex: 7, question: 'من هو النبي الذي كلّمه الله مباشرة على جبل الطور؟', options: ['عيسى عليه السلام', 'موسى عليه السلام', 'يوسف عليه السلام', 'هارون عليه السلام'], correctIndex: 1),

  // Day 8 — السيرة النبوية (المولد والهجرة)
  ReligiousQuizQuestion(id: 36, dayIndex: 8, question: 'في أي مدينة وُلد النبي محمد صلى الله عليه وسلم؟', options: ['المدينة المنورة', 'مكة المكرمة', 'الطائف', 'القدس'], correctIndex: 1),
  ReligiousQuizQuestion(id: 37, dayIndex: 8, question: 'إلى أي مدينة هاجر النبي صلى الله عليه وسلم؟', options: ['مكة المكرمة', 'المدينة المنورة', 'الطائف', 'دمشق'], correctIndex: 1),
  ReligiousQuizQuestion(id: 38, dayIndex: 8, question: 'من هو الصحابي الذي رافق النبي صلى الله عليه وسلم في هجرته؟', options: ['عمر بن الخطاب', 'أبو بكر الصديق', 'علي بن أبي طالب', 'عثمان بن عفان'], correctIndex: 1),
  ReligiousQuizQuestion(id: 39, dayIndex: 8, question: 'ما اسم أم النبي محمد صلى الله عليه وسلم؟', options: ['آمنة بنت وهب', 'حليمة السعدية', 'خديجة', 'فاطمة'], correctIndex: 0),
  ReligiousQuizQuestion(id: 40, dayIndex: 8, question: 'من هي المرضعة التي أرضعت النبي صلى الله عليه وسلم في صغره؟', options: ['آمنة', 'حليمة السعدية', 'خديجة', 'أم أيمن'], correctIndex: 1),

  // Day 9 — معلومات عن القرآن الكريم
  ReligiousQuizQuestion(id: 41, dayIndex: 9, question: 'ما هي أول سورة في ترتيب المصحف؟', options: ['البقرة', 'الفاتحة', 'الناس', 'الإخلاص'], correctIndex: 1),
  ReligiousQuizQuestion(id: 42, dayIndex: 9, question: 'ما هي أطول سورة في القرآن الكريم؟', options: ['آل عمران', 'البقرة', 'النساء', 'يوسف'], correctIndex: 1),
  ReligiousQuizQuestion(id: 43, dayIndex: 9, question: 'ما هي آخر سورة في ترتيب المصحف؟', options: ['الفلق', 'الإخلاص', 'الناس', 'الكوثر'], correctIndex: 2),
  ReligiousQuizQuestion(id: 44, dayIndex: 9, question: 'على من نزل القرآن الكريم؟', options: ['النبي موسى عليه السلام', 'النبي عيسى عليه السلام', 'النبي محمد صلى الله عليه وسلم', 'النبي إبراهيم عليه السلام'], correctIndex: 2),
  ReligiousQuizQuestion(id: 45, dayIndex: 9, question: 'ما اسم الملَك الذي كان ينزل بالوحي على النبي صلى الله عليه وسلم؟', options: ['ميكائيل', 'جبريل عليه السلام', 'إسرافيل', 'مالك'], correctIndex: 1),

  // Day 10 — الصلوات الخمس وعدد ركعاتها
  ReligiousQuizQuestion(id: 46, dayIndex: 10, question: 'كم عدد ركعات صلاة الفجر؟', options: ['ركعتان', 'ثلاث ركعات', 'أربع ركعات', 'ركعة واحدة'], correctIndex: 0),
  ReligiousQuizQuestion(id: 47, dayIndex: 10, question: 'كم عدد ركعات صلاة الظهر المفروضة؟', options: ['ركعتان', 'ثلاث ركعات', 'أربع ركعات', 'خمس ركعات'], correctIndex: 2),
  ReligiousQuizQuestion(id: 48, dayIndex: 10, question: 'كم عدد ركعات صلاة المغرب؟', options: ['ركعتان', 'ثلاث ركعات', 'أربع ركعات', 'ركعة واحدة'], correctIndex: 1),
  ReligiousQuizQuestion(id: 49, dayIndex: 10, question: 'أي صلاة تأتي بعد صلاة العصر؟', options: ['الظهر', 'المغرب', 'العشاء', 'الفجر'], correctIndex: 1),
  ReligiousQuizQuestion(id: 50, dayIndex: 10, question: 'كم مجموع عدد الركعات المفروضة في اليوم والليلة؟', options: ['15', '17', '20', '24'], correctIndex: 1),

  // Day 11 — آداب إسلامية عامة
  ReligiousQuizQuestion(id: 51, dayIndex: 11, question: 'ماذا نقول عندما نلتقي مسلمًا؟', options: ['صباح الخير فقط', 'السلام عليكم', 'مرحبا فقط', 'أهلا وسهلا فقط'], correctIndex: 1),
  ReligiousQuizQuestion(id: 52, dayIndex: 11, question: 'بأي يد يُستحب أن نأكل ونشرب؟', options: ['اليسرى', 'اليمنى', 'بكلتا اليدين', 'لا فرق'], correctIndex: 1),
  ReligiousQuizQuestion(id: 53, dayIndex: 11, question: 'ماذا نقول قبل الأكل؟', options: ['الحمد لله', 'بسم الله', 'سبحان الله', 'لا إله إلا الله'], correctIndex: 1),
  ReligiousQuizQuestion(id: 54, dayIndex: 11, question: 'ماذا نقول بعد الانتهاء من الأكل؟', options: ['بسم الله', 'الحمد لله', 'الله أكبر', 'أستغفر الله'], correctIndex: 1),
  ReligiousQuizQuestion(id: 55, dayIndex: 11, question: 'من الآداب الإسلامية، عند العطاس نقول:', options: ['سبحان الله', 'الحمد لله', 'الله أكبر', 'لا حول ولا قوة إلا بالله'], correctIndex: 1),

  // Day 12 — رمضان والصيام
  ReligiousQuizQuestion(id: 56, dayIndex: 12, question: 'في أي شهر هجري يصوم المسلمون؟', options: ['شعبان', 'رمضان', 'شوال', 'ذو الحجة'], correctIndex: 1),
  ReligiousQuizQuestion(id: 57, dayIndex: 12, question: 'من متى إلى متى يمتنع الصائم عن الطعام والشراب؟', options: ['من الظهر إلى المغرب', 'من الفجر إلى المغرب', 'من العصر إلى الفجر', 'طوال اليوم بدون توقف'], correctIndex: 1),
  ReligiousQuizQuestion(id: 58, dayIndex: 12, question: 'ماذا نسمي الوجبة التي نأكلها قبل الفجر في رمضان؟', options: ['الإفطار', 'السحور', 'العشاء', 'الغداء'], correctIndex: 1),
  ReligiousQuizQuestion(id: 59, dayIndex: 12, question: 'ماذا نسمي الوجبة التي نأكلها عند أذان المغرب في رمضان؟', options: ['السحور', 'الإفطار', 'الغداء', 'الفطور الصباحي'], correctIndex: 1),
  ReligiousQuizQuestion(id: 60, dayIndex: 12, question: 'العيد الذي يأتي بعد انتهاء شهر رمضان يسمى:', options: ['عيد الأضحى', 'عيد الفطر', 'عيد الهجرة', 'عيد المولد'], correctIndex: 1),

  // Day 13 — الحج وأركانه
  ReligiousQuizQuestion(id: 61, dayIndex: 13, question: 'إلى أي مدينة يذهب الحجاج لأداء فريضة الحج؟', options: ['المدينة المنورة', 'مكة المكرمة', 'القدس', 'الطائف'], correctIndex: 1),
  ReligiousQuizQuestion(id: 62, dayIndex: 13, question: 'ما اسم البيت الذي يطوف حوله الحجاج؟', options: ['المسجد الأقصى', 'الكعبة المشرفة', 'قبة الصخرة', 'مسجد قباء'], correctIndex: 1),
  ReligiousQuizQuestion(id: 63, dayIndex: 13, question: 'ماذا نسمي الطواف حول الكعبة؟', options: ['السعي', 'الطواف', 'الرمي', 'الوقوف'], correctIndex: 1),
  ReligiousQuizQuestion(id: 64, dayIndex: 13, question: 'في أي جبل يقف الحجاج يوم عرفة؟', options: ['جبل النور', 'جبل عرفة', 'جبل أحد', 'جبل الطور'], correctIndex: 1),
  ReligiousQuizQuestion(id: 65, dayIndex: 13, question: 'ماذا يلبس الرجل الحاج أثناء أداء مناسك الحج؟', options: ['ملابس ملونة', 'ثياب الإحرام البيضاء', 'بدلة رسمية', 'ملابس عادية'], correctIndex: 1),

  // Day 14 — من أسماء الله الحسنى
  ReligiousQuizQuestion(id: 66, dayIndex: 14, question: 'من أسماء الله الحسنى الذي يعني أنه يرزق جميع الخلق؟', options: ['الرزّاق', 'الخالق', 'الرحيم', 'العليم'], correctIndex: 0),
  ReligiousQuizQuestion(id: 67, dayIndex: 14, question: 'اسم الله "الرحمن" يدل على:', options: ['قوته سبحانه', 'رحمته الواسعة بجميع خلقه', 'غناه سبحانه', 'علمه سبحانه'], correctIndex: 1),
  ReligiousQuizQuestion(id: 68, dayIndex: 14, question: 'من أسماء الله الحسنى الذي يعني أنه يعلم كل شيء؟', options: ['العليم', 'القدير', 'الغفور', 'السميع'], correctIndex: 0),
  ReligiousQuizQuestion(id: 69, dayIndex: 14, question: 'اسم الله "الغفور" يدل على أنه سبحانه:', options: ['يرزق الخلق', 'يغفر الذنوب لمن تاب', 'يخلق كل شيء', 'يسمع كل شيء'], correctIndex: 1),
  ReligiousQuizQuestion(id: 70, dayIndex: 14, question: 'كم عدد أسماء الله الحسنى كما ورد في الحديث الشريف؟', options: ['99 اسمًا', '50 اسمًا', '100 اسم', '77 اسمًا'], correctIndex: 0),

  // Day 15 — مراجعة عامة
  ReligiousQuizQuestion(id: 71, dayIndex: 15, question: 'ما هو الركن الخامس من أركان الإسلام؟', options: ['الصلاة', 'الصيام', 'الزكاة', 'الحج'], correctIndex: 3),
  ReligiousQuizQuestion(id: 72, dayIndex: 15, question: 'ما هي أول سورة نزلت على النبي صلى الله عليه وسلم؟', options: ['الفاتحة', 'العلق', 'الإخلاص', 'البقرة'], correctIndex: 1),
  ReligiousQuizQuestion(id: 73, dayIndex: 15, question: 'من هي أول زوجة (أم مؤمنين) للنبي صلى الله عليه وسلم؟', options: ['عائشة', 'خديجة', 'حفصة', 'ميمونة'], correctIndex: 1),
  ReligiousQuizQuestion(id: 74, dayIndex: 15, question: 'كم عدد ركعات صلاة العشاء؟', options: ['ثلاث ركعات', 'أربع ركعات', 'ركعتان', 'خمس ركعات'], correctIndex: 1),
  ReligiousQuizQuestion(id: 75, dayIndex: 15, question: 'ماذا نقول عند بدء الوضوء؟', options: ['الحمد لله', 'بسم الله', 'الله أكبر', 'سبحان الله'], correctIndex: 1),
];
