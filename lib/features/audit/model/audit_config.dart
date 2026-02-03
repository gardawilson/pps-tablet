// lib/features/audit/model/audit_config.dart

/// Configuration untuk field mapping per module
class AuditFieldConfig {
  final String idField;
  final String? nameField;
  final String displayLabel;
  final AuditFieldType type;

  const AuditFieldConfig({
    required this.idField,
    this.nameField,
    required this.displayLabel,
    this.type = AuditFieldType.relational,
  });

  bool get isScalar => type == AuditFieldType.scalar;
  bool get isRelational => type == AuditFieldType.relational;
}

enum AuditFieldType {
  relational,
  scalar,
}

/// Module-specific audit configurations
class AuditModuleConfig {
  final String module;
  final String pkField;
  final String displayName;
  final List<AuditFieldConfig> fields;

  const AuditModuleConfig({
    required this.module,
    required this.pkField,
    required this.displayName,
    required this.fields,
  });

  // =============================
  // Predefined configs
  // =============================
  static const washing = AuditModuleConfig(
    module: 'washing',
    pkField: 'NoWashing',
    displayName: 'Washing',
    fields: [
      AuditFieldConfig(
        idField: 'IdJenisPlastik',
        nameField: 'NamaJenisPlastik',
        displayLabel: 'Jenis Plastik',
        type: AuditFieldType.relational,
      ),
      AuditFieldConfig(
        idField: 'IdWarehouse',
        nameField: 'NamaWarehouse',
        displayLabel: 'Warehouse',
        type: AuditFieldType.relational,
      ),
      AuditFieldConfig(
        idField: 'Blok',
        displayLabel: 'Blok',
        type: AuditFieldType.scalar,
      ),
      AuditFieldConfig(
        idField: 'IdLokasi',
        displayLabel: 'Lokasi',
        type: AuditFieldType.scalar,
      ),
    ],
  );

  static const broker = AuditModuleConfig(
    module: 'broker',
    pkField: 'NoBroker',
    displayName: 'Broker',
    fields: [
      AuditFieldConfig(
        idField: 'IdJenisPlastik',
        nameField: 'NamaJenisPlastik',
        displayLabel: 'Jenis Plastik',
        type: AuditFieldType.relational,
      ),
      AuditFieldConfig(
        idField: 'IdWarehouse',
        nameField: 'NamaWarehouse',
        displayLabel: 'Warehouse',
        type: AuditFieldType.relational,
      ),
      AuditFieldConfig(
        idField: 'Blok',
        displayLabel: 'Blok',
        type: AuditFieldType.scalar,
      ),
      AuditFieldConfig(
        idField: 'IdLokasi',
        displayLabel: 'Lokasi',
        type: AuditFieldType.scalar,
      ),
    ],
  );

  static const crusher = AuditModuleConfig(
    module: 'crusher',
    pkField: 'NoCrusher',
    displayName: 'Crusher',
    fields: [
      AuditFieldConfig(
        idField: 'IdCrusher',
        nameField: 'NamaCrusher',
        displayLabel: 'Crusher Machine',
        type: AuditFieldType.relational,
      ),
      AuditFieldConfig(
        idField: 'IdWarehouse',
        nameField: 'NamaWarehouse',
        displayLabel: 'Warehouse',
        type: AuditFieldType.relational,
      ),
      AuditFieldConfig(
        idField: 'Berat',
        displayLabel: 'Berat (kg)',
        type: AuditFieldType.scalar,
      ),
      AuditFieldConfig(
        idField: 'DateCreate',
        displayLabel: 'Tanggal Buat',
        type: AuditFieldType.scalar,
      ),
      AuditFieldConfig(
        idField: 'Blok',
        displayLabel: 'Blok',
        type: AuditFieldType.scalar,
      ),
      AuditFieldConfig(
        idField: 'IdLokasi',
        displayLabel: 'Lokasi',
        type: AuditFieldType.scalar,
      ),
    ],
  );

