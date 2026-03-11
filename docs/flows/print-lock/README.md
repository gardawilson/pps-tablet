# Print Lock Flow (Washing)

Flow ini menjelaskan proses lock label saat print, increment `HasBeenPrinted`, dan fallback retry queue saat jaringan bermasalah.

## Files

- Diagram source: [flow_print_lock.mmd](./flow_print_lock.mmd)
- Diagram image: [flow_print_lock.png](./flow_print_lock.png)

## Ringkasan

1. Acquire lock via `POST /api/labels/:noLabel/print-lock`.
2. Jika print sukses (`writeBytes == true`), panggil `PATCH /api/labels/washing/:noWashing/print`.
3. Release lock via `DELETE /api/labels/:noLabel/print-lock`.
4. Jika PATCH/DELETE gagal, simpan job ke queue lokal (Hive) dan retry otomatis.
5. Socket event sinkronkan status lock dan count antar device.

## Event Socket

- `initial_locks`
- `lock_acquired`
- `lock_released`
- `print_confirmed` (atau `print_count_updated`)
