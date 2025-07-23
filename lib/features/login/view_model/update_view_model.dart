import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:smb_connect/smb_connect.dart';
import 'package:path_provider/path_provider.dart';
import '../model/update_model.dart';
import 'dart:math';

class UpdateViewModel {
  static const String _sharePath = "gsu/pps_tablet_mobile/update_tablet";

  Future<UpdateInfo?> checkForUpdate() async {
    SmbConnect? connect;
    try {
      connect = await _connectToSmb();

      final versionFile = await connect.file("$_sharePath/version.txt");
      final content = await _readSmbFile(connect, versionFile);

      final lines = content.split('\n').where((line) => line.trim().isNotEmpty).toList();
      if (lines.isEmpty) throw Exception('Invalid version.txt format');

      final remoteVersion = lines[0].trim();
      final packageInfo = await PackageInfo.fromPlatform();
      final localVersion = packageInfo.version;

      // **Tambahkan perbandingan versi**
      if (_compareVersions(localVersion, remoteVersion) >= 0) {
        print("Versi terbaru sudah digunakan ($localVersion)");
        return null; // Tidak ada update jika versi saat ini >= versi dari Notepad
      }

      return UpdateInfo(
        version: remoteVersion,
        fileName: lines.length > 1 ? lines[1].trim() : 'app-release.apk',
        changelog: lines.length > 2 ? lines.sublist(2).join('\n').trim() : '',
      );
    } catch (e) {
      print('Error checking update: $e');
      return null;
    } finally {
      await connect?.close();
    }
  }


  Future<File?> downloadUpdate(String fileName, void Function(int) onProgress) async {
    SmbConnect? connect;
    RandomAccessFile? raf;
    IOSink? fileSink;

    try {
      connect = await _connectToSmb();
      final remoteFile = await connect.file("$_sharePath/$fileName");
      raf = await connect.open(remoteFile);
      final fileSize = await raf.length();

      if (fileSize <= 0) throw Exception('Invalid file size: $fileSize bytes');

      final tempDir = await getTemporaryDirectory();
      final localFile = File('${tempDir.path}/$fileName');
      fileSink = localFile.openWrite();

      // Perbaikan disini - gunakan buffer dengan read()
      const chunkSize = 64 * 1024; // 64KB
      int received = 0;
      final buffer = Uint8List(chunkSize);

      while (received < fileSize) {
        final remaining = fileSize - received;
        final readSize = remaining < chunkSize ? remaining : chunkSize;

        // Baca data ke buffer
        final chunk = await raf.read(readSize); // Perbaikan utama

        fileSink.add(chunk);
        received += chunk.length;
        onProgress((received / fileSize * 100).toInt());
      }

      await fileSink.close();

      if (await localFile.length() != fileSize) {
        await localFile.delete();
        throw Exception('Download incomplete');
      }

      if (!await _validateApk(localFile)) {
        await localFile.delete();
        throw Exception('Invalid APK file');
      }

      return localFile;
    } catch (e) {
      print('Download error: $e');
      return null;
    } finally {
      await raf?.close();
      await fileSink?.close();
      await connect?.close();
    }
  }
  Future<SmbConnect> _connectToSmb() async {
    return await SmbConnect.connectAuth(
      host: "192.168.10.100",
      domain: "",
      username: "rduser5",
      password: "Utama1234",
    );
  }

  Future<String> _readSmbFile(SmbConnect connect, SmbFile file) async {
    final raf = await connect.open(file);
    try {
      final bytes = await raf.read(await raf.length());
      return utf8.decode(bytes).trim();
    } finally {
      await raf.close();
    }
  }

  Future<bool> _validateApk(File file) async {
    try {
      // Minimal size check
      if (await file.length() < 1024 * 1024) return false;

      // Magic number check (APK should start with 'PK')
      final magicNumber = await file.openRead(0, 2).transform(utf8.decoder).first;
      return magicNumber == 'PK';
    } catch (e) {
      return false;
    }
  }

  int _compareVersions(String v1, String v2) {
    try {
      final parts1 = v1.split('.').map((p) => int.tryParse(p) ?? 0).toList();
      final parts2 = v2.split('.').map((p) => int.tryParse(p) ?? 0).toList();

      for (int i = 0; i < max(parts1.length, parts2.length); i++) {
        final part1 = i < parts1.length ? parts1[i] : 0;
        final part2 = i < parts2.length ? parts2[i] : 0;

        if (part1 < part2) return -1;
        if (part1 > part2) return 1;
      }
      return 0;
    } catch (e) {
      print('Version comparison error: $e');
      return 0;
    }
  }
}