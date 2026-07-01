class CustomerInfo {
  final String name;
  final String table;

  const CustomerInfo({
    this.name = '',
    this.table = '',
  });

  CustomerInfo copyWith({
    String? name,
    String? table,
  }) {
    return CustomerInfo(
      name: name ?? this.name,
      table: table ?? this.table,
    );
  }
}