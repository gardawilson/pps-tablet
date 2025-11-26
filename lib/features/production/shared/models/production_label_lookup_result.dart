// lib/features/production/shared/models/production_label_lookup_result.dart

import 'broker_item.dart';
import 'bb_item.dart';
import 'washing_item.dart';
import 'crusher_item.dart';
import 'gilingan_item.dart';
import 'mixer_item.dart';
import 'reject_item.dart';
import 'bonggolan_item.dart'; // ⬅️ pastikan path & nama file sesuai

class ProductionLabelLookupResult {
  final bool found;
  final String message;
  final String? prefix;
  final String? tableName;
  final int totalRecords;
  final List<Map<String, dynamic>> data;
  final Map<String, dynamic> raw;

  const ProductionLabelLookupResult({
    required this.found,
    required this.message,
    required this.prefix,
    required this.tableName,
    required this.totalRecords,
    required this.data,
    required this.raw,
  });

  factory ProductionLabelLookupResult.success(Map<String, dynamic> body) {
    return ProductionLabelLookupResult(
      found: true,
      message: (body['message'] as String?) ?? 'OK',
      prefix: body['prefix'] as String?,
      tableName: body['tableName'] as String?,
      totalRecords: (body['totalRecords'] as num?)?.toInt() ??
          (body['data'] is List ? (body['data'] as List).length : 0),
      data: _castListMap(body['data']),
      raw: body,
    );
  }

  factory ProductionLabelLookupResult.notFound(Map<String, dynamic> body) {
    return ProductionLabelLookupResult(
      found: false,
      message: (body['message'] as String?) ?? 'Label tidak ditemukan',
      prefix: body['prefix'] as String?,
      tableName: body['tableName'] as String?,
      totalRecords: 0,
      data: const [],
      raw: body,
    );
  }

