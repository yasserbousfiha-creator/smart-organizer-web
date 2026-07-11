import 'dart:html' as html;
import '../portal/portal_client.dart';

const _kVisitedFlagKey = 'smart_organizer_visited';
const String _kTable = 'site_visits';

/// كيسجّل زيارة جديدة (مرة وحدة فكل متصفح، عبر localStorage) ويرجّع
/// العدد الإجمالي الحالي للزوار. إذا صرا أي خطأ (مثلاً الجدول ماكاينش
/// بعد فـSupabase) كيرجّع null بهدوء بلا ما يكسر الصفحة.
Future<int?> logVisitAndGetCount() async {
  try {
    final alreadyVisited = html.window.localStorage[_kVisitedFlagKey] == '1';
    if (!alreadyVisited) {
      html.window.localStorage[_kVisitedFlagKey] = '1';
      await portalClient.from(_kTable).insert({});
    }
    return await portalClient.from(_kTable).count();
  } catch (_) {
    return null;
  }
}
