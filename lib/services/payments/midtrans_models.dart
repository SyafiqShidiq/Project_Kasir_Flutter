class MidtransQrResponse {
  final String transactionId;
  final String qrUrl;

  const MidtransQrResponse({
    required this.transactionId,
    required this.qrUrl,
  });

  factory MidtransQrResponse.fromMap(
    Map<String, dynamic> json,
  ) {
    return MidtransQrResponse(
      transactionId: json['transaction_id'] ?? '',
      qrUrl: json['actions'] == null
          ? ''
          : (json['actions'] as List)
              .firstWhere(
                (e) => e['name'] == 'generate-qr-code',
                orElse: () => {'url': ''},
              )['url'],
    );
  }
}