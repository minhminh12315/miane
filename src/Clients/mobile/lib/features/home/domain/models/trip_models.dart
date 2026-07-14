import 'dart:convert';

enum TripTimelineStatus {
  upcoming,
  ongoing,
  completed,
}

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

  TripTimelineStatus get timelineStatus =>
      _resolveTripTimelineStatus(status, startDate, endDate);

  String get timelineStatusLabel => _timelineStatusLabel(timelineStatus);

  bool get isCompletedByDate => timelineStatus == TripTimelineStatus.completed;
}

class TripPlaceData {
  final String? placeId;
  final String name;
  final String? formattedAddress;
  final double? latitude;
  final double? longitude;
  final String? country;
  final String? city;
  final String? province;
  final List<String> types;
  final Map<String, dynamic>? viewport;

  const TripPlaceData({
    required this.name,
    this.placeId,
    this.formattedAddress,
    this.latitude,
    this.longitude,
    this.country,
    this.city,
    this.province,
    this.types = const [],
    this.viewport,
  });

  String get displayName {
    final address = formattedAddress?.trim();
    if (address != null && address.isNotEmpty) return address;

    final pieces = [
      name,
      if ((province ?? '').isNotEmpty && province != city) province,
      if ((country ?? '').isNotEmpty) country,
    ].whereType<String>().where((part) => part.trim().isNotEmpty).toList();

    return pieces.join(', ');
  }

  String get destinationCity => (city ?? '').trim().isNotEmpty ? city! : name;

  Map<String, dynamic> toMetadataJson() {
    return {
      'placeId': placeId,
      'name': name,
      'formattedAddress': formattedAddress,
      'latitude': latitude,
      'longitude': longitude,
      'country': country,
      'city': city,
      'province': province,
      'types': types,
      'viewport': viewport,
    }..removeWhere(
        (_, value) => value == null || value is String && value.trim().isEmpty);
  }
}

class TripCreationDraft {
  final String name;
  final TripPlaceData place;
  final String? description;
  final String baseCurrency;
  final DateTime startDate;
  final DateTime endDate;
  final String? coverImageUrl;
  final String? coverImagePrompt;
  final String? coverImageLandmark;

  const TripCreationDraft({
    required this.name,
    required this.place,
    required this.startDate,
    required this.endDate,
    this.description,
    this.baseCurrency = 'VND',
    this.coverImageUrl,
    this.coverImagePrompt,
    this.coverImageLandmark,
  });

  int get durationDays => endDate.difference(startDate).inDays + 1;

