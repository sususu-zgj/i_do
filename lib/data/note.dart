import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:i_do/data/db.dart';

class Note {
  ///
  ///  [key] 数据库主键，为空时无法进行除插入数据库以外的操作
  ///  [title] 标题
  ///  [text] 内容
  ///  [tags] 标签列表
  ///  [date] 日期（仅年月日有效）
  ///  [isFinished] 是否完成
  ///  [isStarred] 是否加标记为重要
  Note({
    this.key, 
    required this.title, 
    this.text = '', 
    this.tags = const [], 
    required DateTime date, 
    this.isFinished = false,
    this.isStarred = false,
  }) : _dateTime = DateTime(date.year, date.month, date.day);

  int? key;
  String title;
  String text;
  List<String> tags;
  DateTime _dateTime;
  bool isFinished;
  bool isStarred;

  /// 统一仅使用年月日
  DateTime get dateTime => _dateTime;
  set dateTime(DateTime dateTime) => _dateTime = DateTime(dateTime.year, dateTime.month, dateTime.day);

  Map<String, Object?> toMap() {
    return {
      'key': key,
      'title': title,
      'text': text,
      'tags': jsonEncode(tags),
      'dateTime': dateTime.millisecondsSinceEpoch,
      'finish': isFinished ? 1 : 0,
      'starred': isStarred ? 1 : 0,
    };
  }

  factory Note.fromMap(Map<String, Object?> map) {
    // parse tags safely (handle null/empty/invalid JSON)
    List<String> parsedTags = [];
    final tagsRaw = map['tags'] as String?;
    if (tagsRaw != null && tagsRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(tagsRaw);
        if (decoded is List) {
          parsedTags = decoded.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList();
        }
      } catch (_) {
        // ignore JSON parse errors and fall back to empty list
      }
    }

    DateTime dt = DateTime.fromMillisecondsSinceEpoch((map['dateTime'] as int?) ?? 0);

    return Note(
      key: map['key'] as int?,
      title: map['title'] as String? ?? '',
      text: map['text'] as String? ?? '',
      tags: parsedTags,
      date: DateTime(dt.year, dt.month, dt.day),
      isFinished: (map['finish'] as int?) == 1,
      isStarred: (map['starred'] as int?) == 1,
    );
  }
}

/// 管理 Note 的接口
class Noter extends ChangeNotifier {
  /// 单例
  Noter._internal();
  factory Noter() => _instance;
  static final Noter _instance = Noter._internal();

  // 数据
  final NoteData _noteData = NoteData();

  List<Note> get notes => _noteData.notes;
  List<String> get tags => _noteData.tags;
  List<DateTime> get dateTimes => _noteData.dateTimes;

  NoteData get data => _noteData;

  Future<void> load() async {
    _noteData.clear();
    try {
      // 确保数据库已打开
      await DB().open();
      debugPrint('Database open');

      // 并行获取 notes 和 tags
      final results = await Future.wait([
        DB().getNotes(),
        DB().getTags(),
      ]);

      debugPrint('Notes and tags loaded');

      final notes = results[0] as List<Note>;
      final tags = results[1] as List<String>;

      for (var tag in tags) {
        _noteData.addTag(tag);
      }

      for (var note in notes) {
        _noteData.addNote(note);
      }
    } catch (e) {
      debugPrint('Error loading notes and tags: $e');
    }

    notifyListeners();
  }

  Future<void> addNotes(List<Note> notes) async {
    notes = notes.where((n) => !_noteData.containsNote(n)).toList();

    try {
      List<int> keys = await DB().insertNotes(notes);
      for (int i = 0; i < notes.length; i++) {
        notes[i].key = keys[i];
        _noteData.addNote(notes[i]);
      }
      debugPrint('Added ${notes.length} notes');
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding notes: $e');
    }

    notifyListeners();
  }

  Future<bool> addNote(Note note) async {
    if (!_noteData.containsNote(note)) {
      try {
        int key = await DB().insertNote(note);
        note.key = key;
        _noteData.addNote(note);

        debugPrint('Added note with key: $key');
        notifyListeners();

        return true;
      } catch (e) {
        debugPrint('Error adding note: $e');
      }
    }
    return false;
  }

  Future<bool> updateNote(Note note) async {
    if (_noteData.containsNote(note) && note.key != null) {
      try {
        await DB().updateNote(note);
        _noteData.updateNote(note);

        debugPrint('Updated note with key: ${note.key}');
        notifyListeners();
        return true;
      } catch (e) {
        debugPrint('Error updating note: $e');
      }
    }

    return false;
  }

  Future<bool> updateNotes(List<Note> notes, {bool reclassify = true}) async {
    notes = notes.where((n) => n.key != null && _noteData.containsNote(n)).toList();

    try {
      await DB().updateNotes(notes);
      
      if (reclassify) {
        for (var note in notes) {
          _noteData.updateNote(note);
        }
      }

      notifyListeners();
      debugPrint('Updated ${notes.length} notes');
      return true;
    } catch (e) {
      debugPrint('Error updating notes: $e');
    }
    return false;
  }

  Future<bool> removeNote(Note note) async {
    if (_noteData.containsNote(note) && note.key != null) {
      try {
        await DB().removeNote(note);
        _noteData.removeNote(note);
        notifyListeners();
        debugPrint('Removed note with key: ${note.key}');
        return true;
      } catch (e) {
        debugPrint('Error removing note: $e');
      }
    }
    return false;
  }

