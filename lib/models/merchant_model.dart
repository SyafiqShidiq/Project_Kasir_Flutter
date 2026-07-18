class MerchantModel {
  final String id;
  final String merchantCode;
  final String merchantName;
  final String? address;
  final String? phone;
  final String? midtransMerchantId;
  final String? midtransClientKey;
  final String? midtransServerKey;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MerchantModel({
    required this.id,
    required this.merchantCode,
    required this.merchantName,
    this.address,
    this.phone,
    this.midtransMerchantId,
    this.midtransClientKey,
    this.midtransServerKey,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MerchantModel.fromMap(Map<String, dynamic> map) {
    return MerchantModel(
      id: map['id'] as String,
      merchantCode: map['merchant_code'] as String,
      merchantName: map['merchant_name'] as String,
      address: map['address'] as String?,
      phone: map['phone'] as String?,
      midtransMerchantId: map['midtrans_merchant_id'] as String?,
      midtransClientKey: map['midtrans_client_key'] as String?,
      midtransServerKey: map['midtrans_server_key'] as String?,
      isActive: map['is_active'] as bool,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'merchant_code': merchantCode,
      'merchant_name': merchantName,
      'address': address,
      'phone': phone,
      'midtrans_merchant_id': midtransMerchantId,
      'midtrans_client_key': midtransClientKey,
      'midtrans_server_key': midtransServerKey,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  MerchantModel copyWith({
    String? id,
    String? merchantCode,
    String? merchantName,
    String? address,
    String? phone,
    String? midtransMerchantId,
    String? midtransClientKey,
    String? midtransServerKey,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MerchantModel(
      id: id ?? this.id,
      merchantCode: merchantCode ?? this.merchantCode,
      merchantName: merchantName ?? this.merchantName,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      midtransMerchantId:
          midtransMerchantId ?? this.midtransMerchantId,
      midtransClientKey:
          midtransClientKey ?? this.midtransClientKey,
      midtransServerKey:
          midtransServerKey ?? this.midtransServerKey,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
  @override
  String toString() {
    return 'MerchantModel('
        'code: $merchantCode, '
        'name: $merchantName, '
        'active: $isActive'
        ')';
  }
}