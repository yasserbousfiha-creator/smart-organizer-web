// ── Shared employee-portal translations (EN/AR toggle) ──────────
// tr() looks up the Arabic UI string and returns its English
// counterpart when isEnglish is true. The Arabic string itself
// stays the canonical value used for DB writes/comparisons —
// only the rendered Text changes.
const Map<String, String> portalArToEn = {
  // Common actions / statuses
  'إلغاء': 'Cancel',
  'إرسال': 'Send',
  'حفظ': 'Save',
  'تحديث': 'Refresh',
  'بحث...': 'Search...',
  'اختر': 'Select',
  'خروج': 'Logout',
  'تسجيل الخروج': 'Logout',
  'قيد المراجعة': 'Pending',
  'قيد الانتظار': 'Pending',
  'موافق عليها': 'Approved',
  'مرفوضة': 'Rejected',
  'الكل': 'All',
  'نشط': 'Active',
  'موظف': 'Employee',
  'الموظف': 'Employee',
  'ريال': 'SAR',
  'لا توجد نتائج': 'No results',
  'طلب جديد': 'New Request',

  // Leave types
  'سنوية': 'Annual',
  'مرضية': 'Sick',
  'طارئة': 'Emergency',
  'بدون راتب': 'Unpaid',
  'أخرى': 'Other',

  // Shift options
  'صباحي': 'Morning',
  'مسائي': 'Evening',
  'صباحي + مسائي': 'Morning + Evening',
  'متناوب': 'Rotating',
  'إداري': 'Administrative',

  // Request types
  'شهادة خبرة': 'Experience Certificate',
  'شهادة راتب': 'Salary Certificate',
  'طلب آخر': 'Other Request',

  // Login screen
  'أدخل اسم المستخدم': 'Enter your username',
  'اسم المستخدم أو كلمة المرور غير صحيحة': 'Incorrect username or password',
  'محاولات كثيرة، انتظر قليلاً': 'Too many attempts, please wait a moment',
  'بوابة الموظفين': 'Employee Portal',
  'سجّل دخولك للاطلاع على بياناتك': 'Sign in to view your information',
  'اسم المستخدم': 'Username',
  'كلمة المرور': 'Password',
  'تسجيل الدخول': 'Sign In',

  // Profile screen
  'الملف الشخصي': 'Profile',
  'بياناتك الوظيفية': 'Your employment details',
  'تغيير كلمة المرور': 'Change Password',
  'القسم': 'Department',
  'الدوام': 'Shift',
  'الجنسية': 'Nationality',
  'الهاتف': 'Phone',
  'البريد الإلكتروني': 'Email',
  'الحالة الوظيفية': 'Employment Status',
  'تاريخ بداية العقد': 'Contract Start Date',
  'تاريخ نهاية العقد': 'Contract End Date',
  'الراتب الأساسي الشهري': 'Basic Monthly Salary',
  'بيانات العيادة': 'Clinic Details',
  'أدخل كلمة المرور الحالية': 'Enter your current password',
  'كلمة المرور الجديدة يجب أن تكون 6 أحرف على الأقل':
      'New password must be at least 6 characters',
  'كلمتا المرور الجديدتان غير متطابقتين': 'The new passwords do not match',
  'كلمة المرور الجديدة مطابقة للحالية': 'New password matches current password',
  'تعذّر التحقق من الجلسة، سجّل الدخول مجدداً':
      'Could not verify session, please sign in again',
  'تم تغيير كلمة المرور بنجاح ✓': 'Password changed successfully ✓',
  'كلمة المرور الحالية غير صحيحة': 'Current password is incorrect',
  'كلمة المرور الحالية': 'Current Password',
  'كلمة المرور الجديدة': 'New Password',
  'تأكيد كلمة المرور الجديدة': 'Confirm New Password',
  'حفظ كلمة المرور الجديدة': 'Save New Password',

  // Leaves screen
  'الإجازات': 'Leaves',
  'إدارة إجازاتك وطلباتك': 'Manage your leaves and requests',
  'الرصيد': 'Balance',
  'مستخدم': 'Used',
  'متبقي': 'Remaining',
  'يرجى تحديد تاريخ البداية والنهاية': 'Please select the start and end dates',
  'لا يمكن تسجيل إجازة بتاريخ في الماضي': 'Cannot register a leave with a past date',
  'تاريخ النهاية يجب أن يكون بعد البداية': 'End date must be after the start date',
  'تجاوز الرصيد': 'Balance Exceeded',
  'إرسال رغم التجاوز': 'Send Anyway',
  'تم إرسال طلب الإجازة بنجاح ✓': 'Leave request sent successfully ✓',
  'سجل الطلبات': 'Request History',
  'لا توجد طلبات إجازات': 'No leave requests',
  'طلب إجازة جديدة': 'New Leave Request',
  'نوع الإجازة': 'Leave Type',
  'من تاريخ': 'From Date',
  'إلى تاريخ': 'To Date',
  'السبب (اختياري)': 'Reason (optional)',
  'السبب': 'Reason',
  'أيام': 'days',

  // Advances screen
  'السلف': 'Advances',
  'إدارة سلفك وطلباتك': 'Manage your advances and requests',
  'أدخل مبلغاً صحيحاً': 'Enter a valid amount',
  'أدخل مبلغ الاستقطاع الشهري': 'Enter the monthly deduction amount',
  'الاستقطاع الشهري لا يمكن أن يكون أكثر من إجمالي السلفة':
      'Monthly deduction cannot exceed the total advance amount',
  'مدة السداد تتجاوز 24 شهراً — يرجى رفع مبلغ الاستقطاع الشهري':
      'Repayment period exceeds 24 months — please increase the monthly deduction',
  'تم إرسال طلب السلفة ✓': 'Advance request sent ✓',
  'إجمالي السلف المتبقية': 'Total Remaining Advances',
  'سجل السلف': 'Advance History',
  'لا توجد سلف': 'No advances',
  'طلب سلفة جديدة': 'New Advance Request',
  'المبلغ المطلوب (ريال)': 'Requested Amount (SAR)',
  'الاستقطاع الشهري (ريال)': 'Monthly Deduction (SAR)',
  'إرسال الطلب': 'Submit Request',
  'المتبقي': 'Remaining',
  'شهري': 'Monthly',

  // Payslip screen
  'كشف الراتب': 'Payslip',
  'سجل مستحقاتك الشهرية': 'Your monthly payroll history',
  'لا توجد كشوف رواتب': 'No payslips',
  'صافي': 'Net',
  'يناير': 'January', 'فبراير': 'February', 'مارس': 'March',
  'أبريل': 'April', 'مايو': 'May', 'يونيو': 'June',
  'يوليو': 'July', 'أغسطس': 'August', 'سبتمبر': 'September',
  'أكتوبر': 'October', 'نوفمبر': 'November', 'ديسمبر': 'December',
  'الإيرادات': 'Earnings',
  'الراتب الأساسي': 'Basic Salary',
  'البدلات': 'Allowances',
  'العمولات': 'Commissions',
  'الاستقطاعات': 'Deductions',
  'استقطاع السلفة': 'Advance Deduction',
  'صافي الراتب': 'Net Salary',

  // Requests screen
  'الطلبات': 'Requests',
  'إرسال طلباتك الرسمية إلى الإدارة': 'Send your official requests to management',
  'جاري الإرسال...': 'Sending...',
  'الطلبات السابقة': 'Previous Requests',
  'لا توجد طلبات سابقة': 'No previous requests',
  'نوع الطلب (مثال: خطاب بنكي، إجازة طارئة...)':
      'Request type (e.g., bank letter, emergency leave...)',
  'تفاصيل إضافية (اختياري)': 'Additional details (optional)',
  'تم إرسال الطلب بنجاح': 'Request sent successfully',
  'يرجى التواصل مع المسؤول لإعداد النظام': 'please contact the admin to set up the system',

  // Messages screens (employee + admin)
  'المراسلات': 'Messages',
  'تواصل مع إدارة الموارد البشرية': 'Contact HR management',
  'ابدأ محادثة مع الإدارة': 'Start a conversation with management',
  'يمكنك إرسال أي استفسار أو طلب': 'You can send any inquiry or request',
  'اكتب رسالتك هنا...': 'Type your message here...',
  'فشل إرسال الرسالة — يرجى التواصل مع المسؤول لإعداد النظام':
      'Failed to send message — please contact the admin to set up the system',
  'محادثات الموظفين مع الإدارة': "Employee conversations with management",
  'لا توجد محادثات بعد': 'No conversations yet',
  'اكتب ردك هنا...': 'Type your reply here...',
  'فشل إرسال الرسالة': 'Failed to send message',
  'لا توجد رسائل بعد': 'No messages yet',

  // Clinic schedule screen
  'الأحد': 'Sunday', 'الاثنين': 'Monday', 'الثلاثاء': 'Tuesday',
  'الأربعاء': 'Wednesday', 'الخميس': 'Thursday', 'الجمعة': 'Friday',
  'السبت': 'Saturday',
  'جدول العيادات': 'Clinic Schedule',
  'توزيعك الأسبوعي في العيادات': 'Your weekly clinic distribution',
  'ملخص': 'Summary',
  'الجدول الأسبوعي': 'Weekly Schedule',
  'لم يتم تحديد جدول العيادات بعد': 'Clinic schedule not set yet',
  'يرجى التواصل مع الإدارة': 'Please contact management',
  'اليوم': 'Today',
  'إجازة': 'Off',

  // Admin screen
  'لوحة الإدارة': 'Admin Panel',
  'الموظفون': 'Employees',
  'الدوامات': 'Shifts',
  'لا توجد طلبات': 'No requests',
  'تمت الموافقة': 'Approved',
  'تم الرفض': 'Rejected',
  'رفض': 'Reject',
  'موافقة': 'Approve',
  'بحث باسم الموظف أو القسم...': 'Search by employee name or department...',
  'تم تحديث الدوام': 'Shift updated',

  // Admin messages screen
  // ('المراسلات' already covered above)

  // Dashboard / home tab (PortalHomeScreen)
  'الرئيسية': 'Home',
  'الإدارة': 'Admin',
  'ملفي': 'My Profile',
  'الراتب': 'Payslip',
  'العيادات': 'Clinics',
  'لوحة تحكم مدير النظام': 'System Admin Dashboard',
  'محادثات الموظفين': 'Employee chats',
  'مراجعة الطلبات': 'Review requests',
  'عرض البيانات': 'View data',
  'تعديل الجداول': 'Edit schedules',
  'إليك نظرة سريعة على بياناتك': "Here's a quick look at your info",
  'الحالة': 'Status',
  'الوصول السريع': 'Quick Access',
  'طلب إجازة': 'Request Leave',
  'طلب سلفة': 'Request Advance',
  'طلباتي': 'My Requests',
  'مراسلة الإدارة': 'Message Admin',
};

String tr(bool isEnglish, String ar) => isEnglish ? (portalArToEn[ar] ?? ar) : ar;