  static const bonggolan = AuditModuleConfig(
    module: 'bonggolan',
    pkField: 'NoBonggolan',
    displayName: 'Bonggolan',
    fields: [
      AuditFieldConfig(
        idField: 'IdBonggolan',
        nameField: 'NamaBonggolan',
        displayLabel: 'Jenis Bonggolan',
        type: AuditFieldType.relational,
      ),
      AuditFieldConfig(
        idField: 'IdWarehouse',
        nameField: 'NamaWarehouse',
        displayLabel: 'Warehouse',
        type: AuditFieldType.relational,
      ),
      AuditFieldConfig(
        idField: 'Berat',
        displayLabel: 'Berat (kg)',
        type: AuditFieldType.scalar,
      ),
      AuditFieldConfig(
        idField: 'DateCreate',
        displayLabel: 'Tanggal Buat',
        type: AuditFieldType.scalar,
      ),
      AuditFieldConfig(
        idField: 'Blok',
        displayLabel: 'Blok',
        type: AuditFieldType.scalar,
      ),
      AuditFieldConfig(
        idField: 'IdLokasi',
        displayLabel: 'Lokasi',
        type: AuditFieldType.scalar,
      ),
    ],
  );

  static const gilingan = AuditModuleConfig(
    module: 'gilingan',
    pkField: 'NoGilingan',
    displayName: 'Gilingan',
    fields: [
      AuditFieldConfig(
        idField: 'IdGilingan',
        nameField: 'NamaGilingan',
        displayLabel: 'Jenis Gilingan',
        type: AuditFieldType.relational,
      ),
      AuditFieldConfig(
        idField: 'IdWarehouse',
        nameField: 'NamaWarehouse',
        displayLabel: 'Warehouse',
        type: AuditFieldType.relational,
      ),
      AuditFieldConfig(
        idField: 'Berat',
        displayLabel: 'Berat (kg)',
        type: AuditFieldType.scalar,
      ),
      AuditFieldConfig(
        idField: 'DateCreate',
        displayLabel: 'Tanggal Buat',
        type: AuditFieldType.scalar,
      ),
      AuditFieldConfig(
        idField: 'Blok',
        displayLabel: 'Blok',
        type: AuditFieldType.scalar,
      ),
      AuditFieldConfig(
        idField: 'IdLokasi',
        displayLabel: 'Lokasi',
        type: AuditFieldType.scalar,
      ),
    ],
  );

  static const mixer = AuditModuleConfig(
    module: 'mixer',
    pkField: 'NoMixer',
    displayName: 'Mixer',
    fields: [
      AuditFieldConfig(
        idField: 'IdMixer',
        nameField: 'NamaMixer',
        displayLabel: 'Jenis Mixer',
        type: AuditFieldType.relational,
      ),
      AuditFieldConfig(
        idField: 'IdWarehouse',
        nameField: 'NamaWarehouse',
        displayLabel: 'Warehouse',
        type: AuditFieldType.relational,
      ),
      AuditFieldConfig(
        idField: 'Blok',
        displayLabel: 'Blok',
        type: AuditFieldType.scalar,
      ),
      AuditFieldConfig(
        idField: 'IdLokasi',
        displayLabel: 'Lokasi',
        type: AuditFieldType.scalar,
      ),
    ],
  );

  static const furniturewip = AuditModuleConfig(
    module: 'furniturewip',
    pkField: 'NoFurnitureWIP',
    displayName: 'Furniture WIP',
    fields: [
      AuditFieldConfig(
        idField: 'IDFurnitureWIP',
        nameField: 'NamaFurnitureWIP',
        displayLabel: 'Furniture WIP',
        type: AuditFieldType.relational,
      ),
      AuditFieldConfig(
        idField: 'IdWarehouse',
        nameField: 'NamaWarehouse',
        displayLabel: 'Warehouse',
        type: AuditFieldType.relational,
      ),
      AuditFieldConfig(
        idField: 'Pcs',
        displayLabel: 'Pcs',
        type: AuditFieldType.scalar,
      ),
      AuditFieldConfig(
        idField: 'Berat',
        displayLabel: 'Berat (kg)',
        type: AuditFieldType.scalar,
      ),
      AuditFieldConfig(
        idField: 'DateCreate',
        displayLabel: 'Tanggal Buat',
        type: AuditFieldType.scalar,
      ),
      AuditFieldConfig(
        idField: 'Blok',
        displayLabel: 'Blok',
        type: AuditFieldType.scalar,
      ),
      AuditFieldConfig(
        idField: 'IdLokasi',
        displayLabel: 'Lokasi',
        type: AuditFieldType.scalar,
      ),
    ],
  );

