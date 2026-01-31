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
      default:
        return null;
    }
  }
}