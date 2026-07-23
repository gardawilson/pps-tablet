/// User master data untuk fitur kelola akses lokasi (assign/revoke).
class SoV2AccessUser {
  final int idUsername;
  final String username;
  final String fName;
  final String? lName;
  final bool isOnline;

  SoV2AccessUser({
    required this.idUsername,
    required this.username,
    required this.fName,
    this.lName,
    this.isOnline = false,
  });

  String get fullName =>
      [fName, lName].where((s) => s != null && s.trim().isNotEmpty).join(' ');

  factory SoV2AccessUser.fromJson(Map<String, dynamic> json) {
    return SoV2AccessUser(
      idUsername: (json['IdUsername'] as num?)?.toInt() ?? 0,
      username: json['Username']?.toString() ?? '',
      fName: json['FName']?.toString() ?? '',
      lName: json['LName']?.toString(),
      isOnline: json['Status']?.toString().toUpperCase() == 'ONLINE',
    );
  }
}
