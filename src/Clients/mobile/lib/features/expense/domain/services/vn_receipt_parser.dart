import '../models/scan_bill_result.dart';

/// Rule-based parser turning raw OCR text lines from a Vietnamese receipt
/// into a structured [ScanBillResult].
///
/// This is deliberately not an AI/LLM — it runs on-device with zero model
/// weights, using regex heuristics tuned for common Vietnamese receipt
/// conventions (dot-thousands, "K" shorthand, "x" multipliers, and tabular
/// "Số lượng | Đơn giá | Thành tiền" columns). See
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
    // Header/footer noise on printed invoices (date, phone, receipt no.) —
    // these often end in a bare digit run that looks like a price token.
    'ngay',
    'dien thoai',
    'so ct',
  ];

  static const _trailingUnitWords = [
    'vien',
    'hop',
    'chai',
    'goi',
    'cai',
    'vi',
    'tuyp',
    'lo',
    'ong',
    'kg',
    'ml',
    'lit',
  ];

  /// Any monetary-looking number: dot-thousands ("1.250.000"), "K" shorthand
  /// ("45K"), or a bare 4+ digit run. Matched anywhere on the line (not just
  /// at the end), since a tabular row can have several — quantity, unit
  /// price, and total — trailing after the item name.
  static final _moneyTokenRegex = RegExp(
    r'\d{1,3}(?:\.\d{3})+|\d+[kK]|\d{4,}',
  );

  /// A standalone 1-3 digit integer (a plausible "Số lượng" quantity or STT
  /// index) — not part of a dot-thousands group and not glued to letters
  /// (e.g. "30mg", "H/60v" don't count).
  static final _standaloneIntRegex = RegExp(r'(?<!\.)\b\d{1,3}\b(?!\.\d)');

  static final _multiplierSuffixRegex = RegExp(r'[xX]\s*(\d+)\s*$');
  static final _multiplierPrefixRegex = RegExp(r'^(\d+)\s*[xX]\s*');

  static final _leadingIndexRegex = RegExp(r'^\d{1,3}\s+');

  static final _trailingUnitRegex = RegExp(
    r'\s+(' + _trailingUnitWords.join('|') + r')$',
    caseSensitive: false,
  );

  static final _foreignCurrencyRegex = RegExp(
    r'\b(USD|EUR|THB|JPY|KRW|GBP)\b',
    caseSensitive: false,
  );

  static const _transferAmountKeywords = [
    'so tien',
    'so tien chuyen',
    'so tien giao dich',
    'amount',
  ];

  static const _transferContentKeywords = [
    'noi dung',
    'noi dung chuyen khoan',
    'loi nhan',
    'dien giai',
    'message',
    'content',
    'description',
  ];

  /// Parses a bank-transfer slip (biên lai chuyển khoản) rather than an
  /// itemized bill. A transfer has a single amount and a free-text content
  /// line instead of line items, so this produces a one-item [ScanBillResult]:
  ///   - amount: the value on a "Số tiền" line, else the largest money token
  ///   - description: the "Nội dung" line, else the fallback, else "Chuyển khoản"
  ScanBillResult parseTransferSlip(List<String> lines,
      {String? fallbackDescription}) {
    final normalized = lines
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final currency = _detectCurrency(normalized) ?? 'VND';

    double? amount;
    // 1) Prefer a line explicitly labelled as the amount.
    for (final line in normalized) {
      final key = _stripDiacritics(line.toLowerCase());
      if (_transferAmountKeywords.any((kw) => key.contains(kw))) {
        final matches = _moneyTokenRegex.allMatches(line).toList();
        if (matches.isNotEmpty) {
          final parsed = _parseAmount(matches.last.group(0)!);
          if (parsed != null && parsed > 0) {
            amount = parsed;
            break;
          }
        }
      }
    }
    // 2) Fallback: the largest money token anywhere on the slip.
    amount ??= normalized
        .expand((l) => _moneyTokenRegex.allMatches(l))
        .map((m) => _parseAmount(m.group(0)!) ?? 0)
        .fold<double>(0, (max, v) => v > max ? v : max);

    // Description from a "Nội dung" line, else fallback.
    String? description;
    for (final line in normalized) {
      final key = _stripDiacritics(line.toLowerCase());
      final kw = _transferContentKeywords
          .firstWhere((k) => key.contains(k), orElse: () => '');
      if (kw.isNotEmpty) {
        final idx = key.indexOf(kw) + kw.length;
        final tail = line.substring(idx).replaceFirst(RegExp(r'^[:\s]+'), '');
        if (tail.trim().isNotEmpty) {
          description = tail.trim();
          break;
        }
      }
    }
    description ??= fallbackDescription ?? 'Chuyển khoản';

    final items = amount > 0
        ? [ScannedItem(name: description, unitPrice: amount, quantity: 1)]
        : <ScannedItem>[];

    return ScanBillResult(
      description: description,
      items: items,
      totalAmount: amount,
      currency: currency,
    );
  }

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

      final moneyMatches = _moneyTokenRegex.allMatches(line).toList();
      if (moneyMatches.isEmpty) {
        continue; // noise line: store name, address, footer, etc.
      }

      final lastMatch = moneyMatches.last;
      final lastAmount = _parseAmount(lastMatch.group(0)!);
      if (lastAmount == null || lastAmount <= 0) continue;

      final isTotalLine =
          _totalKeywords.any((kw) => normalizedForKeywords.contains(kw));
      if (isTotalLine) {
        detectedTotal ??= lastAmount;
        continue;
      }

      final isExcluded =
          _excludeKeywords.any((kw) => normalizedForKeywords.contains(kw));
      if (isExcluded) {
        continue;
      }

      final tabularItem = _tryParseTabularRow(line, moneyMatches, lastAmount);
      if (tabularItem != null) {
        items.add(tabularItem);
        continue;
      }

      items.add(_parseSimpleRow(line, lastMatch, lastAmount));
    }

    final itemsSum = items.fold(0.0, (sum, i) => sum + i.amount);
    final totalAmount = detectedTotal ?? itemsSum;

    final hasDiscrepancy = detectedTotal != null &&
        items.isNotEmpty &&
        (detectedTotal - itemsSum).abs() > detectedTotal * 0.05;

    final description = _pickTitle(normalized, fallbackDescription);

    return ScanBillResult(
      description: description,
      items: items,
      totalAmount: totalAmount,
      currency: currency,
      hasDiscrepancy: hasDiscrepancy,
    );
  }

  /// Handles a tabular row shaped like
  /// "<STT> <name> <ĐVT> <Số lượng> <Đơn giá> <Thành tiền>" — common on
  /// printed invoices (pharmacy/retail bills) that list quantity and unit
  /// price as separate columns instead of an inline "xN" shorthand.
  ///
  /// Requires at least 2 money tokens (unit price + total) and a standalone
  /// integer immediately before the unit price that reconciles
  /// (qty * unitPrice ≈ total). Falls back to null if it doesn't fit, so
  /// ambiguous lines go through the simpler single-price path instead.
  ScannedItem? _tryParseTabularRow(
    String line,
    List<RegExpMatch> moneyMatches,
    double total,
  ) {
    if (moneyMatches.length < 2) return null;

    final unitPriceMatch = moneyMatches[moneyMatches.length - 2];
    final unitPrice = _parseAmount(unitPriceMatch.group(0)!);
    if (unitPrice == null || unitPrice <= 0) return null;

    final qtyMatch = _lastStandaloneIntBefore(line, unitPriceMatch.start);
    if (qtyMatch == null) return null;

    final qty = int.tryParse(qtyMatch.group(0)!) ?? 0;
    if (qty <= 0) return null;

    if ((qty * unitPrice - total).abs() > total * 0.05) return null;

    var itemName = line.substring(0, qtyMatch.start).trim();
    itemName = _stripLeadingIndex(itemName);
    itemName = _stripTrailingUnitWord(itemName);
    if (itemName.isEmpty) itemName = 'Mục không tên';

    return ScannedItem(name: itemName, unitPrice: unitPrice, quantity: qty);
  }

  /// Handles a simple row shaped like "<name> <price>" or
  /// "<name> xN <price>" — the original inline-shorthand style.
  ScannedItem _parseSimpleRow(
    String line,
    RegExpMatch lastMatch,
    double amount,
  ) {
    final beforePrice = line.substring(0, lastMatch.start).trim();

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

    return ScannedItem(
      name: itemName,
      unitPrice: amount / quantity,
      quantity: quantity,
    );
  }

  static const _genericHeaderKeywords = [
    'hoa don',
    'phieu thu',
    'bien lai',
    'invoice',
    'receipt',
  ];

  /// Picks a title for the expense: the first line that reads like a
  /// business/vendor name (short, no digits, not a generic invoice header
  /// like "HOÁ ĐƠN THANH TOÁN") — usually the store name printed at the top
  /// of the receipt. Falls back to the trip destination only when nothing
  /// usable was recognized, since a specific vendor name is more useful in
  /// an expense list than a generic trip-wide fallback.
  String _pickTitle(List<String> lines, String? fallbackDescription) {
    for (final line in lines.take(5)) {
      final trimmed = line.trim();
      if (trimmed.length < 3) continue;

      final normalized = _stripDiacritics(trimmed.toLowerCase());
      final looksGeneric =
          _genericHeaderKeywords.any((kw) => normalized.contains(kw));
      final hasDigit = RegExp(r'\d').hasMatch(trimmed);

      if (!looksGeneric && !hasDigit) {
        return trimmed;
      }
    }
    return fallbackDescription ?? lines.first;
  }

  RegExpMatch? _lastStandaloneIntBefore(String line, int beforeIndex) {
    RegExpMatch? best;
    for (final m in _standaloneIntRegex.allMatches(line)) {
      if (m.end > beforeIndex) break;
      best = m;
    }
    return best;
  }

  String _stripLeadingIndex(String name) {
    final m = _leadingIndexRegex.firstMatch(name);
    return m != null ? name.substring(m.end).trim() : name;
  }

  String _stripTrailingUnitWord(String name) {
    final normalized = _stripDiacritics(name.toLowerCase());
    final match = _trailingUnitRegex.firstMatch(normalized);
    if (match == null) return name;
    return name.substring(0, match.start).trim();
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
