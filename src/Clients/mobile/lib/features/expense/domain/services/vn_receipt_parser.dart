import '../models/scan_bill_result.dart';

/// Rule-based parser turning raw OCR text lines from a Vietnamese receipt
/// into a structured [ScanBillResult].
///
/// This is deliberately not an AI/LLM — it runs on-device with zero model
/// weights, using regex heuristics tuned for common Vietnamese receipt
/// conventions (dot-thousands, "K" shorthand, "x" multipliers). See
/// AI_OCR_LOCAL_REQUIREMENTS.md §6 for the algorithm this implements.
class VnReceiptParser {
  static const _totalKeywords = [
    'tong cong',
    'tong tien',
    'thanh tien',
    'tong thanh toan',
    'grand total',
    'total',
  ];

  static const _excludeKeywords = [
    'vat',
    'thue',
    'phi phuc vu',
    'service charge',
    'sub total',
    'subtotal',
  ];

  /// Trailing price token: dot-thousands ("1.250.000"), "K" shorthand ("45K"),
  /// or plain digits (4+ digits to avoid matching quantities/table numbers),
  /// optionally followed by a currency marker.
  static final _priceRegex = RegExp(
    r'(\d{1,3}(?:\.\d{3})+|\d+[kK]|\d{4,})\s*(?:đ|d|vnd|VND)?\s*$',
  );

  static final _multiplierSuffixRegex = RegExp(r'[xX]\s*(\d+)\s*$');
  static final _multiplierPrefixRegex = RegExp(r'^(\d+)\s*[xX]\s*');

  static final _foreignCurrencyRegex = RegExp(
    r'\b(USD|EUR|THB|JPY|KRW|GBP)\b',
    caseSensitive: false,
  );

  ScanBillResult parse(List<String> lines, {String? fallbackDescription}) {
    final normalized = lines
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    if (normalized.isEmpty) {
      return ScanBillResult(
        description: fallbackDescription ?? 'Hóa đơn',
        items: const [],
        totalAmount: 0,
        currency: 'VND',
      );
    }

    double? detectedTotal;
    final items = <ScannedItem>[];
    String currency = _detectCurrency(normalized) ?? 'VND';

    for (final line in normalized) {
      final normalizedForKeywords = _stripDiacritics(line.toLowerCase());

      final priceMatch = _priceRegex.firstMatch(line);
      if (priceMatch == null) {
        continue; // noise line: store name, address, footer, etc.
      }

      final amount = _parseAmount(priceMatch.group(1)!);
      if (amount == null || amount <= 0) continue;

      final isTotalLine =
          _totalKeywords.any((kw) => normalizedForKeywords.contains(kw));
      if (isTotalLine) {
        detectedTotal ??= amount;
        continue;
      }

      final isExcluded =
          _excludeKeywords.any((kw) => normalizedForKeywords.contains(kw));
      if (isExcluded) {
        continue;
      }

      final beforePrice = line.substring(0, priceMatch.start).trim();

      var quantity = 1;
      var itemName = beforePrice;

      final suffixMatch = _multiplierSuffixRegex.firstMatch(beforePrice);
      final prefixMatch = _multiplierPrefixRegex.firstMatch(beforePrice);
      if (suffixMatch != null) {
        quantity = int.tryParse(suffixMatch.group(1)!) ?? 1;
        itemName = beforePrice.substring(0, suffixMatch.start).trim();
      } else if (prefixMatch != null) {
        quantity = int.tryParse(prefixMatch.group(1)!) ?? 1;
        itemName = beforePrice.substring(prefixMatch.end).trim();
      }

      if (itemName.isEmpty) {
        itemName = 'Mục không tên';
      }
      if (quantity <= 0) quantity = 1;

      final unitPrice = amount / quantity;
      items.add(ScannedItem(
        name: itemName,
        unitPrice: unitPrice,
        quantity: quantity,
      ));
    }

    final itemsSum = items.fold(0.0, (sum, i) => sum + i.amount);
    final totalAmount = detectedTotal ?? itemsSum;

    final hasDiscrepancy = detectedTotal != null &&
        items.isNotEmpty &&
        (detectedTotal - itemsSum).abs() > detectedTotal * 0.05;

    final description = fallbackDescription ??
        (normalized.isNotEmpty ? normalized.first : 'Hóa đơn');

    return ScanBillResult(
      description: description,
      items: items,
      totalAmount: totalAmount,
      currency: currency,
      hasDiscrepancy: hasDiscrepancy,
    );
  }

  double? _parseAmount(String token) {
    final kMatch = RegExp(r'^(\d+)[kK]$').firstMatch(token);
    if (kMatch != null) {
      return double.parse(kMatch.group(1)!) * 1000;
    }
    final digitsOnly = token.replaceAll('.', '').replaceAll(',', '');
    return double.tryParse(digitsOnly);
  }

  String? _detectCurrency(List<String> lines) {
    for (final line in lines) {
      final match = _foreignCurrencyRegex.firstMatch(line);
      if (match != null) {
        return match.group(1)!.toUpperCase();
      }
      if (line.contains('\$')) return 'USD';
    }
    return null;
  }

  static String _stripDiacritics(String input) {
    const withDiacritics =
        'àáảãạăằắẳẵặâầấẩẫậèéẻẽẹêềếểễệìíỉĩịòóỏõọôồốổỗộơờớởỡợùúủũụưừứửữựỳýỷỹỵđ';
    const withoutDiacritics =
        'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';

    final buffer = StringBuffer();
    for (final rune in input.runes) {
      final char = String.fromCharCode(rune);
      final index = withDiacritics.indexOf(char);
      buffer.write(index >= 0 ? withoutDiacritics[index] : char);
    }
    return buffer.toString();
  }
}
