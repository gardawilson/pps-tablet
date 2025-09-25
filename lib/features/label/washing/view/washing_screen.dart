import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../view_model/washing_view_model.dart';


class WashingListScreen extends StatelessWidget {
  const WashingListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Washing List")),
      body: Consumer<WashingViewModel>(
        builder: (context, vm, _) {
          if (vm.isLoading) return const Center(child: CircularProgressIndicator());
          if (vm.errorMessage.isNotEmpty) return Center(child: Text(vm.errorMessage));

          return ListView.separated(
            itemCount: vm.items.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final item = vm.items[index];
              return ListTile(
                title: Text(item.noWashing),
                subtitle: Text(
                  "Jenis: ${item.namaJenisPlastik} • Gudang: ${item.namaWarehouse}",
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Density: ${item.density}"),
                    Text("Moisture: ${item.moisture}"),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