  String get compactDescription {
    final pieces = [
      place.displayName,
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
      'destination': place.name,
      'destinationCity': place.destinationCity,
      'destinationProvince': place.province,
      'destinationCountry': place.country,
      'formattedAddress': place.formattedAddress,
      'placeId': place.placeId,
      'placeTypes': place.types,
      'placeMetadataJson': jsonEncode(place.toMetadataJson()),
      'startDate': _asUtcDate(startDate).toIso8601String(),
      'endDate': _asUtcDate(endDate).toIso8601String(),
      'coverImageUrl': coverImageUrl,
      'coverImagePrompt': coverImagePrompt,
      'coverImageLandmark': coverImageLandmark,
      'latitude': place.latitude,
      'longitude': place.longitude,
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

  String get displayRoleName {
    final normalized = (roleName ?? '').trim().toLowerCase();
    switch (normalized) {
      case 'owner':
        return 'Chủ chuyến đi';
      case 'admin':
        return 'Quản trị viên';
      case 'finance':
        return 'Phụ trách chi phí';
      case 'planner':
        return 'Phụ trách lịch trình';
      case 'photographer':
        return 'Phụ trách ảnh';
      case 'member':
        return 'Thành viên';
    }

    if (role == 0) return 'Chủ chuyến đi';
    if (role == 1) return 'Quản trị viên';
    return 'Thành viên';
  }
}

class TripFileModel {
  final String id;
  final String tripId;
  final String folder;
  final String fileName;
  final String fileUrl;
  final String? contentType;
  final int? fileSizeBytes;
  final String uploadedByUserId;
  final List<String> tags;
  final DateTime createdAt;

  const TripFileModel({
    required this.id,
    required this.tripId,
    required this.folder,
    required this.fileName,
    required this.fileUrl,
    this.contentType,
    this.fileSizeBytes,
    required this.uploadedByUserId,
    this.tags = const [],
    required this.createdAt,
  });

  factory TripFileModel.fromJson(Map<String, dynamic> json) {
    return TripFileModel(
      id: (json['id'] ?? '').toString(),
      tripId: (json['tripId'] ?? '').toString(),
      folder: (json['folder'] ?? 'Chung').toString(),
      fileName: (json['fileName'] ?? '').toString(),
      fileUrl: (json['fileUrl'] ?? '').toString(),
      contentType: json['contentType'] as String?,
      fileSizeBytes: (json['fileSizeBytes'] as num?)?.toInt(),
      uploadedByUserId: (json['uploadedByUserId'] ?? '').toString(),
      tags: _stringList(json['tags']),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  String get displayFolder {
    final value = folder.trim();
    if (value.isEmpty || value == 'General') return 'Chung';
    return value;
  }

  String get extension {
    final parts = fileName.split('.');
    if (parts.length < 2) return '';
    return parts.last.toUpperCase();
  }
}

class TripFileDraft {
  final String fileName;
  final String fileUrl;
  final String folder;
  final String? contentType;
  final int? fileSizeBytes;
  final List<String> tags;

  const TripFileDraft({
    required this.fileName,
    required this.fileUrl,
    this.folder = 'Chung',
    this.contentType,
    this.fileSizeBytes,
    this.tags = const [],
  });

  Map<String, dynamic> toApiJson() {
    return {
      'fileName': fileName,
      'fileUrl': fileUrl,
      'folder': folder,
      'contentType': contentType,
      'fileSizeBytes': fileSizeBytes,
      'tags': tags,
    }..removeWhere((_, value) => value == null);
  }
}

class TripLocalFileDraft {
  final String? filePath;
  final List<int>? fileBytes;
  final String fileName;
  final String folder;
  final List<String> tags;

  const TripLocalFileDraft({
    this.filePath,
    this.fileBytes,
    required this.fileName,
    this.folder = 'Chung',
    this.tags = const [],
  });
}

class TripNoteDraft {
  final String title;
  final String content;
  final String folder;
  final List<String> tags;

  const TripNoteDraft({
    required this.title,
    required this.content,
    this.folder = 'Ghi chú',
    this.tags = const [],
  });

  Map<String, dynamic> toApiJson() {
    return {
      'title': title,
      'content': content,
      'folder': folder,
      'tags': tags,
    };
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

  TripTimelineStatus get timelineStatus =>
      _resolveTripTimelineStatus(status, startDate, endDate);

  String get timelineStatusLabel => _timelineStatusLabel(timelineStatus);

  bool get isCompletedByDate => timelineStatus == TripTimelineStatus.completed;
}

List<String> _stringList(dynamic value) {
  if (value is! List) return const [];
  return value
      .map((item) => item.toString().trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}

TripTimelineStatus _resolveTripTimelineStatus(
  int rawStatus,
  DateTime? startDate,
  DateTime? endDate,
) {
  if (rawStatus != 0) return TripTimelineStatus.completed;

  final today = _dateOnly(DateTime.now());
  final start = startDate == null ? null : _dateOnly(startDate);
  final end = endDate == null ? null : _dateOnly(endDate);

  if (end != null && end.isBefore(today)) return TripTimelineStatus.completed;
  if (start != null && start.isAfter(today)) return TripTimelineStatus.upcoming;
  return TripTimelineStatus.ongoing;
}

String _timelineStatusLabel(TripTimelineStatus status) {
  return switch (status) {
    TripTimelineStatus.upcoming => 'Sắp diễn ra',
    TripTimelineStatus.ongoing => 'Đang diễn ra',
    TripTimelineStatus.completed => 'Đã đi',
  };
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);
