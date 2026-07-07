enum MoonAbayaCategory { abaya, perfume, other }

extension MoonAbayaCategoryX on MoonAbayaCategory {
  String get label {
    switch (this) {
      case MoonAbayaCategory.abaya:
        return 'عباية';
      case MoonAbayaCategory.perfume:
        return 'عطر';
      case MoonAbayaCategory.other:
        return 'أخرى';
    }
  }

  static MoonAbayaCategory fromName(String name) {
    return MoonAbayaCategory.values.firstWhere(
      (c) => c.name == name,
      orElse: () => MoonAbayaCategory.other,
    );
  }
}

class MoonAbayaPayment {
  final String id;
  final double amount;
  final DateTime date;
  final String note;

  MoonAbayaPayment({
    required this.id,
    required this.amount,
    required this.date,
    this.note = '',
  });

  Map<String, dynamic> toJson(String itemId) => {
        'id': id,
        'item_id': itemId,
        'amount': amount,
        'date': date.toIso8601String(),
        'note': note,
      };

  factory MoonAbayaPayment.fromJson(Map<String, dynamic> json) {
    return MoonAbayaPayment(
      id: json['id'] as String,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      note: json['note'] as String? ?? '',
    );
  }
}

class MoonAbayaItem {
  final String id;
  final MoonAbayaCategory category;
  final String model;
  final double purchasePrice;
  final double salePrice;
  final int quantity;
  final String notes;
  final DateTime date;
  final bool sold;
  final String buyerName;
  final List<MoonAbayaPayment> payments;

  MoonAbayaItem({
    required this.id,
    required this.category,
    required this.model,
    required this.purchasePrice,
    required this.salePrice,
    required this.quantity,
    this.notes = '',
    required this.date,
    this.sold = true,
    this.buyerName = '',
    this.payments = const [],
  });

  double get unitProfit => salePrice - purchasePrice;
  double get totalCost => purchasePrice * quantity;
  double get totalRevenue => salePrice * quantity;
  double get totalProfit => unitProfit * quantity;

  double get amountPaid => payments.fold(0.0, (s, p) => s + p.amount);

  double get remainingDebt {
    final r = totalRevenue - amountPaid;
    return r < 0.01 ? 0 : r;
  }

  bool get isFullyPaid => remainingDebt <= 0.01;

  /// المبلغ المستلم فعلياً أقل من تكلفة الشراء، أي أن العملية في خسارة حالياً.
  bool get isCurrentLoss => amountPaid < totalCost;

  MoonAbayaItem copyWith({
    MoonAbayaCategory? category,
    String? model,
    double? purchasePrice,
    double? salePrice,
    int? quantity,
    String? notes,
    DateTime? date,
    bool? sold,
    String? buyerName,
    List<MoonAbayaPayment>? payments,
  }) {
    return MoonAbayaItem(
      id: id,
      category: category ?? this.category,
      model: model ?? this.model,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      salePrice: salePrice ?? this.salePrice,
      quantity: quantity ?? this.quantity,
      notes: notes ?? this.notes,
      date: date ?? this.date,
      sold: sold ?? this.sold,
      buyerName: buyerName ?? this.buyerName,
      payments: payments ?? this.payments,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category.name,
        'model': model,
        'purchase_price': purchasePrice,
        'sale_price': salePrice,
        'quantity': quantity,
        'notes': notes,
        'date': date.toIso8601String(),
        'sold': sold,
        'buyer_name': buyerName,
      };

  factory MoonAbayaItem.fromJson(Map<String, dynamic> json) {
    final rawPayments = json['moon_abaya_payments'] as List?;
    final payments = (rawPayments ?? const [])
        .map((e) => MoonAbayaPayment.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return MoonAbayaItem(
      id: json['id'] as String,
      category: MoonAbayaCategoryX.fromName(json['category'] as String? ?? ''),
      model: json['model'] as String? ?? '',
      purchasePrice: (json['purchase_price'] as num?)?.toDouble() ?? 0,
      salePrice: (json['sale_price'] as num?)?.toDouble() ?? 0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      notes: json['notes'] as String? ?? '',
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      sold: json['sold'] as bool? ?? true,
      buyerName: json['buyer_name'] as String? ?? '',
      payments: payments,
    );
  }
}
