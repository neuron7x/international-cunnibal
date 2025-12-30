class SchemaVersion {
  static const int major = 1;
  static const int minor = 0;
  static const int patch = 0;

  static String get current => '$major.$minor.$patch';

  static bool isCompatible(String version) {
    final parts = version.split('.');
    if (parts.isEmpty) return false;
    final parsedMajor = int.tryParse(parts.first);
    if (parsedMajor == null) return false;
    return parsedMajor == major;
  }
}
