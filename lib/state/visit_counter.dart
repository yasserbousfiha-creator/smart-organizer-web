import '../portal/portal_client.dart';

const String _kTable = 'site_visits';

/// Logs every page load as its own visit — repeat visits from the same
/// device/browser each count separately, no per-device deduplication.
Future<int?> logVisitAndGetCount() async {
  try {
    await portalClient.from(_kTable).insert({});
    return await portalClient.from(_kTable).count();
  } catch (_) {
    return null;
  }
}
