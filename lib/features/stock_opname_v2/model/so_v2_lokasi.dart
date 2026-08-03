/// Sentinel blok value untuk label yang tidak memiliki Blok tercatat.
const String kSoV2UnknownBlok = 'TIDAK_DIKETAHUI';

/// Sentinel locationId untuk label yang tidak memiliki lokasi tercatat.
const int kSoV2UnknownLocationId = 0;

/// User yang diizinkan mengakses satu lokasi (dari field `allowedUsers`
/// pada response lokasi).
class SoV2LokasiAllowedUser {
  final int idUsername;
  final String username;
  final String fullName;

  SoV2LokasiAllowedUser({
    required this.idUsername,
    required this.username,
    required this.fullName,
  });

  String get displayName => fullName.isEmpty ? username : fullName;

  factory SoV2LokasiAllowedUser.fromJson(Map<String, dynamic> json) {
    return SoV2LokasiAllowedUser(
      idUsername: (json['idUsername'] as num?)?.toInt() ?? 0,
      username: json['username']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
    );
  }
}

class SoV2Lokasi {
  final int locationId;
  final String description;
  final int labelCount;
  final int scannedCount;
  final double totalWeight;
  final List<SoV2LokasiAllowedUser> allowedUsers;

  SoV2Lokasi({
    required this.locationId,
    required this.description,
    required this.labelCount,
    required this.scannedCount,
    required this.totalWeight,
    this.allowedUsers = const [],
  });

  bool get isUnknown => locationId == kSoV2UnknownLocationId;

  double get progress => labelCount > 0 ? scannedCount / labelCount : 0;

  SoV2Lokasi copyWith({int? scannedCount, double? totalWeight}) {
    return SoV2Lokasi(
      locationId: locationId,
      description: description,
      labelCount: labelCount,
      scannedCount: scannedCount ?? this.scannedCount,
      totalWeight: totalWeight ?? this.totalWeight,
      allowedUsers: allowedUsers,
    );
  }

  factory SoV2Lokasi.fromJson(Map<String, dynamic> json) {
    final allowedUsersList = (json['allowedUsers'] as List?) ?? const [];
    return SoV2Lokasi(
      locationId: (json['locationId'] as num?)?.toInt() ?? 0,
      description: json['description']?.toString() ?? '',
      labelCount: (json['labelCount'] as num?)?.toInt() ?? 0,
      scannedCount: (json['scannedCount'] as num?)?.toInt() ?? 0,
      // Kategori berbasis pcs (mis. furniturewip) mengirim "totalPcs",
      // bukan "totalWeight".
      totalWeight:
          (json['totalWeight'] as num?)?.toDouble() ??
          (json['totalPcs'] as num?)?.toDouble() ??
          0,
      allowedUsers: allowedUsersList
          .map(
            (e) => SoV2LokasiAllowedUser.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
    );
  }
}
