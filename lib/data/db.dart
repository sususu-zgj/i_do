import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:i_do/data/note.dart';
import 'package:i_do/data/setting.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DB {
  // 单例
  DB._internal();
  factory DB() => _instance;
  static final DB _instance = DB._internal();

  // 数据库版本
  static const int _dbVersion = 1;

  /// settingDb - 设置相关数据库，包含 SettingData 和 HomeData
  static const String _settingDbName = 'i_do_setting.db';

  /// db - 其它数据，如 Note, Tag 等
  static const String _dbName = 'i_do.db';

  Database? _settingDb;
  Database? _db;

  /// 从数据库文件中载入数据，包括 SettingData 和 HomeData
  Future<Database> openSettingDb() async {
    if (_settingDb != null && _settingDb!.isOpen) {
      return _settingDb!;
    }

    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _settingDbName);

    _settingDb = await openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute(_SettingDb.CREATE);
        await db.execute(_HomeDataDb.CREATE);
      },
    );
    return _settingDb!;
  }

  /// 获取指定 id 的 Setting 数据
  Future<SettingData> getSettingData(String id) async {
    final db = await openSettingDb();
    final List<Map<String, Object?>> maps = await db.query(
      _SettingDb.table,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return SettingData.fromMap(maps.first);
    } else {
      // 返回默认设置
      final path = (await getApplicationDocumentsDirectory()).path;
      final data = SettingData(
        version: 1,
        darkMode: null,
        flexColorScheme: FlexScheme.flutterDash,
        path: path,
      );
      await insertSettingData(data);
      return data;
    }
  }

  /// 插入 Setting 数据
  Future<int> insertSettingData(SettingData data) async {
    final db = await openSettingDb();
    return await db.insert(
      _SettingDb.table,
      data.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 更新 Setting 数据
  Future<int> updateSettingData(SettingData data) async {
    final db = await openSettingDb();
    return await db.update(
      _SettingDb.table,
      data.toMap(),
      where: 'id = ?',
      whereArgs: [data.id],
    );
  }

  /// 获取指定 id 的 HomeData 数据
  Future<Map<String, Object>?> getHomeData(String id) async {
    final db = await openSettingDb();
    final List<Map<String, Object?>> maps = await db.query(
      _HomeDataDb.table,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return maps.first.cast<String, Object>();
    } else {
      return null;
    }
  }

  /// 插入 HomeData 数据
  Future<int> insertHomeData(String id, Map<String, Object> data) async {
    final db = await openSettingDb();
    return await db.insert(
      _HomeDataDb.table,
      {'id': id, ...data},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 更新 HomeData 数据
  Future<int> updateHomeData(String id, Map<String, Object> data) async {
    final db = await openSettingDb();
    return await db.update(
      _HomeDataDb.table,
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// open - 从数据库文件中载入数据，包括 Note 和 Tag
  Future<Database> open() async {
    if (_db != null && _db!.isOpen) {
      return _db!;
    }

    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _dbName);

    _db = await openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute(_NoteDb.CREATE);
        await db.execute(_TagDb.CREATE);
      },
    );
    return _db!;
  }

  /// 获取所有 Note 数据
  Future<List<Note>> getNotes() async {
    final db = await open();
    final rows = await db.query(_NoteDb.table);
    return rows.map((r) => Note.fromMap(r)).toList();
  }

  /// 插入单个 Note 数据
  Future<int> insertNote(Note note) async {
    final db = await open();
    final id = await db.insert(_NoteDb.table, note.toMap());
    return id;
  }

  /// 批量插入 Note 数据
  Future<List<int>> insertNotes(List<Note> notes) async {
    if (notes.isEmpty) return [];
    final db = await open();
    final batch = db.batch();
    for (Note note in notes) {
      batch.insert(_NoteDb.table, note.toMap());
    }
    final results = await batch.commit();
    return results.whereType<int>().toList();
  }

  /// 更新单个 Note 数据
  Future<int> updateNote(Note note) async {
    final db = await open();
    if (note.key == null) throw ArgumentError('Note.key is null');
    return db.update(
      _NoteDb.table,
      note.toMap(),
      where: 'key = ?',
      whereArgs: [note.key],
    );
  }

  /// 批量更新 Note 数据
  Future<List<int>> updateNotes(List<Note> notes) async {
    if (notes.isEmpty) return [];
    final db = await open();
    final batch = db.batch();

    for (Note note in notes) {
      if (note.key == null) continue;
      batch.update(
        _NoteDb.table,
        note.toMap(),
        where: 'key = ?',
        whereArgs: [note.key],
      );
    }

    final results = await batch.commit();
    return results.whereType<int>().toList();
  }

  /// 删除单个 Note 数据
  Future<int> removeNote(Note note) async {
    final db = await open();
    return db.delete(
      _NoteDb.table,
      where: 'key = ?',
      whereArgs: [note.key],
    );
  }

  /// 批量删除 Note 数据
  Future<void> removeNotes(List<Note> notes) async {
    if (notes.isEmpty) return;
    final db = await open();
    final batch = db.batch();

    for (Note note in notes) {
      batch.delete(
        _NoteDb.table, 
        where: 'key = ?',
        whereArgs: [note.key],
      );
    }

    await batch.commit(noResult: true);
  }

  /// 清空所有 Note 数据
  Future<void> clearNotes() async {
    final db = await open();
    await db.delete(_NoteDb.table);
  }

  /// 获取所有 Tag 数据
  Future<List<String>> getTags() async {
    final db = await open();
    final rows = await db.query(_TagDb.table);
    return rows.map((r) => r['tag'] as String).toList();
  }

  /// 插入单个 Tag 数据
  Future<void> insertTag(String tag) async {
    final db = await open();
    await db.insert(
      _TagDb.table,
      {'tag': tag},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  /// 批量插入 Tag 数据
  Future<void> insertTags(Iterable<String> tags) async {
    if (tags.isEmpty) return;
    final db = await open();
    final batch = db.batch();
    for (final t in tags) {
      batch.insert(
        _TagDb.table,
        {'tag': t},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    await batch.commit(noResult: true);
  }

  /// 删除单个 Tag 数据
  Future<int> removeTag(String tag) async {
    final db = await open();
    return db.delete(
      _TagDb.table,
      where: 'tag = ?',
      whereArgs: [tag],
    );
  }

  /// 批量删除 Tag 数据
  Future<void> removeTags(Iterable<String> tags) async {
    if (tags.isEmpty) return;
    final db = await open();
    final batch = db.batch();
    for (final t in tags) {
      batch.delete(
        _TagDb.table,
        where: 'tag = ?',
        whereArgs: [t],
      );
    }
    await batch.commit(noResult: true);
  }

  /// 清空所有 Tag 数据
  Future<int> clearTags() async {
    final db = await open();
    return db.delete(_TagDb.table);
  }

  /// 关闭所有数据库连接
  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
    if (_settingDb != null) {
      await _settingDb!.close();
      _settingDb = null;
    }
  }
}

/// 数据库的表结构定义
/// Note, Tag, Setting, HomeData
class _NoteDb {
  static const String table = 'notes';

  static const String CREATE = 
  '''
    CREATE TABLE $table (
      key INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      text TEXT,
      tags TEXT,
      dateTime INTEGER NOT NULL,
      finish INTEGER NOT NULL
    );
  ''';
}

class _TagDb {
  static const String table = 'tags';

  static const String CREATE = 
  '''
    CREATE TABLE $table (
      tag TEXT PRIMARY KEY
    );
  ''';
}

class _SettingDb {
  static const String table = 'settings';

  static const String CREATE = 
  '''
    CREATE TABLE $table (
      id TEXT PRIMARY KEY,
      version INTEGER NOT NULL,
      darkMode INTEGER NOT NULL,
      flexColorScheme TEXT NOT NULL,
      path TEXT NOT NULL,
      enableAnimations INTEGER NOT NULL,
      savePop INTEGER NOT NULL
    );
  ''';
}

class _HomeDataDb {
  static const String table = 'home_data';

  static const String CREATE = 
  '''
    CREATE TABLE $table (
      id TEXT PRIMARY KEY,
      isEditButtonFloating INTEGER NOT NULL,
      isFinishShown INTEGER NOT NULL,
      isUnfinishShown INTEGER NOT NULL,
      isDateShown INTEGER NOT NULL,
      isTagShown INTEGER NOT NULL,
      isToggleFinish INTEGER NOT NULL
    );
  ''';
}