  static const barangjadi = AuditModuleConfig(
    module: 'barangjadi',
    pkField: 'NoBJ',
    displayName: 'Barang Jadi',
    fields: [
      AuditFieldConfig(
        idField: 'IdBJ',
        nameField: 'NamaBJ',
        displayLabel: 'Barang Jadi',
        type: AuditFieldType.relational,
      ),
      AuditFieldConfig(
        idField: 'Pcs',
        displayLabel: 'Pcs',
        type: AuditFieldType.scalar,
      ),
      AuditFieldConfig(
        idField: 'Berat',
        displayLabel: 'Berat (kg)',
        type: AuditFieldType.scalar,
      ),
      AuditFieldConfig(
        idField: 'DateCreate',
        displayLabel: 'Tanggal Buat',
        type: AuditFieldType.scalar,
      ),
      AuditFieldConfig(
        idField: 'Blok',
        displayLabel: 'Blok',
        type: AuditFieldType.scalar,
      ),
      AuditFieldConfig(
        idField: 'IdLokasi',
        displayLabel: 'Lokasi',
        type: AuditFieldType.scalar,
      ),
    ],
  );

  static const reject = AuditModuleConfig(
    module: 'reject',
    pkField: 'NoReject',
    displayName: 'Reject',
    fields: [
      AuditFieldConfig(
        idField: 'IdReject',
        nameField: 'NamaReject',
        displayLabel: 'Reject',
        type: AuditFieldType.relational,
      ),
      AuditFieldConfig(
        idField: 'Berat',
        displayLabel: 'Berat (kg)',
        type: AuditFieldType.scalar,
      ),
      AuditFieldConfig(
        idField: 'DateCreate',
        displayLabel: 'Tanggal Buat',
        type: AuditFieldType.scalar,
      ),
      AuditFieldConfig(
        idField: 'Blok',
        displayLabel: 'Blok',
        type: AuditFieldType.scalar,
      ),
      AuditFieldConfig(
        idField: 'IdLokasi',
        displayLabel: 'Lokasi',
        type: AuditFieldType.scalar,
      ),
    ],
  );

  static const washingProduksi = AuditModuleConfig(
    module: 'washing_produksi',
    pkField: 'NoProduksi',
    displayName: 'Washing Produksi',
    fields: [
      // kalau di backend nanti kamu join nama operator/mesin,
      // pakai nameField. Kalau belum, nameField boleh null.

      AuditFieldConfig(
        idField: 'IdMesin',
        nameField: 'NamaMesin', // optional (kalau backend join)
        displayLabel: 'Mesin',
        type: AuditFieldType.relational,
      ),
      AuditFieldConfig(
        idField: 'IdOperator',
        nameField: 'NamaOperator', // optional (kalau backend join)
        displayLabel: 'Operator',
        type: AuditFieldType.relational,
      ),

      // scalar fields (old/new dari JSON header)
      AuditFieldConfig(
        idField: 'TglProduksi',
        displayLabel: 'Tanggal Produksi',
        type: AuditFieldType.scalar,
      ),
      AuditFieldConfig(
        idField: 'Shift',
        displayLabel: 'Shift',
        type: AuditFieldType.scalar,
      ),
      AuditFieldConfig(
        idField: 'JamKerja',
        displayLabel: 'Jam Kerja',
        type: AuditFieldType.scalar,
      ),
      AuditFieldConfig(
        idField: 'JmlhAnggota',
        displayLabel: 'Jumlah Anggota',
        type: AuditFieldType.scalar,
      ),
      AuditFieldConfig(
        idField: 'Hadir',
        displayLabel: 'Hadir',
        type: AuditFieldType.scalar,
      ),
      AuditFieldConfig(
        idField: 'HourMeter',
        displayLabel: 'Hour Meter',
        type: AuditFieldType.scalar,
      ),
      AuditFieldConfig(
        idField: 'HourStart',
        displayLabel: 'Mulai',
        type: AuditFieldType.scalar,
      ),
      AuditFieldConfig(
        idField: 'HourEnd',
        displayLabel: 'Selesai',
        type: AuditFieldType.scalar,
      ),
      AuditFieldConfig(
        idField: 'CreateBy',
        displayLabel: 'Create By',
        type: AuditFieldType.scalar,
      ),
    ],
  );


