import 'dart:io';
import 'dart:typed_data';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Key untuk SharedPreferences
const _kPrinterMac = 'bt_printer_mac';
const _kPrinterName = 'bt_printer_name';

/// Service untuk print langsung ke thermal printer via classic Bluetooth (SPP)
/// Tidak membutuhkan RawBT atau aplikasi pihak ketiga lainnya.
class BtPrintService {
  BtPrintService({
    required this.baseUrl,
    this.defaultSystem = 'pps',
    this.httpClient,
    this.getAuthHeader,
  });

  final String baseUrl;
  final String defaultSystem;
  final http.Client? httpClient;
  final Map<String, String> Function()? getAuthHeader;

  // =============== URL BUILDER =================

  Uri buildPdfUri({
    required String reportName,
    required Map<String, String> query,
    String? system,
  }) {
    final u = Uri.parse(
      '$baseUrl/api/crystalreport/${system ?? defaultSystem}/export-pdf',
    );
    return u.replace(queryParameters: {'reportName': reportName, ...query});
  }

  // =============== PRINTER PREFERENCE =================

  /// Simpan printer yang dipilih ke SharedPreferences
  static Future<void> savePrinter({
    required String mac,
    required String name,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPrinterMac, mac);
    await prefs.setString(_kPrinterName, name);
    debugPrint('💾 Printer tersimpan: $name ($mac)');
  }

