import '../models/scan_bill_result.dart';

class _TransferAmountCandidate {
  final double value;
  final int score;

  const _TransferAmountCandidate(this.value, this.score);
}

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

  /// Any monetary-looking number: dot/comma-thousands ("1.250.000" or
  /// "8,700,000"), "K" shorthand ("45K"), or a bare 4+ digit run. Matched
  /// anywhere on the line (not just at the end), since a tabular row can
  /// have several — quantity, unit price, and total — trailing after the
  /// item name.
  static final _moneyTokenRegex = RegExp(
    r'\d{1,3}(?:[.,]\d{3})+|\d+[kK]|\d{4,}',
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
    'gia tri giao dich',
    'tong tien',
    'tong cong',
    'amount',
  ];

  static const _transferSuccessKeywords = [
    'chuyen khoan thanh cong',
    'giao dich thanh cong',
    'thanh toan thanh cong',
    'transaction successful',
    'successful transfer',
  ];

  static const _transferIdentifierKeywords = [
    'tai khoan',
    'so tai khoan',
    'account number',
    'account no',
    'ma giao dich',
    'chi tiet giao dich',
    'transaction id',
    'transaction code',
    'ma tham chieu',
    'so tham chieu',
    'reference no',
    'reference id',
    'so dien thoai',
    'dien thoai',
    'sdt',
    'phone',
    'mobile',
  ];

  static const _transferNonAmountKeywords = [
    'thoi gian',
    'ngay giao dich',
    'ngay thanh toan',
    'date',
    'time',
    'phi giao dich',
    'phi chuyen tien',
    'fee',
  ];

  static const _transferContentKeywords = [
    'noi dung chuyen khoan',
    'noi dung',
    'loi nhan',
    'dien giai',
    'tin nhan',
    'message',
    'content',
    'description',
  ];

  static const _transferRecipientKeywords = [
    'ten nguoi thu huong',
    'nguoi thu huong',
    'nguoi nhan',
    'beneficiary',
    'recipient',
    'den',
  ];

  static const _transferFieldKeywords = [
    ..._transferAmountKeywords,
    ..._transferContentKeywords,
    ..._transferRecipientKeywords,
    ..._transferIdentifierKeywords,
    ..._transferNonAmountKeywords,
    'ngan hang',
    'ten danh ba',
    'nguoi gui',
    'loai giao dich',
  ];

  static final _vndMarkerRegex = RegExp(
    r'(?:\bVND\b|VNĐ|₫|đ(?:\b|$)|\bdong\b)',
    caseSensitive: false,
  );

  /// Parses a bank-transfer slip (biên lai chuyển khoản) rather than an
  /// itemized bill. A transfer has a single amount and a free-text content
  /// line instead of line items, so this produces a one-item [ScanBillResult]:
  ///   - amount: the best money candidate based on labels/currency/context;
  ///     account numbers, transaction IDs, phone numbers, dates and fees are
  ///     explicitly excluded
  ///   - description: transfer content, then recipient, then fallback
  ScanBillResult parseTransferSlip(List<String> lines,
      {String? fallbackDescription}) {
    final normalized =
        lines.map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

    final currency = _detectCurrency(normalized) ?? 'VND';

    final amount = _findTransferAmount(normalized);

    final content = _extractTransferField(normalized, _transferContentKeywords);
    final recipient =
        _extractTransferField(normalized, _transferRecipientKeywords);
    final description = content ??
        (recipient == null ? null : 'Chuyển khoản đến $recipient') ??
        fallbackDescription ??
        'Chuyển khoản';

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

  double _findTransferAmount(List<String> lines) {
    _TransferAmountCandidate? best;

    for (var lineIndex = 0; lineIndex < lines.length; lineIndex++) {
      final line = lines[lineIndex];
      final key = _stripDiacritics(line.toLowerCase());
      final previousKey = lineIndex == 0
          ? ''
          : _stripDiacritics(lines[lineIndex - 1].toLowerCase());

      final isIdentifierContext =
          _containsAny(key, _transferIdentifierKeywords) ||
              _containsAny(previousKey, _transferIdentifierKeywords);
      final isNonAmountContext =
          _containsAny(key, _transferNonAmountKeywords) ||
              _containsAny(previousKey, _transferNonAmountKeywords);
      if (isIdentifierContext || isNonAmountContext) continue;

      final hasAmountLabel = _containsAny(key, _transferAmountKeywords);
      final followsAmountLabel =
          _containsAny(previousKey, _transferAmountKeywords);
      final hasCurrency = _vndMarkerRegex.hasMatch(line);
      final followsSuccess =
          _containsAny(previousKey, _transferSuccessKeywords);
      final isSuccessLine = _containsAny(key, _transferSuccessKeywords);

      for (final match in _moneyTokenRegex.allMatches(line)) {
        final token = match.group(0)!;
        final value = _parseAmount(token);
        if (value == null || value <= 0) continue;

        final grouped = token.contains('.') || token.contains(',');
        final isKNotation = token.endsWith('k') || token.endsWith('K');
        final digitCount = token.replaceAll(RegExp(r'[^0-9]'), '').length;

        // Long, unformatted numbers without a currency/amount label are
        // overwhelmingly account numbers, transaction IDs or phone numbers.
        if (digitCount >= 9 &&
            !grouped &&
            !isKNotation &&
            !hasCurrency &&
            !hasAmountLabel &&
            !followsAmountLabel) {
          continue;
        }

        var score = 0;
        if (hasAmountLabel) score += 120;
        if (followsAmountLabel) score += 110;
        if (hasCurrency) score += 70;
        if (grouped || isKNotation) score += 45;
        if (followsSuccess) score += 35;
        if (isSuccessLine) score += 20;

        final candidate = _TransferAmountCandidate(value, score);
        if (best == null ||
            candidate.score > best.score ||
            (candidate.score == best.score && candidate.value > best.value)) {
          best = candidate;
        }
      }
    }

    return best?.value ?? 0;
  }

  String? _extractTransferField(
    List<String> lines,
    List<String> keywords,
  ) {
    for (var lineIndex = 0; lineIndex < lines.length; lineIndex++) {
      final line = lines[lineIndex];
      final key = _stripDiacritics(line.toLowerCase());
      final keyword = keywords.firstWhere(
        (candidate) => key.contains(candidate),
        orElse: () => '',
      );
      if (keyword.isEmpty) continue;

      final keywordEnd = key.indexOf(keyword) + keyword.length;
      final sameLineValue = _cleanTransferFieldValue(
        line.substring(keywordEnd),
      );
      if (_isMeaningfulTransferFieldValue(sameLineValue)) {
        return sameLineValue;
      }

      // Vision commonly recognizes a label and its right-hand value as two
      // consecutive rows. Only inspect the immediate next row so that an
      // empty "Tin nhắn" field cannot consume unrelated footer text.
      if (lineIndex + 1 < lines.length) {
        final nextLine = lines[lineIndex + 1];
        final nextKey = _stripDiacritics(nextLine.toLowerCase());
        final nextIsAnotherField =
            _containsAny(nextKey, _transferFieldKeywords);
        final nextValue = _cleanTransferFieldValue(nextLine);
        if (!nextIsAnotherField && _isMeaningfulTransferFieldValue(nextValue)) {
          return nextValue;
        }
      }
    }
    return null;
  }

  String _cleanTransferFieldValue(String value) {
    return value.replaceFirst(RegExp(r'^[\s:–—-]+'), '').trim();
  }

  bool _isMeaningfulTransferFieldValue(String value) {
    if (value.length < 2) return false;
    if (!RegExp(r'[A-Za-zÀ-ỹ0-9]').hasMatch(value)) return false;

    final normalized = _stripDiacritics(value.toLowerCase()).trim();
    return normalized != 'khong co' &&
        normalized != 'none' &&
        normalized != 'n/a';
  }

  bool _containsAny(String value, List<String> keywords) {
    return keywords.any(value.contains);
  }

  ScanBillResult parse(List<String> lines, {String? fallbackDescription}) {
    final normalized =
        lines.map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

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