  static const brokerProduksi = AuditModuleConfig(
    module: 'broker_produksi',
    pkField: 'NoProduksi',
    displayName: 'Broker Produksi',
    fields: [
      AuditFieldConfig(
        idField: 'IdMesin',
        nameField: 'NamaMesin', // optional kalau backend join
        displayLabel: 'Mesin',
        type: AuditFieldType.relational,
      ),
      AuditFieldConfig(
        idField: 'IdOperator',
        nameField: 'NamaOperator', // optional kalau backend join
        displayLabel: 'Operator',
        type: AuditFieldType.relational,
      ),

      AuditFieldConfig(
        idField: 'TglProduksi',
        displayLabel: 'Tanggal Produksi',
        type: AuditFieldType.scalar,
      ),
      AuditFieldConfig(
        idField: 'Shift',
        displayLabel: 'Shift',
        type: AuditFieldType.scalar,
      ),
      AuditFieldConfig(
        idField: 'Jam',
        displayLabel: 'Jam',
        type: AuditFieldType.scalar,
      ),
      AuditFieldConfig(
        idField: 'JmlhAnggota',
        displayLabel: 'Jumlah Anggota',
        type: AuditFieldType.scalar,
      ),
      AuditFieldConfig(
        idField: 'Hadir',
        displayLabel: 'Hadir',
        type: AuditFieldType.scalar,
      ),
      AuditFieldConfig(
        idField: 'HourMeter',
        displayLabel: 'Hour Meter',
        type: AuditFieldType.scalar,
      ),
      AuditFieldConfig(
        idField: 'HourStart',
        displayLabel: 'Mulai',
        type: AuditFieldType.scalar,
      ),
      AuditFieldConfig(
        idField: 'HourEnd',
        displayLabel: 'Selesai',
        type: AuditFieldType.scalar,
      ),
      AuditFieldConfig(
        idField: 'CreateBy',
        displayLabel: 'Create By',
        type: AuditFieldType.scalar,
      ),
    ],
  );

