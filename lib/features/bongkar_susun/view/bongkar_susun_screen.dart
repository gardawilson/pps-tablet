// lib/features/shared/bongkar_susun/view/bongkar_susun_screen.dart
import 'package:flutter/material.dart';
import 'package:pps_tablet/features/bongkar_susun/view/bongkar_susun_input_screen.dart';
import 'package:provider/provider.dart';

import '../../../../common/widgets/error_status_dialog.dart';
import '../../../../common/widgets/horizontal_paged_table.dart';
import '../../../../common/widgets/success_status_dialog.dart';
import '../../../../common/widgets/table_column_spec.dart';
import '../../../../core/utils/date_formatter.dart';

import '../../production/broker/view/broker_production_input_screen.dart';
import '../model/bongkar_susun_model.dart';
import '../repository/bongkar_susun_repository.dart';
import '../view_model/bongkar_susun_view_model.dart';

// Action bar
import '../widgets/bongkar_susun_action_bar.dart';
import '../widgets/bongkar_susun_delete_dialog.dart';
import '../widgets/bongkar_susun_form_dialog.dart';
import '../widgets/bongkar_susun_row_popover.dart';

class BongkarSusunScreen extends StatefulWidget {
  const BongkarSusunScreen({super.key});

  @override
  State<BongkarSusunScreen> createState() => _BongkarSusunScreenState();
}

class _BongkarSusunScreenState extends State<BongkarSusunScreen> {
  final TextEditingController _searchCtl = TextEditingController();
  String? _selectedNoBongkarSusun;

  // ✅ Store VM instance as field
  late final BongkarSusunViewModel _viewModel;

