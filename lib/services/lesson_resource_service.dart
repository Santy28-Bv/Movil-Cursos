class LessonResourceService {
  static Uri? validatedExternal(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty) {
      return null;
    }
    if (uri.path.contains('/storage/v1/object/public/')) return null;
    return uri;
  }
}