  static const crusherProduksi = AuditModuleConfig(
    module: 'crusher_produksi',
    pkField: 'NoCrusherProduksi',
    displayName: 'Crusher Produksi',
    fields: [
      AuditFieldConfig(
        idField: 'IdMesin',
        nameField: 'NamaMesin', // optional kalau backend join
        displayLabel: 'Mesin',
        type: AuditFieldType.relational,
      ),
      AuditFieldConfig(
        idField: 'IdOperator',
        nameField: 'NamaOperator', // optional kalau backend join
        displayLabel: 'Operator',
        type: AuditFieldType.relational,
      ),

      AuditFieldConfig(
        idField: 'Tanggal',
        displayLabel: 'Tanggal Produksi',
        type: AuditFieldType.scalar,
      ),
      AuditFieldConfig(
        idField: 'Shift',
        displayLabel: 'Shift',
        type: AuditFieldType.scalar,
      ),
      AuditFieldConfig(
        idField: 'Jam',
        displayLabel: 'Jam',
        type: AuditFieldType.scalar,
      ),
      AuditFieldConfig(
        idField: 'JmlhAnggota',
        displayLabel: 'Jumlah Anggota',
        type: AuditFieldType.scalar,
      ),
      AuditFieldConfig(
        idField: 'Hadir',
        displayLabel: 'Hadir',
        type: AuditFieldType.scalar,
      ),
      AuditFieldConfig(
        idField: 'HourMeter',
        displayLabel: 'Hour Meter',
        type: AuditFieldType.scalar,
      ),
      AuditFieldConfig(
        idField: 'HourStart',
        displayLabel: 'Mulai',
        type: AuditFieldType.scalar,
      ),
      AuditFieldConfig(
        idField: 'HourEnd',
        displayLabel: 'Selesai',
        type: AuditFieldType.scalar,
      ),
      AuditFieldConfig(
        idField: 'CreateBy',
        displayLabel: 'Create By',
        type: AuditFieldType.scalar,
      ),
      AuditFieldConfig(
        idField: 'CheckBy1',
        displayLabel: 'Check By 1',
        type: AuditFieldType.scalar,
      ),
      AuditFieldConfig(
        idField: 'CheckBy2',
        displayLabel: 'Check By 2',
        type: AuditFieldType.scalar,
      ),
      AuditFieldConfig(
        idField: 'ApproveBy',
        displayLabel: 'Approve By',
        type: AuditFieldType.scalar,
      ),
    ],
  );


  static const gilinganProduksi = AuditModuleConfig(
    module: 'gilingan_produksi',
    pkField: 'NoProduksi',
    displayName: 'Gilingan Produksi',
    fields: [
      AuditFieldConfig(
        idField: 'IdMesin',
        nameField: 'NamaMesin',
        displayLabel: 'Mesin',
        type: AuditFieldType.relational,
      ),
      AuditFieldConfig(
        idField: 'IdOperator',
        nameField: 'NamaOperator',
        displayLabel: 'Operator',
        type: AuditFieldType.relational,
      ),

      AuditFieldConfig(
        idField: 'Tanggal',
        displayLabel: 'Tanggal Produksi',
        type: AuditFieldType.scalar,
      ),
      AuditFieldConfig(
        idField: 'Shift',
        displayLabel: 'Shift',
        type: AuditFieldType.scalar,
      ),
      AuditFieldConfig(
        idField: 'Jam',
        displayLabel: 'Jam',
        type: AuditFieldType.scalar,
      ),
      AuditFieldConfig(
        idField: 'JmlhAnggota',
        displayLabel: 'Jumlah Anggota',
        type: AuditFieldType.scalar,
      ),
      AuditFieldConfig(
        idField: 'Hadir',
        displayLabel: 'Hadir',
        type: AuditFieldType.scalar,
      ),
      AuditFieldConfig(
        idField: 'HourMeter',
        displayLabel: 'Hour Meter',
        type: AuditFieldType.scalar,
      ),
      AuditFieldConfig(
        idField: 'HourStart',
        displayLabel: 'Mulai',
        type: AuditFieldType.scalar,
      ),
      AuditFieldConfig(
        idField: 'HourEnd',
        displayLabel: 'Selesai',
        type: AuditFieldType.scalar,
      ),
      AuditFieldConfig(
        idField: 'CreateBy',
        displayLabel: 'Create By',
        type: AuditFieldType.scalar,
      ),
    ],
  );