  @override
  void initState() {
    super.initState();

    // ✅ Screen hanya tahu tentang ViewModel, tidak peduli repository
    _viewModel = BongkarSusunViewModel();  // ← Clean!

    debugPrint(
      '🟦🟦🟦 [SCREEN] initState: Created VM hash=${_viewModel.hashCode}',
    );
    debugPrint(
      '🟦🟦🟦 [SCREEN] initState: PagingController hash=${_viewModel.pagingController.hashCode}',
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
    required BongkarSusun row,
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
              child: BongkarSusunRowPopover(
                row: row,
                onClose: () => Navigator.of(dialogCtx).pop(),
                onInput: () {
                  // popover sudah tertutup oleh _runAndClose di dalam popover
                  Future.microtask(() {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BongkarSusunInputScreen(
                          noBongkarSusun: row.noBongkarSusun,
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
                      return BongkarSusunDeleteDialog(
                        header: row,
                        onConfirm: () async {
                          final success =
                          await _viewModel.deleteBongkarSusun(row.noBongkarSusun);

                          if (ctx.mounted) Navigator.of(ctx).pop();
                          if (!context.mounted) return;

                          if (success) {
                            showDialog(
                              context: context,
                              builder: (_) => SuccessStatusDialog(
                                title: 'Berhasil Menghapus',
                                message:
                                'No. Bongkar/Susun ${row.noBongkarSusun} berhasil dihapus.',
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
    return ChangeNotifierProvider<BongkarSusunViewModel>.value(
      value: _viewModel,
      child: Consumer<BongkarSusunViewModel>(
        builder: (context, vm, _) {
          debugPrint(
            '🟦 [SCREEN] Consumer.builder() called, VM hash=${vm.hashCode}',
          );
          debugPrint(
            '🟦 [SCREEN] Consumer pagingController: hash=${vm.pagingController.hashCode}',
          );

          final columns = <TableColumnSpec<BongkarSusun>>[
            TableColumnSpec(
              title: 'NO. BS',
              width: 180,
              headerAlign: TextAlign.left,
              cellAlign: TextAlign.left,
              cellBuilder: (_, r) => Text(
                r.noBongkarSusun,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TableColumnSpec(
              title: 'TANGGAL',
              width: 130,
              headerAlign: TextAlign.left,
              cellAlign: TextAlign.left,
              cellBuilder: (_, r) => Text(formatDateToShortId(r.tanggal)),
            ),
            TableColumnSpec(
              title: 'CREATED BY',
              width: 130,
              headerAlign: TextAlign.center,
              cellAlign: TextAlign.center,
              cellBuilder: (_, r) => Text('${r.username}'),
            ),
            TableColumnSpec(
              title: 'CATATAN',
              width: 300,
              headerAlign: TextAlign.left,
              cellAlign: TextAlign.left,
              cellBuilder: (_, r) => Text(
                r.note ?? '-',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.black87),
              ),
            ),
          ];

          return Scaffold(
            appBar: AppBar(
              title: const Text('Bongkar Susun'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    debugPrint(
                      '🟦 [SCREEN] Manual refresh button pressed, VM hash=${vm.hashCode}',
                    );
                    vm.refreshPaged();
                  },
                ),
              ],
            ),
            body: Column(
              children: [
                BongkarSusunActionBar(
                  controller: _searchCtl,
                  onSearchChanged: (value) => vm.setSearchDebounced(value),
                  onClear: () {
                    _searchCtl.clear();
                    vm.clearFilters();
                  },
                  onAddPressed: _openCreateDialog,
                ),
                Expanded(
                  child: HorizontalPagedTable<BongkarSusun>(
                    pagingController: vm.pagingController,
                    columns: columns,
                    horizontalPadding: 16,
                    selectedPredicate: (r) =>
                    r.noBongkarSusun == _selectedNoBongkarSusun,
                    onRowTap: (r) => setState(
                          () => _selectedNoBongkarSusun = r.noBongkarSusun,
                    ),
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
    debugPrint('🟦 [SCREEN] Opening create dialog...');
    debugPrint('🟦 [SCREEN] Using VM hash=${_viewModel.hashCode}');
    debugPrint(
      '🟦 [SCREEN] Using controller hash=${_viewModel.pagingController.hashCode}',
    );

    if (!mounted) return;

    final created = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        debugPrint('🟦 [SCREEN] Building create dialog...');

        // ✅ Share the SAME VM instance using .value
        return ChangeNotifierProvider<BongkarSusunViewModel>.value(
          value: _viewModel,
          child: const BongkarSusunFormDialog(),
        );
      },
    );

    debugPrint('🟦 [SCREEN] Dialog closed, result: $created');

    if (!mounted) return;

    if (created == true) {
      debugPrint('🟦 [SCREEN] Success detected (create).');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bongkar/Susun berhasil dibuat'),
        ),
      );
    } else {
      debugPrint('🟦 [SCREEN] Result was null or false: $created');
    }
  }

  Future<void> _openEditDialog(
      BuildContext context,
      BongkarSusun row,
      ) async {
    debugPrint('🟦 [SCREEN] Opening edit dialog for: ${row.noBongkarSusun}');
    debugPrint('🟦 [SCREEN] Using VM hash=${_viewModel.hashCode}');
    debugPrint(
      '🟦 [SCREEN] Using controller hash=${_viewModel.pagingController.hashCode}',
    );

    if (!mounted) return;

    final updated = await showDialog<BongkarSusun>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        debugPrint('🟦 [SCREEN] Building edit dialog...');

        // ✅ Share the SAME VM instance
        return ChangeNotifierProvider<BongkarSusunViewModel>.value(
          value: _viewModel,
          child: BongkarSusunFormDialog(
            header: row,
          ),
        );
      },
    );

    debugPrint(
      '🟦 [SCREEN] Edit dialog closed, result: ${updated?.noBongkarSusun}',
    );

    if (!mounted) return;

    if (updated != null) {
      debugPrint('🟦 [SCREEN] Success detected (update).');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No. Bongkar/Susun ${updated.noBongkarSusun} berhasil diperbarui',
          ),
        ),
      );
    } else {
      debugPrint('🟦 [SCREEN] Result was null');
    }
  }
}