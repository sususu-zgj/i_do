import 'dart:io';

import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:i_do/i_do_api.dart';
import 'package:path/path.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

class AppConfig extends ChangeNotifier {
  // 单例
  AppConfig._internal();
  static final AppConfig _instance = AppConfig._internal();
  factory AppConfig() => _instance;

  // 排序模式
  /// 默认排序
  static const int SORT_DEFAULT = 0; 

  /// 标题排序
  static const int SORT_TITLE = 1;

  /// 日期排序
  static const int SORT_DATE = 2;

  static Future<File> get config async {
    return File(join( await IDoAPI.storagePath, 'config.yaml'));
  }

  /// 排序模式
  int get sortMode => _sortMode;
  set sortMode(int value) {
    if (value < SORT_DEFAULT || value > SORT_DATE) {
      return;
    }
    _sortMode = value;
    update();
  }

  // 逆向排序
  bool get isSortReverse => _isSortReverse;
  set isSortReverse(bool value) {
    _isSortReverse = value;
    update();
  }

  // Note 显示的列数
  int get columnsCount => _columnsCount;
  set columnsCount(int value) {
    value = value.clamp(1, 2);
    _columnsCount = value;
    update();
  }


  /// 控制创建Note按钮的位置
  /// true - 浮动在右下角
  /// false - 固定在AppBar 
  bool get isEditButtonFloating => _isEditButtonFloating;
  set isEditButtonFloating(bool value) {
    _isEditButtonFloating = value;
    update();
  }

  /// 是否显示完成的Note
  bool get isFinishShown => _isFinishShown;
  set isFinishShown(bool value) {
    _isFinishShown = value;
    if (!_isFinishShown && !_isUnfinishShown) {
      // 保证至少有一个被显示
      _isUnfinishShown = true;
    }
    update();
  }
  
  /// 是否显示未完成的Note
  bool get isUnfinishShown => _isUnfinishShown;
  set isUnfinishShown(bool value) {
    _isUnfinishShown = value;
    if (!_isUnfinishShown && !_isFinishShown) {
      // 保证至少有一个被显示
      _isFinishShown = true;
    }
    update();
  }

  // 通过点击修改完成情况
  bool get isToggleFinish => _isToggleFinish;
  set isToggleFinish(bool value) {
    _isToggleFinish = value;
    update();
  }

  Map<String, Object> toMap() {
    return {
      'isEditButtonFloating': _isEditButtonFloating,
      'isFinishShown': _isFinishShown ,
      'isUnfinishShown': _isUnfinishShown,
      'isToggleFinish': _isToggleFinish,
      'sortMode': _sortMode,
      'isSortReverse': _isSortReverse,
      'columnsCount': _columnsCount,
    };
  }

  /// 从Map中加载数据
  void fromMap(Map<String, Object?> map) {
    _isEditButtonFloating = map['isEditButtonFloating'] is bool
        ? map['isEditButtonFloating'] as bool
        : _isEditButtonFloating;
    _isFinishShown = map['isFinishShown'] is bool
        ? map['isFinishShown'] as bool
        : _isFinishShown;
    _isUnfinishShown = map['isUnfinishShown'] is bool
        ? map['isUnfinishShown'] as bool
        : _isUnfinishShown;
    _isToggleFinish = map['isToggleFinish'] is bool
        ? map['isToggleFinish'] as bool
        : _isToggleFinish;
    _sortMode = map['sortMode'] is int 
        ? (map['sortMode'] as int).clamp(SORT_DEFAULT, SORT_DATE) 
        : SORT_DEFAULT;
    _isSortReverse = map['isSortReverse'] is bool
        ? map['isSortReverse'] as bool
        : _isSortReverse;
    _columnsCount = map['columnsCount'] is int 
        ? (map['columnsCount'] as int).clamp(1, 2) 
        : 1;

    notifyListeners();
  }

  /// 初始化
  Future<void> load() async {
    try {
      final configData = await config;

      if (await configData.exists()) {
        final yamlContent = await configData.readAsString();
        final yamlMap = loadYaml(yamlContent)['config'];
        if (yamlMap is YamlMap) {
          fromMap(Map<String, Object?>.from(yamlMap));
        } else if (yamlMap is Map) {
          fromMap(Map<String, Object?>.from(yamlMap));
        }
        
        debugPrint('Loaded AppConfig');
      }
      await update(notify: false);
    } catch(e) {
      debugPrint('Failed to load AppConfig');
    }
  }

  /// 更新
  Future<void> update({bool notify = true}) async {
    try {
      final configData = await config;
      final dataMap = toMap();

      if (await configData.exists()) {
        final yamlContent = await configData.readAsString();
        final yamlEditor = YamlEditor(yamlContent.trim().isNotEmpty ? yamlContent : 'config:');

        yamlEditor.update(['config'], dataMap);
        await configData.writeAsString(yamlEditor.toString());
      } else {
        final yamlEditor = YamlEditor('');
        yamlEditor.update([], {'config': dataMap});
        await configData.writeAsString(yamlEditor.toString());
      }

      notifyListeners();
      debugPrint('Saved AppConfig');
    } catch (e) {
      debugPrint('Failed to save AppConfig');
      debugPrint(e.toString());
    }
  }