  /// Ambil printer tersimpan. Null jika belum pernah pilih.
  static Future<({String mac, String name})?> loadSavedPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    final mac = prefs.getString(_kPrinterMac);
    final name = prefs.getString(_kPrinterName);
    if (mac == null || mac.isEmpty) return null;
    return (mac: mac, name: name ?? mac);
  }

  /// Hapus printer tersimpan
  static Future<void> clearSavedPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kPrinterMac);
    await prefs.remove(_kPrinterName);
  }

  // =============== PERMISSIONS =================

  /// Request runtime Bluetooth permissions yang diperlukan.
  /// - Android 12+ (API 31+): BLUETOOTH_CONNECT + BLUETOOTH_SCAN
  /// - Android 11 ke bawah  : BLUETOOTH (legacy, biasanya auto-granted)
  ///
  /// Returns true jika semua permission granted, false jika ada yang ditolak.
  static Future<bool> ensurePermissions() async {
    if (!Platform.isAndroid) return true;

    // Android 12+ butuh runtime request untuk BLUETOOTH_CONNECT & BLUETOOTH_SCAN
    final statuses = await [
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
    ].request();

    final connectGranted =
        statuses[Permission.bluetoothConnect]?.isGranted ?? false;
    final scanGranted = statuses[Permission.bluetoothScan]?.isGranted ?? false;

    debugPrint(
      '🔐 BT permissions — CONNECT: $connectGranted, SCAN: $scanGranted',
    );

    if (!connectGranted || !scanGranted) {
      debugPrint(
        '⚠️ BT permission ditolak. Buka Settings > Izin Aplikasi > Perangkat Terdekat.',
      );
      return false;
    }
    return true;
  }

  // =============== DEVICE LISTING =================

  /// Ambil daftar Bluetooth device yang sudah di-pair di sistem Android.
  /// User harus pair printer dulu di Settings > Bluetooth Android.
  /// Akan otomatis request permission jika belum diberikan.
  static Future<List<BluetoothInfo>> getPairedDevices() async {
    try {
      final granted = await ensurePermissions();
      if (!granted) {
        debugPrint('❌ getPairedDevices: BT permission tidak diberikan');
        return [];
      }

      final devices = await PrintBluetoothThermal.pairedBluetooths;
      debugPrint('🔵 Paired BT devices: ${devices.length}');
      for (final d in devices) {
        debugPrint('  • ${d.name} [${d.macAdress}]');
      }
      return devices;
    } catch (e) {
      debugPrint('❌ Error getting paired devices: $e');
      return [];
    }
  }

  // =============== MAIN PRINT FUNCTION =================

  /// Print label langsung ke thermal printer via Bluetooth.
  ///
  /// [reportName] nama report Crystal Report, mis. 'CrLabelBarangJadi'
  /// [query]      parameter query, mis. {'NoBJ': '...'}
  /// [mac]        MAC address printer Bluetooth
  /// [onStatus]   callback status update untuk UI
  /// [onError]    callback error untuk UI
  ///
  /// Returns true jika berhasil, false jika gagal.
  Future<bool> printLabel({
    required String reportName,
    required Map<String, String> query,
    required String mac,
    String? system,
    Function(String)? onStatus,
    Function(String)? onError,
  }) async {
    try {
      // Step 0: Pastikan permission BT sudah diberikan
      final granted = await ensurePermissions();
      if (!granted) {
        onError?.call(
          'Permission Bluetooth ditolak.\n'
          'Buka Settings > Izin Aplikasi > lalu aktifkan "Perangkat Terdekat".',
        );
        return false;
      }

      // Step 1: Download PDF
      onStatus?.call('Mengunduh PDF dari server...');
      final url = buildPdfUri(
        reportName: reportName,
        query: query,
        system: system,
      );
      final pdfBytes = await _downloadPdf(url);
      debugPrint('📄 PDF: ${pdfBytes.length} bytes');

      // Step 2: Rasterize PDF → PNG images
      onStatus?.call('Memproses PDF...');
      final escBytes = await _pdfToEscPos(pdfBytes);
      debugPrint('🖨️ ESC/POS bytes: ${escBytes.length}');

      // Step 3: Pastikan BT aktif di sistem
      onStatus?.call('Mengecek Bluetooth...');
      final btOn = await PrintBluetoothThermal.bluetoothEnabled;
      if (!btOn) {
        onError?.call(
          'Bluetooth tidak aktif. Aktifkan Bluetooth lalu coba lagi.',
        );
        return false;
      }

      // Selalu putuskan sesi lama sebelum connect baru.
      // Alasan: connectionStatus bisa return false tapi socket di Android masih
      // dalam state CONNECTED (mSocketState: CONNECTED), sehingga connect() baru
      // langsung gagal dengan "read failed, socket might closed or timeout".
      // Dengan selalu disconnect + delay 1500ms, socket Android punya waktu
      // untuk benar-benar melepas koneksi sebelum kita reconnect.
      debugPrint('🔄 Disconnect sesi BT sebelumnya (unconditional)...');
      await PrintBluetoothThermal.disconnect;
      await Future.delayed(const Duration(milliseconds: 1500));

      // Step 4: Connect ke printer (dengan 1 kali retry jika gagal)
      onStatus?.call('Menghubungkan ke printer...');
      bool connected = await PrintBluetoothThermal.connect(
        macPrinterAddress: mac,
      );
      if (!connected) {
        debugPrint('⚠️ Connect pertama gagal, coba lagi setelah 1.2s...');
        await Future.delayed(const Duration(milliseconds: 1200));
        connected = await PrintBluetoothThermal.connect(macPrinterAddress: mac);
      }
      if (!connected) {
        onError?.call(
          'Gagal terhubung ke printer.\n'
          'Pastikan:\n'
          '• Bluetooth aktif\n'
          '• Printer menyala & dalam jangkauan\n'
          '• Printer sudah di-pair di Settings Android\n'
          '• MAC: $mac',
        );
        return false;
      }
      debugPrint('✅ Connected to printer: $mac');

      // Step 5: Kirim ESC/POS bytes
      onStatus?.call('Mencetak...');
      final ok = await PrintBluetoothThermal.writeBytes(escBytes);
      debugPrint('🖨️ Write bytes result: $ok');

      if (ok) {
        onStatus?.call('✅ Berhasil dicetak!');
        return true;
      } else {
        onError?.call('Gagal mengirim data ke printer.');
        return false;
      }
    } catch (e) {
      debugPrint('❌ BtPrintService error: $e');
      onError?.call('Error: ${e.toString()}');
      return false;
    }
  }

  // =============== INTERNALS =================

  Future<Uint8List> _downloadPdf(Uri url) async {
    final client = httpClient ?? http.Client();
    final headers = <String, String>{};
    if (getAuthHeader != null) headers.addAll(getAuthHeader!());

    final resp = await client
        .get(url, headers: headers)
        .timeout(const Duration(seconds: 30));

    if (resp.statusCode != 200 || resp.bodyBytes.isEmpty) {
      throw Exception('HTTP ${resp.statusCode} — tidak ada data PDF.');
    }
    return resp.bodyBytes;
  }

  /// Convert PDF bytes → ESC/POS byte list siap kirim ke thermal printer.
  ///
  /// Proses:
  /// 1. Raster PDF ke PNG pada 406 DPI (2× resolusi fisik 203 DPI)
  /// 2. Flatten alpha-transparan → background putih (hindari background hitam)
  /// 3. Boost contrast 30% → teks/barcode makin hitam, background makin putih
  /// 4. Grayscale → threshold 1-bit lebih bersih
  /// 5. Auto-trim whitespace kosong di bagian bawah gambar
  /// 6. Resize ke 576px dengan cubic interpolation
  /// 7. imageRaster dengan high density horizontal + vertical
  Future<List<int>> _pdfToEscPos(Uint8List pdfBytes) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);
    final List<int> bytes = [];

    // 406 DPI = 2× resolusi fisik printer (203 DPI).
    // Teknik standar thermal: render di 2× target resolusi lalu resize down.
    // Hasil downsampling dari sumber 2× jauh lebih tajam daripada render
    // langsung di resolusi target (teks kecil, garis tipis, barcode lebih bersih).
    final pages = Printing.raster(pdfBytes, dpi: 406);
    await for (final page in pages) {
      final pngBytes = await page.toPng();

      var decoded = img.decodeImage(pngBytes);
      if (decoded == null) continue;

      // Flatten transparency → background putih.
      // PDF raster sering punya channel alpha transparan di background.
      // ESC/POS imageRaster() tidak mengerti alpha: piksel transparan → hitam.
      // Fix: composite di atas canvas putih opaque (RGB, tanpa alpha).
      final whiteBg = img.Image(
        width: decoded.width,
        height: decoded.height,
        numChannels: 3,
      );
      img.fill(whiteBg, color: img.ColorRgb8(255, 255, 255));
      img.compositeImage(whiteBg, decoded);
      decoded = whiteBg;

      // Boost contrast sebelum grayscale.
      // contrast: 0.3 = 30% peningkatan — teks/garis/barcode makin hitam,
      // background putih makin putih → threshold 1-bit lebih crisp.
      final contrasted = img.adjustColor(decoded, contrast: 0.3);

      // Grayscale untuk konversi 1-bit
      final gray = img.grayscale(contrasted);

      // Auto-trim whitespace kosong di bagian bawah menggunakan img.trim().
      // - mode: bottomRightColor → warna referensi diambil dari piksel pojok
      //   kanan-bawah (yang pasti berada di area margin kosong PDF).
      //   Library mencocokkan warna itu ke semua baris bawah dan memotongnya.
      //   Ini menghindari masalah format piksel (uint8 vs float) dan threshold
      //   manual yang tidak reliabel.
      // - sides: Trim.bottom → hanya potong dari bawah, atas/kiri/kanan aman.
      final trimmed = img.trim(
        gray,
        mode: img.TrimMode.bottomRightColor,
        sides: img.Trim.bottom,
      );
      debugPrint('✂️ Auto-trim: ${gray.height}px → ${trimmed.height}px');

      // Resize ke 576 dots dengan cubic interpolation.
      // Cubic memberi anti-aliasing lebih baik dibanding linear saat downscale.
      final resized = img.copyResize(
        trimmed,
        width: 576,
        interpolation: img.Interpolation.cubic,
      );

      // highDensityHorizontal + highDensityVertical = full 203×203 DPI mode
      bytes.addAll(
        generator.imageRaster(
          resized,
          highDensityHorizontal: true,
          highDensityVertical: true,
        ),
      );
    }

    // feed(1) — satu baris kecil sebelum cut agar pisau tidak terlalu mepet
    bytes.addAll(generator.feed(1));
    bytes.addAll(generator.cut());

    return bytes;
  }
}
