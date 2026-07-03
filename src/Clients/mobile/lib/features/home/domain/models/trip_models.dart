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
  final String? destinationCity;
  final String? destinationCountry;
  final double? latitude;
  final double? longitude;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? coverImageUrl;
  final String? shareUrl;

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
    this.destinationCity,
    this.destinationCountry,
    this.latitude,
    this.longitude,
    this.startDate,
    this.endDate,
    this.coverImageUrl,
    this.shareUrl,
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
      destinationCity: json['destinationCity'] as String?,
      destinationCountry: json['destinationCountry'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate'] as String)
          : null,
      endDate: json['endDate'] != null
          ? DateTime.tryParse(json['endDate'] as String)
          : null,
      coverImageUrl: json['coverImageUrl'] as String?,
      shareUrl: json['shareUrl'] as String?,
    );
  }

  String get destinationLabel {
    if ((destinationCity ?? '').isNotEmpty &&
        (destinationCountry ?? '').isNotEmpty) {
      return '$destinationCity, $destinationCountry';
    }
    if ((destinationCity ?? '').isNotEmpty) return destinationCity!;
    if ((destinationCountry ?? '').isNotEmpty) return destinationCountry!;
    return description ?? 'Chưa có điểm đến';
  }

  int? get durationDays {
    if (startDate == null || endDate == null) return null;
    return endDate!.difference(startDate!).inDays + 1;
  }
}

class TripCreationDraft {
  final String name;
  final String destinationText;
  final String? description;
  final String baseCurrency;
  final DateTime startDate;
  final DateTime endDate;
  final String? coverImageUrl;
  final double? latitude;
  final double? longitude;

  const TripCreationDraft({
    required this.name,
    required this.destinationText,
    required this.startDate,
    required this.endDate,
    this.description,
    this.baseCurrency = 'VND',
    this.coverImageUrl,
    this.latitude,
    this.longitude,
  });

  int get durationDays => endDate.difference(startDate).inDays + 1;

  String get compactDescription {
    final pieces = [
      destinationText,
      if ((description ?? '').trim().isNotEmpty) description!.trim(),
      '${_formatDate(startDate)} - ${_formatDate(endDate)}',
      '$durationDays ngày',
    ];
    return pieces.join(' • ');
  }

  Map<String, dynamic> toApiJson() {
    return {
      'name': name,
      'description': compactDescription,
      'baseCurrency': baseCurrency,
      'destination': destinationText,
      'destinationCity': destinationText,
      'startDate': _asUtcDate(startDate).toIso8601String(),
      'endDate': _asUtcDate(endDate).toIso8601String(),
      'coverImageUrl': coverImageUrl,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  static String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  static DateTime _asUtcDate(DateTime date) =>
      DateTime.utc(date.year, date.month, date.day);
}

class TripCreationResult {
  final String tripId;
  final String inviteCode;
  final String shareUrl;

  const TripCreationResult({
    required this.tripId,
    required this.inviteCode,
    required this.shareUrl,
  });

  factory TripCreationResult.fromJson(Map<String, dynamic> json) {
    final tripId = (json['tripId'] ?? json['id'] ?? '').toString();
    final inviteCode = (json['inviteCode'] ?? json['code'] ?? '').toString();
    return TripCreationResult(
      tripId: tripId,
      inviteCode: inviteCode,
      shareUrl:
          (json['shareUrl'] ?? 'https://miane.app/trip/$inviteCode').toString(),
    );
  }
}

class TripMemberModel {
  final String userId;
  final int role;
  final String? roleName;
  final String? nickName;
  final int userTier;
  final DateTime joinedAt;

  TripMemberModel({
    required this.userId,
    required this.role,
    this.roleName,
    this.nickName,
    required this.userTier,
    required this.joinedAt,
  });

  factory TripMemberModel.fromJson(Map<String, dynamic> json) {
    return TripMemberModel(
      userId: json['userId'] as String? ?? '',
      role: json['role'] as int? ?? 1,
      roleName: json['roleName'] as String?,
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
  final String? destinationCity;
  final String? destinationCountry;
  final double? latitude;
  final double? longitude;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? coverImageUrl;
  final String? shareUrl;
  final DateTime createdAt;
  final List<TripMemberModel> members;

  TripDetailModel({
    required this.id,
    required this.name,
    this.description,
    required this.inviteCode,
    required this.baseCurrency,
    required this.status,
    this.destinationCity,
    this.destinationCountry,
    this.latitude,
    this.longitude,
    this.startDate,
    this.endDate,
    this.coverImageUrl,
    this.shareUrl,
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
      destinationCity: json['destinationCity'] as String?,
      destinationCountry: json['destinationCountry'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate'] as String)
          : null,
      endDate: json['endDate'] != null
          ? DateTime.tryParse(json['endDate'] as String)
          : null,
      coverImageUrl: json['coverImageUrl'] as String?,
      shareUrl: json['shareUrl'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      members: (json['members'] as List<dynamic>?)
              ?.map((m) => TripMemberModel.fromJson(m as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  String get destinationLabel {
    if ((destinationCity ?? '').isNotEmpty &&
        (destinationCountry ?? '').isNotEmpty) {
      return '$destinationCity, $destinationCountry';
    }
    if ((destinationCity ?? '').isNotEmpty) return destinationCity!;
    if ((destinationCountry ?? '').isNotEmpty) return destinationCountry!;
    return description ?? 'Chưa có điểm đến';
  }

  int? get durationDays {
    if (startDate == null || endDate == null) return null;
    return endDate!.difference(startDate!).inDays + 1;
  }
}