  static List<Map<String, dynamic>> _castListMap(dynamic v) {
    if (v is List) {
      return v
          .map<Map<String, dynamic>>(
              (e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }
    return const [];
  }

  // ========== TYPED ITEM CONVERTERS ==========

  /// Konversi data ke List<BrokerItem>
  List<BrokerItem> get brokerItems {
    if (!found || data.isEmpty) return const [];
    return data.map((json) => BrokerItem.fromJson(json)).toList();
  }

  /// Konversi data ke List<BbItem>
  List<BbItem> get bbItems {
    if (!found || data.isEmpty) return const [];
    return data.map((json) => BbItem.fromJson(json)).toList();
  }

  /// Konversi data ke List<WashingItem>
  List<WashingItem> get washingItems {
    if (!found || data.isEmpty) return const [];
    return data.map((json) => WashingItem.fromJson(json)).toList();
  }

  /// Konversi data ke List<CrusherItem>
  List<CrusherItem> get crusherItems {
    if (!found || data.isEmpty) return const [];
    return data.map((json) => CrusherItem.fromJson(json)).toList();
  }

  /// Konversi data ke List<GilinganItem>
  List<GilinganItem> get gilinganItems {
    if (!found || data.isEmpty) return const [];
    return data.map((json) => GilinganItem.fromJson(json)).toList();
  }

  /// Konversi data ke List<MixerItem>
  List<MixerItem> get mixerItems {
    if (!found || data.isEmpty) return const [];
    return data.map((json) => MixerItem.fromJson(json)).toList();
  }

  /// Konversi data ke List<RejectItem>
  List<RejectItem> get rejectItems {
    if (!found || data.isEmpty) return const [];
    return data.map((json) => RejectItem.fromJson(json)).toList();
  }

  /// Konversi data ke List<BonggolanItem>
  List<BonggolanItem> get bonggolanItems {
    if (!found || data.isEmpty) return const [];
    return data.map((json) => BonggolanItem.fromJson(json)).toList();
  }

  // ========== SMART GETTER BASED ON PREFIX ==========

  /// Mengembalikan list item yang sesuai berdasarkan prefix
  /// Return type adalah dynamic, cast sesuai kebutuhan di UI
  List<dynamic> get typedItems {
    if (!found || data.isEmpty) return const [];

    final p = (prefix ?? '').toUpperCase();

    switch (p) {
      case 'D.':
        return brokerItems; // Broker_d
      case 'A.':
        return bbItems; // BahanBaku_d
      case 'B.':
        return washingItems; // Washing_d
      case 'F.':
        return crusherItems; // Crusher
      case 'V.':
        return gilinganItems; // Gilingan
      case 'H.':
        return mixerItems; // Mixer_d
      case 'BF.':
        return rejectItems; // RejectV2
      case 'M.':
        return bonggolanItems; // Bonggolan (Crusher Bonggol)
      default:
        return const [];
    }
  }

  // ========== PREFIX TYPE ENUM ==========

  /// Enum untuk tipe prefix yang dikenali
  PrefixType get prefixType {
    final p = (prefix ?? '').toUpperCase();
    switch (p) {
      case 'D.':
        return PrefixType.broker;
      case 'A.':
        return PrefixType.bb;
      case 'B.':
        return PrefixType.washing;
      case 'F.':
        return PrefixType.crusher;
      case 'V.':
        return PrefixType.gilingan;
      case 'H.':
        return PrefixType.mixer;
      case 'BF.':
        return PrefixType.reject;
      case 'M.':
        return PrefixType.bonggolan;
      default:
        return PrefixType.unknown;
    }
  }

  // ========== KEY GENERATION METHODS ==========

  /// Generate simple key untuk anti-duplicate check (TEMP & DB)
  /// Format: prefix|table|no|sak
  ///
  /// Digunakan untuk:
  /// - Cek apakah row sudah ada di TEMP atau DB
  /// - Membandingkan data antar source
  String simpleKey(Map<String, dynamic> row) {
    final String table;
    final String prefix;
    final String no;

    // Helper untuk ambil value dari PascalCase atau camelCase
    String? getValue(String pascalKey, String camelKey) {
      return row[pascalKey]?.toString() ?? row[camelKey]?.toString();
    }

    // Deteksi tipe berdasarkan field yang ada di row
    if (row.containsKey('NoBroker') || row.containsKey('noBroker')) {
      table = 'Broker_d';
      prefix = 'D.';
      no = getValue('NoBroker', 'noBroker') ?? '-';
    } else if (row.containsKey('NoBahanBaku') ||
        row.containsKey('noBahanBaku')) {
      table = 'BahanBaku_d';
      prefix = 'A.';

      final nb = getValue('NoBahanBaku', 'noBahanBaku') ?? '-';
      final palletRaw = row['NoPallet'] ?? row['noPallet'];

      String noCombined;
      if (palletRaw == null ||
          (palletRaw is num && palletRaw == 0) ||
          (palletRaw is String && palletRaw.trim().isEmpty)) {
        noCombined = nb;
      } else {
        noCombined = '$nb-$palletRaw'; // contoh: A.0000002171-2
      }

      no = noCombined;
    } else if (row.containsKey('NoWashing') || row.containsKey('noWashing')) {
      table = 'Washing_d';
      prefix = 'B.';
      no = getValue('NoWashing', 'noWashing') ?? '-';
    } else if (row.containsKey('NoCrusher') || row.containsKey('noCrusher')) {
      table = 'Crusher';
      prefix = 'F.';
      no = getValue('NoCrusher', 'noCrusher') ?? '-';
    } else if (row.containsKey('NoGilingan') ||
        row.containsKey('noGilingan')) {
      table = 'Gilingan';
      prefix = 'V.';
      no = getValue('NoGilingan', 'noGilingan') ?? '-';
    } else if (row.containsKey('NoMixer') || row.containsKey('noMixer')) {
      table = 'Mixer_d';
      prefix = 'H.';
      no = getValue('NoMixer', 'noMixer') ?? '-';
    } else if (row.containsKey('NoReject') || row.containsKey('noReject')) {
      table = 'RejectV2';
      prefix = 'BF.';
      no = getValue('NoReject', 'noReject') ?? '-';
    } else if (row.containsKey('NoBonggolan') ||
        row.containsKey('noBonggolan')) {
      table = 'Bonggolan';
      prefix = 'M.'; // prefix untuk bonggolan
      no = getValue('NoBonggolan', 'noBonggolan') ?? '-';
    } else {
      // Fallback: gunakan info dari context
      table = this.tableName ?? '-';
      prefix = this.prefix ?? '-';
      no = '-';
    }

    // Ambil NoSak (support kedua format)
    final sak = (row['NoSak'] ?? row['noSak'] ?? '').toString().trim();

    return '$prefix|$table|$no|$sak';
  }

  /// Generate unique key untuk UI selection (includes index and timestamps)
  /// Format: prefix|table|no|sak|IDX:index|berat|id|createdAt|updatedAt
  ///
  /// Digunakan untuk:
  /// - Track selected rows di UI (pick/unpick)
  /// - Memastikan uniqueness bahkan untuk data yang identik
  String rowKey(Map<String, dynamic> row) {
    final simpleKeyPart = simpleKey(row);
    final index = data.indexOf(row);

    // Helper untuk ambil value dari berbagai format
    String getValue(String pascalKey, String camelKey) {
      return (row[pascalKey] ?? row[camelKey] ?? '').toString();
    }

    final berat = getValue('Berat', 'berat');
    final beratKg = getValue('BeratKg', 'beratKg');
    final id = getValue('Id', 'id');
    final idCaps = getValue('ID', 'iD'); // edge case
    final createdAt = getValue('CreatedAt', 'created_at');
    final updatedAt = getValue('UpdatedAt', 'updated_at');

    // Gabungkan semua field untuk uniqueness maksimal
    return '$simpleKeyPart|IDX:$index|$berat$beratKg|$id$idCaps|$createdAt|$updatedAt';
  }

  /// Alternative: Generate unique key dengan explicit index parameter
  ///
  /// Digunakan ketika index sudah diketahui dari luar (tidak perlu indexOf)
  String rowKeyWithIndex(Map<String, dynamic> row, int index) {
    final simpleKeyPart = simpleKey(row);

    String getValue(String pascalKey, String camelKey) {
      return (row[pascalKey] ?? row[camelKey] ?? '').toString();
    }

    final berat = getValue('Berat', 'berat');
    final beratKg = getValue('BeratKg', 'beratKg');
    final id = getValue('Id', 'id');
    final idCaps = getValue('ID', 'iD');
    final createdAt = getValue('CreatedAt', 'created_at');
    final updatedAt = getValue('UpdatedAt', 'updated_at');

    return '$simpleKeyPart|IDX:$index|$berat$beratKg|$id$idCaps|$createdAt|$updatedAt';
  }

  // ========== HELPER METHODS ==========

  /// Cek apakah data berisi partial rows
  bool get hasPartialRows {
    if (!found || data.isEmpty) return false;

    switch (prefixType) {
      case PrefixType.broker:
        return brokerItems.any((item) => item.isPartialRow);
      case PrefixType.bb:
        return bbItems.any((item) => item.isPartialRow);
      case PrefixType.gilingan:
        return gilinganItems.any((item) => item.isPartialRow);
      case PrefixType.mixer:
        return mixerItems.any((item) => item.isPartialRow);
      case PrefixType.reject:
        return rejectItems.any((item) => item.isPartialRow);
      case PrefixType.washing:
      case PrefixType.crusher:
      case PrefixType.bonggolan: // bonggolan tidak partial
      case PrefixType.unknown:
        return false;
    }
  }

  /// Hitung total berat dari items
  double get totalBerat {
    if (!found || data.isEmpty) return 0.0;

    return typedItems.fold<double>(0.0, (sum, item) {
      if (item is BrokerItem) return sum + (item.berat ?? 0);
      if (item is BbItem) return sum + (item.berat ?? 0);
      if (item is WashingItem) return sum + (item.berat ?? 0);
      if (item is CrusherItem) return sum + (item.berat ?? 0);
      if (item is GilinganItem) return sum + (item.berat ?? 0);
      if (item is MixerItem) return sum + (item.berat ?? 0);
      if (item is RejectItem) return sum + (item.berat ?? 0);
      if (item is BonggolanItem) return sum + (item.berat ?? 0);
      return sum;
    });
  }

  /// Check if row is valid (memiliki identifier yang diperlukan)
  bool isRowValid(Map<String, dynamic> row) {
    // Support kedua format (PascalCase dan camelCase)
    switch (prefixType) {
      case PrefixType.broker:
        return row['NoBroker'] != null || row['noBroker'] != null;
      case PrefixType.bb:
        return row['NoBahanBaku'] != null || row['noBahanBaku'] != null;
      case PrefixType.washing:
        return row['NoWashing'] != null || row['noWashing'] != null;
      case PrefixType.crusher:
        return row['NoCrusher'] != null || row['noCrusher'] != null;
      case PrefixType.gilingan:
        return row['NoGilingan'] != null || row['noGilingan'] != null;
      case PrefixType.mixer:
        return row['NoMixer'] != null || row['noMixer'] != null;
      case PrefixType.reject:
        return row['NoReject'] != null || row['noReject'] != null;
      case PrefixType.bonggolan:
        return row['NoBonggolan'] != null || row['noBonggolan'] != null;
      case PrefixType.unknown:
        return false;
    }
  }

  /// Debug method to check for duplicate keys
  /// Returns map of keys that appear more than once with their indices
  Map<String, List<int>> analyzeKeyDuplicates() {
    final keyToIndices = <String, List<int>>{};

    for (int i = 0; i < data.length; i++) {
      final row = data[i];
      final key = simpleKey(row); // Gunakan simpleKey untuk analisis duplikat

      if (keyToIndices.containsKey(key)) {
        keyToIndices[key]!.add(i);
      } else {
        keyToIndices[key] = [i];
      }
    }

    // Return only duplicate keys
    final duplicates = <String, List<int>>{};
    keyToIndices.forEach((key, indices) {
      if (indices.length > 1) {
        duplicates[key] = indices;
      }
    });

    return duplicates;
  }
}

/// Enum untuk tipe prefix yang dikenali sistem
enum PrefixType {
  broker,    // D.
  bb,        // A.
  washing,   // B.
  crusher,   // F.
  gilingan,  // V.
  mixer,     // H.
  reject,    // BF.
  bonggolan, // M.
  unknown;

  String get displayName {
    switch (this) {
      case PrefixType.broker:
        return 'Broker';
      case PrefixType.bb:
        return 'Bahan Baku';
      case PrefixType.washing:
        return 'Washing';
      case PrefixType.crusher:
        return 'Crusher';
      case PrefixType.gilingan:
        return 'Gilingan';
      case PrefixType.mixer:
        return 'Mixer';
      case PrefixType.reject:
        return 'Reject';
      case PrefixType.bonggolan:
        return 'Bonggolan';
      case PrefixType.unknown:
        return 'Unknown';
    }
  }

  String get prefixCode {
    switch (this) {
      case PrefixType.broker:
        return 'D.';
      case PrefixType.bb:
        return 'A.';
      case PrefixType.washing:
        return 'B.';
      case PrefixType.crusher:
        return 'F.';
      case PrefixType.gilingan:
        return 'V.';
      case PrefixType.mixer:
        return 'H.';
      case PrefixType.reject:
        return 'BF.';
      case PrefixType.bonggolan:
        return 'M.';
      case PrefixType.unknown:
        return '';
    }
  }
}

// ====== TEMP PARTIAL CODE GENERATOR ======
// Aturan: A. -> P.XXXXX, V. -> Y.XXX, H. -> T.XXXX, BF. -> BK.XXXX, D. -> Q.XXXXXXXXXX

extension TempPartialFormat on PrefixType {
  /// Prefix huruf untuk partial sementara per kategori
  String get tempPartialLetter {
    switch (this) {
      case PrefixType.broker:
        return 'Q'; // Broker
      case PrefixType.bb:
        return 'P'; // Bahan Baku
      case PrefixType.gilingan:
        return 'Y'; // Gilingan
      case PrefixType.mixer:
        return 'T'; // Mixer
      case PrefixType.reject:
        return 'BK'; // Reject
      case PrefixType.washing:
      case PrefixType.crusher:
      case PrefixType.bonggolan:
      case PrefixType.unknown:
        return ''; // lainnya tidak dipakai
    }
  }

  /// Jumlah digit numeric setelah titik
  int get tempPartialDigits {
    switch (this) {
      case PrefixType.broker:
        return 10; // Q.0000000087
      case PrefixType.bb:
        return 5; // P.00001
      case PrefixType.gilingan:
        return 3; // Y.001
      case PrefixType.mixer:
        return 4; // T.0001
      case PrefixType.reject:
        return 4; // BK.0001
      case PrefixType.washing:
      case PrefixType.crusher:
      case PrefixType.bonggolan:
      case PrefixType.unknown:
        return 0;
    }
  }

  /// Apakah kategori ini mendukung temp-partial
  bool get supportsTempPartial {
    return this == PrefixType.broker ||
        this == PrefixType.bb ||
        this == PrefixType.gilingan ||
        this == PrefixType.mixer ||
        this == PrefixType.reject;
  }

  /// Bentuk kode temp-partial dari sequence (0-based atau 1-based sama saja; kamu kontrol dari luar)
  /// Contoh:
  /// - broker (D.) seq=87 -> Q.0000000087
  /// - bb (A.) seq=1 -> P.00001
  /// - mixer (H.) seq=1 -> T.0001
  String formatTempPartial(int seq) {
    if (!supportsTempPartial) return '';
    final n = seq < 1 ? (seq + 1) : seq; // aman kalau kamu pakai 0-based
    final pad = tempPartialDigits;
    final numStr = n.toString().padLeft(pad, '0');
    return '$tempPartialLetter.$numStr';
  }
}

/// Util sederhana jika kamu mau pakai tanpa instance enum
String generateTempPartialCode(PrefixType t, int seq) =>
    t.formatTempPartial(seq);
