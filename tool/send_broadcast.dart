// أداة سطر أوامر لإرسال إشعار جماعي مخصَّص بالاسم لكل مستخدم عبر Firebase
// Cloud Messaging - طلب صريح: "ياسر لا تنس قيام الليل" عند مستخدم،
// "فيصل لا تنس قيام الليل" عند آخر، من نفس الإرسال الواحد. ونص مختلف حسب
// لغة كل مستخدم (طلب صريح): عربي افتراضي، وفرنسي/إنجليزي اختياريان.
//
// لماذا سكربت منفصل بدل لوحة Firebase Console مباشرة: لوحة Firebase لا
// تدعم إرسال رسائل "بيانات فقط" (data-only) من واجهتها الرسومية، وهذا
// بالضبط ما يحتاجه التخصيص الموثوق - رسائل notification العادية (التي
// ترسلها اللوحة) يعرضها أندرويد تلقائياً بالنص الخام والتطبيق في الخلفية،
// بلا أي فرصة لتطبيقنا لتخصيصها. رسالة "بيانات فقط" تصل دائماً لكود
// التطبيق (في كل الحالات) فيبني هو الإشعار محلياً، يختار لغة المستخدم،
// ويستبدل {name}.
//
// عناصر نائبة أخرى (طلب صريح: "الجو حار اليوم في {مدينتك}") تُستبدَل محلياً
// أيضاً من بيانات كل جهاز الخاصة (لا استهداف/تجزئة من جهة الإرسال إطلاقاً):
//   {city} - اسم المدينة المختارة لمواقيت الصلاة عند ذلك المستخدم تحديداً.
//   {temp} - آخر قراءة حرارة معروفة (مخزَّنة محلياً، قد تتأخر ببضع ساعات عن
//            الفعلي - نفس مصدر الطقس المعروض بشريط الصلاة والويدجت).
//   {temp_tomorrow} - أعلى حرارة متوقَّعة غداً فمدينة ذلك المستخدم (Open-Meteo).
//   {temp_tomorrow_min} - أدنى حرارة متوقَّعة غداً.
//   {temp_tomorrow_range} - الصيغة الجاهزة "أدنى-أقصى" (مثلاً "22-38") بدل
//                           كتابة العنصرين يدوياً.
// مثال: "{name} مساء الخير، الجو حار اليوم في {city} بدرجة حرارة {temp}°"
// يصل لكل مستخدم برقم حرارة مدينته هو تحديداً، لا رقم ثابت واحد للجميع.
//
// الإعداد لمرة واحدة فقط:
//   1. Firebase Console → ⚙️ Project settings → Service accounts
//   2. اضغط "Generate new private key" → سيُحمَّل ملف JSON
//   3. احفظه في نفس مجلد المشروع باسم service-account.json (بلا مشاركته
//      مع أي أحد - هذا مفتاح كامل الصلاحية لإرسال الإشعارات باسم مشروعك)
//
// الاستخدام (عربي فقط، الحالة الشائعة):
//   dart run tool/send_broadcast.dart "العنوان" "النص - استخدم {name} لإدراج اسم المستخدم"
//
// مثال فعلي مطابق للطلب:
//   dart run tool/send_broadcast.dart "تذكير" "{name} لا تنس قيام الليل"
//
// لإضافة نص فرنسي/إنجليزي مختلف (اختياري):
//   dart run tool/send_broadcast.dart "العنوان" "النص العربي" \
//     --fr-title "Titre" --fr-body "Texte {name}" \
//     --en-title "Title" --en-body "Text {name}"
// (نفس الشيء عبر أداة GitHub Actions - الخانات الفرنسية/الإنجليزية اختيارية
// هناك أيضاً؛ عند تركها فارغة يصل النص العربي لكل المستخدمين مهما كانت لغتهم)
//
// طلب صريح: إرسال يصل الساعة 12 ظهراً لكل مستخدم بتوقيته المحلي هو (لا
// بتوقيت واحد ثابت يصل بأوقات مختلفة فعلياً - المغرب مثلاً يستقبله 10
// صباحاً لو أُرسل بتوقيت السعودية الثابت). أضف --time "HH:mm" (24 ساعة):
// كل تطبيق يجدوِل الإشعار محلياً لتلك الساعة بتوقيت جهازه هو (اليوم، أو
// غداً إن كانت الساعة قد فاتت اليوم فعلاً) - بلا أي حساب فارق توقيت يدوي.
// بدون --time يصل الإشعار فوراً كالمعتاد.
//   dart run tool/send_broadcast.dart "تذكير" "{name} حان وقت الظهر" --time "12:00"

