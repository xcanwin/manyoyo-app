import 'package:flutter_test/flutter_test.dart';

import 'package:manyoyo_app/models/fs_entry.dart';

void main() {
  test('FsEntry.fromJson parses file', () {
    final entry = FsEntry.fromJson({
      'name': 'main.dart',
      'path': '/workspace/main.dart',
      'type': 'file',
      'size': 1024,
      'editable': true,
      'language': 'dart',
    });
    expect(entry.name, equals('main.dart'));
    expect(entry.path, equals('/workspace/main.dart'));
    expect(entry.isDirectory, isFalse);
    expect(entry.size, equals(1024));
    expect(entry.editable, isTrue);
    expect(entry.language, equals('dart'));
  });

  test('FsEntry.fromJson parses directory', () {
    final entry = FsEntry.fromJson({
      'name': 'src',
      'path': '/workspace/src',
      'type': 'directory',
    });
    expect(entry.isDirectory, isTrue);
    expect(entry.editable, isFalse);
    expect(entry.size, isNull);
  });

  test('FsEntry.fromJson also supports kind field', () {
    final entry = FsEntry.fromJson({
      'name': 'docs',
      'path': '/workspace/docs',
      'kind': 'directory',
    });
    expect(entry.isDirectory, isTrue);
  });

  test('FsEntry.fromJson handles missing optional fields', () {
    final entry = FsEntry.fromJson({
      'name': 'README',
      'path': '/README',
      'type': 'file',
    });
    expect(entry.language, isNull);
    expect(entry.size, isNull);
    expect(entry.editable, isFalse);
  });

  test('FsEntry list from json list', () {
    final list = FsEntry.listFromJson([
      {'name': 'a', 'path': '/a', 'type': 'file'},
      {'name': 'b', 'path': '/b', 'type': 'directory'},
    ]);
    expect(list.length, equals(2));
    expect(list[0].name, equals('a'));
    expect(list[1].isDirectory, isTrue);
  });
}
