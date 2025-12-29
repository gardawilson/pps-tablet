import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/network/api_update_constant.dart';
import '../model/update_model.dart';

class UpdateViewModel {
  // ========= CONFIG =========
  /// ✅ bedakan channel/app
  String get _appId => UpdateConstants.appId;

  late final Dio _dio;

  UpdateViewModel({Dio? dio}) {
    _dio = dio ??
        Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(minutes: 15),
          sendTimeout: const Duration(seconds: 30),
          // jangan set responseType json globally
          validateStatus: (code) => code != null && code >= 200 && code < 400,
        ));

    // ✅ Interceptor log
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        print('➡️ [DIO][$_appId] ${options.method} ${options.uri}');
        print('➡️ [DIO][$_appId] headers: ${options.headers}');
        handler.next(options);
      },
      onResponse: (response, handler) {
        print('⬅️ [DIO][$_appId] status: ${response.statusCode} ${response.requestOptions.uri}');
        print('⬅️ [DIO][$_appId] headers: ${response.headers.map}');
        handler.next(response);
      },
      onError: (e, handler) {
        print('🧨 [DIO][$_appId] ERROR: ${e.type} ${e.requestOptions.uri}');
        print('🧨 [DIO][$_appId] message: ${e.message}');
        if (e.response != null) {
          print('🧨 [DIO][$_appId] status: ${e.response?.statusCode}');
          print('🧨 [DIO][$_appId] headers: ${e.response?.headers.map}');
          print('🧨 [DIO][$_appId] response.data: ${e.response?.data}');
        }
        handler.next(e);
      },
    ));
  }

  // =============================
  // CHECK UPDATE
  // =============================
  Future<UpdateInfo?> checkForUpdate() async {
    try {
      final resp = await _dio.get(
        UpdateConstants.versionUrl,
        options: Options(responseType: ResponseType.json),
      );

      final body = resp.data;
      if (body is! Map) throw Exception('Invalid response shape: ${body.runtimeType}');
      if (body['success'] != true) {
        throw Exception((body['message'] ?? 'Unknown error').toString());
      }

      final data = Map<String, dynamic>.from(body['data'] ?? {});
      final info = UpdateInfo.fromApi(data);

      final packageInfo = await PackageInfo.fromPlatform();
      final localVersion = packageInfo.version;

      print('ℹ️ [UPDATE][$_appId] local=$localVersion latest=${info.latestVersion} file=${info.fileName}');

      // sudah terbaru
      if (_compareVersions(localVersion, info.latestVersion) >= 0) {
        print("✅ [UPDATE][$_appId] Sudah versi terbaru ($localVersion)");
        return null;
      }

      return info;
    } on DioException catch (e) {
      print('❌ [UPDATE][$_appId] check DioException: ${e.type} - ${e.message}');

      String errorMsg;
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        errorMsg = 'Koneksi ke server update timeout. Pastikan jaringan aktif.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMsg = 'Tidak dapat terhubung ke server update. Periksa koneksi.';
      } else if (e.response?.statusCode == 404) {
        errorMsg = 'Endpoint update tidak ditemukan. Hubungi administrator.';
      } else {
        errorMsg = 'Gagal memeriksa update: ${e.message}';
      }

      throw Exception(errorMsg);
    } catch (e) {
      print('❌ [UPDATE][$_appId] check error: $e');
      throw Exception('Gagal memeriksa update: $e');
    }
  }

  // =============================
  // DOWNLOAD APK
  // =============================
  Future<File?> downloadUpdate(UpdateInfo info, void Function(int) onProgress) async {
    final fileName = info.fileName.trim();
    final url = UpdateConstants.downloadUrl(info.fileName);

    print('⬇️ [UPDATE][$_appId] Start download');
    print('⬇️ [UPDATE][$_appId] url=$url');
    print('⬇️ [UPDATE][$_appId] expectedSha256=${info.sha256}');

    try {
      final dir = await getApplicationSupportDirectory();
      await dir.create(recursive: true);

      final savePath = '${dir.path}/$fileName';
      final localFile = File(savePath);

      // hapus file lama
      if (await localFile.exists()) {
        print('🗑️ [UPDATE][$_appId] delete existing: $savePath');
        try {
          await localFile.delete();
        } catch (_) {}
      }

      // ✅ HEAD dulu (optional)
      try {
        final head = await _dio.head(
          url,
          options: Options(
            responseType: ResponseType.plain,
            headers: {'Accept': 'application/vnd.android.package-archive'},
          ),
        );
        print('🔎 [UPDATE][$_appId] HEAD status=${head.statusCode}');
        print('🔎 [UPDATE][$_appId] HEAD content-type=${head.headers.value('content-type')}');
        print('🔎 [UPDATE][$_appId] HEAD content-length=${head.headers.value('content-length')}');
      } catch (e) {
        print('⚠️ [UPDATE][$_appId] HEAD failed (not fatal): $e');
      }

      int lastPct = -1;
      int lastReceived = 0;

      await _dio.download(
        url,
        savePath,
        deleteOnError: true,
        options: Options(
          responseType: ResponseType.stream,
          followRedirects: true,
          receiveTimeout: const Duration(minutes: 15),
          headers: {'Accept': 'application/vnd.android.package-archive'},
        ),
        onReceiveProgress: (received, total) {
          // log per ~512KB
          if (received % (512 * 1024) < 8192 || (total > 0 && received == total)) {
            print('⬇️ [UPDATE][$_appId] progress: received=$received total=$total');
          }

          if (total > 0) {
            final pct = (received / total * 100).clamp(0, 100).toInt();
            if (pct != lastPct) {
              lastPct = pct;
              onProgress(pct);
              print('⬇️ [UPDATE][$_appId] progress=$pct% ($received/$total)');
            }
          } else {
            // fallback
            const estimatedSize = 50 * 1024 * 1024; // 50MB
            final estimatedPct = (received / estimatedSize * 100).clamp(0, 99).toInt();

            if ((received - lastReceived) > 1024 * 1024) {
              lastReceived = received;
              onProgress(estimatedPct);
              print('⬇️ [UPDATE][$_appId] estimated=$estimatedPct% (received=$received total=unknown)');
            }
          }
        },
      );

      final exists = await localFile.exists();
      final size = exists ? await localFile.length() : 0;

      print('✅ [UPDATE][$_appId] finished. exists=$exists size=$size path=$savePath');
      onProgress(100);

      // minimal size
      if (!exists || size < 1024 * 1024) {
        final peek = exists ? await _peekFile(localFile) : '<no file>';
        print('🧪 [UPDATE][$_appId] too small. peek=$peek');
        if (exists) await localFile.delete();
        throw Exception('Download invalid/too small. size=$size');
      }

      // magic "PK"
      final magic = await _readMagic2(localFile);
      print('🧪 [UPDATE][$_appId] magic2="$magic" (APK should start with PK)');
      if (magic != 'PK') {
        final peek = await _peekFile(localFile);
        print('🧪 [UPDATE][$_appId] not APK, peek=$peek');
        await localFile.delete();
        throw Exception('Downloaded file is not an APK (magic=$magic)');
      }

      // sha256
      if (info.sha256.trim().isNotEmpty) {
        final ok = await _verifySha256(localFile, info.sha256);
        print('🧾 [UPDATE][$_appId] sha256 ok=$ok');
        if (!ok) {
          await localFile.delete();
          throw Exception('SHA256 mismatch (file corrupt/wrong file)');
        }
      }

      return localFile;
    } on DioException catch (e) {
      print('🧨 [UPDATE][$_appId] DioException type=${e.type}');
      print('🧨 [UPDATE][$_appId] message=${e.message}');
      print('🧨 [UPDATE][$_appId] url=${e.requestOptions.uri}');
      if (e.response != null) {
        print('🧨 [UPDATE][$_appId] status=${e.response?.statusCode}');
        print('🧨 [UPDATE][$_appId] headers=${e.response?.headers.map}');
        print('🧨 [UPDATE][$_appId] data=${e.response?.data}');
      }
      return null;
    } catch (e) {
      print('🧨 [UPDATE][$_appId] Download error: $e');
      return null;
    }
  }

  // =============================
  // HELPERS
  // =============================
  Future<String> _readMagic2(File file) async {
    try {
      final raf = await file.open();
      try {
        final bytes = await raf.read(2);
        return String.fromCharCodes(bytes);
      } finally {
        await raf.close();
      }
    } catch (_) {
      return '';
    }
  }

  Future<String> _peekFile(File file) async {
    try {
      final raf = await file.open();
      try {
        final bytes = await raf.read(200);
        return bytes.map((b) => (b >= 32 && b <= 126) ? String.fromCharCode(b) : '.').join();
      } finally {
        await raf.close();
      }
    } catch (_) {
      return '<peek failed>';
    }
  }

  Future<bool> _verifySha256(File file, String expectedHex) async {
    try {
      final expected = expectedHex.trim().toLowerCase();
      final digest = await sha256.bind(file.openRead()).first;
      final actual = digest.toString().toLowerCase();
      if (actual != expected) {
        print('🧾 [UPDATE][$_appId] sha256 actual=$actual expected=$expected');
      }
      return actual == expected;
    } catch (e) {
      print('🧾 [UPDATE][$_appId] sha256 calc error: $e');
      return false;
    }
  }

  int _compareVersions(String v1, String v2) {
    try {
      final parts1 = v1.split('.').map((p) => int.tryParse(p) ?? 0).toList();
      final parts2 = v2.split('.').map((p) => int.tryParse(p) ?? 0).toList();

      for (int i = 0; i < max(parts1.length, parts2.length); i++) {
        final a = i < parts1.length ? parts1[i] : 0;
        final b = i < parts2.length ? parts2[i] : 0;
        if (a < b) return -1;
        if (a > b) return 1;
      }
      return 0;
    } catch (_) {
      return 0;
    }
  }
}
