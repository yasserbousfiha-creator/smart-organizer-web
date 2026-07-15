import 'dart:html' as html;
import '../portal/portal_client.dart';

const _kVisitedFlagKey = 'smart_organizer_visited';
const String _kTable = 'site_visits';

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