  static const mixerProduksi = AuditModuleConfig(
    module: 'mixer_produksi',
    pkField: 'NoProduksi',
    displayName: 'Mixer Produksi',
    fields: [
      AuditFieldConfig(
        idField: 'IdMesin',
        nameField: 'NamaMesin',
        displayLabel: 'Mesin',
        type: AuditFieldType.relational,
      ),
      AuditFieldConfig(
        idField: 'IdOperator',
        nameField: 'NamaOperator',
        displayLabel: 'Operator',
        type: AuditFieldType.relational,
      ),

      AuditFieldConfig(
        idField: 'TglProduksi',
        displayLabel: 'Tanggal Produksi',
        type: AuditFieldType.scalar,
      ),
      AuditFieldConfig(
        idField: 'Shift',
        displayLabel: 'Shift',
        type: AuditFieldType.scalar,
      ),
      AuditFieldConfig(
        idField: 'Jam',
        displayLabel: 'Jam',
        type: AuditFieldType.scalar,
      ),
      AuditFieldConfig(
        idField: 'JmlhAnggota',
        displayLabel: 'Jumlah Anggota',
        type: AuditFieldType.scalar,
      ),
      AuditFieldConfig(
        idField: 'Hadir',
        displayLabel: 'Hadir',
        type: AuditFieldType.scalar,
      ),
      AuditFieldConfig(
        idField: 'HourMeter',
        displayLabel: 'Hour Meter',
        type: AuditFieldType.scalar,
      ),
      AuditFieldConfig(
        idField: 'HourStart',
        displayLabel: 'Mulai',
        type: AuditFieldType.scalar,
      ),
      AuditFieldConfig(
        idField: 'HourEnd',
        displayLabel: 'Selesai',
        type: AuditFieldType.scalar,
      ),
      AuditFieldConfig(
        idField: 'CreateBy',
        displayLabel: 'Create By',
        type: AuditFieldType.scalar,
      ),
    ],
  );

  static const injectProduksi = AuditModuleConfig(
    module: 'inject_produksi',
    pkField: 'NoProduksi',
    displayName: 'Inject Produksi',
    fields: [
      AuditFieldConfig(
        idField: 'IdMesin',
        nameField: 'NamaMesin',
        displayLabel: 'Mesin',
        type: AuditFieldType.relational,
      ),
      AuditFieldConfig(
        idField: 'IdOperator',
        nameField: 'NamaOperator',
        displayLabel: 'Operator',
        type: AuditFieldType.relational,
      ),
      AuditFieldConfig(
        idField: 'TglProduksi',
        displayLabel: 'Tanggal Produksi',
        type: AuditFieldType.scalar,
      ),
      AuditFieldConfig(
        idField: 'Shift',
        displayLabel: 'Shift',
        type: AuditFieldType.scalar,
      ),
      AuditFieldConfig(
        idField: 'Jam',
        displayLabel: 'Jam',
        type: AuditFieldType.scalar,
      ),
      AuditFieldConfig(
        idField: 'JmlhAnggota',
        displayLabel: 'Jumlah Anggota',
        type: AuditFieldType.scalar,
      ),
      AuditFieldConfig(
        idField: 'Hadir',
        displayLabel: 'Hadir',
        type: AuditFieldType.scalar,
      ),
      AuditFieldConfig(
        idField: 'HourMeter',
        displayLabel: 'Hour Meter',
        type: AuditFieldType.scalar,
      ),
      AuditFieldConfig(
        idField: 'HourStart',
        displayLabel: 'Mulai',
        type: AuditFieldType.scalar,
      ),
      AuditFieldConfig(
        idField: 'HourEnd',
        displayLabel: 'Selesai',
        type: AuditFieldType.scalar,
      ),
      AuditFieldConfig(
        idField: 'CreateBy',
        displayLabel: 'Create By',
        type: AuditFieldType.scalar,
      ),
    ],
  );

  static const hotStamping = AuditModuleConfig(
    module: 'hot_stamping',
    pkField: 'NoProduksi',
    displayName: 'Hot Stamping',
    fields: [
      AuditFieldConfig(
        idField: 'IdMesin',
        nameField: 'NamaMesin',
        displayLabel: 'Mesin',
        type: AuditFieldType.relational,
      ),
      AuditFieldConfig(
        idField: 'IdOperator',
        nameField: 'NamaOperator',
        displayLabel: 'Operator',
        type: AuditFieldType.relational,
      ),
      AuditFieldConfig(
        idField: 'Tanggal',
        displayLabel: 'Tanggal',
        type: AuditFieldType.scalar,
      ),
      AuditFieldConfig(
        idField: 'Shift',
        displayLabel: 'Shift',
        type: AuditFieldType.scalar,
      ),
      AuditFieldConfig(
        idField: 'HourMeter',
        displayLabel: 'Hour Meter',
        type: AuditFieldType.scalar,
      ),
      AuditFieldConfig(
        idField: 'HourStart',
        displayLabel: 'Mulai',
        type: AuditFieldType.scalar,
      ),
      AuditFieldConfig(
        idField: 'HourEnd',
        displayLabel: 'Selesai',
        type: AuditFieldType.scalar,
      ),
      AuditFieldConfig(
        idField: 'CreateBy',
        displayLabel: 'Create By',
        type: AuditFieldType.scalar,
      ),
    ],
  );

