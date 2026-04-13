class FsEntry {
  const FsEntry({
    required this.name,
    required this.path,
    required this.isDirectory,
    this.size,
    this.editable = false,
    this.language,
  });

  final String name;
  final String path;
  final bool isDirectory;
  final int? size;
  final bool editable;
  final String? language;

  factory FsEntry.fromJson(Map<String, dynamic> json) {
    final kind = (json['kind'] as String?) ?? (json['type'] as String?);
    return FsEntry(
      name: json['name'] as String,
      path: json['path'] as String,
      isDirectory: kind == 'directory',
      size: json['size'] as int?,
      editable: (json['editable'] as bool?) ?? false,
      language: json['language'] as String?,
    );
  }

  static List<FsEntry> listFromJson(List<dynamic> raw) {
    return raw
        .map((e) => FsEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
