import '../models/qr_payload.dart';

class QrParserService {
  const QrParserService();

  QrPayload? parse(String rawData) {
    final uri = Uri.tryParse(rawData);

    if (uri == null) {
      return null;
    }

    if (uri.scheme != 'smartcashier') {
      return null;
    }

    final segments = uri.pathSegments;

    if (segments.length < 2) {
      return null;
    }

    return QrPayload(
      version: uri.host,
      type: segments[0],
      value: segments[1],
    );
  }
}