import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pps_tablet/features/production/broker/view_model/broker_production_input_view_model.dart';
import '../../../../common/widgets/qr_scanner_panel.dart';
import '../widgets/inputs_group_popover.dart';
import '../model/broker_inputs_model.dart';

class BrokerInputsScreen extends StatefulWidget {
  final String noProduksi;

  const BrokerInputsScreen({
    super.key,
    required this.noProduksi,
  });

  @override
  State<BrokerInputsScreen> createState() => _BrokerInputsScreenState();
}

class _BrokerInputsScreenState extends State<BrokerInputsScreen> {
  final _formKey = GlobalKey<FormState>();

  /// Mode pilihan: 'full' | 'select' | 'partial'
  String _selectedMode = 'full';

  /// Hasil QR terbaru (baik dari scan maupun input manual)
  String? _scannedCode;

  /// Kendali untuk menampilkan panel scanner. Default: false (tidak auto open camera)
  bool _scanActive = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<BrokerProductionInputViewModel>();
      final already = vm.inputsOf(widget.noProduksi) != null;
      final loading = vm.isInputsLoading(widget.noProduksi);
      if (!already && !loading) {
        vm.loadInputs(widget.noProduksi);
      }
    });
  }

  String _num(double? v) => v == null ? '-' : v.toStringAsFixed(2);

  void _startScan() {
    setState(() {
      _scanActive = true;
    });
  }

  void _stopScan() {
    setState(() {
      _scanActive = false;
    });
  }

  Future<void> _showManualInputDialog() async {
    final ctl = TextEditingController(text: _scannedCode ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Input Manual Kode Label'),
          content: TextField(
            controller: ctl,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Kode label',
              hintText: 'cth: F.BROKER-2025-000123',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            autofocus: true,
            onSubmitted: (_) => Navigator.of(ctx).pop(ctl.text.trim()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(ctx).pop(ctl.text.trim()),
              icon: const Icon(Icons.check),
              label: const Text('Pakai'),
            ),
          ],
        );
      },
    );

    if (!mounted) return;

    if (result != null && result.isNotEmpty) {
      setState(() {
        _scannedCode = result;
        _scanActive = false; // pastikan kamera mati setelah input manual
      });
      _showSnack('Kode ter-set: $result');
    }
  }

  void _clearCode() {
    setState(() => _scannedCode = null);
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  /// Utility: groupBy generic
  Map<K, List<T>> _groupBy<T, K>(Iterable<T> items, K Function(T) keyOf) {
    final map = <K, List<T>>{};
    for (final item in items) {
      final k = keyOf(item);
      map.putIfAbsent(k, () => <T>[]).add(item);
    }
    return map;
  }

  /// ===== NEW: Title key for BB =====
  /// If partial row -> use noBBPartial as the TITLE (like noBahanBaku)
  /// Else -> use noBahanBaku (optionally with pallet suffix)
  String _bbTitleKey(BbItem e) {
    if (e.isPartialRow) {
      final npart = (e.noBBPartial ?? '').trim();
      return npart.isEmpty ? '-' : npart; // title = noBBPartial
    }
    final nb = (e.noBahanBaku ?? '').trim();
    final np = e.noPallet; // int?

    final hasNb = nb.isNotEmpty;
    final hasNp = (np != null && np > 0);

    if (!hasNb && !hasNp) return '-';
    if (hasNb && hasNp) return '$nb-$np';
    if (hasNb) return nb;
    return 'Pallet $np';
  }


  /// ===== NEW: Title key for Gilingan =====
  /// Jika partial -> pakai noGilinganPartial
  /// Jika bukan partial -> pakai noGilingan
  String _gilinganTitleKey(GilinganItem e) {
    if (e.isPartialRow) {
      final np = (e.noGilinganPartial ?? '').trim();
      return np.isEmpty ? '-' : np; // title = noGilinganPartial
    }
    final ng = (e.noGilingan ?? '').trim();
    return ng.isEmpty ? '-' : ng;   // title = noGilingan
  }


  /// ===== NEW: Title key for Mixer =====
  /// Partial -> pakai noMixerPartial
  /// Non-partial -> pakai noMixer + optional suffix -noSak
  String _mixerTitleKey(MixerItem e) {
    if (e.isPartialRow) {
      final np = (e.noMixerPartial ?? '').trim();
      return np.isEmpty ? '-' : np; // title = noMixerPartial
    }

    final nm = (e.noMixer ?? '').trim();
    final ns = e.noSak; // int?

    final hasNm = nm.isNotEmpty;
    final hasNs = (ns != null && ns > 0);

    if (!hasNm && !hasNs) return '-';
    if (hasNm && hasNs) return '$nm-$ns';
    if (hasNm) return nm;
    return 'Sak $ns';
  }


  /// ===== NEW: Title key for Reject =====
  /// Partial -> pakai noRejectPartial
  /// Non-partial -> pakai noReject
  String _rejectTitleKey(RejectItem e) {
    if (e.isPartialRow) {
      final np = (e.noRejectPartial ?? '').trim();
      return np.isEmpty ? '-' : np; // title = noRejectPartial
    }
    final nr = (e.noReject ?? '').trim();
    return nr.isEmpty ? '-' : nr;   // title = noReject
  }



  String _bbPairLabel(BbItem i) {
    final nb = (i.noBahanBaku ?? '').trim();
    final partRaw = (i.noSak.toString() ?? '').trim();

    // PARTIAL ROW: want "<noBahanBaku>-<partialNumber>"
    if (i.isPartialRow) {
      if (nb.isEmpty && partRaw.isEmpty) return '-';
      // If noBBPartial already looks like "A.000000101-1", just use it
      if (nb.isNotEmpty && partRaw.startsWith('$nb-')) return partRaw;

      // Otherwise, take the last segment as the partial number
      final suffix = () {
        final idx = partRaw.lastIndexOf('-');
        return idx == -1 ? partRaw : partRaw.substring(idx + 1);
      }();

      if (nb.isEmpty) return partRaw.isEmpty ? '-' : partRaw;
      return suffix.isEmpty ? nb : '$nb-$suffix';
    }

    // NON-PARTIAL ROW: want "<noBahanBaku>-<noPallet>" when pallet exists
    final pallet = i.noPallet;
    if (nb.isEmpty && pallet == null) return '-';
    return (pallet == null) ? nb : '$nb-$pallet';
  }


  @override
  Widget build(BuildContext context) {
    return Consumer<BrokerProductionInputViewModel>(
      builder: (context, vm, _) {
        final loading = vm.isInputsLoading(widget.noProduksi);
        final err = vm.inputsError(widget.noProduksi);
        final inputs = vm.inputsOf(widget.noProduksi);

        return Scaffold(
          appBar: AppBar(
            title: Text('Inputs • ${widget.noProduksi}'),
            actions: [
              IconButton(
                tooltip: 'Refresh Inputs',
                icon: const Icon(Icons.refresh),
                onPressed: () => vm.loadInputs(widget.noProduksi, force: true),
              ),
            ],
          ),
          body: Builder(
            builder: (_) {
              if (loading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (err != null) {
                return Center(child: Text('Gagal memuat inputs:\n$err'));
              }
              if (inputs == null) {
                return const Center(child: Text('Tidak ada data inputs.'));
              }

              // ===== GROUPED =====
              final brokerGroups = _groupBy(inputs.broker, (e) => e.noBroker ?? '-');

              // ✅ BAHAN BAKU: Title uses noBBPartial for partial rows
              final bbGroups = _groupBy(inputs.bb, _bbTitleKey);

              final washingGroups = _groupBy(inputs.washing, (e) => e.noWashing ?? '-');
              final crusherGroups = _groupBy(inputs.crusher, (e) => e.noCrusher ?? '-');
              final gilinganGroups = _groupBy(inputs.gilingan, _gilinganTitleKey);
              final mixerGroups = _groupBy(inputs.mixer, _mixerTitleKey);
              final rejectGroups = _groupBy(inputs.reject, _rejectTitleKey);

              return Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // SECTION KIRI: Scan / Manual
                    SizedBox(
                      width: 380,
                      child: Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Form(
                            key: _formKey,
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(
                                children: [
                                  Icon(Icons.qr_code_scanner, color: Colors.blue.shade700),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Input via Scan / Manual',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 24),

                              const Text('Pilih Mode', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: _selectedMode,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  isDense: true,
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'full', child: Text('FULL PALLET')),
                                  DropdownMenuItem(value: 'select', child: Text('SEBAGIAN PALLET')),
                                  DropdownMenuItem(value: 'partial', child: Text('PARTIAL')),
                                ],
                                onChanged: (val) {
                                  if (val == null) return;
                                  setState(() => _selectedMode = val);
                                },
                              ),

                              const SizedBox(height: 16),

                              Row(children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _scanActive ? null : _startScan,
                                    icon: const Icon(Icons.center_focus_strong),
                                    label: const Text('Start Scan'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _showManualInputDialog,
                                    icon: const Icon(Icons.keyboard),
                                    label: const Text('Input Manual'),
                                  ),
                                ),
                              ]),

                              const SizedBox(height: 12),

                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 250),
                                child: _scanActive
                                    ? Column(
                                  key: const ValueKey('scanner'),
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    const Text('Scan QR', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 8),
                                    QrScannerPanel(
                                      onDetected: (code) {
                                        setState(() {
                                          _scannedCode = code;
                                          _scanActive = false;
                                        });
                                        _showSnack('Scan berhasil: $code');
                                      },
                                      scanOnce: true,
                                      debounceMs: 800,
                                      height: 220,
                                      showOverlay: true,
                                    ),
                                    const SizedBox(height: 8),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton.icon(
                                        onPressed: _stopScan,
                                        icon: const Icon(Icons.close),
                                        label: const Text('Tutup Kamera'),
                                      ),
                                    ),
                                  ],
                                )
                                    : _ScannerPlaceholder(
                                  key: const ValueKey('placeholder'),
                                  lastCode: _scannedCode,
                                ),
                              ),

                              const SizedBox(height: 8),
                              if (_scannedCode != null)
                                Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade50,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.green.shade200),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.check_circle, size: 16, color: Colors.green),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                _scannedCode!,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                              ),
                                            ),
                                            IconButton(
                                              tooltip: 'Hapus',
                                              icon: const Icon(Icons.clear, size: 18),
                                              onPressed: _clearCode,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                            ]),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // SECTION KANAN: Data Cards
                    Expanded(
                      child: Column(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                // BROKER
                                Expanded(
                                  child: _SectionCard(
                                    title: 'Broker',
                                    count: brokerGroups.length,
                                    color: Colors.blue,
                                    child: brokerGroups.isEmpty
                                        ? const Center(child: Text('Tidak ada data', style: TextStyle(fontSize: 11)))
                                        : ListView(
                                      padding: const EdgeInsets.all(8),
                                      children: brokerGroups.entries.map((entry) {
                                        final details = <Widget>[
                                          for (final i in entry.value) ...[
                                            _DataRow('Sak', i.noSak?.toString() ?? '-'),
                                            _DataRow('Berat', _num(i.berat)),
                                            const SizedBox(height: 6),
                                          ]
                                        ];
                                        return GroupTooltipAnchorTile(
                                          title: entry.key,
                                          headerSubtitle: (entry.value.isNotEmpty ? entry.value.first.namaJenis : '-') ?? '-',
                                          color: Colors.blue,
                                          details: details,
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // BAHAN BAKU
                                Expanded(
                                  child: _SectionCard(
                                    title: 'Bahan Baku',
                                    count: bbGroups.length,
                                    color: Colors.green,
                                    child: bbGroups.isEmpty
                                        ? const Center(child: Text('Tidak ada data', style: TextStyle(fontSize: 11)))
                                        : ListView(
                                      padding: const EdgeInsets.all(8),
                                      children: bbGroups.entries.map((entry) {
                                        final details = <Widget>[];
                                        for (final i in entry.value) {
                                          if (i.isPartialRow) {
                                            // TITLE = noBBPartial; show origin info inside
                                            details.addAll([
                                              _DataRow('No BB', _bbPairLabel(i)),   // ⬅️ here
                                              _DataRow('Sak', i.noSak?.toString() ?? '-'),
                                              _DataRow('Berat', _num(i.berat)),
                                              _DataRow('Berat', _num(i.berat)),
                                              const SizedBox(height: 6),
                                            ]);
                                          } else {
                                            // TITLE = noBahanBaku (maybe with pallet suffix)
                                            details.addAll([
                                              _DataRow('Sak', i.noSak?.toString() ?? '-'),
                                              _DataRow('Berat', _num(i.berat)),
                                              const SizedBox(height: 6),
                                            ]);
                                          }
                                        }
                                        return GroupTooltipAnchorTile(
                                          title: entry.key, // noBBPartial OR noBahanBaku (w/ pallet suffix)
                                          headerSubtitle: (entry.value.isNotEmpty ? entry.value.first.namaJenis : '-') ?? '-',
                                          color: Colors.green,
                                          details: details,
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // WASHING
                                Expanded(
                                  child: _SectionCard(
                                    title: 'Washing',
                                    count: washingGroups.length,
                                    color: Colors.cyan,
                                    child: washingGroups.isEmpty
                                        ? const Center(child: Text('Tidak ada data', style: TextStyle(fontSize: 11)))
                                        : ListView(
                                      padding: const EdgeInsets.all(8),
                                      children: washingGroups.entries.map((entry) {
                                        final details = <Widget>[
                                          for (final i in entry.value) ...[
                                            _DataRow('Sak', i.noSak?.toString() ?? '-'),
                                            _DataRow('Berat', _num(i.berat)),
                                            const SizedBox(height: 6),
                                          ]
                                        ];
                                        return GroupTooltipAnchorTile(
                                          title: entry.key,
                                          headerSubtitle: (entry.value.isNotEmpty ? entry.value.first.namaJenis : '-') ?? '-',
                                          color: Colors.cyan,
                                          details: details,
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // CRUSHER
                                Expanded(
                                  child: _SectionCard(
                                    title: 'Crusher',
                                    count: crusherGroups.length,
                                    color: Colors.orange,
                                    child: crusherGroups.isEmpty
                                        ? const Center(child: Text('Tidak ada data', style: TextStyle(fontSize: 11)))
                                        : ListView(
                                      padding: const EdgeInsets.all(8),
                                      children: crusherGroups.entries.map((entry) {
                                        final details = <Widget>[
                                          for (final i in entry.value) ...[
                                            _DataRow('Berat', _num(i.berat)),
                                            const SizedBox(height: 6),
                                          ]
                                        ];
                                        return GroupTooltipAnchorTile(
                                          title: entry.key,
                                          headerSubtitle: (entry.value.isNotEmpty ? entry.value.first.namaJenis : '-') ?? '-',
                                          color: Colors.orange,
                                          details: details,
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: Row(
                              children: [
                                // GILINGAN
                                Expanded(
                                  child: _SectionCard(
                                    title: 'Gilingan',
                                    count: gilinganGroups.length,
                                    color: Colors.green,
                                    child: gilinganGroups.isEmpty
                                        ? const Center(child: Text('Tidak ada data', style: TextStyle(fontSize: 11)))
                                        : ListView(
                                      padding: const EdgeInsets.all(8),
                                      children: gilinganGroups.entries.map((entry) {
                                        final details = <Widget>[];
                                        for (final i in entry.value) {
                                          if (i.isPartialRow) {
                                            // TITLE = noBBPartial; show origin info inside
                                            details.addAll([
                                              _DataRow('No Gilingan', i.noGilingan.toString()),   // ⬅️ here
                                              _DataRow('Berat', _num(i.berat)),
                                              const SizedBox(height: 6),
                                            ]);
                                          } else {
                                            // TITLE = noBahanBaku (maybe with pallet suffix)
                                            details.addAll([
                                              _DataRow('Berat', _num(i.berat)),
                                              const SizedBox(height: 6),
                                            ]);
                                          }
                                        }
                                        return GroupTooltipAnchorTile(
                                          title: entry.key, // noGilinganPartial OR noGilingan (w/ pallet suffix)
                                          headerSubtitle: (entry.value.isNotEmpty ? entry.value.first.namaJenis : '-') ?? '-',
                                          color: Colors.green,
                                          details: details,
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // MIXER
                                Expanded(
                                  child: _SectionCard(
                                    title: 'Mixer',
                                    count: mixerGroups.length,
                                    color: Colors.teal,
                                    child: mixerGroups.isEmpty
                                        ? const Center(child: Text('Tidak ada data', style: TextStyle(fontSize: 11)))
                                        : ListView(
                                      padding: const EdgeInsets.all(8),
                                      children: mixerGroups.entries.map((entry) {
                                        final details = <Widget>[
                                          for (final i in entry.value) ...[
                                            _DataRow('No. Partial', i.noMixerPartial ?? '-'),
                                            _DataRow('Berat', _num(i.berat)),
                                            const SizedBox(height: 6),
                                          ]
                                        ];
                                        return GroupTooltipAnchorTile(
                                          title: entry.key,
                                          headerSubtitle: (entry.value.isNotEmpty ? entry.value.first.namaJenis : '-') ?? '-',
                                          color: Colors.teal,
                                          details: details,
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // REJECT
                                Expanded(
                                  child: _SectionCard(
                                    title: 'Reject',
                                    count: rejectGroups.length,
                                    color: Colors.red,
                                    child: rejectGroups.isEmpty
                                        ? const Center(child: Text('Tidak ada data', style: TextStyle(fontSize: 11)))
                                        : ListView(
                                      padding: const EdgeInsets.all(8),
                                      children: rejectGroups.entries.map((entry) {
                                        final details = <Widget>[
                                          for (final i in entry.value) ...[
                                            _DataRow('No. Partial', i.noRejectPartial ?? '-'),
                                            _DataRow('Berat', _num(i.berat)),
                                            const SizedBox(height: 6),
                                          ]
                                        ];
                                        return GroupTooltipAnchorTile(
                                          title: entry.key,
                                          headerSubtitle: (entry.value.isNotEmpty ? entry.value.first.namaJenis : '-') ?? '-',
                                          color: Colors.red,
                                          details: details,
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _ScannerPlaceholder extends StatelessWidget {
  final String? lastCode;
  const _ScannerPlaceholder({super.key, this.lastCode});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.camera_alt_outlined, size: 40, color: Colors.grey),
            const SizedBox(height: 8),
            Text(
              'Kamera belum dinyalakan',
              style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'Tekan “Start Scan” atau pilih “Input Manual”',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            if (lastCode != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.history, size: 16, color: Colors.green),
                    const SizedBox(width: 6),
                    Text(
                      lastCode!,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final int count;
  final Color color;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.count,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              border: Border(
                bottom: BorderSide(color: color.withOpacity(0.3)),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.folder_outlined, size: 16, color: color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  final String label;
  final String value;

  const _DataRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Text(': ', style: TextStyle(fontSize: 11)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
