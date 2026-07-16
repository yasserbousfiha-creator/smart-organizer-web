import 'dart:convert';

import 'package:http/http.dart' as http;

/// يرسل بريدًا إلكترونيًا عبر EmailJS عند تفعيل صلاة.
///
/// أنشئ حسابًا مجانيًا على emailjs.com ثم عوّض القيم الثلاث أدناه:
/// - _serviceId: من صفحة Email Services
/// - _templateId: من صفحة Email Templates
/// - _publicKey: من Account > General > Public Key
/// وفعّل خيار "Allow EmailJS API for non-browser applications" من
/// Account > Security، لأن الطلب يأتي من تطبيق Flutter وليس من متصفح.
class PrayerEmailNotifier {
  static const String _serviceId = 'service_o8rg2v5';
  static const String _templateId = 'template_2xctwhu';
  static const String _publicKey = 'PsKFU9KMWN7uvG8qL';
  static const String _toEmail = 'yasserbousfiha@gmail.com';

  static const _endpoint = 'https://api.emailjs.com/api/v1.0/email/send';

  static Future<void> notifyPrayerActivated(String prayerLabel) async {
    if (_serviceId.startsWith('YOUR_')) return;
    try {
      await http.post(
        Uri.parse(_endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'service_id': _serviceId,
          'template_id': _templateId,
          'user_id': _publicKey,
          'template_params': {
            'to_email': _toEmail,
            'prayer_name': prayerLabel,
            'time': DateTime.now().toString(),
          },
        }),
      );
    } catch (_) {
      // نتجاهل أخطاء الشبكة حتى لا تعطل تجربة المستخدم داخل التطبيق.
    }
  }
}
