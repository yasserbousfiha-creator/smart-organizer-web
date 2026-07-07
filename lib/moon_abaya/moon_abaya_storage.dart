import '../portal/portal_client.dart';
import 'moon_abaya_models.dart';

class MoonAbayaStorage {
  static const table = 'moon_abaya_items';
  static const paymentsTable = 'moon_abaya_payments';

  static Future<List<MoonAbayaItem>> load() async {
    final rows = await portalClient
        .from(table)
        .select('*, $paymentsTable(*)')
        .order('date', ascending: false);
    return (rows as List)
        .map((e) => MoonAbayaItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> upsert(MoonAbayaItem item) {
    return portalClient.from(table).upsert(item.toJson());
  }

  static Future<void> delete(String id) {
    return portalClient.from(table).delete().eq('id', id);
  }

  static Future<void> addPayment(String itemId, MoonAbayaPayment payment) {
    return portalClient.from(paymentsTable).insert(payment.toJson(itemId));
  }

  static Future<void> deletePayment(String paymentId) {
    return portalClient.from(paymentsTable).delete().eq('id', paymentId);
  }
}
