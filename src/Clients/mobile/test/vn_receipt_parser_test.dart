import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/expense/domain/services/vn_receipt_parser.dart';

void main() {
  final parser = VnReceiptParser();

  test('printed thermal receipt with simple items', () {
    final result = parser.parse([
      'CAFE HIGHLAND',
      '12 Nguyễn Huệ, Q1',
      'Cà phê sữa đá 29.000',
      'Bánh mì que 15.000',
      'Tổng cộng 44.000',
    ]);

    expect(result.items.length, 2);
    expect(result.items[0].name, contains('Cà phê sữa đá'));
    expect(result.items[0].amount, 29000);
    expect(result.items[1].amount, 15000);
    expect(result.totalAmount, 44000);
    expect(result.hasDiscrepancy, isFalse);
    expect(result.currency, 'VND');
  });

  test('handwritten style bill with "x" multiplier', () {
    final result = parser.parse([
      'Quán nhậu Ba Lu',
      'Bò lúc lắc x2 90.000',
      'Rau muống xào tỏi x1 35.000',
      'Bia Hà Nội x3 60.000',
      'Tổng thanh toán 185.000',
    ]);

    expect(result.items.length, 3);
    final bo = result.items.firstWhere((i) => i.name.contains('Bò lúc lắc'));
    expect(bo.quantity, 2);
    expect(bo.unitPrice, 45000);
    expect(result.totalAmount, 185000);
  });

  test('K shorthand notation', () {
    final result = parser.parse([
      'Bún chả Hà Nội 45K',
      'Nem cua bể 35K',
      'Tổng cộng 80K',
    ]);

    expect(result.items.length, 2);
    expect(result.items[0].amount, 45000);
    expect(result.items[1].amount, 35000);
    expect(result.totalAmount, 80000);
  });

  test('long itemized seafood receipt', () {
    final result = parser.parse([
      'Nhà hàng hải sản Lan Hạ',
      'Tôm sú nướng 250.000',
      'Cua hoàng đế 850.000',
      'Sò điệp x5 150.000',
      'Ghẹ hấp bia 220.000',
      'Mực nướng 180.000',
      'Tổng cộng 1.650.000',
    ]);

    expect(result.items.length, 5);
    expect(result.totalAmount, 1650000);
  });

  test('VAT and service charge lines are excluded from items', () {
    final result = parser.parse([
      'Nhà hàng ABC',
      'Phở bò tái chín 65.000',
      'VAT 10% 6.500',
      'Phí phục vụ 5% 3.250',
      'Tổng thanh toán 74.750',
    ]);

    expect(result.items.length, 1);
    expect(result.items[0].name, contains('Phở bò tái chín'));
    expect(result.totalAmount, 74750);
  });

  test('bilingual receipt still extracts items', () {
    final result = parser.parse([
      'Tourist Restaurant',
      'Fried rice / Cơm chiên 80.000',
      'Iced tea / Trà đá 10.000',
      'Total 90.000',
    ]);

    expect(result.items.length, 2);
    expect(result.totalAmount, 90000);
  });

  test('discrepancy flag triggers when total does not reconcile', () {
    final result = parser.parse([
      'Quán ăn',
      'Cơm gà 40.000',
      'Tổng cộng 100.000',
    ]);

    expect(result.hasDiscrepancy, isTrue);
  });

  test('low-quality OCR output with no readable prices returns empty items', () {
    final result = parser.parse([
      'a;lskdjf',
      '###',
      '',
    ]);

    expect(result.items, isEmpty);
    expect(result.totalAmount, 0);
  });

  test('no items but total line present uses total only', () {
    final result = parser.parse([
      'Khách sạn Sunrise',
      'Tổng cộng 1.200.000',
    ]);

    expect(result.items, isEmpty);
    expect(result.totalAmount, 1200000);
  });

  test('tabular pharmacy invoice with STT/ĐVT/Số lượng/Đơn giá columns', () {
    // Reconstructed rows as ReceiptTextRecognizer would emit them after
    // bbox-based row-merging of Vision's per-cell observations.
    final result = parser.parse([
      'NHÀ THUỐC BỆNH VIỆN ĐK HẢI DƯƠNG',
      'Địa chỉ: 225 Nguyễn Lương Bằng Điện thoại: 02203895269',
      'HOÁ ĐƠN THANH TOÁN',
      'Ngày 18 tháng 10 năm 2023 Số CT:',
      'Bệnh nhân: TRẦN Điện thoại:',
      'Bác sĩ kê đơn: Vũ Thị Nghinh - TTTM NV bán hàng: DS Hoàng Thị Thu Trang',
      'ST Tên mặt hàng/Dịch vụ ĐVT Số lượng Đơn giá Thành tiền',
      '1 Bestimac Q10 30mg (H/60v) viên 30 4.950 148.500',
      '2 Devodil 50mg (Hộp 2 vỉ x 10 viên) 2018 viên 60 2.860 171.600',
      'Tổng tiền : 320.100',
      'Viết bằng chữ: Ba trăm hai mươi nghìn một trăm đồng',
      'Người bán (Ký, họ tên)',
      'DS Hoàng Thị Thu Trang',
    ], fallbackDescription: 'Phú Quốc, Việt Nam');

    expect(result.description, 'NHÀ THUỐC BỆNH VIỆN ĐK HẢI DƯƠNG');
    expect(result.items.length, 2);

    final bestimac = result.items.firstWhere((i) => i.name.contains('Bestimac'));
    expect(bestimac.quantity, 30);
    expect(bestimac.unitPrice, 4950);
    expect(bestimac.amount, 148500);

    final devodil = result.items.firstWhere((i) => i.name.contains('Devodil'));
    expect(devodil.quantity, 60);
    expect(devodil.unitPrice, 2860);
    expect(devodil.amount, 171600);

    expect(result.totalAmount, 320100);
    expect(result.hasDiscrepancy, isFalse);
  });

  test('bank transfer slip: amount + content extraction', () {
    final result = parser.parseTransferSlip([
      'Vietcombank',
      'Chuyển khoản thành công',
      'Số tiền: 500.000 VND',
      'Đến: NGUYEN VAN A',
      'Nội dung: An toi Da Nang',
      'Mã giao dịch: FT2023101812345',
    ], fallbackDescription: 'Đà Nẵng');

    expect(result.items.length, 1);
    expect(result.totalAmount, 500000);
    expect(result.items[0].unitPrice, 500000);
    expect(result.description, 'An toi Da Nang');
    expect(result.currency, 'VND');
  });

  test('bank transfer slip: falls back to largest amount + fallback desc', () {
    final result = parser.parseTransferSlip([
      'MB Bank',
      'Giao dich thanh cong',
      '1.200.000',
      'Phi: 0',
    ], fallbackDescription: 'Chuyến Sa Pa');

    expect(result.totalAmount, 1200000);
    expect(result.description, 'Chuyến Sa Pa');
  });

  test('foreign currency detection', () {
    final result = parser.parse([
      'Bangkok Street Food',
      'Pad Thai 120',
      'Total 120 THB',
    ]);

    expect(result.currency, 'THB');
  });
}
