class UpdateInfo {
  final String latestVersion;
  final String minVersion;
  final bool forceUpdate;
  final String fileName;
  final String sha256;
  final String changelog;

  const UpdateInfo({
    required this.latestVersion,
    required this.minVersion,
    required this.forceUpdate,
    required this.fileName,
    required this.sha256,
    required this.changelog,
  });

  factory UpdateInfo.fromApi(Map<String, dynamic> json) {
    return UpdateInfo(
      latestVersion: (json['latestVersion'] ?? '').toString(),
      minVersion: (json['minVersion'] ?? '0.0.0').toString(),
      forceUpdate: json['forceUpdate'] == true,
      fileName: (json['fileName'] ?? 'app-release.apk').toString(),
      sha256: (json['sha256'] ?? '').toString(),
      changelog: (json['changelog'] ?? '').toString(),
    );
  }
}