  static const pasangKunci = AuditModuleConfig(
    module: 'pasang_kunci',
    pkField: 'NoProduksi',
    displayName: 'Pasang Kunci',
    fields: [
      AuditFieldConfig(
        idField: 'IdMesin',
        nameField: 'NamaMesin',
        displayLabel: 'Mesin',
        type: AuditFieldType.relational,
      ),
      AuditFieldConfig(
        idField: 'IdOperator',
        nameField: 'NamaOperator',
        displayLabel: 'Operator',
        type: AuditFieldType.relational,
      ),
      AuditFieldConfig(
        idField: 'Tanggal',
        displayLabel: 'Tanggal',
        type: AuditFieldType.scalar,
      ),
      AuditFieldConfig(
        idField: 'Shift',
        displayLabel: 'Shift',
        type: AuditFieldType.scalar,
      ),
      AuditFieldConfig(
        idField: 'HourMeter',
        displayLabel: 'Hour Meter',
        type: AuditFieldType.scalar,
      ),
      AuditFieldConfig(
        idField: 'HourStart',
        displayLabel: 'Mulai',
        type: AuditFieldType.scalar,
      ),
      AuditFieldConfig(
        idField: 'HourEnd',
        displayLabel: 'Selesai',
        type: AuditFieldType.scalar,
      ),
      AuditFieldConfig(
        idField: 'CreateBy',
        displayLabel: 'Create By',
        type: AuditFieldType.scalar,
      ),
    ],
  );

  static const spanner = AuditModuleConfig(
    module: 'spanner',
    pkField: 'NoProduksi',
    displayName: 'Spanner',
    fields: [
      AuditFieldConfig(
        idField: 'IdMesin',
        nameField: 'NamaMesin',
        displayLabel: 'Mesin',
        type: AuditFieldType.relational,
      ),
      AuditFieldConfig(
        idField: 'IdOperator',
        nameField: 'NamaOperator',
        displayLabel: 'Operator',
        type: AuditFieldType.relational,
      ),
      AuditFieldConfig(
        idField: 'Tanggal',
        displayLabel: 'Tanggal',
        type: AuditFieldType.scalar,
      ),
      AuditFieldConfig(
        idField: 'Shift',
        displayLabel: 'Shift',
        type: AuditFieldType.scalar,
      ),
      AuditFieldConfig(
        idField: 'HourMeter',
        displayLabel: 'Hour Meter',
        type: AuditFieldType.scalar,
      ),
      AuditFieldConfig(
        idField: 'HourStart',
        displayLabel: 'Mulai',
        type: AuditFieldType.scalar,
      ),
      AuditFieldConfig(
        idField: 'HourEnd',
        displayLabel: 'Selesai',
        type: AuditFieldType.scalar,
      ),
      AuditFieldConfig(
        idField: 'CreateBy',
        displayLabel: 'Create By',
        type: AuditFieldType.scalar,
      ),
    ],
  );

