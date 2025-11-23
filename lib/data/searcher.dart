import 'package:flutter/material.dart';
import 'package:i_do/data/note.dart';

class Searcher extends ChangeNotifier {
  /// 单例
  static final Searcher _instance = Searcher._internal();
  factory Searcher() => _instance;
  Searcher._internal();

  late NoteData _noteData;  // 引用内存中的数据
  String _title = '';   // 搜索标题
  List<String> _tags = [];  // 搜索标签
  List<String> _blackTags = [];   // 排除标签，筛选结果不受tagStrict影响
  int _year = -1;   // 搜索年份，非正数表示不筛选本级及下级日期，下同
  int _month = -1;    // 搜索月份
  int _day = -1;    // 搜索日期
  bool _titleStrict = true;  // 标题严格模式
  bool _tagStrict = true; // 标签严格模式，不影响blackTags的筛选结果

  String get title => _title;
  List<String> get tags => _tags;
  List<String> get blackTags => _blackTags;
  int get year => _year;
  int get month => _month;
  int get day => _day;
  bool get titleStrict => _titleStrict;
  bool get tagStrict => _tagStrict;

  List<Note> _results = [];
  List<Note> get results => List.of(_results);
  
  int get resultCount => _results.length;

  void load(NoteData noteData) {
    _noteData = noteData;
    _results = _noteData.notes;
    notifyListeners();
  }

  List<Note> search({
    String? title,
    List<String>? tags,
    List<String>? blackTags,
    int? year,
    int? month,
    int? day,
    bool? titleStrict,
    bool? tagStrict,
    List<Note>? from,
  }) {
    _title = title?.toLowerCase() ?? _title;
    _tags = tags ?? _tags;
    _blackTags = blackTags ?? _blackTags;
    _year = year ?? _year;
    _month = month ?? _month;
    _day = day ?? _day;
    _titleStrict = titleStrict ?? _titleStrict;
    _tagStrict = tagStrict ?? _tagStrict;

    final rs = (from ?? _noteData.notes).where((note) {
      /// 标签黑名单
      /// 包含任意一项会被排除
      if (_blackTags.any((tag) => note.tags.contains(tag))) {
        return false;
      }
      /// 日期筛选
      /// 可按照 年份、月份、日期 逐级筛选
      if (_year > 0) {
        if (note.dateTime.year != _year) {
          return false;
        }
        if (_month > 0) {
          if (note.dateTime.month != _month) {
            return false;
          }
          if (_day > 0 && note.dateTime.day != _day) {
            return false;
          }
        }
      }
      /// 标签筛选
      /// 严格模式：必须包含所有标签
      /// 非严格模式：包含任意一个标签即可
      if (_tagStrict && !_tags.every((tag) => note.tags.contains(tag))) {
        return false;
      }
      else if (!_tagStrict && _tags.isNotEmpty && !_tags.any((tag) => note.tags.contains(tag))) {
        return false;
      }
      /// 标题筛选
      /// 严格模式：标题必须以指定内容开头
      /// 非严格模式：标题包含指定内容即可
      final ti = note.title.trim().toLowerCase();
      if (ti.isNotEmpty && ( _titleStrict ? !ti.startsWith(_title) : !ti.contains(_title))) {
        return false;
      }

      return true;
    }).toList();

    if(from==null) {
      _results = rs;
      debugPrint('Searched');
      notifyListeners();
    }
    
    return rs;
  }

  void update() {
    notifyListeners();
  }

  List<Note> byFilter(List<Note>? from, SearchFilter filter) {
    return search(
      title: filter.title,
      tags: filter.tags,
      blackTags: filter.blackTags,
      year: filter.year,
      month: filter.month,
      day: filter.day,
      titleStrict: filter.titleStrict,
      tagStrict: filter.tagStrict,
      from: from,
    );
  }

}

class SearchFilter {
  int? key;

  final String id;
  final String name;

  final String title;
  final List<String> tags;
  final List<String> blackTags;
  final int year;
  final int month;
  final int day;
  final bool titleStrict;
  final bool tagStrict;

  SearchFilter({
    this.key,
    required this.id,
    this.name = '无',
    this.title = '',
    this.tags = const [],
    this.blackTags = const [],
    this.year = -1,
    this.month = -1,
    this.day = -1,
    this.titleStrict = false,
    this.tagStrict = false,
  });

  SearchFilter copyWith({
    int? key,
    String? id,
    String? name,
    String? title,
    List<String>? tags,
    List<String>? blackTags,
    int? year,
    int? month,
    int? day,
    bool? titleStrict,
    bool? tagStrict,
  }) {
    return SearchFilter(
      key: key ?? this.key,
      id: id ?? this.id,
      name: name ?? this.name,
      title: title ?? this.title,
      tags: tags ?? this.tags,
      blackTags: blackTags ?? this.blackTags,
      year: year ?? this.year,
      month: month ?? this.month,
      day: day ?? this.day,
      titleStrict: titleStrict ?? this.titleStrict,
      tagStrict: tagStrict ?? this.tagStrict,
    );
  }
}