// lib/features/production/inject/view/inject_production_screen.dart

import 'package:flutter/material.dart';
import 'package:pps_tablet/features/audit/view/audit_screen_with_prefilled.dart';
import 'package:pps_tablet/features/production/inject/repository/inject_production_repository.dart';
import 'package:provider/provider.dart';

import '../../../../common/widgets/error_status_dialog.dart';
import '../../../../common/widgets/success_status_dialog.dart';

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
import '../widgets/inject_production_header_table.dart';
import '../widgets/inject_production_row_popover.dart';
import 'inject_production_input_screen.dart';

class InjectProductionScreen extends StatefulWidget {
  const InjectProductionScreen({super.key});

  @override
  State<InjectProductionScreen> createState() => _InjectProductionScreenState();
}

class _InjectProductionScreenState extends State<InjectProductionScreen> {
  final TextEditingController _searchCtl = TextEditingController();
  String? _selectedNoProduksi;

  late final InjectProductionViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = InjectProductionViewModel(
      repository: InjectProductionRepository(),
    );
    _viewModel.refreshPaged();
  }

  @override
  void dispose() {
    _searchCtl.dispose();
    _viewModel.dispose();
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
                          final success = await _viewModel.deleteProduksi(
                            row.noProduksi,
                          );

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
                            showDialog(
                              context: context,
                              builder: (_) => ErrorStatusDialog(
                                title: 'Gagal Menghapus!',
                                message:
                                    _viewModel.saveError ??
                                    'Gagal menghapus data',
                              ),
                            );
                          }
                        },
                      );
                    },
                  );
                },
                onPrint: () {},
                onAuditHistory: () {
                  _navigateToAuditHistory(row);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _navigateToAuditHistory(InjectProduction header) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            AuditScreenWithPrefilledDoc(documentNo: header.noProduksi),
      ),
    );
  }

  Future<void> _openCreateDialog(BuildContext ctx) async {
    final created = await showDialog<InjectProduction>(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => MultiProvider(
        providers: [
          ChangeNotifierProvider<InjectProductionViewModel>.value(
            value: _viewModel,
          ),
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
      ),
    );
    if (!mounted || !ctx.mounted) return;
    if (created != null) {
      _viewModel.refreshPaged();
      setState(() => _selectedNoProduksi = created.noProduksi);
      showDialog(
        context: ctx,
        builder: (_) => SuccessStatusDialog(
          title: 'Berhasil Membuat',
          message: 'No. Produksi ${created.noProduksi} berhasil dibuat.',
        ),
      );
    }
  }

  Future<void> _openEditDialog(
    BuildContext ctx,
    InjectProduction row,
  ) async {
    final updated = await showDialog<InjectProduction>(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => MultiProvider(
        providers: [
          ChangeNotifierProvider<InjectProductionViewModel>.value(
            value: _viewModel,
          ),
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
        child: InjectProductionFormDialog(header: row),
      ),
    );
    if (!mounted || !ctx.mounted) return;
    if (updated != null) {
      _viewModel.refreshPaged();
      showDialog(
        context: ctx,
        builder: (_) => SuccessStatusDialog(
          title: 'Berhasil Mengupdate',
          message: 'No. Produksi ${updated.noProduksi} berhasil diperbarui.',
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<InjectProductionViewModel>.value(
      value: _viewModel,
      child: Consumer<InjectProductionViewModel>(
        builder: (context, vm, _) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Inject Production'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh',
                  onPressed: vm.refreshPaged,
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
                  onAddPressed: () => _openCreateDialog(context),
                ),
                Expanded(
                  child: InjectProductionHeaderTable(
                    selectedNoProduksi: _selectedNoProduksi,
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
}
