// lib/features/production/inject/view/inject_production_screen.dart

import 'package:flutter/material.dart';
import 'package:pps_tablet/features/production/inject/repository/inject_production_repository.dart';
import 'package:provider/provider.dart';

import '../../../../common/widgets/error_status_dialog.dart';
import '../../../../common/widgets/horizontal_paged_table.dart';
import '../../../../common/widgets/success_status_dialog.dart';
import '../../../../common/widgets/table_column_spec.dart';
import '../../../../core/utils/date_formatter.dart';

import '../../../cetakan/repository/cetakan_repository.dart';
import '../../../cetakan/view_model/cetakan_view_model.dart';
import '../../../furniture_material/repository/furniture_material_lookup_repository.dart';
import '../../../furniture_material/view_model/furniture_material_lookup_view_model.dart';
import '../../../warna/repository/warna_repository.dart';
import '../../../warna/view_model/warna_view_model.dart';

import '../model/inject_production_model.dart';
import '../view_model/inject_production_view_model.dart';
import '../widgets/inject_production_action_bar.dart';
import '../widgets/inject_production_delete_dialog.dart';
import '../widgets/inject_production_form_dialog.dart';
import '../widgets/inject_production_row_popover.dart';
import 'inject_production_input_screen.dart';

class InjectProductionScreen extends StatefulWidget {
  const InjectProductionScreen({super.key});

  @override
  State<InjectProductionScreen> createState() =>
      _InjectProductionScreenState();
}

class _InjectProductionScreenState extends State<InjectProductionScreen> {
  final TextEditingController _searchCtl = TextEditingController();
  String? _selectedNoProduksi;

  // ✅ Store VM instance as field
  late final InjectProductionViewModel _viewModel;

  @override
  void initState() {
    super.initState();

    // ✅ Create VM once in initState
    _viewModel = InjectProductionViewModel(
      repository: InjectProductionRepository()
    );

    debugPrint(
      '🟦🟦🟦 [INJECT_SCREEN] initState: Created VM hash=${_viewModel.hashCode}',
    );
    debugPrint(
      '🟦🟦🟦 [INJECT_SCREEN] initState: PagingController hash=${_viewModel.pagingController.hashCode}',
    );

    // Initialize first load
    _viewModel.refreshPaged();
  }

  @override
  void dispose() {
    _searchCtl.dispose();
    _viewModel.dispose(); // ✅ Dispose VM
    super.dispose();
  }

