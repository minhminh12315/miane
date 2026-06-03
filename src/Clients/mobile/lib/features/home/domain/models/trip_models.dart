class TripModel {
  final String id;
  final String name;
  final String? description;
  final String inviteCode;
  final String baseCurrency;
  final int status; // 0: Active, etc.
  final int memberCount;
  final int userRole; // 0: Owner, 1: Member
  final DateTime createdAt;

  TripModel({
    required this.id,
    required this.name,
    this.description,
    required this.inviteCode,
    required this.baseCurrency,
    required this.status,
    required this.memberCount,
    required this.userRole,
    required this.createdAt,
  });

  factory TripModel.fromJson(Map<String, dynamic> json) {
    return TripModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      inviteCode: json['inviteCode'] as String? ?? '',
      baseCurrency: json['baseCurrency'] as String? ?? 'VND',
      status: json['status'] as int? ?? 0,
      memberCount: json['memberCount'] as int? ?? 1,
      userRole: json['userRole'] as int? ?? 1,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }
}

class TripMemberModel {
  final String userId;
  final int role;
  final String? nickName;
  final int userTier;
  final DateTime joinedAt;

  TripMemberModel({
    required this.userId,
    required this.role,
    this.nickName,
    required this.userTier,
    required this.joinedAt,
  });

  factory TripMemberModel.fromJson(Map<String, dynamic> json) {
    return TripMemberModel(
      userId: json['userId'] as String? ?? '',
      role: json['role'] as int? ?? 1,
      nickName: json['nickName'] as String?,
      userTier: json['userTier'] as int? ?? 0,
      joinedAt: json['joinedAt'] != null
          ? DateTime.parse(json['joinedAt'] as String)
          : DateTime.now(),
    );
  }
}

class TripDetailModel {
  final String id;
  final String name;
  final String? description;
  final String inviteCode;
  final String baseCurrency;
  final int status;
  final DateTime createdAt;
  final List<TripMemberModel> members;

  TripDetailModel({
    required this.id,
    required this.name,
    this.description,
    required this.inviteCode,
    required this.baseCurrency,
    required this.status,
    required this.createdAt,
    required this.members,
  });

  factory TripDetailModel.fromJson(Map<String, dynamic> json) {
    return TripDetailModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      inviteCode: json['inviteCode'] as String? ?? '',
      baseCurrency: json['baseCurrency'] as String? ?? 'VND',
      status: json['status'] as int? ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      members: (json['members'] as List<dynamic>?)
              ?.map((m) => TripMemberModel.fromJson(m as Map<String, dynamic>))
              .toList() ?? [],
    );
  }
}
