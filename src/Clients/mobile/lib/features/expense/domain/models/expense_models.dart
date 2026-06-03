class ExpenseModel {
  final String id;
  final String description;
  final double amount;
  final String currency;
  final double convertedAmount;
  final double exchangeRate;
  final String paidByUserId;
  final int splitType;
  final bool isPaidFromPool;
  final DateTime createdAt;
  final List<SplitModel> splits;

  ExpenseModel({
    required this.id,
    required this.description,
    required this.amount,
    required this.currency,
    required this.convertedAmount,
    required this.exchangeRate,
    required this.paidByUserId,
    required this.splitType,
    required this.isPaidFromPool,
    required this.createdAt,
    required this.splits,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id'] as String? ?? '',
      description: json['description'] as String? ?? '',
      amount: (json['amount'] as num? ?? 0).toDouble(),
      currency: json['currency'] as String? ?? 'VND',
      convertedAmount: (json['convertedAmount'] as num? ?? 0).toDouble(),
      exchangeRate: (json['exchangeRate'] as num? ?? 1.0).toDouble(),
      paidByUserId: json['paidByUserId'] as String? ?? '',
      splitType: json['splitType'] as int? ?? 0,
      isPaidFromPool: json['isPaidFromPool'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      splits: (json['splits'] as List<dynamic>?)
              ?.map((s) => SplitModel.fromJson(s as Map<String, dynamic>))
              .toList() ?? [],
    );
  }
}

class SplitModel {
  final String userId;
  final double amount;
  final bool isPaid;

  SplitModel({
    required this.userId,
    required this.amount,
    required this.isPaid,
  });

  factory SplitModel.fromJson(Map<String, dynamic> json) {
    return SplitModel(
      userId: json['userId'] as String? ?? '',
      amount: (json['amount'] as num? ?? 0).toDouble(),
      isPaid: json['isPaid'] as bool? ?? false,
    );
  }
}

class DebtModel {
  final String debtRecordId;
  final String fromUserId;
  final String toUserId;
  final double amount;
  final String currency;
  final bool isSettled;
  final DateTime? settledAt;

  DebtModel({
    required this.debtRecordId,
    required this.fromUserId,
    required this.toUserId,
    required this.amount,
    required this.currency,
    required this.isSettled,
    this.settledAt,
  });

  factory DebtModel.fromJson(Map<String, dynamic> json) {
    return DebtModel(
      debtRecordId: json['debtRecordId'] as String? ?? '',
      fromUserId: json['fromUserId'] as String? ?? '',
      toUserId: json['toUserId'] as String? ?? '',
      amount: (json['amount'] as num? ?? 0).toDouble(),
      currency: json['currency'] as String? ?? 'VND',
      isSettled: json['isSettled'] as bool? ?? false,
      settledAt: json['settledAt'] != null
          ? DateTime.parse(json['settledAt'] as String)
          : null,
    );
  }
}

class TripBalancesModel {
  final String tripId;
  final List<DebtModel> unsettledDebts;
  final List<DebtModel> settledDebts;

  TripBalancesModel({
    required this.tripId,
    required this.unsettledDebts,
    required this.settledDebts,
  });

  factory TripBalancesModel.fromJson(Map<String, dynamic> json) {
    return TripBalancesModel(
      tripId: json['tripId'] as String? ?? '',
      unsettledDebts: (json['unsettledDebts'] as List<dynamic>?)
              ?.map((d) => DebtModel.fromJson(d as Map<String, dynamic>))
              .toList() ?? [],
      settledDebts: (json['settledDebts'] as List<dynamic>?)
              ?.map((d) => DebtModel.fromJson(d as Map<String, dynamic>))
              .toList() ?? [],
    );
  }
}

class TripPoolModel {
  final String poolId;
  final double balance;
  final String currency;
  final List<PoolContributionModel> contributions;

  TripPoolModel({
    required this.poolId,
    required this.balance,
    required this.currency,
    required this.contributions,
  });

  factory TripPoolModel.fromJson(Map<String, dynamic> json) {
    return TripPoolModel(
      poolId: json['poolId'] as String? ?? '',
      balance: (json['balance'] as num? ?? 0).toDouble(),
      currency: json['currency'] as String? ?? 'VND',
      contributions: (json['contributions'] as List<dynamic>?)
              ?.map((c) => PoolContributionModel.fromJson(c as Map<String, dynamic>))
              .toList() ?? [],
    );
  }
}

class PoolContributionModel {
  final String userId;
  final double amount;
  final DateTime contributedAt;

  PoolContributionModel({
    required this.userId,
    required this.amount,
    required this.contributedAt,
  });

  factory PoolContributionModel.fromJson(Map<String, dynamic> json) {
    return PoolContributionModel(
      userId: json['userId'] as String? ?? '',
      amount: (json['amount'] as num? ?? 0).toDouble(),
      contributedAt: json['contributedAt'] != null
          ? DateTime.parse(json['contributedAt'] as String)
          : DateTime.now(),
    );
  }
}
