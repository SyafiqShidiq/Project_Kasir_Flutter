import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/merchant_model.dart';
import '../services/merchant_service.dart';

final merchantServiceProvider = Provider<MerchantService>((ref) {
  return MerchantService();
});

final merchantProvider =
    NotifierProvider<MerchantNotifier, MerchantModel?>(
  MerchantNotifier.new,
);

class MerchantNotifier extends Notifier<MerchantModel?> {
  late final MerchantService _service;

  @override
  MerchantModel? build() {
    _service = ref.read(merchantServiceProvider);
    return null;
  }

  Future<void> loadCurrentMerchant() async {
    print('Load Merchant');
    final merchant = await _service.getCurrentMerchant();
    print('Merchant: $merchant');
    state = merchant;
  }

  Future<void> loadMerchantByCode(String merchantCode) async {
    final merchant =
        await _service.getMerchantByCode(merchantCode);
    state = merchant;
  }

  void setMerchant(MerchantModel merchant) {
    state = merchant;
  }

  void clear() {
    state = null;
  }
}