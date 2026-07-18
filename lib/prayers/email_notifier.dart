import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

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

  static const _months = [
    'يناير', 'فبراير', 'مارس', 'أبريل', 'ماي', 'يونيو',
    'يوليوز', 'غشت', 'شتنبر', 'أكتوبر', 'نونبر', 'دجنبر',
  ];

  static bool _tzReady = false;

  /// Tetouan's actual wall-clock time, independent of the sending device's
  /// own (possibly misconfigured) timezone setting.
  static tz.TZDateTime _tetouanNow() {
    if (!_tzReady) {
      tz_data.initializeTimeZones();
      _tzReady = true;
    }
    return tz.TZDateTime.now(tz.getLocation('Africa/Casablanca'));
  }

  static String _formatTetouanTime(tz.TZDateTime t) {
    final hour12 = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final period = t.hour < 12 ? 'ص' : 'م';
    final minute = t.minute.toString().padLeft(2, '0');
    return '${t.day} ${_months[t.month - 1]} ${t.year} - $hour12:$minute $period';
  }

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
            'time': _formatTetouanTime(_tetouanNow()),
          },
        }),
      );
    } catch (_) {
      // نتجاهل أخطاء الشبكة حتى لا تعطل تجربة المستخدم داخل التطبيق.
    }
  }
}