  static const packing = AuditModuleConfig(
    module: 'packing',
    pkField: 'NoPacking',
    displayName: 'Packing',
    fields: [
      AuditFieldConfig(
        idField: 'IdMesin',
        nameField: 'NamaMesin',
        displayLabel: 'Mesin',
        type: AuditFieldType.relational,
      ),
      AuditFieldConfig(
        idField: 'IdOperator',
        nameField: 'NamaOperator',
        displayLabel: 'Operator',
        type: AuditFieldType.relational,
      ),
      AuditFieldConfig(
        idField: 'Tanggal',
        displayLabel: 'Tanggal',
        type: AuditFieldType.scalar,
      ),
      AuditFieldConfig(
        idField: 'Shift',
        displayLabel: 'Shift',
        type: AuditFieldType.scalar,
      ),
      AuditFieldConfig(
        idField: 'HourMeter',
        displayLabel: 'Hour Meter',
        type: AuditFieldType.scalar,
      ),
      AuditFieldConfig(
        idField: 'HourStart',
        displayLabel: 'Mulai',
        type: AuditFieldType.scalar,
      ),
      AuditFieldConfig(
        idField: 'HourEnd',
        displayLabel: 'Selesai',
        type: AuditFieldType.scalar,
      ),
      AuditFieldConfig(
        idField: 'CreateBy',
        displayLabel: 'Create By',
        type: AuditFieldType.scalar,
      ),
    ],
  );

  static const sortirReject = AuditModuleConfig(
    module: 'sortir_reject',
    pkField: 'NoBJSortir',
    displayName: 'Sortir Reject',
    fields: [
      AuditFieldConfig(
        idField: 'IdWarehouse',
        nameField: 'NamaWarehouse',
        displayLabel: 'Warehouse',
        type: AuditFieldType.relational,
      ),
      AuditFieldConfig(
        idField: 'TglBJSortir',
        displayLabel: 'Tanggal',
        type: AuditFieldType.scalar,
      ),
    ],
  );

  static const bjJual = AuditModuleConfig(
    module: 'bj_jual',
    pkField: 'NoBJJual',
    displayName: 'BJ Jual',
    fields: [
      AuditFieldConfig(
        idField: 'IdPembeli',
        nameField: 'NamaPembeli',
        displayLabel: 'Pembeli',
        type: AuditFieldType.relational,
      ),
      AuditFieldConfig(
        idField: 'Tanggal',
        displayLabel: 'Tanggal',
        type: AuditFieldType.scalar,
      ),
      AuditFieldConfig(
        idField: 'Remark',
        displayLabel: 'Remark',
        type: AuditFieldType.scalar,
      ),
    ],
  );

  static const bongkarSusun = AuditModuleConfig(
    module: 'bongkar_susun',
    pkField: 'NoBongkarSusun',
    displayName: 'Bongkar Susun',
    fields: [
      AuditFieldConfig(
        idField: 'Tanggal',
        displayLabel: 'Tanggal',
        type: AuditFieldType.scalar,
      ),
      AuditFieldConfig(
        idField: 'Note',
        displayLabel: 'Note',
        type: AuditFieldType.scalar,
      ),
    ],
  );


  // =============================
  // Lookup helper
  // =============================
  static AuditModuleConfig? forModule(String module) {
    switch (module.toLowerCase()) {
      case 'washing':
        return washing;
      case 'broker':
        return broker;
      case 'crusher':
        return crusher;
      case 'bonggolan':
        return bonggolan;
      case 'gilingan':
        return gilingan;
      case 'mixer':
        return mixer;
      case 'furniturewip':
        return furniturewip;
      case 'barangjadi':
        return barangjadi;
      case 'reject':
        return reject;
      case 'washing_produksi':
        return washingProduksi;
      case 'broker_produksi':
        return brokerProduksi;
      case 'crusher_produksi':
        return crusherProduksi;
      case 'gilingan_produksi':
        return gilinganProduksi;
      case 'mixer_produksi':
        return mixerProduksi;
      case 'inject_produksi':
        return injectProduksi;
      case 'hot_stamping':
        return hotStamping;
      case 'pasang_kunci':
        return pasangKunci;
      case 'spanner':
        return spanner;
      case 'packing':
        return packing;
      case 'sortir_reject':
        return sortirReject;
      case 'bj_jual':
        return bjJual;
      case 'bongkar_susun':
        return bongkarSusun;
      default:
        return null;
    }
  }
}