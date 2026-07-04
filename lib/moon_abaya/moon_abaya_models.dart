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
  final double amountPaid;
  final String buyerName;

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
    double? amountPaid,
    this.buyerName = '',
  }) : amountPaid = amountPaid ?? (salePrice * quantity);

  double get unitProfit => salePrice - purchasePrice;
  double get totalCost => purchasePrice * quantity;
  double get totalRevenue => salePrice * quantity;
  double get totalProfit => unitProfit * quantity;

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
    double? amountPaid,
    String? buyerName,
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
      amountPaid: amountPaid ?? this.amountPaid,
      buyerName: buyerName ?? this.buyerName,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category.name,
        'model': model,
        'purchasePrice': purchasePrice,
        'salePrice': salePrice,
        'quantity': quantity,
        'notes': notes,
        'date': date.toIso8601String(),
        'sold': sold,
        'amountPaid': amountPaid,
        'buyerName': buyerName,
      };

  factory MoonAbayaItem.fromJson(Map<String, dynamic> json) {
    return MoonAbayaItem(
      id: json['id'] as String,
      category: MoonAbayaCategoryX.fromName(json['category'] as String? ?? ''),
      model: json['model'] as String? ?? '',
      purchasePrice: (json['purchasePrice'] as num?)?.toDouble() ?? 0,
      salePrice: (json['salePrice'] as num?)?.toDouble() ?? 0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      notes: json['notes'] as String? ?? '',
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      sold: json['sold'] as bool? ?? true,
      amountPaid: (json['amountPaid'] as num?)?.toDouble(),
      buyerName: json['buyerName'] as String? ?? '',
    );
  }
}