  int _sortMode = SORT_DEFAULT;
  bool _isSortReverse = false;
  bool _isEditButtonFloating = true;
  bool _isFinishShown = true;  
  bool _isUnfinishShown = true;  
  bool _isToggleFinish = false;
  int _columnsCount = 1;
}

class Setting extends ChangeNotifier {
  Setting._internal();
  factory Setting() => _instance;
  static final Setting _instance = Setting._internal();

  static final Map<String, FlexScheme> schemesMap = {
    for (var e in IDoAPI.schemes) e.name: e
  };

  static final Map<String, ThemeMode> themeModesMap = {
    for (var e in ThemeMode.values) e.name: e
  };

  static Future<File> get config async {
    return File(join(await IDoAPI.storagePath, 'config.yaml'));
  }

  ThemeMode _themeMode = ThemeMode.system;
  FlexScheme _colorScheme = FlexScheme.flutterDash;
  String _dataPath = '';
  String _startUpSentence = 'Hello! {<weekday>}!\n{<year>}\/{<month>}\/{<day>}';
  bool _enableAnimations = true;
  bool _savePop = true;
  bool _enableStartUpAnimation = true;

  ThemeMode get themeMode => _themeMode;
  FlexScheme get colorScheme => _colorScheme;
  String get dataPath => _dataPath;
  String get startUpSentence => _startUpSentence;
  bool get enableAnimations => _enableAnimations;
  bool get savePop => _savePop;
  bool get enableStartUpAnimation => _enableStartUpAnimation;

  set themeMode(ThemeMode mode) {
    _themeMode = mode;
    update();
  }

  set colorScheme(FlexScheme scheme) {
    _colorScheme = scheme;
    update();
  }

  set dataPath(String path) {
    _dataPath = path;
    update();
  }

  set startUpSentence(String sentence) {
    _startUpSentence = sentence;
    update();
  }

  set enableAnimations(bool enable) {
    _enableAnimations = enable;
    update();
  }

  set savePop(bool save) {
    _savePop = save;
    update();
  }

  set enableStartUpAnimation(bool enable) {
    _enableStartUpAnimation = enable;
    update();
  }

  Future<void> load() async {
    try {
      final configData = await config;

      if (await configData.exists()) {
        final yamlContent = await configData.readAsString();
        final yamlMap = loadYaml(yamlContent)['setting'];
        if (yamlMap is YamlMap) {
          fromMap(Map<String, Object?>.from(yamlMap));
        } else if (yamlMap is Map) {
          fromMap(Map<String, Object?>.from(yamlMap));
        }

        debugPrint('Loaded Setting');
      }
      await update(notify: false);
    } catch(_) {
      debugPrint('Failed to load Setting');
    }
  }

  Future<void> update({bool notify = true}) async {
    try {
      final configData = await config;
      final dataMap = toMap();

      if (await configData.exists()) {
        final content = await configData.readAsString();
        final yamlEditor = YamlEditor(content.trim().isNotEmpty ? content : 'setting:');
        yamlEditor.update(['setting'], dataMap);
        await configData.writeAsString(yamlEditor.toString());
      } else {
        final yamlEditor = YamlEditor('');
        yamlEditor.update([], {'setting': dataMap});
        await configData.writeAsString(yamlEditor.toString());
      }

      if (notify) {
        notifyListeners();
      }
      debugPrint('Saved Setting');
    } catch (_) {
      debugPrint('Failed to save Setting');
    }
  }

  Map<String, Object> toMap() {
    return {
      'themeMode': _themeMode.name,
      'colorScheme': _colorScheme.name,
      'dataPath': _dataPath,
      'startUpSentence': _startUpSentence,
      'enableAnimations': _enableAnimations,
      'savePop': _savePop,
      'enableStartUpAnimation': _enableStartUpAnimation,
    };
  }

  void fromMap(Map<String, Object?> map) {
    _themeMode = map['themeMode'] is String
        ? themeModesMap[map['themeMode'] as String] ?? ThemeMode.system
        : ThemeMode.system;
    _colorScheme = map['colorScheme'] is String
        ? schemesMap[map['colorScheme'] as String] ?? FlexScheme.flutterDash
        : FlexScheme.flutterDash;
    _dataPath = map['dataPath'] is String 
        ? map['dataPath'] as String 
        : '';
    _startUpSentence = map['startUpSentence'] is String 
        ? map['startUpSentence'] as String 
        : '';
    _enableAnimations = map['enableAnimations'] is bool 
        ? map['enableAnimations'] as bool 
        : _enableAnimations;
    _savePop = map['savePop'] is bool 
        ? map['savePop'] as bool 
        : _savePop;
    _enableStartUpAnimation = map['enableStartUpAnimation'] is bool 
        ? map['enableStartUpAnimation'] as bool
        : _enableStartUpAnimation;
    notifyListeners();
  }
}
