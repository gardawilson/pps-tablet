# Alur Pilih Printer Bluetooth

## Deskripsi

Alur ketika user membuka dialog pemilihan printer Bluetooth pada `PdfViewerScreen`.
Dialog menampilkan daftar perangkat BT yang sudah di-pair di Android, dilengkapi
alias dari database (`MstPrinter`) agar nama printer mudah dikenali antar tablet.

## Flowchart

```mermaid
flowchart TD
    A([Dialog dibuka]) --> B[Future.wait — parallel]

    B --> C[getPairedDevices — Android BT]
    B --> D[fetchAliases — GET /api/mst-printer]

    C --> H
    D -- Sukses --> H
    D -- Gagal/Offline --> H

    H[Keduanya selesai — data digabung] --> I[setState — simpan devices dan aliases]

    I --> J[ListView render]
    J --> K{Resolve nama per item}
    K -- Ada alias --> L[Tampil alias + badge biru]
    K -- Tidak ada alias --> M[Tampil nama BT atau MAC]

    L & M --> O[Daftar printer tampil]

    O --> P{User action}

    P -- Tap Refresh --> B
    P -- Tap edit alias --> Q[showDialog — AliasEditDialog]
    Q --> R{Hasil}
    R -- SIMPAN atau HAPUS --> S[POST atau DELETE /api/mst-printer\nUpdate cache SharedPreferences]
    R -- BATAL --> O
    S --> D

    P -- Tap printer --> T[Resolve nama — alias lalu nama BT lalu MAC]
    T --> U[savePrinter — simpan ke SharedPreferences]
    U --> V[onSelected — update parent state]
    V --> W([Dialog tutup — Printer aktif berganti])
```

## Catatan

- **Parallel fetch** — `getPairedDevices` dan `fetchAliases` berjalan bersamaan via `Future.wait`,
  total waktu tunggu = proses yang paling lambat.
- **Offline fallback** — jika API gagal, alias diambil dari cache `SharedPreferences`.
- **Alias global** — alias disimpan di tabel `MstPrinter` (SQL Server), sehingga perubahan
  nama di satu tablet otomatis terlihat di semua tablet lain saat dialog dibuka/di-refresh.
- **`AliasEditDialog`** menggunakan `StatefulWidget` agar `TextEditingController` di-dispose
  oleh Flutter setelah animasi dialog selesai, menghindari error `_dependents.isEmpty`.

## File Terkait

| File                                            | Keterangan                        |
| ----------------------------------------------- | --------------------------------- |
| `lib/common/widgets/pdf_viewer_screen.dart`     | UI dialog + logika pilih printer  |
| `lib/core/utils/master_printer_repository.dart` | Repository API MstPrinter + cache |
| `lib/core/utils/bt_print_service.dart`          | BT scan, connect, print ESC/POS   |
| `lib/core/network/endpoints.dart`               | Konstanta URL `/api/mst-printer`  |