  Future<bool> removeNotes(List<Note> notes) async {
    notes = notes.where((n) => n.key != null && _noteData.containsNote(n)).toList();

    try {
      await DB().removeNotes(notes);
      for (var note in notes) {
        _noteData.removeNote(note);
      }
      
      notifyListeners();
      debugPrint('Removed ${notes.length} notes');
      return true;
    } catch (e) {
      debugPrint('Error removing notes: $e');
    }
    return false;
  }

  Future<bool> addTag(String tag) async {
    if (!_noteData.tags.contains(tag)) {
      try {
        await DB().insertTag(tag);
        _noteData.addTag(tag);
        notifyListeners();
        debugPrint('Added tag: $tag');
        return true;
      } catch (e) {
        debugPrint('Error adding tag: $e');
      }
    }
    return false;
  }

  Future<bool> addTags(List<String> tags) async {
    tags = tags.where((t) => !_noteData.tags.contains(t)).toList();

    try {
      await DB().insertTags(tags);
      for (var tag in tags) {
        _noteData.addTag(tag);
      }
      
      notifyListeners();
      debugPrint('Added ${tags.length} tags');
      return true;
    } catch (e) {
      debugPrint('Error adding tags: $e');
    }

    return false;
  }

  Future<bool> removeTag(String tag) async {
    if (_noteData.tags.contains(tag)) {
      try {
        await DB().removeTag(tag);
        _noteData.removeTag(tag);

        notifyListeners();
        debugPrint('Removed tag: $tag');
        return true;
      } catch (e) {
        debugPrint('Error removing tag: $e');
      }
    }
    return false;
  }

  Future<bool> removeTags(List<String> tags) async {
    tags = tags.where((t) => _noteData.tags.contains(t)).toList();

    try {
      await DB().removeTags(tags);
      for (var tag in tags) {
        _noteData.removeTag(tag);
      }
      notifyListeners();
      debugPrint('Removed ${tags.length} tags');
      return true;
    } catch (e) {
      debugPrint('Error removing tags: $e');
    }

    return false;
  }

  Future<bool> clear() async {
    try {
      await DB().clearNotes();
      await DB().clearTags();
      _noteData.clear();
      notifyListeners();
      debugPrint('Cleared all notes and tags');
      return true;
    } catch (e) {
      debugPrint('Error clearing notes: $e');
    }
    return false;
  } 

  void update() {
    notifyListeners();
    debugPrint('Noter updated');
  }

}

class NoteData {
  // 所有的note
  final List<Note> _notes = [];

  List<Note> get notes => List.of(_notes);

  // 所有的tag
  final List<String> _tags = [];

  List<String> get tags => List.of(_tags);

  // 所有的DateTime
  final List<DateTime> _dateTimes = [];

  final Map<DateTime, List<Note>> _datedNotes = {};

  List<DateTime> get dateTimes => List.of(_dateTimes);

  void addNote(Note note) {
    if (!_notes.contains(note)) {
      note.tags.where((tag) => !_tags.contains(tag)).forEach((tag) => _tags.add(tag));

      final dt = note.dateTime;
      if (!_dateTimes.contains(dt)) {
        _dateTimes.add(dt);
        _datedNotes[dt] = [note];
        _dateTimes.sort((a, b) => b.compareTo(a));
      } else {
        _datedNotes[dt]!.add(note);
      }

      _notes.add(note);
    }
  }

  void updateNote(Note note) {
    if (_notes.contains(note)) {
      note.tags.where((tag) => !_tags.contains(tag)).forEach((tag) => _tags.add(tag));

      final dt = note.dateTime;
      
      // 从原时间分类中移除
      _datedNotes.forEach((key, value) {
        value.removeWhere((n) => n == note);
      });
      // 清理空的时间分类
      _datedNotes.removeWhere((key, value) => value.isEmpty);
      _dateTimes.removeWhere((d) => !_datedNotes.containsKey(d));
      // 添加到新时间分类
      if (_datedNotes.containsKey(dt)) {
        _datedNotes[dt]!.add(note);
      } else {
        _dateTimes.add(dt);
        _datedNotes[dt] = [note];
        _dateTimes.sort((a, b) => b.compareTo(a));
      }
    }
  }

  void removeNote(Note note) {
    if (_notes.contains(note)) {
      _notes.remove(note);

      final dt = note.dateTime;
      if (_datedNotes.containsKey(dt)) {
        _datedNotes[dt]!.remove(note);
        if (_datedNotes[dt]!.isEmpty) {
          _datedNotes.remove(dt);
          _dateTimes.remove(dt);
        }
      }
    }
  }

  bool containsNote(Note note) {
    return _notes.contains(note);
  }

  void addTag(String tag) {
    if (!_tags.contains(tag)) {
      _tags.add(tag);
    }
  }

  void removeTag(String tag) {
    if (_tags.contains(tag)) {
      _tags.remove(tag);

      for (var note in _notes) {
        note.tags.remove(tag);
      }
    }
  }

  void clear() {
    _notes.clear();
    _tags.clear();
    _dateTimes.clear();
    _datedNotes.clear();
  }
}