import 'dart:convert';
import 'dart:io';

import 'package:googleapis_auth/auth_io.dart' as auth;

const _projectId = 'smartorganizer-f9ba5';
const _topic = 'all_users';
const _scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

const _usage =
    'الاستخدام: dart run tool/send_broadcast.dart "العنوان" "النص" '
    '[--fr-title "..." --fr-body "..."] [--en-title "..." --en-body "..."] '
    '[--time "HH:mm"]';

final _timePattern = RegExp(r'^([01]?\d|2[0-3]):[0-5]\d$');

Future<void> main(List<String> args) async {
  if (args.length < 2) {
    stderr.writeln(_usage);
    exit(1);
  }
  final titleAr = args[0];
  final bodyAr = args[1];
  String? titleFr, bodyFr, titleEn, bodyEn, time;
  for (var i = 2; i < args.length; i++) {
    switch (args[i]) {
      case '--fr-title':
        titleFr = args[++i];
        break;
      case '--fr-body':
        bodyFr = args[++i];
        break;
      case '--en-title':
        titleEn = args[++i];
        break;
      case '--en-body':
        bodyEn = args[++i];
        break;
      case '--time':
        time = args[++i];
        break;
      default:
        stderr.writeln('خيار غير معروف: ${args[i]}\n$_usage');
        exit(1);
    }
  }
  if (time != null && !_timePattern.hasMatch(time)) {
    stderr.writeln('صيغة --time غير صحيحة، يجب أن تكون "HH:mm" مثل "12:00"\n$_usage');
    exit(1);
  }

  final serviceAccountFile = File('service-account.json');
  if (!serviceAccountFile.existsSync()) {
    stderr.writeln(
      'لم أجد service-account.json في مجلد المشروع.\n'
      'حمّله مرة واحدة من: Firebase Console → إعدادات المشروع (⚙️) → Service accounts → Generate new private key',
    );
    exit(1);
  }

  final credentials = auth.ServiceAccountCredentials.fromJson(
    jsonDecode(serviceAccountFile.readAsStringSync()) as Map<String, dynamic>,
  );

  final client = await auth.clientViaServiceAccount(credentials, _scopes);
  try {
    final data = <String, String>{
      'title_ar': titleAr,
      'body_ar': bodyAr,
      if (titleFr != null) 'title_fr': titleFr,
      if (bodyFr != null) 'body_fr': bodyFr,
      if (titleEn != null) 'title_en': titleEn,
      if (bodyEn != null) 'body_en': bodyEn,
      if (time != null) 'time': time,
    };
    final response = await client.post(
      Uri.parse('https://fcm.googleapis.com/v1/projects/$_projectId/messages:send'),
      headers: {'Content-Type': 'application/json'},
      // data-only عمداً (بلا حقل "notification") حتى يصل دائماً لكود
      // التطبيق نفسه في كل الحالات (مقدّمة/خلفية/مغلق تماماً)، هو من يبني
      // الإشعار محلياً ويختار لغة المستخدم ويستبدل {name} - انظر main.dart،
      // _showPersonalizedFcmNotification.
      body: jsonEncode({
        'message': {'topic': _topic, 'data': data},
      }),
    );
    if (response.statusCode == 200) {
      stdout.writeln('✅ تم الإرسال بنجاح لكل المستخدمين المشتركين.');
    } else {
      stderr.writeln('❌ فشل الإرسال (${response.statusCode}): ${response.body}');
      exit(1);
    }
  } finally {
    client.close();
  }
}
