class ScannedItem {
  final String name;
  final double unitPrice;
  final int quantity;

  const ScannedItem({
    required this.name,
    required this.unitPrice,
    this.quantity = 1,
  });

  double get amount => unitPrice * quantity;

  ScannedItem copyWith({String? name, double? unitPrice, int? quantity}) {
    return ScannedItem(
      name: name ?? this.name,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
    );
  }
}

class ScanBillResult {
  final String description;
  final List<ScannedItem> items;
  final double totalAmount;
  final String currency;

  /// True when the sum of parsed items doesn't reconcile with the detected
  /// total line (beyond a small tolerance) — the rule-based parser has no
  /// way to "reason" about the mismatch, so it just flags it for the human
  /// review step.
  final bool hasDiscrepancy;

  const ScanBillResult({
    required this.description,
    required this.items,
    required this.totalAmount,
    this.currency = 'VND',
    this.hasDiscrepancy = false,
  });

  double get itemsSum =>
      items.fold(0.0, (sum, item) => sum + item.amount);

  ScanBillResult copyWith({
    String? description,
    List<ScannedItem>? items,
    double? totalAmount,
    String? currency,
    bool? hasDiscrepancy,
  }) {
    return ScanBillResult(
      description: description ?? this.description,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      currency: currency ?? this.currency,
      hasDiscrepancy: hasDiscrepancy ?? this.hasDiscrepancy,
    );
  }
}
