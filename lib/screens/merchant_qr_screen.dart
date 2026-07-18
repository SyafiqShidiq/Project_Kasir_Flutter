import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../providers/merchant_provider.dart';
import 'cashier_home_screen.dart';

class MerchantQrScreen extends ConsumerStatefulWidget {
  const MerchantQrScreen({super.key});

  @override
  ConsumerState<MerchantQrScreen> createState() =>
      _MerchantQrScreenState();
}

class _MerchantQrScreenState
    extends ConsumerState<MerchantQrScreen> {

  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      await ref
          .read(merchantProvider.notifier)
          .loadCurrentMerchant();
    });
  }

  @override
  Widget build(BuildContext context) {

    final merchant = ref.watch(merchantProvider);
    print(merchant);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Merchant QR'),
      ),
      bottomNavigationBar:
          const CashierNavigationBar(activeIndex: 3),
      
      body: merchant == null
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  //Card Merchant
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [

                          const Icon(
                            Icons.store,
                            size: 48,
                          ),

                          const SizedBox(height: 12),

                          Text(
                            merchant.merchantName,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),

                          const SizedBox(height: 16),

                          const Text(
                            'Kode Merchant',
                            style: TextStyle(
                              color: Colors.grey,
                            ),
                          ),

                          const SizedBox(height: 4),

                          Text(
                            merchant.merchantCode,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  //Card QR
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          QrImageView(
                            data:
                                'smartcashier://v1/merchant/${merchant.merchantCode}',
                            version: QrVersions.auto,
                            size: 240,
                          ),

                          const SizedBox(height: 20),

                          const Text(
                            'Isi QR',
                          ),

                          const SizedBox(height: 4),

                          Text(
                            'smartcashier://v1/merchant/${merchant.merchantCode}',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  //Card Instruksi
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.info_outline,
                            size: 28,
                          ),

                          const SizedBox(width: 16),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Petunjuk Penggunaan',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),

                                const SizedBox(height: 12),

                                const Text(
                                  'QR ini digunakan sebagai QR pembayaran pelanggan.\n\n'
                                  '• Cetak QR ini dan letakkan di setiap meja.\n\n'
                                  '• Semua meja pada cabang ini dapat menggunakan QR yang sama.\n\n'
                                  '• Jika salah satu QR rusak, pelanggan dapat menggunakan QR dari meja lain atau meminta bantuan kasir.',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  //Card button
                  Row(
                    children: [

                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          icon: Icon(Icons.download),
                          label: Text("Download"),
                        ),
                      ),

                      SizedBox(width: 12),

                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: Icon(Icons.print),
                          label: Text("Print"),
                        ),
                      ),
                    ],
                  )
                ]
              )
            )
    );
  }
}