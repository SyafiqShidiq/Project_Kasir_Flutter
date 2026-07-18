class QrPayload {
  const QrPayload({
    required this.version,
    required this.type,
    required this.value,
  });

  final String version;
  final String type;
  final String value;

  @override
  String toString() {
    return 'QrPayload('
        'version: $version, '
        'type: $type, '
        'value: $value'
        ')';
  }
}