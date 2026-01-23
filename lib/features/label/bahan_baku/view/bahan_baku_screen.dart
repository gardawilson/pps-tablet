// lib/features/production/bahan_baku/view/bahan_baku_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../model/bahan_baku_header.dart';
import '../model/bahan_baku_pallet.dart';
import '../view_model/bahan_baku_view_model.dart';
import '../widgets/bahan_baku_action_bar.dart';
import '../widgets/bahan_baku_header_table.dart';
import '../widgets/bahan_baku_pallet_table.dart';
import '../widgets/bahan_baku_pallet_detail_table.dart';

class BahanBakuScreen extends StatefulWidget {
  const BahanBakuScreen({super.key});

  @override
  State<BahanBakuScreen> createState() => _BahanBakuScreenState();
}

class _BahanBakuScreenState extends State<BahanBakuScreen> {
  final TextEditingController searchCtrl = TextEditingController();
  final ScrollController _headerScrollController = ScrollController();
  final ScrollController _palletScrollController = ScrollController();
  final ScrollController _detailScrollController = ScrollController();

  bool _isLoadingMore = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BahanBakuViewModel>().fetchBahanBakuHeaders();
      context.read<BahanBakuViewModel>().resetForScreen();
    });
    _headerScrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _headerScrollController.dispose();
    _palletScrollController.dispose();
    _detailScrollController.dispose();
    searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    final vm = context.read<BahanBakuViewModel>();
    if (_headerScrollController.position.pixels >=
        _headerScrollController.position.maxScrollExtent - 100) {
      if (!_isLoadingMore && vm.hasMore) {
        _isLoadingMore = true;
        vm.loadMore().then((_) {
          if (mounted) {
            setState(() {
              _isLoadingMore = false;
            });
          }
        });
      }
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      context.read<BahanBakuViewModel>().fetchBahanBakuHeaders(search: query);
      if (_headerScrollController.hasClients) {
        _headerScrollController.jumpTo(0);
      }
    });
  }

  void _onHeaderTap(BahanBakuHeader header) {
    final vm = context.read<BahanBakuViewModel>();
    vm.fetchPallets(header.noBahanBaku);

    if (_palletScrollController.hasClients) {
      _palletScrollController.jumpTo(0);
    }
  }

  void _onPalletTap(BahanBakuPallet pallet) {
    final vm = context.read<BahanBakuViewModel>();
    final noBahanBaku = vm.currentNoBahanBaku;

    if (noBahanBaku == null) {
      debugPrint('⚠️ NoBahanBaku is null, cannot load pallet details');
      return;
    }

    vm.fetchPalletDetails(
      noBahanBaku: noBahanBaku,
      noPallet: pallet.noPallet,
    );

    if (_detailScrollController.hasClients) {
      _detailScrollController.jumpTo(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        elevation: 2,
        title: Consumer<BahanBakuViewModel>(
          builder: (_, vm, __) {
            final label = vm.isLoading && vm.items.isEmpty
                ? 'LABEL BAHAN BAKU (…)'
                : 'LABEL BAHAN BAKU (${vm.totalCount})';
            return Text(
              label,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            );
          },
        ),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: Row(
        children: [
          // 1️⃣ Header Table (Kiri) - FLEX DIKURANGI
          Expanded(
            flex: 5, // ⬅️ dari 3 ke 5 untuk lebih lebar
            child: Container(
              color: Colors.white,
              child: Column(
                children: [
                  BahanBakuActionBar(
                    controller: searchCtrl,
                    onSearchChanged: _onSearchChanged,
                    onClear: () {
                      searchCtrl.clear();
                      context
                          .read<BahanBakuViewModel>()
                          .fetchBahanBakuHeaders(search: "");
                    },
                  ),
                  Expanded(
                    child: BahanBakuHeaderTable(
                      scrollController: _headerScrollController,
                      onItemTap: _onHeaderTap,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Divider 1
          Container(width: 1, color: Colors.grey.shade300),

          // 2️⃣ Pallet Table (Tengah)
          Expanded(
            flex: 4, // ⬅️ dari 2 ke 4
            child: BahanBakuPalletTable(
              scrollController: _palletScrollController,
              onPalletTap: _onPalletTap,
            ),
          ),

          // Divider 2
          Container(width: 1, color: Colors.grey.shade300),

          // 3️⃣ Detail Table (Kanan)
          Expanded(
            flex: 2, // ⬅️ dari 1 ke 2
            child: BahanBakuPalletDetailTable(
              scrollController: _detailScrollController,
            ),
          ),
        ],
      ),
    );
  }
}