  Future<void> _showRowPopover({
    required BuildContext context,
    required InjectProduction row,
    required Offset globalPos,
  }) async {
    final overlay =
    Overlay.maybeOf(context)?.context.findRenderObject() as RenderBox?;
    if (overlay == null) return;

    final local = overlay.globalToLocal(globalPos);

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black26,
      builder: (dialogCtx) {
        final safeLeft = local.dx.clamp(8.0, overlay.size.width - 320.0);
        final safeTop = local.dy.clamp(8.0, overlay.size.height - 220.0);

        return Stack(
          children: [
            Positioned(
              left: safeLeft,
              top: safeTop,
              child: InjectProductionRowPopover(
                row: row,
                onClose: () => Navigator.of(dialogCtx).pop(),
                onInput: () {
                  Future.microtask(() {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => InjectProductionInputScreen(
                          noProduksi: row.noProduksi,
                          isLocked: row.isLocked,
                          lastClosedDate: row.lastClosedDate,
                        ),
                      ),
                    );
                  });
                },
                onEdit: () async {
                  await _openEditDialog(context, row);
                },
                onDelete: () async {
                  await showDialog<void>(
                    context: context,
                    barrierDismissible: false,
                    builder: (ctx) {
                      return InjectProductionDeleteDialog(
                        header: row,
                        onConfirm: () async {
                          final success =
                          await _viewModel.deleteProduksi(row.noProduksi);

                          if (ctx.mounted) Navigator.of(ctx).pop();
                          if (!context.mounted) return;

                          if (success) {
                            showDialog(
                              context: context,
                              builder: (_) => SuccessStatusDialog(
                                title: 'Berhasil Menghapus',
                                message:
                                'No. Produksi ${row.noProduksi} berhasil dihapus.',
                              ),
                            );
                          } else {
                            final rawMsg =
                                _viewModel.saveError ?? 'Gagal menghapus data';
                            showDialog(
                              context: context,
                              builder: (_) => ErrorStatusDialog(
                                title: 'Gagal Menghapus!',
                                message: rawMsg,
                              ),
                            );
                          }
                        },
                      );
                    },
                  );
                },
                onPrint: () {
                  // TODO: kalau nanti ada cetak label inject
                },
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Use .value to provide existing VM instance
    return ChangeNotifierProvider<InjectProductionViewModel>.value(
      value: _viewModel,
      child: Consumer<InjectProductionViewModel>(
        builder: (context, vm, _) {
          debugPrint(
            '🟦 [INJECT_SCREEN] Consumer.builder() called, VM hash=${vm.hashCode}',
          );
          debugPrint(
            '🟦 [INJECT_SCREEN] Consumer pagingController: hash=${vm.pagingController.hashCode}',
          );

          final columns = <TableColumnSpec<InjectProduction>>[
            TableColumnSpec(
              title: 'NO. PRODUKSI',
              width: 170,
              headerAlign: TextAlign.left,
              cellAlign: TextAlign.left,
              cellBuilder: (_, r) => Text(
                r.noProduksi,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TableColumnSpec(
              title: 'TANGGAL',
              width: 130,
              headerAlign: TextAlign.left,
              cellAlign: TextAlign.left,
              cellBuilder: (_, r) => Text(formatDateToShortId(r.tglProduksi)),
            ),
            TableColumnSpec(
              title: 'SHIFT',
              width: 70,
              headerAlign: TextAlign.center,
              cellAlign: TextAlign.center,
              cellBuilder: (_, r) => Text('${r.shift}'),
            ),
            TableColumnSpec(
              title: 'MESIN',
              width: 180,
              cellBuilder: (_, r) => Text(
                r.namaMesin,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TableColumnSpec(
              title: 'OPERATOR',
              width: 200,
              cellBuilder: (_, r) => Text(
                r.namaOperator,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // ✅ JAM column (similar to Mixer's JAM KERJA)
            TableColumnSpec(
              title: 'JAM',
              width: 100,
              headerAlign: TextAlign.center,
              cellAlign: TextAlign.center,
              cellBuilder: (_, r) => Text(
                r.jam != null && r.jam! > 0 ? '${r.jam} jam' : '-',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TableColumnSpec(
              title: 'JAM KERJA',
              width: 140,
              headerAlign: TextAlign.center,
              cellAlign: TextAlign.center,
              cellBuilder: (_, r) => Text(
                '${r.hourStart ?? '--:--'} - ${r.hourEnd ?? '--:--'}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TableColumnSpec(
              title: 'HM',
              width: 80,
              headerAlign: TextAlign.right,
              cellAlign: TextAlign.right,
              cellBuilder: (_, r) => Text('${r.hourMeter ?? 0}'),
            ),
            TableColumnSpec(
              title: 'BERAT (kg)',
              width: 100,
              headerAlign: TextAlign.right,
              cellAlign: TextAlign.right,
              cellBuilder: (_, r) => Text('${r.beratProdukHasilTimbang ?? 0}'),
            ),
          ];

          return Scaffold(
            appBar: AppBar(
              title: const Text('Inject Production'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    debugPrint(
                      '🟦 [INJECT_SCREEN] Manual refresh button pressed, VM hash=${vm.hashCode}',
                    );
                    vm.refreshPaged();
                  },
                ),
              ],
            ),
            body: Column(
              children: [
                InjectProductionActionBar(
                  controller: _searchCtl,
                  onSearchChanged: (value) => vm.setSearchDebounced(value),
                  onClear: () {
                    _searchCtl.clear();
                    vm.clearFilters();
                  },
                  onAddPressed: _openCreateDialog,
                ),
                Expanded(
                  child: HorizontalPagedTable<InjectProduction>(
                    pagingController: vm.pagingController,
                    columns: columns,
                    horizontalPadding: 16,
                    selectedPredicate: (r) =>
                    r.noProduksi == _selectedNoProduksi,
                    onRowTap: (r) =>
                        setState(() => _selectedNoProduksi = r.noProduksi),
                    onRowLongPress: (r, globalPos) async {
                      await _showRowPopover(
                        context: context,
                        row: r,
                        globalPos: globalPos,
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _openCreateDialog() async {
    debugPrint('🟦 [INJECT_SCREEN] Opening create dialog...');
    debugPrint('🟦 [INJECT_SCREEN] Using VM hash=${_viewModel.hashCode}');
    debugPrint(
      '🟦 [INJECT_SCREEN] Using controller hash=${_viewModel.pagingController.hashCode}',
    );

    if (!mounted) return;

    final created = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        debugPrint('🟦 [INJECT_SCREEN] Building create dialog...');

        // ✅ MultiProvider: Share VM + provide dependencies for form
        return MultiProvider(
          providers: [
            // Main VM - use .value to share existing instance
            ChangeNotifierProvider<InjectProductionViewModel>.value(
              value: _viewModel,
            ),
            // Dependencies for form - create new instances
            ChangeNotifierProvider(
              create: (_) => CetakanViewModel(repository: CetakanRepository()),
            ),
            ChangeNotifierProvider(
              create: (_) => WarnaViewModel(repository: WarnaRepository()),
            ),
            ChangeNotifierProvider(
              create: (_) => FurnitureMaterialLookupViewModel(
                repository: FurnitureMaterialLookupRepository(),
              ),
            ),
          ],
          child: const InjectProductionFormDialog(),
        );
      },
    );

    debugPrint('🟦 [INJECT_SCREEN] Dialog closed, result: $created');

    if (!mounted) return;

    if (created == true) {
      debugPrint('🟦 [INJECT_SCREEN] Success detected (create).');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Produksi inject berhasil dibuat'),
        ),
      );
    } else {
      debugPrint('🟦 [INJECT_SCREEN] Result was null or false: $created');
    }
  }

  Future<void> _openEditDialog(
      BuildContext context,
      InjectProduction row,
      ) async {
    debugPrint(
        '🟦 [INJECT_SCREEN] Opening edit dialog for: ${row.noProduksi}');
    debugPrint('🟦 [INJECT_SCREEN] Using VM hash=${_viewModel.hashCode}');
    debugPrint(
      '🟦 [INJECT_SCREEN] Using controller hash=${_viewModel.pagingController.hashCode}',
    );

    if (!mounted) return;

    final updated = await showDialog<InjectProduction>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        debugPrint('🟦 [INJECT_SCREEN] Building edit dialog...');

        // ✅ MultiProvider: Share VM + provide dependencies for form
        return MultiProvider(
          providers: [
            // Main VM - use .value to share existing instance
            ChangeNotifierProvider<InjectProductionViewModel>.value(
              value: _viewModel,
            ),
            // Dependencies for form - create new instances
            ChangeNotifierProvider(
              create: (_) => CetakanViewModel(repository: CetakanRepository()),
            ),
            ChangeNotifierProvider(
              create: (_) => WarnaViewModel(repository: WarnaRepository()),
            ),
            ChangeNotifierProvider(
              create: (_) => FurnitureMaterialLookupViewModel(
                repository: FurnitureMaterialLookupRepository(),
              ),
            ),
          ],
          child: InjectProductionFormDialog(
            header: row,
          ),
        );
      },
    );

    debugPrint(
      '🟦 [INJECT_SCREEN] Edit dialog closed, result: ${updated?.noProduksi}',
    );

    if (!mounted) return;

    if (updated != null) {
      debugPrint('🟦 [INJECT_SCREEN] Success detected (update).');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No. Produksi ${updated.noProduksi} berhasil diperbarui',
          ),
        ),
      );
    } else {
      debugPrint('🟦 [INJECT_SCREEN] Result was null');
    }
  }
}