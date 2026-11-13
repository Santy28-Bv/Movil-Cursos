import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart' as web;

String createResourceUrl(Uint8List bytes, String contentType) =>
    web.URL.createObjectURL(
      web.Blob(
        <JSAny>[bytes.toJS].toJS,
        web.BlobPropertyBag(type: contentType),
      ),
    );
void revokeResourceUrl(String url) => web.URL.revokeObjectURL(url);
